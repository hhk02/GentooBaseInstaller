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
fi
fi
echo "Erasing and creating partition: EFI Partition"
mkfs.vfat -F 32 $efi_partition
echo "Erasing and creating partition: Root partition"
mkfs.ext4 $root_partition
clear
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
echo "Detecting CPU Cores for /mnt/gentoo/etc/portage/make.conf"
echo -e 'COMMON_CFLAGS="-march=native -O2 -pipe"\n''CXXFLAGS="${COMMON_FLAGS}"\n''FFLAGS="${COMMON_FLAGS}"\n''LC_MESSAGES=C\n''MAKEOPTS="-j$(nproc)"\n' > /mnt/gentoo/etc/portage/make.conf
echo "Adding pre-build packages repository EXPERIMENTAL! "
echo -e '[binhost]\n''priority = 9999\n''sync-uri = "https://gentoo.osuosl.org/experimental/amd64/binpkg/default/linux/17.1/x86-64/"' > /mnt/gentoo/etc/portage/binrepos.conf
echo 'EMERGE_DEFAULT_OPTS="--binpkg-respect-use=y --getbinpkg=y"' >> /mnt/gentoo/etc/portage/make.conf
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
echo "Copying default repository configuration!"
cp -v /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
echo "Selecting a mirror"
mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
echo "Changing into target.."
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
	
mount $efi_partition /mnt/gentoo/boot
chroot /mnt/gentoo /bin/bash -c 'emerge-webrsync'
echo "Syncing repos!"
chroot /mnt/gentoo /bin/bash -c 'emerge --sync'
chroot /mnt/gentoo /bin/bash -c 'emerge --sync --quiet'
chroot /mnt/gentoo /bin/bash -c 'emerge --ask --verbose --update --deep --newuse @world'
echo "Showing profiles"
chroot /mnt/gentoo /bin/bash -c 'eselect profile list'
echo "Select a profile: "
read selection
if [ -z $selection ]; then
	echo "Selected one by default... Continue... "
else
	chroot /mnt/gentoo /bin/bash -c 'eselect profile set $selection'
fi
echo "Write the timezone: "
read timezone
if [ -z $timezone ]; then
	echo "Selected one by default... Continue... "
else
	echo "Selected: $timezone"
fi
echo "Generating LocalTime"
chroot /mnt/gentoo /bin/bash -c 'ln -sf /usr/share/zoneinfo/$timezone /etc/localtime'
echo "Done!"
nano -w /mnt/gentoo/etc/locale.gen
chroot /mnt/gentoo /bin/bash -c 'locale-gen'
echo "Installing kernel...."
chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/gentoo-kernel-bin'
chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/linux-headers'
chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-fs/genfstab'
chroot /mnt/gentoo /bin/bash -c 'emerge --autounmask=y --autounmask-write sys-kernel/linux-firmware'
chroot /mnt/gentoo /usr/sbin/dispatch-conf
chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/linux-firmware'
chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/genkernel'
echo "Generating fstab file!"
chroot /mnt/gentoo /bin/bash -c 'genfstab -U / > /etc/fstab'
echo "Generating kernel files..."
chroot /mnt/gentoo /bin/bash -c 'genkernel all'
ls /mnt/gentoo/boot/vmlinu* /mnt/gentoo/boot/initramfs*
echo "Cleaning..."
chroot /mnt/gentoo /bin/bash -c 'emerge --depclean'
echo "Write hostname: "
read hostname
if [ -z $hostname ]; then
	echo "Selected one by default... Continue... "
else
	echo "Selected: $(hostname)"
fi
echo $hostname > /mnt/gentoo/etc/hostname
chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot networkmanager nm-applet pulseaudio dhpcd'
chroot /mnt/gentoo /bin/bash -c 'systemctl enable --now NetworkManager'
echo "Creating hosts"
touch /mnt/gentoo/etc/hosts
chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-apps/pcmciautils'
chroot /mnt/gentoo /bin/bash -c 'passwd'
chroot /mnt/gentoo /bin/bash -c 'useradd -m $username'
chroot /mnt/gentoo /bin/bash -c 'passwd $username'
chroot /mnt/gentoo /bin/bash -c 'usermod -aG wheel $username'
chroot /mnt/gentoo /bin/bash -c 'systemd-firstboot --prompt --setup-machine-id'
chroot /mnt/gentoo /bin/bash -c 'systemctl preset-all'
echo "Installing Wireless support"
arch-chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot net-wireless/iw net-wireless/wpa_supplicant'
echo "Installing GRUB"
echo 'GRUB_PLATFORMS="efi-64"' >> /mnt/gentoo/etc/portage/make.conf
chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot --verbose sys-boot/grub'
chroot /mnt/gentoo /bin/bash -c 'emerge --update --newuse --verbose sys-boot/grub'
echo "Installing bootloader!"
chroot /mnt/gentoo /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot'
chroot /mnt/gentoo /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'
echo "Installation complete!"	
}

Welcome
