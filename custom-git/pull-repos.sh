#!/usr/bin/env bash

# Pulls the latest changes from all git repositories inside a "Projects" directory that
# the user specify.
# If no directory path is passed, the script will look for git repositories inside the 
# "$HOME/Projects/" directory.

PROJECTS="$HOME/Projects/"
WARNING="\033[33m"
ERROR="\033[31m"
INFO='\033[0;36m'
NC="\033[0m"

printMissingActions() {
    local uncommitted=("${!1}")
    local conflicting=("${!2}")

    if [ ${#uncommitted[@]} -ne 0 ]; then
        echo -e "${WARNING}The following directories contain uncommitted changes:${NC}"
        for dir in "${uncommitted[@]}"; do
            echo -e "${WARNING}$dir${NC}"
        done
    fi

    if [ ${#conflicting[@]} -ne 0 ]; then
        echo -e "${ERROR}The following directories had conflicts when pulling:${NC}"
        for dir in "${conflicting[@]}"; do
            echo -e "${ERROR}$dir${NC}"
        done
    fi
}

pullChanges() {
    local dir=$(pwd)
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        return 1
    fi
    
    # Try to pull changes
    if ! git pull --quiet; then
        branch=$(git symbolic-ref --short HEAD)
        echo -e "${ERROR}aborting merge...${NC}"
        git merge --abort
        return 2
    fi
    
    return 0
}

printUsage() {
    echo "Usage: update-repos [PROJECTS_PATH]"
}

setProjectsDir() {
    # Check if the user passed a 'Projects' directory
    if [ $# -ne 0 ]; then
        PROJECTS="$1"
        
        # Ensure path ends with /
        [[ "$PROJECTS" != */ ]] && PROJECTS="$PROJECTS/"
    
        # Check if $PROJECTS directory exists
        if [ ! -d "$PROJECTS" ]; then
            echo -e "${ERROR}error: directory $PROJECTS does not exist${NC}"
            printUsage
            exit 1
        fi
        echo "${INFO}Projects directory set to '$PROJECTS'${NC}"
    fi
}

main() {
    # Check if user passed a "Projects" directory
    setProjectsDir "$@"

    # CD into Projects directory
    cd "$PROJECTS" || { echo -e "${ERROR}error: failed to cd to $PROJECTS${NC}"; exit 1; }

    # Variables for controlling errors
    uncommittedDirectories=()
    directoriesConflicting=()

    # Iterate over directories inside $PROJECTS
    for dir in */; do
        [ -d "$dir" ] || continue  # Skip if not a directory
        echo -e "${INFO}Checking $dir${NC}"
        
        # CD into dir
        cd "$dir" || { echo -e "${ERROR}error: failed to enter $dir${NC}"; continue; }
  
        # Check if $dir is a git directory 
        if git rev-parse --is-inside-work-tree &>/dev/null; then
            pullChanges
            case $? in
                1) uncommittedDirectories+=("$(pwd)") ;;
                2) directoriesConflicting+=("$(pwd)") ;;
            esac
        else
            echo -e "${WARNING}$dir is not a git repository${NC}"
        fi
        
        # Return to Projects directory
        cd ..
    done
    
    echo -e "${INFO}Checking $CONFIG${NC}"    
    # CD into dir
    cd "$CONFIG" || { echo -e "${ERROR}error: failed to enter $CONFIG${NC}"; }
    
    # Check if $dir is a git directory 
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        pullChanges
        case $? in
            1) uncommittedDirectories+=("$(pwd)") ;;
            2) directoriesConflicting+=("$(pwd)") ;;
        esac
    else
        echo -e "${WARNING}$CONFIG is not a git repository${NC}"
    fi

    printMissingActions uncommittedDirectories[@] directoriesConflicting[@]
    
    exit 0
}

main "$@"
