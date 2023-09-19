#!/bin/bash
set -e
set -o pipefail

force_update=${1:-false}

# Constants
QBM_PATH="/opt/QbitManage"
QBM_VENV_PATH="/opt/.venv/qbm-venv"
QBM_SERVICE_NAME="qbmanage"
QBM_UPSTREAM_GIT_REMOTE="origin"
QBM_VERSION_FILE="$QBM_PATH/VERSION"
QBM_REQUIREMENTS_FILE="$QBM_PATH/requirements.txt"
CURRENT_UID=$(id -u)

# Check if QBM is installed and if the current user owns it
check_qbm_installation() {
    if [ -d "$QBM_PATH" ]; then
        local qbm_repo_owner=$(stat -c '%u' "$QBM_PATH")
        if [ "$qbm_repo_owner" != "$CURRENT_UID" ]; then
            echo "You do not own the QbitManage repo. Please run this script as the user that owns the repo [$qbm_repo_owner]."
            exit 1
        fi
    else
        echo "QbitManage folder does not exist. Please install QbitManage before running this script."
        exit 1
    fi
}

# Update QBM if necessary
update_qbm() {
    current_branch=$(git -C "$QBM_PATH" rev-parse --abbrev-ref HEAD)
    echo "Current Branch: $current_branch. Checking for updates..."
    git -C "$QBM_PATH" fetch
    if [ "$(git -C "$QBM_PATH" rev-parse HEAD)" = "$(git -C "$QBM_PATH" rev-parse @'{u}')" ] && [ "$force_update" != true ]; then
        local current_version=$(cat "$QBM_VERSION_FILE")
        echo "=== Already up to date $current_version on $current_branch ==="
        exit 0
    fi
    git -C "$QBM_PATH" reset --hard "$QBM_UPSTREAM_GIT_REMOTE/$current_branch"
}

# Update virtual environment if requirements have changed
update_venv() {
    local current_requirements=$(sha1sum "$QBM_REQUIREMENTS_FILE" | awk '{print $1}')
    local new_requirements=$(sha1sum "$QBM_REQUIREMENTS_FILE" | awk '{print $1}')
    if [ "$current_requirements" != "$new_requirements" ] || [ "$force_update" = true ]; then
        echo "=== Requirements changed, updating venv ==="
        "$QBM_VENV_PATH/bin/python" "$QBM_VENV_PATH/bin/pip" install -r "$QBM_REQUIREMENTS_FILE"
    fi
}

# Restart the QBM service
restart_service() {
    echo "=== Restarting QBM Service ==="
    sudo systemctl restart "$QBM_SERVICE_NAME"
    local new_version=$(cat "$QBM_VERSION_FILE")
    echo "=== Updated to $new_version on $current_branch"
}

# Main script execution
check_qbm_installation
update_qbm
update_venv
restart_service
