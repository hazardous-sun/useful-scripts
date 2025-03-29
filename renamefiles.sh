#!/usr/bin/bash

# Check if exactly two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <search_string> <prefix>"
    exit 1
fi

# Assign arguments to variables
search_string="$1"
prefix="$2"

# Iterate over all files in the current directory
for file in *; do
    # Skip if it's not a regular file
    if [ ! -f "$file" ]; then
        continue
    fi

    # Check if the filename contains the search string (case-sensitive)
    if [[ "$file" == *"$search_string"* ]]; then
        # Check if the filename already starts with the prefix
        if [[ "$file" != "${prefix}"* ]]; then
            # Rename the file by prepending the prefix
            mv "$file" "${prefix}${file}"
            echo "Renamed '$file' to '${prefix}${file}'"
        else
            echo "Skipping '$file' (already starts with '$prefix')"
        fi
    fi
done
