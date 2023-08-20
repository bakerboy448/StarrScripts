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

# Check if Plex-Image-Cleanup is installed and the current user owns it
check_pic_installation() {
    if [ -d "$PIC_PATH" ]; then
        local pic_repo_owner=$(stat -c '%u' "$PIC_PATH")
        if [ "$pic_repo_owner" != "$CURRENT_UID" ]; then
            echo "You do not own the Plex-Image-Cleanup repo. Please run this script as the user that owns the repo [$pic_repo_owner]."
            exit 1
        fi
    else
        echo "Plex-Image-Cleanup folder does not exist. Please install Plex-Image-Cleanup before running this script."
        exit 1
    fi
}

# Update Plex-Image-Cleanup if necessary
update_pic() {
    local current_branch=$(git -C "$PIC_PATH" rev-parse --abbrev-ref HEAD)
    echo "Current Branch: $current_branch. Checking for updates..."
    git -C "$PIC_PATH" fetch
    if [ "$(git -C "$PIC_PATH" rev-parse HEAD)" = "$(git -C "$PIC_PATH" rev-parse @'{u}')" ] && [ "$force_update" != true ]; then
        local current_version=$(cat "$PIC_VERSION_FILE")
        echo "=== Already up to date $current_version on $current_branch ==="
        exit 0
    fi
    git -C "$PIC_PATH" reset --hard "$PIC_UPSTREAM_GIT_REMOTE/$current_branch"
}

# Update venv if necessary
update_venv() {
    local current_requirements=$(sha1sum "$PIC_REQUIREMENTS_FILE" | awk '{print $1}')
    local new_requirements=$(sha1sum "$PIC_REQUIREMENTS_FILE" | awk '{print $1}')
    if [ "$current_requirements" != "$new_requirements" ] || [ "$force_update" = true ]; then
        echo "=== Requirements changed, updating venv ==="
        "$PIC_VENV_PATH/bin/python3" "$PIC_VENV_PATH/bin/pip" install -r "$PIC_REQUIREMENTS_FILE"
    fi
}

# Restart the Plex-Image-Cleanup service
restart_service() {
    echo "=== Restarting Plex-Image-Cleanup Service ==="
    sudo systemctl restart "$PIC_SERVICE_NAME"
    local new_version=$(cat "$PIC_VERSION_FILE")
    echo "=== Updated to $new_version on $current_branch ==="
}

# Main script execution
check_pic_installation
update_pic
update_venv
restart_service
