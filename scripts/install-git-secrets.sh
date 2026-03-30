#!/bin/bash
if ! git config --get-all secrets.patterns | grep -Fq AKIA; then
  git-secrets --register-aws
fi
if ! git config --get-all secrets.providers | grep -Fxq "cat /usr/share/secrets-scanner/nhsd-rules-deny.txt"; then
  git-secrets --add-provider -- cat /usr/share/secrets-scanner/nhsd-rules-deny.txt
fi
