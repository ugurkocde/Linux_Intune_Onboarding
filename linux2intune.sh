#!/bin/bash

# Author: Ugur Koc
# Description: This script is used to install Microsoft Intune on Ubuntu 20.04 and 22.04.

# Get Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)

# Verify if Ubuntu version is either 20.04 or 22.04
if [[ "$UBUNTU_VERSION" != "20.04" ]] && [[ "$UBUNTU_VERSION" != "22.04" ]]; then
    echo "Unsupported Ubuntu version. This script supports Ubuntu 20.04 and 22.04 only."
    exit 1
fi

# Check if Microsoft Intune app is already installed
if dpkg -s intune-portal &> /dev/null; then
    echo "\033[33mMicrosoft Intune is already installed. Skipping installation.\033[0m"
else
    # Install Microsoft Intune
    echo "\e[31mStarting installation of Microsoft Intune...\e[0m"

    # Install curl and GPG
    echo "Installing dependencies..."
    sudo apt install curl gpg -y

    # Download and install the Microsoft package signing key
    echo "Adding Microsoft package signing key..."
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/'"$UBUNTU_VERSION"'/prod '$UBUNTU_CODENAME' main" > /etc/apt/sources.list.d/microsoft-ubuntu-'$UBUNTU_CODENAME'-prod.list'
    sudo rm microsoft.gpg

    # Update package repositories
    echo "Updating package repositories..."
    sudo apt update

    # Install the Microsoft Intune app
    echo "Installing Microsoft Intune..."
    sudo apt install intune-portal -y

    # Check if Microsoft Intune app has been installed
    if dpkg -s intune-portal &> /dev/null; then
        echo "\033[32mMicrosoft Intune installed successfully.\033[0m"
        # Start the application
        echo "Installation complete. Starting Application now."
        intune-portal
    else
        echo "Microsoft Intune installation failed."
    fi
fi
