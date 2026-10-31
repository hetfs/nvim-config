$ErrorActionPreference = "Stop"

$version = "0.1.19"
$archiveName = "jq-lsp_${version}_windows_amd64.zip"
$downloadUrl = "https://github.com/wader/jq-lsp/releases/download/v${version}/${archiveName}"
$expectedHash = "c3fa28c183d9bc964ae036aec4781b2a8ed98c9a297ee0cf63019a3febc0d865"

$installDir = Join-Path $env:LOCALAPPDATA "Programs\jq-lsp"
$installedBinary = Join-Path $installDir "jq-lsp.exe"
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())

$archivePath = Join-Path $tempDir $archiveName
$stagedBinary = Join-Path $tempDir "jq-lsp.exe"

try {
    # Prepare temporary directory.
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

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

    # Extract the archive.
    $extractDir = Join-Path $tempDir "extracted"
    Expand-Archive -Path $archivePath -DestinationPath $extractDir -Force

    # Locate the executable.
    $binary = Get-ChildItem -Path $extractDir -Filter "jq-lsp.exe" -File -Recurse |
        Select-Object -First 1

    if (-not $binary) {
        throw "jq-lsp.exe was not found in the release archive."
    }

    # Stage the executable before replacing the installed version.
    Copy-Item -Path $binary.FullName -Destination $stagedBinary -Force

    if (-not (Test-Path $stagedBinary -PathType Leaf)) {
        throw "Staging failed: executable is missing."
    }

    # Verify the staged executable.
    $reportedVersion = (& $stagedBinary --version 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "The downloaded jq-lsp executable failed its version check: $reportedVersion"
    }

    # Install the verified executable.
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Move-Item -Path $stagedBinary -Destination $installedBinary -Force

    if (-not (Test-Path $installedBinary -PathType Leaf)) {
        throw "Installation failed: executable is missing."
    }

    # Add the installation directory to the user PATH.
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathEntries = @(
        $userPath -split ";" |
            Where-Object { $_ -and $_.Trim() }
    )

    $pathExists = $pathEntries | Where-Object {
        $_.TrimEnd("\") -ieq $installDir.TrimEnd("\")
    }

    if (-not $pathExists) {
        $newPath = (@($pathEntries) + $installDir) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    }

    # Make jq-lsp available in the current PowerShell session.
    $sessionPathEntries = @(
        $env:PATH -split ";" |
            Where-Object { $_ -and $_.Trim() }
    )

    $sessionPathExists = $sessionPathEntries | Where-Object {
        $_.TrimEnd("\") -ieq $installDir.TrimEnd("\")
    }

    if (-not $sessionPathExists) {
        $env:PATH = "$installDir;$env:PATH"
    }

    # Verify the installed executable.
    $installedVersion = (& $installedBinary --version 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Installed jq-lsp failed its version check: $installedVersion"
    }

    if (-not (Get-Command jq-lsp -ErrorAction SilentlyContinue)) {
        throw "jq-lsp is installed, but PowerShell cannot resolve it through PATH."
    }

    Write-Host "`njq-lsp installation verified." -ForegroundColor Green
    Write-Host "Expected version: $version"
    Write-Host "Reported version: $installedVersion"
    Write-Host "Executable: $installedBinary"
    Write-Host "PATH: $installDir"
}
finally {
    # Remove temporary installation files.
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}
