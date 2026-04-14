#!/usr/bin/env bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

DEFAULT_INSTALL_DIR="/usr/local/bin"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"

case "${TARGETARCH:-}" in
	amd64|arm64)
		TFLINT_ARCH="${TARGETARCH}"
		;;
	*)
		echo "Unsupported or missing TARGETARCH: '${TARGETARCH:-}'"
		echo "Expected one of: amd64, arm64"
		exit 1
		;;
esac

if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
	apt-get update
	apt-get install -y --no-install-recommends curl unzip ca-certificates
fi

if ! command -v gh >/dev/null 2>&1; then
	echo "GitHub CLI (gh) is required for attestation verification but was not found"
	exit 1
fi

TFLINT_URL="https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_${TFLINT_ARCH}.zip"
TFLINT_ASSET_NAME="tflint_linux_${TFLINT_ARCH}.zip"
CHECKSUMS_URL="https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/checksums.txt"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

curl -fsSL "${CHECKSUMS_URL}" -o "${tmp_dir}/checksums.txt"
gh attestation verify "${tmp_dir}/checksums.txt" -R terraform-linters/tflint

curl -fsSL "${TFLINT_URL}" -o "${tmp_dir}/${TFLINT_ASSET_NAME}"
(
	cd "${tmp_dir}"
	sha256sum --ignore-missing -c checksums.txt
)

unzip -q "${tmp_dir}/${TFLINT_ASSET_NAME}" -d "${tmp_dir}"

mkdir -p "$INSTALL_DIR"
install -m 0755 "$tmp_dir/tflint" "${INSTALL_DIR}/tflint"
