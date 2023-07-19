#!/bin/bash

echo "Starting chroot script..."
userdel linux
rm -rf /home/linux

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

read -p "Do you want the Xfce desktop environment installed? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
    echo "Removing Xfce..."
    systemctl disable lightdm.service
    apt purge xfconf xfce4-utils xfwm4 xfce4-session xfdesktop4 exo-utils xfce4-panel xfce4-terminal thunar lightdm lightdm-settings -y
    apt remove xfce4* -y
    apt autoremove -y
fi
