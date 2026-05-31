#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/SubMergeProMac.xcodeproj"
SCHEME="SubMergeProMac"
CONFIGURATION="Release"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
PRODUCTS_DIR="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION"
APP_PRODUCT_NAME="SubMergeProMac.app"
APP_DISPLAY_NAME="SubMergePro.app"

echo "==> Cleaning release output"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "==> Building $SCHEME ($CONFIGURATION)"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$PRODUCTS_DIR/$APP_PRODUCT_NAME"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app not found at $APP_PATH" >&2
  exit 1
fi

PACKAGED_APP="$DIST_DIR/$APP_DISPLAY_NAME"
cp -R "$APP_PATH" "$PACKAGED_APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PACKAGED_APP/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PACKAGED_APP/Contents/Info.plist")"
ARTIFACT_BASENAME="SubMergePro-v$VERSION-build$BUILD-macOS"

echo "==> Creating zip"
ditto -c -k --sequesterRsrc --keepParent "$PACKAGED_APP" "$DIST_DIR/$ARTIFACT_BASENAME.zip"

echo "==> Creating dmg"
DMG_ROOT="$ROOT_DIR/build/dmg-root"
rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
cp -R "$PACKAGED_APP" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create \
  -volname "SubMergePro" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$ARTIFACT_BASENAME.dmg"

echo "==> Writing checksums"
(
  cd "$DIST_DIR"
  shasum -a 256 "$ARTIFACT_BASENAME.zip" "$ARTIFACT_BASENAME.dmg" > SHA256SUMS.txt
)

echo "==> Release artifacts"
ls -lh "$DIST_DIR"
