#!/bin/bash

# Function to display an error message and exit
handle_error() {
    echo "Error: $1"
    exit 1
}

# Display usage information
display_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h                    Display this help message"
    echo "  --repo-url URL        Set the repository URL (default: https://github.com/Notifiarr/notifiarr.git)"
    echo "  --repo-dir DIR        Set the repository directory (default: /home/bakerboy448/notifiarr)"
    echo "  --bin-path PATH       Set the binary path (default: /usr/bin/notifiarr)"
    echo "  --notifiarruser USER  Set the Notifiarr user (default: notifiarr)"
    echo "  --branch BRANCH       Set the branch (default: master)"
    exit 0
}

# Check if Golang is installed, install if not
if ! command -v go &>/dev/null; then
    read -p "Golang is not installed. Do you want to install it? [Y/n] " go_install_choice
    if [[ "$go_install_choice" == [Yy]* ]]; then
        sudo apt update && sudo apt install -y golang || handle_error "Failed to install Golang."
    else
        echo "Golang is required for this script. Exiting."
        exit 1
    fi
fi

# Check if Make is installed, install if not
if ! command -v make &>/dev/null; then
    read -p "Make is not installed. Do you want to install it? [Y/n] " make_install_choice
    if [[ "$make_install_choice" == [Yy]* ]]; then
        sudo apt update && sudo apt install -y make || handle_error "Failed to install Make."
    else
        echo "Make is required for this script. Exiting."
        exit 1
    fi
fi

# Default parameter values
repo_url="https://github.com/Notifiarr/notifiarr.git"
repo_dir="/home/bakerboy448/notifiarr"
bin_path="/usr/bin/notifiarr"
notifiarruser="notifiarr"
branch="master"

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
    --notifiarruser)
        notifiarruser="$2"
        shift
        ;;
    --branch)
        branch="$2"
        shift
        ;;
    *)
        echo "Invalid option: $1. Use -h for help."
        exit 1
        ;;
    esac
    shift
done

# Check if user wants to reinstall using apt
read -p "Do you want to reinstall Notifiarr using apt? [Y/n] " apt_choice

if [[ "$apt_choice" == [Yy]* ]]; then
    sudo apt update && sudo apt install --reinstall notifiarr || handle_error "Failed to reinstall Notifiarr using apt."
    exit 0
fi

# Clone the repo if it doesn't exist, else fetch the latest
if [[ ! -d "$repo_dir" ]]; then
    git clone "$repo_url" "$repo_dir" || handle_error "Failed to clone repository."
else
    git -C "$repo_dir" fetch --all --prune || handle_error "Failed to fetch updates from remote."
fi

# Get the current branch
current_branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD)
echo "Current branch is: $current_branch"
read -p "Do you want to use the current branch? [Y/n] " choice

if [[ "$choice" != [Yy]* ]]; then
    # List all available branches
    branches=$(git -C "$repo_dir" branch -r | sed 's/origin\///' | sed 's/* //')
    echo "Available branches:"
    echo "$branches"

    while true; do
        read -p "Enter the branch name you want to use: " branch
        if [[ $branches =~ $branch ]]; then
            break
        else
            echo "Invalid choice. Please select a valid branch."
        fi
    done

    # Checkout the selected branch
    git -C "$repo_dir" checkout "$branch" || handle_error "Failed to checkout branch $branch."
else
    branch=$current_branch
fi

# Pull latest changes from the selected branch
git -C "$repo_dir" pull || handle_error "Failed to pull latest changes."

# Compile the code (assuming the repository requires a 'make' step)
make --directory="$repo_dir" || handle_error "Failed to compile."

echo "Stopping notifiarr..."
sudo systemctl stop notifiarr

# Move the binaries
if [[ -f "$bin_path" ]]; then
    sudo mv "$bin_path" "$repo_dir".old && echo "Old binary moved to $repo_dir.old"
fi

sudo mv "$repo_dir/notifiarr" "$bin_path" && echo "New binary moved to $bin_path"
# Change owner of the compiled binary
sudo chown "root:root" "$bin_path"

# Start the service again
sudo systemctl start notifiarr

# Check if the service started successfully
if [[ $? -eq 0 ]]; then
    echo "Notifiarr service started successfully"

    # Check the status of the service
    sudo systemctl is-active --quiet notifiarr
    if [[ $? -eq 0 ]]; then
        echo "Notifiarr service is currently running"
    else
        echo "Notifiarr service is not running"
    fi
else
    echo "Failed to start Notifiarr service"
fi

# Exit the script
exit 0
