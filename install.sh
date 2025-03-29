#!/usr/bin/bash

# Removes the previous version of the script inside /opt/
# Expects 1 parameter, the name of the script that should be removed
removePreviousVersion() {
    # CD into /opt/
    echo "Removing previous version of $1..."
    rm "/opt/useful-scripts/$1"
    rm "/usr/bin/$1"
}

# Installs the script
# Expects 1 parameter, the name of the script that should be installed
install() {
    removePreviousVersion $1
    echo "Installing $1"
    
    # Copy file to /opt/useful-scripts/
    cp "$(pwd)/$1" "/opt/useful-scripts/"
    chown "$USER":"$USER" "/opt/useful-scripts/$1"

    # Create a symbolinc reference in /usr/bin/
    ln -s "/opt/useful-scripts/$1" "/usr/bin/"
    chown "$USER":"$USER" "/usr/bin/$1"
    chmod +x "/usr/bin/$1"
}

checkPermissions() {
    if [ "$(id -u)" != "0" ]; then
        echo "Please run the script with sudo"
        exit 1
    fi
}

main() {
    checkPermissions
    
    echo "Updating /opt/useful-scripts"
    rm -r /opt/useful-scripts/ 
    mkdir /opt/useful-scripts

    directories=()
    for file in *; do
        if [[ $file == "install.sh" ]]; then
            continue
        elif [ -f $file ]; then
            install $file
        else 
            $directories+=$file
        fi
    done
}

main
