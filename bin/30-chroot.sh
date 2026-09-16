#!/usr/bin/env bash
# bin/30-chroot.sh — runs inside the chrooted target: bootloader, locale,
# hostname, users. Then chains to 40-packages and 50-user.
#
#   Usage: arch-chroot /mnt /opt/arch-install/bin/30-chroot.sh
#          (orchestrated automatically by arch-install.sh)

set -euo pipefail
source /opt/arch-install/bin/lib/common.sh

# --- runtime state ------------------------------------------------------------
state_load
BOOT_MODE="${BOOT_MODE:-bios}"
HOSTNAME_INPUT="${HOSTNAME:-$HOSTNAME_DEFAULT}"
DISK="${DISK:-/dev/sda}"

# --- hostname -----------------------------------------------------------------
dialog --no-cancel --inputbox "Computer hostname:" 10 60 2> "$ARCH_INSTALL_DIR/.host"
HOSTNAME=$(<"$ARCH_INSTALL_DIR/.host")
rm -f "$ARCH_INSTALL_DIR/.host"
hostname "$HOSTNAME"
echo "$HOSTNAME" > /etc/hostname
log "Hostname set to $HOSTNAME"

# --- systemd config -----------------------------------------------------------
# timezone
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# locale
sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

# --- bootloader ---------------------------------------------------------------
pacman --noconfirm -S grub
if [[ "$BOOT_MODE" == uefi ]]; then
    pacman --noconfirm -S efibootmgr
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
else
    grub-install "$DISK"
fi
grub-mkconfig -o /boot/grub/grub.cfg

# --- root password -------------------------------------------------------------
function prompt_user() {
    local label="$1" user_name="" pass1="" pass2=""

    while true; do
        case "$label" in
            root)
                dialog --no-cancel --passwordbox "Set the root password:" 10 60 2> "$ARCH_INSTALL_DIR/.p1"
                ;;
            *)
                dialog --no-cancel --inputbox "Username (default: $USER_DEFAULT):" 10 60 2> "$ARCH_INSTALL_DIR/.name"
                user_name=$(<"$ARCH_INSTALL_DIR/.name")
                [[ -z "$user_name" ]] && user_name="$USER_DEFAULT"
                rm -f "$ARCH_INSTALL_DIR/.name"
                dialog --no-cancel --passwordbox "Set password for $user_name:" 10 60 2> "$ARCH_INSTALL_DIR/.p1"
                ;;
        esac

        dialog --no-cancel --passwordbox "Confirm password:" 10 60 2> "$ARCH_INSTALL_DIR/.p2"

        if [[ "$(<"$ARCH_INSTALL_DIR/.p1")" == "$(<"$ARCH_INSTALL_DIR/.p2")" ]]; then
            pass1=$(<"$ARCH_INSTALL_DIR/.p1")
            rm -f "$ARCH_INSTALL_DIR/.p1" "$ARCH_INSTALL_DIR/.p2"
            break
        fi
        dialog --no-cancel --msgbox "Passwords do not match. Try again." 10 60
        rm -f "$ARCH_INSTALL_DIR/.p1" "$ARCH_INSTALL_DIR/.p2"
    done

    if [[ "$label" == root ]]; then
        echo "root:$pass1" | chpasswd
    else
        if ! id -u "$user_name" >/dev/null 2>&1; then
            useradd -m -g wheel -s /bin/bash "$user_name"
        fi
        echo "$user_name:$pass1" | chpasswd
        TARGET_USER="$user_name"
    fi
}

dialog --title "Root password" --msgbox "Set a password for the root user." 10 60
prompt_user root

dialog --title "Create user" --msgbox "Now create your primary user." 10 60
prompt_user user

# Save all state (including DISK/BOOT_MODE from earlier phases + TARGET_USER)
state_save TARGET_USER="$TARGET_USER"
log "User $TARGET_USER created"

# --- chain to next phases (still inside chroot) --------------------------------
log "Launching 40-packages.sh (as root)..."
bash "$ARCH_INSTALL_DIR/bin/40-packages.sh"

log "Launching 50-user.sh (as $TARGET_USER)..."
runuser -u "$TARGET_USER" -- bash "$ARCH_INSTALL_DIR/bin/50-user.sh"

# --- cleanup -------------------------------------------------------------------
log "Chroot setup complete. Cleaning up temp files..."
rm -rf "$ARCH_INSTALL_DIR" /var/lib/arch-install/state.env

dialog --title "Done!" --yesno "Installation complete. Reboot now?" 10 60
case $? in
    0) reboot ;;
esac