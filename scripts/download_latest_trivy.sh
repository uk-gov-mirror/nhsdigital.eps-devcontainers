#!/usr/bin/env bash
set -euo pipefail

VERSION="v0.69.3"
RELEASE_NUMBER="${VERSION#v}"
BASE_URL="https://github.com/aquasecurity/trivy/releases/download/${VERSION}"
ARCHIVE="trivy_${RELEASE_NUMBER}_Linux-64bit.tar.gz"
BUNDLE="${ARCHIVE}.sigstore.json"
CHECKSUM_FILE="${ARCHIVE}.sha256"
CERT_IDENTITY="https://github.com/aquasecurity/trivy/.github/workflows/reusable-release.yaml@refs/tags/${VERSION}"
OUTPUT_DIR="${1:-$PWD}"

usage() {
  cat <<'EOF'
Usage: download_latest_trivy.sh [output_dir]

Downloads Trivy v0.69.3, its sigstore bundle, and checksum into output_dir (default: current directory),
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

mkdir -p "$OUTPUT_DIR"
pushd "$OUTPUT_DIR" >/dev/null
trap 'popd >/dev/null' EXIT

download() {
  local url="${1}" dest="${2}"
  echo "Downloading ${dest} ..."
  curl -fsSL "${url}" -o "${dest}"
}

set_downloads() {
  download "${BASE_URL}/${ARCHIVE}" "${ARCHIVE}"
  download "${BASE_URL}/${BUNDLE}" "${BUNDLE}"
  download "${BASE_URL}/${CHECKSUM_FILE}" "${CHECKSUM_FILE}"
}

set_downloads

if sha256sum -c "${CHECKSUM_FILE}"; then
  echo "Checksum verification passed"
else
  echo "Checksum verification failed" >&2
  exit 1
fi

cosign verify-blob-attestation "${ARCHIVE}" \
  --bundle "${BUNDLE}" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  --certificate-identity "${CERT_IDENTITY}"

echo "Sigstore verification passed"
echo "Trivy ${VERSION} download verified in ${OUTPUT_DIR}"
