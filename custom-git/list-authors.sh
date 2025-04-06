#!/bin/env bash 

# Lists all the authors of a Git repository

ERROR="\033[31m"
INFO='\033[0;36m'
NC="\033[0m"

main() {
    # Check if $dir is a git directory 
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git shortlog --summary --numbered --email
    else 
        echo -e "${ERROR}error: not a Git repository${NC}"
    fi
}

main 
