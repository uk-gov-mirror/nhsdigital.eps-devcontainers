#!/usr/bin/env bash
# Script to run as devcontainer postCreateCommand
set -euo pipefail

echo "Running common post-create script"


# Install git-secrets, register AWS patterns and NHS rules in an idempotent way
if ! git config --get-all secrets.patterns | grep -Fq AKIA; then
  git-secrets --register-aws
fi
if ! git config --get-all secrets.providers | grep -Fxq "cat /usr/share/secrets-scanner/nhsd-rules-deny.txt"; then
  git-secrets --add-provider -- cat /usr/share/secrets-scanner/nhsd-rules-deny.txt
fi
