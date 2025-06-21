#!/usr/bin/env bash

# Define color variables
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color (reset)

# Default installation path
DEFAULT_INSTALL_PATH="/opt/useful-scripts/"

# Check if script is run with sudo
checkPermissions() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}⚠️ Please run the script with sudo${NC}"
        exit 1
    fi
}

# Get installation directory from user
getInstallPath() {
    echo -e "${CYAN}ℹ️ Enter the directory where scripts are installed (leave blank for default '${DEFAULT_INSTALL_PATH}'):${NC}"
    read -r -p "> " userInput

    if [[ -z "$userInput" ]]; then
        INSTALL_PATH="$DEFAULT_INSTALL_PATH"
    else
        # Ensure path ends with /
        [[ "$userInput" != */ ]] && userInput="$userInput/"
        INSTALL_PATH="$userInput"
    fi

    echo -e "${CYAN}ℹ️ Using installation path: ${YELLOW}'${INSTALL_PATH}'${NC}"
    
    if [ ! -d "$INSTALL_PATH" ]; then
        echo -e "${RED}❌ error: Directory '$INSTALL_PATH' does not exist${NC}"
        exit 1
    fi
}

# List installed scripts and get user selection
selectScriptsToRemove() {
    local scripts=()
    local options=()
    local count=1

    echo -e "${CYAN}🔄 Finding installed scripts...${NC}"
    
    # Find all .sh files in installation directory
    while IFS= read -r -d $'\0' script; do
        scripts+=("$script")
        script_name=$(basename "$script")
        options+=("$count" "$script_name" "off")
        ((count++))
    done < <(find "$INSTALL_PATH" -type f -name "*.sh" -print0)

    if [ ${#scripts[@]} -eq 0 ]; then
        echo -e "${YELLOW}ℹ️ No scripts found in '$INSTALL_PATH'${NC}"
        exit 0
    fi

    # Add "All" option
    options+=("$count" "All scripts" "off")

    # Show selection dialog
    echo -e "${CYAN}ℹ️ Select scripts to uninstall:${NC}"
    choices=$(whiptail --title "Script Uninstaller" --checklist \
        "Choose scripts to uninstall:" 20 60 10 \
        "${options[@]}" 3>&1 1>&2 2>&3) || exit

    # Process user choices
    if [[ -z "$choices" ]]; then
        echo -e "${YELLOW}ℹ️ No scripts selected for removal. Exiting.${NC}"
        exit 0
    fi

    # Convert choices to array
    IFS=' ' read -ra selected_indices <<< "$choices"

    # Check if "All" was selected (last option)
    for index in "${selected_indices[@]}"; do
        if [[ "$index" == "\"$count\"" ]]; then
            SELECTED_SCRIPTS=("${scripts[@]}")
            return
        fi
    done

    # Get selected scripts
    for index in "${selected_indices[@]}"; do
        # Remove quotes and convert to zero-based index
        idx=${index//\"}
        idx=$((idx-1))
        SELECTED_SCRIPTS+=("${scripts[$idx]}")
    done
}

# Remove selected scripts
removeScripts() {
    for script in "${SELECTED_SCRIPTS[@]}"; do
        script_name=$(basename "$script")
        symlink_path="/usr/bin/$script_name"

        echo -e "${CYAN}ℹ️ Removing $script_name...${NC}"
        
        # Remove script file
        rm -f "$script"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Removed: $script${NC}"
        else
            echo -e "${RED}❌ error: Failed to remove: $script${NC}"
        fi

        # Remove symlink if exists
        if [[ -L "$symlink_path" ]]; then
            rm -f "$symlink_path"
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}✅ Removed symlink: $symlink_path${NC}"
            else
                echo -e "${RED}❌ error: Failed to remove symlink: $symlink_path${NC}"
            fi
        fi
    done
}

main() {
    checkPermissions
    getInstallPath
    selectScriptsToRemove
    removeScripts
    
    echo -e "${GREEN}✅ Uninstallation complete${NC}"
}

main
