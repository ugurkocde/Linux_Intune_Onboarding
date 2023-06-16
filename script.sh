#!/bin/bash

# Author: Ugur Koc
# Description: This script is used to install Microsoft Intune and Microsoft Defender for Endpoint on Ubuntu 20.04 and 22.04.
#             The script is based on the following Microsoft documentation: https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/linux-install-manually?view=o365-worldwide and https://learn.microsoft.com/en-us/mem/intune/user-help/microsoft-intune-app-linux
#             The script is tested on Ubuntu 20.04 and 22.04.
#             The script is provided "AS IS" with no warranties.

# Get Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)

# Verify if Ubuntu version is either 20.04 or 22.04
if [[ "$UBUNTU_VERSION" != "20.04" ]] && [[ "$UBUNTU_VERSION" != "22.04" ]]; then
    echo "Unsupported Ubuntu version. This script supports Ubuntu 20.04 and 22.04 only."
    exit 1
fi

# Set initial value of menu loop variable
MENU_LOOP=true

while $MENU_LOOP; do

# Show menu and get selection
CHOICE=$(zenity --list --title="Linux2Intune " --text "Select an option:" --column "Options" --column "Menu" \
        "1" "Microsoft Intune" \
        "2" "Update and Upgrade System" \
        "3" "Display System Information")


# Exit menu if user cancels
if [[ $? -ne 0 ]]; then
  echo "Exiting menu..."
  MENU_LOOP=false
  break
fi

# Perform action based on selection
case $CHOICE in
"1")
    # Show Microsoft Intune menu options
    INTUNE_CHOICE=$(zenity --list --title="Microsoft Intune" --text "Select an option:" --column "Options" --column "Menu" \
        "1" "Intune - Onboarding (Reboot required)" \
        "2" "Intune - Offboarding" \
        "3" "Back to Main Menu")

    # Perform action based on selection
    case $INTUNE_CHOICE in
    "1")
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
            # Reboot the device
            echo "Installation complete. A reboot is required to complete the installation."
            echo "The device will automatically reboot in 5 seconds."
            sleep 5
            sudo reboot
        else
            echo "Microsoft Intune installation failed."
        fi
        ;;

    "2")
        # Intune Offboarding
        echo -e "\e[31mUninstalling Intune app...\e[0m"
        sudo apt remove intune-portal -y
        sudo apt purge intune-portal -y

        # Remove local registration data
        echo "Removing local registration data..."
        sudo rm -rf /var/opt/microsoft/mdm
        sudo rm -rf /etc/opt/microsoft/mdm
        sudo rm -rf /usr/share/intune-portal
        sudo rm -rf /usr/share/doc/intune-portal

        # Remove Microsoft's sources list and signing key
        echo "Removing Microsoft's sources list and signing key..."
        sudo rm /etc/apt/sources.list.d/microsoft-ubuntu-$UBUNTU_CODENAME-prod.list
        sudo rm /usr/share/keyrings/microsoft.gpg

        echo -e "\033[32mIntune app and local registration data have been removed.\033[0m"
        echo -e "\e[33mGoing back to the menu ... \e[0m"
        sleep 5
        ;;

    "3")
        # Back to main menu
        echo "Exiting menu..."
        ;;
    esac
    ;;

"2")
    # Update and upgrade system
    echo -e "\e[32mUpdating package repositories... \e[0m"
    sudo apt update
        echo " "
    echo -e "\e[32mUpgrading packages...... \e[0m"
    sudo apt upgrade -y
        echo " "
    echo -e "\e[32mSystem update and upgrade complete. \e[0m"
    echo -e "\e[33mGoing back to the menu ... \e[0m"
    sleep 2
    ;;
"3")
    # Capture system information in variables
    CPU_INFO=$(cat /proc/cpuinfo | grep -i 'model name\|cpu mhz\|cache size\|smt\|core id')
    MEM_INFO=$(free -h)
    STORAGE_INFO=$(df -h)

    # Show information in Zenity dialog
    zenity --text-info --width=500 --height=400 --title="System Information" --text="Displaying system information...

    CPU information:
    $CPU_INFO

    Memory information:
    $MEM_INFO

    Storage information:
    $STORAGE_INFO"

    ;;
esac

done
