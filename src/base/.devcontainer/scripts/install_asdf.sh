#!/usr/bin/env bash
set -euo pipefail

VERSION=${VERSION:-"v0.18.1"}
# Expected SHA256 checksums taken from https://github.com/asdf-vm/asdf/releases/tag/v0.18.1
# When we change asdf versions, these must be changed
sha256sum_expected_arm="sha256:1850faf576cab7acb321e99dd98d3fe0d4665e1331086ad9ed991aeec1dc9d36"
sha256sum_expected_amd64="sha256:56141dc99eab75c140dcdd85cf73f3b82fed2485a8dccd4f11a4dc5cbcb6ea5c"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt-get -y install --no-install-recommends "$@"
    fi
}

check_packages curl ca-certificates tar

install() {
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' EXIT

    download_file="${tmp_dir}/asdf.tar.gz"

    if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then
        download_url="https://github.com/asdf-vm/asdf/releases/download/${VERSION}/asdf-${VERSION}-linux-arm64.tar.gz"
        sha256sum_expected="${sha256sum_expected_arm}"
    else
        download_url="https://github.com/asdf-vm/asdf/releases/download/${VERSION}/asdf-${VERSION}-linux-amd64.tar.gz"
        sha256sum_expected="${sha256sum_expected_amd64}"
    fi
    curl -fsSL "${download_url}" -o "${download_file}"

    download_file_sha256sum=$(sha256sum "${download_file}" | awk '{print $1}')
    if [ "${download_file_sha256sum}" != "${sha256sum_expected#sha256:}" ]; then
        echo "SHA256 checksum mismatch for downloaded asdf archive"
        echo "Expected: ${sha256sum_expected}"
        echo "Actual:   sha256:${download_file_sha256sum}"
        exit 1
    fi

    tar -xzf "${download_file}" -C "${tmp_dir}"
    mkdir -p /usr/bin
    mv "${tmp_dir}/asdf" /usr/bin/asdf
    chmod +x /usr/bin/asdf
}
echo "(*) Installing asdf..."

install

echo "Done!"
