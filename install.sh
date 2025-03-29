#!/usr/bin/bash

# Removes the previous version of the script inside /opt/
# Expects 1 parameter, the path to the script that should be removed
removePreviousVersion() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    
    echo "Removing previous version of $script_name..."
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
    echo "Installing $script_name to $dest_dir"
    
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

checkPermissions() {
    if [ "$(id -u)" != "0" ]; then
        echo "Please run the script with sudo"
        exit 1
    fi
}

main() {
    checkPermissions
    
    echo "Updating scripts in /opt"
    
    # Process each directory and file
    find . -type f -name "*.sh" ! -name "install.sh" | while read -r script_path; do
        # Remove leading './' from path
        relative_path="${script_path#./}"
        
        # Get destination directory by removing the script filename
        dest_dir="/opt/useful-scripts/$(dirname "$relative_path")"
        
        installScript "$script_path" "$dest_dir"
    done
    
    echo "Installation complete"
}

main

