#!/usr/bin/env bash
set -euo pipefail

DEFAULT_INSTALL_DIR="/usr/local/bin"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
REQUESTED_VERSION="${1:-latest}"
OS="$(uname -s)"
ARCH="$(uname -m)"
API_URL="https://api.github.com/repos/sigstore/cosign/releases"

usage() {
  cat <<'EOF'
Usage: install_cosign.sh [version]

Downloads the requested cosign release (default: latest) for Linux amd64, verifies
its SHA256 checksum, and installs it into $INSTALL_DIR (override via INSTALL_DIR env var).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$OS" != "Linux" ]]; then
  echo "Error: This installer currently supports Linux only" >&2
  exit 1
fi

case "$ARCH" in
  x86_64|amd64)
    BINARY_NAME="cosign-linux-amd64"
    ;;
  *)
    echo "Error: Unsupported architecture $ARCH" >&2
    exit 1
    ;;
esac

for cmd in curl sha256sum install; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is required but not found in PATH" >&2
    exit 1
  fi
done

get_latest_tag() {
  curl -fsSL "$API_URL/latest" | awk -F'"' '/tag_name/ {print $4; exit}'
}

VERSION="$REQUESTED_VERSION"
if [[ "$VERSION" == "latest" ]]; then
  VERSION="$(get_latest_tag)"
fi

if [[ -z "$VERSION" ]]; then
  echo "Error: Unable to determine cosign version" >&2
  exit 1
fi

BASE_URL="https://github.com/sigstore/cosign/releases/download/${VERSION}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BIN_PATH="$TMP_DIR/${BINARY_NAME}"
SHA_PATH="$TMP_DIR/${BINARY_NAME}.sha256"

curl -fsSL "${BASE_URL}/${BINARY_NAME}" -o "$BIN_PATH"
curl -fsSL "${BASE_URL}/${BINARY_NAME}.sha256" -o "$SHA_PATH"

pushd "$TMP_DIR" >/dev/null
sha256sum -c "${BINARY_NAME}.sha256"
popd >/dev/null

install -m 0755 "$BIN_PATH" "${INSTALL_DIR}/cosign"

"${INSTALL_DIR}/cosign" version

echo "cosign ${VERSION} installed to ${INSTALL_DIR}"
