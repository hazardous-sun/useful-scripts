#!/usr/bin/bash

RED="\033[0;31m"
NC="\033[0m"

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# This script may be dangerous.
# It messes with SHA1 git objects. Execute it with caution.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# This script sets all commits e-mails and users to the ones set under your local "git config user.email" and "git config user.name" values. 

main() {
    # Warn the user of what the chaos this script may generate
    echo -ne "${RED}Are you SURE you want to change the commit e-mails from this repository? It will probably create a conflicts hell that you'll have to manually fix, not to mention that the only way to rollback will be recloning the project...${NC}"
    
    # Read user input
    read -r user_input

    # Convert the input to lower case
    choice=$(echo "$user_input" | '[:upper:]' '[:lower:]')

    # Check if the user agreed to run the script 
    if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
        echo "Starting the rebase..."
        git rebase -r --root --exec "git commit --amend --no-edit --reset-author"
        echo "Finished rebasing"
    fi
}
