#!/usr/bin/env python3
"""Verify updater artifacts and write the per-platform update pointers.

alloomi's auto-updater (tauri-plugin-updater, see alloomi
apps/web/src-tauri/src/update.rs `manifest_endpoint`) reads one pointer per
flavor, channel and platform:

    updater/<flavor>/<channel>/<target>-<arch>.json
    {"version", "pub_date", "url", "signature"}

One file per platform means a partial publish (the outlook-china variant)
moves only the platforms it uploaded, and the two flavors never share a file.

Usage:
    updater_pointers.py check <artifacts_dir> <prefix> <version> [--require-all]
    updater_pointers.py write <artifacts_dir> <prefix> <version> <flavor>
                              <channel> <base_url> <out_dir>

`check` runs before anything is uploaded: every installer present must come
with its updater payload and signature. `write` runs after the upload, so a
client can never see a pointer whose files are not in the bucket yet.
"""

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

# (updater target, installer, updater payload). macOS updates by replacing the
# whole .app from an archive; Windows and Linux run the installer itself, so
# the payload is the installer and only gains a signature.
PLATFORMS = [
    ("darwin-aarch64", "{p}{v}_macOS_aarch64.dmg", "{p}{v}_macOS_aarch64.app.tar.gz"),
    ("darwin-x86_64", "{p}{v}_macOS_amd64.dmg", "{p}{v}_macOS_amd64.app.tar.gz"),
    ("windows-x86_64", "{p}{v}_windows_amd64.exe", "{p}{v}_windows_amd64.exe"),
    ("linux-x86_64", "{p}{v}_linux_amd64.deb", "{p}{v}_linux_amd64.deb"),
    ("linux-aarch64", "{p}{v}_linux_aarch64.deb", "{p}{v}_linux_aarch64.deb"),
]

FLAVORS = ("alloomi", "outlook_china")

# The client compares this field with semver; anything else (e.g. a version
# derived from a CI-named file like Alloomi_ci_<sha>_aarch64.dmg) would make
# every pointer unusable.
SEMVER = re.compile(r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$")
CHANNELS = ("stable", "beta", "nightly")


def present_platforms(artifacts: Path, prefix: str, version: str):
    """Return (target, payload_name, signature) for each installer present.

    Raises SystemExit naming every incomplete platform at once.
    """
    if not SEMVER.match(version):
        sys.exit(f"version {version!r} is not semver; pass the version input explicitly")
    problems = []
    found = []
    for target, installer, payload in PLATFORMS:
        installer_name = installer.format(p=prefix, v=version)
        payload_name = payload.format(p=prefix, v=version)
        if not (artifacts / installer_name).is_file():
            continue
        sig_path = artifacts / f"{payload_name}.sig"
        if not (artifacts / payload_name).is_file():
            problems.append(f"{target}: missing updater payload {payload_name}")
            continue
        if not sig_path.is_file() or not sig_path.read_text().strip():
            problems.append(f"{target}: missing or empty signature {sig_path.name}")
            continue
        found.append((target, payload_name, sig_path.read_text().strip()))
    if problems:
        sys.exit("updater artifacts incomplete:\n  " + "\n  ".join(problems))
    return found


def check(artifacts: Path, prefix: str, version: str, require_all: bool):
    found = present_platforms(artifacts, prefix, version)
    if require_all and len(found) != len(PLATFORMS):
        have = {target for target, _, _ in found}
        missing = [target for target, _, _ in PLATFORMS if target not in have]
        sys.exit(f"updater artifacts incomplete: no installer for {', '.join(missing)}")
    if not found:
        sys.exit("updater artifacts incomplete: no installers found")
    for target, payload, _ in found:
        print(f"ok: {target} -> {payload} (+ .sig)")


def write(artifacts: Path, prefix: str, version: str, flavor: str,
          channel: str, base_url: str, out_dir: Path):
    if flavor not in FLAVORS:
        sys.exit(f"unknown flavor: {flavor}")
    if channel not in CHANNELS:
        sys.exit(f"unknown channel: {channel}")
    found = present_platforms(artifacts, prefix, version)
    pointer_dir = out_dir / "updater" / flavor / channel
    pointer_dir.mkdir(parents=True, exist_ok=True)
    pub_date = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    for target, payload, signature in found:
        pointer = {
            "version": version,
            "pub_date": pub_date,
            "url": f"{base_url.rstrip('/')}/{payload}",
            "signature": signature,
        }
        path = pointer_dir / f"{target}.json"
        path.write_text(json.dumps(pointer, indent=2) + "\n")
        print(f"wrote: {path.relative_to(out_dir)} -> {version}")


def main(argv):
    if len(argv) >= 4 and argv[0] == "check":
        check(Path(argv[1]), argv[2], argv[3], "--require-all" in argv[4:])
    elif len(argv) == 8 and argv[0] == "write":
        write(Path(argv[1]), argv[2], argv[3], argv[4], argv[5], argv[6], Path(argv[7]))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
