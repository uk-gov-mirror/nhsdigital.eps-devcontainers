#!/usr/bin/env bash
set -euo pipefail

VERSION=${VERSION:-"v4.52.5"}
# Expected SHA256 checksums taken from https://github.com/mikefarah/yq/releases/tag/v4.52.5
# When we change yq versions, these must be changed
sha256sum_expected_arm="sha256:90fa510c50ee8ca75544dbfffed10c88ed59b36834df35916520cddc623d9aaa"
sha256sum_expected_amd64="sha256:75d893a0d5940d1019cb7cdc60001d9e876623852c31cfc6267047bc31149fa9"

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

    download_file="${tmp_dir}/yq"

    if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then
        download_url="https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_linux_arm64"
        sha256sum_expected="${sha256sum_expected_arm}"
    else
        download_url="https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_linux_amd64"
        sha256sum_expected="${sha256sum_expected_amd64}"
    fi
    echo "Downloading yq from ${download_url}..."
    curl -fsSL "${download_url}" -o "${download_file}"

    download_file_sha256sum=$(sha256sum "${download_file}" | awk '{print $1}')
    if [ "${download_file_sha256sum}" != "${sha256sum_expected#sha256:}" ]; then
        echo "SHA256 checksum mismatch for downloaded yq archive"
        echo "Expected: ${sha256sum_expected}"
        echo "Actual:   sha256:${download_file_sha256sum}"
        exit 1
    fi

    mkdir -p /usr/bin
    mv "${download_file}" /usr/bin/yq
    chmod +x /usr/bin/yq
}
echo "(*) Installing yq..."

install

echo "Done!"
