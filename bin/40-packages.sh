#!/usr/bin/env bash
# bin/40-packages.sh — install package groups from apps.csv via dialog.
# Run inside chroot as root (called from 30), or standalone post-reboot.
#
#   Usage: 40-packages.sh

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "$0")/lib/common.sh"

require_root
state_load

TARGET_USER="${TARGET_USER:-$USER_DEFAULT}"
CSV="${ARCH_INSTALL_DIR:-$REPO_DIR}/packages/apps.csv"
AUR_QUEUE_FILE="$ARCH_INSTALL_DIR/.aur_queue"

# --- build checklist from CSV --------------------------------------------------
IFS=$'\n' read -d '' -r CATEGORIES <<< "$(parse_categories "$CSV")"
declare -a CHECKLIST=()
for cat in $CATEGORIES; do
    state_on=on
    # Pre-select defaults
    if echo "$APPS_DEFAULT" | grep -qw "$cat"; then
        state_on=on
    else
        state_on=off
    fi
    CHECKLIST+=("$cat" "" "$state_on")
done

Choices=$(dialog --checklist \
    "Choose which app groups to install. SPACE selects, ENTER confirms." \
    0 0 0 "${CHECKLIST[@]}" 2>/dev/null) || die "Aborted"

log "Selected groups: $Choices"

# --- parse selections → install list ------------------------------------------
count=0
: > "$AUR_QUEUE_FILE"
while IFS= read -r line; do
    count=$((count + 1))
    awk -F, -v c="$line" '$1==c && NF && !/^#/ { print $2 }' "$CSV"
done <<< "$Choices" | sort -u > "$ARCH_INSTALL_DIR/.pkg_list"

total=$(wc -l < "$ARCH_INSTALL_DIR/.pkg_list")
pkg_num=0

while IFS= read -r pkg; do
    pkg_num=$((pkg_num + 1))
    dialog --title "Installing packages" --infobox \
        "Installing $pkg_num/$total: $pkg" 8 70

    if pacman --noconfirm --needed -S "$pkg" >/dev/null 2>&1; then
        continue
    fi

    # If pacman failed, queue for the AUR helper
    echo "$pkg" >> "$AUR_QUEUE_FILE"
    log "Queued $pkg for AUR (pacman failed)"

    # Category-specific post-install hooks (system-level, runs as root)
    case "$pkg" in
        zsh)
            chsh -s "$(command -v zsh)" "$TARGET_USER"
            log "Default shell set to zsh for $TARGET_USER"
            ;;
        networkmanager)
            systemctl enable --now NetworkManager.service 2>/dev/null || true
            log "NetworkManager enabled"
            ;;
    esac
done < "$ARCH_INSTALL_DIR/.pkg_list"

# ensure wheel group has sudo
grep -q "^%wheel" /etc/sudoers 2>/dev/null || echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

rm -f "$ARCH_INSTALL_DIR/.pkg_list"

# --- post-install: enable system services --------------------------------------
for svc in "${SYSTEMD_SERVICES[@]}"; do
    if systemctl list-unit-files "${svc}.service" >/dev/null 2>&1; then
        systemctl enable --now "${svc}.service" 2>/dev/null || true
    fi
done

AUR_COUNT=$(wc -l < "$AUR_QUEUE_FILE")
if [[ "$AUR_COUNT" -gt 0 ]]; then
    msgbox "$AUR_COUNT package(s) queued for AUR. Run 50-user.sh as the target user to install them."
else
    msgbox "All packages installed successfully."
fi

log "40-packages done. Packages installed: $((total - AUR_COUNT)), queued: $AUR_COUNT"