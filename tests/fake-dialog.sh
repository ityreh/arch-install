#!/usr/bin/env bash
# tests/fake-dialog.sh — non-interactive stand-in for dialog.
# Lets 40/50-packages run unattended by answering prompts with canned values.
# Point DIALOG at it:  DIALOG=/path/to/fake-dialog.sh  (common.sh honors $DIALOG)

# Dialog writes its RESULT to stderr (exit code carries cancel/ok).
# We mimic that: echo canned answers to stderr, always exit 0.

answer() {
    printf '%s\n' "$1" >&2
}

case "$*" in
    *--yesno*)      exit 0 ;;                    # confirm()  → yes
    *--msgbox*|*--infobox*)  exit 0 ;;
    *--inputbox*|*--passwordbox*)
        answer "${FAKE_DIALOG_TEXT:-archbox}" ;;
    *--checklist*)
        answer "${FAKE_DIALOG_CHECKLIST:-essential}" ;;
    *--menu*)
        answer "${FAKE_DIALOG_MENU:-1}" ;;
    *)  exit 0 ;;
esac