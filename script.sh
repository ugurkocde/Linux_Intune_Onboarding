#!/bin/bash

# Define menu options
OPTIONS=(1 "Change Devicename"
         2 "Install Microsoft Intune"
         3 "Update and Upgrade System"
         4 "Display System Information"
         5 "Exit")

# Show menu and get selection
CHOICE=$(whiptail --title "Linux2Intune Onboarding" --menu "Select an option:" 12 50 5 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

# Perform action based on selection
case $CHOICE in
  1)
    # Change device name
    echo "Enter a new device name:"
    read NEWNAME
    sudo hostnamectl set-hostname $NEWNAME
    echo "Device name changed to $NEWNAME."
    ;;
  2)
    # Install Microsoft Intune
    echo "Starting installation of Microsoft Intune..."

    # Install curl and GPG
    echo "Installing dependencies..."
    sudo apt install curl gpg -y

    # Download and install the Microsoft package signing key
    echo "Adding Microsoft package signing key..."
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/microsoft-ubuntu-jammy-prod.list'
    sudo rm microsoft.gpg

    # Update package repositories
    echo "Updating package repositories..."
    sudo apt update

    # Install the Microsoft Intune app
    echo "Installing Microsoft Intune..."
    sudo apt install intune-portal -y

    # Reboot the device
    echo "Installation complete. A reboot is required to complete the installation."
    echo "The device will automatically reboot in 5 seconds."
    sleep 5
    sudo reboot
    ;;
  3)
    # Update and upgrade system
    echo "Updating package repositories..."
    sudo apt update
    echo "Upgrading packages..."
    sudo apt upgrade -y
    echo "System update and upgrade complete."
    ;;
  4)
    # Display system information
    echo "Displaying system information..."
    echo "CPU information:"
    cat /proc/cpuinfo | grep -i 'model name\|cpu mhz\|cache size\|smt\|core id'
    echo "Memory information:"
    free -h
    echo "Storage information:"
    df -h
    ;;
  5)
    # Exit menu
    echo "Exiting menu..."
    ;;
esac
