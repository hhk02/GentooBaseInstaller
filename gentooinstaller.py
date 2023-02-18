import os, sys
import posix

efi_partition = ""
root_partition = ""
disk = ""
mntdir = "/mnt/gentoo"
hostname="Gentoo"
desktop=""

def SetupSystemD():
        os.system("/bin/systemd-firstboot --prompt --setup-machine-id")
        os.system("/bin/systemctl preset-all")
        if (desktop=="KDE"):
                os.system("systemctl enable NetworkManager")
                os.system("systemctl enable sddm")
        else:
             os.system("systemctl enable NetworkManager")
             os.system("systemctl enable gdm")   
        print("Installation complete!")
def InstallKernel():
    os.system("emerge --oneshot genkernel sys-kernel/gentoo-kernel-bin sys-kernel/linux-headers sys-fs/genfstab")
    os.system("emerge --autounmask=y --autounmask-write sys-kernel/linux-firmware")
    os.system("dispatch-conf")
    os.system("/usr/bin/emerge --oneshot sys-kernel/linux-firmware")
    os.system("clear")
    print("Generating fstab")
    os.system("/usr/bin/genfstab -U / > /etc/fstab")
    os.system("echo " + 'GRUB_PLATFORMS="efi-64"' + ">> /mnt/gentoo/etc/portage/make.conf")
    os.system("/usr/bin/emerge --oneshot --verbose sys-boot/grub")
    os.system("/usr/bin/emerge --update --newuse --verbose sys-boot/grub")
    os.system("/usr/sbin/grub-install --target=x86_64-efi --efi-directory=/boot")
    os.system("/usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg")
    SetHostname()



def SetHostname():
        hostname = input("Write your hostname: ")
        print("Changing to " + hostname)
        os.system("echo " + hostname + " > /etc/hostname")
        SetupSystemD()
pass




def TimeZone():
    tz = input("Write your timezone ex: Europe/Madrid")
    if (tz == ""):
            TimeZone()
    else:
            os.system("/bin/ln -sf /usr/share/zoneinfo/"+tz+" /etc/localtime")
            os.system("nano -w /mnt/gentoo/etc/locale.gen")
            os.system("/usr/sbin/locale-gen")
            InstallKernel()
    pass
pass


def SelectDesktop():
    print("Select a desktop: ")
    print("KDE")
    print("GNOME")
    desktop = input("")
    if (desktop == "KDE"):
            os.system("echo USE='plymouth minimal pulseaudio sddm sdk smart systemd thunderbolt wallpapers accessibility browser-integration  bluetooth  colord crash-handler crypt desktop-portal  discover display-manager firewall grub gtk handbook networkmanager' >> /mnt/gentoo/etc/portage/make.conf")
            os.system("/usr/bin/emerge --autounmask=y --autounmask-write plasma-meta")
            os.system("/usr/bin/emerge --sync")
            os.system("/usr/sbin/dispatch-conf")
            os.system("/usr/bin/emerge -v kde-plasma/plasma-meta sddm networkmanager nm-applet")
            print("KDE Plasma insatlled")
            TimeZone()

    elif (desktop == "GNOME"):
            os.system("echo USE="'-qt5 -kde X gtk minimal gnome networkmanager systemd pulseaudio'" >> /mnt/gentoo/etc/portage/make.conf")
            os.system("/usr/bin/emerge --sync")
            os.system("/usr/sbin/dispatch-conf")
            os.system("/usr/bin/emerge -v gnome-base/gnome-light gdm networkmanager nm-applet pulseaudio")
            list.infobox("GNOME installed")
            TimeZone()
    pass




def Install(mountpoint):
    os.system("mount " + root_partition + "" + mountpoint)
    os.chdir(mountpoint)
    os.system("wget http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/stage3-amd64-desktop-systemd-20230129T164658Z.tar.xz")
    os.system("tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner")
    os.system("nano -w /mnt/gentoo/etc/portage/make.conf")
    os.mkdir("/mnt/gentoo/etc/portage/repos.conf")
    os.system("cp -v /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf")
    os.system("cp --dereference /etc/resolv.conf /mnt/gentoo/etc/")
    os.system("mount --types proc /proc /mnt/gentoo/proc")
    os.system("mount --rbind /sys /mnt/gentoo/sys")
    os.system("mount --make-rslave /mnt/gentoo/sys")
    os.system("mount --rbind /dev /mnt/gentoo/dev")
    os.system("mount --make-rslave /mnt/gentoo/dev")
    os.system("mount --bind /run /mnt/gentoo/run")
    os.system("mount --make-slave /mnt/gentoo/run")
    os.chroot(mountpoint)
    os.system("mount " + efi_partition + "" + "/boot")
    os.system("source /etc/profile")
    os.system("export PS1=(chroot) ${PS1}")
    os.system("/usr/bin/emerge-websync")
    print("Syncing repos")
    os.system("/usr/bin/emerge --sync --quiet")
    SelectDesktop()

def FormatDisk(disk):
    efi_partition = input("EFI PARTITION: ")
    if (efi_partition == ""):
            print("Invalid entry")
            FormatDisk(disk=disk)
    else:
            os.system("mkfs.vfat -F 32 " + efi_partition)
            root_partition = input("Root partition: ")
            os.system("mkfs.ext4 " + root_partition)
            Install(mntdir)
    pass

                



def Menu():
   print("Welcome to the Gentoo Installer made by hhk02. For start please specify your device")
   os.system("lsblk")
   disk = input("")
   if (disk==""):
        Menu()
   else:
        FormatDisk(disk=disk)
