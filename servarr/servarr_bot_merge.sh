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
git checkout "$COMMIT_BRANCH"

# Rebase the commit onto the target branch
git rebase origin/"$TARGET_BRANCH"

# Check if the rebase was successful
if [ $? -eq 0 ]; then
    # Attempt to push the changes back to the repository
    if git push origin "$COMMIT_BRANCH"; then
        echo "Rebase and push completed successfully."
    else
        echo "Push failed. Please check the remote branch status and resolve any issues."
    fi
else
    echo "Rebase encountered conflicts. Resolve them manually and then continue the rebase process."
fi
