#!/usr/bin/env bash
# Package the final macOS .app as the auto-updater archive and sign it.
#
# Usage:
#   bash scripts/pack-macos-updater.sh <path/to/Alloomi.app> <output.app.tar.gz>
#
# Run it on the same, final .app the DMG was built from (after the optimizer
# re-signed it): the archive replaces the installed bundle wholesale, so it has
# to be byte-for-byte the app new users get from the DMG. The CDHash check
# below enforces that the archive holds exactly that code signature.
#
# Signing uses scripts/sign-updater-artifact.sh (see there for the
# environment it needs) and writes <output>.sig.
set -euo pipefail

APP="${1:?usage: pack-macos-updater.sh <app> <output.app.tar.gz>}"
OUT="${2:?usage: pack-macos-updater.sh <app> <output.app.tar.gz>}"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "${APP}" ]; then
  echo "pack-macos-updater: ${APP} is not a directory" >&2
  exit 1
fi

cdhash() {
  # codesign -d reports on stderr.
  codesign -dvvv "$1" 2>&1 | sed -n 's/^CDHash=//p'
}

# The plugin drops the first path component on extraction, so the archive
# root must be the .app directory itself. COPYFILE_DISABLE keeps macOS tar from
# adding AppleDouble ._* entries.
rm -f "${OUT}" "${OUT}.sig"
COPYFILE_DISABLE=1 tar -czf "${OUT}" -C "$(dirname "${APP}")" "$(basename "${APP}")"

SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT
tar -xzf "${OUT}" -C "${SCRATCH}"
EXTRACTED="${SCRATCH}/$(basename "${APP}")"
codesign --verify --deep --strict "${EXTRACTED}"
SOURCE_HASH="$(cdhash "${APP}")"
ARCHIVE_HASH="$(cdhash "${EXTRACTED}")"
if [ -z "${SOURCE_HASH}" ] || [ "${SOURCE_HASH}" != "${ARCHIVE_HASH}" ]; then
  echo "pack-macos-updater: CDHash mismatch (app '${SOURCE_HASH}', archive '${ARCHIVE_HASH}')" >&2
  exit 1
fi
echo "archive verified: CDHash ${SOURCE_HASH}, $(du -h "${OUT}" | cut -f1)"

bash "${HERE}/sign-updater-artifact.sh" "${OUT}"
