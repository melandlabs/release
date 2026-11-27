#!/usr/bin/env bash
#
# Stage the CN client artifacts on the CN box, so the publish job does not
# have to download them.
#
# Why: the box reaches GitHub's artifact storage at ~20 KB/s, so downloading
# the 1.5 GB artifact set there would take days. The artifacts are fetched on
# a machine that has GitHub access and pushed to the box instead; the publish
# workflow then works from the staged copy.
#
# The files keep the names the CI produced (Alloomi_0.6.17-nightly.<date>_
# amd64.deb and friends): the publish workflow renames them into the names
# the client actually requests.
#
# Usage: scripts/stage-cn-artifacts.sh <artifact>...

set -euo pipefail

BOX="${CN_BOX_HOST:-alloomi-tx}"
STAGING_DIR="${CN_BOX_STAGING_DIR:-/opt/oo/staging}"

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <artifact>..." >&2
  exit 1
fi

echo "[stage-cn-artifacts] staging $# file(s) on $BOX:$STAGING_DIR"
ssh "$BOX" "sudo mkdir -p '$STAGING_DIR' && sudo chown ubuntu '$STAGING_DIR'"
scp "$@" "$BOX:$STAGING_DIR/"
ssh "$BOX" "ls -la '$STAGING_DIR'"
