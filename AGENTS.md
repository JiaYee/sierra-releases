# sierra-releases — Agent Guide

**Public Android OTA distribution channel** for Sierra. This repo holds the update manifest (`version.json`), release automation script, and docs — **not** application source code. APK binaries are published to **GitHub Releases**, never committed to git.

## What this repo is

| Contains | Does not contain |
|----------|------------------|
| `version.json` OTA manifest | Application source code |
| `scripts/release.ps1` automation | `package.json` or npm scripts |
| GitHub Release APK assets | CI / GitHub Actions |
| Release documentation | Electron/desktop builds |

## Tech stack

| Component | Technology |
|-----------|------------|
| Manifest | JSON |
| Release script | PowerShell |
| Publishing | GitHub CLI (`gh release create`) |
| Binary hosting | GitHub Releases |

Build toolchain lives in sibling **sierra-v2** (Expo/React Native Android Gradle).

## Release command

Run from **sierra-v2** root (not this repo):

```powershell
..\sierra-releases\scripts\release.ps1 `
  -VersionName "1.0.1" `
  -VersionCode 2 `
  -Notes "Description of changes."
```

Prerequisites: `gh auth login`, Android release keystore in sierra-v2, both repos as siblings.

## OTA fetch URL

```
https://github.com/JiaYee/sierra-releases/releases/latest/download/version.json
```

Consumed by sierra-v2 `src/updates.ts`.

## Gotchas

- **No `package.json`** — don't look for npm scripts here.
- **APKs are gitignored** — stored on GitHub Releases + local `build/` cache.
- **Builds happen in sierra-v2** — this repo only publishes artifacts.
- **Signing is critical** — configured entirely in sierra-v2, not here.
- **sha256 in manifest is not verified** by the app after download.

## Ecosystem

```
sierra-v2 ──build APK──► release.ps1 ──publish──► GitHub Releases
sierra-v2 ──fetch version.json + APK──► this repo's releases
```

## Documentation

See [docs/README.md](docs/README.md) for the full index.

- [Release process](docs/release-process.md)
- [Manifest schema](docs/manifest.md)

Extended workflow docs in sierra-v2: [docs/RELEASES.md](../sierra-v2/docs/RELEASES.md), [docs/ANDROID_RELEASE_SIGNING.md](../sierra-v2/docs/ANDROID_RELEASE_SIGNING.md).
