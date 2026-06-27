# sierra-releases

Public release artifacts for **Sierra** (Android APKs and update manifest).

Application source code lives in a private repository; this repo exists only to host **versioned APK downloads** and `version.json` for over-the-air updates.

## Manifest URL (used by the app)

```
https://github.com/JiaYee/sierra-releases/releases/latest/download/version.json
```

## Publishing a release

From the app project (`sierra-v2` sibling folder), run:

```powershell
..\sierra-releases\scripts\release.ps1 `
  -VersionName "1.0.1" `
  -VersionCode 2 `
  -Notes "Bug fixes and improvements."
```

Prerequisites:

1. [GitHub CLI](https://cli.github.com/) installed and authenticated: `gh auth login`
2. Android release signing configured (see `sierra-v2/docs/ANDROID_RELEASE_SIGNING.md`)

Full workflow and troubleshooting: see `docs/release-process.md` and `sierra-v2/docs/RELEASES.md`.
