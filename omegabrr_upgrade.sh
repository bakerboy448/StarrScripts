#!/bin/bash
old_version="$(omegabrr version)"
dlurl="$(curl -s https://api.github.com/repos/autobrr/omegabrr/releases/latest | grep download | grep linux_x86_64 | cut -d\" -f4)"
wget "$dlurl"
sudo tar -xzf omegabrr*.tar.gz
sudo mv omegabrr /usr/bin/omegabrr
rm omegabrr*.tar.gz
echo "Omegabrr Updated"
echo "Old Version"
echo "$old_version"
echo "New Version"
omegabrr version
sysrestart omegabrr@bakerboy448
