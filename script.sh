#!/bin/bash

# Define menu options
OPTIONS=(1 "Microsoft Intune - Onboarding"
         2 "Update and Upgrade System"
         3 "Display System Information"
         4 "Exit")

# Show menu and get selection
CHOICE=$(whiptail --title "Linux2Intune" --menu "Choose an option:" 12 50 4 "${OPTIONS[@]}" --no-button 3>&1 1>&2 2>&3)

# Perform action based on selection
case $CHOICE in
  1)
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
 2)
    # Onboard Microsoft Defender for Endpoint
    echo "Starting onboarding of Microsoft Defender for Endpoint..."

    # Install curl and libplist-utils
    echo "Installing dependencies..."
    sudo apt-get install curl libplist-utils -y

    # Identify system information
    DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    VERSION=$(lsb_release -rs | cut -f1 -d'.')

    # Download and install the Microsoft repository configuration
    echo "Adding Microsoft repository configuration..."
    curl -o microsoft.list https://packages.microsoft.com/config/$DISTRO/$VERSION/prod.list
    sudo mv ./microsoft.list /etc/apt/sources.list.d/microsoft-prod.list

    # Install the GPG package and the Microsoft GPG public key
    echo "Installing GPG and adding Microsoft GPG public key..."
    sudo apt-get install gpg -y
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

    # Install the HTTPS driver
    echo "Installing HTTPS driver..."
    sudo apt-get install apt-transport-https -y

    # Update the repository metadata
    echo "Updating package repositories..."
    sudo apt-get update

    # Install Microsoft Defender for Endpoint
    echo "Installing Microsoft Defender for Endpoint..."
    sudo apt-get install mdatp -y

    # Verify that the service is running
    echo "Verifying that the service is running..."
    sudo systemctl status mdatp.service

    # Print message to indicate onboarding is complete
    echo "Onboarding of Microsoft Defender for Endpoint is complete. Please verify that the Microsoft Defender for Endpoint service is running."
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
