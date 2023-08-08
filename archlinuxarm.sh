#!/bin/bash

echo "Arch Linux ARM for unsupported Chromebooks"
echo "Release 2023.08.08"
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

if [[ -f "$PWD/archlinuxarm.sh" ]]; then 
     echo "Script is running from the root directory of the repository, continuing..." 
 else 
     echo "Error: Please run this script from the Paxxer repository." 
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

TARGET=$(echo $2)
FIRMWAREDIR=$PWD/firmware/*
REPODIR=$PWD
disk_size=$(blockdev --getsize64 "/dev/$TARGET")
sector_size=$(blockdev --getss "/dev/$TARGET")
total_sectors=$((disk_size / sector_size))
start_sector=$(cgpt show -i 1 -b "/dev/$TARGET")
end_sector=$((total_sectors - 1))
disk_node="$(echo $TARGET)"
partitions=$(lsblk -l -o NAME | grep "^$disk_node")
dev_type=$(lsblk -no TYPE "$disk_node")
is_mounted=false

if [[ -b "/dev/$TARGET" ]]; then
    echo "Valid device node, continuing..."
else
    echo "Error: Not a valid device node! Please make sure that the target disk is connected."
    exit
fi

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
     echo ""
     echo "Partitioning the selected device..."
     echo "WARNING: THIS WILL WIPE ALL DATA on the selected drive."
     echo "Press any key to continue..."
     read -s -n 1
     echo ""
     echo "Pressed a key, wiping..."
     echo g | fdisk /dev/$(echo $TARGET)
     cgpt create /dev/$(echo $TARGET)
     cgpt add -i 1 -t kernel -b 8192 -s 65536 -l Kernel -S 1 -T 5 -P 10 /dev/$(echo $TARGET)
     cgpt add -i 2 -t data -s "$start_sector" -e "$end_sector" -l Root "/dev/$TARGET"
     if [[ $TARGET =~ mmcblk[01] ]]; then
        mkfs.ext4 "/dev/$(echo $TARGET)p2"
        
    elif [[ -b $disk_node ]]; then
        mkfs.ext4 "/dev/$(echo $TARGET)2"
    fi
     echo "Downloading RootFS, this may take a while..."
     cd /tmp
     wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
     if [[ $TARGET =~ mmcblk[01] ]]; then
        mkdir /tmp/tmpmount
        mount /dev/$(echo $TARGET)p2 /tmp/tmpmount
        
    elif [[ -b $disk_node ]]; then
        mkdir /tmp/tmpmount
        mount /dev/$(echo $TARGET)2 /tmp/tmpmount
    fi
    bsdtar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C /tmp/tmpmount
    mount -t devtmpfs /dev /tmp/tmpmount/dev
    mount -o bind /proc /tmp/tmpmount/proc
    mount -o bind /run /tmp/tmpmount/run
    mount -o bind /sys /tmp/tmpmount/sys
    cp -r $FIRMWAREDIR /
    rm -rf /tmp/tmpmount/etc/resolv.conf
    cp /etc/resolv.conf /tmp/tmpmount/etc/
    cp $REPODIR/chroot-run.sh /tmp/tmpmount/
    chroot /tmp/tmpmount /bin/bash -c "bash /chroot-run.sh"
    echo "Cleaning up..."
    rm -rf /tmp/ArchLinuxARM-aarch64-latest.tar.gz
    rm -rf /tmp/tmpmount/chroot-run.sh
    umount /tmp/tmpmount/dev
    umount /tmp/tmpmount/proc
    umount /tmp/tmpmount/run
    umount /tmp/tmpmount/sys
    umount /tmp/tmpmount
    rm -rf /tmp/tmpmount
    echo "Script has successfully installed Arch Linux ARM. You can now boot into the new system by inserting the drive into the Chromebook," 
    echo "rebooting, and pressing CTRL+U."
    echo "End time: $(date)
 fi
