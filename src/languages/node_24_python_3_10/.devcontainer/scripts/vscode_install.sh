#!/usr/bin/env bash
set -e
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

asdf plugin add python
asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git

asdf install python
asdf install

pip install --user -r "${SCRIPT_DIR}/requirements-user.txt"
