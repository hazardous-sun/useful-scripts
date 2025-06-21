#!/usr/bin/env bash

# Collects all the content from the current Git repository and stores it
# in a structured output file

# Color definitions
WARNING="\033[33m"
ERROR="\033[31m"
INFO='\033[0;36m'
NC="\033[0m"

# Initialize variables
declare -A processed_dirs  # Track processed directories to avoid duplicates
ignoredFiles=()
manuallyIgnoredFiles=()     # full path ignores from CLI and defaults
ignoreAllFiles=()           # ignore by filename regardless of path
output_file="content.json"

parse_args() {
    # Default output file
    if [[ "$1" && "$1" != --* ]]; then
        output_file="$1"
        shift
    fi

    # Parse remaining flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ignore)
                if [[ -n "$2" ]]; then
                    manuallyIgnoredFiles+=("$2")
                    shift 2
                else
                    echo -e "${ERROR}❌ error: --ignore requires a filename argument${NC}" >&2
                    exit 1
                fi
                ;;
            --ignore-all)
                if [[ -n "$2" ]]; then
                    ignoreAllFiles+=("$2")
                    shift 2
                else
                    echo -e "${ERROR}❌ error: --ignore-all requires a filename argument${NC}" >&2
                    exit 1
                fi
                ;;
            *)
                echo -e "${ERROR}❌ error: unknown argument: $1${NC}" >&2
                exit 1
                ;;
        esac
    done
}

getIgnoredFiles() {
    # Check if inside a Git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo -e "${ERROR}❌ error: not in a git repository${NC}" >&2
        exit 1
    fi

    # Parse .gitignore and collect ignored files
    if [[ -f .gitignore ]]; then
        while IFS= read -r pattern || [[ -n "$pattern" ]]; do
            if [[ -z "$pattern" || "$pattern" == \#* ]]; then
                continue
            fi

            # Trim whitespace
            pattern="${pattern#"${pattern%%[![:space:]]*}"}"
            pattern="${pattern%"${pattern##*[![:space:]]}"}"

            [[ -z "$pattern" ]] && continue

            while IFS= read -r -d $'\0' file; do
                ignoredFiles+=("$file")
            done < <(git ls-files -z --ignored --exclude="$pattern")
        done < .gitignore
    fi

    # Add manually ignored files (make sure path format matches)
    for manual_file in "${manuallyIgnoredFiles[@]}"; do
        # Prepend "./" if missing for consistency with find/git ls-files output
        if [[ "$manual_file" != ./* ]]; then
            ignoredFiles+=("./$manual_file")
        else
            ignoredFiles+=("$manual_file")
        fi
    done
}

isIgnored() {
    local file="$1"

    # Skip hidden files/directories (except .git)
    if [[ "$file" =~ ^\./\. ]] && [[ "$file" != "./.git/"* ]]; then
        return 0
    fi

    # Check if basename is in ignoreAllFiles
    local basefile
    basefile=$(basename "$file")
    for name in "${ignoreAllFiles[@]}"; do
        if [[ "$basefile" == "$name" ]]; then
            return 0
        fi
    done

    # Check full path ignores
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

    echo -e "${INFO}🔄 Processing ${WARNING}'$dir'${INFO}...${NC}"

    # Skip if we've already processed this directory
    if [[ -n "${processed_dirs[$dir]}" ]]; then
        return
    fi
    processed_dirs["$dir"]=1

    # Open JSON object
    printf '%s"%s": {\n' "$indent" "${dir#./}" >> "$output_file"

    # Process files
    while IFS= read -r -d $'\0' file; do
        if ! isIgnored "$file"; then
            if [ "$first_file" = false ]; then
                printf ',\n' >> "$output_file"
            fi
            first_file=false

            local content
            content=$(sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/$/\\n/' "$file" | tr -d '\n')
            content="${content%\\n}"

            printf '%s  "%s": "%s"' "$indent" "$(basename "$file")" "$content" >> "$output_file"
        fi
    done < <(find "$dir" -maxdepth 1 -type f ! -name ".*" -print0 | sort -z)

    # Process subdirectories
    while IFS= read -r -d $'\0' subdir; do
        local dirname
        dirname=$(basename "$subdir")
        if [ "$dirname" != "." ] && [ "$dirname" != ".." ] && [[ "$dirname" != .* || "$dirname" == ".git" ]]; then
            if ! isIgnored "$subdir/"; then
                if [ "$first_file" = false ]; then
                    printf ',\n' >> "$output_file"
                fi
                first_file=false
                processDirectory "$subdir" "$indent  "
            fi
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -print0 | sort -z)

    # Close JSON object
    printf '\n%s}' "$indent" >> "$output_file"
}

main() {
    parse_args "$@"

    # Always ignore the output file itself
    manuallyIgnoredFiles+=("$output_file")

    getIgnoredFiles

    if [ ${#ignoredFiles[@]} -ne 0 ] || [ ${#ignoreAllFiles[@]} -ne 0 ]; then
        echo -e "${WARNING}⚠️ Ignoring the following files:${NC}"
        if [ ${#ignoredFiles[@]} -ne 0 ]; then
            printf '%s\n' "${ignoredFiles[@]}"
        fi
        if [ ${#ignoreAllFiles[@]} -ne 0 ]; then
            echo "By filename (ignore-all):"
            printf '%s\n' "${ignoreAllFiles[@]}"
        fi
        echo
    fi

    echo -e "${INFO}ℹ️ Creating output file: $output_file${NC}"
    echo "{" > "$output_file"

    processDirectory "." ""

    echo -e "\n}" >> "$output_file"

    echo -e "${INFO}✅ Repository content successfully saved to $output_file${NC}"
}

main "$@"
