#!/bin/bash

echo "Starting chroot script..."
pacman-key --init
pacman-key --populate archlinuxarm
pacman -S sudo git linux-aarch64 linux-aarch64-chromebook bash --noconfirm
touch /etc/modprobe.d/blacklist.conf
echo "install bluetooth /bin/false" | tee -a /etc/modprobe.d/blacklist.conf
mkinitcpio -p linux-aarch64
userdel alarm 
rm -rf /home/alarm

read -p "Enter the username to add: " username
useradd "$username"
passwd "$username"
mkdir /home/$(echo $username)

if [[ $? -eq 0 ]]; then
  echo "User '$username' created successfully."
else
  echo "Error: Failed to create user '$username'."
fi

read -p "Enter the new hostname: " new_hostname

hostnamectl set-hostname "$new_hostname"

if [[ $? -eq 0 ]]; then
  echo "Hostname changed to '$new_hostname' successfully."
else
  echo "Error: Failed to change hostname to '$new_hostname'."
fi

echo "$(echo $username) ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

echo "Enter password to set for root"
passwd

echo "Only GDM and console display managers (ly, etc.) work."
pacman -S gnome gdm networkmanager firefox --noconfirm
systemctl enable NetworkManager.service
