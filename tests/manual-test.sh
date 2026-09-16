#!/usr/bin/env bash
# tests/manual-test.sh — lightweight smoke tests for the install pipeline.
#
# Runs inside the archlinux test container (or on any system with pacman).
# No interactive prompts; uses fake-dialog for all dialog calls.
#
#   bash tests/manual-test.sh           # quick checks only
#   bash tests/manual-test.sh --full    # also run 40/50 for real (needs root)
#
# Quick checks verify helpers and CSV parsing without touching pacman.
# Full checks install a few packages inside the container.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAKE_DIALOG="$REPO_DIR/tests/fake-dialog.sh"

PASS=0
FAIL=0
run() {
    local label="$1"; shift
    printf '  %-50s ' "$label"
    if "$@" >/dev/null 2>&1; then
        printf 'PASS\n'; PASS=$((PASS+1))
    else
        printf 'FAIL\n'; FAIL=$((FAIL+1))
    fi
}

# --- assertions (tiny) -------------------------------------------------------
contains() { grep -q "$2" "$1"; }

echo '=== arch-install smoke tests ==='

# --- 1. config/settings.sh loads and exposes expected keys --------------------
echo
echo '[settings.sh]'
run "sources without error" bash -c "source $REPO_DIR/config/settings.sh"
run "TIMEZONE is set"       bash -c "source $REPO_DIR/config/settings.sh; [[ -n \"\$TIMEZONE\" ]]"
run "LOCALE is set"         bash -c "source $REPO_DIR/config/settings.sh; [[ -n \"\$LOCALE\" ]]"
run "GIT_EMAIL is set"      bash -c "source $REPO_DIR/config/settings.sh; [[ -n \"\$GIT_EMAIL\" ]]"

# --- 2. common.sh helpers ----------------------------------------------------
echo
echo '[common.sh]'
run "sources without error" bash -c "source $REPO_DIR/bin/lib/common.sh"
run "state_save + roundtrip" bash -c "
    source $REPO_DIR/bin/lib/common.sh
    STATE_DIR=\$(mktemp -d) STATE_FILE=\$STATE_DIR/test.env
    state_save DISK=/dev/sda BOOT_MODE=uefi
    state_load
    [[ \"\$DISK\" == /dev/sda && \"\$BOOT_MODE\" == uefi ]]
"

# --- 3. packages/apps.csv parsing --------------------------------------------
echo
echo '[packages/apps.csv]'
run "parse_categories returns a non-empty list" \
    bash -c "source $REPO_DIR/bin/lib/common.sh; [[ -n \"\$(parse_categories $REPO_DIR/packages/apps.csv)\" ]]"
run "parse_categories includes 'essential'" \
    bash -c "source $REPO_DIR/bin/lib/common.sh; parse_categories $REPO_DIR/packages/apps.csv | grep -q essential"
run "filter_by_category returns packages for essential" \
    bash -c "source $REPO_DIR/bin/lib/common.sh; filter_by_category $REPO_DIR/packages/apps.csv essential | grep -q xorg"
run "parse_categories returns exactly the 13 known groups" \
    bash -c "source $REPO_DIR/bin/lib/common.sh; \
        expected='browsers develop essential git i3 js neovim network notifier tmux tools urxvt zsh'; \
        actual=\"\$(parse_categories $REPO_DIR/packages/apps.csv | sort | tr '\\n' ' ' | sed 's/ \$//')\"; \
        [[ \"\$actual\" == \"\$expected\" ]]"

# --- 4. fake-dialog.sh works for checklist/inputbox --------------------------
echo
echo '[fake-dialog.sh]'
run "inputbox returns FAKE_DIALOG_TEXT" \
    bash -c "source $REPO_DIR/bin/lib/common.sh; DIALOG=$FAKE_DIALOG; [[ \"\$(inputbox 'test')\" == archbox ]]"
run "checklist returns FAKE_DIALOG_CHECKLIST" \
    bash -c "source $REPO_DIR/bin/lib/common.sh; DIALOG=$FAKE_DIALOG; [[ \"\$(checklist 'test' 0 0 0 a '' on)\" == essential ]]"

# --- 5. bash -n (syntax) over every script -----------------------------------
echo
echo '[syntax check]'
all_pass=true
for f in "$REPO_DIR"/bin/*.sh "$REPO_DIR"/bin/lib/*.sh "$REPO_DIR"/config/settings.sh; do
    run "bash -n $(basename "$f")" bash -n "$f" || all_pass=false
done

# --- 6. full run (optional): 40-packages + 50-user ---------------------------
if [[ "${1:-}" == "--full" ]]; then
    echo
    echo '[full run — 40-packages + 50-user (pacman installs)]'
    export DIALOG="$FAKE_DIALOG"
    export FAKE_DIALOG_CHECKLIST="essential"
    export ARCH_INSTALL_DIR="$REPO_DIR"

    run "40-packages.sh (as root)" bash -c "
        source $REPO_DIR/bin/lib/common.sh
        state_save TARGET_USER=tester DISK=/dev/sda BOOT_MODE=uefi
        sudo bash $REPO_DIR/bin/40-packages.sh
    "

    run "50-user.sh (as tester)" bash -c "
        source $REPO_DIR/bin/lib/common.sh
        state_save TARGET_USER=tester DISK=/dev/sda BOOT_MODE=uefi
        sudo -u tester bash -c '
            export ARCH_INSTALL_DIR=$REPO_DIR STATE_DIR=/var/lib/arch-install
            source $REPO_DIR/bin/lib/common.sh
            source $REPO_DIR/config/settings.sh
            export DIALOG=$FAKE_DIALOG
            export FAKE_DIALOG_TEXT=tester
            $REPO_DIR/bin/50-user.sh
        '
    "
fi

# --- summary ------------------------------------------------------------------
echo
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1