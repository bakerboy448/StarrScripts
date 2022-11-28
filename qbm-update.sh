#!/bin/bash

force=${1:false}

# Get Current User
uid=$(id -u)

# Set Variables
qbmPath="/opt/QbitManage"
qbmVenvName="qbit-venv"
qbmServiceName="qbmanage"
qbmUpstreamGitRemote="origin"

# Create Paths
qbmVersionFile="$qbmPath/VERSION"
qbmRequirementsFile="$qbmPath/requirements.txt"
qbmVenvPath="$qbmPath"/"$qbmVenvName"
currentVersion=$(cat "$qbmVersionFile")
currentRequirements=$(sha1sum "$qbmRequirementsFile" | awk '{print $1}')

# Check if qbm is installed & Get Repo Owner
# Check if user executing script owns qbm Repo
if [ -d "$qbmPath" ]; then
    qbmRepoOwner=$(stat -c '%u' "$qbmPath")
    if [ "$qbmRepoOwner" != "$uid" ]; then
        echo "QbitManage folder does exist but you [$uid] do not own the repo. Please run this script as the user that owns the repo [$qbmRepoOwner]"
        exit 1
    fi
else
    echo "QbitManage folder does not exist. Please install QbitManage before running this script."
    exit 1
fi

# Get current Branch
branch=$(git -C "$qbmPath" rev-parse --abbrev-ref HEAD)
echo "Current Branch: $branch. Checking for updates..."
git -C "$qbmPath" fetch
echo "force update is:$force"
if [ "$(git -C "$qbmPath" rev-parse HEAD)" = "$(git -C "$qbmPath" rev-parse @'{u}')" ] && [ "$force" = false ]; then
    echo "=== Already up to date $currentVersion on $branch ==="
    exit 0
fi

git -C "$qbmPath" reset --hard "$qbmUpstreamGitRemote"/"$branch"
newVersion=$(cat "$qbmVersionFile")
newRequirements=$(sha1sum "$qbmRequirementsFile" | awk '{print $1}')
if [ "$currentRequirements" != "$newRequirements" ] || [ "$force" = true ]; then
    echo "=== Requirements changed, updating venv ==="
    "$qbmVenvPath"/bin/python3 "$qbmVenvPath"/bin/pip install -r "$qbmRequirementsFile"
fi
echo "=== Restarting qbm Service ==="
sudo systemctl restart "$qbmServiceName"
echo "=== Updated from $currentVersion to $newVersion on $branch"
exit 0
