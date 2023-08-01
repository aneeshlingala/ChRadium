#!/bin/bash

echo "Arch Linux ARM for unsupported Chromebooks"
echo "Release 2023.07.31, Pani Puri"
echo ""

arch=$(uname -m)

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
     echo "Error: Please specify the model of the Chromebook (kukui, etc.)."
     exit
fi

if [ "$2" == "" ]; then
     echo "Error: Please specify a USB, SD Card, etc. to install to (sda, sdb, etc.)."
     exit
fi

if [[ -b "/dev/$TARGET" ]]; then
    echo "Valid device node, continuing..."
else
    echo "Error: Not a valid device node! Please make sure that the target disk is connected."
    exit
fi

TARGET=$(echo $2)
REPODIR=$PWD
disk_node="$(echo $TARGET)"
partitions=$(lsblk -l -o NAME | grep "^$disk_node")
dev_type=$(lsblk -no TYPE "$disk_node")
is_mounted=false

while read -r partition; do
  mountpoint=$(lsblk -l -o MOUNTPOINT "$partition" | tail -n 1)
  if [[ -n "$mountpoint" ]]; then
    echo "Error: Partition $partition is mounted at $mountpoint!"
    is_mounted=true
    exit
  fi
done <<< "$partitions"

if [[ "$is_mounted" = false ]]; then
  echo "No partitions are mounted on $disk_node, continuing..."
fi

if [[ $dev_type == "part" ]]; then
  echo "Error: The target, $(echo $TARGET) is a partition."
  exit
else
  echo "The specified disk is not a partition."
fi

if [ "$1" == "--device=kukui" ]; then
    cd /tmp
    wget https://github.com/hexdump0815/imagebuilder/releases/download/230218-01/chromebook_kukui-aarch64-bookworm.img.gz
    gzip -d chromebook_kukui-aarch64-bookworm.img.gz
    echo "Flashing, this may take a while..."
    if [[ $TARGET =~ mmcblk[01] ]]; then
            dd if=chromebook_kukui-aarch64-bookworm.img of=/dev/$(echo TARGET) bs=1M
            mkdir /tmp/tmpmount
            mount /dev/$(echo $TARGET)p4 /tmp/tmpmount
  
    elif [[ -b $disk_node ]]; then
            dd if=chromebook_kukui-aarch64-bookworm.img of=/dev/$(echo TARGET) bs=1M
            mkdir /tmp/tmpmount
            mount /dev/$(echo $TARGET)4 /tmp/tmpmount
    fi
    mount -t devtmpfs /dev /tmp/tmpmount/dev
    mount -o bind /proc /tmp/tmpmount/proc
    mount -o bind /run /tmp/tmpmount/run
    mount -o bind /sys /tmp/tmpmount/sys
    rm -rf /tmp/tmpmount/etc/resolv.conf
    cp /etc/resolv.conf /tmp/tmpmount/etc/
    cp $REPODIR/chroot-run.sh /tmp/tmpmount/
    chroot /tmp/tmpmount /bin/bash -c "bash /chroot-run-debian.sh"
    echo "Cleaning up..."
    rm -rf /tmp/chromebook_kukui-aarch64-bookworm*
    rm -rf /tmp/tmpmount/chroot-run.sh
    umount /tmp/tmpmount/dev
    umount /tmp/tmpmount/proc
    umount /tmp/tmpmount/run
    umount /tmp/tmpmount/sys
    umount /tmp/tmpmount
    rm -rf /tmp/tmpmount
    echo "Script has successfully installed Debian. You can now boot into the new system by inserting the drive into the Chromebook," 
    echo "rebooting, and pressing CTRL+U."
    echo "End time: $($date "+%D %T")"
fi
