#!/usr/bin/env bash
set -euo pipefail

VERSION=${VERSION:-"v2.37.1"}
# Expected SHA256 checksums taken from https://github.com/direnv/direnv/releases/tag/v2.37.1
# When we change direnv versions, these must be changed
sha256sum_expected_arm="sha256:2a9cef8d73521d6a3ec3f2871c4b747b8c4cc038628c1b57a7efa42b393a2d82"
sha256sum_expected_amd64="sha256:1f1b93dd6f38523fde26dfac96151ef9d31a374e3005cd3345fb93555ae0c9b5"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        sudo apt-get -y install --no-install-recommends "$@"
    fi
}

check_packages curl ca-certificates tar

install() {
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' EXIT

    download_file="${tmp_dir}/direnv"

    if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then
        download_url="https://github.com/direnv/direnv/releases/download/${VERSION}/direnv.linux-arm64"
        sha256sum_expected="${sha256sum_expected_arm}"
    else
        download_url="https://github.com/direnv/direnv/releases/download/${VERSION}/direnv.linux-amd64"
        sha256sum_expected="${sha256sum_expected_amd64}"
    fi
    echo "Downloading direnv from ${download_url}..."
    curl -fsSL "${download_url}" -o "${download_file}"

    download_file_sha256sum=$(sha256sum "${download_file}" | awk '{print $1}')
    if [ "${download_file_sha256sum}" != "${sha256sum_expected#sha256:}" ]; then
        echo "SHA256 checksum mismatch for downloaded direnv archive"
        echo "Expected: ${sha256sum_expected}"
        echo "Actual:   sha256:${download_file_sha256sum}"
        exit 1
    fi

    mkdir -p /usr/bin
    mv "${download_file}" /usr/bin/direnv
    chmod +x /usr/bin/direnv
}
echo "(*) Installing direnv..."

install

echo "Done!"
