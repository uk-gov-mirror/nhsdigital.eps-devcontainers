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
its signature, and installs it into $INSTALL_DIR (override via INSTALL_DIR env var).
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
  aarch64|arm64)
    BINARY_NAME="cosign-linux-arm64"
    ;;
  *)
    echo "Error: Unsupported architecture $ARCH" >&2
    exit 1
    ;;
esac

for cmd in curl openssl install go jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is required but not found in PATH" >&2
    exit 1
  fi
done

get_latest_tag() {
  local response
  response="$(curl -fsSL "$API_URL/latest")"
  awk -F'"' '/tag_name/ {print $4; exit}' <<<"$response"
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

download() {
  local url="${1}" dest="${2}"
  echo "Downloading ${dest} ..."
  curl -fsSL "${url}" -o "${dest}"
}

BIN_PATH="$TMP_DIR/${BINARY_NAME}"
SIGSTORE_PATH="$TMP_DIR/${BINARY_NAME}-kms.sigstore.json"
ARTIFACT_PATH="$TMP_DIR/artifact.pub"
DECODED_SIGSTORE_PATH="$TMP_DIR/cosign-kms.sig.decoded"

download "${BASE_URL}/${BINARY_NAME}" "$BIN_PATH"
download "${BASE_URL}/${BINARY_NAME}-kms.sigstore.json" "$SIGSTORE_PATH"

# install tuf-client
go install github.com/theupdateframework/go-tuf/cmd/tuf-client@latest

# setup tuf-client
SIGSTORE_ROOT_PATH="$TMP_DIR/sigstore-root.json"
curl -o "$SIGSTORE_ROOT_PATH" https://raw.githubusercontent.com/sigstore/root-signing/refs/heads/main/metadata/root_history/10.root.json
tuf-client init https://tuf-repo-cdn.sigstore.dev "$SIGSTORE_ROOT_PATH"

tuf-client get https://tuf-repo-cdn.sigstore.dev artifact.pub > "$ARTIFACT_PATH"

cat "$SIGSTORE_PATH" | jq -r .messageSignature.signature | base64 -d > "$DECODED_SIGSTORE_PATH"
pushd "$TMP_DIR" >/dev/null
echo "verifying signature with artifact.pub"
openssl dgst -sha256 -verify "$ARTIFACT_PATH" -signature "$DECODED_SIGSTORE_PATH" "$BIN_PATH"
popd >/dev/null

echo "verifying signature with cosign verify-blob"
chmod +x "$BIN_PATH"
${BIN_PATH} verify-blob --bundle "${SIGSTORE_PATH}" --key "$ARTIFACT_PATH" "$BIN_PATH"

mkdir -p "$INSTALL_DIR"
install -m 0755 "$BIN_PATH" "${INSTALL_DIR}/cosign"

"${INSTALL_DIR}/cosign" version

echo "cosign ${VERSION} installed to ${INSTALL_DIR}"
