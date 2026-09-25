# Single source of truth for the whole install pipeline.
# Every bin/*.sh sources this via lib/common.sh. Nothing else holds values.

# Where the pipeline lives on the target system once 20-bootstrap copies it in.
ARCH_INSTALL_DIR=/opt/arch-install

# Repo used as the canonical source of truth for the installed scripts.
REPO_URL=https://github.com/ityreh/arch-install

# --- machine -------------------------------------------------------------
# Defaults; every install still asks via dialog, but these pre-fill the boxes.
HOSTNAME_DEFAULT=archbox
TIMEZONE=Europe/Berlin
LOCALE=en_US.UTF-8
KB_LAYOUT=de-latin1

# --- disk ------------------------------------------------------------------
BOOT_PART_SIZE=512M
SWAP_SIZE_DEFAULT=8G
ROOT_FS=btrfs

# --- user -------------------------------------------------------------------
USER_DEFAULT=main
DOTFILES_REPO=https://github.com/ityreh/dotfiles
DOTFILES_BRANCH=mouseless
GIT_NAME="Yannick Rehberger"
GIT_EMAIL=yr@ityreh.de

# --- user tools ------------------------------------------------------------------
# Cargo-installed binaries land in ~/.cargo/bin, ble.sh path is referenced by .bashrc.
CARGO_TOOLS=(workmux starship)
BLE_SH_TAG=v0.4.0-devel3
BLE_SH_DIR=ble-0.4.0-devel3
BLE_SH_URL="https://github.com/akinomyoga/ble.sh/releases/download/${BLE_SH_TAG}/${BLE_SH_DIR}.tar.xz"

# --- packages ----------------------------------------------------------------
AUR_HELPER=yay
# Categories pre-selected in the 40-packages dialog checklist.
APPS_DEFAULT="essential network tools tmux notifier git i3 zsh neovim"

# systemd units enabled during 30-chroot (installed as part of the catalog).
SYSTEMD_SERVICES=(NetworkManager)