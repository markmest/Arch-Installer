#!/usr/bin/env -S bash -e

# Clear the TTY.
clear

# Cosmetics (colours for text).
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'  
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

# Pretty print (function).
info_print () {
    echo -e "${BOLD}${BGREEN}[${BYELLOW}•${BGREEN}] $1${RESET}"
}

# Pretty print for input (function).
input_print () {
    echo -ne "${BOLD}${BYELLOW}[${BGREEN}•${BYELLOW}] $1${RESET}"
}

# Alert user of bad input (function).
error_print () {
    echo -e "${BOLD}${BRED}[${BBLUE}•${BRED}] $1${RESET}"
}

info_print "Setting up mirrors for optimal download speed and generating new keyring."
timedatectl set-ntp true
loadkeys croat
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector --country Croatia --age 6 --sort rate --save /etc/pacman.d/mirrorlist
pacman-key --init 
pacman-key --populate
pacman -Syyy

info_print "Partitioning and formatting."
info_print "Drives availiable in the system: "
lsblk

input_print "Drive to partition and format (example /dev/sda): " 
read -r TARGET_DRIVE
cfdisk $TARGET_DRIVE

info_print "Formatting /dev/sda1 as FAT32..."
mkfs.fat -F32 /dev/sda1

info_print "Formatting /dev/sda2 & /dev/sda3 as ext4..."
mkfs.ext4 /dev/sda2 
mkfs.ext4 /dev/sda3
info_print "Mounting partitions to their respective mount points..."
mount /dev/sda2 /mnt 
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/sda1 /mnt/boot
mount /dev/sda3 /mnt/home

info_print "Installing base packages..."
pacstrap /mnt base base-devel linux linux-firmware intel-ucode 

info_print "Generating fstab file..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "-------------------------------------------------"
echo "-----Base system installed successfully----------"
echo "-------------------------------------------------"
arch-chroot /mnt
exit


