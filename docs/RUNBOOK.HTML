<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Server Health — Incident Runbook</title>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400;500;700&family=Syne:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --bg:         #0d1117;
    --bg2:        #161b22;
    --bg3:        #1c2128;
    --bg4:        #21262d;
    --border:     #30363d;
    --border2:    #3d444d;
    --text:       #c9d1d9;
    --text-dim:   #8b949e;
    --text-bright:#f0f6fc;
    --blue:       #1f6feb;
    --blue-dim:   #0d419d;
    --blue-glow:  #388bfd;
    --cyan:       #39d353;
    --red:        #f85149;
    --red-dim:    #3d1a1a;
    --red-border: #6e1b1b;
    --yellow:     #e3b341;
    --yellow-dim: #2d2010;
    --yellow-bdr: #5a3e0a;
    --green:      #3fb950;
    --green-dim:  #12261e;
    --green-bdr:  #1a5232;
    --mono:       'JetBrains Mono', monospace;
    --sans:       'Syne', sans-serif;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  html { scroll-behavior: smooth; }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: var(--mono);
    font-size: 14px;
    line-height: 1.7;
    min-height: 100vh;
  }

  /* ── SCANLINE OVERLAY ── */
  body::before {
    content: '';
    position: fixed;
    inset: 0;
    background: repeating-linear-gradient(
      0deg,
      transparent,
      transparent 2px,
      rgba(0,0,0,0.04) 2px,
      rgba(0,0,0,0.04) 4px
    );
    pointer-events: none;
    z-index: 9999;
  }

  /* ── SIDEBAR ── */
  .sidebar {
    position: fixed;
    top: 0; left: 0;
    width: 260px;
    height: 100vh;
    background: var(--bg2);
    border-right: 1px solid var(--border);
    overflow-y: auto;
    z-index: 100;
    display: flex;
    flex-direction: column;
  }

  .sidebar-logo {
    padding: 24px 20px 16px;
    border-bottom: 1px solid var(--border);
  }

  .sidebar-logo .srv {
    font-family: var(--sans);
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.15em;
    color: var(--text-dim);
    text-transform: uppercase;
    margin-bottom: 4px;
  }

  .sidebar-logo .title {
    font-family: var(--sans);
    font-size: 18px;
    font-weight: 800;
    color: var(--text-bright);
    line-height: 1.2;
  }

  .sidebar-logo .title span { color: var(--blue-glow); }

  .sidebar-meta {
    padding: 10px 20px;
    border-bottom: 1px solid var(--border);
    font-size: 11px;
    color: var(--text-dim);
  }

  .sidebar-meta div { margin-bottom: 2px; }
  .sidebar-meta strong { color: var(--text); }

  .nav-section-label {
    padding: 14px 20px 4px;
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--text-dim);
  }

  .nav a {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 7px 20px;
    color: var(--text-dim);
    text-decoration: none;
    font-size: 12px;
    font-family: var(--mono);
    transition: all 0.15s;
    border-left: 2px solid transparent;
  }

  .nav a:hover {
    color: var(--text-bright);
    background: var(--bg3);
    border-left-color: var(--blue-glow);
  }

  .nav a .badge {
    margin-left: auto;
    font-size: 9px;
    font-weight: 700;
    padding: 1px 5px;
    border-radius: 3px;
  }

  .badge-crit { background: var(--red-dim);    color: var(--red);    border: 1px solid var(--red-border); }
  .badge-warn { background: var(--yellow-dim); color: var(--yellow); border: 1px solid var(--yellow-bdr); }
  .badge-info { background: var(--green-dim);  color: var(--green);  border: 1px solid var(--green-bdr); }

  .nav a.section-link {
    color: var(--text);
    font-weight: 500;
    font-size: 12px;
    padding-top: 9px;
    padding-bottom: 9px;
  }

  /* ── MAIN ── */
  .main {
    margin-left: 260px;
    padding: 48px 56px;
    max-width: 1100px;
  }

  /* ── HERO ── */
  .hero {
    border: 1px solid var(--border);
    background: linear-gradient(135deg, var(--bg2) 0%, var(--bg3) 100%);
    border-radius: 8px;
    padding: 48px;
    margin-bottom: 48px;
    position: relative;
    overflow: hidden;
  }

  .hero::before {
    content: '';
    position: absolute;
    top: -80px; right: -80px;
    width: 300px; height: 300px;
    background: radial-gradient(circle, rgba(31,111,235,0.15) 0%, transparent 70%);
    pointer-events: none;
  }

  .hero-eyebrow {
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--blue-glow);
    margin-bottom: 12px;
  }

  .hero h1 {
    font-family: var(--sans);
    font-size: 42px;
    font-weight: 800;
    color: var(--text-bright);
    line-height: 1.1;
    margin-bottom: 16px;
  }

  .hero h1 span { color: var(--blue-glow); }

  .hero p {
    color: var(--text-dim);
    font-size: 14px;
    max-width: 580px;
    margin-bottom: 28px;
    line-height: 1.8;
  }

  .hero-tags { display: flex; gap: 8px; flex-wrap: wrap; }

  .tag {
    background: var(--bg4);
    border: 1px solid var(--border2);
    color: var(--text-dim);
    font-size: 11px;
    padding: 4px 10px;
    border-radius: 4px;
  }

  /* ── HOW TO USE ── */
  .how-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
    margin: 20px 0;
  }

  .how-card {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 16px;
    display: flex;
    gap: 12px;
    align-items: flex-start;
  }

  .how-card .icon {
    font-size: 20px;
    flex-shrink: 0;
    line-height: 1;
    margin-top: 2px;
  }

  .how-card strong {
    display: block;
    color: var(--text-bright);
    font-size: 13px;
    margin-bottom: 4px;
  }

  .how-card p { color: var(--text-dim); font-size: 12px; line-height: 1.6; }

  /* ── SECTION HEADER ── */
  .section-header {
    display: flex;
    align-items: center;
    gap: 16px;
    margin: 56px 0 28px;
    padding-bottom: 16px;
    border-bottom: 1px solid var(--border);
  }

  .section-number {
    font-family: var(--sans);
    font-size: 11px;
    font-weight: 800;
    letter-spacing: 0.1em;
    color: var(--blue-glow);
    background: var(--blue-dim);
    border: 1px solid var(--blue);
    padding: 3px 10px;
    border-radius: 3px;
    white-space: nowrap;
  }

  .section-header h2 {
    font-family: var(--sans);
    font-size: 22px;
    font-weight: 700;
    color: var(--text-bright);
  }

  /* ── ISSUE CARD ── */
  .issue-card {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: 8px;
    margin-bottom: 24px;
    overflow: hidden;
  }

  .issue-header {
    display: flex;
    align-items: center;
    gap: 14px;
    padding: 18px 24px;
    cursor: pointer;
    user-select: none;
    transition: background 0.15s;
    border-bottom: 1px solid transparent;
  }

  .issue-header:hover { background: var(--bg3); }
  .issue-header.open { border-bottom-color: var(--border); }

  .severity-dot {
    width: 10px; height: 10px;
    border-radius: 50%;
    flex-shrink: 0;
  }
  .dot-crit { background: var(--red);    box-shadow: 0 0 6px var(--red); }
  .dot-warn { background: var(--yellow); box-shadow: 0 0 6px var(--yellow); }
  .dot-info { background: var(--green);  box-shadow: 0 0 6px var(--green); }

  .issue-title {
    font-family: var(--sans);
    font-size: 16px;
    font-weight: 700;
    color: var(--text-bright);
    flex: 1;
  }

  .severity-badge {
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.08em;
    padding: 3px 8px;
    border-radius: 3px;
    text-transform: uppercase;
  }

  .sev-crit { background: var(--red-dim);    color: var(--red);    border: 1px solid var(--red-border); }
  .sev-warn { background: var(--yellow-dim); color: var(--yellow); border: 1px solid var(--yellow-bdr); }
  .sev-info { background: var(--green-dim);  color: var(--green);  border: 1px solid var(--green-bdr); }

  .metric-tag {
    font-size: 11px;
    color: var(--text-dim);
    background: var(--bg4);
    border: 1px solid var(--border);
    padding: 2px 8px;
    border-radius: 3px;
    font-family: var(--mono);
  }

  .chevron {
    color: var(--text-dim);
    transition: transform 0.2s;
    font-size: 12px;
  }

  .issue-header.open .chevron { transform: rotate(180deg); }

  .issue-body {
    display: none;
    padding: 24px;
  }

  .issue-body.open { display: block; }

  /* ── SUBSECTIONS ── */
  .sub-label {
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--blue-glow);
    margin: 20px 0 10px;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .sub-label::after {
    content: '';
    flex: 1;
    height: 1px;
    background: var(--border);
  }

  .sub-label:first-child { margin-top: 0; }

  /* ── LISTS ── */
  ul.rb-list { list-style: none; padding: 0; }

  ul.rb-list li {
    color: var(--text);
    font-size: 13px;
    padding: 4px 0 4px 20px;
    position: relative;
    line-height: 1.6;
  }

  ul.rb-list li::before {
    content: '▸';
    position: absolute;
    left: 0;
    color: var(--blue-glow);
    font-size: 10px;
    top: 6px;
  }

  /* ── STEPS ── */
  ol.steps { list-style: none; counter-reset: step; padding: 0; }

  ol.steps li {
    counter-increment: step;
    display: flex;
    gap: 14px;
    padding: 6px 0;
    font-size: 13px;
    align-items: flex-start;
    line-height: 1.6;
  }

  ol.steps li::before {
    content: counter(step);
    background: var(--blue-dim);
    color: var(--blue-glow);
    border: 1px solid var(--blue);
    font-size: 10px;
    font-weight: 700;
    width: 20px; height: 20px;
    border-radius: 3px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    margin-top: 2px;
  }

  /* ── CODE ── */
  .cmd {
    display: block;
    background: #010409;
    border: 1px solid var(--border);
    border-left: 3px solid var(--blue-glow);
    border-radius: 0 4px 4px 0;
    padding: 10px 14px;
    font-family: var(--mono);
    font-size: 12px;
    color: #79c0ff;
    margin: 8px 0;
    overflow-x: auto;
    white-space: pre;
  }

  .cmd .comment { color: var(--text-dim); }

  /* ── DIAGNOSE BLOCK ── */
  .diagnose-block {
    background: #010409;
    border: 1px solid var(--border);
    border-radius: 6px;
    overflow: hidden;
    margin: 8px 0;
  }

  .diagnose-bar {
    background: var(--bg4);
    border-bottom: 1px solid var(--border);
    padding: 6px 14px;
    font-size: 10px;
    color: var(--text-dim);
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .diagnose-bar::before {
    content: '●  ●  ●';
    color: var(--border2);
    letter-spacing: 2px;
  }

  .diagnose-block code {
    display: block;
    padding: 12px 14px;
    font-size: 12px;
    color: #79c0ff;
    line-height: 1.8;
    white-space: pre;
  }

  /* ── ESCALATE BOX ── */
  .escalate-box {
    background: var(--red-dim);
    border: 1px solid var(--red-border);
    border-radius: 6px;
    padding: 14px 18px;
    margin-top: 16px;
  }

  .escalate-box .esc-label {
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: var(--red);
    margin-bottom: 6px;
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .escalate-box p { color: #ffa8a8; font-size: 13px; }

  /* ── PREVENTION BOX ── */
  .prevention-box {
    background: var(--green-dim);
    border: 1px solid var(--green-bdr);
    border-radius: 6px;
    padding: 14px 18px;
    margin-top: 12px;
  }

  .prevention-box .prev-label {
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: var(--green);
    margin-bottom: 8px;
    display: flex;
    align-items: center;
    gap: 6px;
  }

  /* ── QUICK REF TABLE ── */
  .ref-table {
    width: 100%;
    border-collapse: collapse;
    margin: 16px 0;
    font-size: 12px;
  }

  .ref-table th {
    background: var(--bg4);
    color: var(--text-dim);
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    padding: 10px 14px;
    text-align: left;
    border-bottom: 1px solid var(--border2);
  }

  .ref-table td {
    padding: 10px 14px;
    border-bottom: 1px solid var(--border);
    vertical-align: top;
    color: var(--text);
  }

  .ref-table tr:hover td { background: var(--bg3); }

  .ref-table td code {
    font-family: var(--mono);
    font-size: 11px;
    color: #79c0ff;
    background: #010409;
    border: 1px solid var(--border);
    padding: 1px 6px;
    border-radius: 3px;
  }

  .ref-table td:last-child { color: var(--green); }

  /* ── CONTACTS TABLE ── */
  .contact-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
  }

  .contact-table th {
    background: var(--bg4);
    color: var(--text-dim);
    font-size: 10px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    font-weight: 700;
    padding: 10px 14px;
    text-align: left;
    border-bottom: 1px solid var(--border2);
  }

  .contact-table td {
    padding: 12px 14px;
    border-bottom: 1px solid var(--border);
    color: var(--text-dim);
  }

  .contact-table td:first-child { color: var(--text-bright); font-weight: 500; }

  .contact-table .fill {
    border-bottom: 1px dashed var(--border2);
    color: transparent;
    display: inline-block;
    width: 180px;
    user-select: none;
  }

  .contact-table .fill::after {
    content: 'fill in';
    color: var(--border2);
    font-size: 11px;
    font-style: italic;
  }

  /* ── FOOTER ── */
  .page-footer {
    margin: 64px 0 32px;
    padding-top: 24px;
    border-top: 1px solid var(--border);
    display: flex;
    justify-content: space-between;
    align-items: center;
    color: var(--text-dim);
    font-size: 11px;
  }

  /* ── SCROLL TOP ── */
  .scroll-top {
    position: fixed;
    bottom: 28px;
    right: 28px;
    background: var(--bg4);
    border: 1px solid var(--border2);
    color: var(--text-dim);
    width: 38px; height: 38px;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    font-size: 16px;
    transition: all 0.2s;
    text-decoration: none;
    z-index: 200;
  }

  .scroll-top:hover { background: var(--blue-dim); border-color: var(--blue); color: var(--blue-glow); }

  /* ── RESPONSIVE ── */
  @media (max-width: 900px) {
    .sidebar { display: none; }
    .main { margin-left: 0; padding: 24px 20px; }
    .how-grid { grid-template-columns: 1fr; }
    .hero h1 { font-size: 28px; }
  }

  /* ── ANIMATIONS ── */
  .issue-card { animation: fadeUp 0.3s ease both; }
  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(8px); }
    to   { opacity: 1; transform: translateY(0); }
  }
</style>
</head>
<body>

<!-- ═══ SIDEBAR ═══ -->
<nav class="sidebar">
  <div class="sidebar-logo">
    <div class="srv">Server Health</div>
    <div class="title">Incident <span>Runbook</span></div>
  </div>
  <div class="sidebar-meta">
    <div><strong>Version:</strong> 1.0</div>
    <div><strong>OS:</strong> Ubuntu 24.04 LTS</div>
    <div><strong>Updated:</strong> Apr 2026</div>
  </div>

  <div class="nav-section-label">Sections</div>
  <div class="nav">
    <a href="#how-to-use" class="section-link">📖 How to Use</a>

    <a href="#sec-cpu" class="section-link">§1 CPU Issues</a>
    <a href="#cpu-high">↳ High CPU Usage <span class="badge badge-crit">CRIT</span></a>
    <a href="#cpu-iowait">↳ High iowait %wa <span class="badge badge-crit">CRIT</span></a>
    <a href="#cpu-steal">↳ CPU Steal %st <span class="badge badge-warn">WARN</span></a>

    <a href="#sec-mem" class="section-link">§2 Memory Issues</a>
    <a href="#mem-high">↳ High Memory <span class="badge badge-crit">CRIT</span></a>
    <a href="#mem-oom">↳ OOM Killer Fired <span class="badge badge-crit">CRIT</span></a>
    <a href="#mem-swap">↳ Swap Exhaustion <span class="badge badge-warn">WARN</span></a>

    <a href="#sec-disk" class="section-link">§3 Disk Issues</a>
    <a href="#disk-full">↳ Disk Full <span class="badge badge-crit">CRIT</span></a>
    <a href="#disk-inode">↳ Inode Exhaustion <span class="badge badge-crit">CRIT</span></a>
    <a href="#disk-io">↳ Slow Disk I/O <span class="badge badge-warn">WARN</span></a>

    <a href="#sec-proc" class="section-link">§4 Process & Services</a>
    <a href="#svc-failed">↳ Failed Service <span class="badge badge-crit">CRIT</span></a>
    <a href="#svc-zombie">↳ Zombie Processes <span class="badge badge-warn">WARN</span></a>
    <a href="#svc-fd">↳ FD Leak <span class="badge badge-warn">WARN</span></a>

    <a href="#sec-net" class="section-link">§5 Network Issues</a>
    <a href="#net-loss">↳ Packet Loss <span class="badge badge-crit">CRIT</span></a>
    <a href="#net-cw">↳ CLOSE_WAIT High <span class="badge badge-crit">CRIT</span></a>

    <a href="#sec-load" class="section-link">§6 Load Average</a>
    <a href="#load-high">↳ Load Exceeds Cores <span class="badge badge-crit">CRIT</span></a>

    <a href="#sec-ref" class="section-link">§7 Quick Reference</a>
    <a href="#sec-contacts" class="section-link">§8 Escalation Contacts</a>
  </div>
</nav>

<!-- ═══ MAIN ═══ -->
<main class="main">

  <!-- HERO -->
  <div class="hero">
    <div class="hero-eyebrow">// incident_runbook_v1.0</div>
    <h1>Server Health<br><span>Incident Runbook</span></h1>
    <p>Structured troubleshooting guide for Linux production production servers. Each issue includes symptoms, diagnosis commands, step-by-step remediation, and escalation criteria.</p>
    <div class="hero-tags">
      <span class="tag">Ubuntu 24.04 LTS</span>
      <span class="tag">systemd</span>
      <span class="tag">/opt/server-health</span>
      <span class="tag">bash</span>
      <span class="tag">on-call reference</span>
    </div>
  </div>

  <!-- HOW TO USE -->
  <div id="how-to-use">
    <div class="section-header">
      <span class="section-number">§ 00</span>
      <h2>How to Use This Runbook</h2>
    </div>
    <div class="how-grid">
      <div class="how-card">
        <span class="icon">🚨</span>
        <div>
          <strong>Alert fired</strong>
          <p>The health report script triggered a threshold. Jump directly to that section using the sidebar.</p>
        </div>
      </div>
      <div class="how-card">
        <span class="icon">🐢</span>
        <div>
          <strong>User reports slowness</strong>
          <p>Start with §7 Quick Reference table — match the symptom to a first command and likely fix.</p>
        </div>
      </div>
      <div class="how-card">
        <span class="icon">🔍</span>
        <div>
          <strong>Proactive check</strong>
          <p>Use the Diagnose commands in each issue to verify health before a threshold is breached.</p>
        </div>
      </div>
      <div class="how-card">
        <span class="icon">📋</span>
        <div>
          <strong>Post-incident review</strong>
          <p>Use Prevention sections to implement safeguards and avoid recurrence.</p>
        </div>
      </div>
    </div>

    <table class="ref-table" style="margin-top:20px;">
      <thead><tr><th>Badge</th><th>Meaning</th><th>Response Time</th></tr></thead>
      <tbody>
        <tr><td><span class="severity-badge sev-crit">CRITICAL</span></td><td>Service interruption possible. Act immediately.</td><td>Escalate if unresolved in 5 min</td></tr>
        <tr><td><span class="severity-badge sev-warn">WARNING</span></td><td>Degradation detected. Investigate promptly.</td><td>Within 15 minutes</td></tr>
        <tr><td><span class="severity-badge sev-info">INFO</span></td><td>Healthy. Reference for proactive checks.</td><td>No action required</td></tr>
      </tbody>
    </table>
  </div>


  <!-- ═══ SECTION 1: CPU ═══ -->
  <div id="sec-cpu">
    <div class="section-header">
      <span class="section-number">§ 01</span>
      <h2>CPU Issues</h2>
    </div>

    <!-- High CPU -->
    <div class="issue-card" id="cpu-high">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">High CPU Usage</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">%cpu > 70% warn / > 90% crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>Orders taking longer than usual to execute</li>
          <li>SSH login is sluggish or timing out</li>
          <li>top shows %us or %sy near 100%</li>
          <li>Load average exceeds core count</li>
        </ul>

        <div class="sub-label">Possible Causes</div>
        <ul class="rb-list">
          <li>Process stuck in a loop or processing backlog</li>
          <li>Market data feed spiking during high-volatility period</li>
          <li>Scheduled cron job (log rotation, backup) running at wrong time</li>
          <li>Memory pressure causing kernel to thrash (%sy elevated)</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>top -b -n 1 | head -20
ps aux --sort=-%cpu | head -10
uptime   <span class="comment"># compare load to: nproc</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Identify the offending process:<div class="cmd">ps aux --sort=-%cpu | head -10</div></li>
          <li>Confirm it is not a legitimate spike (market open, replay):<div class="cmd">journalctl -u &lt;service-name&gt; --since '10 minutes ago' | tail -20</div></li>
          <li>Trace what the process is doing:<div class="cmd">strace -p &lt;PID&gt; -c -f</div></li>
          <li>If safe to restart the service:<div class="cmd">systemctl restart &lt;service&gt;</div></li>
          <li>Graceful kill if a runaway script:<div class="cmd">kill -15 &lt;PID&gt;</div></li>
          <li>Force kill only as absolute last resort:<div class="cmd">kill -9 &lt;PID&gt;</div></li>
          <li>Verify CPU returns to normal:<div class="cmd">watch -n 2 'ps aux --sort=-%cpu | head -5'</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>CPU stays above 90% for more than 5 minutes after restart, or the offending process is the core production engine.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Set CPU limits per service in systemd: <code>CPUQuota=80%</code></li>
            <li>Schedule cron jobs outside business hours (before 07:00 or after 18:00)</li>
            <li>Monitor CPU trend: <code>sar -u 1 10</code> and alert on sustained > 70%</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- iowait -->
    <div class="issue-card" id="cpu-iowait">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">High iowait (%wa)</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">%wa > 10% warn / > 25% crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>CPU shows low %us but system still feels slow</li>
          <li>%wa column elevated in top or iostat</li>
          <li>Disk reads or writes queuing — aqu-sz > 1 in iostat</li>
          <li>Log files writing slowly or with truncated entries</li>
        </ul>

        <div class="sub-label">Possible Causes</div>
        <ul class="rb-list">
          <li>Service logs writing faster than disk can handle</li>
          <li>Database performing full table scans to disk</li>
          <li>Disk partition nearly full causing fragmentation</li>
          <li>Hardware disk degradation or impending failure</li>
          <li>Backup job running during business hours</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>iostat -x 1 5        <span class="comment"># look at %util, r_await, w_await</span>
iotop -o             <span class="comment"># find which process is doing the I/O</span>
du -h /opt/server-health/logs | sort -rh | head -10</code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Confirm disk is the bottleneck (not CPU):<div class="cmd">iostat -x 1 5 | grep -v loop</div></li>
          <li>Find which process is hitting the disk:<div class="cmd">iotop -o   <span class="comment"># install: apt install iotop</span></div></li>
          <li>Check if logs are growing uncontrolled:<div class="cmd">ls -lth /opt/server-health/logs/ | head -10</div></li>
          <li>Clean up old log files immediately:<div class="cmd">find /opt/server-health/logs -name '*.log' -mtime +7 -delete</div></li>
          <li>Clear systemd journal if large:<div class="cmd">journalctl --vacuum-time=3d</div></li>
          <li>Check disk health (SMART data):<div class="cmd">smartctl -a /dev/sda   <span class="comment"># apt install smartmontools</span></div></li>
          <li>If await > 50ms disk hardware may be failing — escalate immediately</li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>w_await or r_await exceed 50ms, %util stays above 90%, or smartctl reports reallocated sectors.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Rotate logs daily, keep only 7 days on disk</li>
            <li>Mount /opt/server-health on a dedicated SSD partition</li>
            <li>Run backups after business hours: <code>ionice -c3 rsync ...</code></li>
            <li>Set log level to WARN in production (not DEBUG)</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- CPU Steal -->
    <div class="issue-card" id="cpu-steal">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-warn"></span>
        <span class="issue-title">CPU Steal (%st) — VM Environment</span>
        <span class="severity-badge sev-warn">Warning</span>
        <span class="metric-tag">%steal > 5% warn / > 10% crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>Server feels slow despite low %us and %wa</li>
          <li>%st column elevated in top output</li>
          <li>Performance degrades at unpredictable times</li>
          <li>vmstat shows steal column non-zero</li>
        </ul>

        <div class="sub-label">Possible Causes</div>
        <ul class="rb-list">
          <li>Physical host oversubscribed — other VMs consuming CPU</li>
          <li>Cloud provider throttling the instance</li>
          <li>Noisy neighbour on shared hypervisor</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>vmstat 1 10 | awk '{print $17}'   <span class="comment"># column 17 = steal</span>
sar -u 1 10                       <span class="comment"># historical CPU inc steal</span>
top -b -n 1 | grep Cpu            <span class="comment"># check st value</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Confirm steal is sustained (not momentary):<div class="cmd">vmstat 1 30 | awk 'NR>2{print $17}' | sort -n</div></li>
          <li>Check cloud provider console for host CPU metrics</li>
          <li>Open a support ticket with provider — include vmstat output</li>
          <li>Short-term reduce VM workload:<div class="cmd">systemctl stop &lt;non-critical-service&gt;</div></li>
          <li>Request a host migration if problem persists over 1 hour</li>
          <li>Long-term: move to dedicated instance or bare metal</li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>%steal stays above 10% for 15 minutes and latency is measurably impacted.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Use dedicated or reserved instances for production production servers</li>
            <li>Choose cloud regions/zones with less contention</li>
            <li>Monitor %steal daily as part of health checks</li>
          </ul>
        </div>
      </div>
    </div>
  </div>


  <!-- ═══ SECTION 2: MEMORY ═══ -->
  <div id="sec-mem">
    <div class="section-header">
      <span class="section-number">§ 02</span>
      <h2>Memory Issues</h2>
    </div>

    <!-- High Memory -->
    <div class="issue-card" id="mem-high">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">High Memory Usage</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">mem > 75% warn / > 90% crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>free -h shows very little free memory</li>
          <li>System starts using swap — si/so non-zero in vmstat</li>
          <li>Application response times increasing</li>
          <li>OOM killer may start terminating processes</li>
        </ul>

        <div class="sub-label">Possible Causes</div>
        <ul class="rb-list">
          <li>Memory leak in production application — RSS grows over time</li>
          <li>Too many concurrent connections held in memory</li>
          <li>Market data stored in memory not being flushed</li>
          <li>Cache not releasing — buff/cache growing unbounded</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>free -h
ps aux --sort=-%mem | head -10
cat /proc/&lt;PID&gt;/status | grep -E 'VmRSS|VmSwap|VmPeak'</code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Find which process is consuming most memory:<div class="cmd">ps aux --sort=-%mem | head -10</div></li>
          <li>Watch if memory is growing (possible leak):<div class="cmd">watch -n 5 'ps -p &lt;PID&gt; -o pid,rss,vsz,pmem --no-headers'</div></li>
          <li>Drop page cache safely (does not affect app data):<div class="cmd">echo 1 > /proc/sys/vm/drop_caches</div></li>
          <li>If the service is the hog, restart it:<div class="cmd">systemctl restart &lt;service&gt;</div></li>
          <li>Add swap as emergency safety net:<div class="cmd">fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile</div></li>
          <li>Make swap permanent:<div class="cmd">echo '/swapfile none swap sw 0 0' >> /etc/fstab</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>Memory above 90% and swap is also filling up, or OOM killer has already fired.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Set memory limits in systemd unit file: <code>MemoryMax=4G</code></li>
            <li>Monitor VmRSS growth: <code>watch -n 60 'cat /proc/&lt;PID&gt;/status | grep VmRSS'</code></li>
            <li>Schedule application restarts during low-traffic windows if leak is known</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- OOM -->
    <div class="issue-card" id="mem-oom">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">OOM Killer Fired</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">OOM events > 0 in dmesg/journal</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>dmesg shows: "Out of memory: Killed process"</li>
          <li>Service disappeared without being explicitly stopped</li>
          <li>journalctl shows service restarted unexpectedly</li>
          <li>Traders report feed or order system went offline briefly</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>dmesg | grep -i 'killed process'
journalctl -k --since '1 hour ago' | grep -i oom
cat /proc/&lt;PID&gt;/oom_score   <span class="comment"># higher = more likely to be killed</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Identify what was killed and when:<div class="cmd">dmesg | grep -i 'killed process' | tail -10</div></li>
          <li>Restart the killed service immediately:<div class="cmd">systemctl restart &lt;service&gt;</div></li>
          <li>Protect critical process from future OOM kills:<div class="cmd">echo -1000 > /proc/$(pgrep &lt;app-name&gt;)/oom_score_adj</div></li>
          <li>Add swap to prevent future OOM events:<div class="cmd">fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile</div></li>
          <li>Find and address the memory hog:<div class="cmd">ps aux --sort=-%mem | head -10</div></li>
          <li>Check if OOM is recurring (same service every time):<div class="cmd">journalctl -k | grep oom | tail -20</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>OOM fires more than once in an hour, or the production engine itself was killed.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Always configure swap — minimum 2x RAM for production servers</li>
            <li>Set <code>oom_score_adj = -1000</code> for critical service PIDs at startup</li>
            <li>Set <code>MemoryMax</code> in systemd unit files to cap per-service usage</li>
            <li>Alert when memory exceeds 80% — don't wait for OOM</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Swap -->
    <div class="issue-card" id="mem-swap">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-warn"></span>
        <span class="issue-title">Swap Exhaustion</span>
        <span class="severity-badge sev-warn">Warning</span>
        <span class="metric-tag">swap > 40% warn / > 80% crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>vmstat shows non-zero si (swap-in) or so (swap-out) columns</li>
          <li>System very slow — disk I/O from swapping</li>
          <li>free -h shows swap nearly full</li>
          <li>High %wa in top due to swap I/O</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>vmstat 1 5   <span class="comment"># watch si and so — both should be 0 when healthy</span>
free -h      <span class="comment"># check swap used vs total</span>
smem -s swap | head -10   <span class="comment"># apt install smem</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Confirm active swapping (not just used swap sitting idle):<div class="cmd">vmstat 1 10 | awk '{print $7, $8}'   <span class="comment"># si so should be 0</span></div></li>
          <li>Find what is in swap:<div class="cmd">smem -s swap | tail -10</div></li>
          <li>Reduce swappiness to prefer RAM:<div class="cmd">echo 10 > /proc/sys/vm/swappiness</div></li>
          <li>Restart the largest memory consumer:<div class="cmd">systemctl restart &lt;service&gt;</div></li>
          <li>Expand swap if disk space allows:<div class="cmd">swapoff /swapfile
fallocate -l 4G /swapfile
mkswap /swapfile && swapon /swapfile</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>vmstat shows sustained swap-in/out above 100MB/s, or swap is full and OOM is imminent.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Size swap at minimum 2x RAM</li>
            <li>Set <code>vm.swappiness=10</code> permanently in /etc/sysctl.conf</li>
            <li>Alert if vmstat si/so are non-zero for more than 60 seconds</li>
          </ul>
        </div>
      </div>
    </div>
  </div>


  <!-- ═══ SECTION 3: DISK ═══ -->
  <div id="sec-disk">
    <div class="section-header">
      <span class="section-number">§ 03</span>
      <h2>Disk Issues</h2>
    </div>

    <!-- Disk Full -->
    <div class="issue-card" id="disk-full">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">Disk Space Full</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">disk > 80% warn / > 90% crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>Application cannot write log files — services may fail silently</li>
          <li>df -h shows 90%+ on a partition</li>
          <li>Error messages: "No space left on device"</li>
          <li>New processes cannot start (cannot write PID file)</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>df -h                                         <span class="comment"># which partition?</span>
du -h /opt/server-health | sort -rh | head -10      <span class="comment"># largest dirs</span>
find / -type f -size +500M 2>/dev/null        <span class="comment"># big files</span>
lsof | grep deleted | head -20                <span class="comment"># deleted but held open</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Identify full partition and biggest consumers:<div class="cmd">df -h && du -h /var | sort -rh | head -10</div></li>
          <li>Delete old log files immediately:<div class="cmd">find /opt/server-health/logs -name '*.log' -mtime +7 -delete</div></li>
          <li>Clear systemd journal:<div class="cmd">journalctl --vacuum-size=500M</div></li>
          <li>Clean APT cache:<div class="cmd">apt clean</div></li>
          <li>Remove old core dumps:<div class="cmd">find / -name 'core.*' -mtime +1 -delete 2>/dev/null</div></li>
          <li>Release deleted-but-open file space by restarting the holding process:<div class="cmd">lsof | grep deleted
systemctl restart &lt;process-holding-deleted-file&gt;</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>Disk at 95%+ and cannot immediately free space. Service logs cannot write — this is a service-impacting incident.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Set up logrotate for /opt/server-health/logs — rotate daily, keep 7 days</li>
            <li>Cron cleanup: <code>find /opt/server-health/logs -name '*.log' -mtime +7 -delete</code></li>
            <li>Alert at 80% — never let it reach 90% unmanaged</li>
            <li>Mount /opt/server-health on a separate partition from /</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Inode -->
    <div class="issue-card" id="disk-inode">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">Inode Exhaustion</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">inode usage > 80% warn / > 90% crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>df -h shows space available but cannot create new files</li>
          <li>Error: "No space left on device" despite disk not being full</li>
          <li>df -i shows inode usage at 90%+</li>
          <li>Application cannot create new log files, temp files, or sockets</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>df -i    <span class="comment"># inode usage per filesystem</span>
<span class="comment"># find dirs with most files:</span>
find / -xdev -type d | xargs -I{} sh -c \
  'echo $(ls {} 2>/dev/null | wc -l) {}' 2>/dev/null | sort -rn | head -10</code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Confirm it is an inode problem, not disk space:<div class="cmd">df -h && df -i   <span class="comment"># disk has space but inodes are full</span></div></li>
          <li>Find the directory with the most files:<div class="cmd">for d in /var/*/; do echo $(find $d | wc -l) $d; done | sort -rn | head -10</div></li>
          <li>Clean up small stale files:<div class="cmd">find /tmp -mtime +3 -delete
find /var/tmp -mtime +7 -delete</div></li>
          <li>Check and clean mail spool:<div class="cmd">ls -la /var/spool/mail/
cat /dev/null > /var/spool/mail/root</div></li>
          <li>Delete old small log files:<div class="cmd">find /opt/server-health/logs -name '*.log' -mtime +3 -delete</div></li>
          <li>Verify inodes are freed:<div class="cmd">df -i</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>Inodes at 99% and cleanup is not freeing enough. Filesystem restructuring may be required.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Never log one-file-per-request — use rolling log files</li>
            <li>Cron: clean /tmp and /var/tmp weekly</li>
            <li>Monitor inode usage as part of weekly health check</li>
            <li>Create /opt/server-health on its own partition with appropriate inode count</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Slow IO -->
    <div class="issue-card" id="disk-io">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-warn"></span>
        <span class="issue-title">Slow Disk I/O (High Latency)</span>
        <span class="severity-badge sev-warn">Warning</span>
        <span class="metric-tag">r/w await > 20ms warn / > 50ms crit | %util > 70%</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>Application slow but CPU is idle</li>
          <li>%iowait elevated in top</li>
          <li>iostat shows r_await or w_await > 20ms</li>
          <li>aqu-sz (queue depth) above 1 in iostat output</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>iostat -x 1 5                    <span class="comment"># r_await, w_await, %util, aqu-sz</span>
iotop -o                         <span class="comment"># which process is causing I/O</span>
smartctl -a /dev/sda             <span class="comment"># disk health and error count</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Check which disk is slow:<div class="cmd">iostat -x 1 5 | grep -v loop</div></li>
          <li>Find which process is responsible:<div class="cmd">iotop -o</div></li>
          <li>Check SMART health — look for reallocated sectors:<div class="cmd">smartctl -a /dev/sda | grep -i 'reallocated\|error\|pending'</div></li>
          <li>Reduce write pressure — lower log verbosity in app config:<div class="cmd"><span class="comment"># In app config: set log_level = WARN (not DEBUG)</span></div></li>
          <li>Use tmpfs for non-critical temp data:<div class="cmd">mount -t tmpfs -o size=512m tmpfs /opt/server-health/tmp</div></li>
          <li>If SMART shows errors — disk is failing, replace immediately and escalate</li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>%util sustains above 90% or SMART reports pending/reallocated sectors. Disk failure is imminent — initiate backup immediately.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Use SSDs for production server storage</li>
            <li>Separate OS, logs, and market data onto different volumes</li>
            <li>Run smartctl health check weekly via cron</li>
            <li>Use <code>ionice -c3</code> for backup jobs to lower their I/O priority</li>
          </ul>
        </div>
      </div>
    </div>
  </div>


  <!-- ═══ SECTION 4: PROCESSES ═══ -->
  <div id="sec-proc">
    <div class="section-header">
      <span class="section-number">§ 04</span>
      <h2>Process &amp; Service Issues</h2>
    </div>

    <!-- Failed Service -->
    <div class="issue-card" id="svc-failed">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">Failed or Crashed Service</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">systemctl --failed shows 1+ units</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>Traders report a specific function is down (API, web service, background job, etc.)</li>
          <li>systemctl status shows "failed"</li>
          <li>journalctl shows FATAL or non-zero exit code</li>
          <li>Port is no longer listening (ss -tulnp)</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>systemctl --failed
systemctl status &lt;service&gt;
journalctl -u &lt;service&gt; -n 100 --no-pager</code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Identify all failed services:<div class="cmd">systemctl --failed</div></li>
          <li>Read the last 50 lines of logs to find root cause:<div class="cmd">journalctl -u &lt;service&gt; -n 50 --no-pager</div></li>
          <li>Check exit code and signal:<div class="cmd">systemctl show &lt;service&gt; | grep -E 'ExecMainStatus|Result'</div></li>
          <li>Attempt a restart:<div class="cmd">systemctl restart &lt;service&gt;</div></li>
          <li>Watch if it stays up:<div class="cmd">watch -n 3 systemctl is-active &lt;service&gt;</div></li>
          <li>If config changed recently, test config syntax:<div class="cmd">&lt;service&gt; --config-test   <span class="comment"># flag varies by service</span></div></li>
          <li>Reset failed state after fixing:<div class="cmd">systemctl reset-failed &lt;service&gt;</div></li>
          <li>Check that all dependencies are running:<div class="cmd">systemctl list-dependencies &lt;service&gt;</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>Service fails to stay up after 3 restart attempts, or root cause is not identifiable from logs within 5 minutes.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Set <code>Restart=on-failure</code> and <code>RestartSec=5</code> in systemd unit files</li>
            <li>Set <code>StartLimitIntervalSec</code> and <code>StartLimitBurst</code> to prevent restart loops</li>
            <li>Configure health check endpoints and monitor them externally</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Zombie -->
    <div class="issue-card" id="svc-zombie">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-warn"></span>
        <span class="issue-title">Zombie Processes</span>
        <span class="severity-badge sev-warn">Warning</span>
        <span class="metric-tag">ps aux shows Z state processes</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>ps aux shows Z in the state column</li>
          <li>Process count growing over time without release</li>
          <li>Parent process may have crashed or is not reaping children</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>ps aux | awk '$8=="Z"'                    <span class="comment"># list zombies</span>
ps -o ppid= -p &lt;ZOMBIE_PID&gt;                <span class="comment"># find parent PID</span>
ps aux | grep &lt;PPID&gt;                       <span class="comment"># what is the parent?</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Find zombie PIDs and their parent:<div class="cmd">ps aux | awk '$8=="Z" {print "Zombie:", $2, "Parent:", $3}'</div></li>
          <li>Check if parent is healthy:<div class="cmd">ps aux | grep &lt;PPID&gt;</div></li>
          <li>Gracefully restart the parent process:<div class="cmd">systemctl restart &lt;parent-service&gt;</div></li>
          <li>If parent is stuck, force it:<div class="cmd">kill -15 &lt;PPID&gt;   <span class="comment"># graceful</span>
kill -9 &lt;PPID&gt;    <span class="comment"># force — zombies auto-clean after</span></div></li>
          <li>Verify zombies are gone:<div class="cmd">ps aux | awk '$8=="Z"'</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>Zombie count growing rapidly (> 50), or parent process is the production engine itself.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Ensure application properly calls wait()/waitpid() on child exit</li>
            <li>Use systemd to manage child processes — it reaps zombies automatically</li>
            <li>Alert when zombie count exceeds 5</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- FD Leak -->
    <div class="issue-card" id="svc-fd">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-warn"></span>
        <span class="issue-title">Open File Descriptor Leak</span>
        <span class="severity-badge sev-warn">Warning</span>
        <span class="metric-tag">open FDs > 10,000 warn / > 50,000 crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>Application fails to open new connections or files</li>
          <li>Error: "Too many open files"</li>
          <li>lsof | wc -l returns very large number</li>
          <li>FD count grows steadily over time without releasing</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>lsof | wc -l                                   <span class="comment"># total open FDs</span>
lsof 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -10
cat /proc/&lt;PID&gt;/limits | grep 'open files'     <span class="comment"># per-process limit</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Find which process is the leaker:<div class="cmd">lsof 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -10</div></li>
          <li>Temporarily raise the system FD limit:<div class="cmd">ulimit -n 100000</div></li>
          <li>Restart the leaking service:<div class="cmd">systemctl restart &lt;service&gt;</div></li>
          <li>Raise per-service FD limit permanently in unit file:<div class="cmd"><span class="comment"># Add to /etc/systemd/system/&lt;service&gt;.service:</span>
LimitNOFILE=65536</div></li>
          <li>Reload and restart:<div class="cmd">systemctl daemon-reload && systemctl restart &lt;service&gt;</div></li>
          <li>Raise system-wide limit permanently:<div class="cmd">echo 'fs.file-max = 500000' >> /etc/sysctl.conf && sysctl -p</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>FD count at system limit and application is rejecting connections — immediate service restart required.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Set <code>LimitNOFILE=65536</code> in all systemd unit files</li>
            <li>Ensure application closes file handles explicitly after use</li>
            <li>Monitor daily: <code>lsof -p &lt;PID&gt; | wc -l</code></li>
          </ul>
        </div>
      </div>
    </div>
  </div>


  <!-- ═══ SECTION 5: NETWORK ═══ -->
  <div id="sec-net">
    <div class="section-header">
      <span class="section-number">§ 05</span>
      <h2>Network Issues</h2>
    </div>

    <!-- Packet Loss -->
    <div class="issue-card" id="net-loss">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">Packet Loss to Gateway / Upstream</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">> 10% loss warn / > 50% loss crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>Traders report disconnections or feed drops</li>
          <li>ping to gateway shows packet loss</li>
          <li>Service not reaching upstream — connection timeouts</li>
          <li>traceroute shows drops at first or second hop</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>ping -c 20 &lt;gateway-ip&gt;       <span class="comment"># how much loss?</span>
traceroute &lt;upstream-ip&gt;       <span class="comment"># where does it drop?</span>
ip -s link show eth0           <span class="comment"># NIC error counters</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Run extended ping to quantify loss:<div class="cmd">ping -c 50 $(ip route | awk '/default/{print $3}')</div></li>
          <li>Trace route to identify where packets drop:<div class="cmd">traceroute &lt;upstream-ip&gt;</div></li>
          <li>Check NIC for hardware errors:<div class="cmd">ip -s link show eth0   <span class="comment"># look for 'errors' or 'dropped'</span></div></li>
          <li>Check link speed and duplex mismatch:<div class="cmd">ethtool eth0</div></li>
          <li>Check dmesg for NIC errors:<div class="cmd">dmesg | grep -i 'eth0\|network\|link'</div></li>
          <li>Try reloading the NIC driver:<div class="cmd">modprobe -r &lt;driver&gt; && modprobe &lt;driver&gt;</div></li>
          <li>Escalate to network team with traceroute output</li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>Any packet loss to exchange — service disruption possible. Contact network team immediately.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Use bonded NICs (active/passive) for redundancy</li>
            <li>Monitor with ping every 30 seconds — alert on any loss</li>
            <li>Keep spare NIC and cables on-site</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- CLOSE_WAIT -->
    <div class="issue-card" id="net-cw">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">High CLOSE_WAIT Connections</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">CLOSE_WAIT count > 50</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>ss -an | grep CLOSE-WAIT shows many entries</li>
          <li>Application cannot open new connections despite port being available</li>
          <li>Connection pool exhausted</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>ss -an | grep -c CLOSE-WAIT
ss -anp | grep CLOSE-WAIT | head -20   <span class="comment"># which process?</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Confirm count and identify which process:<div class="cmd">ss -anp | grep CLOSE-WAIT | awk '{print $6}' | sort | uniq -c</div></li>
          <li>Restart the offending application:<div class="cmd">systemctl restart &lt;service&gt;</div></li>
          <li>Watch if CLOSE_WAIT returns after restart:<div class="cmd">watch -n 5 'ss -an | grep -c CLOSE-WAIT'</div></li>
          <li>Enable TCP keepalive to detect and close dead connections:<div class="cmd">echo 60 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 10 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 6  > /proc/sys/net/ipv4/tcp_keepalive_probes</div></li>
          <li>Root cause: this is a code bug — connections must be explicitly closed after receiving FIN from peer. Raise with development team.</li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>CLOSE_WAIT above 200 and connection pool is exhausted — application cannot accept new connections.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Implement proper connection lifecycle in production application</li>
            <li>Use connection timeout settings in all client libraries</li>
            <li>Enable TCP keepalives at socket level in application code</li>
          </ul>
        </div>
      </div>
    </div>
  </div>


  <!-- ═══ SECTION 6: LOAD ═══ -->
  <div id="sec-load">
    <div class="section-header">
      <span class="section-number">§ 06</span>
      <h2>Load Average</h2>
    </div>

    <div class="issue-card" id="load-high">
      <div class="issue-header" onclick="toggle(this)">
        <span class="severity-dot dot-crit"></span>
        <span class="issue-title">Load Average Exceeds Core Count</span>
        <span class="severity-badge sev-crit">Critical</span>
        <span class="metric-tag">load > 0.8×cores warn / > 1.2×cores crit</span>
        <span class="chevron">▼</span>
      </div>
      <div class="issue-body">
        <div class="sub-label">Symptoms</div>
        <ul class="rb-list">
          <li>uptime shows 1min load above nproc value</li>
          <li>vmstat 'r' column (run queue) exceeds core count</li>
          <li>System slow to respond to commands</li>
          <li>SSH login takes several seconds</li>
        </ul>

        <div class="sub-label">Diagnose First</div>
        <div class="diagnose-block">
          <div class="diagnose-bar">bash — root@server-health</div>
          <code>uptime && nproc                         <span class="comment"># compare load to cores</span>
vmstat 1 5                              <span class="comment"># 'r'=run queue, 'b'=blocked</span>
top -b -n 1 | head -20                 <span class="comment"># who is consuming?</span></code>
        </div>

        <div class="sub-label">Remediation Steps</div>
        <ol class="steps">
          <li>Compare load to core count:<div class="cmd">echo "Load: $(cat /proc/loadavg | awk '{print $1}')  Cores: $(nproc)"</div></li>
          <li>Check if it is CPU or I/O causing the load:<div class="cmd">vmstat 1 5  <span class="comment"># 'b' high = blocked on I/O; 'r' high = CPU bound</span></div></li>
          <li>If iowait is the cause — follow the Disk I/O section above</li>
          <li>If CPU is the cause — follow the High CPU Usage section above</li>
          <li>If load sustained above 2x cores, stop non-critical services:<div class="cmd">systemctl stop &lt;non-essential-service&gt;</div></li>
        </ol>

        <div class="escalate-box">
          <div class="esc-label">🚨 Escalate When</div>
          <p>Load average at 3x core count for more than 5 minutes and root cause cannot be identified.</p>
        </div>

        <div class="prevention-box">
          <div class="prev-label">🛡 Prevention</div>
          <ul class="rb-list">
            <li>Set cgroups CPU limits for non-critical services</li>
            <li>Spread scheduled jobs to avoid simultaneous execution</li>
            <li>Scale horizontally if sustained overload is the norm</li>
          </ul>
        </div>
      </div>
    </div>
  </div>


  <!-- ═══ SECTION 7: QUICK REFERENCE ═══ -->
  <div id="sec-ref">
    <div class="section-header">
      <span class="section-number">§ 07</span>
      <h2>Quick Reference</h2>
    </div>
    <p style="color:var(--text-dim); margin-bottom:16px; font-size:13px;">Use during a live incident for rapid decision-making. Match the symptom, run the command, apply the fix.</p>
    <table class="ref-table">
      <thead>
        <tr><th>Symptom</th><th>First Command</th><th>Likely Fix</th></tr>
      </thead>
      <tbody>
        <tr><td>System slow, SSH laggy</td><td><code>uptime && top -b -n1 | head -5</code></td><td>Find CPU hog: ps aux --sort=-%cpu</td></tr>
        <tr><td>CPU busy but nothing obvious</td><td><code>top -b -n1 | grep Cpu</code> (check %wa)</td><td>High iowait → run iostat -x 1 5</td></tr>
        <tr><td>"No space left on device"</td><td><code>df -h</code></td><td>Clean logs: find /opt/server-health/logs -mtime +7 -delete</td></tr>
        <tr><td>Disk has space but can't create files</td><td><code>df -i</code></td><td>Inode full → delete small files in /tmp</td></tr>
        <tr><td>App offline, no crash visible</td><td><code>systemctl --failed</code></td><td>Restart: systemctl restart &lt;service&gt;</td></tr>
        <tr><td>Service not reaching upstream</td><td><code>ping -c 10 &lt;upstream-ip&gt;</code></td><td>Packet loss → contact network team</td></tr>
        <tr><td>App slow, CPU is idle</td><td><code>iostat -x 1 3</code> (check %util)</td><td>Disk bottleneck → iotop to find hog</td></tr>
        <tr><td>RAM nearly full</td><td><code>free -h && ps aux --sort=-%mem | head -5</code></td><td>Restart hog or add swap</td></tr>
        <tr><td>App fails to open connections</td><td><code>lsof | wc -l</code></td><td>FD leak → restart service, raise LimitNOFILE</td></tr>
        <tr><td>Random process killed</td><td><code>dmesg | grep -i 'killed process'</code></td><td>OOM → add swap, protect with oom_score_adj</td></tr>
        <tr><td>New connections failing</td><td><code>ss -an | grep -c CLOSE-WAIT</code></td><td>CLOSE_WAIT high → restart service, fix in code</td></tr>
        <tr><td>VM feels slow, CPU fine</td><td><code>top -b -n1 | grep st</code></td><td>CPU steal → contact cloud provider</td></tr>
      </tbody>
    </table>
  </div>


  <!-- ═══ SECTION 8: CONTACTS ═══ -->
  <div id="sec-contacts">
    <div class="section-header">
      <span class="section-number">§ 08</span>
      <h2>Escalation Contacts</h2>
    </div>
    <p style="color:var(--text-dim); margin-bottom:16px; font-size:13px;">Fill in before deploying this runbook. Keep this page accessible offline.</p>
    <table class="contact-table">
      <thead>
        <tr><th>Role</th><th>Name</th><th>Contact</th><th>Escalate When</th></tr>
      </thead>
      <tbody>
        <tr><td>Senior Engineer</td><td><span class="fill"></span></td><td><span class="fill"></span></td><td>5 min unresolved</td></tr>
        <tr><td>Network Team</td><td><span class="fill"></span></td><td><span class="fill"></span></td><td>Any packet loss</td></tr>
        <tr><td>Cloud Provider</td><td><span class="fill"></span></td><td><span class="fill"></span></td><td>%steal > 10%</td></tr>
        <tr><td>Upstream Support</td><td><span class="fill"></span></td><td><span class="fill"></span></td><td>Upstream path down</td></tr>
        <tr><td>Security Team</td><td><span class="fill"></span></td><td><span class="fill"></span></td><td>Suspicious process</td></tr>
      </tbody>
    </table>
  </div>

  <!-- FOOTER -->
  <div class="page-footer">
    <span>Server Health Incident Runbook — v1.0</span>
    <span>Ubuntu 24.04 LTS · systemd · /opt/server-health</span>
  </div>

</main>

<a href="#" class="scroll-top" title="Back to top">↑</a>

<script>
  function toggle(header) {
    const body = header.nextElementSibling;
    const isOpen = body.classList.contains('open');
    body.classList.toggle('open', !isOpen);
    header.classList.toggle('open', !isOpen);
  }

  // open first card in each section by default
  document.querySelectorAll('.issue-card:first-of-type .issue-header').forEach(h => {
    h.classList.add('open');
    h.nextElementSibling.classList.add('open');
  });

  // highlight active nav link on scroll
  const sections = document.querySelectorAll('[id]');
  const navLinks = document.querySelectorAll('.nav a');
  window.addEventListener('scroll', () => {
    let current = '';
    sections.forEach(s => {
      if (window.scrollY >= s.offsetTop - 80) current = s.id;
    });
    navLinks.forEach(a => {
      a.style.color = a.getAttribute('href') === '#' + current
        ? 'var(--text-bright)' : '';
      a.style.borderLeftColor = a.getAttribute('href') === '#' + current
        ? 'var(--blue-glow)' : '';
      a.style.background = a.getAttribute('href') === '#' + current
        ? 'var(--bg3)' : '';
    });
  });
</script>
</body>
</html>
