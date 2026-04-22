#!/usr/bin/env bash
set -e

# install allure and java using asdf
asdf plugin add java
asdf plugin add allure
asdf install
