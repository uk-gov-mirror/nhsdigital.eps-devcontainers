#!/usr/bin/env bash

VERSION=${VERSION:-"8.30.1"}
# Expected SHA256 checksums taken from https://github.com/gitleaks/gitleaks/releases/tag/v8.30.1
# When we change gitleaks versions, these must be changed
sha256sum_expected_arm="sha256:e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080"
sha256sum_expected_amd64="sha256:551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

check_packages curl ca-certificates tar sha256sum

install() {
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' EXIT

    download_file="${tmp_dir}/gitleaks.tar.gz"

    if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then
        download_url="https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_arm64.tar.gz"
        sha256sum_expected="${sha256sum_expected_arm}"
    else
        download_url="https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_x64.tar.gz"
        sha256sum_expected="${sha256sum_expected_amd64}"
    fi
    echo "Downloading gitleaks from ${download_url}..."
    curl -fsSL "${download_url}" -o "${download_file}"

    download_file_sha256sum=$(sha256sum "${download_file}" | awk '{print $1}')
    if [ "${download_file_sha256sum}" != "${sha256sum_expected#sha256:}" ]; then
        echo "SHA256 checksum mismatch for downloaded gitleaks archive"
        echo "Expected: ${sha256sum_expected}"
        echo "Actual:   sha256:${download_file_sha256sum}"
        exit 1
    fi

    tar -xzf "${download_file}" -C "${tmp_dir}"
    mkdir -p /usr/bin
    mv "${tmp_dir}/gitleaks" /usr/bin/gitleaks
    chmod +x /usr/bin/gitleaks
}
echo "(*) Installing gitleaks..."

install

echo "Done!"
