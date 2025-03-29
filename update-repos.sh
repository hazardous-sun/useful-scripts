#!/usr/bin/bash

# Pulls the latest changes from all git repositories inside a "Projects" directory that
# the user specify.
# If no directory path is passed, the script will look for git repositories inside the 
# "$HOME/Projects/" directory.

PROJECTS="$HOME/Projects/"
uncommitedDirectories=()
directoriesConflicting=()

printMissingActions() {
    echo "The following directories contain uncommitted changes:"
    for dir in uncommitedDirectories; do
        echo "$PROJECTS/$dir"
    done
    
    echo "The following directories had conflicts when pulling:"
    for dir in directoriesConflicting; do
        echo "$PROJECTS/$dir"
    done
}

pullChanges() {
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then # there are uncommitted changes Append $dir to the list of uncommitted directories 
        $uncommitedDirectories+=$(pwd)
    else # no uncommitted changes
        if [[ $(git pull) != 0 ]]; then
            branch=$(git symbolic-ref --short HEAD)
            echo "error: conflicts found while trying to pull latest changes in '$dir' on branch '$branch'"
            echo "aborting merge..."
            git merge --abort
            $directoriesConflicting+=$(pwd)
        fi
    fi
}

printUsage() {
    echo "update-repos [PATH]"
    echo "Miscelaneous:"
    echo "    -h --help \t Displays the program usage"
}

setProjectsDir() {
    # Check if the user passed a 'Projects' directory
    if [ $# -ne 0 ]; then
        $PROJECTS = "$PROJECTS/$1"
    
        # Check if $PROJECTS directory exists
        if [ -d $PROJECTS ]; then
            echo "Projects directory set to '$PROJECTS'"
        else
            echo "error: directory $PROJECTS does not exist"
            printUsage
            exit 1
        fi
    fi
}

main() {
    # Check if user passed a "Projects" directory
    setProjectsDir

    # CD into Projects directory
    cd $PROJECTS

    # Iterate over directories inside $HOME/Projects/
    for dir in */; do
        echo "cd $PROJECTS$dir"
        # CD into dir
        cd "$PROJECTS$dir"
  
        # Check if $dir is a git directory 
        if [[ $(git rev-parse --is-inside-work-tree) == "true" ]]; then
            echo "Pulling changes"
            pullChanges
        fi
    done

    exit 0
}

main

