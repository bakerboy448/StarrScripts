#!/bin/bash

# Define variables
REPO_URL="https://github.com/Servarr/Wiki.git"
TARGET_BRANCH="master"
COMMIT_BRANCH="update-wiki-supported-indexers"

# Navigate to the repository's directory
cd ~/_development/servarr.wiki

# Fetch the latest updates from the origin
git fetch origin

# Ensure the TARGET_BRANCH is up to date with origin
git checkout $TARGET_BRANCH
git pull origin $TARGET_BRANCH

# Checkout to the branch containing the commit you want to rebase
git checkout $COMMIT_BRANCH

# Rebase the commit onto the target branch
git rebase origin/$TARGET_BRANCH

# Check if the rebase was successful
if [ $? -eq 0 ]; then
    # Switch back to the target branch
    git checkout $TARGET_BRANCH
    
    # Merge the commit branch into the target branch to bring the rebased commit into target
    # This is assuming the rebase has made commit branch ahead of target and can be fast-forwarded
    git merge --ff-only $COMMIT_BRANCH

    # Now push the updated TARGET_BRANCH to the remote
    if git push origin $TARGET_BRANCH; then
        echo "Rebase, merge, and push to $TARGET_BRANCH completed successfully."
    else
        echo "Push to $TARGET_BRANCH failed. Please check the remote branch status and resolve any issues."
    fi
else
    echo "Rebase encountered conflicts. Resolve them manually and then continue the rebase process."
fi
