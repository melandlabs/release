#!/usr/bin/env bash
# Reclaim runner disk before the macOS desktop build.
#
# GitHub-hosted macOS runners are documented at 14 GB of free disk, and a cold
# `pnpm tauri:build` peaks well past that: the pnpm store plus a hoisted
# node_modules, the Rust target restored from cache, the GStreamer SDK, the
# webpack cache restored into .next/cache, and finally the file-tracing copy
# into .next/standalone. On 2026-10-12 ci-alloomi-macos-arm64 hit ENOSPC twice
# -- the second run so completely that the runner worker could not append to
# its own diagnostic log ("No space left on device: _diag/Worker_*.log").
#
# The image is the cheapest place to get that space back: the stock macOS
# runners preinstall a dozen Xcode copies and the iOS/watchOS simulator
# runtimes, none of which this job touches. Everything signing-related lives in
# the default Xcode under Contents/Developer/usr/bin (codesign, hdiutil, xcrun
# notarytool) and works without any simulator platform installed.
#
# Pruning is best-effort: a path that is already gone, or that the image no
# longer ships, is skipped. What is NOT best-effort is the free-space check at
# the end -- if pruning was not enough, fail here with a clear message instead
# of two hours into the build with an opaque ENOSPC.
#
# Usage: bash scripts/free-macos-build-disk.sh
#   MIN_FREE_GB  required free space on the workspace volume (default 20)
set -euo pipefail

MIN_FREE_GB="${MIN_FREE_GB:-20}"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "free-macos-build-disk: no-op on $(uname -s)"
  exit 0
fi

WORKSPACE="${GITHUB_WORKSPACE:-$PWD}"
MOUNT="$(df -k "$WORKSPACE" | awk 'NR == 2 { print $1 }')"
free_gb() { df -k "$MOUNT" | awk 'NR == 2 { printf "%d", $4 / 1048576 }'; }

# Real path of the selected Xcode, so we never delete the one `xcode-select`
# points at -- on some image revisions /Applications/Xcode.app is a symlink
# into one of the versioned copies we are about to prune. Resolve the app
# root (not Contents/Developer) so it compares equal to the candidate.
default_xcode=""
if [ -d /Applications/Xcode.app ]; then
  default_xcode="$(cd /Applications/Xcode.app && pwd -P)"
fi

targets=()
add() {
  for candidate in "$@"; do
    # Unset globs stay literal and simply do not match anything below.
    [ -e "$candidate" ] || continue
    resolved="$(cd "$candidate" 2>/dev/null && pwd -P || echo "$candidate")"
    if [ -n "$default_xcode" ] && [ "$resolved" = "$default_xcode" ]; then
      echo "  keeping $(basename "$candidate") (selected Xcode)"
      continue
    fi
    targets+=("$candidate")
  done
}

# Non-default Xcode copies. macos-15 selects 15.4 under /Applications/Xcode.app
# and ships 15.0 through 16.2 alongside it; macos-14 shipped a dozen including
# four 26.x releases. Nothing in this workflow sets DEVELOPER_DIR or calls
# xcodebuild, so only the selected copy has to survive.
add /Applications/Xcode_*.app

# iOS/watchOS/tvOS simulator runtimes and device types.
add /Library/Developer/CoreSimulator/Profiles/Runtimes/* \
    /Library/Developer/CoreSimulator/Profiles/DeviceTypes/* \
    "$HOME"/Library/Developer/CoreSimulator/Profiles/Runtimes/* \
    "$HOME"/Library/Developer/CoreSimulator/Profiles/DeviceTypes/*

# Android. Tauri's iOS/Android bundlers are not part of this build.
add "/Applications/Android Studio.app" \
    /usr/local/share/android-sdk \
    "$HOME"/Library/Android

# Download caches the toolchain steps refetch from the network anyway. Homebrew
# itself stays -- `brew install meson ninja pkgconf` runs after this. The npm
# cache stays too: pnpm/action-setup shells out to npm to install pnpm.
add "$HOME"/Library/Caches/Homebrew \
    "$HOME"/Library/Caches/CocoaPods \
    "$HOME"/.cocoapods

before="$(free_gb)"
echo "free-macos-build-disk: $MOUNT has ${before} GB free, pruning ${#targets[@]} path(s)"

if [ "${#targets[@]}" -gt 0 ]; then
  printf 'free-macos-build-disk: %s\n' "${targets[@]}"
  # Parallel: each Xcode copy is a few hundred thousand files, and the runner
  # has the cores to spare while we wait.
  for target in "${targets[@]}"; do
    rm -rf "$target" &
  done
  wait || true
fi

sync
after="$(free_gb)"
echo "free-macos-build-disk: ${after} GB free (was ${before} GB)"
df -h "$MOUNT"

if [ "$after" -lt "$MIN_FREE_GB" ]; then
  cat >&2 <<EOF
ERROR: only ${after} GB free on ${MOUNT}, need at least ${MIN_FREE_GB} GB for the
       macOS build. The runner image changed or the prune list needs updating.
       Raise MIN_FREE_GB only if the build genuinely fits in less space.
EOF
  exit 1
fi