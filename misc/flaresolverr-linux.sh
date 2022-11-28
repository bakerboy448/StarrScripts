#! /bin/sh

github_repo_url="https://github.com/FlareSolverr/FlareSolverr/releases/"
install_dir="/opt"
fs_user="flaresolverr"
github_release_latestpath="$github_repo_url""releases/latest"
latest_version=$("curl -L -s -H 'Accept: application/json' $github_repo_url$github_release_latestpath" | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
download_url=$("$github_repo_url/download/${latest_version}/flaresolverr-$latest_version-linux-x64.zip")
wget -q -O /tmp/flaresolverr.zip "$download_url"
unzip flaresolverr.zip
sudo mv flarsolverr/ "$install_dir"
sudo chown -R $fs_user:$fs_user /opt/Flaresolverr
cat << EOF | tee /etc/systemd/system/flaresolverr.service > /dev/null
[Unit]
Description=Flaresolverr Daemon
After=syslog.target network.target
[Service]
User=$fs_user
Group=$fs_user
UMask=0022
Type=simple
ExecStart=/opt/Flaresolverr/Flaresolverr
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl -q daemon-reload
sudo systemctl enable --now -q flaresolverr
sudo systemctl status flaresolverr
