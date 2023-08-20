#!/bin/bash
set -e
set -o pipefail

force_update=${1:-false}

# Constants
PIC_PATH="/opt/Plex-Image-Cleanup"
PIC_VENV_PATH="/opt/.venv/pmm-image"
PIC_SERVICE_NAME="pmm-image"
PIC_UPSTREAM_GIT_REMOTE="origin"
PIC_VERSION_FILE="$PIC_PATH/VERSION"
PIC_REQUIREMENTS_FILE="$PIC_PATH/requirements.txt"
CURRENT_UID=$(id -u)

# Check if PIC is installed and if the current user owns it
check_pic_installation() {
    if [ -d "$PIC_PATH" ]; then
        local pic_repo_owner=$(stat -c '%u' "$PIC_PATH")
        if [ "$pic_repo_owner" != "$CURRENT_UID" ]; then
            echo "You do not own the Plex-Image-Cleanup repo. Please run this script as the user that owns the repo [$pic_repo_owner]."
            exit 1
        fi
    else
        echo "Plex-Image-Cleanup folder does not exist. Please install Plex-Image-Cleanup before running this script."
        exit
