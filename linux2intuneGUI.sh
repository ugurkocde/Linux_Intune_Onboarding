#!/bin/bash

# Author: Ugur Koc
# Description: This script is used to install Microsoft Intune and Microsoft Defender for Endpoint on Ubuntu 20.04 and 22.04.
# The script is based on the following Microsoft documentation: https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/linux-install-manually?view=o365-worldwide and https://learn.microsoft.com/en-us/mem/intune/user-help/microsoft-intune-app-linux
# The script is tested on Ubuntu 20.04 and 22.04.
# The script is provided "AS IS" with no warranties.

# Specify the log file path
LOG_FILE="/var/log/linux2intune.log"

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
  echo "$(date): Script not run with root privileges." >> "$LOG_FILE"
  exit
fi

# Start of the script
echo "$(date): Starting the script." >> "$LOG_FILE"

# Verify if Ubuntu version is either 20.04 or 22.04
if [[ "$UBUNTU_VERSION" != "20.04" ]] && [[ "$UBUNTU_VERSION" != "22.04" ]]; then
    echo "Unsupported Ubuntu version. This script supports Ubuntu 20.04 and 22.04 only."
    echo "$(date): Unsupported Ubuntu version - $UBUNTU_VERSION" >> "$LOG_FILE"
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
    echo "$(date): Cleaned up temporary files." >> "$LOG_FILE"
}

function get_sys_info {
    # Open a new terminal window and display system information
    gnome-terminal -- /bin/sh -c 'uname -a; echo; free -h; echo; df -h; echo; lscpu; echo; ip a; exec bash'
}

# Trap to ensure cleanup happens on exit
trap cleanup EXIT

# Set initial value of menu loop variable
MENU_LOOP=true

while $MENU_LOOP; do

# Show menu and get selection
CHOICE=$(zenity --list --title="Linux2Intune " --text "Select an option:" --column "Menu" \
        "Microsoft Intune" \
        "Defender for Endpoint" \
        "Update and Upgrade System" \
        "Show System Information")

# Check if user canceled the dialog box
if [ $? -eq 1 ]; then
    MENU_LOOP=false
    echo "$(date): Exiting the script because the user clicked the cancel button." >> "$LOG_FILE"
    continue
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

# Check if user canceled the dialog box
if [ $? -eq 1 ]; then
    echo "$(date): Exiting the Microsoft Intune submenu because the user clicked the cancel button." >> "$LOG_FILE"
    continue
fi

    # Perform action based on selection
    case $INTUNE_CHOICE in
    "Intune - Onboarding")
        # Check if Microsoft Intune app is already installed
        if is_installed "intune-portal"; then
            echo "Microsoft Intune is already installed. Skipping installation."
            echo "$(date): Microsoft Intune is already installed." >> "$LOG_FILE"
        else
            # Install Microsoft Intune
            echo -e "${RED}Starting installation of Microsoft Intune...${NC}"
            echo "$(date): Starting installation of Microsoft Intune." >> "$LOG_FILE"

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
                echo -e "Microsoft Intune installed successfully."
                echo "$(date): Microsoft Intune installed successfully." >> "$LOG_FILE"
                # Reboot the device
                echo "Installation complete. Starting Application now."
                intune-portal
            else
                echo "Microsoft Intune installation failed."
                echo "$(date): Microsoft Intune installation failed." >> "$LOG_FILE"
            fi
        fi
        ;;



    "Intune - Offboarding")
        # Intune Offboarding
        if is_installed "intune-portal"; then
            echo -e "${RED}Uninstalling Intune app...${NC}"
            echo "$(date): Uninstalling Intune app." >> "$LOG_FILE"
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

            echo -e "Intune app and local registration data have been removed."
            echo "$(date): Intune app and local registration data have been removed." >> "$LOG_FILE"
        else
            echo -e "Intune app is not installed."
            echo "$(date): Intune app is not installed." >> "$LOG_FILE"
        fi
        echo -e "${YELLOW}Going back to the menu ... ${NC}"
        sleep 2
        ;;


    "Intune - Update App")
        # Intune Update
        echo -e "${RED}Checking for Intune app updates...${NC}"
        echo "$(date): Checking for Intune app updates." >> "$LOG_FILE"
        if is_installed "intune-portal"; then
            sudo apt update
            if sudo apt list --upgradable 2>/dev/null | grep -q 'intune-portal'; then
                echo "New version of Intune app is available. Updating..."
                echo "$(date): New version of Intune app is available. Updating." >> "$LOG_FILE"
                sudo apt install intune-portal -y
                echo -e "Intune app has been updated."
                echo "$(date): Intune app has been updated." >> "$LOG_FILE"
            else
                echo -e "Intune app is up-to-date."
                echo "$(date): Intune app is up-to-date." >> "$LOG_FILE"
            fi
        else
            echo -e "Intune app is not installed."
            echo "$(date): Intune app is not installed." >> "$LOG_FILE"
        fi
        echo -e "${YELLOW}Going back to the menu ... ${NC}"
        sleep 2
        ;;



    "Back to Main Menu")
        # Back to main menu
        echo "Exiting menu..."
        echo "$(date): Exiting menu." >> "$LOG_FILE"
        ;;
    esac
    ;;

"Defender for Endpoint")
    # Show Microsoft Intune menu options
INTUNE_CHOICE=$(zenity --list --title="Microsoft Intune" --text "Select an option:" --column "Menu" \
        "MDE - Onboarding" \
        "MDE - Offboarding" \
        "Back to Main Menu")

    # Check if user canceled the dialog box
    if [ $? -eq 1 ]; then
        echo "$(date): Exiting the Microsoft Intune submenu because the user clicked the cancel button." >> "$LOG_FILE"
        continue
    fi

    # Perform action based on selection
    case $INTUNE_CHOICE in
    "MDE - Onboarding")
       
    ONBOARD_FILE=$(zenity --file-selection)
    TAG=$(zenity --entry --text="Enter device tag or leave empty for no tag")
    if [ -z "$TAG" ]
    then
        curl -s https://raw.githubusercontent.com/microsoft/mdatp-xplat/master/linux/installation/mde_installer.sh | sudo bash -s -- --install --channel prod --onboard $ONBOARD_FILE --min_req -y
    else
        curl -s https://raw.githubusercontent.com/microsoft/mdatp-xplat/master/linux/installation/mde_installer.sh | sudo bash -s -- --install --channel prod --onboard $ONBOARD_FILE --tag GROUP $TAG --min_req -y
    fi

        ;;


    "MDE - Offboarding")

        # OFFBOARD_FILE=$(zenity --file-selection)
        curl -s https://raw.githubusercontent.com/microsoft/mdatp-xplat/master/linux/installation/mde_installer.sh | sudo bash -s -- --remove -y

        ;;

    "Back to Main Menu")
        # Back to main menu
        echo "Exiting menu..."
        echo "$(date): Exiting menu." >> "$LOG_FILE"
        ;;
    esac
    ;;


"Update and Upgrade System")
    # Update and upgrade system
    if zenity --question --text="You are about to update and upgrade your system. Do you want to proceed?"; then

    echo -e "${GREEN}Updating package repositories... ${NC}"
    echo "$(date): Updating package repositories." >> "$LOG_FILE"
    sudo apt update
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to update package repositories. Please check your internet connection or package repositories.${NC}"
        echo "$(date): Failed to update package repositories." >> "$LOG_FILE"
        zenity --error --text="Failed to update package repositories. Please check your internet connection or package repositories."
        sleep 2
        continue
    fi
    echo " "
    
    echo -e "${GREEN}Upgrading packages...... ${NC}"
    echo "$(date): Upgrading packages." >> "$LOG_FILE"
    sudo apt upgrade -y
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to upgrade packages. Please check your internet connection or package repositories.${NC}"
        echo "$(date): Failed to upgrade packages." >> "$LOG_FILE"
        zenity --error --text="Failed to upgrade packages. Please check your internet connection or package repositories."
        sleep 2
        continue
    fi
    echo " "
    
    echo -e "${GREEN}System update and upgrade complete. ${NC}"
    echo "$(date): System update and upgrade complete." >> "$LOG_FILE"
    zenity --info --text="System update and upgrade complete."
    sleep 2

    else
        echo -e "${RED}Update and upgrade cancelled by the user.${NC}"
        echo "$(date): Update and upgrade cancelled by the user." >> "$LOG_FILE"
        sleep 2
    fi
    ;;





"Show System Information")
    # Display system information
    echo "$(date): Showing system information." >> "$LOG_FILE"
    get_sys_info
    ;;

esac

done
