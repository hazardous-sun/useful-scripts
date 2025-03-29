#!/usr/bin/env bash

# Reconnects a wireless Bluetooth device.

# Colors for error messages
readonly ERROR="\033[31m"
readonly NC="\033[0m"

# Device MAC addresses (configurable)
declare -A DEVICES=(
    # New devices should be added here if neeeded
    ["headset"]="38:5C:76:AC:F6:8B"
)

printUsage() {
    echo "Usage: ${0##*/} [DEVICE]"
    echo "Devices:"
    for device in "${!DEVICES[@]}"; do
        echo -e "  ${device}\t${DEVICES[$device]}"
    done
}

reconnectDevice() {
    local device_mac="$1"
    
    if ! bluetoothctl disconnect "$device_mac"; then
        echo -e "${ERROR}Failed to disconnect $device_mac${NC}" >&2
        return 1
    fi
    
    if ! bluetoothctl connect "$device_mac"; then
        echo -e "${ERROR}Failed to connect $device_mac${NC}" >&2
        return 1
    fi
    
    echo "Successfully reconnected $device_mac"
}

getDeviceMac() {
    local device_name="$1"
    
    if [[ -n "${DEVICES[$device_name]}" ]]; then
        echo "${DEVICES[$device_name]}"
    else
        # Assume the input is already a MAC address
        echo "$device_name"
    fi
}

main() {
    # Check if a device name was passed
    if [[ $# -eq 0 ]]; then
        echo -e "${ERROR}Error: No device specified.${NC}" >&2
        printUsage
        exit 1
    fi
    
    local device_mac
    device_mac=$(getDeviceMac "$1")
    
    if ! reconnectDevice "$device_mac"; then
        exit 1
    fi
}

main "$@"
