#!/usr/bin/env bash
# bin/50-user.sh — user-level setup: keymap, AUR helper, git identity, dotfiles.
# Must run as the target user (sudo -u or after reboot).
#
#   Usage: 50-user.sh

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "$0")/lib/common.sh"

[[ $EUID -eq 0 ]] && die "Run 50-user.sh as a normal user (or use runuser -u)."
state_load

TARGET_USER="${TARGET_USER:-$USER_DEFAULT}"
DOTFILES="$HOME/dotfiles"
ARCH_INSTALL_DIR="${ARCH_INSTALL_DIR:-/opt/arch-install}"
STATE_DIR="${STATE_DIR:-/var/lib/arch-install}"
AUR_QUEUE="$STATE_DIR/.aur_queue"

# --- keymap ------------------------------------------------------------------
if command -v localectl >/dev/null; then
    localectl --no-convert set-x11-keymap "$KB_LAYOUT"
    log "X11 keymap set to $KB_LAYOUT"
fi

# --- AUR helper (yay) --------------------------------------------------------
install_aur_helper() {
    if command -v "$AUR_HELPER" >/dev/null; then
        log "$AUR_HELPER already installed"
        return 0
    fi
    log "Installing $AUR_HELPER..."
    local tmp; tmp=$(mktemp -d)
    if [[ "$AUR_HELPER" == yay ]]; then
        (
            cd "$tmp"
            git clone https://aur.archlinux.org/yay.git .
            makepkg -si --noconfirm
        )
    else
        die "Unknown AUR helper: $AUR_HELPER"
    fi
    rm -rf "$tmp"
    log "$AUR_HELPER installed"
}

install_aur_helper

# --- AUR queue ----------------------------------------------------------------
if [[ -f "$AUR_QUEUE" ]]; then
    total=$(wc -l < "$AUR_QUEUE")
    c=0
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        c=$((c + 1))
        if ! "$AUR_HELPER" --noconfirm -S "$pkg" 2>/dev/null; then
            log "WARN: $pkg failed to install from AUR"
        else
            log "AUR $c/$total: $pkg"
        fi
    done < "$AUR_QUEUE"
    rm -f "$AUR_QUEUE"
else
    log "No AUR packages queued"
fi

# --- git identity -------------------------------------------------------------
mkdir -p "$HOME/.config/git"
if [[ -f "$HOME/.config/git/gitconfig" ]] \
    && grep -q "$GIT_EMAIL" "$HOME/.config/git/gitconfig" 2>/dev/null; then
    log "Git identity already configured, skipping"
else
    git config --global user.email "$GIT_EMAIL"
    git config --global user.name  "$GIT_NAME"
    git config --global pull.rebase true
    log "Git identity configured for $GIT_NAME <$GIT_EMAIL>"
fi

# --- dotfiles -----------------------------------------------------------------
if [[ ! -d "$DOTFILES" ]]; then
    log "Cloning dotfiles from $DOTFILES_REPO"
    git clone "$DOTFILES_REPO" "$DOTFILES"
fi

if [[ -f "$DOTFILES/install.sh" ]]; then
    log "Running dotfiles installer"
    (
        cd "$DOTFILES"
        bash install.sh
    )
elif [[ -f "$DOTFILES/.zshenv" ]]; then
    log "Sourcing .zshenv from dotfiles"
    source "$DOTFILES/.zshenv"
fi

log "50-user done. Everything installed. Enjoy!"