#!/bin/bash

# Get the old version of omegabrr
old_version=$(omegabrr version)

# Fetch the URL of the latest release for linux_x86_64
dlurl=$(curl -s https://api.github.com/repos/autobrr/omegabrr/releases/latest | grep -E 'browser_download_url.*linux_x86_64' | cut -d\" -f4)

# Download the latest release
if [ -n "$dlurl" ]; then
    wget "$dlurl"
    # Extract the downloaded archive
    sudo tar -xzf omegabrr*.tar.gz
    # Move omegabrr to /usr/bin
    sudo mv omegabrr /usr/bin/omegabrr
    # Clean up downloaded files
    rm omegabrr*.tar.gz
    echo "Omegabrr Updated"
else
    echo "Failed to fetch download URL. Exiting..."
    exit 1
fi

# Display old and new versions
echo "Old Version: $old_version"
echo "New Version: $(omegabrr version)"

# Restart the omegabrr service (assuming sysrestart command exists)
sysrestart omegabrr@bakerboy448
