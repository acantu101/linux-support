# linux-support
scripts to troubleshoot and investigate issues in a linux env
# 🖥️ Server Health Report

A comprehensive bash diagnostic script for Linux servers. Generates a full health report with color-coded alerts, threshold analysis, and a summary table — all saved to a log file for incident history.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Report Sections](#report-sections)
- [Thresholds](#thresholds)
- [Scheduling with Cron](#scheduling-with-cron)
- [Output Example](#output-example)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

When a client calls saying *"everything is slow"* you have minutes to diagnose the problem. This script gives you a full-system snapshot in one command — covering CPU, memory, disk, network, services, logs, and more — with clear `✅ OK`, `⚠️ WARN`, and `🔴 CRIT` indicators so you know exactly where to look.

Reports are saved to `/opt/server-health/logs/health_report_<timestamp>.txt` so you can build a history of incidents over time.

## 📖 Runbook

After cloning, open the runbook locally:

```bash
# Mac
open RUNBOOK.html

# Linux
xdg-open RUNBOOK.html

# Windows
start RUNBOOK.html
```

---

## Features

- **CPU analysis** — usage, iowait, steal, top hogs by process
- **Load average** — compared against actual core count
- **Memory breakdown** — used, free, swap, buff/cache
- **OOM crash detection** — scans dmesg and journalctl
- **Disk usage** — per partition with largest files and directories
- **Inode health** — per filesystem
- **Disk I/O performance** — iostat read/write latency and utilisation
- **Zombie process detection** — count and PID listing
- **Crashed service detection** — failed systemd units + FATAL log entries
- **Error analysis** — total errors in last 10 minutes with context lines
- **Open file descriptors** — against system limits
- **Listening ports** — all open ports and bound services
- **Network health** — connection states, TIME_WAIT, packet loss
- **Service status** — all enabled services checked active/inactive
- **vmstat snapshot** — swap activity, run queue, block I/O
- **Summary table** — every metric with value, status, and threshold

---

## Requirements

| Tool | Purpose | Install |
|------|---------|---------|
| `bash` | Script runtime | Pre-installed |
| `top` | CPU/process stats | Pre-installed |
| `iostat` | Disk I/O stats | `apt install sysstat` |
| `vmstat` | Virtual memory stats | `apt install procps` |
| `ss` | Network connections | `apt install iproute2` |
| `lsof` | Open file descriptors | `apt install lsof` |
| `systemctl` | Service status | Pre-installed (systemd) |
| `journalctl` | System logs | Pre-installed (systemd) |
| `dmesg` | Kernel messages | Pre-installed |
| `bc` | Math calculations | `apt install bc` |

Install all at once:

```bash
apt install sysstat procps iproute2 lsof bc -y
```

---

## Installation

```bash
# clone the repo
git clone https://github.com/yourusername/server-health-report.git

# copy script to server-health bin directory
cp server_health_report.sh /opt/server-health/bin/

# make it executable
chmod 755 /opt/server-health/bin/server_health_report.sh

# create log directory
mkdir -p /opt/server-health/logs
```

---

## Usage

```bash
# run as root
bash /opt/server-health/bin/server_health_report.sh
```

> **Note:** Must be run as `root` to access all `/proc` entries, `dmesg`, and full `lsof` output.

---

## Report Sections

| # | Section | What It Checks |
|---|---------|---------------|
| 1 | CPU Analysis | Usage %, iowait, steal, top 5 CPU hogs |
| 2 | Load Average | 1min / 5min / 15min vs core count |
| 3 | Memory Analysis | Used, free, swap, top 5 memory hogs |
| 4 | OOM Crashes | dmesg + journal OOM kill events |
| 5 | Disk Usage | Per partition, top dirs, files > 100MB |
| 6 | Inode Health | Per filesystem inode usage % |
| 7 | Disk I/O | iostat latency (r_await / w_await), util% |
| 8 | Zombie Processes | Count and offending PIDs |
| 9 | Crashed Services | Failed systemd units + FATAL log entries |
| 10 | Error Analysis | Errors last 10min + 1 line before / 2 after |
| 11 | Open Files | FD count vs system limits |
| 12 | Listening Ports | All open ports and services |
| 13 | Network Health | ESTABLISHED / TIME_WAIT / CLOSE_WAIT + ping |
| 14 | Service Status | All enabled services active/inactive |
| 15 | Disk Consumers | Top 10 directories system-wide |
| 16 | vmstat Snapshot | Swap in/out, run queue, block I/O |
| 17 | Summary Table | Every metric with status and threshold |

---

## Thresholds

All thresholds are defined at the top of the script and can be customised:

```bash
# CPU
CPU_WARN=70        # warn above 70% usage
CPU_CRIT=90        # critical above 90% usage

# Memory
MEM_WARN=75        # warn above 75% used
MEM_CRIT=90        # critical above 90% used

# Swap
SWAP_WARN=40
SWAP_CRIT=80

# Disk
DISK_WARN=80
DISK_CRIT=90

# I/O wait
IOWAIT_WARN=10
IOWAIT_CRIT=25

# Disk await latency (ms)
AWAIT_WARN=20
AWAIT_CRIT=50

# Disk utilisation
UTIL_WARN=70
UTIL_CRIT=85

# Inodes
INODE_WARN=80
INODE_CRIT=90

# Open file descriptors
OFD_WARN=10000
OFD_CRIT=50000

# Load average multiplier of core count
LOAD_WARN=0.8      # warn at 80% of core count
LOAD_CRIT=1.2      # critical at 120% of core count
```

---

## Scheduling with Cron

Run automatically every 5 minutes and build a history of reports:

```bash
crontab -e
```

Add the line:

```
*/5 * * * * bash /opt/server-health/bin/server_health_report.sh
```

Reports accumulate in `/opt/server-health/logs/` — useful for post-incident analysis:

```
health_report_20260425_093000.txt
health_report_20260425_093500.txt
health_report_20260425_094000.txt   ← issue starts here
health_report_20260425_094500.txt   ← degradation visible
```

To clean up old reports automatically (keep last 7 days):

```bash
find /opt/server-health/logs -name "health_report_*.txt" -mtime +7 -delete
```

---

## Output Example

```
════════════════════════════════════════════════════
  17. ANALYSIS SUMMARY TABLE
════════════════════════════════════════════════════

  METRIC                         VALUE           STATUS     THRESHOLD
  ------------------------------ --------------- ---------- ---------
  CPU Usage                      2%              ✅ OK      warn>70% crit>90%
  CPU iowait                     0%              ✅ OK      warn>10% crit>25%
  CPU Steal (VM)                 0%              ✅ OK      warn>5% crit>10%
  Load Avg (1min)                0.00            ✅ OK      warn>3.2 crit>4.8
  Memory Usage                   26%             ✅ OK      warn>75% crit>90%
  Swap Usage                     0%              ✅ OK      warn>40% crit>80%
  OOM Crashes                    0 events        ✅ OK      crit>0
  Zombie Processes               0               ✅ OK      warn>0
  Failed Services                0               ✅ OK      crit>0
  FATAL Errors (10min)           0               ✅ OK      warn>1 crit>10
  Total Errors (10min)           3               ✅ OK      warn>10 crit>50
  Open File Descriptors          1842            ✅ OK      warn>10000 crit>50000
  CLOSE_WAIT conns               0               ✅ OK      crit>50
  TIME_WAIT conns                4               ✅ OK      warn>100
  Disk Usage (/)                 34%             ✅ OK      warn>80% crit>90%
  Inode Usage (/)                12%             ✅ OK      warn>80% crit>90%
```

---

## Contributing

Pull requests welcome. To add a new section:

1. Add your check between existing sections
2. Follow the `ok()` / `warn()` / `crit()` helper pattern
3. Add the metric to the summary table in section 17
4. Define thresholds as variables at the top of the script

---

## License

MIT License — free to use, modify, and distribute.

---

> Built for Linux server environments running Ubuntu/Debian with systemd.
> Tested on Ubuntu 24.04 (Noble).
