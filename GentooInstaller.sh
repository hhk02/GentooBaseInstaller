#!/bin/bash
# EXPERIMENTAL 
# Gentoo Base Installer by hhk02

network_device=""
disk=""
efi_partition=""
root_partition=""
selection="12"
hostname="Gentoo"
timezone="Europe/Madrid"
username=""
password=""

Welcome () {
if [[ $EUID = 0 ]]; then
	echo "Welcome to the Gentoo Installer by hhk02 THIS IT'S A EXPERIMENTAL BUILD SO I'AM NOT RESPONSABLE A DATA LOSE!"
	echo "For start, please specify your network adapter for connect to Internet."
	echo "Testing Internet connection!"
	if ping -c 1 www.google.com &> /dev/null
	then
		echo "Connection Successfull!"
		MakeDisk
	else
	read network_device
	if [ -z  $network_device ]; then
		echo "Invalid device! Try again...."
		read network_device
		net-setup $network_device
		dhcpcd $network_device
	else
		MakeDisk
	fi
	fi
fi
}

MakeDisk () {

echo "Write your disk device ex: /dev/sda"
read disk
if [ -z $disk ]; then
	echo "Write your disk device ex: /dev/sda"
	read disk
else
cfdisk $disk
echo "EFI Partiiton ex /dev/sda1 :"
read efi_partition
if [ -z $efi_partition ]; then
	echo "EFI Partiiton ex /dev/sda1 :"
	read efi_partition
else
	echo "Root partiiton ex /dev/sda2:"
	read root_partition
echo "Erasing and creating partition: EFI Partition"
mkfs.vfat -F 32 $efi_partition
echo "Erasing and creating partition: Root partition"
mkfs.ext4 $root_partition
clear
Install
fi
fi

}

Install () {

echo "Creating /mnt/gentoo!"
mkdir --parents /mnt/gentoo
echo "Mounting root partition!"
mount $root_partition /mnt/gentoo
cd /mnt/gentoo
echo "Installing Gentoo with systemd"
wget http://ftp.rnl.tecnico.ulisboa.pt/pub/gentoo/gentoo-distfiles/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/stage3-amd64-desktop-systemd-20230129T164658Z.tar.xz
echo "Extracting"
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
nano -w /mnt/gentoo/etc/portage/make.conf
mkdir /mnt/gentoo/etc/portage/repos.conf
mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
echo "Changing into target.."
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
mount $efi_partition /mnt/gentoo/boot
chroot "/mnt/gentoo" /usr/bin/emerge --sync
chroot "/mnt/gentoo" /usr/bin/emerge --sync --quiet
echo "Showing profiles"
chroot "/mnt/gentoo" /usr/bin/eselect profile list
echo "Select a profile"
read selection
if [ -z $selection ]; then
	echo "Selected one by default... Continue... "
else
	chroot "/mnt/gentoo" /usr/bin/eselect profile set $selection
fi
chroot "/mnt/gentoo" /usr/bin/emerge --ask --verbose --update --deep --newuse @world

echo "Write the timezone: "
read timezone
if [ -z $timezone ]; then
	echo "Selected one by default... Continue... "
else
	echo "Selected: $timezone"
fi
echo "Generating LocalTime"
chroot "/mnt/gentoo" /bin/ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
nano -w /mnt/gentoo/etc/locale.gen
chroot "/mnt/gentoo" /usr/sbin/locale-gen
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot sys-kernel/gentoo-kernel-bin
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot sys-kernel/linux-headers
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot sys-fs/genfstab
chroot "/mnt/gentoo" /usr/bin/emerge --autounmask=y --autounmask-write sys-kernel/linux-firmware
chroot "/mnt/gentoo" /usr/sbin/dispatch-conf
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot sys-kernel/linux-firmware
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot genkernel
chroot "/mnt/gentoo" /usr/bin/genfstab -U / > /etc/fstab
chroot "/mnt/gentoo" /usr/bin/genkernel all
chroot "/mnt/gentoo" /usr/bin/emerge --depclean

echo "Write hostname: "
read hostname
if [ -z $hostname ]; then
	echo "Selected one by default... Continue... "
else
	echo "Selected: $(hostname)"
echo $hostname > /mnt/gentoo/etc/hostname
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot networkmanager nm-applet pulseaudio dhcpcd 
chroot "/mnt/gentoo" /bin/systemctl enable --now NetworkManager
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot sys-apps/pcmciautils
chroot "/mnt/gentoo" /bin/passwd
useradd -R /mnt/gentoo -m $username
passwd -R /mnt/gentoo $username
usermod -R /mnt/gentoo -aG wheel $username
chroot "/mnt/gentoo" /bin/systemd-firstboot --prompt --setup-machine-id 
chroot "/mnt/gentoo" /bin/systemctl preset-all
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot net-wireless/iw net-wireless/wpa_supplicant
echo 'GRUB_PLATFORMS="efi-64"' >> /mnt/gentoo/etc/portage/make.conf
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot --verbose sys-boot/grub
chroot "/mnt/gentoo" /usr/bin/emerge --update --newuse --verbose sys-boot/grub
chroot "/mnt/gentoo" /usr/sbin/grub-install --target=x86_64-efi --efi-directory=/boot 
chroot "/mnt/gentoo" /usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg
fi
echo "Installation complete!"

}

Welcome
