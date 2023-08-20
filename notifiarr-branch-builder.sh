#!/bin/bash

# Define variables
repo_url="https://github.com/Notifiarr/notifiarr.git"
repo_dir="/home/bakerboy448/notifiarr"
source_path="$repo_dir/notifiarr"
bin_path="/usr/bin/notifiarr"
notifiarruser="notifiarr"

# Function to display an error message and exit
handle_error() {
    echo "Error: $1"
    exit 1
}

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
    git -C "$repo_dir" fetch --all || handle_error "Failed to fetch updates from remote."
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

# Change owner of the compiled binary
sudo chown "$notifiarruser":"$notifiarruser" "$source_path"
echo "Stopping notifiarr..."
sudo systemctl stop notifiarr

# Move the binaries
if [[ -f "$bin_path" ]]; then
    sudo mv "$bin_path" "$repo_dir".old && echo "Old binary moved to $repo_dir.old"
fi

sudo mv "$source_path" "$bin_path" && echo "New binary moved to $bin_path"

# Start the service again
sudo systemctl start notifiarr
