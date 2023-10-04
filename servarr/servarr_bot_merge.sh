#!/bin/bash

# Define variables
REPO_URL="https://github.com/Servarr/Wiki.git"
TARGET_BRANCH="master"
COMMIT_BRANCH="update-wiki-supported-indexers"

# Clone the repository
git clone "$REPO_URL"
cd Wiki

# Fetch latest updates
git fetch origin

# Checkout to the branch containing the commit you want to rebase
git checkout "$COMMIT_BRANCH"

# Rebase the commit onto the target branch
git rebase "$TARGET_BRANCH"

# Check if the rebase was successful
if [ $? -eq 0 ]; then
    # Push the changes back to the repository
    git push origin "$COMMIT_BRANCH"
    echo "Rebase and push completed."
else
    echo "Rebase encountered conflicts. Resolve them manually and then continue the rebase process."
fi
