#!/usr/bin/env bash
set -euo pipefail

VERSION=${VERSION:-"3.2.0"}
# Expected SHA256 checksums taken from https://github.com/aws-cloudformation/cloudformation-guard/releases/tag/3.2.0
# When we change gitleaks versions, these must be changed
sha256sum_expected_arm="sha256:d562e14831794a4859782f5609186970373e8e0a049fbded2c01612d2dcdb087"
sha256sum_expected_amd64="sha256:9f8c4d9f15f7dd54a37ea70a5237ba00aba682fb1e6521a744d12259961dfc13"


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

    download_file="${tmp_dir}/gitleaks.tar.gz"

    if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then
        download_url="https://github.com/aws-cloudformation/cloudformation-guard/releases/download/${VERSION}/cfn-guard-v3-aarch64-ubuntu-latest.tar.gz"
        arch_type="aarch64"
        sha256sum_expected="${sha256sum_expected_arm}"
    else
        download_url="https://github.com/aws-cloudformation/cloudformation-guard/releases/download/${VERSION}/cfn-guard-v3-x86_64-ubuntu-latest.tar.gz"
        arch_type="x86_64"
        sha256sum_expected="${sha256sum_expected_amd64}"
    fi
    echo "Downloading cfn-guard from ${download_url}..."
    curl -fsSL "${download_url}" -o "${download_file}"

    download_file_sha256sum=$(sha256sum "${download_file}" | awk '{print $1}')
    if [ "${download_file_sha256sum}" != "${sha256sum_expected#sha256:}" ]; then
        echo "SHA256 checksum mismatch for downloaded cfn-guard archive"
        echo "Expected: ${sha256sum_expected}"
        echo "Actual:   sha256:${download_file_sha256sum}"
        exit 1
    fi

    tar -xzf "${download_file}" -C "${tmp_dir}"
    mkdir -p ~/.guard/bin
    mv "${tmp_dir}/cfn-guard-v3-${arch_type}-ubuntu-latest/cfn-guard" ~/.guard/bin/cfn-guard
    chmod +x ~/.guard/bin/cfn-guard
}
echo "(*) Installing cfn-guard..."

install

echo "Done!"
