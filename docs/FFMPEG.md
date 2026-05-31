# FFmpeg Notes

SubMergePro shells out to FFmpeg for subtitle burn-in and preview frame rendering.

## Local Installation

The recommended development setup is:

```bash
brew install ffmpeg
```

The app checks:

- Bundled `ffmpeg` inside the app resources
- `PATH`
- `/opt/homebrew/bin/ffmpeg`
- `/usr/local/bin/ffmpeg`
- `/usr/bin/ffmpeg`

## Distribution Choice

Current release artifacts do not bundle FFmpeg. Users should install FFmpeg separately.

This keeps app packages small and avoids mixing FFmpeg binary distribution concerns into the app release.

If you decide to bundle FFmpeg later:

- Add the FFmpeg binary to the app resources during build
- Make sure the bundled binary is executable
- Document exactly which FFmpeg build is shipped
- Include the relevant FFmpeg license notices in the release
- Confirm the selected FFmpeg build configuration matches your distribution plans

## Troubleshooting

If the app reports that FFmpeg cannot be found:

```bash
which ffmpeg
ffmpeg -version
```

If Homebrew installed FFmpeg but GUI launches still cannot find it, the app should still detect `/opt/homebrew/bin/ffmpeg` or `/usr/local/bin/ffmpeg`.
