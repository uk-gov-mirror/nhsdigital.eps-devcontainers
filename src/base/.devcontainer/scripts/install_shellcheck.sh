#!/usr/bin/env bash
set -euo pipefail

VERSION=${VERSION:-"v0.11.0"}
# Expected SHA256 checksums taken from https://github.com/koalaman/shellcheck/releases/tag/v0.11.0
# When we change shellcheck versions, these must be changed
sha256sum_expected_arm="sha256:68a8133197a50beb8803f8d42f9908d1af1c5540d4bb05fdfca8c1fa47decefc"
sha256sum_expected_amd64="sha256:b7af85e41cc99489dcc21d66c6d5f3685138f06d34651e6d34b42ec6d54fe6f6"

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

    download_file="${tmp_dir}/shellcheck.tar.gz"

    if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then
        download_url="https://github.com/koalaman/shellcheck/releases/download/${VERSION}/shellcheck-${VERSION}.linux.aarch64.tar.gz"
        sha256sum_expected="${sha256sum_expected_arm}"
    else
        download_url="https://github.com/koalaman/shellcheck/releases/download/${VERSION}/shellcheck-${VERSION}.linux.x86_64.tar.gz"
        sha256sum_expected="${sha256sum_expected_amd64}"
    fi
    echo "Downloading shellcheck from ${download_url}..."
    curl -fsSL "${download_url}" -o "${download_file}"

    download_file_sha256sum=$(sha256sum "${download_file}" | awk '{print $1}')
    if [ "${download_file_sha256sum}" != "${sha256sum_expected#sha256:}" ]; then
        echo "SHA256 checksum mismatch for downloaded shellcheck archive"
        echo "Expected: ${sha256sum_expected}"
        echo "Actual:   sha256:${download_file_sha256sum}"
        exit 1
    fi

    tar -xzf "${download_file}" -C "${tmp_dir}"
    mkdir -p /usr/bin
    mv "${tmp_dir}/shellcheck-${VERSION}/shellcheck" /usr/bin/shellcheck
    chmod +x /usr/bin/shellcheck
}
echo "(*) Installing shellcheck..."

install

echo "Done!"
