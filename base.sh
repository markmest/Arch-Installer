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
lsblk


