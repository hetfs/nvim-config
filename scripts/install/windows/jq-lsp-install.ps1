$ErrorActionPreference = "Stop"

$version = "0.1.19"
$archiveName = "jq-lsp_${version}_windows_amd64.zip"
$downloadUrl = "https://github.com/wader/jq-lsp/releases/download/v${version}/${archiveName}"
$expectedHash = "c3fa28c183d9bc964ae036aec4781b2a8ed98c9a297ee0cf63019a3febc0d865"

$installDir = Join-Path $env:LOCALAPPDATA "Programs\jq-lsp"
$tempDir = Join-Path $env:TEMP "jq-lsp-install"
$archivePath = Join-Path $tempDir $archiveName

# Prepare temporary and installation directories.
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-Item -ItemType Directory -Path $installDir -Force | Out-Null

# Download the official Windows x64 release.
Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath

if (-not (Test-Path $archivePath -PathType Leaf)) {
    throw "Release archive was not downloaded."
}

# Verify the published SHA-256 checksum.
$actualHash = (Get-FileHash -Path $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()

if ($actualHash -ne $expectedHash) {
    throw "SHA-256 verification failed. Expected $expectedHash, received $actualHash."
}

Write-Host "SHA-256 verification passed." -ForegroundColor Green

# Extract and locate the executable.
Expand-Archive -Path $archivePath -DestinationPath $tempDir -Force

$binary = Get-ChildItem -Path $tempDir -Filter "jq-lsp.exe" -Recurse |
    Select-Object -First 1

if (-not $binary) {
    throw "jq-lsp.exe was not found in the release archive."
}

Copy-Item -Path $binary.FullName `
    -Destination (Join-Path $installDir "jq-lsp.exe") -Force

$installedBinary = Join-Path $installDir "jq-lsp.exe"

if (-not (Test-Path $installedBinary -PathType Leaf)) {
    throw "Installation failed: executable is missing."
}

# Add the installation directory to the user PATH.
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @($userPath -split ";" | Where-Object { $_ })

if ($installDir -notin $pathEntries) {
    $newPath = (@($pathEntries) + $installDir) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

# Make it available in this PowerShell session.
if (($env:PATH -split ";") -notcontains $installDir) {
    $env:PATH = "$installDir;$env:PATH"
}

Write-Host "`njq-lsp installation verified." -ForegroundColor Green
Write-Host "Version: $version"
Write-Host "Executable: $installedBinary"
Write-Host "PATH: $installDir"
