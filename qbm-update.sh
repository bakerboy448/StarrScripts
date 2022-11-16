#!/bin/bash

qbmPath="/opt/QbitManage"
qbmVenvPath="$qbmPath"/"qbit-venv/"
qbmServiceName="qbmanage"
cd "$qbmPath" || exit
currentVersion=$(cat VERSION)
branch=$(git rev-parse --abbrev-ref HEAD)
git fetch
if [ "$(git rev-parse HEAD)" = "$(git rev-parse @'{u}')" ]; then
    echo "=== Already up to date $currentVersion on $branch ==="
    exit 0
fi
git pull
newVersion=$(cat VERSION)
"$qbmVenvPath"/bin/python -m pip install -r requirements.txt
echo "=== Updated from $currentVersion to $newVersion on $branch ==="
echo "=== Restarting qbm Service ==="
sudo systemctl restart "$qbmServiceName"
exit 0
