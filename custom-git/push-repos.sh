#!/usr/bin/env bash

# Pushes local changes to remote repositories for all git repositories inside a "Projects" directory
# that the user specifies. If no directory path is passed, the script will look for git repositories
# inside the "$HOME/Projects/" directory.

PROJECTS="$HOME/Projects/"
WARNING="\033[33m"
ERROR="\033[31m"
INFO='\033[0;36m'
NC="\033[0m"

printStatus() {
    local uncommitted=("${!1}")
    local unpushed=("${!2}")
    local failed=("${!3}")

    if [ ${#uncommitted[@]} -ne 0 ]; then
        echo -e "${WARNING}🟡 The following directories contain uncommitted changes:${NC}"
        for dir in "${uncommitted[@]}"; do
            echo -e "${WARNING}$dir${NC}"
        done
    fi

    if [ ${#unpushed[@]} -ne 0 ]; then
        echo -e "${WARNING}📤 The following directories have commits not yet pushed:${NC}"
        for dir in "${unpushed[@]}"; do
            echo -e "${WARNING}$dir${NC}"
        done
    fi

    if [ ${#failed[@]} -ne 0 ]; then
        echo -e "${ERROR}❌ error: Failed to push changes in the following directories:${NC}"
        for dir in "${failed[@]}"; do
            echo -e "${ERROR}$dir${NC}"}
        done
    fi
}

pushChanges() {
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        return 1
    fi
    
    # Check if there are commits to push
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -z "$branch" ]; then
        # Not on any branch (detached HEAD)
        return 0
    fi
    
    local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [ -z "$upstream" ]; then
        # No upstream branch set
        return 0
    fi
    
    local local_commit=$(git rev-parse @)
    local remote_commit=$(git rev-parse "$upstream")
    local base_commit=$(git merge-base @ "$upstream")
    
    if [ "$local_commit" = "$remote_commit" ]; then
        # Up to date
        return 0
    elif [ "$local_commit" = "$base_commit" ]; then
        # Need to pull
        return 2
    elif [ "$remote_commit" = "$base_commit" ]; then
        # Need to push
        if ! git push; then
            return 3
        fi
    else
        # Diverged
        return 4
    fi
    
    return 0
}

printUsage() {
    echo "Usage: push-repos [PROJECTS_PATH]"
}

setProjectsDir() {
    # Check if the user passed a 'Projects' directory
    if [ $# -ne 0 ]; then
        PROJECTS="$1"
        
        # Ensure path ends with /
        [[ "$PROJECTS" != */ ]] && PROJECTS="$PROJECTS/"
    
        # Check if $PROJECTS directory exists
        if [ ! -d "$PROJECTS" ]; then
            echo -e "${ERROR}❌ error: directory $PROJECTS does not exist${NC}"
            printUsage
            exit 1
        fi
        echo "${INFO}ℹ️ Projects directory set to '$PROJECTS'${NC}"
    fi
}

main() {
    # Check if user passed a "Projects" directory
    setProjectsDir "$@"

    # CD into Projects directory
    cd "$PROJECTS" || { echo -e "${ERROR}❌ error: Failed to cd to $PROJECTS${NC}"; exit 1; }

    # Variables for tracking status
    uncommittedDirectories=()
    unpushedDirectories=()
    failedPushDirectories=()

    # Iterate over directories inside $PROJECTS
    for dir in */; do
        [ -d "$dir" ] || continue  # Skip if not a directory
        echo -e "${INFO}🧪 Checking $dir${NC}"
        
        # CD into dir
        cd "$dir" || { echo -e "${ERROR}❌ error: Failed to enter $dir${NC}"; continue; }
  
        # Check if $dir is a git directory 
        if git rev-parse --is-inside-work-tree &>/dev/null; then
            pushChanges
            case $? in
                1) uncommittedDirectories+=("$(pwd)") ;;
                2) unpushedDirectories+=("$(pwd)") ;;
                3) failedPushDirectories+=("$(pwd)") ;;
                4) 
                    unpushedDirectories+=("$(pwd)")
                    failedPushDirectories+=("$(pwd)")
                    ;;
            esac
        else
            echo -e "${WARNING}📁 $dir is not a git repository${NC}"
        fi
        
        # Return to Projects directory
        cd ..
    done

    printStatus uncommittedDirectories[@] unpushedDirectories[@] failedPushDirectories[@]
    
    exit 0
}

main "$@"
