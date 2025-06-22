#!/usr/bin/env bash 

# Checks if there are uncommitted changes in the repositories inside a "$PROJECTS" directory, 
# or the path that the user specify. 

WARNING="\033[33m"
ERROR="\033[31m"
NOT_PUSHED="\033[38;5;190m"
INFO='\033[0;36m'
NC="\033[0m"

printMissingActions() {
    local uncommitted=("${!1}")
    local noUpstream=("${!2}")
    local notPushed=("${!3}")
    
    local COUNT=1
    if [ ${#uncommitted[@]} -ne 0 ]; then 
        echo -e "${WARNING}🟡 The following directories contain uncommitted changes:${NC}" 
        for dir in "${uncommitted[@]}"; do
            echo -e "${WARNING}$COUNT. $dir${NC}"
            ((COUNT++))
        done
    fi
    
    COUNT=1
    if [ ${#noUpstream[@]} -ne 0 ]; then
        echo -e "${ERROR}🚫 The following directories do not have an upstream branch set:${NC}"
        for dir in "${noUpstream[@]}"; do
            echo -e "${ERROR}$COUNT. $dir${NC}"
            
            # Get current branch name
            branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
            
            # Check if a remote branch with the same name exists
            if git -C "$dir" show-ref --quiet "refs/remotes/origin/$branch"; then
                echo -e "${WARNING}$COUNT.1 ⚠️ Remote branch 'origin/$branch' exists. To link it, run:${NC}"
                echo -e "${WARNING}\tgit -C \"$dir\" branch --set-upstream-to=origin/$branch $branch${NC}"
            else
                echo -e "${ERROR}    $COUNT.1 ❌ No matching remote branch found for '$branch'.${NC}"
            fi
            ((COUNT++))
        done
    fi

    COUNT=1
    if [ ${#notPushed[@]} -ne 0 ]; then
        echo -e "${NOT_PUSHED}📤 The following directories contain changes that were commited but not yet pushed:${NC}"
        for dir in "${notPushed[@]}"; do
            echo -e "${NOT_PUSHED}$COUNT. $dir${NC}"
            ((COUNT++))
        done
    fi
}

pullChanges() {
    local dir=$(pwd)
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        return 1
    fi

    # Check if upstream is set
    if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
        return 2 
    fi

    # Check for changes commited but not yet pushed
    if [ -n "$(git cherry -v)" ]; then
        return 3
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
            echo -e "${ERROR}❌ error: directory $PROJECTS does not exist${NC}"
            printUsage
            exit 1
        fi
        echo -e "${INFO}✅ Projects directory set to '$PROJECTS'${NC}"
    fi
}

main() {
    # Check if user passed a "Projects" directory
    setProjectsDir "$@"

    # CD into Projects directory
    cd "$PROJECTS" || { echo -e "${ERROR}❌ error: failed to cd to $PROJECTS${NC}"; exit 1; }

    # Variables for controlling errors
    uncommittedDirectories=()
    noUpstreamRepos=()
    directoriesConflicting=()

    # Iterate over directories inside $PROJECTS
    for dir in */; do
        [ -d "$dir" ] || continue  # Skip if not a directory
        echo -e "${INFO}🔍 Checking $dir${NC}"
        
        # CD into dir
        cd "$dir" || { echo -e "${ERROR}❌ error: failed to enter $dir${NC}"; continue; }
  
        # Check if $dir is a git directory 
        if git rev-parse --is-inside-work-tree &>/dev/null; then
            pullChanges
            case $? in
                1) uncommittedDirectories+=("$(pwd)") ;;
                2) noUpstreamRepos+=("$(pwd)") ;;
                3) directoriesConflicting+=("$(pwd)") ;;
            esac
        else
            echo -e "${WARNING}📁 $dir is not a git repository${NC}"
        fi
        
        # Return to Projects directory
        cd ..
    done

    # After processing all $PROJECTS subdirectories, check the $CONFIG directory
    if [ -d "$CONFIG" ]; then
        echo -e "${INFO}🔍 Checking $CONFIG${NC}"
        cd "$CONFIG" || exit
    
        if [[ -d .git ]]; then
            # Check for uncommitted changes
            if [[ -n $(git status --porcelain) ]]; then
                uncommitted+=("$CONFIG")
            fi
            
            # Check for commits not pushed
            if [[ -n $(git log --branches --not --remotes) ]]; then
                notPushed+=("$CONFIG")
            fi
        fi
    fi

    printMissingActions uncommittedDirectories[@] noUpstreamRepos[@] directoriesConflicting[@]
    
    exit 0
}

main "$@"
