#!/usr/bin/env bash
set -euo pipefail

DEFAULT_INSTALL_DIR="/usr/local/bin"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
VERSION="v0.69.3"
DEFAULT_ARCH="64bit"
ARCH="${ARCH:-$DEFAULT_ARCH}"
RELEASE_NUMBER="${VERSION#v}"
BASE_URL="https://github.com/aquasecurity/trivy/releases/download/${VERSION}"
ARCHIVE="trivy_${RELEASE_NUMBER}_Linux-${ARCH}.tar.gz"
BUNDLE="${ARCHIVE}.sigstore.json"
CERT_IDENTITY="https://github.com/aquasecurity/trivy/.github/workflows/reusable-release.yaml@refs/tags/${VERSION}"

usage() {
  cat <<'EOF'
Usage: install_trivy.sh [output_dir]

Downloads Trivy, its sigstore bundle, and checksum into output_dir (default: current directory),
then verifies the checksum and the sigstore bundle, following
https://github.com/aquasecurity/trivy/blob/main/docs/getting-started/signature-verification.md.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

for cmd in curl cosign sha256sum; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is required but not found in PATH" >&2
    exit 1
  fi
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

download() {
  local url="${1}" dest="${2}"
  echo "Downloading ${dest} ..."
  curl -fsSL "${url}" -o "${dest}"
}
ARCHIVE_PATH="${TMP_DIR}/${ARCHIVE}"
BUNDLE_PATH="${TMP_DIR}/${BUNDLE}"
download "${BASE_URL}/${ARCHIVE}" "${ARCHIVE_PATH}"
download "${BASE_URL}/${BUNDLE}" "${BUNDLE_PATH}"


cosign verify-blob-attestation "${ARCHIVE_PATH}" \
  --bundle "${BUNDLE_PATH}" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  --certificate-identity "${CERT_IDENTITY}"

echo "Sigstore verification passed"
tar -xzf "${ARCHIVE_PATH}" -C "${TMP_DIR}"

mkdir -p "$INSTALL_DIR"
install -m 0755 "$TMP_DIR/trivy" "${INSTALL_DIR}/trivy"

echo "trivy ${VERSION} installed to ${INSTALL_DIR}"
