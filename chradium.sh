#!/bin/bash

arch=$(uname -m)
TARGET=$1

echo "Welcome to the ChRadium Wizard!"
echo "Note: Only MT8183 ARM Chromebooks are supported."
echo ""
echo "Tip: You can run your favorite distro's install script manually."
echo ""
echo "For example:"
echo "ArchLinuxARM: sudo bash archlinuxarm.sh --device=kukui TARGETDRIVE"
echo ""
echo "Debian: sudo bash debian.sh --device=kukui TARGETDRIVE"
echo ""
echo "Ubuntu: sudo bash ubuntu.sh --device=kukui TARGETDRIVE"
echo ""
echo "Make sure to replace TARGETDRIVE with a storage medium's dev node. (eg. sda, sdb, mmcblk0, etc.)"
sleep 10

if [[ "$arch" == "aarch64" ]]; then
    echo "Architecture is aarch64, continuing..."
else
    echo "Error: Please run this on an arm64 system. Instructions are in the readme."
    exit
fi

if ping -q -c 1 -W 1 google.com >/dev/null; then
  echo "You are online, continuing..."
  echo ""
else
  echo "Error: You are offline! Please connect to the internet."
  echo ""
  exit
fi

if [[ -b "$PWD/firmware/usr/share/alsa/ucm2/mt8183_mt6358_t.readme" ]]; then
    echo "Script is running from the root directory of the repository, continuing..."
else
    echo "Error: Please run this script from the ChRadium repository."
    exit
fi

if [[ $EUID -eq 0 ]]; then
    echo "Script is being run as root, continuing..."
else
    echo "Error: Please run this script as root!"
    echo "This is usually done with sudo or doas."
    exit
fi

if [ "$1" == "" ]; then
     echo "Error: Please specify a USB, SD Card, etc. to install to (sda, sdb, etc.)."
     exit
fi

PS3='Please enter your choice: '
options=("ArchLinuxARM" "Debian" "Ubuntu" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "ArchLinuxARM")
            echo "Starting ArchLinuxARM installer..."
            bash archlinuxarm.sh --device=kukui $TARGET
            
            ;;
        "Debian")
            echo "Starting Debian installer..."
            bash debian.sh --device=kukui $TARGET
            ;;
        "Ubuntu")
            echo "Starting Ubuntu installer..."
            bash ubuntu.sh --device=kukui $TARGET
            ;;
        "Quit")
            echo "Quitting..."
            exit
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done
