#!/usr/bin/bash

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
    if $# > 1; then
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
    # CD into Projects directory
    cd $PROJECTS

    # iterate over directories inside $HOME/Projects/
    for dir in */; do
        # CD into dir
        cd "$PROJECTS/$dir"
  
        # check if $dir is a git directory 
        if [[ $(git rev-parse --is-inside-work-tree) == 0 ]]; then
            pullChanges
        fi
    done

    exit 0
}

main

