#!/usr/bin/bash

PROJECTS="$HOME/Projects/"
uncommitedDirectories=()
directoriesConflicting=()

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

