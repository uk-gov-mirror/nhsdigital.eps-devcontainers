#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Add amd64 architecture if on arm64
if [ "$TARGETARCH" == "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then 
    echo "Adding amd64 architecture support"
    dpkg --add-architecture amd64

    # Update sources.list to include amd64 repositories
    echo "Configuring sources.list for amd64 and arm64"
    sed -i.bak '/^deb / s|http://ports.ubuntu.com/ubuntu-ports|[arch=arm64] http://ports.ubuntu.com/ubuntu-ports|' /etc/apt/sources.list
    # shellcheck disable=SC2129
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy main universe" >> /etc/apt/sources.list
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-updates main universe" >> /etc/apt/sources.list
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-security main universe" >> /etc/apt/sources.list
fi

# update and upgrade packages
echo "Running apt-get update"
apt-get update
apt-get upgrade -y

# install necessary libraries for asdf and language runtimes
echo "Installing necessary packages"
apt-get -y install --no-install-recommends htop vim curl git build-essential \
    libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg8-dev libbz2-dev \
    zlib1g-dev unixodbc unixodbc-dev libsecret-1-0 libsecret-1-dev libsqlite3-dev \
    jq apt-transport-https ca-certificates gnupg-agent \
    software-properties-common bash-completion make parallel \
    libreadline-dev wget llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev liblzma-dev netcat-traditional libyaml-dev uuid-runtime xxd unzip

# install AWS SAM CLI
VERSION="${SAM_VERSION}" "${SCRIPTS_DIR}/${CONTAINER_NAME}/install_aws_sam_cli.sh"
# Install ASDF
VERSION="${ASDF_VERSION}" "${SCRIPTS_DIR}/${CONTAINER_NAME}/install_asdf.sh"
# install gitleaks
VERSION="${GITLEAKS_VERSION}" "${SCRIPTS_DIR}/${CONTAINER_NAME}/install_gitleaks.sh"
# install shellcheck
VERSION="${SHELLCHECK_VERSION}" "${SCRIPTS_DIR}/${CONTAINER_NAME}/install_shellcheck.sh"
# install direnv
VERSION="${DIRENV_VERSION}" "${SCRIPTS_DIR}/${CONTAINER_NAME}/install_direnv.sh"
# install yq
VERSION="${YQ_VERSION}" "${SCRIPTS_DIR}/${CONTAINER_NAME}/install_yq.sh"

# install gitsecrets
# this should be removed once we have migrated all repos to gitleaks
git clone https://github.com/awslabs/git-secrets.git /tmp/git-secrets
cd /tmp/git-secrets
make install
cd
rm -rf /tmp/git-secrets
mkdir -p /usr/share/secrets-scanner
chmod 755 /usr/share/secrets-scanner
curl -L https://raw.githubusercontent.com/NHSDigital/software-engineering-quality-framework/main/tools/nhsd-git-secrets/nhsd-rules-deny.txt -o /usr/share/secrets-scanner/nhsd-rules-deny.txt

# get cfn-guard ruleset
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
download_file="${tmp_dir}/ruleset.zip"
curl -fsSL "https://github.com/aws-cloudformation/aws-guard-rules-registry/releases/download/1.0.2/ruleset-build-v1.0.2.zip" -o "${download_file}"

mkdir -p "${SCRIPTS_DIR}/cfnguard_rulesets"
unzip "${download_file}" -d "${SCRIPTS_DIR}/cfnguard_rulesets" 

# clean up
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
