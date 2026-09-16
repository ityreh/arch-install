#!/usr/bin/env bash
# bin/20-bootstrap.sh — live USB phase: pacstrap base system, fstab, and
# copy this repo into the target so every later phase runs from disk
# (no curl-cascade from GitHub).
#
#   Usage: 20-bootstrap.sh

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "$0")/lib/common.sh"

require_root
state_load
[[ -n "${DISK:-}" ]] || die "Run 10-partition.sh first"

if [[ ! -d /mnt/sys ]]; then
    mountpoint -q /mnt || die "/mnt is not mounted. Run 10-partition.sh first."
fi

# --- base system ---------------------------------------------------------------
msgbox "Phase 2: installing the base system to /mnt. This takes a while."
log "Installing base packages with pacstrap"
pacstrap /mnt \
    base base-devel linux linux-firmware \
    dialog sudo btrfs-progs git

# --- fstab ----------------------------------------------------------------------
log "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# --- carry the state file into the target --------------------------------------
if [[ -f "$STATE_FILE" ]]; then
    mkdir -p /mnt/var/lib/arch-install
    cp "$STATE_FILE" /mnt/var/lib/arch-install/state.env
fi

# --- copy this repo into the target --------------------------------------------
log "Copying install scripts to $ARCH_INSTALL_DIR"
mkdir -p "/mnt$ARCH_INSTALL_DIR"
if command -v rsync >/dev/null; then
    rsync -a --exclude=.git --exclude='*.code-workspace' "$REPO_DIR/" "/mnt$ARCH_INSTALL_DIR/"
else
    cp -a "$REPO_DIR" "/mnt$ARCH_INSTALL_DIR/"
fi

log "Bootstrap done. Run bin/30-chroot.sh next."
msgbox "Base system installed. Continuing with the chroot setup."