#!/usr/bin/bash

# Removes the previous version of the script inside /opt/
# Expects 1 parameter, the name of the script that should be removed
removePreviousVersion() {
    # CD into /opt/
    pushd /opt/useful-scripts
    
    echo "Removing previous version of $1..."
    rm $1
    break

    popd
}

# Installs the script
# Expects 1 parameter, the name of the script that should be installed
install() {
    removePreviousVersion $1
    echo "Installing $1"
    cp "$(pwd)/$1 /opt/useful-scripts"
    chown $USER:$USER "/opt/$1"
    ln -s "/opt/$1" "/usr/bin/"
}

checkPermissions() {
    if [ "$(id -u)" != "0" ]; then
        echo "Please run the script with sudo"
        exit 1
    fi
}

main() {
    checkPermissions

    mkdir /opt/useful-scripts

    directories=()
    for file in *; do
        if $file == "install.sh"; then
            continue
        elif [ -f $file ]; then
            install $file
        else 
            $directories+=$file
        fi
    done
}

main
