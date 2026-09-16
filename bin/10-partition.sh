#!/usr/bin/env bash
# bin/10-partition.sh — live USB phase: wipe, partition, format, mount the disk.
# Run as root from the Arch live ISO, before bootstrapping.
#
#   Usage: 10-partition.sh [--disk /dev/sdX] [--swap 8G]

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "$0")/lib/common.sh"

require_root

# --- optional flags override interactive prompts ----------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --disk) DISK_ARG="$2"; shift 2 ;;
        --swap) SWAP_ARG="$2"; shift 2 ;;
        *) die "Unknown option: $1" ;;
    esac
done
DISK_ARG="${DISK_ARG:-}"
SWAP_ARG="${SWAP_ARG:-}"
export DISK_ARG SWAP_ARG

if confirm "This is your personal Arch Linux install.

    It will DESTROY EVERYTHING on one of your hard disks.

    Don't say YES if you are not sure what you're doing!

    Do you want to continue?"; then
    :
else
    die "Aborted by user"
fi

# --- collect inputs ----------------------------------------------------------

[[ -n "$DISK_ARG" ]] || DISK_ARG="$(inputbox "Enter the disk to install to (e.g. /dev/sda):")"
[[ -n "$SWAP_ARG" ]] || SWAP_ARG="$(inputbox "Swap size (default ${SWAP_SIZE_DEFAULT}):" "$SWAP_SIZE_DEFAULT")"

# sanitize swap size: must look like a number or end with a size suffix
if ! [[ "$SWAP_ARG" =~ ^[0-9]+[MGK]?$ ]]; then
    log "Invalid swap size '$SWAP_ARG', using ${SWAP_SIZE_DEFAULT}"
    SWAP_ARG="$SWAP_SIZE_DEFAULT"
fi

grep -q "^$DISK_ARG " /proc/partitions || die "Disk $DISK_ARG not found"
DISK="$DISK_ARG"
SWAP="$SWAP_ARG"

# --- detect boot mode (UEFI or BIOS) -----------------------------------------
BOOT_MODE=bios
if ls /sys/firmware/efi/efivars >/dev/null 2>&1; then
    BOOT_MODE=uefi
fi
log "Boot mode: $BOOT_MODE"

# --- disk wipe ----------------------------------------------------------------
wipe_choice=$(menu "How should $DISK be wiped?" 15 60 4 \
    1 "Use dd (overwrite all bytes)" \
    2 "Use shred (slow & secure)" \
    3 "No need - disk is already empty")

case "$wipe_choice" in
    1) dd if=/dev/zero of="$DISK" bs=1M status=progress ;;
    2) shred -v "$DISK" ;;
esac
[[ $wipe_choice == 3 ]] && log "Skipping wipe, leaving disk contents untouched"

# --- partition (fresh GPT table) ----------------------------------------------
PART_SUFFIX=
[[ "$DISK" == *nvme* || "$DISK" == *mmcblk* ]] && PART_SUFFIX=p

partprobe "$DISK"

# Partition numbers: 1 = boot/efi, 2 = swap, 3 = root.
# For UEFI partition 1 is an EFI system partition, for BIOS a BIOS boot partion.
if [[ "$BOOT_MODE" == uefi ]]; then
    printf 'g\nn\n1\n\n+%s\nt\n1\nn\n2\n\n+%s\nn\n3\n\n\nw\n' \
        "$BOOT_PART_SIZE" "$SWAP" | fdisk "$DISK" >/dev/null
    BOOT_PART="${DISK}${PART_SUFFIX}1"
    SWAP_PART="${DISK}${PART_SUFFIX}2"
    ROOT_PART="${DISK}${PART_SUFFIX}3"
else
    printf 'g\nn\n1\n\n+%s\nt\n4\nn\n2\n\n+%s\nn\n3\n\n\nw\n' \
        "$BOOT_PART_SIZE" "$SWAP" | fdisk "$DISK" >/dev/null
    BOOT_PART="${DISK}${PART_SUFFIX}1"
    SWAP_PART="${DISK}${PART_SUFFIX}2"
    ROOT_PART="${DISK}${PART_SUFFIX}3"
fi
partprobe "$DISK"
sleep 1

# --- filesystems ---------------------------------------------------------------
log "Creating filesystems on $DISK"
mkswap "$SWAP_PART"
swapon "$SWAP_PART"
mkfs."$ROOT_FS" "$ROOT_PART"
mount "$ROOT_PART" /mnt

if [[ "$BOOT_MODE" == uefi ]]; then
    mkfs.fat -F32 "$BOOT_PART"
    mount --mkdir "$BOOT_PART" /mnt/boot/efi
else
    mkdir -p /mnt/boot
fi

# --- persist for the next phases --------------------------------------------------
state_save DISK="$DISK" BOOT_MODE="$BOOT_MODE" SWAP_PART="$SWAP_PART" \
    ROOT_PART="$ROOT_PART" BOOT_PART="$BOOT_PART"
log "Partitioning done. Root is mounted at /mnt."