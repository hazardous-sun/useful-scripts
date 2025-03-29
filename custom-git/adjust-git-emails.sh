#!/usr/bin/env bash

RED="\033[0;31m"
NC="\033[0m"

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# WARNING: This script may be dangerous!
# It rewrites Git history, changing commit authors/emails.
# Conflicts may occur, and the only rollback may be recloning.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

main() {
    # Warn the user about potential risks
    echo -e "${RED}WARNING: This will rewrite Git history, changing ALL commit authors/emails.${NC}"
    echo -e "${RED}This may cause conflicts, and the only way to undo it may be to reclone the repo.${NC}"
    echo -e "${RED}Are you ABSOLUTELY sure you want to proceed? (y/N)${NC}"

    # Read user input (case-insensitive)
    read -r -p "> " user_input
    choice=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

    # Only proceed on explicit "y" or "yes" (case-insensitive)
    if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
        echo "Starting rebase to reset authors..."
        git rebase -r --root --exec "git commit --amend --no-edit --reset-author" || {
            echo -e "${RED}Rebase failed! Check Git status and resolve conflicts.${NC}" >&2
            exit 1
        }
        echo "Successfully updated all commits."
    else
        echo "Aborted. No changes were made."
    fi
}

main
