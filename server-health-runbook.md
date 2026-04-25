# 🖥️ Trading Server — Incident Runbook

> Structured troubleshooting guide for Linux production trading servers.
> Each issue includes symptoms, diagnosis commands, step-by-step remediation, and escalation criteria.

**Version:** 1.0 &nbsp;|&nbsp; **OS:** Ubuntu 24.04 LTS &nbsp;|&nbsp; **Updated:** Apr 2026 &nbsp;|&nbsp; **Audience:** SysAdmin / On-call Engineer

---

## 📋 Table of Contents

- [How to Use This Runbook](#-how-to-use-this-runbook)
- [§1 — CPU Issues](#1--cpu-issues)
  - [High CPU Usage](#-high-cpu-usage--critical-)
  - [High iowait (%wa)](#-high-iowait-wa--critical-)
  - [CPU Steal (%st)](#-cpu-steal-st--vm-environment--warning-)
- [§2 — Memory Issues](#2--memory-issues)
  - [High Memory Usage](#-high-memory-usage--critical-)
  - [OOM Killer Fired](#-oom-killer-fired--critical-)
  - [Swap Exhaustion](#-swap-exhaustion--warning-)
- [§3 — Disk Issues](#3--disk-issues)
  - [Disk Space Full](#-disk-space-full--critical-)
  - [Inode Exhaustion](#-inode-exhaustion--critical-)
  - [Slow Disk I/O](#-slow-disk-io-high-latency--warning-)
- [§4 — Process & Service Issues](#4--process--service-issues)
  - [Failed or Crashed Service](#-failed-or-crashed-service--critical-)
  - [Zombie Processes](#-zombie-processes--warning-)
  - [Open File Descriptor Leak](#-open-file-descriptor-leak--warning-)
- [§5 — Network Issues](#5--network-issues)
  - [Packet Loss to Gateway](#-packet-loss-to-gateway--exchange--critical-)
  - [High CLOSE_WAIT Connections](#-high-close_wait-connections--critical-)
- [§6 — Load Average](#6--load-average)
  - [Load Average Exceeds Core Count](#-load-average-exceeds-core-count--critical-)
- [§7 — Quick Reference Table](#7--quick-reference-table)
- [§8 — Escalation Contacts](#8--escalation-contacts)

---

## 📖 How to Use This Runbook

| When | What to do |
|---|---|
| 🚨 Alert fired from health script | Jump directly to that section using the table of contents |
| 🐢 Trader reports slowness | Start with §7 Quick Reference — match symptom to first command |
| 🔍 Proactive check | Use the **Diagnose First** commands before a threshold is breached |
| 📋 Post-incident review | Use **Prevention** sections to implement safeguards |

| Badge | Meaning | Response Time |
|---|---|---|
| 🔴 `CRITICAL` | Service interruption possible. Act immediately. | Escalate if unresolved in 5 min |
| ⚠️ `WARNING` | Degradation detected. Investigate promptly. | Within 15 minutes |
| ✅ `INFO` | Healthy. Reference for proactive checks. | No action required |

---

## §1 — CPU Issues

---

### 🔴 High CPU Usage `[ CRITICAL ]`

**Metric:** `%cpu > 70%` (warn) &nbsp;/&nbsp; `> 90%` (crit)

**Symptoms**
- Orders taking longer than usual to execute
- SSH login is sluggish or timing out
- `top` shows `%us` or `%sy` near 100%
- Load average exceeds core count

**Possible Causes**
- Trading process stuck in a loop or processing backlog
- Market data feed spiking during high-volatility period
- Scheduled cron job (log rotation, backup) running at wrong time
- Memory pressure causing kernel to thrash (`%sy` elevated)

**Diagnose First**
```bash
top -b -n 1 | head -20
ps aux --sort=-%cpu | head -10
uptime   # compare load to: nproc
```

**Remediation Steps**

1. Identify the offending process:
   ```bash
   ps aux --sort=-%cpu | head -10
   ```
2. Confirm it is not a legitimate spike (market open, data replay):
   ```bash
   journalctl -u trading --since '10 minutes ago' | tail -20
   ```
3. Trace what the process is doing:
   ```bash
   strace -p <PID> -c -f
   ```
4. If safe to restart the service:
   ```bash
   systemctl restart <service>
   ```
5. Graceful kill if a runaway script:
   ```bash
   kill -15 <PID>
   ```
6. Force kill only as absolute last resort:
   ```bash
   kill -9 <PID>
   ```
7. Verify CPU returns to normal:
   ```bash
   watch -n 2 'ps aux --sort=-%cpu | head -5'
   ```

> [!CAUTION]
> **Escalate when:** CPU stays above 90% for more than 5 minutes after restart, or the offending process is the core trading engine.

> [!TIP]
> **Prevention:**
> - Set CPU limits per service in systemd: `CPUQuota=80%`
> - Schedule cron jobs outside trading hours (before 07:00 or after 18:00)
> - Monitor CPU trend with `sar -u 1 10` and alert on sustained > 70%

---

### 🔴 High iowait (%wa) `[ CRITICAL ]`

**Metric:** `%iowait > 10%` (warn) &nbsp;/&nbsp; `> 25%` (crit)

**Symptoms**
- CPU shows low `%us` but system still feels slow
- `%wa` column elevated in `top` or `iostat`
- Disk reads or writes queuing — `aqu-sz > 1` in iostat
- Log files writing slowly or with truncated entries

**Possible Causes**
- Trading logs writing faster than disk can handle
- Database performing full table scans to disk
- Disk partition nearly full causing fragmentation
- Hardware disk degradation or impending failure
- Backup job running during trading hours

**Diagnose First**
```bash
iostat -x 1 5        # look at %util, r_await, w_await
iotop -o             # find which process is doing the I/O
du -h /opt/trading/logs | sort -rh | head -10
```

**Remediation Steps**

1. Confirm disk is the bottleneck (not CPU):
   ```bash
   iostat -x 1 5 | grep -v loop
   ```
2. Find which process is hitting the disk:
   ```bash
   iotop -o   # install: apt install iotop
   ```
3. Check if logs are growing uncontrolled:
   ```bash
   ls -lth /opt/trading/logs/ | head -10
   ```
4. Clean up old log files immediately:
   ```bash
   find /opt/trading/logs -name '*.log' -mtime +7 -delete
   ```
5. Clear systemd journal if large:
   ```bash
   journalctl --vacuum-time=3d
   ```
6. Check disk health (SMART data):
   ```bash
   smartctl -a /dev/sda   # apt install smartmontools
   ```
7. If `await > 50ms` disk hardware may be failing — **escalate immediately**

> [!CAUTION]
> **Escalate when:** `w_await` or `r_await` exceed 50ms, `%util` stays above 90%, or `smartctl` reports reallocated sectors.

> [!TIP]
> **Prevention:**
> - Rotate logs daily, keep only 7 days on disk
> - Mount `/opt/trading` on a dedicated SSD partition
> - Run backups after trading hours: `ionice -c3 rsync ...`
> - Set log level to `WARN` in production (not `DEBUG`)

---

### ⚠️ CPU Steal (%st) — VM Environment `[ WARNING ]`

**Metric:** `%steal > 5%` (warn) &nbsp;/&nbsp; `> 10%` (crit)

**Symptoms**
- Server feels slow despite low `%us` and `%wa`
- `%st` column elevated in `top` output
- Performance degrades at unpredictable times
- `vmstat` shows steal column non-zero

**Possible Causes**
- Physical host oversubscribed — other VMs consuming CPU
- Cloud provider throttling the instance
- Noisy neighbour on shared hypervisor

**Diagnose First**
```bash
vmstat 1 10 | awk '{print $17}'   # column 17 = steal
sar -u 1 10                       # historical CPU including steal
top -b -n 1 | grep Cpu            # check st value
```

**Remediation Steps**

1. Confirm steal is sustained (not a momentary spike):
   ```bash
   vmstat 1 30 | awk 'NR>2{print $17}' | sort -n
   ```
2. Check cloud provider console for host CPU metrics
3. Open a support ticket with provider — include `vmstat` output
4. Short-term: reduce VM workload:
   ```bash
   systemctl stop <non-critical-service>
   ```
5. Request a host migration if problem persists over 1 hour
6. Long-term: move to dedicated instance or bare metal

> [!CAUTION]
> **Escalate when:** `%steal` stays above 10% for 15 minutes and trading latency is measurably impacted.

> [!TIP]
> **Prevention:**
> - Use dedicated or reserved instances for production trading servers
> - Choose cloud regions/zones with less contention
> - Monitor `%steal` daily as part of health checks

---

## §2 — Memory Issues

---

### 🔴 High Memory Usage `[ CRITICAL ]`

**Metric:** `mem > 75%` (warn) &nbsp;/&nbsp; `> 90%` (crit)

**Symptoms**
- `free -h` shows very little free memory
- System starts using swap — `si/so` non-zero in `vmstat`
- Application response times increasing
- OOM killer may start terminating processes

**Possible Causes**
- Memory leak in trading application — RSS grows over time
- Too many concurrent connections held in memory
- Market data stored in memory not being flushed
- Cache not releasing — `buff/cache` growing unbounded

**Diagnose First**
```bash
free -h
ps aux --sort=-%mem | head -10
cat /proc/<PID>/status | grep -E 'VmRSS|VmSwap|VmPeak'
```

**Remediation Steps**

1. Find which process is consuming most memory:
   ```bash
   ps aux --sort=-%mem | head -10
   ```
2. Watch if memory is growing (possible leak):
   ```bash
   watch -n 5 'ps -p <PID> -o pid,rss,vsz,pmem --no-headers'
   ```
3. Drop page cache safely (does not affect application data):
   ```bash
   echo 1 > /proc/sys/vm/drop_caches
   ```
4. If trading service is the hog, restart it:
   ```bash
   systemctl restart trading
   ```
5. Add swap as an emergency safety net:
   ```bash
   fallocate -l 2G /swapfile
   chmod 600 /swapfile
   mkswap /swapfile && swapon /swapfile
   ```
6. Make swap permanent:
   ```bash
   echo '/swapfile none swap sw 0 0' >> /etc/fstab
   ```

> [!CAUTION]
> **Escalate when:** Memory above 90% and swap is also filling up, or OOM killer has already fired.

> [!TIP]
> **Prevention:**
> - Set memory limits in systemd unit file: `MemoryMax=4G`
> - Monitor VmRSS growth: `watch -n 60 'cat /proc/<PID>/status | grep VmRSS'`
> - Schedule application restarts during low-traffic windows if leak is known

---

### 🔴 OOM Killer Fired `[ CRITICAL ]`

**Metric:** OOM events detected in `dmesg` or journal `> 0`

**Symptoms**
- `dmesg` shows: `Out of memory: Killed process`
- Service disappeared without being explicitly stopped
- `journalctl` shows service restarted unexpectedly
- Traders report feed or order system went offline briefly

**Diagnose First**
```bash
dmesg | grep -i 'killed process'
journalctl -k --since '1 hour ago' | grep -i oom
cat /proc/<PID>/oom_score   # higher = more likely to be killed
```

**Remediation Steps**

1. Identify what was killed and when:
   ```bash
   dmesg | grep -i 'killed process' | tail -10
   ```
2. Restart the killed service immediately:
   ```bash
   systemctl restart <service>
   ```
3. Protect the critical trading process from future OOM kills:
   ```bash
   echo -1000 > /proc/$(pgrep trading)/oom_score_adj
   ```
4. Add swap to prevent future OOM events:
   ```bash
   fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
   ```
5. Find and address the memory hog:
   ```bash
   ps aux --sort=-%mem | head -10
   ```
6. Check if OOM is a recurring pattern (same service every time):
   ```bash
   journalctl -k | grep oom | tail -20
   ```

> [!CAUTION]
> **Escalate when:** OOM fires more than once in an hour, or the trading engine itself was killed.

> [!TIP]
> **Prevention:**
> - Always configure swap — minimum 2x RAM for trading servers
> - Set `oom_score_adj = -1000` for critical trading PIDs at startup
> - Set `MemoryMax` in systemd unit files to cap per-service usage
> - Alert when memory exceeds 80% — don't wait for OOM

---

### ⚠️ Swap Exhaustion `[ WARNING ]`

**Metric:** `swap > 40%` (warn) &nbsp;/&nbsp; `> 80%` (crit)

**Symptoms**
- `vmstat` shows non-zero `si` (swap-in) or `so` (swap-out) columns
- System very slow — disk I/O caused by swapping
- `free -h` shows swap nearly full
- High `%wa` in `top` due to swap I/O

**Diagnose First**
```bash
vmstat 1 5   # watch si and so columns — both should be 0 when healthy
free -h      # check swap used vs total
smem -s swap | head -10   # apt install smem
```

**Remediation Steps**

1. Confirm active swapping (not just used swap sitting idle):
   ```bash
   vmstat 1 10 | awk '{print $7, $8}'   # si so should be 0
   ```
2. Find what is in swap:
   ```bash
   smem -s swap | tail -10
   ```
3. Reduce swappiness to prefer RAM:
   ```bash
   echo 10 > /proc/sys/vm/swappiness
   ```
4. Restart the largest memory consumer:
   ```bash
   systemctl restart <service>
   ```
5. Expand swap if disk space allows:
   ```bash
   swapoff /swapfile
   fallocate -l 4G /swapfile
   mkswap /swapfile && swapon /swapfile
   ```

> [!CAUTION]
> **Escalate when:** `vmstat` shows sustained swap-in/out above 100MB/s, or swap is full and OOM is imminent.

> [!TIP]
> **Prevention:**
> - Size swap at minimum 2x RAM
> - Set `vm.swappiness=10` permanently in `/etc/sysctl.conf`
> - Alert if `vmstat` si/so are non-zero for more than 60 seconds

---

## §3 — Disk Issues

---

### 🔴 Disk Space Full `[ CRITICAL ]`

**Metric:** `disk > 80%` (warn) &nbsp;/&nbsp; `> 90%` (crit)

**Symptoms**
- Application cannot write log files — orders may fail silently
- `df -h` shows 90%+ on a partition
- Error messages: `No space left on device`
- New processes cannot start (cannot write PID file)

**Diagnose First**
```bash
df -h                                         # which partition is full?
du -h /opt/trading | sort -rh | head -10      # largest directories
find / -type f -size +500M 2>/dev/null        # files over 500MB
lsof | grep deleted | head -20                # deleted but still held open
```

**Remediation Steps**

1. Identify the full partition and biggest consumers:
   ```bash
   df -h && du -h /var | sort -rh | head -10
   ```
2. Delete old log files immediately:
   ```bash
   find /opt/trading/logs -name '*.log' -mtime +7 -delete
   ```
3. Clear systemd journal:
   ```bash
   journalctl --vacuum-size=500M
   ```
4. Clean APT cache:
   ```bash
   apt clean
   ```
5. Remove old core dumps:
   ```bash
   find / -name 'core.*' -mtime +1 -delete 2>/dev/null
   ```
6. Release space from deleted-but-open files by restarting the holding process:
   ```bash
   lsof | grep deleted
   systemctl restart <process-holding-deleted-file>
   ```

> [!CAUTION]
> **Escalate when:** Disk at 95%+ and cannot immediately free space. Trading logs cannot write — this is a service-impacting incident.

> [!TIP]
> **Prevention:**
> - Set up `logrotate` for `/opt/trading/logs` — rotate daily, keep 7 days
> - Add cron cleanup: `find /opt/trading/logs -name '*.log' -mtime +7 -delete`
> - Alert at 80% — never let it reach 90% unmanaged
> - Mount `/opt/trading` on a separate partition from `/`

---

### 🔴 Inode Exhaustion `[ CRITICAL ]`

**Metric:** `inode usage > 80%` (warn) &nbsp;/&nbsp; `> 90%` (crit)

**Symptoms**
- `df -h` shows space available but cannot create new files
- Error: `No space left on device` despite disk not being full
- `df -i` shows inode usage at 90%+
- Application cannot create new log files, temp files, or sockets

**Possible Causes**
- Thousands of tiny log files or temp files accumulating
- Mail spool filling with unread system mail
- Session files, PID files, or cache files not being cleaned
- Application creating a new file per trade without cleanup

**Diagnose First**
```bash
df -i    # inode usage per filesystem

# Find directories with the most files:
find / -xdev -type d | xargs -I{} sh -c \
  'echo $(ls {} 2>/dev/null | wc -l) {}' 2>/dev/null | sort -rn | head -10
```

**Remediation Steps**

1. Confirm it is an inode problem, not disk space:
   ```bash
   df -h && df -i   # disk has space but inodes are full
   ```
2. Find the directory with the most files:
   ```bash
   for d in /var/*/; do echo $(find $d | wc -l) $d; done | sort -rn | head -10
   ```
3. Clean up small stale files:
   ```bash
   find /tmp -mtime +3 -delete
   find /var/tmp -mtime +7 -delete
   ```
4. Check and clean mail spool:
   ```bash
   ls -la /var/spool/mail/
   cat /dev/null > /var/spool/mail/root
   ```
5. Delete old small log files:
   ```bash
   find /opt/trading/logs -name '*.log' -mtime +3 -delete
   ```
6. Verify inodes are freed:
   ```bash
   df -i
   ```

> [!CAUTION]
> **Escalate when:** Inodes at 99% and cleanup is not freeing enough. Filesystem restructuring may be required.

> [!TIP]
> **Prevention:**
> - Never log one-file-per-trade — use rolling log files
> - Cron: clean `/tmp` and `/var/tmp` weekly
> - Monitor inode usage as part of weekly health checks
> - Create `/opt/trading` on its own partition with appropriate inode count

---

### ⚠️ Slow Disk I/O (High Latency) `[ WARNING ]`

**Metric:** `r_await` or `w_await > 20ms` (warn) &nbsp;/&nbsp; `> 50ms` (crit) &nbsp;|&nbsp; `%util > 70%`

**Symptoms**
- Application slow but CPU is idle
- `%iowait` elevated in `top`
- `iostat` shows `r_await` or `w_await > 20ms`
- `aqu-sz` (queue depth) above 1 in `iostat` output

**Possible Causes**
- Disk is saturated — too many concurrent read/write operations
- HDD (spinning disk) too slow for trading workload — SSD needed
- Disk hardware beginning to fail (reallocated sectors)
- RAID rebuild in progress

**Diagnose First**
```bash
iostat -x 1 5                    # r_await, w_await, %util, aqu-sz
iotop -o                         # which process is causing I/O
smartctl -a /dev/sda             # disk health and error count
```

**Remediation Steps**

1. Check which disk is slow:
   ```bash
   iostat -x 1 5 | grep -v loop
   ```
2. Find which process is responsible:
   ```bash
   iotop -o
   ```
3. Check SMART health — look for reallocated sectors:
   ```bash
   smartctl -a /dev/sda | grep -i 'reallocated\|error\|pending'
   ```
4. Reduce write pressure — lower log verbosity in trading config:
   ```bash
   # In trading config: set log_level = WARN (not DEBUG)
   ```
5. Use `tmpfs` for non-critical temp data:
   ```bash
   mount -t tmpfs -o size=512m tmpfs /opt/trading/tmp
   ```
6. If SMART shows errors — disk is failing, **replace immediately and escalate**

> [!CAUTION]
> **Escalate when:** `%util` sustains above 90% or SMART reports pending/reallocated sectors. Disk failure is imminent — initiate backup immediately.

> [!TIP]
> **Prevention:**
> - Use SSDs for trading server storage
> - Separate OS, logs, and market data onto different volumes
> - Run `smartctl` health check weekly via cron
> - Use `ionice -c3` for backup jobs to lower their I/O priority

---

## §4 — Process & Service Issues

---

### 🔴 Failed or Crashed Service `[ CRITICAL ]`

**Metric:** `systemctl --failed` shows 1 or more units

**Symptoms**
- Traders report a specific function is down (order entry, market data, etc.)
- `systemctl status <service>` shows `failed`
- `journalctl` shows FATAL or non-zero exit code
- Port is no longer listening (`ss -tulnp`)

**Diagnose First**
```bash
systemctl --failed
systemctl status <service>
journalctl -u <service> -n 100 --no-pager
```

**Remediation Steps**

1. Identify all failed services:
   ```bash
   systemctl --failed
   ```
2. Read the last 50 lines of logs to find root cause:
   ```bash
   journalctl -u <service> -n 50 --no-pager
   ```
3. Check exit code and signal:
   ```bash
   systemctl show <service> | grep -E 'ExecMainStatus|Result'
   ```
4. Attempt a restart:
   ```bash
   systemctl restart <service>
   ```
5. Watch if it stays up:
   ```bash
   watch -n 3 systemctl is-active <service>
   ```
6. If config was recently changed, test config syntax:
   ```bash
   <service> --config-test   # flag varies by service
   ```
7. Reset failed state after fixing:
   ```bash
   systemctl reset-failed <service>
   ```
8. Check that all dependencies are running:
   ```bash
   systemctl list-dependencies <service>
   ```

> [!CAUTION]
> **Escalate when:** Service fails to stay up after 3 restart attempts, or root cause is not identifiable from logs within 5 minutes.

> [!TIP]
> **Prevention:**
> - Set `Restart=on-failure` and `RestartSec=5` in systemd unit files
> - Set `StartLimitIntervalSec` and `StartLimitBurst` to prevent restart loops
> - Configure health check endpoints and monitor them externally

---

### ⚠️ Zombie Processes `[ WARNING ]`

**Metric:** `ps aux` shows processes in `Z` (zombie) state

**Symptoms**
- `ps aux` shows `Z` in the state column
- Process count growing over time without release
- Parent process may have crashed or is not reaping children

**Possible Causes**
- Parent process crashed without waiting for child to finish
- Parent has a bug — not calling `wait()` on child exit
- Rapid process spawning without proper cleanup

**Diagnose First**
```bash
ps aux | awk '$8=="Z"'                    # list zombies
ps -o ppid= -p <ZOMBIE_PID>              # find parent PID
ps aux | grep <PPID>                     # what is the parent?
```

**Remediation Steps**

1. Find zombie PIDs and their parent:
   ```bash
   ps aux | awk '$8=="Z" {print "Zombie:", $2, "Parent:", $3}'
   ```
2. Check if parent is healthy:
   ```bash
   ps aux | grep <PPID>
   ```
3. Gracefully restart the parent process:
   ```bash
   systemctl restart <parent-service>
   ```
4. If parent is stuck, force it:
   ```bash
   kill -15 <PPID>   # graceful
   kill -9 <PPID>    # force — zombies auto-clean after parent exits
   ```
5. Verify zombies are gone:
   ```bash
   ps aux | awk '$8=="Z"'
   ```

> **Note:** You cannot kill a zombie directly — only killing the parent process cleans them up.

> [!CAUTION]
> **Escalate when:** Zombie count growing rapidly (> 50), or parent process is the trading engine itself.

> [!TIP]
> **Prevention:**
> - Ensure trading application properly calls `wait()` or `waitpid()` on child exit
> - Use systemd to manage child processes — it reaps zombies automatically
> - Alert when zombie count exceeds 5

---

### ⚠️ Open File Descriptor Leak `[ WARNING ]`

**Metric:** `open FDs > 10,000` (warn) &nbsp;/&nbsp; `> 50,000` (crit)

**Symptoms**
- Application fails to open new connections or files
- Error: `Too many open files`
- `lsof | wc -l` returns very large number
- FD count grows steadily over time without releasing

**Possible Causes**
- Application opens files or sockets but never closes them
- Connection pool not releasing connections on timeout
- Log file handles not being released after rotation
- System FD limit too low for workload

**Diagnose First**
```bash
lsof | wc -l                                   # total open FDs
lsof 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -10
cat /proc/<PID>/limits | grep 'open files'     # per-process limit
cat /proc/sys/fs/file-max                      # system-wide limit
```

**Remediation Steps**

1. Find which process is the leaker:
   ```bash
   lsof 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -10
   ```
2. Temporarily raise the system FD limit:
   ```bash
   ulimit -n 100000
   ```
3. Restart the leaking service:
   ```bash
   systemctl restart <service>
   ```
4. Raise per-service FD limit permanently in unit file:
   ```bash
   # Add to /etc/systemd/system/<service>.service:
   LimitNOFILE=65536
   ```
5. Reload and restart:
   ```bash
   systemctl daemon-reload && systemctl restart <service>
   ```
6. Raise system-wide limit permanently:
   ```bash
   echo 'fs.file-max = 500000' >> /etc/sysctl.conf && sysctl -p
   ```

> [!CAUTION]
> **Escalate when:** FD count at system limit and application is rejecting connections — immediate service restart required.

> [!TIP]
> **Prevention:**
> - Set `LimitNOFILE=65536` in all systemd unit files
> - Ensure application closes file handles explicitly after use
> - Monitor daily: `lsof -p <PID> | wc -l`

---

## §5 — Network Issues

---

### 🔴 Packet Loss to Gateway / Exchange `[ CRITICAL ]`

**Metric:** `> 10%` packet loss (warn) &nbsp;/&nbsp; `> 50%` packet loss (crit)

**Symptoms**
- Traders report disconnections or feed drops
- `ping` to gateway shows packet loss
- Orders not reaching exchange — connection timeouts
- `traceroute` shows drops at first or second hop

**Possible Causes**
- Network cable or switch port faulty
- NIC hardware issue or driver crash
- Network interface misconfigured or duplex mismatch
- Upstream network infrastructure failure

**Diagnose First**
```bash
ping -c 20 <gateway-ip>       # how much loss?
traceroute <exchange-ip>      # where does it drop?
ip -s link show eth0          # NIC error counters
ethtool eth0 | grep -i link  # link speed and duplex
```

**Remediation Steps**

1. Run extended ping to quantify loss:
   ```bash
   ping -c 50 $(ip route | awk '/default/{print $3}')
   ```
2. Trace the route to identify where packets drop:
   ```bash
   traceroute <exchange-ip>
   ```
3. Check NIC for hardware errors:
   ```bash
   ip -s link show eth0   # look for 'errors' or 'dropped'
   ```
4. Check link speed and duplex:
   ```bash
   ethtool eth0
   ```
5. Check `dmesg` for NIC errors:
   ```bash
   dmesg | grep -i 'eth0\|network\|link'
   ```
6. Try reloading the NIC driver:
   ```bash
   modprobe -r <driver> && modprobe <driver>
   ```
7. Escalate to network team with `traceroute` output

> [!CAUTION]
> **Escalate when:** Any packet loss to the exchange — trading halt may be required. Contact network team and exchange immediately.

> [!TIP]
> **Prevention:**
> - Use bonded NICs (active/passive) for redundancy
> - Monitor with `ping` every 30 seconds — alert on any loss
> - Keep spare NIC and cables on-site

---

### 🔴 High CLOSE_WAIT Connections `[ CRITICAL ]`

**Metric:** `CLOSE_WAIT count > 50`

**Symptoms**
- `ss -an | grep CLOSE-WAIT` shows many entries
- Application cannot open new connections despite port being available
- Connection pool exhausted

**Possible Causes**
- Application code not closing connections after remote side closes
- Missing timeout on idle connections
- Bug in connection pool or session management

**Diagnose First**
```bash
ss -an | grep -c CLOSE-WAIT
ss -anp | grep CLOSE-WAIT | head -20   # which process?
```

**Remediation Steps**

1. Confirm count and identify which process:
   ```bash
   ss -anp | grep CLOSE-WAIT | awk '{print $6}' | sort | uniq -c
   ```
2. Restart the offending application:
   ```bash
   systemctl restart <service>
   ```
3. Watch if `CLOSE_WAIT` returns after restart:
   ```bash
   watch -n 5 'ss -an | grep -c CLOSE-WAIT'
   ```
4. Enable TCP keepalive to detect and close dead connections:
   ```bash
   echo 60 > /proc/sys/net/ipv4/tcp_keepalive_time
   echo 10 > /proc/sys/net/ipv4/tcp_keepalive_intvl
   echo 6  > /proc/sys/net/ipv4/tcp_keepalive_probes
   ```
5. Root cause: this is a **code bug** — connections must be explicitly closed after receiving `FIN` from peer. Raise with development team.

> [!CAUTION]
> **Escalate when:** `CLOSE_WAIT` above 200 and connection pool is exhausted — application cannot accept new trading connections.

> [!TIP]
> **Prevention:**
> - Implement proper connection lifecycle in trading application
> - Use connection timeout settings in all client libraries
> - Enable TCP keepalives at socket level in application code

---

## §6 — Load Average

---

### 🔴 Load Average Exceeds Core Count `[ CRITICAL ]`

**Metric:** `load > 0.8 × cores` (warn) &nbsp;/&nbsp; `> 1.2 × cores` (crit)

**Symptoms**
- `uptime` shows 1min load above `nproc` value
- `vmstat` `r` column (run queue) exceeds core count
- System slow to respond to commands
- SSH login takes several seconds

**Possible Causes**
- CPU-bound process consuming all cores
- High `iowait` causing processes to block on disk
- Too many processes spawned simultaneously
- Insufficient CPU for current workload

**Diagnose First**
```bash
uptime && nproc                         # compare load to cores
vmstat 1 5                              # 'r' = run queue, 'b' = blocked
top -b -n 1 | head -20                 # who is consuming?
```

**Remediation Steps**

1. Compare load to core count:
   ```bash
   echo "Load: $(cat /proc/loadavg | awk '{print $1}')  Cores: $(nproc)"
   ```
2. Check if it is CPU or I/O causing the load:
   ```bash
   vmstat 1 5   # 'b' high = blocked on I/O;  'r' high = CPU bound
   ```
3. If `iowait` is the cause — follow the [Disk I/O section](#-slow-disk-io-high-latency--warning-)
4. If CPU is the cause — follow the [High CPU Usage section](#-high-cpu-usage--critical-)
5. If load is sustained above 2x cores, stop non-critical services:
   ```bash
   systemctl stop <non-essential-service>
   ```

> [!CAUTION]
> **Escalate when:** Load average at 3x core count for more than 5 minutes and root cause cannot be identified.

> [!TIP]
> **Prevention:**
> - Set cgroups CPU limits for non-critical services
> - Spread scheduled jobs to avoid simultaneous execution
> - Scale horizontally if sustained overload is the norm

---

## §7 — Quick Reference Table

> Use during a live incident. Match the symptom, run the first command, apply the fix.

| Symptom | First Command | Likely Fix |
|---|---|---|
| System slow, SSH laggy | `uptime && top -b -n1 \| head -5` | Find CPU hog: `ps aux --sort=-%cpu` |
| CPU busy but nothing obvious | `top -b -n1 \| grep Cpu` (check `%wa`) | High iowait → run `iostat -x 1 5` |
| "No space left on device" | `df -h` | Clean logs: `find /opt/trading/logs -mtime +7 -delete` |
| Disk has space but can't create files | `df -i` | Inode full → delete small files in `/tmp` |
| App offline, no crash visible | `systemctl --failed` | Restart: `systemctl restart <service>` |
| Orders not reaching exchange | `ping -c 10 <exchange-ip>` | Packet loss → contact network team |
| App slow, CPU is idle | `iostat -x 1 3` (check `%util`) | Disk bottleneck → `iotop` to find hog |
| RAM nearly full | `free -h && ps aux --sort=-%mem \| head -5` | Restart hog or add swap |
| App fails to open connections | `lsof \| wc -l` | FD leak → restart service, raise `LimitNOFILE` |
| Random process killed | `dmesg \| grep -i 'killed process'` | OOM → add swap, protect with `oom_score_adj` |
| New connections failing | `ss -an \| grep -c CLOSE-WAIT` | `CLOSE_WAIT` high → restart service, fix in code |
| VM feels slow, CPU fine | `top -b -n1 \| grep st` | CPU steal → contact cloud provider |

---

## §8 — Escalation Contacts

> Fill in before deploying this runbook. Keep this page accessible offline.

| Role | Name | Contact | Escalate When |
|---|---|---|---|
| Senior Engineer | | | 5 min unresolved |
| Network Team | | | Any packet loss |
| Cloud Provider | | | `%steal > 10%` |
| Exchange Support | | | Order path down |
| Security Team | | | Suspicious process |

---

*Trading Server Incident Runbook — v1.0 &nbsp;|&nbsp; Ubuntu 24.04 LTS · systemd · /opt/trading*
