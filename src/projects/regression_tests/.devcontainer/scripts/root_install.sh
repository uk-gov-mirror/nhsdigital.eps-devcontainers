#!/usr/bin/env bash

set -euo pipefail

# install chrome
mkdir -p /etc/apt/keyrings
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | tee /etc/apt/keyrings/google.asc >/dev/null
sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google.asc] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'
apt-get update 
apt-get install -y google-chrome-stable

# clean up
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
