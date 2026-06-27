# sierra-releases — Documentation Index

Documentation optimized for AI coding agents working on the Sierra OTA release channel.

## What this repo does

Publishes Android APK updates for **sierra-v2** devices. The app checks a manifest URL on startup and in Settings to download and install newer APKs.

## Quick reference

| Item | Value |
|------|-------|
| Manifest URL | `https://github.com/JiaYee/sierra-releases/releases/latest/download/version.json` |
| GitHub repo | `JiaYee/sierra-releases` |
| Release script | `scripts/release.ps1` |
| App source | Sibling repo `../sierra-v2` |

## Agent docs

| Document | Contents |
|----------|----------|
| [release-process.md](release-process.md) | Full release workflow, script parameters, prerequisites |
| [manifest.md](manifest.md) | `version.json` schema and OTA client behavior |

## Related repos

| Repo | Role |
|------|------|
| [sierra-v2](../sierra-v2) | App source — builds APK, consumes OTA manifest |

## Extended docs (in sierra-v2)

| Document | Contents |
|----------|----------|
| [sierra-v2/docs/RELEASES.md](../sierra-v2/docs/RELEASES.md) | Full OTA publish + smoke-test workflow |
| [sierra-v2/docs/ANDROID_RELEASE_SIGNING.md](../sierra-v2/docs/ANDROID_RELEASE_SIGNING.md) | Keystore setup for production APKs |

## Human-readable docs

See also the root [README.md](../README.md).
