#!/usr/bin/env bash
# bin/arch-install.sh — entry point for a full Arch install.
# Run on the Arch live ISO.  Optionally pass --disk /dev/XYZ and --swap 8G.
#
#   Usage: bash bin/arch-install.sh
#          bash bin/arch-install.sh --disk /dev/sda --swap 8G

set -euo pipefail
BIN_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BIN_DIR/lib/common.sh"

require_root

# --- install dialog on live ISO if missing ------------------------------------
if ! command -v dialog >/dev/null; then
    pacman -Sy dialog --noconfirm
fi

# --- dispatch ------------------------------------------------------------------
msgbox "Arch Linux installer — this will guide you through the full setup."

log "Phase 1: partitioning"
"$BIN_DIR/10-partition.sh"

log "Phase 2: bootstrap"
"$BIN_DIR/20-bootstrap.sh"

# --- chroot: runs phases 30 → 40 → 50 ----------------------------------------
log "Phase 3: chroot setup (30 → 40 → 50)"
arch-chroot /mnt bash "$ARCH_INSTALL_DIR/bin/30-chroot.sh"

# --- done -----------------------------------------------------------------------
log "Full install complete."
