#!/usr/bin/env bash

# This script renames files by adding a prefix to filenames matching a search string.

main() {
    # Check if exactly two arguments are provided
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 <search_string> <prefix>" >&2
        exit 1
    fi
    
    local search_string="$1"
    local prefix="$2"
    
    # Check if the prefix contains invalid filename characters
    if [[ "$prefix" =~ [/\\:\*\?""<>|] ]]; then
        echo "Error: Prefix contains invalid filename characters." >&2
        exit 1
    fi
    
    # Iterate over files (nullglob avoids issues if no files match)
    shopt -s nullglob
    for file in *; do
        # Skip if not a regular file (directories, symlinks, etc.)
        [ ! -f "$file" ] && continue
        
        # Check if filename contains the search string (case-sensitive)
        if [[ "$file" == *"$search_string"* ]]; then
            # Skip if already prefixed
            if [[ "$file" != "${prefix}"* ]]; then
                # Check if target filename already exists
                if [ -e "${prefix}${file}" ]; then
                    echo "Error: '${prefix}${file}' already exists. Skipping '$file'." >&2
                    continue
                fi
                
                # Rename the file
                if mv -- "$file" "${prefix}${file}"; then
                    echo "Renamed '$file' to '${prefix}${file}'"
                else
                    echo "Error: Failed to rename '$file'." >&2
                fi
            else
                echo "Skipping '$file' (already starts with '$prefix')"
            fi
        fi
    done
    shopt -u nullglob  # Reset nullglob
}

main "$@"
