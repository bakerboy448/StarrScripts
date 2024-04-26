#!/bin/bash
set -e
set -o pipefail

force_update=${1:-false}

# Constants
PMM_PATH="/opt/Plex-Meta-Manager"
PMM_VENV_NAME="pmm-venv"
PMM_SERVICE_NAME="pmm"
PMM_UPSTREAM_GIT_REMOTE="origin"
PMM_VERSION_FILE="$PMM_PATH/VERSION"
PMM_REQUIREMENTS_FILE="$PMM_PATH/requirements.txt"
PMM_VENV_PATH="/opt/.venv/$PMM_VENV_NAME"
CURRENT_UID=$(id -u)

# Check if PMM is installed and the current user owns it
check_pmm_installation() {
    if [ -d "$PMM_PATH" ]; then
        pmm_repo_owner=$(stat -c '%u' "$PMM_PATH")
        if [ "$pmm_repo_owner" != "$CURRENT_UID" ]; then
            echo "You do not own the Plex Meta Manager repo. Please run this script as the user that owns the repo [$pmm_repo_owner]."
            exit 1
        fi
    else
        echo "Plex Meta Manager folder does not exist. Please install Plex Meta Manager before running this script."
        exit 1
    fi
}

# Update PMM if necessary
update_pmm() {
    current_branch=$(git -C "$PMM_PATH" rev-parse --abbrev-ref HEAD)
    echo "Current Branch: $current_branch. Checking for updates..."
    git -C "$PMM_PATH" fetch
    if [ "$(git -C "$PMM_PATH" rev-parse HEAD)" = "$(git -C "$PMM_PATH" rev-parse @'{u}')" ] && [ "$force_update" != true ]; then
        current_version=$(cat "$PMM_VERSION_FILE")
        echo "=== Already up to date $current_version on $current_branch ==="
        exit 0
    fi
    git -C "$PMM_PATH" reset --hard "$PMM_UPSTREAM_GIT_REMOTE/$current_branch"
}

# Update venv if necessary
update_venv() {
    current_requirements=$(sha1sum "$PMM_REQUIREMENTS_FILE" | awk '{print $1}')
    new_requirements=$(sha1sum "$PMM_REQUIREMENTS_FILE" | awk '{print $1}')
    if [ "$current_requirements" != "$new_requirements" ] || [ "$force_update" = true ]; then
        echo "=== Requirements changed, updating venv ==="
        "$PMM_VENV_PATH/bin/python3" "$PMM_VENV_PATH/bin/pip" install -r "$PMM_REQUIREMENTS_FILE"
    fi
}

# Restart the PMM service
restart_service() {
    echo "=== Restarting PMM Service ==="
    sudo systemctl restart "$PMM_SERVICE_NAME"
    new_version=$(cat "$PMM_VERSION_FILE")
    echo "=== Updated to $new_version on $current_branch"
}

# Main script execution
check_pmm_installation
update_pmm
update_venv
restart_service
