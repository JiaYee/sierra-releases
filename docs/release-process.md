# Release Process

## Overview

Releases are **fully manual** — no CI or GitHub Actions. A PowerShell script in this repo orchestrates version bumping, APK building (in sierra-v2), manifest writing, git commit, and GitHub Release creation.

```mermaid
flowchart LR
  script["release.ps1"] -->|"1. bump versions"| app["sierra-v2 app.json + build.gradle"]
  script -->|"2. gradle build"| apk["app-release.apk"]
  script -->|"3. copy + sha256"| manifest["version.json"]
  script -->|"4. git commit + push"| git["this repo"]
  script -->|"5. gh release create"| gh["GitHub Releases"]
  client["sierra-v2 app"] -->|"fetch manifest + APK"| gh
```

## Prerequisites

1. **Sibling repo layout:**

   ```
   C:\Users\Tai\Crappy\
   ├── sierra-v2/           ← app source
   └── sierra-releases/     ← this repo
   ```

2. **GitHub CLI** authenticated:

   ```powershell
   gh auth login
   # Install if missing: winget install --id GitHub.cli -e
   ```

3. **Android release keystore** configured in sierra-v2 — see [ANDROID_RELEASE_SIGNING.md](../../sierra-v2/docs/ANDROID_RELEASE_SIGNING.md).

4. **Gradle build environment** — Android SDK, Java, native project generated (`npm run android` once in sierra-v2).

## Release command

Run from **sierra-v2** root:

```powershell
..\sierra-releases\scripts\release.ps1 `
  -VersionName "1.0.1" `
  -VersionCode 2 `
  -Notes "Description of changes."
```

## Script parameters

| Parameter | Required | Default | Purpose |
|-----------|----------|---------|---------|
| `-VersionName` | Yes | — | User-visible semver (e.g. `1.0.1`) |
| `-VersionCode` | Yes | — | Android `versionCode` integer (must increase monotonically) |
| `-Notes` | No | `""` | Release notes → manifest + GitHub release body |
| `-MinSupportedVersionCode` | No | `1` | Oldest supported client; below this → mandatory update |
| `-AppRoot` | No | `../sierra-v2` | Path to app repo |
| `-GithubRepo` | No | `JiaYee/sierra-releases` | Target GitHub repo |
| `-SkipBuild` | No | off | Skip version bump + Gradle build; use existing APK |

## Step-by-step (what `release.ps1` does)

1. Verify `gh` is installed and authenticated
2. Resolve sierra-v2 sibling path (or use `-AppRoot`)
3. Unless `-SkipBuild`:
   - Bump `expo.version` and `expo.android.versionCode` in `sierra-v2/app.json`
   - Bump `versionCode` / `versionName` in `sierra-v2/android/app/build.gradle`
   - Run `npm run android:gradle:release` in sierra-v2
4. Copy `android/app/build/outputs/apk/release/app-release.apk` → `build/sierra-v2-{VersionName}.apk`
5. Compute SHA-256 hash of APK
6. Write `version.json` with manifest fields
7. `git add version.json` → commit `"Release v{VersionName}"` → `git push` (if changed)
8. `gh release create v{VersionName} {apk} {version.json} --repo JiaYee/sierra-releases --title v{VersionName} --notes {Notes}`

## Versioning scheme

| Concept | Format | Example |
|---------|--------|---------|
| Git tag / GitHub Release | `v{VersionName}` | `v1.0.0` |
| APK filename | `sierra-v2-{VersionName}.apk` | `sierra-v2-1.0.0.apk` |
| Android versionCode | Monotonic integer | 1 |
| versionName | Semver string | `1.0.0` |

**versionCode must always increase** — the OTA client compares integer versionCodes.

## Smoke test after release

1. On a device with an older APK, open sierra-v2 → **Settings** → **Check for updates**
2. Or restart the app — `UpdatePrompt` checks on startup (Android only)
3. Confirm new version detected, APK downloads and installs

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| `gh auth login` required | Authenticate GitHub CLI |
| App root not found | Ensure sierra-v2 is sibling directory |
| Gradle build failed | Check keystore, Android SDK, run `npm run android` once |
| APK not found | Build failed or wrong output path |
| `gh release create` failed — tag exists | Delete existing release/tag or use new version |
| OTA install fails | Signing key must match previous releases |
| App doesn't detect update | Verify `versionCode` increased; check manifest URL |

## Skip-build workflow

To republish an existing APK without rebuilding:

```powershell
..\sierra-releases\scripts\release.ps1 `
  -VersionName "1.0.1" `
  -VersionCode 2 `
  -Notes "Re-publish." `
  -SkipBuild
```

Requires existing `app-release.apk` in sierra-v2's Gradle output directory.

## Git-tracked files

- `.gitignore`
- `README.md`
- `AGENTS.md`
- `scripts/release.ps1`
- `version.json`
- `docs/`

APKs in `build/` are gitignored. Release assets live on GitHub Releases.
