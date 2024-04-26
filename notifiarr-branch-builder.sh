#!/bin/bash

# Extend the PATH to include the go binary directory
export PATH=$PATH:/usr/local/go/bin

# Function to display error messages and exit with status 1
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to display usage information
display_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help               Display this help message"
    echo "  --repo-url URL           Set the repository URL (default: https://github.com/Notifiarr/notifiarr.git)"
    echo "  --repo-dir DIR           Set the repository directory (default: /opt/notifiarr-repo)"
    echo "  --bin-path PATH          Set the binary path (default: /usr/bin/notifiarr)"
    echo "  --branch BRANCH          Set the branch (default: master)"
    echo "  --reinstall-apt          Reinstall Notifiarr using apt without prompting."
    exit 0
}

# Function to check and prompt for installation of a required tool
ensure_tool_installed() {
    local tool=$1
    local install_cmd=$2
    if ! command -v "$tool" &>/dev/null; then
        read -r -p "$tool is not installed. Do you want to install it? [Y/n] " response
        if [[ "$response" =~ ^[Yy] ]]; then
            eval "$install_cmd" || handle_error "Failed to install $tool."
        else
            echo "$tool is required for this script. Exiting."
            exit 1
        fi
    fi
}

# Default parameters
repo_url="https://github.com/Notifiarr/notifiarr.git"
repo_dir="/opt/notifiarr-repo"
bin_path="/usr/bin/notifiarr"
branch="master"
apt_reinstall=false

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
        display_help
        ;;
    --repo-url)
        repo_url="$2"
        shift
        ;;
    --repo-dir)
        repo_dir="$2"
        shift
        ;;
    --bin-path)
        bin_path="$2"
        shift
        ;;
    --branch)
        branch="$2"
        shift
        ;;
    --reinstall-apt)
        apt_reinstall=true
        ;;
    *)
        echo "Invalid option: $1. Use -h for help."
        exit 1
        ;;
    esac
    shift
done

# Ensure required tools are installed
ensure_tool_installed "make" "sudo apt update && sudo apt install -y make"

# Reinstallation condition handling
reinstall_notifiarr() {
    # shellcheck disable=SC2015
    sudo apt update && sudo apt install --reinstall notifiarr || handle_error "Failed to reinstall Notifiarr using apt."
}

[[ $apt_reinstall == true ]] && reinstall_notifiarr

# Repository management
if [[ ! -d "$repo_dir" ]]; then
    git clone "$repo_url" "$repo_dir" || handle_error "Failed to clone repository."
else
    git -C "$repo_dir" fetch --all --prune || handle_error "Failed to fetch updates from remote."
fi

# Branch handling and updating
current_branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD)
read -r -p "Do you want to use the current branch ($current_branch)? [Y/n] " choice
if [[ "$choice" =~ ^[Nn] ]]; then
    branches=$(git -C "$repo_dir" branch -r | sed 's/origin\///;s/* //')
    echo "Available branches:"
    echo "$branches"
    while true; do
        read -r -p "Enter the branch name you want to use: " branch
        if [[ $branches =~ $branch ]]; then
            git -C "$repo_dir" checkout "$branch" || handle_error "Failed to checkout branch $branch."
            break
        else
            echo "Invalid choice. Please select a valid branch."
        fi
    done
fi

git -C "$repo_dir" pull || handle_error "Failed to pull latest changes."
make --directory="$repo_dir" || handle_error "Failed to compile."

# Service management
echo "Stopping notifiarr..."
sudo systemctl stop notifiarr

if [[ -f "$bin_path" ]]; then
    sudo mv "$bin_path" "$repo_dir".old && echo "Old binary moved to $repo_dir.old"
fi

sudo mv "$repo_dir/notifiarr" "$bin_path" && echo "New binary moved to $bin_path"
sudo chown root:root "$bin_path"

echo "Starting Notifiarr..."
sudo systemctl start notifiarr

if sudo systemctl is-active –quiet notifiarr; then
    echo "Notifiarr service started and is currently running"
else
    handle_error "Failed to start Notifiarr service"
fi

exit 0
