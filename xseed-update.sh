#!/usr/bin/env bash
PKGNAME="cross-seed"
SERVICENAME="xseed"
sudo npm uninstall --location=global "$PKGNAME"
sudo npm install --location=global "$PKGNAME"
sudo systemctl restart "$SERVICENAME"
