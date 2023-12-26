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

info_print "Setting up mirrors for optimal download speed."
timedatectl set-ntp true
loadkeys croat
mv /mnt/etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist.backup
reflector --country Croatia --age 6 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyy

info_print "Drives availiable in the system: "
lsblk

input_print "Drive to partition and format (example /dev/sda): " 
read -r TARGET_DRIVE
cfdisk $TARGET_DRIVE

echo " "
lsblk
echo " "

input_print "Enter root partition (example /dev/sda2): "
read -r ROOT_PART
if [[ -n "$ROOT_PART" ]]; then
	info_print "Formatting $ROOT_PART as ext4."
	mkfs.ext4 $ROOT_PART
	info_print "Mounting $ROOT_PART to /mnt."
	mount $ROOT_PART /mnt
fi

input_print "Enter EFI partition (example /dev/sda1): "
read -r EFI_PART
if [[ -n "$EFI_PART" ]]; then
	info_print "Formatting $EFI_PART as FAT32."
	mkfs.fat -F32 $EFI_PART 
	info_print "Mounting $EFI_PART to /mnt/boot."
	mkdir /mnt/boot
	mount $EFI_PART /mnt/boot
fi


input_print "Do you also have a home partition (y/n): "
read -r HOME
if [[ "$HOME" == "y" ]]; then
	input_print "Enter home partition (example /dev/sda3): "
	read -r HOME_PART
	info_print "Formatting $HOME_PART as ext4."
	mkfs.ext4 $HOME_PART
	info_print "Mounting $HOME_PART to /mnt/home."
	mkdir /mnt/home
	mount $HOME_PART /mnt/home
fi

input_print "Do you also have a swap partition (y/n): "
read -r SWAP
if [[ "$SWAP" == "y" ]]; then
	input_print "Enter swap partition (example /dev/sda4): "
	read -r SWAP_PART
	info_print "Formatting $SWAP_PART as swap."
	info_print "Turning swap partition on."
	mkswap $SWAP_PART
	swapon $SWAP_PART

info_print "Installing base packages and generating keyring."
pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode 

info_print "Generating fstab file."
genfstab -U /mnt >> /mnt/etc/fstab
info_print "Base system installed successfully. Chrooting into the new installation."
arch-chroot /mnt
exit


