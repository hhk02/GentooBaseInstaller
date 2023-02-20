#!/bin/bash

DESKTOP=''
USERNAME=''

Main() {
    echo "WELCOME TO THE POST-INSTALLATION FOR GENTOO LINUX BY HHK02 FIRST LET'S CREATE A USER !\n"

    read -p "USERNAME: "

    if [ -z $USERNAME ]; then
        echo "Please write a username!"
        read -p "USERNAME: "
    else
        echo "Creating: " && $USERNAME
        useradd -m $USERNAME
        echo "Please write a password: "
        passwd $USERNAME
    fi

    emerge --sync

    echo "Now let's install a desktop\n"
    echo "Do you want?\n"
    echo "KDE"
    echo "GNOME"
    echo "MATE"

    read -p DESKTOP

    if [ -z $DESKTOP ]; then
        echo "Please specify a desktop!"
        read -p DESKTOP
    else
        echo "Selected :" && $DESKTOP

        if [ $DESKTOP == "KDE" ]; then
            emerge --autounmask=y --autounmask-write plasma-meta
            echo "Please press 'u' in the keyboard for unmask some KDE dependencies!"
            dispatch-conf
            emerge -v plasma-meta sddm networkmanager nm-applet pulseaudio
            systemctl enable sddm
            systemctl enable NetworkManager
            systemctl --user enable pulseaudio
            echo "Done!"
        elif [ $DESKTOP == "GNOME" ]; then
            emerge -v gnome-light gdm networkmanager nm-applet pulseaudio
            systemctl enable gdm
            systemctl enable NetworkManager
            systemctl --user enable pulseaudio
            echo "Done!"
        else
            emerge -v mate lightdm networkmanager nm-applet pulseaudio
            systemctl enable lightdm
            systemctl enable NetworkManager
            systemctl --user enable pulseaudio
            echo "Done!"
        fi
    fi
}

if [ $EUID -eq 0 ]; then
    Menu
else
    echo "Make sure you root for run this!"
fi