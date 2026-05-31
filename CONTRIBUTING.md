# Contributing

Thanks for helping improve SubMergePro.

## Development Setup

1. Install Xcode.
2. Install FFmpeg:

   ```bash
   brew install ffmpeg
   ```

3. Open the Xcode project:

   ```bash
   open SubMergeProMac.xcodeproj
   ```

## Checks

Before opening a pull request, run:

```bash
make doctor
swift build
xcodebuild -project SubMergeProMac.xcodeproj -scheme SubMergeProMac -configuration Debug -destination 'platform=macOS' build
```

## Pull Requests

- Keep changes focused.
- Describe the user-facing behavior change.
- Include screenshots or screen recordings for visible UI changes.
- Update `README.md` or `CHANGELOG.md` when behavior, setup, or release steps change.

## Releases

Use semantic versions such as `1.1.0`.

```bash
scripts/bump_version.sh 1.1.0
git add .
git commit -m "Release 1.1.0"
git tag v1.1.0
git push origin main --tags
```
