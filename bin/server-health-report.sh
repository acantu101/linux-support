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
section()  { echo -e "\n${CYN}${BLD}════════════════════════════════════════════════════${RST}"
             echo -e "${CYN}${BLD}  $1${RST}"
             echo -e "${CYN}${BLD}════════════════════════════════════════════════════${RST}"; }
ok()       { echo -e "  ${GRN}[  OK  ]${RST}  $1"; }
warn()     { echo -e "  ${YEL}[ WARN ]${RST}  $1"; }
crit()     { echo -e "  ${RED}[ CRIT ]${RST}  $1"; }
info()     { echo -e "  ${BLD}[ INFO ]${RST}  $1"; }
divider()  { echo -e "  --------------------------------------------------------"; }
autocheck(){ echo -e "  ${CYN}  ▶ AUTO: $1${RST}"; }
fix() {
  echo -e "  ${YEL}${BLD}  ▶ ACTION REQUIRED:${RST}"
  while IFS= read -r step; do
    echo -e "  ${YEL}    $step${RST}"
  done <<< "$1"
  echo ""
}

# Safe integer conversion
to_int() {
  local val
  val=$(echo "${1}" | head -1 | tr -d '\n' | grep -oE '^[0-9]+')
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
LOAD_WARN=0.8;      LOAD_CRIT=1.2

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
TOP_OUTPUT=$(top -b -n 2 -d 0.5 2>/dev/null | grep "Cpu(s)" | tail -1)
CPU_IDLE=$(echo "$TOP_OUTPUT"   | awk '{for(i=1;i<=NF;i++) if($i~/id,/) print $(i-1)}' | tr -d '%')
CPU_IOWAIT=$(echo "$TOP_OUTPUT" | awk '{for(i=1;i<=NF;i++) if($i~/wa,/) print $(i-1)}' | tr -d '%')
CPU_USER=$(echo "$TOP_OUTPUT"   | awk '{for(i=1;i<=NF;i++) if($i~/us,/) print $(i-1)}' | tr -d '%')
CPU_SYS=$(echo "$TOP_OUTPUT"    | awk '{for(i=1;i<=NF;i++) if($i~/sy,/) print $(i-1)}' | tr -d '%')
CPU_STEAL=$(echo "$TOP_OUTPUT"  | awk '{for(i=1;i<=NF;i++) if($i~/st/) print $(i-1)}' | tr -d '%')
CPU_IDLE=${CPU_IDLE:-0}; CPU_IOWAIT=${CPU_IOWAIT:-0}; CPU_STEAL=${CPU_STEAL:-0}
CPU_USED=$(echo "100 - ${CPU_IDLE}" | bc 2>/dev/null || echo "0")
CPU_USED=${CPU_USED:-0}
CPU_INT=$(to_int "$CPU_USED"); IOWAIT_INT=$(to_int "$CPU_IOWAIT"); STEAL_INT=$(to_int "$CPU_STEAL")

info "CPU Cores       : $CPU_CORES"
info "CPU Used        : ${CPU_USED}%  (user=${CPU_USER:-0}% sys=${CPU_SYS:-0}% iowait=${CPU_IOWAIT}% steal=${CPU_STEAL}%)"
divider

if [ "$CPU_INT" -ge "$CPU_CRIT" ]; then
  crit "CPU usage ${CPU_USED}% — server is overwhelmed!"
  autocheck "Top 10 CPU-consuming processes right now:"
  ps aux --sort=-%cpu | awk 'NR==1{print "    "$0} NR>1 && NR<=11{printf "    %-10s %-8s %-6s %-6s %s\n",$1,$2,$3,$4,$11}'
  autocheck "Scheduled jobs that may have triggered this:"
  crontab -l 2>/dev/null | grep -v "^#" | head -10 | while IFS= read -r l; do echo "    $l"; done
  ls /etc/cron.d/ 2>/dev/null | while IFS= read -r l; do echo "    /etc/cron.d/$l"; done
  fix "1. Identify the hog above and determine if it is legitimate
2. Graceful restart:         systemctl restart <service>
3. Force kill (last resort): kill -9 <PID>
4. Set CPU limit in unit:    CPUQuota=80%  then  systemctl daemon-reload"
elif [ "$CPU_INT" -ge "$CPU_WARN" ]; then
  warn "CPU usage ${CPU_USED}% — getting busy"
  autocheck "Top 5 CPU consumers:"
  ps aux --sort=-%cpu | awk 'NR>1 && NR<=6{printf "    %-10s %-8s %-6s %s\n",$1,$2,$3,$11}'
  fix "1. Monitor if it keeps climbing: watch -n 5 'ps aux --sort=-%cpu | head -5'
2. Restart offending service if confirmed: systemctl restart <service>"
else
  ok "CPU usage ${CPU_USED}% is healthy"
fi

if [ "$IOWAIT_INT" -ge "$IOWAIT_CRIT" ]; then
  crit "%iowait ${CPU_IOWAIT}% — severe disk bottleneck!"
  autocheck "Disk utilisation right now:"
  iostat -x 1 2 2>/dev/null | awk '/^(sd|vd|nvme)/{printf "    Device: %-10s  %%util: %s  r_await: %s  w_await: %s\n",$1,$NF,$9,$10}'
  autocheck "Log directory sizes:"
  du -h /opt/server-health/logs 2>/dev/null | sort -rh | head -5 | while IFS= read -r l; do echo "    $l"; done
  autocheck "Disk health (SMART):"
  for disk in /dev/sd? /dev/vd? /dev/nvme?; do
    [ -b "$disk" ] && smartctl -H "$disk" 2>/dev/null | grep -E "overall|result" | while IFS= read -r l; do echo "    $disk: $l"; done
  done
  fix "1. Find the I/O hog:          iotop -o   (apt install iotop)
2. Clean old logs:           find /opt/server-health/logs -name '*.log' -mtime +7 -delete
3. Clear journal:            journalctl --vacuum-time=3d
4. Escalate if SMART shows errors — hardware may be failing"
elif [ "$IOWAIT_INT" -ge "$IOWAIT_WARN" ]; then
  warn "%iowait ${CPU_IOWAIT}% — disk may be slow"
  autocheck "Current disk I/O snapshot:"
  iostat -x 1 2 2>/dev/null | awk '/^(sd|vd|nvme)/{printf "    Device: %-10s  %%util: %s\n",$1,$NF}'
  autocheck "Log directory growth:"
  ls -lth /opt/server-health/logs/ 2>/dev/null | head -5 | while IFS= read -r l; do echo "    $l"; done
  fix "1. Run iotop to find the writing process: iotop -o
2. Clean old logs if growing:  find /opt/server-health/logs -name '*.log' -mtime +7 -delete"
else
  ok "%iowait ${CPU_IOWAIT}% — no disk bottleneck"
fi

if [ "$STEAL_INT" -ge 10 ]; then
  crit "%steal ${CPU_STEAL}% — VM host is starving this server!"
  autocheck "Steal trend over 10 seconds:"
  vmstat 1 10 2>/dev/null | awk 'NR>2{print "    steal: "$17"%"}'
  fix "1. Contact cloud provider with vmstat output — request host migration
2. Short-term: systemctl stop <non-critical-service> to reduce load
3. Long-term: move to dedicated instance"
elif [ "$STEAL_INT" -ge 5 ]; then
  warn "%steal ${CPU_STEAL}% — VM host stealing some CPU"
  autocheck "Steal trend over 5 seconds:"
  vmstat 1 5 2>/dev/null | awk 'NR>2{print "    steal: "$17"%"}'
  fix "1. Open support ticket with cloud provider if sustained above 5%"
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
    autocheck "Run queue and blocked processes right now:"
    vmstat 1 3 2>/dev/null | awk 'NR>1{printf "    r=%-3s b=%-3s swpd=%-8s si=%-4s so=%-4s wa=%s\n",$1,$2,$3,$7,$8,$17}'
    autocheck "Blocked processes (state=D, waiting on I/O):"
    ps aux | awk '$8=="D" {printf "    PID:%-8s USER:%-10s CMD:%s\n",$2,$1,$11}' | head -10
    autocheck "Top CPU hogs:"
    ps aux --sort=-%cpu | awk 'NR>1 && NR<=6{printf "    %-10s %-8s %-6s %s\n",$1,$2,$3,$11}'
    fix "1. If blocked processes found above: check iowait in section 1 — disk may be the root cause
2. Restart the offending service: systemctl restart <service>
3. Kill runaway process:          kill -15 <PID>"
  elif (( $(echo "$val > $LOAD_WARN_VAL" | bc -l) )); then
    warn "Load $label = $val — approaching limit"
    autocheck "Current run queue:"
    vmstat 1 3 2>/dev/null | awk 'NR>1{printf "    r=%-3s b=%-3s wa=%s\n",$1,$2,$17}'
    fix "1. Watch the trend:  run this report again in 2 minutes
2. If load keeps climbing: restart non-critical services"
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
MEM_INT=$(to_int "$MEM_PCT"); SWAP_INT=$(to_int "$SWAP_PCT")

info "Memory Total    : ${MEM_TOTAL} MB"
info "Memory Used     : ${MEM_USED} MB  (${MEM_PCT}%)"
info "Memory Free     : ${MEM_FREE} MB"
info "Buff/Cache      : ${MEM_CACHE} MB"
info "Swap Total      : ${SWAP_TOTAL} MB"
info "Swap Used       : ${SWAP_USED} MB  (${SWAP_PCT}%)"
divider

if [ "$MEM_INT" -ge "$MEM_CRIT" ]; then
  crit "Memory ${MEM_PCT}% used — OOM risk!"
  autocheck "Top 10 memory hogs right now:"
  ps aux --sort=-%mem | awk 'NR==1{print "    "$0} NR>1 && NR<=11{printf "    %-10s %-8s %-6s %-6s %s\n",$1,$2,$3,$4,$11}'
  autocheck "OOM scores for top 5 consumers (higher = killed first):"
  ps aux --sort=-%mem | awk 'NR>1 && NR<=6{print $2}' | while IFS= read -r pid; do
    score=$(cat /proc/"$pid"/oom_score 2>/dev/null)
    cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
    [ -n "$score" ] && echo "    PID $pid ($cmd) OOM score: $score"
  done
  autocheck "Dropping page cache safely (frees buff/cache, not app memory):"
  sync && echo 1 > /proc/sys/vm/drop_caches && echo "    Page cache dropped" || echo "    Could not drop cache"
  free -m | awk '/^Mem/{printf "    Memory after cache drop: used=%dMB free=%dMB\n",$3,$4}'
  fix "1. Restart the leaking service (identify from hogs above): systemctl restart <service>
2. If OOM is imminent:  bash add_swap.sh
3. Set memory cap in unit file:  MemoryMax=4G  then  systemctl daemon-reload"
elif [ "$MEM_INT" -ge "$MEM_WARN" ]; then
  warn "Memory ${MEM_PCT}% used — getting tight"
  autocheck "Top 5 memory consumers:"
  ps aux --sort=-%mem | awk 'NR>1 && NR<=6{printf "    %-10s %-8s %-6s %s\n",$1,$2,$4,$11}'
  autocheck "VmRSS (actual RAM) for top consumer:"
  TOP_PID=$(ps aux --sort=-%mem | awk 'NR==2{print $2}')
  cat /proc/"$TOP_PID"/status 2>/dev/null | grep -E "VmRSS|VmSwap|VmPeak" | while IFS= read -r l; do echo "    $l"; done
  fix "1. If a service is growing over time (memory leak): systemctl restart <service>
2. Schedule restart during off-hours if leak is known but non-critical"
else
  ok "Memory ${MEM_PCT}% used — healthy"
fi

if [ "$SWAP_INT" -ge "$SWAP_CRIT" ]; then
  crit "Swap ${SWAP_PCT}% used — system is swapping heavily, major slowdown!"
  autocheck "Swap activity right now (si=swap-in so=swap-out, both should be 0):"
  vmstat 1 5 2>/dev/null | awk 'NR>1{printf "    si=%-6s so=%s\n",$7,$8}'
  autocheck "What is using swap (top consumers):"
  ps aux --sort=-%mem | awk 'NR>1 && NR<=6{printf "    %-10s %-8s %-6s %s\n",$1,$2,$4,$11}'
  fix "1. Restart the largest memory consumer (identified above): systemctl restart <service>
2. Kill non-critical process: kill -15 <PID>
3. Tune swappiness:           echo 10 > /proc/sys/vm/swappiness
4. Contact senior engineer if service cannot be restarted"
elif [ "$SWAP_INT" -ge "$SWAP_WARN" ]; then
  warn "Swap ${SWAP_PCT}% used — memory pressure building"
  autocheck "Swap activity (should be 0 for si and so):"
  vmstat 1 3 2>/dev/null | awk 'NR>1{printf "    si=%-6s so=%s\n",$7,$8}'
  fix "1. Restart the largest memory consumer if confirmed leaking: systemctl restart <service>
2. Run swap setup if more headroom needed: bash add_swap.sh"
elif [ "$SWAP_TOTAL" -eq 0 ]; then
  warn "No swap configured — OOM killer will fire with no safety net"
  autocheck "Current memory headroom:"
  free -h | while IFS= read -r l; do echo "    $l"; done
  fix "1. Run swap setup script now:  bash add_swap.sh"
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
  crit "OOM killer has fired $OOM_COUNT time(s)!"
  autocheck "What was killed and when:"
  dmesg | grep -i "oom\|out of memory\|killed process" | tail -10 | while IFS= read -r l; do echo "    $l"; done
  autocheck "Current OOM scores (top 5 — higher = killed first next time):"
  ps aux --sort=-%mem | awk 'NR>1 && NR<=6{print $2}' | while IFS= read -r pid; do
    score=$(cat /proc/"$pid"/oom_score 2>/dev/null)
    cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
    [ -n "$score" ] && echo "    PID $pid ($cmd) OOM score: $score"
  done
  autocheck "Protecting all non-root critical services from OOM kill:"
  ps aux --sort=-%mem | awk 'NR>1 && NR<=4{print $2}' | while IFS= read -r pid; do
    cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
    echo "-500" > /proc/"$pid"/oom_score_adj 2>/dev/null && \
      echo "    Protected PID $pid ($cmd) — oom_score_adj set to -500" || \
      echo "    Could not adjust PID $pid"
  done
  fix "1. Restart the killed service: systemctl restart <service>
2. Add swap to prevent future OOM: bash add_swap.sh
3. Set MemoryMax in unit file to cap usage:  MemoryMax=4G"
else
  ok "No OOM events detected in dmesg"
fi

JOUR_OOM=$(journalctl -k --since "24 hours ago" 2>/dev/null | grep -ic "oom\|killed process")
JOUR_OOM=$(to_int "${JOUR_OOM:-0}")
if [ "$JOUR_OOM" -gt 0 ]; then
  crit "OOM events in journal (last 24h): $JOUR_OOM"
  autocheck "OOM pattern — checking if it repeats at the same time:"
  journalctl -k --since "24 hours ago" 2>/dev/null | grep -i "killed process" | \
    awk '{print $1, $2, $3}' | while IFS= read -r l; do echo "    $l"; done
  fix "1. If pattern repeats at same time — check crontab for a heavy job
2. Review memory limits: systemctl show <service> | grep -i memory"
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
      autocheck "Top directories on $MNT:"
      du -h "$MNT" 2>/dev/null | sort -rh | head -8 | while IFS= read -r l; do echo "    $l"; done
      autocheck "Files over 100MB on $MNT:"
      find "$MNT" -type f -size +100M -not -path "/proc/*" -printf '%s %p\n' 2>/dev/null | \
        sort -rn | head -5 | awk '{printf "    %-12s %s\n",$1,$2}'
      autocheck "Deleted files still held open (space not released until process closed):"
      lsof 2>/dev/null | grep -i "deleted\|DEL" | awk '{printf "    %-15s PID:%-8s %s\n",$1,$2,$NF}' | head -5
      fix "1. Clean old logs:     find $MNT -name '*.log' -mtime +7 -delete
2. Clear journal:      journalctl --vacuum-size=500M
3. Clear APT cache:    apt clean
4. Restart any process holding deleted files open (shown above)"
    elif [ "$PCT" -ge "$DISK_WARN" ]; then
      echo -e "  ${YEL}[WARN $PCT%]${RST} $line"
      autocheck "Top 5 directories on $MNT:"
      du -h "$MNT" 2>/dev/null | sort -rh | head -5 | while IFS= read -r l; do echo "    $l"; done
      fix "1. Review largest directories above and clean old logs/archives"
    else
      echo -e "  ${GRN}[  OK $PCT%]${RST} $line"
    fi
  fi
done

echo ""
info "Top 10 largest directories in /var:"
divider
du -h /var 2>/dev/null | sort -rh | head -10 | while IFS= read -r l; do echo "  $l"; done

echo ""
info "Top 10 largest files in /var:"
divider
find /var -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -10 | awk '{printf "  %-12s %s\n",$1,$2}'

echo ""
info "Files larger than 100MB on system (excluding /proc):"
divider
find / -type f -size +100M -not -path "/proc/*" -printf '%s %p\n' 2>/dev/null | sort -rn | head -10 | awk '{printf "  %-12s %s\n",$1,$2}'

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
      autocheck "Directories with most files on $MNT:"
      for d in "$MNT"/*/; do
        count=$(find "$d" 2>/dev/null | wc -l)
        echo "    $count  $d"
      done 2>/dev/null | sort -rn | head -8
      autocheck "Mail spool check:"
      ls -la /var/spool/mail/ 2>/dev/null | while IFS= read -r l; do echo "    $l"; done
      fix "1. Delete old log files:  find $MNT -name '*.log' -mtime +3 -delete
2. Clean temp files:       find /tmp -mtime +3 -delete && find /var/tmp -mtime +7 -delete
3. Clean mail spool:       cat /dev/null > /var/spool/mail/root"
    elif [ "$PCT" -ge "$INODE_WARN" ]; then
      echo -e "  ${YEL}[WARN $PCT%]${RST} $line"
      autocheck "Top inode-consuming directories on $MNT:"
      for d in "$MNT"/*/; do
        count=$(find "$d" 2>/dev/null | wc -l)
        echo "    $count  $d"
      done 2>/dev/null | sort -rn | head -5
      fix "1. Start cleaning small files: find $MNT -name '*.log' -mtime +7 -delete"
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
IOSTAT_OUT=$(iostat -x 1 3 2>/dev/null)
echo "$IOSTAT_OUT" | while IFS= read -r line; do echo "  $line"; done

echo ""
info "Disk utilisation per device:"
divider
echo "$IOSTAT_OUT" | awk '/^(sd[a-z]|vd[a-z]|nvme|xvd[a-z]|hd[a-z])/{print $1, $NF}' | \
while IFS= read -r devline; do
  DEV=$(echo "$devline" | awk '{print $1}')
  UTIL=$(echo "$devline" | awk '{print $2}')
  UTIL_INT=$(to_int "$UTIL")
  if [ "$UTIL_INT" -ge "$UTIL_CRIT" ]; then
    crit "Device $DEV — disk util ${UTIL}% — disk saturated!"
    autocheck "Detailed I/O stats for /dev/$DEV:"
    iostat -x 1 2 2>/dev/null | grep "^$DEV" | tail -1 | \
      awk '{printf "    r/s=%-8s w/s=%-8s r_await=%-8s w_await=%-8s %%util=%s\n",$2,$8,$9,$10,$NF}'
    autocheck "SMART health for /dev/$DEV:"
    smartctl -H "/dev/$DEV" 2>/dev/null | grep -E "overall|result|PASSED|FAILED" | \
      while IFS= read -r l; do echo "    $l"; done
    autocheck "Log directory size:"
    du -sh /opt/server-health/logs 2>/dev/null | while IFS= read -r l; do echo "    $l"; done
    fix "1. Find the I/O hog:          iotop -o   (apt install iotop)
2. Clean old logs:           find /opt/server-health/logs -name '*.log' -mtime +7 -delete
3. Clear journal:            journalctl --vacuum-time=3d
4. If SMART shows FAILED — disk is dying: escalate immediately"
  elif [ "$UTIL_INT" -ge "$UTIL_WARN" ]; then
    warn "Device $DEV — disk util ${UTIL}% — getting busy"
    autocheck "I/O stats for /dev/$DEV:"
    iostat -x 1 2 2>/dev/null | grep "^$DEV" | tail -1 | \
      awk '{printf "    r/s=%-8s w/s=%-8s %%util=%s\n",$2,$8,$NF}'
    fix "1. Run iotop to find writing process: iotop -o
2. Clean old logs if growing:          find /opt/server-health/logs -name '*.log' -mtime +7 -delete"
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
  autocheck "Zombie PIDs and their parent processes:"
  ps aux | awk '$8=="Z" {print $2}' | while IFS= read -r zpid; do
    ppid=$(ps -o ppid= -p "$zpid" 2>/dev/null | tr -d ' ')
    pcmd=$(ps -p "$ppid" -o comm= 2>/dev/null)
    zcmd=$(ps -p "$zpid" -o comm= 2>/dev/null)
    echo "    Zombie PID: $zpid ($zcmd)  →  Parent PID: $ppid ($pcmd)"
  done
  fix "1. Restart the parent service shown above: systemctl restart <parent-service>
2. If parent is stuck:                       kill -15 <PARENT_PID>
3. Force kill only as last resort:           kill -9 <PARENT_PID>
   NOTE: Zombies cannot be killed directly — killing the parent cleans them up."
else
  ok "No zombie processes found"
fi

# ============================================================
section "9. CRASHED / FATAL SERVICES"
# ============================================================

investigate_crashed_service() {
  local SVC="$1"
  local CRASH_DATE; CRASH_DATE=$(date +%Y%m%d_%H%M%S)
  local CLEAN_SVC; CLEAN_SVC=$(echo "$SVC" | sed 's/\.service$//')
  local CRASH_LOG="$REPORT_DIR/${CLEAN_SVC}_crash_${CRASH_DATE}.txt"

  echo -e "\n  ${RED}${BLD}══ CRASH INVESTIGATION: $SVC ══${RST}"

  {
    echo "======================================================"
    echo "  CRASH INVESTIGATION REPORT"
    echo "  Service   : $SVC"
    echo "  Generated : $(date)"
    echo "  Server    : $(hostname)"
    echo "======================================================"
    echo ""
    echo "------------------------------------------------------"
    echo "  1. SYSTEMCTL STATUS"
    echo "------------------------------------------------------"
    systemctl status "$SVC" 2>/dev/null
    echo ""
    echo "------------------------------------------------------"
    echo "  2. RESTART CONFIGURATION"
    echo "------------------------------------------------------"
    RESTART_POLICY=$(systemctl show "$SVC" --property=Restart 2>/dev/null | cut -d= -f2)
    RESTART_SEC=$(systemctl show "$SVC" --property=RestartSec 2>/dev/null | cut -d= -f2)
    START_LIMIT=$(systemctl show "$SVC" --property=StartLimitBurst 2>/dev/null | cut -d= -f2)
    START_INTERVAL=$(systemctl show "$SVC" --property=StartLimitIntervalSec 2>/dev/null | cut -d= -f2)
    echo "  Restart policy    : ${RESTART_POLICY:-not set}"
    echo "  Restart delay     : ${RESTART_SEC:-not set}"
    echo "  Start limit burst : ${START_LIMIT:-not set}"
    echo "  Start limit window: ${START_INTERVAL:-not set}"
    if [ "${RESTART_POLICY:-no}" = "no" ] || [ -z "$RESTART_POLICY" ]; then
      echo "  ⚠️  NOT configured to restart on failure"
    else
      echo "  ✅ Auto-restart configured: Restart=$RESTART_POLICY"
    fi
    echo ""
    echo "------------------------------------------------------"
    echo "  3. FAILURE DETAILS"
    echo "------------------------------------------------------"
    EXIT_CODE=$(systemctl show "$SVC" --property=ExecMainStatus 2>/dev/null | cut -d= -f2)
    RESULT=$(systemctl show "$SVC" --property=Result 2>/dev/null | cut -d= -f2)
    MAIN_PID=$(systemctl show "$SVC" --property=MainPID 2>/dev/null | cut -d= -f2)
    echo "  Exit code  : ${EXIT_CODE:-unknown}"
    echo "  Result     : ${RESULT:-unknown}"
    echo "  Last PID   : ${MAIN_PID:-unknown}"
    echo ""
    echo "------------------------------------------------------"
    echo "  4. LAST 50 LOG ENTRIES"
    echo "------------------------------------------------------"
    journalctl -u "$SVC" -n 50 --no-pager 2>/dev/null
    echo ""
    echo "------------------------------------------------------"
    echo "  5. DEPENDENCIES"
    echo "------------------------------------------------------"
    systemctl list-dependencies "$SVC" 2>/dev/null
    echo ""
    echo "------------------------------------------------------"
    echo "  6. REQUIRED BY (what depends on this service)"
    echo "------------------------------------------------------"
    systemctl list-dependencies "$SVC" --reverse 2>/dev/null | head -20
    echo ""
    echo "------------------------------------------------------"
    echo "  7. UNIT FILE"
    echo "------------------------------------------------------"
    UNIT_FILE=$(systemctl show "$SVC" --property=FragmentPath 2>/dev/null | cut -d= -f2)
    echo "  Unit file : ${UNIT_FILE:-not found}"
    [ -f "$UNIT_FILE" ] && echo "" && cat "$UNIT_FILE"
    echo ""
    echo "======================================================"
    echo "  END OF CRASH REPORT — $SVC"
    echo "======================================================"
  } | tee "$CRASH_LOG" | while IFS= read -r line; do echo "    $line"; done

  echo ""
  echo -e "  ${BLD}  📄 Crash log saved: $CRASH_LOG${RST}"
  echo ""

  # Summary in main report
  if [ "${RESTART_POLICY:-no}" = "no" ] || [ -z "$RESTART_POLICY" ]; then
    echo -e "  ${RED}  ✗ NOT configured to restart on failure${RST}"
  else
    echo -e "  ${GRN}  ✓ Auto-restart configured: Restart=${RESTART_POLICY}${RST}"
  fi
  echo -e "  ${YEL}  Failure result : ${RESULT:-unknown}  |  Exit code: ${EXIT_CODE:-unknown}${RST}"
  echo ""
  fix "1. Read crash log:           cat $CRASH_LOG
2. Restart the service:      systemctl restart $SVC
3. After fixing root cause — clear failed state:
   systemctl reset-failed $SVC
   (clears systemd's crash memory so future restarts are not blocked)
4. If not auto-restarting — add to unit file: Restart=on-failure
   Then: systemctl daemon-reload && systemctl restart $SVC
5. Watch it live:            journalctl -fu $SVC
6. Escalate if unresolved:   contact senior engineer"
}

info "Services that have crashed or failed:"
divider
FAILED_SERVICES=$(systemctl --failed --type=service 2>/dev/null | grep "●" | awk '{print $2}')
FAILED_COUNT=$(echo "$FAILED_SERVICES" | grep -c "service" 2>/dev/null)
FAILED_COUNT=$(to_int "${FAILED_COUNT:-0}")

if [ "$FAILED_COUNT" -gt 0 ]; then
  crit "$FAILED_COUNT failed service(s) detected — running automated investigation..."
  echo "$FAILED_SERVICES" | while IFS= read -r SVC; do
    [ -z "$SVC" ] && continue
    investigate_crashed_service "$SVC"
    divider
  done
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
  autocheck "FATAL log entries with source service:"
  journalctl --since "10 minutes ago" 2>/dev/null | grep -i "fatal\|FATAL" | tail -10 | while IFS= read -r line; do
    UNIT=$(echo "$line" | awk '{print $5}' | sed 's/\[.*//' | sed 's/://')
    echo -e "    ${YEL}[${UNIT:-unknown}]${RST} $line"
  done
  fix "1. Restart the affected service (identified above): systemctl restart <service>
2. If recurring FATAL — do not just keep restarting: escalate to senior engineer"
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
  autocheck "Errors per service (top offenders):"
  journalctl -p err --since "10 minutes ago" --no-pager 2>/dev/null | grep -v "^--" | \
    awk '{print $5}' | sed 's/\[.*//' | sed 's/://' | sort | uniq -c | sort -rn | head -10 | \
    while IFS= read -r l; do echo "    $l"; done
  fix "1. Restart the highest-error service (shown above): systemctl restart <service>
2. Escalate to senior engineer if errors persist after restart"
elif [ "$ERROR_COUNT" -ge 10 ]; then
  warn "$ERROR_COUNT errors in last 10 min — needs attention"
  autocheck "Errors per service:"
  journalctl -p err --since "10 minutes ago" --no-pager 2>/dev/null | grep -v "^--" | \
    awk '{print $5}' | sed 's/\[.*//' | sed 's/://' | sort | uniq -c | sort -rn | head -5 | \
    while IFS= read -r l; do echo "    $l"; done
  fix "1. Investigate the top error source above: journalctl -u <service> -n 50"
else
  ok "$ERROR_COUNT errors in last 10 min — normal"
fi

echo ""
info "Error lines with context (source file shown per entry):"
divider
if [ -f /var/log/syslog ]; then
  info "Source file: /var/log/syslog"
  divider
  grep -n -i "error\|fatal\|critical" /var/log/syslog | tail -5 | while IFS= read -r match; do
    LINENUM=$(echo "$match" | cut -d: -f1)
    SERVICE=$(echo "$match" | awk '{for(i=1;i<=NF;i++) if($i~/\[/||$i~/:$/){gsub(/\[.*|\]/,"",$i);gsub(/:$/,"",$i);print $i;exit}}')
    START=$((LINENUM - 1)); END=$((LINENUM + 2))
    echo -e "  ${YEL}--- Line $LINENUM | /var/log/syslog | Process: ${SERVICE:-unknown} ---${RST}"
    sed -n "${START},${END}p" /var/log/syslog | while IFS= read -r l; do echo "    $l"; done
    echo ""
  done
else
  info "Source: journalctl (no /var/log/syslog found)"
  divider
  journalctl -p err --since "10 minutes ago" --no-pager 2>/dev/null | grep -v "^--" | tail -20 | \
    while IFS= read -r line; do
      UNIT=$(echo "$line" | awk '{print $5}' | sed 's/\[.*//' | sed 's/://')
      echo -e "  ${YEL}[src: ${UNIT:-unknown}]${RST} $line"
    done
fi

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
      echo "    $COUNT error   from  $SVC"
    fi
  done

# ============================================================
section "11. OPEN FILES & FILE DESCRIPTORS"
# ============================================================

OPEN_FILES=$(lsof 2>/dev/null | wc -l)
OPEN_FILES=$(to_int "${OPEN_FILES:-0}")
info "Total open file descriptors : $OPEN_FILES"
info "System FD limit             : $(cat /proc/sys/fs/file-max)"
info "Current FD usage            : $(awk '{print $1}' /proc/sys/fs/file-nr)"
divider

if [ "$OPEN_FILES" -ge "$OFD_CRIT" ]; then
  crit "Open FDs $OPEN_FILES — file descriptor leak possible!"
  autocheck "Top FD consumers right now:"
  lsof 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 | \
    while IFS= read -r l; do echo "    $l"; done
  autocheck "FD count for top consumer:"
  TOP_PROC=$(lsof 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | awk 'NR==2{print $2}')
  TOP_PID=$(pgrep -x "$TOP_PROC" 2>/dev/null | head -1)
  [ -n "$TOP_PID" ] && echo "    $TOP_PROC has $(lsof -p "$TOP_PID" 2>/dev/null | wc -l) open FDs"
  [ -n "$TOP_PID" ] && cat /proc/"$TOP_PID"/limits 2>/dev/null | grep "open files" | \
    while IFS= read -r l; do echo "    limit: $l"; done
  autocheck "Temporarily raising system FD limit to 100000:"
  ulimit -n 100000 && echo "    Done — limit raised" || echo "    Could not raise limit"
  fix "1. Restart the leaking process (identified above): systemctl restart <service>
2. Make FD limit permanent in unit file:  LimitNOFILE=65536
   Then: systemctl daemon-reload && systemctl restart <service>
3. Raise system limit permanently:  echo 'fs.file-max=500000' >> /etc/sysctl.conf && sysctl -p"
elif [ "$OPEN_FILES" -ge "$OFD_WARN" ]; then
  warn "Open FDs $OPEN_FILES — getting high"
  autocheck "Top 5 FD consumers:"
  lsof 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -5 | \
    while IFS= read -r l; do echo "    $l"; done
  fix "1. Monitor trend: watch -n 30 'lsof | wc -l'
2. If growing steadily — restart the top consumer: systemctl restart <service>"
else
  ok "Open FDs $OPEN_FILES — healthy"
fi

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
  autocheck "Top 10 TIME_WAIT connections:"
  ss -an 2>/dev/null | grep "TIME-WAIT" | head -10 | while IFS= read -r l; do echo "    $l"; done
  autocheck "Applying TCP fin_timeout reduction and port reuse:"
  echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout && echo "    tcp_fin_timeout set to 30"
  echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse && echo "    tcp_tw_reuse enabled"
  fix "1. Monitor if TIME_WAIT count drops: watch -n 5 'ss -an | grep -c TIME-WAIT'
2. If it keeps growing — investigate connection handling in application code"
fi

if [ "$CLOSE_WAIT" -gt 50 ]; then
  crit "High CLOSE_WAIT ($CLOSE_WAIT) — app not closing connections!"
  autocheck "CLOSE_WAIT connections by process:"
  ss -anp 2>/dev/null | grep "CLOSE-WAIT" | awk '{print $6}' | \
    sed 's/.*,//' | sed 's/".*//' | sort | uniq -c | sort -rn | head -10 | \
    while IFS= read -r l; do echo "    $l"; done
  fix "1. Restart the offending service (identified above): systemctl restart <service>
2. This is a code bug — connections must be closed after remote sends FIN
3. Watch if it returns: watch -n 5 'ss -an | grep -c CLOSE-WAIT'"
fi

echo ""
info "Ping test (gateway):"
GW=$(ip route | awk '/default/ {print $3}' | head -1)
if [ -n "$GW" ]; then
  autocheck "Running extended ping (10 packets) to gateway $GW:"
  PING_RESULT=$(ping -c 10 "$GW" 2>/dev/null | tail -3)
  echo "$PING_RESULT" | while IFS= read -r l; do echo "    $l"; done
  PACKET_LOSS=$(echo "$PING_RESULT" | grep -oP '\d+(?=% packet loss)')
  PACKET_LOSS=$(to_int "${PACKET_LOSS:-0}")
  if [ "$PACKET_LOSS" -ge 50 ]; then
    crit "Packet loss ${PACKET_LOSS}% to gateway $GW"
    autocheck "Traceroute to gateway:"
    traceroute -m 5 "$GW" 2>/dev/null | while IFS= read -r l; do echo "    $l"; done
    autocheck "NIC error counters:"
    ip -s link show 2>/dev/null | grep -A4 "^[0-9]" | while IFS= read -r l; do echo "    $l"; done
    fix "1. Contact network team with traceroute output shown above
2. Escalate immediately — network loss = service disruption"
  elif [ "$PACKET_LOSS" -ge 10 ]; then
    warn "Packet loss ${PACKET_LOSS}% to gateway $GW"
    autocheck "Interface error counters:"
    ip -s link show 2>/dev/null | grep -E "errors|dropped" | while IFS= read -r l; do echo "    $l"; done
    fix "1. Contact network team if packet loss persists
2. Check physical cable / switch port"
  else
    ok "No packet loss to gateway $GW"
  fi
else
  warn "Could not determine default gateway"
fi

# ============================================================
section "14. SYSTEMD SERVICES STATUS"
# ============================================================

info "Active enabled services:"
divider
systemctl list-unit-files --type=service --state=enabled 2>/dev/null | grep enabled | while IFS= read -r line; do
  SVC=$(echo "$line" | awk '{print $1}')
  STATUS=$(systemctl is-active "$SVC" 2>/dev/null)
  [ "$STATUS" = "active" ] && echo -e "  ${GRN}[active]${RST} $SVC"
done

echo ""
info "Enabled services that are not running (unexpected):"
divider
systemctl list-unit-files --type=service --state=enabled 2>/dev/null | grep enabled | while IFS= read -r line; do
  SVC=$(echo "$line" | awk '{print $1}')
  STATUS=$(systemctl is-active "$SVC" 2>/dev/null)
  if [ "$STATUS" != "active" ]; then
    case "$SVC" in
      *@*|e2scrub*|grub*|secureboot*|sshd-keygen*|pollinate*|ua-reboot*|\
      snapd.core-fixup*|snapd.recovery*|snapd.system-shutdown*|snapd.autoimport*|\
      cloud-*|dmesg*|gpu-manager*|getty*|thermald*|open-iscsi*|vgauth*|\
      ubuntu-advantage*|open-vm-tools*) ;;
      *)
        echo -e "  ${YEL}[inactive]${RST} $SVC"
        ;;
    esac
  fi
done

# ============================================================
section "15. TOP DIRECTORY DISK CONSUMERS"
# ============================================================

info "Top 10 directories consuming disk (entire system):"
divider
du -h --max-depth=2 / 2>/dev/null | sort -rh | head -10 | while IFS= read -r line; do echo "  $line"; done

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
SWAP_IN=$(to_int "${SWAP_IN:-0}"); SWAP_OUT=$(to_int "${SWAP_OUT:-0}")

if [ "$SWAP_IN" -gt 0 ]; then
  warn "Swap-in activity detected ($SWAP_IN) — memory pressure!"
  autocheck "Current memory state:"
  free -h | while IFS= read -r l; do echo "    $l"; done
  autocheck "Top memory consumers:"
  ps aux --sort=-%mem | awk 'NR>1 && NR<=4{printf "    %-10s %-8s %-6s %s\n",$1,$2,$4,$11}'
  fix "1. Restart the largest memory consumer (shown above): systemctl restart <service>"
fi
if [ "$SWAP_OUT" -gt 0 ]; then
  warn "Swap-out activity detected ($SWAP_OUT) — paging to disk!"
  autocheck "Swap activity detail:"
  vmstat 1 5 2>/dev/null | awk 'NR>1{printf "    si=%-6s so=%s\n",$7,$8}'
  fix "1. Restart the largest memory consumer: systemctl restart <service>
2. Add more swap if needed:               bash add_swap.sh"
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

OOM_STATUS="OK"; [ "$OOM_COUNT" -gt 0 ] && OOM_STATUS="CRIT"
print_row "OOM Crashes" "$OOM_COUNT events" "$OOM_STATUS" "crit>0"

ZOMBIE_STATUS="OK"; [ "$ZOMBIE_COUNT" -gt 0 ] && ZOMBIE_STATUS="WARN"
print_row "Zombie Processes" "$ZOMBIE_COUNT" "$ZOMBIE_STATUS" "warn>0"

FAIL_STATUS="OK"; [ "$FAILED_COUNT" -gt 0 ] && FAIL_STATUS="CRIT"
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

CW_STATUS="OK"; [ "$CLOSE_WAIT" -gt 50  ] && CW_STATUS="CRIT"
TW_STATUS="OK"; [ "$TIME_WAIT"  -gt 100 ] && TW_STATUS="WARN"
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
