#!/bin/bash

# Define variables
REPO_URL="git@github.com:Servarr/Wiki.git"  # URL for the repository
TARGET_BRANCH="master"
COMMIT_BRANCH="update-wiki-supported-indexers"
REPO_DIR="/mnt/raid/_development/servarr.wiki"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check and configure git remote
configure_remote() {
    # Check if the remote is set and set it if not
    if git remote | grep -q "origin"; then
        git remote set-url origin $REPO_URL
    else
        git remote add origin $REPO_URL
    fi
}

# Navigate to the repository's directory
cd $REPO_DIR || { log "Failed to change directory to $REPO_DIR. Exiting."; exit 1; }

# Configure git remote
configure_remote

# Fetch the latest updates from the repository
git fetch --prune origin

# Checkout and update commit branch from origin
git checkout $COMMIT_BRANCH || git checkout -b $COMMIT_BRANCH origin/$TARGET_BRANCH
git pull origin $COMMIT_BRANCH || git pull origin $TARGET_BRANCH

# Rebase the commit onto the target branch
if git rebase origin/$TARGET_BRANCH; then
    log "Rebase successful."

    # Push rebased branch to the same repository
    git push origin $COMMIT_BRANCH -f
    log "Commit Branch $COMMIT_BRANCH"
    log "Target Branch $TARGET_BRANCH"
    # Optionally create a pull request if it's a different branch merging scenario
    if [ "$COMMIT_BRANCH" != "$TARGET_BRANCH" ]; then
        log "Commit and Target Differ. Creating PR"
        gh pr create --base $TARGET_BRANCH --head $COMMIT_BRANCH --title "Update $COMMIT_BRANCH" --body "Rebased updates for $COMMIT_BRANCH"
    else
        log "Updates are on the target branch, no pull request needed."
    fi
else
    log "Rebase encountered conflicts. Resolve them manually and then continue the rebase process."
fi
