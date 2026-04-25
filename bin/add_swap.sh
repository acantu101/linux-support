#!/bin/bash
# ============================================================
#  ADD SWAP — Safe swap setup script
#  Run as root: bash add_swap.sh
#  Default size: 2G (pass size as argument: bash add_swap.sh 4G)
# ============================================================

RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
BLD='\033[1m'
RST='\033[0m'

ok()   { echo -e "  ${GRN}[  OK  ]${RST}  $1"; }
fail() { echo -e "  ${RED}[ FAIL ]${RST}  $1"; exit 1; }
info() { echo -e "  ${BLD}[ INFO ]${RST}  $1"; }
warn() { echo -e "  ${YEL}[ WARN ]${RST}  $1"; }

SWAP_SIZE="${1:-2G}"
SWAP_FILE="/swapfile"

echo ""
echo -e "${BLD}  SWAP SETUP SCRIPT${RST}"
echo -e "  Swap size : $SWAP_SIZE"
echo -e "  Swap file : $SWAP_FILE"
echo ""

# ── Step 1: Check we are root ──────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
  fail "Must be run as root. Try: sudo bash add_swap.sh"
fi
ok "Running as root"

# ── Step 2: Check if swap already exists ──────────────────
if swapon --show | grep -q "$SWAP_FILE"; then
  warn "Swap is already active on $SWAP_FILE"
  swapon --show
  echo ""
  info "Current memory and swap:"
  free -h
  echo ""
  warn "Nothing to do — swap is already configured."
  exit 0
fi

# ── Step 3: Check available disk space ────────────────────
AVAIL_KB=$(df / | tail -1 | awk '{print $4}')
# Convert requested size to KB for comparison
SIZE_NUM=$(echo "$SWAP_SIZE" | grep -oE '[0-9]+')
SIZE_UNIT=$(echo "$SWAP_SIZE" | grep -oE '[GgMm]')
case "${SIZE_UNIT,,}" in
  g) NEEDED_KB=$((SIZE_NUM * 1024 * 1024)) ;;
  m) NEEDED_KB=$((SIZE_NUM * 1024)) ;;
  *) NEEDED_KB=$((SIZE_NUM * 1024 * 1024)) ;;
esac

if [ "$AVAIL_KB" -lt "$NEEDED_KB" ]; then
  fail "Not enough disk space. Available: $((AVAIL_KB/1024))MB  Needed: $((NEEDED_KB/1024))MB"
fi
ok "Disk space available: $((AVAIL_KB/1024))MB free — sufficient for $SWAP_SIZE swap"

# ── Step 4: Create the swap file ──────────────────────────
info "Creating swap file at $SWAP_FILE ($SWAP_SIZE)..."
if fallocate -l "$SWAP_SIZE" "$SWAP_FILE" 2>/dev/null; then
  ok "Swap file created with fallocate"
elif dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$((NEEDED_KB/1024))" status=progress 2>/dev/null; then
  ok "Swap file created with dd (fallocate not available)"
else
  fail "Could not create swap file at $SWAP_FILE"
fi

# ── Step 5: Set permissions ────────────────────────────────
info "Setting permissions (chmod 600)..."
chmod 600 "$SWAP_FILE" || fail "Could not set permissions on $SWAP_FILE"
ok "Permissions set to 600 — only root can read/write"

# Verify
PERMS=$(stat -c "%a" "$SWAP_FILE")
if [ "$PERMS" = "600" ]; then
  ok "Permissions verified: $PERMS"
else
  fail "Permissions are $PERMS — expected 600"
fi

# ── Step 6: Format as swap ────────────────────────────────
info "Formatting as swap space (mkswap)..."
mkswap "$SWAP_FILE" || fail "mkswap failed on $SWAP_FILE"
ok "Swap space formatted"

# ── Step 7: Enable swap ───────────────────────────────────
info "Enabling swap (swapon)..."
swapon "$SWAP_FILE" || fail "swapon failed — could not activate swap"
ok "Swap activated"

# ── Step 8: Make permanent in /etc/fstab ──────────────────
FSTAB_ENTRY="/swapfile none swap sw 0 0"
if grep -q "$SWAP_FILE" /etc/fstab; then
  warn "/etc/fstab already has an entry for $SWAP_FILE — skipping"
else
  info "Adding to /etc/fstab to persist across reboots..."
  echo "$FSTAB_ENTRY" >> /etc/fstab
  ok "Added to /etc/fstab: $FSTAB_ENTRY"
fi

# ── Step 9: Set swappiness ────────────────────────────────
info "Setting swappiness to 10 (prefer RAM over swap)..."
echo 10 > /proc/sys/vm/swappiness

# Make swappiness permanent
if grep -q "vm.swappiness" /etc/sysctl.conf; then
  sed -i 's/^vm.swappiness.*/vm.swappiness=10/' /etc/sysctl.conf
else
  echo "vm.swappiness=10" >> /etc/sysctl.conf
fi
ok "Swappiness set to 10 (permanent)"

# ── Step 10: Verify and show summary ──────────────────────
echo ""
echo -e "${BLD}  ✅ SWAP SETUP COMPLETE${RST}"
echo -e "  ────────────────────────────────────────"
echo ""
info "Swap status:"
swapon --show
echo ""
info "Memory and swap overview:"
free -h
echo ""
info "Swappiness:"
cat /proc/sys/vm/swappiness
echo ""
ok "Swap will persist after reboot (entry in /etc/fstab)"
echo ""
