#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2129
# shellcheck disable=SC2016
echo 'PATH="/home/vscode/.asdf/shims/:$PATH"' >> ~/.bashrc
echo '. <(asdf completion bash)' >> ~/.bashrc
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
# shellcheck disable=SC2016
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
# shellcheck disable=SC2016
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc

# Install ASDF plugins
# actionlint install is verified so can install via asdf
asdf plugin add actionlint
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git

# install cfn-guard
VERSION="${CFN_GUARD_VERSION}" "${SCRIPTS_DIR}/${CONTAINER_NAME}/install_cfn_guard.sh"

# install base asdf versions of common tools
cd /home/vscode
asdf install
