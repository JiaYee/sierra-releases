<#
.SYNOPSIS
  Bump versions, build release APK, update version.json, commit to sierra-releases, and publish a GitHub Release.

.EXAMPLE
  .\release.ps1 -VersionName "1.0.1" -VersionCode 2 -Notes "Bug fixes."
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $VersionName,

  [Parameter(Mandatory = $true)]
  [int] $VersionCode,

  [string] $Notes = "",

  [int] $MinSupportedVersionCode = 1,

  [string] $AppRoot = "",

  [string] $GithubRepo = "JiaYee/sierra-releases",

  [switch] $SkipBuild
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  $enc = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Resolve-Gh {
  $cmd = Get-Command gh -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $p = Join-Path ${env:ProgramFiles} "GitHub CLI\gh.exe"
  if (Test-Path $p) { return $p }
  throw "GitHub CLI (gh) not found. Install with: winget install --id GitHub.cli -e"
}

$gh = Resolve-Gh
& $gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Run: gh auth login"
}

$releasesRoot = Split-Path $PSScriptRoot -Parent
if (-not $AppRoot) {
  $parent = Split-Path $releasesRoot -Parent
  $AppRoot = Join-Path $parent "sierra-v2"
}

if (-not (Test-Path (Join-Path $AppRoot "package.json"))) {
  throw "App root not found or invalid: $AppRoot (expected sierra-v2 next to sierra-releases)"
}

$tag = "v$VersionName"
$apkFileName = "sierra-v2-$VersionName.apk"
$apkUrl = "https://github.com/$GithubRepo/releases/download/$tag/$apkFileName"

$buildDir = Join-Path $releasesRoot "build"
if (-not (Test-Path $buildDir)) {
  New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
}

$destApk = Join-Path $buildDir $apkFileName
$versionJsonPath = Join-Path $releasesRoot "version.json"

if (-not $SkipBuild) {
  Write-Host "Updating app.json and build.gradle..." -ForegroundColor Cyan
  $appJsonPath = Join-Path $AppRoot "app.json"
  $raw = Get-Content $appJsonPath -Raw -Encoding UTF8
  $appJson = $raw | ConvertFrom-Json
  $appJson.expo.version = $VersionName
  if ($null -eq $appJson.expo.android.versionCode) {
    $appJson.expo.android | Add-Member -MemberType NoteProperty -Name versionCode -Value $VersionCode
  }
  else {
    $appJson.expo.android.versionCode = $VersionCode
  }
  Write-Utf8NoBom $appJsonPath (($appJson | ConvertTo-Json -Depth 30) + "`n")

  $gradlePath = Join-Path $AppRoot "android\app\build.gradle"
  $gradle = Get-Content $gradlePath -Raw
  $gradle = $gradle -replace 'versionCode\s+\d+', "versionCode $VersionCode"
  $gradle = $gradle -replace 'versionName\s+"[^"]*"', "versionName `"$VersionName`""
  Write-Utf8NoBom $gradlePath $gradle

  Write-Host "Running npm run android:gradle:release..." -ForegroundColor Cyan
  Push-Location $AppRoot
  try {
    npm run android:gradle:release
    if ($LASTEXITCODE -ne 0) { throw "Gradle release build failed." }
  }
  finally {
    Pop-Location
  }
}

$builtApk = Join-Path $AppRoot "android\app\build\outputs\apk\release\app-release.apk"
if (-not (Test-Path $builtApk)) {
  throw "APK not found: $builtApk (build release first or remove -SkipBuild)"
}

Copy-Item -Path $builtApk -Destination $destApk -Force
$hash = (Get-FileHash -Path $destApk -Algorithm SHA256).Hash.ToLowerInvariant()

$manifest = [ordered]@{
  versionCode             = $VersionCode
  versionName             = $VersionName
  apkUrl                  = $apkUrl
  sha256                  = $hash
  minSupportedVersionCode = $MinSupportedVersionCode
  notes                   = $Notes
  mandatory               = $false
}
Write-Utf8NoBom $versionJsonPath (($manifest | ConvertTo-Json -Depth 10) + "`n")

Write-Host "Wrote $versionJsonPath" -ForegroundColor Green

Push-Location $releasesRoot
try {
  if (-not (Test-Path ".git")) {
    throw "Not a git repo. Run: git init -b main; git remote add origin https://github.com/$GithubRepo.git"
  }
  git add version.json
  git diff --cached --quiet
  # Exit 1 = staged changes vs HEAD; 0 = nothing to commit
  if ($LASTEXITCODE -eq 1) {
    git commit -m "Release $tag"
    git push
  }
  else {
    Write-Host "No version.json changes to commit." -ForegroundColor Yellow
  }
}
finally {
  Pop-Location
}

Write-Host "Creating GitHub release $tag ..." -ForegroundColor Cyan
$notesArg = if ($Notes) { $Notes } else { "Release $tag" }
& $gh release create $tag $destApk $versionJsonPath --repo $GithubRepo --title $tag --notes $notesArg
if ($LASTEXITCODE -ne 0) {
  throw "gh release create failed. If the tag exists, delete the release or use a new version."
}

Write-Host ""
Write-Host "Done. Manifest: https://github.com/$GithubRepo/releases/latest/download/version.json" -ForegroundColor Green
