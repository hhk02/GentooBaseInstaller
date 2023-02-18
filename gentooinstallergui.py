import os, sys
import posix
import dialog

from dialog import Dialog
efi_partition = ""
root_partition = ""
disk = ""
mntdir = "/mnt/gentoo"
d = Dialog(dialog="Menu")
d.set_background_title("Gentoo Installer by hhk02")

def InstallKernel():
    d.progressbox(file_path="/usr/bin/emerge --oneshot genkernel sys-kernel/gentoo-kernel-bin sys-kernel/linux-headers sys-fs/genfstab",text="Installing kernel")
    d.clear()
    os.system("/usr/bin/emerge --autounmask=y --autounmask-write sys-kernel/linux-firmware")
    os.system("/usr/sbin/dispatch-conf")
    d.progressbox(file_path="/usr/bin/emerge --oneshot sys-kernel/linux-firmware",text="Installing firmware")
    d.clear()
    d.progressbox(file_path="/usr/bin/genfstab -U / > /etc/fstab",text="Generating fstab")





def TimeZone():
    tz = Dialog(dialog="tz")
    if (tz.inputbox(text="Write your timezone ex: Europe/Madrid") == d.OK):
        if (tz == ""):
            TimeZone()
        else:
            tz.progressbox(file_path="/bin/ln -sf /usr/share/zoneinfo/"+tz+" /etc/localtime",text="Apply timezone")
            tz.clear()
            d.infobox(text="Now open the locale.gen and write your keyboard layout... Ex: es_ES.UTF-8 UTF-8")
            os.system("nano -w /mnt/gentoo/etc/locale.gen")
            d.progressbox(file_path="/usr/sbin/locale-gen",text="Generating locales")
            d.clear()
            InstallKernel()
        pass
    pass


def SelectDesktop():
    list = Dialog(dialog="list")
    if (list.inputmenu(text="Select a desktop",choices=({"KDE"},{"GNOME"})) == list.OK):
        if (list == "KDE"):
            os.system("echo USE='plymouth minimal pulseaudio sddm sdk smart systemd thunderbolt wallpapers accessibility browser-integration  bluetooth  colord crash-handler crypt desktop-portal  discover display-manager firewall grub gtk handbook networkmanager' >> /mnt/gentoo/etc/portage/make.conf")
            list.progressbox(file_path="/usr/bin/emerge --autounmask=y --autounmask-write plasma-meta",text="Unmasking Dependencies of KDE Plasma")
            list.progressbox(file_path="/usr/bin/emerge --sync",text="Syncing repositories.")
            list.clear()
            list.progressbox(file_path="/usr/sbin/dispatch-conf",text="Apply changes for unmask Plasma dependences")
            list.clear()
            list.progressbox(file_path="/usr/bin/emerge -v kde-plasma/plasma-meta sddm networkmanager nm-applet",text="Installing KDE Plasma")
            list.infobox("KDE Plasma installed")
            d.clear()
            TimeZone()

        elif (list == "GNOME"):
            os.system("echo USE='-qt5 -kde X gtk minimal gnome networkmanager systemd pulseaudio' >> /mnt/gentoo/etc/portage/make.conf")
            list.progressbox(file_path="/usr/bin/emerge --sync",text="Syncing repositories.")
            list.clear()
            list.progressbox(file_path="/usr/sbin/dispatch-conf",text="Apply changes for unmask GNOME dependences")
            list.clear()
            list.progressbox(file_path="/usr/bin/emerge -v gnome-base/gnome-light gdm networkmanager nm-applet pulseaudio",text="Installing GNOME minimal")
            list.infobox("GNOME installed")
            d.clear()
            TimeZone()
        pass
    pass




def Install(mountpoint):
    os.system("mount " + root_partition + "" + mountpoint)
    os.chdir(mountpoint)
    d.progressbox(text="Downloading Gentoo with SystemD",file_path="/usr/bin/wget http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/stage3-amd64-desktop-systemd-20230129T164658Z.tar.xz")
    d.clear()
    d.progressbox(file_path="/usr/bin/tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner",text="Extracing files to disk")
    d.clear()
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
    d.progressbox(file_path="/usr/bin/emerge-websync",text="Syncing repositories.")
    d.clear()
    d.progressbox(file_path="/usr/bin/emerge --sync",text="Syncing repositories.")
    d.clear()
    d.progressbox(file_path="/usr/bin/emerge --sync --quiet",text="Syncing repositories.")
    d.clear()
    SelectDesktop()

def FormatDisk(disk):
    if(d.inputbox("EFI Partition")) == d.OK:
        if (d == ""):
            d.msgbox("Invalid entry!")
            FormatDisk(disk=disk)
        else:
            d.progressbox("mkfs.vfat -F 32" + d)
            d.clear()
            if(d.inputbox("Root Partition")) == d.OK:
                d.progressbox("mkfs.ext4 " + d)
                d.clear()
                Install(mntdir)
            pass
        pass
    pass


                



def Menu():
    if (d.yesno("Welcome to the Gentoo Installer made by hhk02. Do you want?")) == d.OK:
        d.clear()
        if(d.inputbox("Write your disk ex: /dev/sda") == d.OK):
            if (d == ""):
                d.msgbox("Invalid entry!")
                d.clear()
                Menu()
                
            else:
                FormatDisk(d)
            pass
        pass
    pass



