#!/bin/bash

# Author: Ugur Koc
# Description: This script is used to install Microsoft Intune and Microsoft Defender for Endpoint on Ubuntu 20.04 and 22.04.
# The script is based on the following Microsoft documentation: https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/linux-install-manually?view=o365-worldwide and https://learn.microsoft.com/en-us/mem/intune/user-help/microsoft-intune-app-linux
# The script is tested on Ubuntu 20.04 and 22.04.
# The script is provided "AS IS" with no warranties.

# Get Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)

# Terminal Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
NC='\e[0m' 

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


# Verify if Ubuntu version is either 20.04 or 22.04
if [[ "$UBUNTU_VERSION" != "20.04" ]] && [[ "$UBUNTU_VERSION" != "22.04" ]]; then
    echo "Unsupported Ubuntu version. This script supports Ubuntu 20.04 and 22.04 only."
    exit 1
fi

# Function to check if Microsoft Intune app is installed
function is_installed {
    dpkg -s $1 &> /dev/null
    return $?
}

# Function to cleanup temporary files
function cleanup {
    echo "Cleaning up temporary files..."
    rm -f microsoft.gpg
}

# Trap to ensure cleanup happens on exit
trap cleanup EXIT

# Set initial value of menu loop variable
MENU_LOOP=true

while $MENU_LOOP; do

# Show menu and get selection
CHOICE=$(zenity --list --title="Linux2Intune " --text "Select an option:" --column "Menu" \
        "Microsoft Intune" \
        "Update and Upgrade System" )


# Exit menu if user cancels
if [[ $? -ne 0 ]]; then
  echo "Exiting menu..."
  MENU_LOOP=false
  break
fi

# Perform action based on selection
case $CHOICE in
"Microsoft Intune")
    # Show Microsoft Intune menu options
    INTUNE_CHOICE=$(zenity --list --title="Microsoft Intune" --text "Select an option:" --column "Menu" \
        "Intune - Onboarding" \
        "Intune - Offboarding" \
        "Intune - Update App" \
        "Back to Main Menu")

    # Perform action based on selection
    case $INTUNE_CHOICE in
    "Intune - Onboarding")
        # Check if Microsoft Intune app is already installed
        if is_installed "intune-portal"; then
            echo "Microsoft Intune is already installed. Skipping installation."
        else
            # Install Microsoft Intune
            echo "${RED}Starting installation of Microsoft Intune...${NC}"

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
                echo "${YELLOW}Microsoft Intune installed successfully.${NC}"
                # Reboot the device
                echo "Installation complete. Starting Application now."
                intune-portal
            else
                echo "Microsoft Intune installation failed."
            fi
        fi
        ;;



    "Intune - Offboarding")
        # Intune Offboarding
        if is_installed "intune-portal"; then
            echo -e "${RED}Uninstalling Intune app...${NC}"
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

            echo -e "${YELLOW}Intune app and local registration data have been removed.${NC}"
        else
            echo "Intune app is not installed."
        fi
        echo -e "${YELLOW}Going back to the menu ... ${NC}"
        sleep 5
        ;;


    "Intune - Update App")
        # Intune Update
        echo -e "${RED}Checking for Intune app updates...${NC}"
        if is_installed "intune-portal"; then
            sudo apt update
            if sudo apt list --upgradable 2>/dev/null | grep -q 'intune-portal'; then
                echo "New version of Intune app is available. Updating..."
                sudo apt install intune-portal -y
                echo -e "${GREEN}Intune app has been updated.${NC}"
            else
                echo "${GREEN}Intune app is up-to-date. ${NC}"
            fi
        else
            echo "${YELLOW}Intune app is not installed.${NC}"
        fi
        echo -e "${YELLOW}Going back to the menu ... ${NC}"
        sleep 2
        ;;



    "Back to Main Menu")
        # Back to main menu
        echo "Exiting menu..."
        ;;
    esac
    ;;

"Update and Upgrade System")
    # Update and upgrade system
    echo -e "${GREEN}Updating package repositories... ${NC}"
    sudo apt update
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to update package repositories. Please check your internet connection or package repositories.${NC}"
        echo -e "${YELLOW}Returning to the menu...${NC}"
        sleep 2
        continue
    fi
    echo " "
    
    echo -e "${GREEN}Upgrading packages...... ${NC}"
    sudo apt upgrade -y
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to upgrade packages. Please check your internet connection or package repositories.${NC}"
        echo -e "${YELLOW}Returning to the menu...${NC}"
        sleep 2
        continue
    fi
    echo " "
    
    echo -e "${GREEN}System update and upgrade complete. ${NC}"
    echo -e "${YELLOW}Going back to the menu ... ${NC}"
    sleep 2
    ;;


esac

done
