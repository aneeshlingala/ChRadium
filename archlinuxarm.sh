echo "Arch Linux ARM for unsupported Chromebooks"
echo "Release 2023.07.08, Pani Puri"
echo ""

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
FIRMWAREDIR=$PWD/firmware/*
disk_size=$(blockdev --getsize64 "/dev/$TARGET")
sector_size=$(blockdev --getss "/dev/$TARGET")
total_sectors=$((disk_size / sector_size))
start_sector=$(cgpt show -i 1 -b "/dev/$TARGET")
end_sector=$((total_sectors - 1))



if [ "$1" == "--device=kukui" ]; then
     echo ""
     echo "Partitioning the selected device..."
     echo "WARNING: THIS WILL WIPE ALL DATA on the selected drive."
     echo "Press any key to continue..."
     read -s -n 1
     echo ""
     echo "Pressed a key, wiping... You can now sit back and relax."
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
    cp chroot-run.sh /tmp/tmpmount/
    chroot /tmp/tmpmount/chroot-run.sh /bin/bash -c "su - -c /chroot-run.sh"
    echo "Successfully finished. You can now boot into the new system by inserting the drive, rebooting, and pressing CTRL+U."
 fi
