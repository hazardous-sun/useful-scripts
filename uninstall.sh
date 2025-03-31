#!/usr/bin/env bash

# Define color variables
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color (reset)

# Default installation path
defaultInstallPath="/opt/useful-scripts/"

# Check if script is run with sudo
checkPermissions() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}Please run the script with sudo${NC}"
        exit 1
    fi
}

# Get installation directory from user
getInstallPath() {
    echo -e "${CYAN}Where are the scripts installed? Leave blank for default (default='${defaultInstallPath}')${NC}"
    read -r -p "> " userInput

    if [[ "$userInput" != "" ]]; then
        # Ensure path ends with /
        [[ "$userInput" != */ ]] && userInput="$userInput/"
        echo "$userInput"
    else
        echo "$defaultInstallPath"
    fi
}

# List all installed scripts and prompt for removal
uninstallScripts() {
    local installPath="$1"
    
    if [ ! -d "$installPath" ]; then
        echo -e "${RED}Error: Directory '$installPath' does not exist${NC}"
        exit 1
    fi

    # Find all scripts in the installation directory
    local scripts=()
    while IFS= read -r -d $'\0' script; do
        scripts+=("$script")
    done < <(find "$installPath" -type f -name "*.sh" -print0)

    if [ ${#scripts[@]} -eq 0 ]; then
        echo -e "${YELLOW}No scripts found in '$installPath'${NC}"
        exit 0
    fi

    echo -e "${CYAN}Found the following installed scripts:${NC}"
    for i in "${!scripts[@]}"; do
        echo -e "${YELLOW}$((i+1)). ${scripts[$i]}${NC}"
    done

    echo -e "\n${CYAN}Select scripts to uninstall (comma-separated numbers), 'a' for all, or 'q' to quit${NC}"
    read -r -p "> " selection

    case "$selection" in
        [aA])
            removeAllScripts "$installPath" "${scripts[@]}"
            ;;
        [qQ])
            echo -e "${GREEN}Quitting without changes${NC}"
            exit 0
            ;;
        *)
            removeSelectedScripts "$selection" "$installPath" "${scripts[@]}"
            ;;
    esac
}

# Remove all scripts
removeAllScripts() {
    local installPath="$1"
    shift
    local scripts=("$@")
    
    echo -e "${RED}Removing all scripts...${NC}"
    for script in "${scripts[@]}"; do
        removeScript "$script" "$installPath"
    done
    
    # Remove installation directory if empty
    if [ -z "$(ls -A "$installPath")" ]; then
        echo -e "${CYAN}Removing empty directory '$installPath'${NC}"
        rmdir "$installPath"
    fi
    
    echo -e "${GREEN}All scripts have been uninstalled${NC}"
}

# Remove selected scripts
removeSelectedScripts() {
    local selection="$1"
    local installPath="$2"
    shift 2
    local scripts=("$@")
    local IFS=',' read -ra selections <<< "$selection"
    
    for sel in "${selections[@]}"; do
        # Validate input
        if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt "${#scripts[@]}" ]; then
            echo -e "${RED}Invalid selection: '$sel'${NC}"
            continue
        fi
        
        local idx=$((sel-1))
        removeScript "${scripts[$idx]}" "$installPath"
    done
    
    # Remove installation directory if empty
    if [ -z "$(ls -A "$installPath")" ]; then
        echo -e "${CYAN}Removing empty directory '$installPath'${NC}"
        rmdir "$installPath"
    fi
    
    echo -e "${GREEN}Selected scripts have been uninstalled${NC}"
}

# Remove a single script
removeScript() {
    local scriptPath="$1"
    local installPath="$2"
    local scriptName="$(basename "$scriptPath")"
    
    echo -e "${CYAN}Removing $scriptName...${NC}"
    
    # Remove the script file
    rm -f "$scriptPath"
    echo -e "${GREEN}Removed: $scriptPath${NC}"
    
    # Remove the symlink from /usr/bin/
    rm -f "/usr/bin/$scriptName"
    echo -e "${GREEN}Rem
