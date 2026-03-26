#!/usr/bin/env bash
set -euo pipefail

DEFAULT_INSTALL_DIR="/usr/local/bin"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
BASE_URL="https://github.com/anchore/${TOOL}/releases/download/v${VERSION}"
ARCHIVE="${TOOL}_${VERSION}_linux_${ARCH}.tar.gz"
CHECKSUMS="${TOOL}_${VERSION}_checksums.txt"
CHECKSUMS_PEM="${TOOL}_${VERSION}_checksums.txt.pem"
CHECKSUMS_SIG="${TOOL}_${VERSION}_checksums.txt.sig"

if [ -z "$TOOL" ]
then
      echo "\$TOOL is NULL"
fi
if [ -z "$ARCH" ]
then
      echo "\$ARCH is NULL"
fi
if [ -z "$VERSION" ]
then
      echo "\$VERSION is NULL"
fi

usage() {
  cat <<'EOF'
Usage: install_anchore_tool.sh

Downloads an Anchore tool (syft or grype) archive and its sigstore bundle to a temporary directory,
verifies the sigstore bundle following 
https://oss.anchore.com/docs/installation/verification/,
and installs the Anchore tool binary into INSTALL_DIR (default: /usr/local/bin).

Environment variables:
  INSTALL_DIR  Directory to install the Anchore tool binary into (default: /usr/local/bin)
  VERSION      Anchore tool version tag to install
  ARCH         Architecture suffix used in the download
  TOOL         Anchore tool name, either "syft" or "grype"
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

for cmd in curl cosign; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is required but not found in PATH" >&2
    exit 1
  fi
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

download() {
  local url="${1}" dest="${2}"
  echo "Downloading ${dest} from ${url} ..."
  curl -fsSL "${url}" -o "${dest}"
}
ARCHIVE_PATH="${TMP_DIR}/${ARCHIVE}"
ALL_CHECKSUMS_PATH="${TMP_DIR}/${CHECKSUMS}"
CHECKSUM_PATH="${TMP_DIR}/${ARCHIVE}.sha256sum"
CHECKSUMS_PEM_PATH="${TMP_DIR}/${CHECKSUMS_PEM}"
CHECKSUMS_SIG_PATH="${TMP_DIR}/${CHECKSUMS_SIG}"
download "${BASE_URL}/${ARCHIVE}" "${ARCHIVE_PATH}"
download "${BASE_URL}/${CHECKSUMS}" "${ALL_CHECKSUMS_PATH}"
download "${BASE_URL}/${CHECKSUMS_PEM}" "${CHECKSUMS_PEM_PATH}"
download "${BASE_URL}/${CHECKSUMS_SIG}" "${CHECKSUMS_SIG_PATH}"

cosign verify-blob "${ALL_CHECKSUMS_PATH}" \
  --certificate "${CHECKSUMS_PEM_PATH}" \
  --signature "${CHECKSUMS_SIG_PATH}" \
  --certificate-identity-regexp "https://github\.com/anchore/${TOOL}/\.github/workflows/.+" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"

echo "Sigstore verification passed"

grep "${ARCHIVE}" "${ALL_CHECKSUMS_PATH}" > "${CHECKSUM_PATH}"

cd "${TMP_DIR}"
sha256sum -c "${CHECKSUM_PATH}"
echo "Checksum verification passed"
tar -xzf "${ARCHIVE_PATH}" -C "${TMP_DIR}"

mkdir -p "$INSTALL_DIR"
install -m 0755 "$TMP_DIR/${TOOL}" "${INSTALL_DIR}/${TOOL}"

echo "${TOOL} ${VERSION} installed to ${INSTALL_DIR}"
