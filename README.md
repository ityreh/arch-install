# arch-install

This is an automated setup of my personal archlinux development environment. Please use the sources here only to get inspiration and take them into your own setup instead of running the scripts as they are on your system, because they are tailored to me. If you want to automate the setup of your own environment, I highly recommend the book by [Matthieu Cneude](https://github.com/Phantas0s) called [Building your Mouseless Development Environment](https://themouseless.dev/) for automating vanilla setup and some explanations or just use a [distro](https://distrowatch.com/) that matches your requirements. Of course, the [Arch Wiki](https://wiki.archlinux.org/title/Main_page) is also a great resource.

## Installation (vanilla)

I am not really maintaining the vanilla installation anymore but I keep it as an example.

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

    curl -LO https://raw.githubusercontent.com/ityreh/arch-install/main/vanilla/install-sys.sh && bash install_sys.sh

## Installation (distro / endeavouros)

Instead of installing vanilla Arch I decided to use EndeavourOS that is based on Arch. The installer is easy to use and you can choose between multiple desktop environments. I am using [KDE Plasma](https://kde.org/de/plasma-desktop/) on my tower and [i3](https://i3wm.org/) on my laptop.

Because the distro installation is doing the system setup, we can just install our apps right after it:

    curl -LO https://raw.githubusercontent.com/ityreh/arch-install/main/endeavouros/install-apps.sh && bash install-apps.sh 

> For more information about my configuration have a look at [.dotfiles](https://github.com/ityreh/.dotfiles).
