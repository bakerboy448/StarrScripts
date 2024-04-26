#!/bin/bash

# Define service name as a variable
service_name="omegabrr@bakerboy448"

# Function to handle errors and exit
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Get the old version of omegabrr
old_version=$(omegabrr version)

# Fetch the URL of the latest release for linux_x86_64
dlurl=$(curl -s https://api.github.com/repos/autobrr/omegabrr/releases/latest |
    grep -E 'browser_download_url.*linux_x86_64' | cut -d\" -f4)

# Validate the download URL
if [ -z "$dlurl" ]; then
    handle_error "Failed to fetch download URL."
fi

# Download the latest release
wget "$dlurl" -O omegabrr_latest.tar.gz || handle_error "Failed to download the latest version."

# Extract the downloaded archive
sudo tar -xzf omegabrr_latest.tar.gz -C /usr/bin/ || handle_error "Failed to extract files."

# Clean up downloaded files
rm omegabrr_latest.tar.gz

# Display old and new versions
new_version=$(omegabrr version)
echo "Omegabrr updated from $old_version to $new_version"

# Restart the specified service
sudo systemctl restart $service_name || handle_error "Failed to restart the service $service_name."

echo "Update and restart successful!"
