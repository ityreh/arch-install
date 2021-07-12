#!/bin/bash

# never run pacman -Sy on your system!
pacman -Sy dialog

# time
timedatectl set-ntp true

# greet and warn users
dialog --defaultno --title "Are you sure?" --yesno \
    "This is my personnal arch linux install. \n\n\
    It will DESTROY EVERYTHING on one of your hard disk. \n\n\
    Don't say YES if you are not sure what you're doing! \n\n\
    Do you want to continue?" 15 60 || exit

# set the computer name
dialog --no-cancel --inputbox "Enter a name for your computer." \
    10 60 2> comp

#TODO: UEFI
