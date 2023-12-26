#!/bin/bash

echo "-------------------------------------------------"
echo "-----Configuring timezone, clock and locale------"
echo "-------------------------------------------------"

echo "Setting timezone and hardware clock...."
ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "Setting default keymap in an interactive session..."
echo "KEYMAP=croat" >> /etc/vconsole.conf
echo " "

echo "-------------------------------------------------"
echo "----------Setting hostname and hosts-------------"
echo "-------------------------------------------------"
echo " "

read -p "Choose a (creative) hostname: " HOSTNAME
echo $HOSTNAME >> /etc/hostname

echo "Setting hosts file."
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain   $HOSTNAME
EOF

read -p "Root password: " ROOT_PASS
echo "root:$ROOT_PASS" | chpasswd

useradd -m -G wheel mm 
read -p "User password: " USER_PASS
echo mm:$USER_PASS | chpasswd

sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

PGKS=(
	'grub'
	'efibootmgr'
	'networkmanager'
)

for PKG in "${PKGS[@]}"; do
    echo "Installing: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done

