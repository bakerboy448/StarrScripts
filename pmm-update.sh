#!/bin/bash

# Get Current User
uid=$(id -u)

# Set Variables
pmmPath="/opt/Plex-Meta-Manager"
pmmVenvName="pmm-venv"
pmmServiceName="pmm"
pmmUpstreamGitRemote="origin"
# Create Paths
pmmVersionFile="$pmmPath/VERSION"
pmmRequirementsFile="$pmmPath/requirements.txt"
pmmVenvPath="$pmmPath"/"$pmmVenvName"
currentVersion=$(cat "$pmmVersionFile")
currentRequirements=$(sha1sum "$pmmRequirementsFile" | awk '{print $1}')

# Check if PMM is installed & Get Repo Owner
# Check if user executing script owns PMM Repo
if [ -d "$pmmPath" ]; then
    pmmRepoOwner=$(stat -c '%u' "$pmmPath")
    if [ "$pmmRepoOwner" != "$uid" ]; then
        echo "Plex Meta Manager folder does exist but you [$uid] do not own the repo. Please run this script as the user that owns the repo [$pmmRepoOwner]"
        exit 1
    fi
else
    echo "Plex Meta Manager folder does not exist. Please install Plex Meta Manager before running this script."
    exit 1
fi

# Get current Branch
branch=$(git -C "$pmmPath" rev-parse --abbrev-ref HEAD)
echo "Current Branch: $branch. Checking for updates..."
git -C "$pmmPath" fetch
if [ "$(git -C "$pmmPath" rev-parse HEAD)" = "$(git -C "$pmmPath" rev-parse @'{u}')" ]; then
    echo "=== Already up to date $currentVersion on $branch ==="
    exit 0
fi
git -C "$pmmPath" reset --hard "$pmmUpstreamGitRemote"/"$branch"
newVersion=$(cat "$pmmVersionFile")
newRequirements=$(sha1sum "$pmmRequirementsFile" | awk '{print $1}')
if [ "$currentRequirements" != "$newRequirements" ]; then
    echo "=== Requirements changed, updating venv ==="
    "$pmmVenvPath"/bin/pip install -r "$pmmRequirementsFile"
fi
echo "=== Restarting PMM Service ==="
sudo systemctl restart "$pmmServiceName"
echo "=== Updated from $currentVersion to $newVersion on $branch"
exit 0
