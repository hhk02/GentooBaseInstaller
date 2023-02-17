#!/bin/bash
# EXPERIMENTAL 
# Gentoo Base Installer by hhk02

SUDOER="yes"
disk=""
efi_partition=""
root_partition=""
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
mkdir /mnt/gentoo/boot
mount $efi_partition /mnt/gentoo/boot
mount $root_partition /mnt/gentoo
cd /mnt/gentoo
echo "Installing dependencies for install."
git clone https://github.com/plougher/squashfs-tools.git
cd squashfs-tools/squashfs-tools/
sed -i 's/#XZ_SUPPORT = 1/XZ_SUPPORT = 1/' Makefile
make
make install
clear
echo "Installing Gentoo"
echo "Extracting"
unsquashfs -f -d /mnt/gentoo /mnt/cdrom/image.squashfs 
nano -w /mnt/gentoo/etc/portage/make.conf
echo "Adding pre-build packages repository EXPERIMENTAL! "
echo -e '[binhost]\n''priority = 9999\n''sync-uri = https://gentoo.osuosl.org/experimental/amd64/binpkg/default/linux/17.1/x86-64/' > /mnt/gentoo/etc/portage/binrepos.conf
echo 'EMERGE_DEFAULT_OPTS="--binpkg-respect-use=y --getbinpkg=y"' >> /mnt/gentoo/etc/portage/make.conf
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
echo "Copying default repository configuration!"
cp -v /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
echo "Changing into target.."
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

chroot "/mnt/gentoo" /usr/bin/emerge-webrsync
chroot "/mnt/gentoo" /usr/bin/emerge --sync
chroot "/mnt/gentoo" /usr/bin/emerge --sync --quiet
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
echo "Write your username"
read username
echo "Is sudoer (yes/no)"
read SUDOER
if [ -z $SUDOER ]; then
	useradd -R /mnt/gentoo -m $username
	passwd -R /mnt/gentoo $username
	usermod -R /mnt/gentoo -aG wheel $username
	usermod -R /mnt/gentoo -aG sudo $username
elif [ $SUDOER -eq "yes" ]; then
	useradd -R /mnt/gentoo -m $username
	passwd -R /mnt/gentoo $username
	usermod -R /mnt/gentoo -aG wheel $username
	usermod -R /mnt/gentoo -aG sudo $username
else
	useradd -R /mnt/gentoo -m $username
	passwd -R /mnt/gentoo $username
fi
clear
echo "Installing bootloader!"
echo 'GRUB_PLATFORMS="efi-64"' >> /mnt/gentoo/etc/portage/make.conf
chroot "/mnt/gentoo" /usr/bin/emerge --oneshot --verbose sys-boot/grub
chroot "/mnt/gentoo" /usr/bin/emerge --update --newuse --verbose sys-boot/grub
chroot "/mnt/gentoo" /usr/sbin/grub-install --target=x86_64-efi --efi-directory=/boot 
chroot "/mnt/gentoo" /usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg
fi
echo "Installation complete!"

}

Welcome
