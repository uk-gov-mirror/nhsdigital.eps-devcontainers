#!/usr/bin/env bash

set -euo pipefail

# clean up
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
