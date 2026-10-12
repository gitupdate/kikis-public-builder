#!/usr/bin/env bash
set -euo pipefail
encrypted="${1:?Usage: decrypt-ipa.sh ENCRYPTED_FILE [OUTPUT_FILE]}"
password_file="${KIKIS_PASSWORD_FILE:-$HOME/.config/kikis-public-builder/ipa-password}"
output="${2:-${encrypted%.enc}}"
test -f "$password_file" || { echo "Password file missing: $password_file" >&2; exit 1; }
test "$encrypted" != "$output" || { echo "Output must differ from input" >&2; exit 1; }
umask 077
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -in "$encrypted" -out "$output" -pass "file:$password_file"
echo "Decrypted: $output"

