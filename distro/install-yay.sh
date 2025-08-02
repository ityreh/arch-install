#!/bin/bash

sudo pacman -Syu --noconfirm
sudo pacman -S --needed base-devel git --noconfirm

git clone https://aur.archlinux.org/yay.git
cd yay

makepkg -si --noconfirm

echo "Yay installed successfully. Version:"
yay --version
