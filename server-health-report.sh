#!/bin/bash
# ============================================================
#  SERVER HEALTH REPORT
#  Run as root: bash server_health_report.sh
#  Output: /opt/server-health/logs/health_report_<date>.txt
# ============================================================

# ---------- COLORS ----------
RED='\033[0;31m'
YEL='\033[0;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BLD='\033[1m'
RST='\033[0m'

# ---------- OUTPUT FILE ----------
REPORT_DIR="/opt/server-health/logs"
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
fix() {
  echo -e "  ${YEL}${BLD}  ▶ RECOMMENDED STEPS:${RST}"
  while IFS= read -r step; do
    echo -e "  ${YEL}    $step${RST}"
  done <<< "$1"
  echo ""
}

# BUG FIX: safe integer conversion — strips decimals, handles empty/multiline values
to_int() {
  local val
  val=$(echo "${1}" | head -1 | tr -d '\n' | grep -oE '^[0-9]+' )
  echo "${val:-0}"
}

# ---------- THRESHOLDS ----------
CPU_WARN=70;        CPU_CRIT=90
MEM_WARN=75;        MEM_CRIT=90
SWAP_WARN=40;       SWAP_CRIT=80
DISK_WARN=80;       DISK_CRIT=90
IOWAIT_WARN=10;     IOWAIT_CRIT=25
UTIL_WARN=70;       UTIL_CRIT=85
INODE_WARN=80;      INODE_CRIT=90
OFD_WARN=10000;     OFD_CRIT=50000
LOAD_WARN=0.8;      LOAD_CRIT=1.2   # multiplier of core count

# ============================================================
echo ""
echo -e "${BLD}  SERVER HEALTH REPORT${RST}"
echo -e "  Generated : $(date)"
echo -e "  Hostname  : $(hostname)"
echo -e "  Uptime    : $(uptime -p)"
echo -e "  Kernel    : $(uname -r)"
echo ""

# ============================================================
section "1. CPU ANALYSIS"
# ============================================================

CPU_CORES=$(nproc)

# BUG FIX: capture top output once to avoid multiple slow calls
TOP_OUTPUT=$(top -b -n 2 -d 0.5 2>/dev/null | grep "Cpu(s)" | tail -1)
CPU_IDLE=$(echo "$TOP_OUTPUT"   | awk '{for(i=1;i<=NF;i++) if($i~/id,/) print $(i-1)}' | tr -d '%')
CPU_IOWAIT=$(echo "$TOP_OUTPUT" | awk '{for(i=1;i<=NF;i++) if($i~/wa,/) print $(i-1)}' | tr -d '%')
CPU_USER=$(echo "$TOP_OUTPUT"   | awk '{for(i=1;i<=NF;i++) if($i~/us,/) print $(i-1)}' | tr -d '%')
CPU_SYS=$(echo "$TOP_OUTPUT"    | awk '{for(i=1;i<=NF;i++) if($i~/sy,/) print $(i-1)}' | tr -d '%')
CPU_STEAL=$(echo "$TOP_OUTPUT"  | awk '{for(i=1;i<=NF;i++) if($i~/st/) print $(i-1)}' | tr -d '%')

CPU_IDLE=${CPU_IDLE:-0}
CPU_IOWAIT=${CPU_IOWAIT:-0}
CPU_STEAL=${CPU_STEAL:-0}
CPU_USED=$(echo "100 - ${CPU_IDLE}" | bc 2>/dev/null || echo "0")
CPU_USED=${CPU_USED:-0}

info "CPU Cores       : $CPU_CORES"
info "CPU Used        : ${CPU_USED}%  (user=${CPU_USER:-0}% sys=${CPU_SYS:-0}% iowait=${CPU_IOWAIT}% steal=${CPU_STEAL}%)"
divider

CPU_INT=$(to_int "$CPU_USED")
IOWAIT_INT=$(to_int "$CPU_IOWAIT")
STEAL_INT=$(to_int "$CPU_STEAL")

if [ "$CPU_INT" -ge "$CPU_CRIT" ]; then
  crit "CPU usage ${CPU_USED}% — server is overwhelmed!"
  fix "1. Find the hog:            ps aux --sort=-%cpu | head -10
2. Watch it live:            top -b -n 1 | head -20
3. Trace what it is doing:   strace -p <PID>
4. Graceful restart:         systemctl restart <service>
5. Force kill (last resort): kill -9 <PID>"
elif [ "$CPU_INT" -ge "$CPU_WARN" ]; then
  warn "CPU usage ${CPU_USED}% — getting busy"
  fix "1. Monitor trend:           top -b -n 5 -d 2
2. Identify top process:    ps aux --sort=-%cpu | head -5
3. Check if scheduled job:  crontab -l && cat /etc/cron.d/*"
else
  ok "CPU usage ${CPU_USED}% is healthy"
fi

if [ "$IOWAIT_INT" -ge "$IOWAIT_CRIT" ]; then
  crit "%iowait ${CPU_IOWAIT}% — severe disk bottleneck!"
  fix "1. Confirm which disk:       iostat -x 1 5
2. Find disk hog process:    iotop -o   (apt install iotop)
3. Check disk utilisation:   iostat -x 1 | grep -v loop
4. Check if logs filling:    du -h /opt/server-health/logs | sort -rh | head -10
5. Check disk health:        smartctl -a /dev/sda
6. Free up space:            find /opt/server-health/logs -name '*.log' -mtime +7 -delete
7. Clear journal logs:       journalctl --vacuum-time=3d"
elif [ "$IOWAIT_INT" -ge "$IOWAIT_WARN" ]; then
  warn "%iowait ${CPU_IOWAIT}% — disk may be slow"
  fix "1. Watch disk I/O:           iostat -x 1 5
2. Find writing processes:   iotop -o
3. Check log growth:         ls -lth /opt/server-health/logs/ | head -10"
else
  ok "%iowait ${CPU_IOWAIT}% — no disk bottleneck"
fi

if [ "$STEAL_INT" -ge 10 ]; then
  crit "%steal ${CPU_STEAL}% — VM host is starving this server!"
  fix "1. Confirm steal over time:  vmstat 1 10 | awk '{print \$17}'
2. Check cloud console:      look for host CPU saturation metrics
3. Consider dedicated host:  contact cloud provider support
4. Reduce VM load short term: systemctl stop <non-critical-service>"
elif [ "$STEAL_INT" -ge 5 ]; then
  warn "%steal ${CPU_STEAL}% — VM host stealing some CPU"
  fix "1. Monitor trend:            sar -u 1 10   (apt install sysstat)
2. Check cloud host metrics: via cloud provider console
3. Open support ticket if sustained above 5%"
else
  ok "%steal ${CPU_STEAL}% — no hypervisor interference"
fi

echo ""
info "Top 5 CPU-consuming processes:"
divider
ps aux --sort=-%cpu | awk 'NR==1{print "  "$0} NR>1 && NR<=6{printf "  %-10s %-8s %-6s %-6s %s\n",$1,$2,$3,$4,$11}'

# ============================================================
section "2. LOAD AVERAGE vs CPU CORES"
# ============================================================

LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD5=$(awk '{print $2}' /proc/loadavg)
LOAD15=$(awk '{print $3}' /proc/loadavg)
LOAD_CRIT_VAL=$(echo "$CPU_CORES * $LOAD_CRIT" | bc)
LOAD_WARN_VAL=$(echo "$CPU_CORES * $LOAD_WARN" | bc)

info "CPU Cores       : $CPU_CORES"
info "Load Average    : 1min=$LOAD1  5min=$LOAD5  15min=$LOAD15"
info "Healthy ceiling : ~$CPU_CORES (equal to core count)"
divider

check_load() {
  local val=$1 label=$2
  if (( $(echo "$val > $LOAD_CRIT_VAL" | bc -l) )); then
    crit "Load $label = $val > $LOAD_CRIT_VAL — system overloaded!"
    fix "1. Check run queue:         vmstat 1 5  (column 'r' = waiting processes)
2. Find blocked processes:  ps aux | awk '\$8==\"D\"'
3. Check if iowait is high: top -b -n1 | grep Cpu  (wa column)
4. Find top CPU hogs:       ps aux --sort=-%cpu | head -10
5. Check for runaway loop:  strace -p <PID>
6. Restart offending svc:   systemctl restart <service>"
  elif (( $(echo "$val > $LOAD_WARN_VAL" | bc -l) )); then
    warn "Load $label = $val — approaching limit"
    fix "1. Watch trend:              uptime  (run again in 1 min)
2. Check what is running:   ps aux --sort=-%cpu | head -10
3. Check iowait:            iostat -x 1 3"
  else
    ok "Load $label = $val — healthy"
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

MEM_INT=$(to_int "$MEM_PCT")
SWAP_INT=$(to_int "$SWAP_PCT")

if [ "$MEM_INT" -ge "$MEM_CRIT" ]; then
  crit "Memory ${MEM_PCT}% used — OOM risk!"
  fix "1. Find memory hogs:         ps aux --sort=-%mem | head -10
2. Check OOM score:          cat /proc/<PID>/oom_score
3. Check per-process mem:    cat /proc/<PID>/status | grep -E 'VmRSS|VmSwap|VmPeak'
4. Restart leaking service:  systemctl restart <service>
5. Drop page cache safely:   echo 1 > /proc/sys/vm/drop_caches
6. Run swap setup script:    bash add_swap.sh"
elif [ "$MEM_INT" -ge "$MEM_WARN" ]; then
  warn "Memory ${MEM_PCT}% used — getting tight"
  fix "1. Watch memory trend:       watch -n 2 free -h
2. Find top consumers:      ps aux --sort=-%mem | head -5
3. Check for memory leaks:  cat /proc/<PID>/status | grep VmRSS"
else
  ok "Memory ${MEM_PCT}% used — healthy"
fi

if [ "$SWAP_INT" -ge "$SWAP_CRIT" ]; then
  crit "Swap ${SWAP_PCT}% used — system is swapping heavily, major slowdown!"
  fix "1. Confirm swapping:         vmstat 1 5  (si/so columns should be 0)
2. Find memory hog:          ps aux --sort=-%mem | head -10
3. Restart leaking service:  systemctl restart <service>
4. Reduce swappiness:        echo 10 > /proc/sys/vm/swappiness
5. Kill non-critical proc:   kill -15 <PID>
6. Contact senior engineer immediately"
elif [ "$SWAP_INT" -ge "$SWAP_WARN" ]; then
  warn "Swap ${SWAP_PCT}% used — memory pressure building"
  fix "1. Check what is in swap:    smem -s swap   (apt install smem)
2. Find memory hogs:         ps aux --sort=-%mem | head -5
3. Monitor swap activity:    vmstat 1 5  (watch si/so columns)"
elif [ "$SWAP_TOTAL" -eq 0 ]; then
  warn "No swap configured — OOM killer will fire with no safety net"
  fix "1. Run the swap setup script: bash add_swap.sh
2. Or add manually:
   fallocate -l 2G /swapfile && chmod 600 /swapfile
   mkswap /swapfile && swapon /swapfile
   echo '/swapfile none swap sw 0 0' >> /etc/fstab"
else
  ok "Swap ${SWAP_PCT}% used — healthy"
fi

echo ""
info "Top 5 memory-consuming processes:"
divider
ps aux --sort=-%mem | awk 'NR==1{print "  "$0} NR>1 && NR<=6{printf "  %-10s %-8s %-6s %-6s %s\n",$1,$2,$3,$4,$11}'

# ============================================================
section "4. OOM (OUT OF MEMORY) CRASHES"
# ============================================================

OOM_COUNT=$(dmesg | grep -ic "oom\|out of memory\|killed process" 2>/dev/null)
OOM_COUNT=$(to_int "${OOM_COUNT:-0}")
info "OOM events in dmesg : $OOM_COUNT"
divider

if [ "$OOM_COUNT" -gt 0 ]; then
  crit "OOM killer has fired $OOM_COUNT time(s)! Details:"
  dmesg | grep -i "oom\|out of memory\|killed process" | tail -10 | while IFS= read -r line; do
    echo "    $line"
  done
  fix "1. See what was killed:      dmesg | grep -i 'killed process'
2. Check memory hogs now:    ps aux --sort=-%mem | head -10
3. Check OOM scores:         cat /proc/<PID>/oom_score
4. Protect critical service: echo -1000 > /proc/<PID>/oom_score_adj
5. Run swap setup script:    bash add_swap.sh
6. Restart killed service:   systemctl restart <service>"
else
  ok "No OOM events detected in dmesg"
fi

JOUR_OOM=$(journalctl -k --since "24 hours ago" 2>/dev/null | grep -ic "oom\|killed process")
JOUR_OOM=$(to_int "${JOUR_OOM:-0}")
if [ "$JOUR_OOM" -gt 0 ]; then
  crit "OOM events in journal (last 24h): $JOUR_OOM"
  fix "1. See full OOM history:     journalctl -k --since '24 hours ago' | grep -i oom
2. Identify pattern:         check if OOM repeats at same time (cron job?)
3. Review memory limits:     systemctl show <service> | grep -i memory"
else
  ok "No OOM events in journal (last 24h)"
fi

# ============================================================
section "5. DISK USAGE"
# ============================================================

info "Filesystem usage:"
divider
df -h | awk 'NR==1{print "  "$0}'
df -h | tail -n +2 | while IFS= read -r line; do
  PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
  MNT=$(echo "$line" | awk '{print $6}')
  if [ "$PCT" != "-" ] && [ -n "$PCT" ] && echo "$PCT" | grep -qE '^[0-9]+$'; then
    if [ "$PCT" -ge "$DISK_CRIT" ]; then
      echo -e "  ${RED}[CRIT $PCT%]${RST} $line"
      echo -e "  ${YEL}    1. Find largest dirs:   du -h $MNT | sort -rh | head -10${RST}"
      echo -e "  ${YEL}    2. Find largest files:  find $MNT -type f -size +100M${RST}"
      echo -e "  ${YEL}    3. Clean old logs:      find $MNT -name '*.log' -mtime +7 -delete${RST}"
      echo -e "  ${YEL}    4. Clear journal:       journalctl --vacuum-size=500M${RST}"
      echo -e "  ${YEL}    5. Clear apt cache:     apt clean${RST}"
      echo -e "  ${YEL}    6. Check open deleted:  lsof | grep deleted | head -20${RST}"
      echo ""
    elif [ "$PCT" -ge "$DISK_WARN" ]; then
      echo -e "  ${YEL}[WARN $PCT%]${RST} $line"
      echo -e "  ${YEL}    ▶ Review: du -h $MNT | sort -rh | head -10${RST}"
      echo ""
    else
      echo -e "  ${GRN}[  OK $PCT%]${RST} $line"
    fi
  fi
done

echo ""
info "Top 10 largest directories in /var:"
divider
du -h /var 2>/dev/null | sort -rh | head -10 | while IFS= read -r line; do echo "  $line"; done

echo ""
info "Top 10 largest files in /var:"
divider
find /var -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -10 | \
  awk '{printf "  %-12s %s\n", $1, $2}'

echo ""
info "Files larger than 100MB on system:"
divider
find / -type f -size +100M -not -path "/proc/*" -printf '%s %p\n' 2>/dev/null | sort -rn | head -10 | \
  awk '{printf "  %-12s %s\n", $1, $2}'

# ============================================================
section "6. INODE HEALTH"
# ============================================================

info "Inode usage per filesystem:"
divider
df -i | awk 'NR==1{print "  "$0}'
df -i | tail -n +2 | while IFS= read -r line; do
  PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
  MNT=$(echo "$line" | awk '{print $6}')
  if [ "$PCT" != "-" ] && [ -n "$PCT" ] && echo "$PCT" | grep -qE '^[0-9]+$'; then
    if [ "$PCT" -ge "$INODE_CRIT" ]; then
      echo -e "  ${RED}[CRIT $PCT%]${RST} $line"
      echo -e "  ${RED}  ▶ INODE EXHAUSTION on $MNT${RST}"
      echo -e "  ${YEL}    1. Find inode hog dirs:  for d in $MNT/*/; do echo \$(find \$d | wc -l) \$d; done | sort -rn | head -10${RST}"
      echo -e "  ${YEL}    2. Delete old log files: find $MNT -name '*.log' -mtime +7 -delete${RST}"
      echo -e "  ${YEL}    3. Delete old tmp files: find /tmp -mtime +3 -delete${RST}"
      echo -e "  ${YEL}    4. Check for mail spool: ls -la /var/spool/mail/${RST}"
      echo ""
    elif [ "$PCT" -ge "$INODE_WARN" ]; then
      echo -e "  ${YEL}[WARN $PCT%]${RST} $line"
      echo -e "  ${YEL}    ▶ Start cleaning: find $MNT -name '*.log' -mtime +7 -delete${RST}"
      echo ""
    else
      echo -e "  ${GRN}[  OK $PCT%]${RST} $line"
    fi
  fi
done

# ============================================================
section "7. DISK I/O PERFORMANCE"
# ============================================================

info "Running iostat (3 samples, 1 second apart)..."
divider

# BUG FIX: collect full iostat output first, display it, then parse device lines only
IOSTAT_OUT=$(iostat -x 1 3 2>/dev/null)
echo "$IOSTAT_OUT" | while IFS= read -r line; do echo "  $line"; done

echo ""
info "Disk utilisation per device:"
divider

# BUG FIX: match only real disk device lines (sda, vda, nvme, etc), extract %util (last column)
echo "$IOSTAT_OUT" | awk '/^(sd[a-z]|vd[a-z]|nvme|xvd[a-z]|hd[a-z])/{print $1, $NF}' | \
while IFS= read -r devline; do
  DEV=$(echo "$devline" | awk '{print $1}')
  UTIL=$(echo "$devline" | awk '{print $2}')
  UTIL_INT=$(to_int "$UTIL")
  if [ "$UTIL_INT" -ge "$UTIL_CRIT" ]; then
    crit "Device $DEV — disk util ${UTIL}% — disk saturated!"
    fix "1. Find disk hog:            iotop -o   (apt install iotop)
2. Check write latency:      iostat -x 1 5 | grep $DEV
3. Check log file growth:    du -h /opt/server-health/logs | sort -rh | head -5
4. Clean old logs:           find /opt/server-health/logs -name '*.log' -mtime +7 -delete
5. Check disk health:        smartctl -a /dev/$DEV
6. Escalate to senior engineer if hardware issue"
  elif [ "$UTIL_INT" -ge "$UTIL_WARN" ]; then
    warn "Device $DEV — disk util ${UTIL}% — getting busy"
    fix "1. Watch I/O live:           iostat -x 1 5
2. Find writing process:     iotop -o"
  else
    ok "Device $DEV — disk util ${UTIL}% — healthy"
  fi
done

# ============================================================
section "8. ZOMBIE PROCESSES"
# ============================================================

ZOMBIE_COUNT=$(ps aux | awk '{print $8}' | grep -c "^Z$")
ZOMBIE_COUNT=$(to_int "${ZOMBIE_COUNT:-0}")
info "Zombie processes : $ZOMBIE_COUNT"
divider

if [ "$ZOMBIE_COUNT" -gt 0 ]; then
  warn "Found $ZOMBIE_COUNT zombie process(es) — parent may have crashed:"
  ps aux | awk '$8=="Z" {print "  PID:"$2, "USER:"$1, "CMD:"$11}'
  fix "1. Find zombie PID:          ps aux | awk '\$8==\"Z\"'
2. Find its parent (PPID):   ps -o ppid= -p <ZOMBIE_PID>
3. Restart the parent:       systemctl restart <parent-service>
4. Graceful kill parent:     kill -15 <PARENT_PID>
5. Force kill parent:        kill -9 <PARENT_PID>
   NOTE: Zombies cannot be killed directly — killing the parent cleans them up."
else
  ok "No zombie processes found"
fi

# ============================================================
section "9. CRASHED / FATAL SERVICES"
# ============================================================

info "Services that have crashed or failed:"
divider
systemctl list-units --type=service --state=failed 2>/dev/null | grep "●" | while IFS= read -r line; do
  crit "FAILED SERVICE: $line"
done

FAILED_COUNT=$(systemctl --failed --type=service 2>/dev/null | grep -c "●")
FAILED_COUNT=$(to_int "${FAILED_COUNT:-0}")

if [ "$FAILED_COUNT" -gt 0 ]; then
  crit "$FAILED_COUNT failed service(s) detected"
  fix "1. See all failed:           systemctl --failed
2. Read service logs:        journalctl -u <service> -n 50
3. Check why it failed:      systemctl status <service>
4. Attempt restart:          systemctl restart <service>
5. Check start deps:         systemctl list-dependencies <service>
6. Reset failed state:       systemctl reset-failed <service>
7. Escalate to senior engineer if unresolved"
else
  ok "No failed services found"
fi

echo ""
info "Services that have restarted recently:"
divider
journalctl --since "1 hour ago" 2>/dev/null | grep -i "started\|restarted\|respawn" | tail -10 | while IFS= read -r line; do
  echo "  $line"
done

echo ""
info "FATAL errors in logs (last 10 min):"
divider
FATAL_COUNT=$(journalctl --since "10 minutes ago" 2>/dev/null | grep -ic "fatal\|FATAL")
FATAL_COUNT=$(to_int "${FATAL_COUNT:-0}")

if [ "$FATAL_COUNT" -gt 0 ]; then
  crit "Found $FATAL_COUNT FATAL entries in last 10 minutes:"
  journalctl --since "10 minutes ago" 2>/dev/null | grep -i "fatal\|FATAL" | tail -10 | while IFS= read -r line; do
    echo "    $line"
  done
  fix "1. Read full context:        journalctl -u <service> --since '10 minutes ago'
2. Check which service:      journalctl -p crit --since '10 minutes ago'
3. Check logs:               tail -50 /opt/server-health/logs/*.log | grep -i fatal
4. Restart affected svc:     systemctl restart <service>
5. If recurring FATAL:       escalate — do not just restart in a loop"
else
  ok "No FATAL errors in last 10 minutes"
fi

# ============================================================
section "10. ERROR ANALYSIS — /var/log"
# ============================================================

info "Total errors in last 10 minutes (journalctl):"
divider
ERROR_COUNT=$(journalctl --since "10 minutes ago" -p err 2>/dev/null | grep -vc "^--")
ERROR_COUNT=$(to_int "${ERROR_COUNT:-0}")

if [ "$ERROR_COUNT" -ge 50 ]; then
  crit "$ERROR_COUNT errors in last 10 min — system is struggling!"
  fix "1. See all errors:           journalctl -p err --since '10 minutes ago'
2. Find which service:       journalctl -p err --since '10 minutes ago' | awk '{print \$5}' | sort | uniq -c | sort -rn
3. Check logs:               grep -i error /opt/server-health/logs/*.log | tail -20
4. Watch live errors:        journalctl -f -p err
5. Escalate if unresolved:   contact senior engineer"
elif [ "$ERROR_COUNT" -ge 10 ]; then
  warn "$ERROR_COUNT errors in last 10 min — needs attention"
  fix "1. Review errors:            journalctl -p err --since '10 minutes ago' | tail -20
2. Identify source service:  journalctl -p err --since '10 minutes ago' | grep -oP 'unit=\S+'"
else
  ok "$ERROR_COUNT errors in last 10 min — normal"
fi

echo ""
info "Error lines with 1 line before and 2 lines after:"
divider

if [ -f /var/log/syslog ]; then
  info "Source file : /var/log/syslog"
  divider
  grep -n -i "error\|fatal\|critical" /var/log/syslog | tail -5 | while IFS= read -r match; do
    LINENUM=$(echo "$match" | cut -d: -f1)
    # Extract the service/process name from the matching line (field between hostname and colon)
    SERVICE=$(echo "$match" | awk '{for(i=1;i<=NF;i++) if($i~/\[/ || $i~/:$/) {gsub(/\[.*|\]/,"",$i); gsub(/:$/,"",$i); print $i; exit}}')
    START=$((LINENUM - 1))
    END=$((LINENUM + 2))
    echo -e "  ${YEL}--- Line $LINENUM | Source: /var/log/syslog | Process: ${SERVICE:-unknown} ---${RST}"
    sed -n "${START},${END}p" /var/log/syslog | while IFS= read -r l; do echo "    $l"; done
    echo ""
  done
else
  # journalctl path — show unit name clearly for each error
  info "Source file : journalctl (no /var/log/syslog found)"
  divider
  journalctl -p err --since "10 minutes ago" -o verbose 2>/dev/null | \
    grep -E "^    (MESSAGE|_SYSTEMD_UNIT|SYSLOG_IDENTIFIER|_EXE)" | \
    paste - - - - 2>/dev/null | head -10 | while IFS= read -r line; do
      echo "  $line"
  done

  # Fallback: plain output with unit highlighted
  echo ""
  info "Full error entries (last 10 min):"
  divider
  journalctl -p err --since "10 minutes ago" --no-pager 2>/dev/null | grep -v "^--" | \
    tail -20 | while IFS= read -r line; do
      # Extract unit/service from journalctl line (format: date host unit[pid]: message)
      UNIT=$(echo "$line" | awk '{print $5}' | sed 's/\[.*//' | sed 's/://')
      echo -e "  ${YEL}[src: ${UNIT:-unknown}]${RST} $line"
  done
fi

# Always show a per-service error breakdown for the last 10 min
echo ""
info "Errors per service (last 10 min):"
divider
journalctl -p err --since "10 minutes ago" --no-pager 2>/dev/null | grep -v "^--" | \
  awk '{print $5}' | sed 's/\[.*//' | sed 's/://' | sort | uniq -c | sort -rn | \
  while IFS= read -r line; do
    COUNT=$(echo "$line" | awk '{print $1}')
    SVC=$(echo "$line" | awk '{print $2}')
    if [ "$COUNT" -ge 5 ]; then
      echo -e "  ${RED}  $COUNT errors${RST}  from  ${BLD}$SVC${RST}"
    elif [ "$COUNT" -ge 2 ]; then
      echo -e "  ${YEL}  $COUNT errors${RST}  from  ${BLD}$SVC${RST}"
    else
      echo -e "    $COUNT error   from  $SVC"
    fi
  done

# ============================================================
section "11. OPEN FILES & FILE DESCRIPTORS"
# ============================================================

OPEN_FILES=$(lsof 2>/dev/null | wc -l)
OPEN_FILES=$(to_int "${OPEN_FILES:-0}")
info "Total open file descriptors : $OPEN_FILES"
divider

if [ "$OPEN_FILES" -ge "$OFD_CRIT" ]; then
  crit "Open FDs $OPEN_FILES — file descriptor leak possible!"
  fix "1. Find which proc leaks:    lsof 2>/dev/null | awk '{print \$1}' | sort | uniq -c | sort -rn | head -10
2. Check per-process FDs:    lsof -p <PID> | wc -l
3. See system FD limit:      cat /proc/sys/fs/file-max
4. Increase limit temp:      ulimit -n 100000
5. Restart leaking service:  systemctl restart <service>
6. Raise system limit perm:  echo 'fs.file-max = 500000' >> /etc/sysctl.conf && sysctl -p"
elif [ "$OPEN_FILES" -ge "$OFD_WARN" ]; then
  warn "Open FDs $OPEN_FILES — getting high"
  fix "1. Check top FD consumers:   lsof 2>/dev/null | awk '{print \$1}' | sort | uniq -c | sort -rn | head -5
2. Watch trend:               watch -n 5 'lsof | wc -l'"
else
  ok "Open FDs $OPEN_FILES — healthy"
fi

info "System FD limit : $(cat /proc/sys/fs/file-max)"
info "Current FD usage: $(awk '{print $1}' /proc/sys/fs/file-nr)"

# ============================================================
section "12. LISTENING PORTS"
# ============================================================

info "All listening ports and services:"
divider
ss -tulnp 2>/dev/null | while IFS= read -r line; do echo "  $line"; done

# ============================================================
section "13. NETWORK HEALTH"
# ============================================================

info "Network connections summary:"
divider
ESTABLISHED=$(ss -an 2>/dev/null | grep -c "ESTAB")
TIME_WAIT=$(ss -an 2>/dev/null | grep -c "TIME-WAIT")
CLOSE_WAIT=$(ss -an 2>/dev/null | grep -c "CLOSE-WAIT")
ESTABLISHED=$(to_int "${ESTABLISHED:-0}")
TIME_WAIT=$(to_int "${TIME_WAIT:-0}")
CLOSE_WAIT=$(to_int "${CLOSE_WAIT:-0}")

info "ESTABLISHED  : $ESTABLISHED"
info "TIME_WAIT    : $TIME_WAIT"
info "CLOSE_WAIT   : $CLOSE_WAIT"

if [ "$TIME_WAIT" -gt 100 ]; then
  warn "High TIME_WAIT ($TIME_WAIT) — possible connection leak"
  fix "1. See what connections:     ss -an | grep TIME-WAIT | head -20
2. Reduce TIME_WAIT timeout: echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
3. Enable port reuse:        echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse"
fi

if [ "$CLOSE_WAIT" -gt 50 ]; then
  crit "High CLOSE_WAIT ($CLOSE_WAIT) — app not closing connections!"
  fix "1. Find which app:           ss -anp | grep CLOSE-WAIT | head -20
2. Connections must be explicitly closed — this is a code/config bug
3. Restart offending svc:    systemctl restart <service>
4. Watch if grows:           watch -n 2 'ss -an | grep -c CLOSE-WAIT'"
fi

echo ""
info "Ping test (gateway):"
GW=$(ip route | awk '/default/ {print $3}' | head -1)
if [ -n "$GW" ]; then
  PING_RESULT=$(ping -c 4 "$GW" 2>/dev/null | tail -2)
  PACKET_LOSS=$(echo "$PING_RESULT" | grep -oP '\d+(?=% packet loss)')
  PACKET_LOSS=$(to_int "${PACKET_LOSS:-0}")
  if [ "$PACKET_LOSS" -ge 50 ]; then
    crit "Packet loss ${PACKET_LOSS}% to gateway $GW"
    fix "1. Run extended ping:        ping -c 20 $GW
2. Trace the route:          traceroute $GW
3. Check NIC errors:         ip -s link show eth0
4. Contact network team:     provide traceroute output
5. Escalate immediately:     network loss = service disruption"
  elif [ "$PACKET_LOSS" -ge 10 ]; then
    warn "Packet loss ${PACKET_LOSS}% to gateway $GW"
    fix "1. Confirm with longer ping: ping -c 20 $GW
2. Check interface errors:   ip -s link show
3. Trace route:              traceroute $GW"
  else
    ok "No packet loss to gateway $GW"
  fi
  echo "  $PING_RESULT"
else
  warn "Could not determine default gateway"
fi

# ============================================================
section "14. SYSTEMD SERVICES STATUS"
# ============================================================

# BUG FIX: only show active services in main list
# Only flag inactive for non-template, non-oneshot services
info "Active enabled services:"
divider
systemctl list-unit-files --type=service --state=enabled 2>/dev/null | grep enabled | while IFS= read -r line; do
  SVC=$(echo "$line" | awk '{print $1}')
  STATUS=$(systemctl is-active "$SVC" 2>/dev/null)
  if [ "$STATUS" = "active" ]; then
    echo -e "  ${GRN}[active]${RST} $SVC"
  fi
done

echo ""
info "Enabled services that are not running:"
divider
FOUND=0
systemctl list-unit-files --type=service --state=enabled 2>/dev/null | grep enabled | while IFS= read -r line; do
  SVC=$(echo "$line" | awk '{print $1}')
  STATUS=$(systemctl is-active "$SVC" 2>/dev/null)
  if [ "$STATUS" != "active" ]; then
    # Skip expected-inactive services (oneshot, templates, boot-only)
    case "$SVC" in
      *@*|e2scrub*|grub*|secureboot*|sshd-keygen*|pollinate*|ua-reboot*|\
      snapd.core-fixup*|snapd.recovery*|snapd.system-shutdown*|snapd.autoimport*|\
      cloud-*|dmesg*|gpu-manager*|getty*|thermald*|open-iscsi*|vgauth*|\
      ubuntu-advantage*|open-vm-tools*)
        ;;  # silently skip — expected to be inactive
      *)
        echo -e "  ${YEL}[inactive]${RST} $SVC"
        FOUND=1
        ;;
    esac
  fi
done
[ "$FOUND" -eq 0 ] 2>/dev/null && ok "No unexpected inactive services"

# ============================================================
section "15. TOP DIRECTORY DISK CONSUMERS"
# ============================================================

info "Top 10 directories consuming disk (entire system):"
divider
du -h --max-depth=2 / 2>/dev/null | sort -rh | head -10 | while IFS= read -r line; do
  echo "  $line"
done

# ============================================================
section "16. VMSTAT SNAPSHOT"
# ============================================================

info "vmstat — virtual memory, processes, I/O, CPU:"
divider
vmstat 1 3 2>/dev/null | while IFS= read -r line; do echo "  $line"; done
echo ""
info "Column guide: r=run queue, b=blocked, si/so=swap in/out, bi/bo=block in/out, wa=iowait"

VMSTAT_LINE=$(vmstat 1 2 2>/dev/null | tail -1)
SWAP_IN=$(echo "$VMSTAT_LINE" | awk '{print $7}')
SWAP_OUT=$(echo "$VMSTAT_LINE" | awk '{print $8}')
SWAP_IN=$(to_int "${SWAP_IN:-0}")
SWAP_OUT=$(to_int "${SWAP_OUT:-0}")

if [ "$SWAP_IN" -gt 0 ]; then
  warn "Swap-in activity detected ($SWAP_IN) — memory pressure!"
  fix "1. Find memory hogs:         ps aux --sort=-%mem | head -10
2. Check swap usage:         free -h
3. Restart memory hog:       systemctl restart <service>"
fi
if [ "$SWAP_OUT" -gt 0 ]; then
  warn "Swap-out activity detected ($SWAP_OUT) — paging to disk!"
  fix "1. Confirm with:             vmstat 1 10  (si/so should be 0 when healthy)
2. Run swap setup script:    bash add_swap.sh
3. Reduce swappiness:        echo 10 > /proc/sys/vm/swappiness"
fi

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

CPU_STATUS="OK"
[ "$CPU_INT" -ge "$CPU_WARN" ] && CPU_STATUS="WARN"
[ "$CPU_INT" -ge "$CPU_CRIT" ] && CPU_STATUS="CRIT"
print_row "CPU Usage" "${CPU_USED}%" "$CPU_STATUS" "warn>${CPU_WARN}% crit>${CPU_CRIT}%"

IOWAIT_STATUS="OK"
[ "$IOWAIT_INT" -ge "$IOWAIT_WARN" ] && IOWAIT_STATUS="WARN"
[ "$IOWAIT_INT" -ge "$IOWAIT_CRIT" ] && IOWAIT_STATUS="CRIT"
print_row "CPU iowait" "${CPU_IOWAIT}%" "$IOWAIT_STATUS" "warn>${IOWAIT_WARN}% crit>${IOWAIT_CRIT}%"

STEAL_STATUS="OK"
[ "$STEAL_INT" -ge 5  ] && STEAL_STATUS="WARN"
[ "$STEAL_INT" -ge 10 ] && STEAL_STATUS="CRIT"
print_row "CPU Steal (VM)" "${CPU_STEAL}%" "$STEAL_STATUS" "warn>5% crit>10%"

LOAD_STATUS="OK"
(( $(echo "$LOAD1 > $LOAD_WARN_VAL" | bc -l) )) && LOAD_STATUS="WARN"
(( $(echo "$LOAD1 > $LOAD_CRIT_VAL" | bc -l) )) && LOAD_STATUS="CRIT"
print_row "Load Avg (1min)" "$LOAD1" "$LOAD_STATUS" "warn>${LOAD_WARN_VAL} crit>${LOAD_CRIT_VAL}"

MEM_STATUS="OK"
[ "$MEM_INT" -ge "$MEM_WARN" ] && MEM_STATUS="WARN"
[ "$MEM_INT" -ge "$MEM_CRIT" ] && MEM_STATUS="CRIT"
print_row "Memory Usage" "${MEM_PCT}%" "$MEM_STATUS" "warn>${MEM_WARN}% crit>${MEM_CRIT}%"

SWAP_STATUS="OK"
[ "$SWAP_INT" -ge "$SWAP_WARN" ] && SWAP_STATUS="WARN"
[ "$SWAP_INT" -ge "$SWAP_CRIT" ] && SWAP_STATUS="CRIT"
[ "$SWAP_TOTAL" -eq 0 ] && SWAP_STATUS="WARN"
print_row "Swap Usage" "${SWAP_PCT}%" "$SWAP_STATUS" "warn>${SWAP_WARN}% crit>${SWAP_CRIT}%"

OOM_STATUS="OK"
[ "$OOM_COUNT" -gt 0 ] && OOM_STATUS="CRIT"
print_row "OOM Crashes" "$OOM_COUNT events" "$OOM_STATUS" "crit>0"

ZOMBIE_STATUS="OK"
[ "$ZOMBIE_COUNT" -gt 0 ] && ZOMBIE_STATUS="WARN"
print_row "Zombie Processes" "$ZOMBIE_COUNT" "$ZOMBIE_STATUS" "warn>0"

FAIL_STATUS="OK"
[ "$FAILED_COUNT" -gt 0 ] && FAIL_STATUS="CRIT"
print_row "Failed Services" "$FAILED_COUNT" "$FAIL_STATUS" "crit>0"

FATAL_STATUS="OK"
[ "$FATAL_COUNT" -ge 1  ] && FATAL_STATUS="WARN"
[ "$FATAL_COUNT" -ge 10 ] && FATAL_STATUS="CRIT"
print_row "FATAL Errors (10min)" "$FATAL_COUNT" "$FATAL_STATUS" "warn>1 crit>10"

ERR_STATUS="OK"
[ "$ERROR_COUNT" -ge 10 ] && ERR_STATUS="WARN"
[ "$ERROR_COUNT" -ge 50 ] && ERR_STATUS="CRIT"
print_row "Total Errors (10min)" "$ERROR_COUNT" "$ERR_STATUS" "warn>10 crit>50"

OFD_STATUS="OK"
[ "$OPEN_FILES" -ge "$OFD_WARN" ] && OFD_STATUS="WARN"
[ "$OPEN_FILES" -ge "$OFD_CRIT" ] && OFD_STATUS="CRIT"
print_row "Open File Descriptors" "$OPEN_FILES" "$OFD_STATUS" "warn>${OFD_WARN} crit>${OFD_CRIT}"

CW_STATUS="OK"
[ "$CLOSE_WAIT" -gt 50  ] && CW_STATUS="CRIT"
TW_STATUS="OK"
[ "$TIME_WAIT"  -gt 100 ] && TW_STATUS="WARN"
print_row "CLOSE_WAIT conns" "$CLOSE_WAIT" "$CW_STATUS" "crit>50"
print_row "TIME_WAIT conns" "$TIME_WAIT" "$TW_STATUS" "warn>100"

ROOT_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
ROOT_PCT=$(to_int "${ROOT_PCT:-0}")
ROOT_STATUS="OK"
[ "$ROOT_PCT" -ge "$DISK_WARN" ] && ROOT_STATUS="WARN"
[ "$ROOT_PCT" -ge "$DISK_CRIT" ] && ROOT_STATUS="CRIT"
print_row "Disk Usage (/)" "${ROOT_PCT}%" "$ROOT_STATUS" "warn>${DISK_WARN}% crit>${DISK_CRIT}%"

ROOT_INODE=$(df -i / | tail -1 | awk '{print $5}' | tr -d '%')
ROOT_INODE=$(to_int "${ROOT_INODE:-0}")
INODE_STATUS="OK"
[ "$ROOT_INODE" -ge "$INODE_WARN" ] && INODE_STATUS="WARN"
[ "$ROOT_INODE" -ge "$INODE_CRIT" ] && INODE_STATUS="CRIT"
print_row "Inode Usage (/)" "${ROOT_INODE}%" "$INODE_STATUS" "warn>${INODE_WARN}% crit>${INODE_CRIT}%"

# ============================================================
echo ""
echo -e "  ${BLD}Report saved to: $REPORT${RST}"
echo -e "  ${BLD}Generated at   : $(date)${RST}"
echo ""
