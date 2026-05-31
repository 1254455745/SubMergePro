# Releasing SubMergePro

This project supports two release paths:

- GitHub Actions release from a version tag
- Local release with GitHub CLI

## Versioning

Use semantic versions such as `1.1.0`.

Update the app version and build number:

```bash
scripts/bump_version.sh 1.1.0
```

Specify a build number manually:

```bash
scripts/bump_version.sh 1.1.0 12
```

The script updates `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the Xcode project.

## Preflight

```bash
make doctor
swift build
make xcode-build
make release
```

Check the files in `dist/`:

```bash
ls -lh dist
shasum -a 256 -c dist/SHA256SUMS.txt
```

## GitHub Actions Release

```bash
scripts/bump_version.sh 1.1.0
git add .
git commit -m "Release 1.1.0"
git tag v1.1.0
git push origin main --tags
```

Pushing the tag starts `.github/workflows/release.yml`.

The workflow builds:

- `SubMergePro-v<version>-build<build>-macOS.zip`
- `SubMergePro-v<version>-build<build>-macOS.dmg`
- `SHA256SUMS.txt`

## Local Release

Install and log into GitHub CLI:

```bash
brew install gh
gh auth login
```

Create or update a release:

```bash
scripts/publish_release.sh v1.1.0
```

## Signing and Notarization

Unsigned builds are fine for testing, but public distribution is smoother when the app is signed and notarized with an Apple Developer ID certificate.

The optional script below signs `dist/SubMergePro.app`, submits it to Apple notarization, staples the result, and repackages `zip` and `dmg` artifacts:

```bash
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="TEAMID"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

scripts/notarize_release.sh
```

Do not commit Apple credentials. Store them in a local password manager or GitHub Actions secrets if you later automate notarization.
