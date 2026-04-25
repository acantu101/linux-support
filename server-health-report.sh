#!/bin/bash
# ============================================================
#  SERVER HEALTH REPORT
#  Run as root: bash server_health_report.sh
#  Output: /opt/logs/health_report_<date>.txt
# ============================================================

# ---------- COLORS ----------
RED='\033[0;31m'
YEL='\033[0;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BLD='\033[1m'
RST='\033[0m'

# ---------- OUTPUT FILE ----------
REPORT_DIR="/opt/logs"
mkdir -p "$REPORT_DIR"
REPORT="$REPORT_DIR/health_report_$(date +%Y%m%d_%H%M%S).txt"
exec > >(tee -a "$REPORT") 2>&1

# ---------- HELPERS ----------
section()  { echo -e "\n${CYN}${BLD}════════════════════════════════════════════════════${RST}"; \
             echo -e "${CYN}${BLD}  $1${RST}"; \
             echo -e "${CYN}${BLD}════════════════════════════════════════════════════${RST}"; }
ok()       { echo -e "  ${GRN}[  OK  ]${RST}  $1"; }
warn()     { echo -e "  ${YEL}[ WARN ]${RST}  $1"; }
crit()     { echo -e "  ${RED}[ CRIT ]${RST}  $1"; }
info()     { echo -e "  ${BLD}[ INFO ]${RST}  $1"; }
divider()  { echo -e "  --------------------------------------------------------"; }

# ---------- THRESHOLDS ----------
CPU_WARN=70;        CPU_CRIT=90
MEM_WARN=75;        MEM_CRIT=90
SWAP_WARN=40;       SWAP_CRIT=80
DISK_WARN=80;       DISK_CRIT=90
IOWAIT_WARN=10;     IOWAIT_CRIT=25
AWAIT_WARN=20;      AWAIT_CRIT=50
UTIL_WARN=70;       UTIL_CRIT=85
INODE_WARN=80;      INODE_CRIT=90
OFD_WARN=10000;     OFD_CRIT=50000
LOAD_WARN=0.8;      LOAD_CRIT=1.2   # multiplier of core count

# ============================================================
echo ""
echo -e "${BLD}   SERVER HEALTH REPORT${RST}"
echo -e "  Generated : $(date)"
echo -e "  Hostname  : $(hostname)"
echo -e "  Uptime    : $(uptime -p)"
echo -e "  Kernel    : $(uname -r)"
echo ""

# ============================================================
section "1. CPU ANALYSIS"
# ============================================================

CPU_CORES=$(nproc)
CPU_IDLE=$(top -b -n 2 -d 0.5 | grep "Cpu(s)" | tail -1 | awk '{for(i=1;i<=NF;i++) if($i~/id,/) print $(i-1)}' | tr -d '%')
CPU_IOWAIT=$(top -b -n 2 -d 0.5 | grep "Cpu(s)" | tail -1 | awk '{for(i=1;i<=NF;i++) if($i~/wa,/) print $(i-1)}' | tr -d '%')
CPU_USER=$(top -b -n 2 -d 0.5 | grep "Cpu(s)" | tail -1 | awk '{for(i=1;i<=NF;i++) if($i~/us,/) print $(i-1)}' | tr -d '%')
CPU_SYS=$(top -b -n 2 -d 0.5 | grep "Cpu(s)" | tail -1 | awk '{for(i=1;i<=NF;i++) if($i~/sy,/) print $(i-1)}' | tr -d '%')
CPU_STEAL=$(top -b -n 2 -d 0.5 | grep "Cpu(s)" | tail -1 | awk '{for(i=1;i<=NF;i++) if($i~/st/) print $(i-1)}' | tr -d '%')
CPU_USED=$(echo "100 - ${CPU_IDLE:-0}" | bc 2>/dev/null || echo "N/A")

info "CPU Cores       : $CPU_CORES"
info "CPU Used        : ${CPU_USED}%  (user=${CPU_USER}% sys=${CPU_SYS}% iowait=${CPU_IOWAIT}% steal=${CPU_STEAL}%)"
divider

# CPU usage alert
if [ "$CPU_USED" != "N/A" ]; then
  CPU_INT=${CPU_USED%.*}
  if   [ "$CPU_INT" -ge "$CPU_CRIT" ]; then crit "CPU usage ${CPU_USED}% — server is overwhelmed! Find hog with: top -b -n1 | head -20"
  elif [ "$CPU_INT" -ge "$CPU_WARN" ]; then warn "CPU usage ${CPU_USED}% — getting busy"
  else ok "CPU usage ${CPU_USED}% is healthy"
  fi
fi

# iowait alert
IOWAIT_INT=${CPU_IOWAIT%.*}
if   [ "${IOWAIT_INT:-0}" -ge "$IOWAIT_CRIT" ]; then crit "%iowait ${CPU_IOWAIT}% — severe disk bottleneck! Run: iostat -x 1 5"
elif [ "${IOWAIT_INT:-0}" -ge "$IOWAIT_WARN" ]; then warn "%iowait ${CPU_IOWAIT}% — disk may be slow"
else ok "%iowait ${CPU_IOWAIT}% — no disk bottleneck"
fi

# steal alert
STEAL_INT=${CPU_STEAL%.*}
if   [ "${STEAL_INT:-0}" -ge 10 ]; then crit "%steal ${CPU_STEAL}% — VM host is starving this server!"
elif [ "${STEAL_INT:-0}" -ge 5  ]; then warn "%steal ${CPU_STEAL}% — VM host stealing some CPU"
else ok "%steal ${CPU_STEAL}% — no hypervisor interference"
fi

echo ""
info "Top 5 CPU-consuming processes:"
divider
ps aux --sort=-%cpu | awk 'NR==1{print "  "$0} NR>1 && NR<=6{printf "  %-10s %-8s %-6s %-6s %s\n",$1,$2,$3,$4,$11}'

# ============================================================
section "2. LOAD AVERAGE vs CPU CORES"
# ============================================================

LOAD1=$(cat /proc/loadavg | awk '{print $1}')
LOAD5=$(cat /proc/loadavg | awk '{print $2}')
LOAD15=$(cat /proc/loadavg | awk '{print $3}')
LOAD_CRIT_VAL=$(echo "$CPU_CORES * $LOAD_CRIT" | bc)
LOAD_WARN_VAL=$(echo "$CPU_CORES * $LOAD_WARN" | bc)

info "CPU Cores       : $CPU_CORES"
info "Load Average    : 1min=$LOAD1  5min=$LOAD5  15min=$LOAD15"
info "Healthy ceiling : ~$CPU_CORES (equal to core count)"
divider

check_load() {
  local val=$1 label=$2
  local int_val=${val%.*}
  local ceil_int=${LOAD_CRIT_VAL%.*}
  local warn_int=${LOAD_WARN_VAL%.*}
  if   (( $(echo "$val > $LOAD_CRIT_VAL" | bc -l) )); then crit "Load $label = $val > $LOAD_CRIT_VAL — system overloaded!"
  elif (( $(echo "$val > $LOAD_WARN_VAL" | bc -l) )); then warn "Load $label = $val — approaching limit"
  else ok "Load $label = $val — healthy"
  fi
}
check_load "$LOAD1"  "1min"
check_load "$LOAD5"  "5min"
check_load "$LOAD15" "15min"

# ============================================================
section "3. MEMORY ANALYSIS"
# ============================================================

MEM_TOTAL=$(free -m | awk '/^Mem/ {print $2}')
MEM_USED=$(free -m  | awk '/^Mem/ {print $3}')
MEM_FREE=$(free -m  | awk '/^Mem/ {print $4}')
MEM_CACHE=$(free -m | awk '/^Mem/ {print $6}')
MEM_PCT=$(awk "BEGIN {printf \"%.1f\", $MEM_USED/$MEM_TOTAL*100}")
SWAP_TOTAL=$(free -m | awk '/^Swap/ {print $2}')
SWAP_USED=$(free -m  | awk '/^Swap/ {print $3}')
SWAP_PCT=0
[ "$SWAP_TOTAL" -gt 0 ] && SWAP_PCT=$(awk "BEGIN {printf \"%.1f\", $SWAP_USED/$SWAP_TOTAL*100}")

info "Memory Total    : ${MEM_TOTAL} MB"
info "Memory Used     : ${MEM_USED} MB  (${MEM_PCT}%)"
info "Memory Free     : ${MEM_FREE} MB"
info "Buff/Cache      : ${MEM_CACHE} MB"
info "Swap Total      : ${SWAP_TOTAL} MB"
info "Swap Used       : ${SWAP_USED} MB  (${SWAP_PCT}%)"
divider

MEM_INT=${MEM_PCT%.*}
if   [ "$MEM_INT" -ge "$MEM_CRIT"  ]; then crit "Memory ${MEM_PCT}% used — OOM risk! Check: ps aux --sort=-%mem | head -10"
elif [ "$MEM_INT" -ge "$MEM_WARN"  ]; then warn "Memory ${MEM_PCT}% used — getting tight"
else ok "Memory ${MEM_PCT}% used — healthy"
fi

SWAP_INT=${SWAP_PCT%.*}
if   [ "$SWAP_INT" -ge "$SWAP_CRIT" ]; then crit "Swap ${SWAP_PCT}% used — system is swapping heavily, major slowdown!"
elif [ "$SWAP_INT" -ge "$SWAP_WARN" ]; then warn "Swap ${SWAP_PCT}% used — memory pressure building"
elif [ "$SWAP_TOTAL" -eq 0          ]; then warn "No swap configured — OOM killer will fire with no safety net"
else ok "Swap ${SWAP_PCT}% used — healthy"
fi

echo ""
info "Top 5 memory-consuming processes:"
divider
ps aux --sort=-%mem | awk 'NR==1{print "  "$0} NR>1 && NR<=6{printf "  %-10s %-8s %-6s %-6s %s\n",$1,$2,$3,$4,$11}'

# ============================================================
section "4. OOM (OUT OF MEMORY) CRASHES"
# ============================================================

OOM_COUNT=$(dmesg | grep -ic "oom\|out of memory\|killed process" 2>/dev/null || echo 0)
info "OOM events in dmesg : $OOM_COUNT"
divider

if [ "$OOM_COUNT" -gt 0 ]; then
  crit "OOM killer has fired $OOM_COUNT time(s)! Details:"
  dmesg | grep -i "oom\|out of memory\|killed process" | tail -10 | while read line; do
    echo "    $line"
  done
else
  ok "No OOM events detected in dmesg"
fi

# check journal OOM
JOUR_OOM=$(journalctl -k --since "24 hours ago" 2>/dev/null | grep -ic "oom\|killed process" || echo 0)
if [ "$JOUR_OOM" -gt 0 ]; then
  crit "OOM events in journal (last 24h): $JOUR_OOM"
else
  ok "No OOM events in journal (last 24h)"
fi

# ============================================================
section "5. DISK USAGE"
# ============================================================

info "Filesystem usage:"
divider
df -h | awk 'NR==1{print "  "$0}' 
df -h | tail -n +2 | while read line; do
  PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
  if [ "$PCT" != "-" ] && [ -n "$PCT" ]; then
    if   [ "$PCT" -ge "$DISK_CRIT" ]; then echo -e "  ${RED}[CRIT $PCT%]${RST} $line"
    elif [ "$PCT" -ge "$DISK_WARN" ]; then echo -e "  ${YEL}[WARN $PCT%]${RST} $line"
    else echo -e "  ${GRN}[  OK $PCT%]${RST} $line"
    fi
  fi
done

echo ""
info "Top 10 largest directories in /var:"
divider
du -h /var 2>/dev/null | sort -rh | head -10 | while read line; do echo "  $line"; done

echo ""
info "Top 10 largest files in /var:"
divider
find /var -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -10 | \
  awk '{printf "  %-12s %s\n", $1, $2}'

echo ""
info "Files larger than 100MB on system:"
divider
find / -type f -size +100M -printf '%s %p\n' 2>/dev/null | sort -rn | head -10 | \
  awk '{printf "  %-12s %s\n", $1, $2}'

# ============================================================
section "6. INODE HEALTH"
# ============================================================

info "Inode usage per filesystem:"
divider
df -i | awk 'NR==1{print "  "$0}'
df -i | tail -n +2 | while read line; do
  PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
  if [ "$PCT" != "-" ] && [ -n "$PCT" ]; then
    if   [ "$PCT" -ge "$INODE_CRIT" ]; then echo -e "  ${RED}[CRIT $PCT%]${RST} $line"
    elif [ "$PCT" -ge "$INODE_WARN" ]; then echo -e "  ${YEL}[WARN $PCT%]${RST} $line"
    else echo -e "  ${GRN}[  OK $PCT%]${RST} $line"
    fi
  fi
done

# ============================================================
section "7. DISK I/O PERFORMANCE"
# ============================================================

info "Running iostat (3 samples, 1 second apart)..."
divider
iostat -x 1 3 2>/dev/null | tail -n +4 | while read line; do
  echo "  $line"
  UTIL=$(echo "$line" | awk '{print $NF}' | tr -d '%')
  AWAIT=$(echo "$line" | awk '{print $10}')
  if echo "$UTIL" | grep -qE '^[0-9]+'; then
    if   (( $(echo "$UTIL >= $UTIL_CRIT" | bc -l 2>/dev/null) )); then crit "Disk util ${UTIL}% — disk saturated!"
    elif (( $(echo "$UTIL >= $UTIL_WARN" | bc -l 2>/dev/null) )); then warn "Disk util ${UTIL}% — getting busy"
    fi
  fi
done

# ============================================================
section "8. ZOMBIE PROCESSES"
# ============================================================

ZOMBIE_COUNT=$(ps aux | awk '{print $8}' | grep -c "^Z$" || echo 0)
info "Zombie processes : $ZOMBIE_COUNT"
divider

if [ "$ZOMBIE_COUNT" -gt 0 ]; then
  warn "Found $ZOMBIE_COUNT zombie process(es) — parent may have crashed:"
  ps aux | awk '$8=="Z" {print "  PID:"$2, "USER:"$1, "CMD:"$11}'
else
  ok "No zombie processes found"
fi

# ============================================================
section "9. CRASHED / FATAL SERVICES"
# ============================================================

info "Services that have crashed or failed:"
divider
systemctl list-units --type=service --state=failed 2>/dev/null | grep "●" | while read line; do
  crit "FAILED SERVICE: $line"
done

FAILED_COUNT=$(systemctl --failed --type=service 2>/dev/null | grep -c "●" || echo 0)
[ "$FAILED_COUNT" -eq 0 ] && ok "No failed services found" || crit "$FAILED_COUNT failed service(s) detected"

echo ""
info "Services that have restarted recently:"
divider
journalctl --since "1 hour ago" 2>/dev/null | grep -i "started\|restarted\|respawn" | tail -10 | while read line; do
  echo "  $line"
done

echo ""
info "FATAL errors in logs (last 10 min):"
divider
FATAL_COUNT=$(journalctl --since "10 minutes ago" 2>/dev/null | grep -ic "fatal\|FATAL" || echo 0)
if [ "$FATAL_COUNT" -gt 0 ]; then
  crit "Found $FATAL_COUNT FATAL entries in last 10 minutes:"
  journalctl --since "10 minutes ago" 2>/dev/null | grep -i "fatal\|FATAL" | tail -10 | while read line; do
    echo "    $line"
  done
else
  ok "No FATAL errors in last 10 minutes"
fi

# ============================================================
section "10. ERROR ANALYSIS — /var/log"
# ============================================================

info "Total errors in last 10 minutes (journalctl):"
divider
ERROR_COUNT=$(journalctl --since "10 minutes ago" -p err 2>/dev/null | grep -vc "^--" || echo 0)
if   [ "$ERROR_COUNT" -ge 50 ]; then crit "$ERROR_COUNT errors in last 10 min — system is struggling!"
elif [ "$ERROR_COUNT" -ge 10 ]; then warn "$ERROR_COUNT errors in last 10 min — needs attention"
else ok "$ERROR_COUNT errors in last 10 min — normal"
fi

echo ""
info "Error lines with 1 line before and 2 lines after (syslog):"
divider
if [ -f /var/log/syslog ]; then
  grep -n -i "error\|fatal\|critical" /var/log/syslog | tail -5 | while read match; do
    LINENUM=$(echo "$match" | cut -d: -f1)
    START=$((LINENUM - 1))
    END=$((LINENUM + 2))
    echo "  --- Error at line $LINENUM ---"
    sed -n "${START},${END}p" /var/log/syslog | while read l; do echo "    $l"; done
    echo ""
  done
else
  journalctl -p err --since "10 minutes ago" 2>/dev/null | tail -20 | while read line; do
    echo "  $line"
  done
fi

# ============================================================
section "11. OPEN FILES & FILE DESCRIPTORS"
# ============================================================

OPEN_FILES=$(lsof 2>/dev/null | wc -l)
info "Total open file descriptors : $OPEN_FILES"
divider

if   [ "$OPEN_FILES" -ge "$OFD_CRIT" ]; then crit "Open FDs $OPEN_FILES — file descriptor leak possible!"
elif [ "$OPEN_FILES" -ge "$OFD_WARN" ]; then warn "Open FDs $OPEN_FILES — getting high"
else ok "Open FDs $OPEN_FILES — healthy"
fi

info "System FD limit : $(cat /proc/sys/fs/file-max)"
info "Current FD usage: $(cat /proc/sys/fs/file-nr | awk '{print $1}')"

# ============================================================
section "12. LISTENING PORTS"
# ============================================================

info "All listening ports and services:"
divider
ss -tulnp 2>/dev/null | while read line; do echo "  $line"; done

# ============================================================
section "13. NETWORK HEALTH"
# ============================================================

info "Network connections summary:"
divider
ESTABLISHED=$(ss -an 2>/dev/null | grep -c ESTAB || echo 0)
TIME_WAIT=$(ss -an 2>/dev/null | grep -c TIME-WAIT || echo 0)
CLOSE_WAIT=$(ss -an 2>/dev/null | grep -c CLOSE-WAIT || echo 0)

info "ESTABLISHED  : $ESTABLISHED"
info "TIME_WAIT    : $TIME_WAIT"
info "CLOSE_WAIT   : $CLOSE_WAIT"

[ "$TIME_WAIT"  -gt 100 ] && warn "High TIME_WAIT ($TIME_WAIT) — possible connection leak"
[ "$CLOSE_WAIT" -gt 50  ] && crit "High CLOSE_WAIT ($CLOSE_WAIT) — app not closing connections!"

echo ""
info "Ping test (gateway):"
GW=$(ip route | awk '/default/ {print $3}' | head -1)
if [ -n "$GW" ]; then
  PING_RESULT=$(ping -c 4 "$GW" 2>/dev/null | tail -2)
  PACKET_LOSS=$(echo "$PING_RESULT" | grep -oP '\d+(?=% packet loss)')
  if   [ "${PACKET_LOSS:-0}" -ge 50 ]; then crit "Packet loss ${PACKET_LOSS}% to gateway $GW"
  elif [ "${PACKET_LOSS:-0}" -ge 10 ]; then warn "Packet loss ${PACKET_LOSS}% to gateway $GW"
  else ok "No packet loss to gateway $GW"
  fi
  echo "  $PING_RESULT"
else
  warn "Could not determine default gateway"
fi

# ============================================================
section "14. SYSTEMD SERVICES STATUS"
# ============================================================

info "Enabled services:"
divider
systemctl list-unit-files --type=service --state=enabled 2>/dev/null | grep enabled | while read line; do
  SVC=$(echo "$line" | awk '{print $1}')
  STATUS=$(systemctl is-active "$SVC" 2>/dev/null)
  if [ "$STATUS" = "active" ]; then
    echo -e "  ${GRN}[active  ]${RST} $SVC"
  else
    echo -e "  ${RED}[inactive]${RST} $SVC  ← not running!"
  fi
done

# ============================================================
section "15. TOP DIRECTORY MEMORY / DISK CONSUMERS"
# ============================================================

info "Top 10 directories consuming disk (entire system):"
divider
du -h --max-depth=2 / 2>/dev/null | sort -rh | head -10 | while read line; do
  echo "  $line"
done

# ============================================================
section "16. VMSTAT SNAPSHOT"
# ============================================================

info "vmstat — virtual memory, processes, I/O, CPU:"
divider
vmstat 1 3 2>/dev/null | while read line; do echo "  $line"; done
echo ""
info "Column guide: r=run queue, b=blocked, si/so=swap in/out, bi/bo=block in/out, wa=iowait"
SWAP_IN=$(vmstat 1 2 2>/dev/null | tail -1 | awk '{print $7}')
SWAP_OUT=$(vmstat 1 2 2>/dev/null | tail -1 | awk '{print $8}')
[ "${SWAP_IN:-0}"  -gt 0 ] && warn "Swap-in activity detected ($SWAP_IN) — memory pressure!"
[ "${SWAP_OUT:-0}" -gt 0 ] && warn "Swap-out activity detected ($SWAP_OUT) — paging to disk!"

# ============================================================
section "17. ANALYSIS SUMMARY TABLE"
# ============================================================

printf "\n  %-30s %-15s %-10s %s\n" "METRIC" "VALUE" "STATUS" "THRESHOLD"
printf "  %-30s %-15s %-10s %s\n"  "------------------------------" "---------------" "----------" "---------"

print_row() {
  local metric=$1 value=$2 status=$3 threshold=$4
  if   [ "$status" = "CRIT" ]; then printf "  ${RED}%-30s %-15s %-10s %s${RST}\n" "$metric" "$value" "🔴 CRIT" "$threshold"
  elif [ "$status" = "WARN" ]; then printf "  ${YEL}%-30s %-15s %-10s %s${RST}\n" "$metric" "$value" "⚠️  WARN" "$threshold"
  else                               printf "  ${GRN}%-30s %-15s %-10s %s${RST}\n" "$metric" "$value" "✅ OK"   "$threshold"
  fi
}

# CPU
CPU_INT=${CPU_USED%.*}
CPU_STATUS="OK"
[ "${CPU_INT:-0}" -ge "$CPU_WARN" ] && CPU_STATUS="WARN"
[ "${CPU_INT:-0}" -ge "$CPU_CRIT" ] && CPU_STATUS="CRIT"
print_row "CPU Usage" "${CPU_USED}%" "$CPU_STATUS" "warn>${CPU_WARN}% crit>${CPU_CRIT}%"

# iowait
IOWAIT_STATUS="OK"
[ "${IOWAIT_INT:-0}" -ge "$IOWAIT_WARN" ] && IOWAIT_STATUS="WARN"
[ "${IOWAIT_INT:-0}" -ge "$IOWAIT_CRIT" ] && IOWAIT_STATUS="CRIT"
print_row "CPU iowait" "${CPU_IOWAIT}%" "$IOWAIT_STATUS" "warn>${IOWAIT_WARN}% crit>${IOWAIT_CRIT}%"

# steal
STEAL_STATUS="OK"
[ "${STEAL_INT:-0}" -ge 5  ] && STEAL_STATUS="WARN"
[ "${STEAL_INT:-0}" -ge 10 ] && STEAL_STATUS="CRIT"
print_row "CPU Steal (VM)" "${CPU_STEAL}%" "$STEAL_STATUS" "warn>5% crit>10%"

# load avg
LOAD_STATUS="OK"
(( $(echo "$LOAD1 > $LOAD_WARN_VAL" | bc -l) )) && LOAD_STATUS="WARN"
(( $(echo "$LOAD1 > $LOAD_CRIT_VAL" | bc -l) )) && LOAD_STATUS="CRIT"
print_row "Load Avg (1min)" "$LOAD1" "$LOAD_STATUS" "warn>${LOAD_WARN_VAL} crit>${LOAD_CRIT_VAL}"

# memory
MEM_STATUS="OK"
MEM_INT=${MEM_PCT%.*}
[ "${MEM_INT:-0}" -ge "$MEM_WARN" ] && MEM_STATUS="WARN"
[ "${MEM_INT:-0}" -ge "$MEM_CRIT" ] && MEM_STATUS="CRIT"
print_row "Memory Usage" "${MEM_PCT}%" "$MEM_STATUS" "warn>${MEM_WARN}% crit>${MEM_CRIT}%"

# swap
SWAP_STATUS="OK"
SWAP_INT=${SWAP_PCT%.*}
[ "${SWAP_INT:-0}" -ge "$SWAP_WARN" ] && SWAP_STATUS="WARN"
[ "${SWAP_INT:-0}" -ge "$SWAP_CRIT" ] && SWAP_STATUS="CRIT"
print_row "Swap Usage" "${SWAP_PCT}%" "$SWAP_STATUS" "warn>${SWAP_WARN}% crit>${SWAP_CRIT}%"

# OOM
OOM_STATUS="OK"
[ "${OOM_COUNT:-0}" -gt 0 ] && OOM_STATUS="CRIT"
print_row "OOM Crashes" "$OOM_COUNT events" "$OOM_STATUS" "crit>0"

# zombies
ZOMBIE_STATUS="OK"
[ "${ZOMBIE_COUNT:-0}" -gt 0 ] && ZOMBIE_STATUS="WARN"
print_row "Zombie Processes" "$ZOMBIE_COUNT" "$ZOMBIE_STATUS" "warn>0"

# failed services
FAIL_STATUS="OK"
[ "${FAILED_COUNT:-0}" -gt 0 ] && FAIL_STATUS="CRIT"
print_row "Failed Services" "$FAILED_COUNT" "$FAIL_STATUS" "crit>0"

# fatal errors
FATAL_STATUS="OK"
[ "${FATAL_COUNT:-0}" -ge 1  ] && FATAL_STATUS="WARN"
[ "${FATAL_COUNT:-0}" -ge 10 ] && FATAL_STATUS="CRIT"
print_row "FATAL Errors (10min)" "$FATAL_COUNT" "$FATAL_STATUS" "warn>1 crit>10"

# total errors
ERR_STATUS="OK"
[ "${ERROR_COUNT:-0}" -ge 10 ] && ERR_STATUS="WARN"
[ "${ERROR_COUNT:-0}" -ge 50 ] && ERR_STATUS="CRIT"
print_row "Total Errors (10min)" "$ERROR_COUNT" "$ERR_STATUS" "warn>10 crit>50"

# open files
OFD_STATUS="OK"
[ "${OPEN_FILES:-0}" -ge "$OFD_WARN" ] && OFD_STATUS="WARN"
[ "${OPEN_FILES:-0}" -ge "$OFD_CRIT" ] && OFD_STATUS="CRIT"
print_row "Open File Descriptors" "$OPEN_FILES" "$OFD_STATUS" "warn>${OFD_WARN} crit>${OFD_CRIT}"

# connections
CW_STATUS="OK"
[ "${CLOSE_WAIT:-0}" -gt 50  ] && CW_STATUS="CRIT"
[ "${TIME_WAIT:-0}"  -gt 100 ] && TW_STATUS="WARN" || TW_STATUS="OK"
print_row "CLOSE_WAIT conns" "$CLOSE_WAIT" "$CW_STATUS" "crit>50"
print_row "TIME_WAIT conns" "$TIME_WAIT" "${TW_STATUS:-OK}" "warn>100"

# disk (root)
ROOT_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
ROOT_STATUS="OK"
[ "${ROOT_PCT:-0}" -ge "$DISK_WARN" ] && ROOT_STATUS="WARN"
[ "${ROOT_PCT:-0}" -ge "$DISK_CRIT" ] && ROOT_STATUS="CRIT"
print_row "Disk Usage (/)" "${ROOT_PCT}%" "$ROOT_STATUS" "warn>${DISK_WARN}% crit>${DISK_CRIT}%"

# inode
ROOT_INODE=$(df -i / | tail -1 | awk '{print $5}' | tr -d '%')
INODE_STATUS="OK"
[ "${ROOT_INODE:-0}" -ge "$INODE_WARN" ] && INODE_STATUS="WARN"
[ "${ROOT_INODE:-0}" -ge "$INODE_CRIT" ] && INODE_STATUS="CRIT"
print_row "Inode Usage (/)" "${ROOT_INODE}%" "$INODE_STATUS" "warn>${INODE_WARN}% crit>${INODE_CRIT}%"

# ============================================================
echo ""
echo -e "  ${BLD}Report saved to: $REPORT${RST}"
echo -e "  ${BLD}Generated at   : $(date)${RST}"
echo ""
