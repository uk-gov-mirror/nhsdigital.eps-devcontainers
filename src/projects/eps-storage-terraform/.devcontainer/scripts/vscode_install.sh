#!/usr/bin/env bash
set -e

# install terraform using asdf
# terraform is verified by asdf install
asdf plugin add terraform
asdf install
