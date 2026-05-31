#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:-}"

if [[ -z "$TAG" ]]; then
  echo "Usage: scripts/publish_release.sh v1.1.0" >&2
  exit 1
fi

if [[ ! "$TAG" =~ ^v[0-9]+(\.[0-9]+){1,2}([-.][0-9A-Za-z]+)?$ ]]; then
  echo "error: tag should look like v1.1.0" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: GitHub CLI is required. Install it with: brew install gh" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "error: GitHub CLI is not logged in. Run: gh auth login" >&2
  exit 1
fi

if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ -n "$(git -C "$ROOT_DIR" status --porcelain)" ]]; then
    echo "warning: working tree has uncommitted changes"
  fi
fi

"$ROOT_DIR/scripts/build_release.sh"

ASSETS=()
while IFS= read -r asset; do
  ASSETS+=("$asset")
done < <(find "$ROOT_DIR/dist" -maxdepth 1 \( -name '*.zip' -o -name '*.dmg' -o -name 'SHA256SUMS.txt' \) -print | sort)

if [[ ${#ASSETS[@]} -eq 0 ]]; then
  echo "error: no release assets found in dist/" >&2
  exit 1
fi

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "==> Uploading assets to existing release $TAG"
  gh release upload "$TAG" "${ASSETS[@]}" --clobber
else
  echo "==> Creating release $TAG"
  gh release create "$TAG" "${ASSETS[@]}" --title "SubMergePro $TAG" --generate-notes
fi

echo "Published $TAG"
