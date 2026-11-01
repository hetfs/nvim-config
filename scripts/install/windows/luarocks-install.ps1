
[CmdletBinding()]
param(
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

# ============================================================
# Configuration
# ============================================================

$LuaVersion = "5.4"

$ReleaseUrl = (
    "https://luarocks.github.io/luarocks/releases/" +
    "luarocks-$Version-win32.zip"
)

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

    Write-Host "`n$Message" -ForegroundColor $Color
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

function Get-LuaRocksVersion {
    param(
        [Parameter(Mandatory)]
        [string]$CommandPath
    )

    Assert-Path `
        -Path $CommandPath `
        -Description "LuaRocks executable"

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

    # Supported output examples:
    #
    # LuaRocks 3.13.0
    # C:\...\luarocks.lua 3.13.0 LuaRocks main command-line interface
    #
    # Match the version after either "luarocks" or "luarocks.lua".

    $VersionMatch = [regex]::Match(
        $OutputText,
        "(?i)luarocks(?:\.lua)?\s+(\d+\.\d+\.\d+)"
    )

    if (-not $VersionMatch.Success) {
        throw @"
Could not determine LuaRocks version.

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

    $CurrentUserPath = [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )

    $Entries = @(
        $CurrentUserPath -split ";" |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
    )

    $Changed = $false

    foreach ($Path in $Paths) {
        if (-not (Test-Path -LiteralPath $Path)) {
            continue
        }

        $FullPath = [IO.Path]::GetFullPath($Path)
        $Exists = $false

        foreach ($Entry in $Entries) {
            $NormalizedEntry = [Environment]::ExpandEnvironmentVariables(
                $Entry.Trim('"')
            )

            try {
                $NormalizedEntry = [IO.Path]::GetFullPath(
                    $NormalizedEntry
                )
            }
            catch {
                continue
            }

            if ([string]::Equals(
                $NormalizedEntry,
                $FullPath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                $Exists = $true
                break
            }
        }

        if (-not $Exists) {
            $Entries += $FullPath
            $Changed = $true
        }

        # Add the directory to the current PowerShell session.
        $SessionExists = $false

        $SessionEntries = @(
            $env:PATH -split ";" |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_)
                }
        )

        foreach ($Entry in $SessionEntries) {
            try {
                $NormalizedEntry = [IO.Path]::GetFullPath(
                    [Environment]::ExpandEnvironmentVariables(
                        $Entry.Trim('"')
                    )
                )
            }
            catch {
                continue
            }

            if ([string]::Equals(
                $NormalizedEntry,
                $FullPath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                $SessionExists = $true
                break
            }
        }

        if (-not $SessionExists) {
            $env:PATH = "$FullPath;$env:PATH"
        }
    }

    if ($Changed) {
        [Environment]::SetEnvironmentVariable(
            "Path",
            ($Entries -join ";"),
            "User"
        )

        Write-Status "Updated user PATH." Green
    }
    else {
        Write-Status "User PATH already contains the required entries." Green
    }
}

# ============================================================
# Validate Lua installation
# ============================================================

Write-Status "Checking Lua installation."

foreach ($File in $RequiredLuaFiles) {
    Assert-Path `
        -Path $File `
        -Description "Lua runtime dependency"
}

$LuaExecutable = Join-Path $LuaRoot "bin\lua.exe"

$LuaOutput = & $LuaExecutable -v 2>&1

if ($LASTEXITCODE -ne 0) {
    throw "Lua executable validation failed."
}

$LuaOutputText = $LuaOutput -join " "

if ($LuaOutputText -notmatch "5\.4") {
    throw "Lua 5.4 is required. Detected: $LuaOutputText"
}

Write-Host $LuaOutputText -ForegroundColor Green

# ============================================================
# Detect MinGW toolchain
# ============================================================

Write-Status "Checking MinGW toolchain."

if ([string]::IsNullOrWhiteSpace($CompilerBin)) {
    $GccCommand = Get-Command gcc -ErrorAction SilentlyContinue

    if (-not $GccCommand) {
        throw @"
GCC was not found.

Add the MinGW bin directory to PATH or provide -CompilerBin.
"@
    }

    $CompilerBin = Split-Path -Parent $GccCommand.Source
}

$GccPath = Join-Path $CompilerBin "gcc.exe"
$MakePath = Join-Path $CompilerBin "mingw32-make.exe"

Assert-Path -Path $GccPath -Description "MinGW GCC"
Assert-Path -Path $MakePath -Description "MinGW Make"

$env:PATH = "$CompilerBin;$env:PATH"

$GccTarget = & $GccPath -dumpmachine

if ($LASTEXITCODE -ne 0) {
    throw "Unable to determine GCC target."
}

if ($GccTarget -notmatch "x86_64-w64-mingw32") {
    throw "Unexpected GCC target: $GccTarget"
}

Write-Host "GCC target: $GccTarget" -ForegroundColor Green
Write-Host "Make: $MakePath" -ForegroundColor Green

# ============================================================
# Check existing installation
# ============================================================

Write-Status "Checking existing LuaRocks installation."

$InstallRequired = $true

if (Test-Path -LiteralPath $LuarocksBat) {
    $InstalledVersion = Get-LuaRocksVersion `
        -CommandPath $LuarocksBat

    if ($InstalledVersion -eq $Version -and -not $Force) {
        Write-Host (
            "LuaRocks $InstalledVersion is already installed."
        ) -ForegroundColor Green

        $InstallRequired = $false
    }
    elseif (-not $Force) {
        throw @"
A different LuaRocks version is already installed.

Installed: $InstalledVersion
Requested: $Version

Use -Force to replace the existing installation.
"@
    }
    else {
        Write-Host (
            "Force requested. Existing installation will be replaced."
        ) -ForegroundColor Yellow
    }
}
elseif (
    (Test-Path -LiteralPath $InstallRoot) -and
    -not $Force
) {
    throw @"
The installation directory already exists but does not contain luarocks.bat:

$InstallRoot

Inspect the directory before proceeding.
Use -Force only if you intend to replace it.
"@
}

# ============================================================
# Download and install
# ============================================================

if ($InstallRequired) {
    Write-Status "Preparing LuaRocks installation."

    New-Item -ItemType Directory -Path $StageRoot -Force |
        Out-Null

    try {
        New-Item -ItemType Directory -Path $ExtractPath -Force |
            Out-Null

        Write-Status "Downloading LuaRocks $Version."

        Invoke-WebRequest `
            -Uri $ReleaseUrl `
            -OutFile $ArchivePath

        Assert-Path `
            -Path $ArchivePath `
            -Description "LuaRocks archive"

        Write-Status "Extracting LuaRocks."

        Expand-Archive `
            -LiteralPath $ArchivePath `
            -DestinationPath $ExtractPath `
            -Force

        $Installer = Get-ChildItem `
            -LiteralPath $ExtractPath `
            -Filter "install.bat" `
            -Recurse |
            Select-Object -First 1

        if (-not $Installer) {
            throw "The LuaRocks archive does not contain install.bat."
        }

        Write-Status "Installing LuaRocks."

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

        $ArgumentString = $InstallerArguments -join " "

        Push-Location $Installer.DirectoryName

        try {
            & $env:ComSpec /d /c (
                "`"$($Installer.FullName)`" $ArgumentString"
            )

            if ($LASTEXITCODE -ne 0) {
                throw (
                    "LuaRocks installer failed with exit code " +
                    "$LASTEXITCODE."
                )
            }
        }
        finally {
            Pop-Location
        }
    }
    finally {
        if (Test-Path -LiteralPath $StageRoot) {
            Remove-Item `
                -LiteralPath $StageRoot `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}

# ============================================================
# Validate installation
# ============================================================

Write-Status "Validating LuaRocks installation."

Assert-Path `
    -Path $LuarocksBat `
    -Description "LuaRocks executable"

Assert-Path `
    -Path $ConfigFile `
    -Description "LuaRocks configuration"

$InstalledVersion = Get-LuaRocksVersion `
    -CommandPath $LuarocksBat

if ($InstalledVersion -ne $Version) {
    throw (
        "Expected LuaRocks $Version but found $InstalledVersion."
    )
}

Write-Host "LuaRocks $InstalledVersion installed." -ForegroundColor Green

# ============================================================
# Configure MinGW Make
# ============================================================

Write-Status "Configuring LuaRocks build tool."

& $LuarocksBat config --scope=system variables.MAKE $MakePath

if ($LASTEXITCODE -ne 0) {
    throw "Failed to configure LuaRocks MAKE variable."
}

$ConfiguredMake = (
    & $LuarocksBat config variables.MAKE
).Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Unable to read LuaRocks MAKE configuration."
}

if (-not [string]::Equals(
    $ConfiguredMake,
    $MakePath,
    [StringComparison]::OrdinalIgnoreCase
)) {
    throw @"
LuaRocks MAKE configuration does not match the expected executable.

Expected: $MakePath
Actual:   $ConfiguredMake
"@
}

Write-Host "MAKE: $ConfiguredMake" -ForegroundColor Green

# ============================================================
# Configure user PATH
# ============================================================

Write-Status "Configuring command-line PATH."

Add-UserPath -Paths @(
    $InstallRoot,
    (Join-Path $RockTree "bin"),
    (Join-Path $UserRockTree "bin")
)

# ============================================================
# Final verification
# ============================================================

Write-Status "Final verification."

$LuaRocksVersionOutput = & $LuarocksBat --version

if ($LASTEXITCODE -ne 0) {
    throw "Final LuaRocks version check failed."
}

$ConfiguredLuaVersion = (
    & $LuarocksBat config lua_version
).Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Unable to read LuaRocks Lua version configuration."
}

if ($ConfiguredLuaVersion -ne $LuaVersion) {
    throw (
        "Expected Lua $LuaVersion but found $ConfiguredLuaVersion."
    )
}

Write-Host "`n$LuaRocksVersionOutput" -ForegroundColor Green
Write-Host "Lua version: $ConfiguredLuaVersion"
Write-Host "Installation: $InstallRoot"
Write-Host "System rock tree: $RockTree"
Write-Host "User rock tree: $UserRockTree"

Write-Status "LuaRocks installation completed successfully." Green

