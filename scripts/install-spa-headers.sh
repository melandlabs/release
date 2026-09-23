#!/usr/bin/env bash
set -euo pipefail

# SPA is header-only. Keep Jammy's PipeWire shared library and glibc intact;
# only supply the video structure definitions expected by libspa 0.9.2.
prefix="${1:?Usage: install-spa-headers.sh ABSOLUTE_PREFIX}"
[[ "$prefix" = /* ]] || { echo "Prefix must be absolute" >&2; exit 1; }
version=0.3.65
sha256=bb76f938136d0ce8c35bffa99e002dc2dbaeab5e14c6c34154e7f750013d1d6b
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
curl --fail --location --retry 3 \
  "https://github.com/PipeWire/pipewire/archive/refs/tags/${version}.tar.gz" \
  --output "$temp_dir/pipewire.tar.gz"
echo "$sha256  $temp_dir/pipewire.tar.gz" | sha256sum --check --strict
tar -xzf "$temp_dir/pipewire.tar.gz" -C "$temp_dir"
mkdir -p "$prefix/include/spa-0.2" "$prefix/lib/pkgconfig"
cp -R "$temp_dir/pipewire-${version}/spa/include/spa" "$prefix/include/spa-0.2/"
cat > "$prefix/lib/pkgconfig/libspa-0.2.pc" <<EOF
prefix=$prefix
includedir=\${prefix}/include/spa-0.2

Name: libspa
Description: Pinned SPA headers for Ubuntu 22.04 builds (no runtime libraries)
Version: 0.2
Cflags: -I\${includedir} -D_REENTRANT
EOF
