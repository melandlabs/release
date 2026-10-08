#!/usr/bin/env bash
# Stamp today's UTC date onto the date-keyed nightly prerelease.
#
# Usage:
#   bash scripts/bump-nightly-version.sh [alloomi_dir]   # default: ./alloomi
#
# alloomi pins nightly builds as `<base>-nightly.<YYYYMMDD>` so the numeric
# prerelease identifier orders correctly through semver -- which means the date
# suffix is a hand-maintained counter that silently goes stale: two builds on the
# same day publish the same version string, and every later day needs a bump
# commit that nobody remembers to make. This rewrites the date in the CI
# checkout right after the clone, so each build carries its own date.
#
# The bump is a property of the build, not of the source, so it is deliberately
# NOT written back to the alloomi repo.
#
# A non-nightly version -- a real release like `0.6.7` -- is left untouched.
# That string is what gets published, and appending a date would invent a
# release that was never cut.
#
# Prints the effective version on stdout and, under Actions, exposes it as the
# step output `version`.
set -euo pipefail

REPO="${1:-alloomi}"
TAURI_CONF="${REPO}/apps/web/src-tauri/tauri.conf.json"

if [ ! -f "${TAURI_CONF}" ]; then
  echo "bump-nightly-version: ${TAURI_CONF} not found" >&2
  exit 1
fi

# Fixed list rather than a repo-wide grep: these are the files that carry the
# release identity (Tauri bundle + updater manifests, the Rust crate, and the
# workspace packages wired via workspace:*). Anything else mentioning a version
# is prose.
python3 - "${REPO}" "${TAURI_CONF}" "$(date -u +%Y%m%d)" <<'PY'
import json, os, re, sys

repo, tauri_conf, today = sys.argv[1], sys.argv[2], sys.argv[3]

# `<base>-nightly.<8 digits>` and nothing else. A stable release, a git tag or a
# hand-rolled suffix must survive untouched.
NIGHTLY = re.compile(r"^(.+)-nightly\.\d{8}$")

JSON_FILES = [
    "apps/web/src-tauri/tauri.conf.json",
    "apps/web/src-tauri/tauri.conf.dev.json",
    "apps/web/src-tauri/tauri.conf.cn.json",
    "apps/web/src-tauri/tauri.conf.intl.json",
    "package.json",
    "apps/web/package.json",
    "packages/billing/package.json",
    "packages/i18n/package.json",
    "packages/integrations/package.json",
]
CARGO_FILE = "apps/web/src-tauri/Cargo.toml"


def bump(match):
    return f"{match.group(1)}-nightly.{today}"


def rewrite_json(rel):
    """Replace the file's own `version` string, leaving formatting alone."""
    path = os.path.join(repo, rel)
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    updated = re.sub(
        r'("version"\s*:\s*")([^"]+)(")',
        lambda m: m.group(1) + NIGHTLY.sub(bump, m.group(2)) + m.group(3),
        text,
        count=1,
    )
    if updated == text:
        return None
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(updated)
    return json.loads(updated)["version"]


def rewrite_cargo(rel):
    """Same, but only for the [package] table -- dependencies have their own."""
    path = os.path.join(repo, rel)
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().splitlines(keepends=True)

    table, updated = None, False
    for i, line in enumerate(lines):
        header = re.match(r"\s*\[([^\]]+)\]", line)
        if header:
            table = header.group(1)
            continue
        if table != "package":
            continue
        def repl(m, _i=i):
            return m.group(1) + NIGHTLY.sub(bump, m.group(2)) + m.group(3)
        new = re.sub(r'(version\s*=\s*")([^"]+)(")', repl, line, count=1)
        updated |= new != line
        lines[i] = new

    if not updated:
        return None
    with open(path, "w", encoding="utf-8") as fh:
        fh.writelines(lines)
    for line in lines:
        if re.match(r"version\s*=", line):
            return re.search(r'"([^"]+)"', line).group(1)
    return None


effective = json.load(open(tauri_conf, encoding="utf-8"))["version"]
if not NIGHTLY.match(effective):
    print(f"bump-nightly-version: {effective} is not a nightly build, leaving as-is")
    sys.exit(0)

print(f"bump-nightly-version: {effective} -> re-stamped to {today}")
for rel in JSON_FILES:
    new = rewrite_json(rel)
    if new:
        print(f"  {rel}: {new}")
new = rewrite_cargo(CARGO_FILE)
if new:
    print(f"  {CARGO_FILE}: {new}")

# Re-read rather than recomputing: this is the string the Tauri bundle, the DMG
# filenames and the updater manifest will actually carry.
effective = json.load(open(tauri_conf, encoding="utf-8"))["version"]
print(f"bump-nightly-version: effective version {effective}")
PY

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  effective=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "${TAURI_CONF}")
  echo "version=${effective}" >> "${GITHUB_OUTPUT}"
fi
