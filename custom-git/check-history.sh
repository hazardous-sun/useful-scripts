#!/usr/bin/env bash

# Checks the last commit date and top 10 most active commit days in the current directory.

INFO="\033[0;36m"
ERROR="\033[31m"
NC="\033[0m"

main() {
    # Check if the current directory is a Git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo -e "${ERROR}Error: Current directory is not a Git repository.${NC}"
        exit 1
    fi

    echo -e "${INFO}Analyzing repository: $(basename "$(pwd)")${NC}"

    # Last commit date in DD-MM-YYYY format
    last_commit_date=$(git log -1 --format=%cd --date=format:'%d-%m-%Y')
    echo "Last commit date: $last_commit_date"

    # Top 10 most active commit days with dates in DD-MM-YYYY format
    echo -e "\nTop 10 most active commit days:"
    git log --date=short --pretty=format:'%ad' \
        | sort \
        | uniq -c \
        | sort -nr \
        | head -10 \
        | while read -r count date; do
            # Format the date to DD-MM-YYYY
            formatted_date=$(date -d "$date" '+%d-%m-%Y')
            echo "  $count commits on $formatted_date"
        done
}

main "$@"

