#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

DEFAULT_INSTALL_DIR="/usr/local/bin"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"

if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
	apt-get update
	apt-get install -y --no-install-recommends curl unzip tar ca-certificates
fi

if ! command -v gh >/dev/null 2>&1; then
	echo "GitHub CLI (gh) is required for attestation verification but was not found"
	exit 1
fi

required_vars=(
	"GITHUB_REPO"
	"VERSION"
	"DOWNLOAD_BINARY"
	"TOOL"
	"COMPRESSION"
	"VERIFY_BINARY_ATTESTATION"
	"VERIFY_CHECKSUM"
)

for var_name in "${required_vars[@]}"; do
	if [ -z "${!var_name:-}" ]; then
		echo "${var_name} must be defined"
		exit 1
	fi
done

if [ "${VERIFY_BINARY_ATTESTATION}" != "true" ] && [ "${VERIFY_CHECKSUM}" != "true" ]; then
	echo "VERIFY_BINARY_ATTESTATION or VERIFY_CHECKSUM must be set to true"
	exit 1
fi

BINARY_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/${DOWNLOAD_BINARY}"
BINARY_ASSET_NAME="${DOWNLOAD_BINARY}"
CHECKSUMS_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/checksums.txt"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

curl -fsSL "${BINARY_URL}" -o "${tmp_dir}/${BINARY_ASSET_NAME}"
if [ "${VERIFY_BINARY_ATTESTATION}" == "true" ]; then
	gh attestation verify "${tmp_dir}/${BINARY_ASSET_NAME}" -R "${GITHUB_REPO}"
fi

if [ "${VERIFY_CHECKSUM}" == "true" ]; then
	curl -fsSL "${CHECKSUMS_URL}" -o "${tmp_dir}/checksums.txt"
	gh attestation verify "${tmp_dir}/checksums.txt" -R "${GITHUB_REPO}"
	(
		cd "${tmp_dir}"
		sha256sum --ignore-missing -c checksums.txt
	)
fi

if [ "${COMPRESSION}" == "zip" ]; then
	unzip -q "${tmp_dir}/${BINARY_ASSET_NAME}" -d "${tmp_dir}"
elif [ "${COMPRESSION}" == "tar.gz" ]; then
	tar -xzf "${tmp_dir}/${BINARY_ASSET_NAME}" -C "${tmp_dir}"
else
	echo "Unsupported compression format: ${COMPRESSION}"
	exit 1
fi

mkdir -p "$INSTALL_DIR"
install -m 0755 "$tmp_dir/$TOOL" "${INSTALL_DIR}/${TOOL}"
