#!/usr/bin/env bash

# Define variables
REPO_URL="git@github.com:Servarr/Wiki.git" # URL for the repository
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
cd $REPO_DIR || {
    log "Failed to change directory to $REPO_DIR. Exiting."
    exit 1
}

# Configure git remote
configure_remote

# Fetch the latest updates from the repository
log "fetching and purning origin"
git fetch --all --prune

log "checking out and pulling $COMMIT_BRANCH. Also pulling origin/$TARGET_BRANCH"
git checkout -B $TARGET_BRANCH
git checkout -B $COMMIT_BRANCH

git_branch=$(git branch --show-current)
log "git branch is $git_branch"
# Rebase the commit onto the target branch
log "Rebasing....on origin/$TARGET_BRANCH"
if git rebase origin/$TARGET_BRANCH; then
    log "Rebase successful."

    # Switch back to the target branch
    git checkout $TARGET_BRANCH

    # Merge the commit branch into the target branch to bring the rebased commit into target
    # This is assuming the rebase has made commit branch ahead of target and can be fast-forwarded
    log "Merging into $COMMIT_BRANCH with --ff-only"
    LOCAL_HASH=$(git rev-parse "$COMMIT_BRANCH")
    REMOTE_HASH=$(git rev-parse "origin/$COMMIT_BRANCH")

    if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
      git merge --ff-only $COMMIT_BRANCH
    else
      echo "Local branch $COMMIT_BRANCH is the same as origin/$COMMIT_BRANCH. No action needed."
    fi
    # Now push the updated TARGET_BRANCH to the remote
    if [ "$LOCAL_HASH" != "$REMOTE_HASH" ] && git push origin $TARGET_BRANCH; then
        log "Rebase, merge, and push to $TARGET_BRANCH completed successfully."
        # Check if the branch exists on the remote
        if git ls-remote --heads origin | grep -q "refs/heads/$COMMIT_BRANCH"; then
          echo "Branch $COMMIT_BRANCH exists on origin. Deleting..."
          git push origin --delete "$COMMIT_BRANCH"
          echo "Branch $COMMIT_BRANCH deleted from origin."
        else
          echo "Branch $COMMIT_BRANCH does not exist on origin."
        fi
        git branch -d $COMMIT_BRANCH
        log "Deleted Local Branch $COMMIT_BRANCH"
    else
        log "Updates are on the target branch, no pull request needed."
    fi
else
    log "Rebase encountered conflicts. Resolve them manually and then continue the rebase process."
fi
