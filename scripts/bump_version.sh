#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/SubMergeProMac.xcodeproj/project.pbxproj"

usage() {
  cat <<'USAGE'
Usage:
  scripts/bump_version.sh <version> [build]

Examples:
  scripts/bump_version.sh 1.1.0
  scripts/bump_version.sh 1.1.0 12
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

VERSION="$1"
BUILD="${2:-$(date +%Y%m%d%H%M)}"

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}([-.][0-9A-Za-z]+)?$ ]]; then
  echo "error: version should look like 1.1.0" >&2
  exit 1
fi

if [[ ! "$BUILD" =~ ^[0-9A-Za-z.-]+$ ]]; then
  echo "error: build contains unsupported characters" >&2
  exit 1
fi

perl -0pi -e "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = $VERSION;/g" "$PROJECT_FILE"
perl -0pi -e "s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = $BUILD;/g" "$PROJECT_FILE"

echo "Updated version to $VERSION ($BUILD)"
