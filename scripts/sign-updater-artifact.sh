#!/usr/bin/env bash
# Sign files for alloomi's auto-updater (tauri-plugin-updater).
#
# Usage:
#   bash scripts/sign-updater-artifact.sh <file>...
#
# Writes <file>.sig next to each file. The signature covers the exact bytes
# that get uploaded, so call this on the FINAL artifact — after the optimizer,
# Developer ID signing and stapling are done — never on an intermediate.
#
# The updater verifies every download against the public key compiled into
# the client (alloomi apps/web/src-tauri/tauri.conf.json,
# plugins.updater.pubkey); a release signed with any other key cannot be
# installed by auto-update. The key is not the Apple certificate.
#
# Environment:
#   TAURI_SIGNING_PRIVATE_KEY           private key contents (required)
#   TAURI_SIGNING_PRIVATE_KEY_PASSWORD  its password (required; the tauri CLI
#                                       cannot sign with an empty-password key)
#   ALLOOMI_DIR                         alloomi checkout, default ./alloomi
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "sign-updater-artifact: no files given" >&2
  exit 2
fi
if [ -z "${TAURI_SIGNING_PRIVATE_KEY:-}" ] || [ -z "${TAURI_SIGNING_PRIVATE_KEY_PASSWORD:-}" ]; then
  echo "sign-updater-artifact: TAURI_SIGNING_PRIVATE_KEY and TAURI_SIGNING_PRIVATE_KEY_PASSWORD must be set" >&2
  echo "  (repository secrets; see the header of .github/workflows/r2-upload.yml)" >&2
  exit 1
fi

ALLOOMI_DIR="${ALLOOMI_DIR:-alloomi}"
TAURI_CLI="${ALLOOMI_DIR}/node_modules/@tauri-apps/cli/tauri.js"
if [ ! -f "${TAURI_CLI}" ]; then
  echo "sign-updater-artifact: tauri CLI not found at ${TAURI_CLI}" >&2
  exit 1
fi

for file in "$@"; do
  if [ ! -s "${file}" ]; then
    echo "sign-updater-artifact: ${file} is missing or empty" >&2
    exit 1
  fi
  rm -f "${file}.sig"
  # The CLI reads the key and password from the environment, so neither ever
  # appears in a process argument list.
  node "${TAURI_CLI}" signer sign "${file}"
  if [ ! -s "${file}.sig" ]; then
    echo "sign-updater-artifact: tauri signer produced no signature for ${file}" >&2
    exit 1
  fi
  echo "signed: ${file}.sig"
done
