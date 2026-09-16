#!/usr/bin/env bash
# bin/lib/common.sh — shared helpers for the whole install pipeline.
#
# Every phase script sources this first. It is idempotent.

set -euo pipefail

# --- resolve paths ----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$BIN_DIR/.." && pwd)"

# Source the settings file relative to the repo root.
# shellcheck source=../../config/settings.sh
source "$REPO_DIR/config/settings.sh"

# --- runtime state ----------------------------------------------------------

STATE_DIR=/var/lib/arch-install
STATE_FILE="$STATE_DIR/state.env"

# Merge new KEY=VALUE pairs into the state file without clobbering existing keys.
state_save() {
    mkdir -p "$STATE_DIR"
    # Remove any lines that will be replaced
    for arg in "$@"; do
        key="${arg%%=*}"
        sed -i "/^${key}=/d" "$STATE_FILE" 2>/dev/null || true
    done
    for arg in "$@"; do
        printf '%s\n' "$arg" >> "$STATE_FILE"
    done
    chmod 0644 "$STATE_FILE"
}

state_load() {
    [[ -f "$STATE_FILE" ]] && source "$STATE_FILE"
}

# --- environment detection --------------------------------------------------

is_live() {
    [[ -f /etc/arch-release ]] && mountpoint -q /proc 2>/dev/null \
        && [[ -z "${TARGET:-}" ]]
}

is_chroot() {
    [[ "$(stat -c %d /)" != "$(stat -c %d /proc/1/root/ 2>/dev/null)" ]]
}

# --- root check -------------------------------------------------------------

require_root() {
    if [[ $EUID -ne 0 ]]; then
        die "Run this script as root"
    fi
}

# --- logging ----------------------------------------------------------------

log()  { printf '[  %s  ] %s\n' "$(date +%H:%M:%S)" "$*" >&2; }
info() { log "INFO"; log " $*"; }
die()  { log "FATAL: $*"; exit 1; }

# --- dialog -----------------------------------------------------------------

DIALOG="${DIALOG:-dialog}"
export DIALOG

# dialog writes results to stderr, so capture via a temp file
# (the Arch Wiki pattern) instead of command substitution.

confirm() {
    "$DIALOG" --defaultno --yesno "$1" 15 60
}

msgbox() {
    "$DIALOG" --msgbox "$1" 15 60
}

infobox() {
    "$DIALOG" --infobox "$1" 8 70
}

inputbox() {
    local out; out=$(mktemp)
    if ! "$DIALOG" --no-cancel --inputbox "$1" 10 60 "${@:2}" 2>"$out"; then
        rm -f "$out"
        die "Aborted"
    fi
    local value; value=$(<"$out"); rm -f "$out"
    printf '%s' "$value"
}

passwordbox() {
    local out; out=$(mktemp)
    if ! "$DIALOG" --no-cancel --passwordbox "$1" 10 60 2>"$out"; then
        rm -f "$out"
        die "Aborted"
    fi
    local value; value=$(<"$out"); rm -f "$out"
    printf '%s' "$value"
}

# --menu <title> <height> <width> <menu-height> <item> <desc> [...]
# echoes the selected item on stdout.
menu() {
    local out; out=$(mktemp)
    if ! "$DIALOG" --menu "$1" "$2" "$3" "$4" "${@:5}" 2>"$out"; then
        rm -f "$out"
        die "Aborted"
    fi
    local value; value=$(<"$out"); rm -f "$out"
    printf '%s' "$value"
}

# --- helpers ----------------------------------------------------------------

# Fetch the Arch Linux package list from the repo's catalog.
# Call as: fetch_packages "$ARCH_INSTALL_DIR/packages/apps.csv"
parse_categories() {
    local csv="${1:?csv path required}"
    awk -F, 'NF && !/^#/ { if (!seen[$1]++) print $1 }' "$csv"
}

# Return all entries belonging to a single category.
filter_by_category() {
    local csv="$1" cat="$2"
    awk -F, -v c="$cat" '$1==c && NF && !/^#/' "$csv"
}

# Run a command, printing its exit status to stdout and suppressing stderr.
run_quiet() {
    "$@" 2>/dev/null
    return $?
}