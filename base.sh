#!/usr/bin/env -S bash -e

# Clear the TTY.
clear

# Set a bigger font.
setfont ter-v22b

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

# Grab the hostname (function).
hostname_selector() {
	input_print "Enter the hostname: "
	read -r HOSTNAME
	if [[ -z "$HOSTNAME" ]]; then
		error_print "Please enter a hostname to continue."
		return 1
	fi
	return 0
}

# Setting up the user account and its password (function).
user_acc () {
    input_print "Enter a name for a user account (enter empty to not create one): "
    read -r USERNAME
    if [[ -z "$USERNAME" ]]; then
        return 0
    fi
    input_print "Enter a password for $USERNAME: "
    read -r -s USERPASS
    if [[ -z "$USERPASS" ]]; then
        echo
        error_print "You need to enter a password for $USERNAME, please try again."
        return 1
    fi
    echo
    input_print "Enter the password again: " 
    read -r -s USERPASS_CHECK
    echo
    if [[ "$USERPASS" != "$USERPASS_CHECK" ]]; then
        echo
        error_print "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

# Setting up a root account and its password (function).
root_acc () {
    input_print "Enter a password for the root user: "
    read -r -s ROOTPASS
    if [[ -z "$ROOTPASS" ]]; then
        echo
        error_print "You need to enter a password for the root user, please try again."
        return 1
    fi
    echo
    input_print "Enter the password again: " 
    read -r -s ROOT_CHECK
    echo
    if [[ "$ROOTPASS" != "$ROOT_CHECK" ]]; then
        error_print "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

# Define the list of pacman packages to install
PKGS=(
	'networkmanager'
	'linuxheaders'
	'bluez'
	'bluez-utils'
	'alsa-utils'
	'pipewire'
	'pipewire-alsa'
	'pipewire-pulse'
	'pipewire-jack'
	'rsync'
	'reflector'
	'neovim'
	'firefox'
	'nvidia'
	'nvidia-utils'
	'nvidia-settings'
)

# Define the services to autostart
services=(NetworkManager bluetooth.service reflector.timer)

# Set keyboard layout.
loadkeys croat

# Setting up root account and password.
until root_acc; do : ; done
echo " "

# Setting up user account and password.
until user_acc; do : ; done
echo " "

# Grab hostname.
until hostname_selector; do : ; done
echo " "

info_print "Drives availiable in the system: "
lsblk

input_print "Drive to partition and format: " 
read -r TARGET_DRIVE
cfdisk $TARGET_DRIVE

echo " "
lsblk
echo " "

input_print "Enter root partition: "
read -r ROOT_PART
if [[ -n "$ROOT_PART" ]]; then
	info_print "Formatting $ROOT_PART as ext4."
	mkfs.ext4 $ROOT_PART &>/dev/null
	info_print "Mounting $ROOT_PART to /mnt."
	mount $ROOT_PART /mnt
fi

input_print "Enter EFI partition: "
read -r EFI_PART
if [[ -n "$EFI_PART" ]]; then
	info_print "Formatting $EFI_PART as FAT32."
	mkfs.fat -F32 $EFI_PART &>/dev/null 
	info_print "Mounting $EFI_PART to /mnt/boot."
	mkdir /mnt/boot
	mount $EFI_PART /mnt/boot 
fi

input_print "Do you also have a home partition (y/n): "
read -r HOME
if [[ "$HOME" == "y" ]]; then
	input_print "Enter home partition: "
	read -r HOME_PART
	info_print "Formatting $HOME_PART as ext4."
	mkfs.ext4 $HOME_PART &>/dev/null
	info_print "Mounting $HOME_PART to /mnt/home."
	mkdir /mnt/home
	mount $HOME_PART /mnt/home
fi

input_print "Do you also have a swap partition (y/n): "
read -r SWAP
if [[ "$SWAP" == "y" ]]; then
	input_print "Enter swap partition: "
	read -r SWAP_PART
	info_print "Formatting $SWAP_PART as swap."
	info_print "Turning swap partition on."
	mkswap $SWAP_PART &>/dev/null
	swapon $SWAP_PART
fi

# Install base packages and NetworkManager 
info_print "Installing base packages and generating keyring."
pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode grub efibootmgr zsh &>/dev/null 

# Set the hostname
echo "$HOSTNAME" > /mnt/etc/hostname

# Generating /etc/fstab.
info_print "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting locale and console keymap
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=croat" > /mnt/etc/vconsole.conf

# Setting hosts file.
info_print "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain   $HOSTNAME
EOF

# Configuring the system
info_print "Configuring the system (timezone, system clock, GRUB)."
arch-chroot /mnt /bin/bash -e <<EOF
	
	# Setting up timezone
	ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime &>/dev/null

	# Setting up system clock
	hwclock --systohc

	# Generating locales
	locale-gen &>/dev/null

	# Installing GRUB
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB &>/dev/null 

	# Create GRUB config file
	grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

EOF

# Setting root password.
info_print "Setting root password."
echo "root:$ROOTPASS" | arch-chroot /mnt chpasswd

# Setting user password and adding the user to the wheel group.
if [[ -n "$USERNAME" ]]; then
	# Enable sudo no password rights.
	echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/wheel
	info_print "Adding the user $USERNAME to the wheel group."
	arch-chroot /mnt useradd -m -G wheel -s /usr/bin/zsh "$USERNAME"
	info_print "Setting user password for $USERNAME."
	echo "$USERNAME:$USERPASS" | arch-chroot /mnt chpasswd
fi

info_print "Installing pacman packages."
for PKG in "${PKGS[@]}"; do
	echo "Installing: ${PKG}"
	arch-chroot /mnt pacman -S "$PKG" --noconfirm --needed
done

info_print "Enabling NetworkManager, reflector and bluetooth."
for service in "${services[@]}"; do
	systemctl enable "$service" --root=/mnt &>/dev/null
done

umount -R /mnt
info_print "Done! You may now reboot the system"
exit
