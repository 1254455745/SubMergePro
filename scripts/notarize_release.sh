#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
APP_PATH="${APP_PATH:-$DIST_DIR/SubMergePro.app}"

required_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "error: $name is required" >&2
    exit 1
  fi
}

required_env CODESIGN_IDENTITY
required_env APPLE_ID
required_env APPLE_TEAM_ID
required_env APPLE_APP_SPECIFIC_PASSWORD

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app not found at $APP_PATH" >&2
  echo "Run scripts/build_release.sh first." >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
ARTIFACT_BASENAME="SubMergePro-v$VERSION-build$BUILD-macOS"
NOTARY_ZIP="$DIST_DIR/$ARTIFACT_BASENAME-notary.zip"

echo "==> Signing app"
codesign \
  --force \
  --deep \
  --options runtime \
  --timestamp \
  --sign "$CODESIGN_IDENTITY" \
  "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose "$APP_PATH" || true

echo "==> Preparing notarization upload"
rm -f "$NOTARY_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARY_ZIP"

echo "==> Submitting to Apple notarization"
xcrun notarytool submit "$NOTARY_ZIP" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --wait

echo "==> Stapling notarization ticket"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "==> Repackaging signed artifacts"
rm -f "$DIST_DIR/$ARTIFACT_BASENAME.zip" "$DIST_DIR/$ARTIFACT_BASENAME.dmg"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$DIST_DIR/$ARTIFACT_BASENAME.zip"

DMG_ROOT="$ROOT_DIR/build/dmg-root-signed"
rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
cp -R "$APP_PATH" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create \
  -volname "SubMergePro" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$ARTIFACT_BASENAME.dmg"

(
  cd "$DIST_DIR"
  shasum -a 256 "$ARTIFACT_BASENAME.zip" "$ARTIFACT_BASENAME.dmg" > SHA256SUMS.txt
)

rm -f "$NOTARY_ZIP"

echo "==> Signed and notarized artifacts"
ls -lh "$DIST_DIR"
