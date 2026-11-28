[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version = "3.13.0",

    [string]$LuaRoot = "C:\DevTools\Lua\5.4",

    [string]$InstallRoot = (
        Join-Path $env:LOCALAPPDATA "Programs\LuaRocks"
    ),

    [string]$RockTree = (
        Join-Path $env:LOCALAPPDATA "LuaRocks\5.4"
    ),

    [string]$CompilerBin,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# LuaRocks Windows installer for an existing 64-bit Lua 5.4 installation.
# Requires a 64-bit MinGW-w64 GCC toolchain and mingw32-make.
# This script does not install Lua or MinGW.

# ============================================================
# Configuration
# ============================================================

$LuaVersion = "5.4"
$ReleaseUrl = "https://luarocks.github.io/luarocks/releases/luarocks-$Version-win32.zip"

$ConfigFile = Join-Path $InstallRoot "config-$LuaVersion.lua"
$LuarocksBat = Join-Path $InstallRoot "luarocks.bat"

$UserRockTree = Join-Path $env:APPDATA "luarocks"

$RequiredLuaFiles = @(
    (Join-Path $LuaRoot "bin\lua.exe"),
    (Join-Path $LuaRoot "bin\lua54.dll"),
    (Join-Path $LuaRoot "include\lua.h"),
    (Join-Path $LuaRoot "lib\liblua54.dll.a")
)

$StageRoot = Join-Path $env:TEMP "luarocks-install-$Version-$PID"
$ArchivePath = Join-Path $StageRoot "luarocks.zip"
$ExtractPath = Join-Path $StageRoot "extracted"

# ============================================================
# Helpers
# ============================================================

function Write-Status {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ConsoleColor]$Color = [ConsoleColor]::Cyan
    )

    Write-Host "`n$message" -ForegroundColor $Color
}

function Assert-Path {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description was not found: $Path"
    }
}

function Get-ApplicationPath {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $Command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -eq $Command) {
        return $null
    }

    return $Command.Source
}

function Get-LuaRocksVersion {
    param(
        [Parameter(Mandatory)]
        [string]$CommandPath
    )

    Assert-Path -Path $CommandPath -Description "LuaRocks command"

    $Output = & $CommandPath --version 2>&1
    $ExitCode = $LASTEXITCODE
    $OutputText = $Output -join "`n"

    if ($ExitCode -ne 0) {
        throw @"
Unable to execute LuaRocks.

Executable: $CommandPath
Exit code: $ExitCode

Actual output:
$OutputText
"@
    }

    $VersionMatch = [regex]::Match(
        $OutputText,
        "(?i)luarocks(?:\.lua)?\s+(\d+\.\d+\.\d+)"
    )

    if (-not $VersionMatch.Success) {
        throw @"
Could not determine the LuaRocks version.

Executable: $CommandPath

Actual output:
$OutputText
"@
    }

    return $VersionMatch.Groups[1].Value
}

function Add-UserPath {
    param(
        [Parameter(Mandatory)]
        [string[]]$Paths
    )

    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $UserEntries = @(
        $UserPath -split ";" |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $Changed = $false

    foreach ($PathEntry in $Paths) {
        if ([string]::IsNullOrWhiteSpace($PathEntry)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $PathEntry -PathType Container)) {
            continue
        }

        $FullPath = [IO.Path]::GetFullPath($PathEntry)
        $FoundInUserPath = $false

        foreach ($Entry in $UserEntries) {
            $Expanded = [Environment]::ExpandEnvironmentVariables(
                $Entry.Trim().Trim('"')
            )

            try {
                $Normalized = [IO.Path]::GetFullPath($Expanded)
            }
            catch {
                continue
            }

            if ([string]::Equals(
                $Normalized,
                $FullPath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                $FoundInUserPath = $true
                break
            }
        }

        if (-not $FoundInUserPath) {
            $UserEntries += $FullPath
            $Changed = $true
        }

        $SessionEntries = @(
            $env:PATH -split ";" |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )

        $FoundInSession = $false

        foreach ($Entry in $SessionEntries) {
            $Expanded = [Environment]::ExpandEnvironmentVariables(
                $Entry.Trim().Trim('"')
            )

            try {
                $Normalized = [IO.Path]::GetFullPath($Expanded)
            }
            catch {
                continue
            }

            if ([string]::Equals(
                $Normalized,
                $FullPath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                $FoundInSession = $true
                break
            }
        }

        if (-not $FoundInSession) {
            $env:PATH = "$FullPath;$env:PATH"
        }
    }

    if ($Changed) {
        [Environment]::SetEnvironmentVariable(
            "Path",
            ($UserEntries -join ";"),
            "User"
        )

        Write-Status "Updated persistent user PATH." Green
    }
    else {
        Write-Status "Persistent user PATH already contains the required entries." Green
    }
}

function Invoke-LuaRocksInstaller {
    param(
        [Parameter(Mandatory)]
        [string]$InstallerPath,

        [Parameter(Mandatory)]
        [string[]]$InstallerArguments
    )

    # install.bat is a batch file. Run it through cmd.exe and preserve
    # quoted paths containing spaces.
    $ArgumentString = $InstallerArguments -join " "
    $CommandLine = '""{0}" {1}"' -f $InstallerPath, $ArgumentString

    Push-Location (Split-Path -Parent $InstallerPath)

    try {
        & $env:ComSpec /d /s /c $CommandLine

        $ExitCode = $LASTEXITCODE
        if ($ExitCode -ne 0) {
            throw "LuaRocks installer failed with exit code $ExitCode."
        }
    }
    finally {
        Pop-Location
    }
}

# ============================================================
# Validate platform and Lua installation
# ============================================================

Write-Status "Validating platform."

if (-not $IsWindows) {
    throw "This installer supports Windows only."
}

if ([Environment]::Is64BitOperatingSystem -ne $true) {
    throw "A 64-bit Windows installation is required."
}

if ([Environment]::Is64BitProcess -ne $true) {
    throw "Run this script from 64-bit PowerShell 7."
}

Write-Host "Windows x64 and 64-bit PowerShell detected." -ForegroundColor Green

Write-Status "Checking Lua installation."

foreach ($File in $RequiredLuaFiles) {
    Assert-Path -Path $File -Description "Lua 5.4 runtime/development file"
}

$LuaExecutable = Join-Path $LuaRoot "bin\lua.exe"
$LuaOutput = & $LuaExecutable -v 2>&1
$LuaExitCode = $LASTEXITCODE
$LuaOutputText = $LuaOutput -join " "

if ($LuaExitCode -ne 0) {
    throw "Lua executable validation failed: $LuaOutputText"
}

if ($LuaOutputText -notmatch 'Lua 5\.4(?:\.\d+)?') {
    throw "Lua 5.4 is required. Detected: $LuaOutputText"
}

Write-Host $LuaOutputText -ForegroundColor Green

# ============================================================
# Detect and validate MinGW toolchain
# ============================================================

Write-Status "Checking MinGW-w64 toolchain."

if ([string]::IsNullOrWhiteSpace($CompilerBin)) {
    $GccCommand = Get-Command gcc -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -eq $GccCommand) {
        throw @"
GCC was not found.

Add the MinGW-w64 bin directory to PATH or provide -CompilerBin.
"@
    }

    $CompilerBin = Split-Path -Parent $GccCommand.Source
}

$CompilerBin = [IO.Path]::GetFullPath($CompilerBin)
$GccPath = Join-Path $CompilerBin "gcc.exe"
$MakePath = Join-Path $CompilerBin "mingw32-make.exe"

Assert-Path -Path $GccPath -Description "MinGW-w64 GCC"
Assert-Path -Path $MakePath -Description "MinGW Make"

# Put the selected compiler first so the installer detects the intended toolchain.
$env:PATH = "$CompilerBin;$env:PATH"

$GccTargetOutput = & $GccPath -dumpmachine 2>&1
$GccExitCode = $LASTEXITCODE
$GccTarget = ($GccTargetOutput -join "").Trim()

if ($GccExitCode -ne 0) {
    throw "Unable to determine GCC target: $GccTarget"
}

if ($GccTarget -notmatch '^x86_64-w64-mingw32') {
    throw "A 64-bit MinGW-w64 GCC target is required. Detected: $GccTarget"
}

$GccVersionOutput = & $GccPath --version 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Unable to execute GCC: $($GccVersionOutput -join "`n")"
}

Write-Host "GCC: $($GccVersionOutput[0])" -ForegroundColor Green
Write-Host "GCC target: $GccTarget" -ForegroundColor Green
Write-Host "MinGW Make: $MakePath" -ForegroundColor Green

# ============================================================
# Check existing installation
# ============================================================

Write-Status "Checking existing LuaRocks installation."

$InstallRequired = $true

if (Test-Path -LiteralPath $LuarocksBat -PathType Leaf) {
    $InstalledVersion = Get-LuaRocksVersion -CommandPath $LuarocksBat

    if (($InstalledVersion -eq $Version) -and (-not $Force)) {
        Write-Host "LuaRocks $InstalledVersion is already installed." -ForegroundColor Green
        $InstallRequired = $false
    }
    elseif (-not $Force) {
        throw @"
A different LuaRocks version is already installed.

Installed: $InstalledVersion
Requested: $Version

Use -Force to replace the LuaRocks installation directory.
"@
    }
    else {
        Write-Host "Force requested. The LuaRocks installation directory will be replaced." -ForegroundColor Yellow
    }
}
elseif ((Test-Path -LiteralPath $InstallRoot) -and (-not $Force)) {
    throw @"
The installation directory already exists but does not contain luarocks.bat:

$InstallRoot

Inspect or back up this directory. Use -Force only if it is safe to replace.
"@
}

# ============================================================
# Download and install
# ============================================================

if ($InstallRequired) {
    Write-Status "Preparing LuaRocks $Version installation."

    New-Item -ItemType Directory -Path $StageRoot -Force | Out-Null

    try {
        New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null

        Write-Status "Downloading LuaRocks $Version."

        Invoke-WebRequest -Uri $ReleaseUrl -OutFile $ArchivePath

        Assert-Path -Path $ArchivePath -Description "LuaRocks release archive"

        $ArchiveItem = Get-Item -LiteralPath $ArchivePath
        if ($ArchiveItem.Length -lt 1024) {
            throw "The downloaded LuaRocks archive is unexpectedly small."
        }

        Write-Status "Extracting LuaRocks archive."

        Expand-Archive -LiteralPath $ArchivePath -DestinationPath $ExtractPath -Force

        $Installer = Get-ChildItem -LiteralPath $ExtractPath -Filter "install.bat" -File -Recurse |
            Select-Object -First 1

        if ($null -eq $Installer) {
            throw "The LuaRocks archive does not contain install.bat."
        }

        $InstallerArguments = @(
            "/P", "`"$InstallRoot`"",
            "/TREE", "`"$RockTree`"",
            "/CONFIG", "`"$InstallRoot`"",
            "/LV", $LuaVersion,
            "/LUA", "`"$LuaRoot`"",
            "/MW",
            "/NOADMIN",
            "/Q"
        )

        if ($Force) {
            $InstallerArguments += "/F"
        }

        Write-Status "Running LuaRocks Windows installer."
        Write-Host "Prefix:     $InstallRoot"
        Write-Host "Config dir: $InstallRoot"
        Write-Host "Rock tree:  $RockTree"
        Write-Host "Lua:        $LuaRoot"
        Write-Host "Compiler:   $CompilerBin"

        Invoke-LuaRocksInstaller `
            -InstallerPath $Installer.FullName `
            -InstallerArguments $InstallerArguments
    }
    finally {
        if (Test-Path -LiteralPath $StageRoot) {
            Remove-Item -LiteralPath $StageRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ============================================================
# Validate installed files and version
# ============================================================

Write-Status "Validating LuaRocks installation."

Assert-Path -Path $LuarocksBat -Description "LuaRocks command file"
Assert-Path -Path $ConfigFile -Description "LuaRocks Lua 5.4 configuration file"

$InstalledVersion = Get-LuaRocksVersion -CommandPath $LuarocksBat

if ($InstalledVersion -ne $Version) {
    throw "Expected LuaRocks $Version but found $InstalledVersion."
}

Write-Host "LuaRocks $InstalledVersion installed." -ForegroundColor Green

# ============================================================
# Configure MinGW Make
# ============================================================

Write-Status "Configuring LuaRocks build tool."

& $LuarocksBat config --scope=system variables.MAKE $MakePath
$ConfigWriteExitCode = $LASTEXITCODE

if ($ConfigWriteExitCode -ne 0) {
    throw "Failed to configure LuaRocks MAKE variable (exit code $ConfigWriteExitCode)."
}

$ConfiguredMakeOutput = & $LuarocksBat config variables.MAKE
$ConfigReadExitCode = $LASTEXITCODE

if ($ConfigReadExitCode -ne 0) {
    throw "Unable to read LuaRocks MAKE configuration."
}

$ConfiguredMake = ($ConfiguredMakeOutput -join "`n").Trim().Trim('"')
$ExpectedMake = [IO.Path]::GetFullPath($MakePath)

try {
    $ActualMake = [IO.Path]::GetFullPath($ConfiguredMake)
}
catch {
    throw "LuaRocks returned an invalid MAKE path: $ConfiguredMake"
}

if (-not [string]::Equals(
    $ActualMake,
    $ExpectedMake,
    [StringComparison]::OrdinalIgnoreCase
)) {
    throw @"
LuaRocks MAKE configuration does not match the expected executable.

Expected: $ExpectedMake
Actual:   $ConfiguredMake
"@
}

Write-Host "MAKE: $ActualMake" -ForegroundColor Green

# ============================================================
# Configure persistent and current-session PATH
# ============================================================

Write-Status "Configuring command-line PATH."

$PathDirectories = @(
    $InstallRoot,
    (Join-Path $RockTree "bin"),
    (Join-Path $UserRockTree "bin")
)

Add-UserPath -Paths $PathDirectories

# ============================================================
# Final verification
# ============================================================

Write-Status "Final verification."

$FinalVersionOutput = & $LuarocksBat --version 2>&1
$FinalVersionExitCode = $LASTEXITCODE

if ($FinalVersionExitCode -ne 0) {
    throw "Final LuaRocks version check failed: $($FinalVersionOutput -join "`n")"
}

$ConfiguredLuaVersionOutput = & $LuarocksBat config lua_version 2>&1
$LuaConfigExitCode = $LASTEXITCODE

if ($LuaConfigExitCode -ne 0) {
    throw "Unable to read LuaRocks Lua version configuration."
}

$ConfiguredLuaVersion = ($ConfiguredLuaVersionOutput -join "`n").Trim()

if ($ConfiguredLuaVersion -ne $LuaVersion) {
    throw "Expected Lua $LuaVersion but LuaRocks reports $ConfiguredLuaVersion."
}

# LuaRocks 3.13 does not expose "lua_interpreter" as a readable
# config key. The Windows installer already detected and configured
# this interpreter; validate the executable directly instead.
Assert-Path -Path $LuaExecutable -Description "Configured Lua interpreter"

$FinalLuaOutput = & $LuaExecutable -v 2>&1
$FinalLuaExitCode = $LASTEXITCODE
$FinalLuaText = $FinalLuaOutput -join " "

if ($FinalLuaExitCode -ne 0) {
    throw "Final Lua interpreter check failed: $FinalLuaText"
}

if ($FinalLuaText -notmatch 'Lua 5\.4(?:\.\d+)?') {
    throw "The configured Lua executable is not Lua 5.4: $FinalLuaText"
}

Write-Host ($FinalVersionOutput -join "`n") -ForegroundColor Green
Write-Host "Lua version:       $ConfiguredLuaVersion"
Write-Host "Lua interpreter:   $LuaExecutable"
Write-Host "Lua runtime:       $FinalLuaText"
Write-Host "Installation:      $InstallRoot"
Write-Host "Configuration:     $ConfigFile"
Write-Host "System rock tree:   $RockTree"
Write-Host "User rock tree:     $UserRockTree"
Write-Host "MinGW compiler:     $GccPath"
Write-Host "MinGW make:         $MakePath"

Write-Status "LuaRocks installation completed successfully." Green
