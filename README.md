# arch-install

This is an automated setup of my personal archlinux development environment. Please use the sources here only to get inspiration and take them into your own setup instead of running the scripts as they are on your system, because they are tailored to me. If you want to automate the setup of your own environment, I highly recommend the book by [Matthieu Cneude](https://github.com/Phantas0s) called [Building your Mouseless Development Environment](https://themouseless.dev/).

## Installation

Prepare an [Arch Linux live system](https://archlinux.org/download/) (e.g. on an USB stick) and boot your system from it. If you do not have an US keyboard layout you can load the right keybindings with `loadkeys <country code>` to enter the first commands more easily. I have a german keyboard layout:

    loadkeys de-latin1

If you are connected to the internet via cable, you can skip to 'Download the installation script'. Otherwise you have to connect to the internet manually to be able to download the installation script. Enter `iwctl` to scan and connect to a WiFi network:

    iwctl

List the available devices:

    [iwd]# device list

Choose a device and get the available networks:

    [iwd]# station <device> get-networks

Choose a network and connect to it. Enter the password if necessary:

    [iwd]# station <device> connect "<network>"

After that you can exit iwctl and continue with the installation script.

    [iwd]# exit

Download the installation script:

    curl -LO https://raw.githubusercontent.com/ityreh/arch-installer/main/install_sys.sh

Run the installation script:

    bash install_sys.sh

For more information about my archlinux development environment configuration have a look at [.dotfiles](https://github.com/ityreh/.dotfiles).
