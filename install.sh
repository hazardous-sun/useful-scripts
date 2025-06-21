#!/usr/bin/env bash

# Define color variables
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color (reset)

# Scripts destiny path 
destinyPath="/opt/useful-scripts/"

# Removes the previous version of the script inside /opt/
# Expects 1 parameter, the path to the script that should be removed
removePreviousVersion() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    
    echo -e "${CYAN}ℹ️ Removing previous version of $script_name...${NC}"
    rm -f "$script_path"
    rm -f "/usr/bin/$script_name"
}

# Installs the script
# Expects 2 parameters:
# 1 - source path to the script
# 2 - destination directory path (without script filename)
installScript() {
    local source_path="$1"
    local dest_dir="$2"
    local script_name="$(basename "$source_path")"
    local dest_path="$dest_dir/$script_name"
    
    removePreviousVersion "$dest_path"
    echo -e "${CYAN}ℹ️ Installing $script_name to $dest_dir${NC}"
    
    # Create destination directory if it doesn't exist
    mkdir -p "$dest_dir"
    
    # Copy file to destination
    cp "$source_path" "$dest_dir/"
    chown "$USER":"$USER" "$dest_path"
    chmod +x "$dest_path"

    # Create a symbolic reference in /usr/bin/
    ln -sf "$dest_path" "/usr/bin/"
    chown "$USER":"$USER" "/usr/bin/$script_name"
}

greetings() {
    echo -e "${CYAN}Welcome, $USER!"
    echo -e "This is the installer for some of the bash scripts that I find myself always going back."
    echo -e "You can find more about the project in Github: https://github.com/hazardous-sun/useful-scripts"
    echo -e "First things first, which directory should be used to install the script? Leave blank for default (default='/opt/useful-scripts/')${NC}"
    
    # Read user input
    read -r -p "> " userInput

    if [[ "$userInput" != "" ]]; then
        destinyPath = $userInput
    fi

    echo -e "${CYAN}ℹ️ Installation path set to: ${YELLOW}'${destinyPath}'${NC}"
}

checkPermissions() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}⚠️ Please run the script with sudo${NC}"
        exit 1
    fi
}

main() {
    checkPermissions
    greetings
    echo -e "${CYAN}🔄 Updating scripts in /opt${NC}"
    
    # Process each directory and file
    find . -type f -name "*.sh" ! -name "install.sh" | while read -r script_path; do
        # Remove leading './' from path
        relative_path="${script_path#./}"
        
        # Get destination directory by removing the script filename
        dest_dir="${destinyPath}$(dirname "$relative_path")"
        
        echo -e "${CYAN}ℹ️ Installing ${YELLOW}'$script_path'${NC}"
        installScript "$script_path" "$dest_dir"
    done
    
    echo -e "${GREEN}✅ Installation complete${NC}"
}

main

