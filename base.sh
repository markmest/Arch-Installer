#!/usr/bin/env bash

echo "-------------------------------------------------"
echo "--Setting up mirrors for optimal download speed--"
echo "-------------------------------------------------"
timedatectl set-ntp true
loadkeys croat
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector --country Croatia --age 6 --sort rate --save /etc/pacman.d/mirrorlist
pacman-key --init 
pacman-key --populate
pacman -Syyy
echo " "

echo "-------------------------------------------------"
echo "-----------Partitioning & Formatting-------------"
echo "-------------------------------------------------"
echo " "

echo "Drives availiable in the system: "
lsblk

read -p "Drive to partition and format (example /dev/sda): " TARGET_DRIVE
cfdisk $TARGET_DRIVE

echo "Current drive state: "
lsblk
echo " "

echo "Formatting /dev/sda1 as FAT32..."
mkfs.fat -F32 /dev/sda1

echo "Formatting /dev/sda2 & /dev/sda3 as ext4..."
mkfs.ext4 /dev/sda2 
mkfs.ext4 /dev/sda3
echo "Mounting partitions to their respective mount points..."
mount /dev/sda2 /mnt 
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/sda1 /mnt/boot
mount /dev/sda3 /mnt/home
echo " "

echo "-------------------------------------------------"
echo "------Pacstrapping & Generating fstab file-------"
echo "-------------------------------------------------"
echo "Installing base packages..."
pacstrap /mnt base base-devel linux linux-firmware intel-ucode neovim

echo "Generating fstab file..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "-------------------------------------------------"
echo "---------Moving into your new installation-------"
echo "-------------------------------------------------"
arch-chroot /mnt
exit


