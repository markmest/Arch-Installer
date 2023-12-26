#!/bin/bash

echo "-------------------------------------------------"
echo "-----Configuring timezone, clock and locale------"
echo "-------------------------------------------------"

echo "Setting timezone and hardware clock...."
ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
hwclock --systohc

echo "Generating locale..."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=croat" >> /etc/vconsole.conf

echo "-------------------------------------------------"
echo "----------Setting hostname and hosts-------------"
echo "-------------------------------------------------"
echo " "

read -p "Choose a (creative) hostname: " HOSTNAME
echo $HOSTNAME >> /etc/hostname

echo "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain   $HOSTNAME
EOF

read -p "Root password: " ROOT_PASS
echo "root:$ROOT_PASS" | chpasswd

