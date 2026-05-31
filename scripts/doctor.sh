#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXIT_CODE=0

pass() {
  printf "ok   %s\n" "$1"
}

warn() {
  printf "warn %s\n" "$1"
}

fail() {
  printf "fail %s\n" "$1"
  EXIT_CODE=1
}

check_command() {
  local command_name="$1"
  local install_hint="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    pass "$command_name: $(command -v "$command_name")"
  else
    fail "$command_name not found. $install_hint"
  fi
}

echo "SubMergePro environment check"
echo "Root: $ROOT_DIR"
echo ""

check_command git "Install Xcode Command Line Tools."
check_command xcodebuild "Install Xcode from the App Store or developer.apple.com."
check_command swift "Install Xcode from the App Store or developer.apple.com."
check_command hdiutil "hdiutil should be available on macOS."

if command -v ffmpeg >/dev/null 2>&1; then
  pass "ffmpeg: $(command -v ffmpeg)"
else
  warn "ffmpeg not found in PATH. Install it with: brew install ffmpeg"
fi

if command -v gh >/dev/null 2>&1; then
  pass "gh: $(command -v gh)"
  if gh auth status >/dev/null 2>&1; then
    pass "GitHub CLI authenticated"
  else
    warn "GitHub CLI is installed but not authenticated. Run: gh auth login"
  fi
else
  warn "GitHub CLI not found. Install it with: brew install gh"
fi

if [[ -d "$ROOT_DIR/SubMergeProMac.xcodeproj" ]]; then
  pass "Xcode project found"
else
  fail "SubMergeProMac.xcodeproj not found"
fi

if [[ -f "$ROOT_DIR/SubMergeProMac.xcodeproj/xcshareddata/xcschemes/SubMergeProMac.xcscheme" ]]; then
  pass "shared Xcode scheme found"
else
  fail "shared Xcode scheme missing"
fi

echo ""
if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "Environment looks ready."
else
  echo "Environment needs attention."
fi

exit "$EXIT_CODE"
