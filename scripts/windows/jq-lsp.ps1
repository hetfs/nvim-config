[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# jq-lsp Windows x64 installer.
# Downloads the pinned release, verifies its SHA-256 checksum, stages and
# validates the executable, then installs it and updates the user/session PATH.

$Version = "0.1.19"
$ArchiveName = "jq-lsp_${Version}_windows_amd64.zip"
$DownloadUrl = "https://github.com/wader/jq-lsp/releases/download/v${Version}/${ArchiveName}"
$ExpectedHash = "c3fa28c183d9bc964ae036aec4781b2a8ed98c9a297ee0cf63019a3febc0d865"

$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\jq-lsp"
$InstalledBinary = Join-Path $InstallDir "jq-lsp.exe"
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("jq-lsp-install-" + [guid]::NewGuid().ToString("N"))
$ArchivePath = Join-Path $TempDir $ArchiveName
$ExtractDir = Join-Path $TempDir "extracted"
$StagedBinary = Join-Path $TempDir "jq-lsp.exe"

function Write-Status {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    Write-Host $Message -ForegroundColor $Color
}

function Add-DirectoryToPath {
    param(
        [Parameter(Mandatory)]
        [string]$Directory
    )

    $normalizedDirectory = [System.IO.Path]::GetFullPath($Directory).TrimEnd("\")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    $userEntries = @(
        $userPath -split ";" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )

    $alreadyInUserPath = $false
    foreach ($entry in $userEntries) {
        try {
            $normalizedEntry = [System.IO.Path]::GetFullPath($entry).TrimEnd("\")
            if ($normalizedEntry -ieq $normalizedDirectory) {
                $alreadyInUserPath = $true
                break
            }
        }
        catch {
            # Ignore malformed PATH entries while checking for a match.
        }
    }

    if (-not $alreadyInUserPath) {
        $newUserPath = (@($userEntries) + $Directory) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        Write-Status "Added jq-lsp to the persistent user PATH." Green
    }
    else {
        Write-Status "jq-lsp is already in the persistent user PATH." DarkGray
    }

    $sessionEntries = @(
        $env:PATH -split ";" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )

    $alreadyInSessionPath = $false
    foreach ($entry in $sessionEntries) {
        try {
            $normalizedEntry = [System.IO.Path]::GetFullPath($entry).TrimEnd("\")
            if ($normalizedEntry -ieq $normalizedDirectory) {
                $alreadyInSessionPath = $true
                break
            }
        }
        catch {
            # Ignore malformed PATH entries while checking for a match.
        }
    }

    if (-not $alreadyInSessionPath) {
        $env:PATH = "$Directory;$env:PATH"
    }
}

try {
    if (-not $env:LOCALAPPDATA) {
        throw "LOCALAPPDATA is not defined. Cannot determine the installation directory."
    }

    Write-Status "Installing jq-lsp $Version for Windows x64..." Cyan

    # Use a unique temporary directory so concurrent runs do not collide.
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

    # Download the official release archive.
    Write-Status "Downloading $ArchiveName..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ArchivePath

    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        throw "Release archive was not downloaded."
    }

    # Verify the published SHA-256 checksum before extracting anything.
    $ActualHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        throw "SHA-256 verification failed. Expected $ExpectedHash, received $ActualHash."
    }

    Write-Status "SHA-256 verification passed." Green

    # Extract the archive into an isolated directory.
    New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $ExtractDir -Force

    $Binary = Get-ChildItem -LiteralPath $ExtractDir -Filter "jq-lsp.exe" -File -Recurse |
        Select-Object -First 1

    if (-not $Binary) {
        throw "jq-lsp.exe was not found in the release archive."
    }

    # Stage and validate the executable before replacing the installed copy.
    Copy-Item -LiteralPath $Binary.FullName -Destination $StagedBinary -Force

    if (-not (Test-Path -LiteralPath $StagedBinary -PathType Leaf)) {
        throw "Staging failed: jq-lsp.exe is missing."
    }

    $StagedVersionOutput = & $StagedBinary --version 2>&1
    $StagedExitCode = $LASTEXITCODE
    $StagedVersion = ($StagedVersionOutput | Out-String).Trim()

    if ($StagedExitCode -ne 0) {
        throw "The downloaded jq-lsp executable failed its version check (exit code $StagedExitCode): $StagedVersion"
    }

    if ($StagedVersion -and $StagedVersion -notmatch [regex]::Escape($Version)) {
        throw "Downloaded executable reported an unexpected version. Expected $Version; received: $StagedVersion"
    }

    # Install only after the download, checksum, extraction, and executable checks pass.
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Move-Item -LiteralPath $StagedBinary -Destination $InstalledBinary -Force

    if (-not (Test-Path -LiteralPath $InstalledBinary -PathType Leaf)) {
        throw "Installation failed: jq-lsp.exe is missing from $InstallDir."
    }

    Add-DirectoryToPath -Directory $InstallDir

    # Verify the installed copy and confirm command resolution through PATH.
    $InstalledVersionOutput = & $InstalledBinary --version 2>&1
    $InstalledExitCode = $LASTEXITCODE
    $InstalledVersion = ($InstalledVersionOutput | Out-String).Trim()

    if ($InstalledExitCode -ne 0) {
        throw "Installed jq-lsp failed its version check (exit code $InstalledExitCode): $InstalledVersion"
    }

    if ($InstalledVersion -and $InstalledVersion -notmatch [regex]::Escape($Version)) {
        throw "Installed executable reported an unexpected version. Expected $Version; received: $InstalledVersion"
    }

    $ResolvedCommand = Get-Command "jq-lsp" -CommandType Application -ErrorAction SilentlyContinue
    if (-not $ResolvedCommand) {
        throw "jq-lsp is installed, but PowerShell cannot resolve jq-lsp.exe through PATH."
    }

    Write-Status "`njq-lsp installation verified." Green
    Write-Host "Expected version: $Version"
    Write-Host "Reported version: $InstalledVersion"
    Write-Host "Executable: $InstalledBinary"
    Write-Host "Resolved command: $($ResolvedCommand.Source)"
    Write-Host "PATH: $InstallDir"
}
catch {
    Write-Status "`n[ERROR] $($_.Exception.Message)" Red
    exit 1
}
finally {
    if (Test-Path -LiteralPath $TempDir) {
        Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
