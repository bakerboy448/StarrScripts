#!/bin/bash

pmmPath="/opt/Plex-Meta-Manager"
pmmVenvPath="$pmmPath"/"pmm-venv"
pmmServiceName="pmm"
cd "$pmmPath" || exit
currentVersion=$(cat VERSION)
branch=$(git rev-parse --abbrev-ref HEAD)
git fetch
if [ "$(git rev-parse HEAD)" = "$(git rev-parse @'{u}')" ]; then
    echo "=== Already up to date $currentVersion on $branch ==="
    exit 0
fi
git reset --hard origin/"$branch"
newVersion=$(cat VERSION)
"$pmmVenvPath"/bin/python -m pip install -r requirements.txt
echo "=== Restarting PMM Service ==="
sudo systemctl restart "$pmmServiceName"
echo "=== Updated from $currentVersion to $newVersion on $branch"
exit 0
