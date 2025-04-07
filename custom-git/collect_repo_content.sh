#!/usr/bin/env bash

# Collects all the content from the current Git repository and stores it
# in a structured output file

# Color definitions
WARNING="\033[33m"
ERROR="\033[31m"
INFO='\033[0;36m'
NC="\033[0m"

# Initialize variables
ignoredFiles=()
output_file="${1:-content}"  # Use first argument or default to "content"

getIgnoredFiles() {    
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo -e "${ERROR}error: Not in a git repository${NC}" >&2
        exit 1
    fi
    
    # Read .gitignore line by line
    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
        # Skip empty lines and comments
        if [[ -z "$pattern" || "$pattern" == \#* ]]; then
            continue
        fi
        
        # Remove leading/trailing whitespace
        pattern="${pattern#"${pattern%%[![:space:]]*}"}"
        pattern="${pattern%"${pattern##*[![:space:]]}"}"
        
        # Skip if empty after trimming
        [[ -z "$pattern" ]] && continue
        
        # Use git to find matching files
        while IFS= read -r -d $'\0' file; do
            ignoredFiles+=("$file")
        done < <(git ls-files -z --ignored --exclude="$pattern")
    done < .gitignore
}

isIgnored() {
    local file="$1"
    
    # Skip hidden directories and files (except .git which is already handled)
    if [[ "$file" == ./* ]] && [[ "$file" =~ /\. ]]; then
        return 0
    fi
    
    for ignored in "${ignoredFiles[@]}"; do
        if [[ "$file" == "$ignored" ]]; then
            return 0
        fi
    done
    return 1
}

processDirectory() {
    local dir="$1"
    local indent="$2"
    local first_file=true
    
    # Log current directory
    echo -e "${INFO}Processing directory ${WARNING}'$dir'${NC}"

    # Open directory bracket
    printf '%s"%s": {\n' "$indent" "$dir" >> "$output_file"
    
    # Process files
    while IFS= read -r -d $'\0' file; do
        if ! isIgnored "${file#./}"; then
            if [ "$first_file" = false ]; then
                printf ',\n' >> "$output_file"
            fi
            first_file=false
            
            # Get file content and escape special characters
            local content=$(sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/$/\\n/' "$file" | tr -d '\n')
            
            # Remove trailing backslash+n if exists
            content="${content%\\n}"
            
            printf '%s  "%s": "%s"' "$indent" "$(basename "$file")" "$content" >> "$output_file"
        fi
    done < <(find "$dir" -maxdepth 1 -type f ! -name ".*" -print0 | sort -z)
    
    # Process subdirectories (excluding hidden dirs except .git)
    while IFS= read -r -d $'\0' subdir; do
        local dirname=$(basename "$subdir")
        if [ "$dirname" != "." ] && [ "$dirname" != ".." ] && [[ "$dirname" != .* || "$dirname" == ".git" ]]; then
            if ! isIgnored "${subdir#./}"; then
                if [ "$first_file" = false ]; then
                    printf ',\n' >> "$output_file"
                fi
                first_file=false
                processDirectory "${subdir#./}" "$indent  "
            fi
        fi
    done < <(find "$dir" -maxdepth 1 -type d ! -name ".*" -print0 | sort -z)
    
    # Close directory bracket
    printf '\n%s}' "$indent" >> "$output_file"
    echo -e "${INFO}Finished processing directory ${WARNING}'$dir'${NC}"
}

main() {
    # Get the ignored files    
    getIgnoredFiles
    
    # Print ignored files for info
    if [ ${#ignoredFiles[@]} -ne 0 ]; then
        echo -e "${WARNING}Ignoring the following files:${NC}"
        printf '%s\n' "${ignoredFiles[@]}"
        echo
    fi
    
    # Initialize output file
    echo -e "${INFO}Creating output file: $output_file${NC}"
    echo "{" > "$output_file"
    
    # Process current directory
    processDirectory "." ""
    
    # Close the root bracket
    echo -e "\n}" >> "$output_file"
    
    echo -e "${INFO}Repository content successfully saved to $output_file${NC}"
}

main "$@"
