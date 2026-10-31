
# ============================================================
# Lua 5.4 - Windows x64 build and installation
# Toolchain: WinLibs GCC/G++ POSIX UCRT
#
# Lua version : 5.4.9
# Architecture : x86_64
# Thread model : POSIX
# C runtime    : UCRT
#
# Outputs:
#   lua54.dll
#   liblua54.dll.a
#   lua.exe
#   luac.exe
#
# Installation:
#   C:\DevTools\Lua\5.4\
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$LuaVersion = "5.4.9"

# Only versions with explicitly verified checksums are accepted.
$LuaChecksums = @{
    "5.4.9" = "2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6"
}

# Installation and workspace root.
$LuaRoot = "C:\DevTools\Lua"

# Official Lua source archive.
$LuaArchive = "lua-$LuaVersion.tar.gz"
$DownloadUrl = "https://www.lua.org/ftp/$LuaArchive"

# Workspace directories.
$DownloadRoot = Join-Path $LuaRoot "downloads"
$SourceRoot = Join-Path $LuaRoot "source"
$BuildRoot = Join-Path $LuaRoot "build"

# Version-specific paths.
$ArchivePath = Join-Path $DownloadRoot $LuaArchive
$SourcePath = Join-Path $SourceRoot "lua-$LuaVersion"
$BuildPath = Join-Path $BuildRoot "lua-$LuaVersion"

# Installation destination.
$InstallPath = Join-Path $LuaRoot "5.4"
$InstallBin = Join-Path $InstallPath "bin"
$InstallInclude = Join-Path $InstallPath "include"
$InstallLib = Join-Path $InstallPath "lib"

# Build outputs.
$LuaSourceDirectory = Join-Path $SourcePath "src"
$LuaDllPath = Join-Path $BuildPath "lua54.dll"
$ImportLibraryPath = Join-Path $BuildPath "liblua54.dll.a"
$LuaExePath = Join-Path $BuildPath "lua.exe"
$LuacExePath = Join-Path $BuildPath "luac.exe"

# ------------------------------------------------------------
# Validate configuration
# ------------------------------------------------------------

if (-not $LuaChecksums.ContainsKey($LuaVersion)) {
    throw @"
Lua version '$LuaVersion' is not registered.

Add its officially verified SHA-256 checksum to `$LuaChecksums
before attempting to download it.
"@
}

$ExpectedSha256 = $LuaChecksums[$LuaVersion]

if ($ExpectedSha256 -notmatch '^[A-Fa-f0-9]{64}$') {
    throw "The registered SHA-256 checksum for Lua $LuaVersion is invalid."
}

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Test-LuaSource {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $RequiredFiles = @(
        "Makefile",
        "README",
        "src\lua.h",
        "src\luaconf.h",
        "src\lauxlib.h",
        "src\lualib.h",
        "src\lua.hpp",
        "src\lua.c",
        "src\luac.c"
    )

    foreach ($File in $RequiredFiles) {
        $FilePath = Join-Path $Path $File

        if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
            return $false
        }
    }

    return $true
}

function Get-LuaArchiveHash {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return (Get-FileHash `
        -LiteralPath $Path `
        -Algorithm SHA256).Hash
}

function Test-LuaArchive {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$ExpectedHash
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    $ActualHash = Get-LuaArchiveHash -Path $Path

    return $ActualHash.Equals(
        $ExpectedHash,
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function Get-GccToolPath {
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,

        [Parameter(Mandatory)]
        [string]$GccPath
    )

    $ToolOutput = & $GccPath "-print-prog-name=$ToolName" 2>&1
    $ToolExitCode = $LASTEXITCODE
    $ReportedPath = ($ToolOutput | Out-String).Trim()

    if ($ToolExitCode -ne 0 -or -not $ReportedPath) {
        throw "GCC could not locate its $ToolName executable."
    }

    # GCC may return an absolute path.
    if (Test-Path -LiteralPath $ReportedPath -PathType Leaf) {
        return (Resolve-Path -LiteralPath $ReportedPath).Path
    }

    # Or it may return an executable name resolved through PATH.
    $ToolCommand = Get-Command `
        -Name $ReportedPath `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    if (-not $ToolCommand -and $ReportedPath -notmatch '\.exe$') {
        $ToolCommand = Get-Command `
            -Name "$ReportedPath.exe" `
            -CommandType Application `
            -ErrorAction SilentlyContinue
    }

    if (-not $ToolCommand) {
        throw "GCC reported '$ReportedPath' for $ToolName, but it could not be found."
    }

    return $ToolCommand.Source
}

function Get-PeImportedDlls {
    param(
        [Parameter(Mandatory)]
        [string]$Executable,

        [Parameter(Mandatory)]
        [string]$ObjDumpPath
    )

    $ImportOutput = & $ObjDumpPath -p $Executable 2>&1
    $ExitCode = $LASTEXITCODE

    if ($ExitCode -ne 0) {
        throw "Unable to inspect PE imports: $Executable"
    }

    $ImportedDlls = @(
        foreach ($Line in $ImportOutput) {
            $LineText = [string]$Line

            if ($LineText -match '^\s*DLL Name:\s*(?<Name>\S+)\s*$') {
                $Matches['Name'].ToLowerInvariant()
            }
        }
    )

    return $ImportedDlls
}

function Test-PeImportsDll {
    param(
        [Parameter(Mandatory)]
        [string[]]$ImportedDlls,

        [Parameter(Mandatory)]
        [string]$DllName
    )

    return ($ImportedDlls -contains $DllName.ToLowerInvariant())
}

# ------------------------------------------------------------
# 1. Prepare directories
# ------------------------------------------------------------

Write-Step "Preparing Lua $LuaVersion directories"

foreach ($Directory in @(
    $LuaRoot,
    $DownloadRoot,
    $SourceRoot,
    $BuildRoot,
    $BuildPath
)) {
    New-Item `
        -ItemType Directory `
        -Path $Directory `
        -Force |
        Out-Null
}

Write-Success "Lua workspace directories are ready."

# ------------------------------------------------------------
# 2. Download and verify source archive
# ------------------------------------------------------------

Write-Step "Checking Lua $LuaVersion source archive"

if (Test-LuaArchive `
    -Path $ArchivePath `
    -ExpectedHash $ExpectedSha256
) {
    Write-Success "Existing source archive passed SHA-256 verification."
}
else {
    Write-Step "Downloading official Lua $LuaVersion source archive"

    # Use a unique temporary file to avoid accepting incomplete downloads.
    $PartialPath = Join-Path $DownloadRoot (
        ".$LuaArchive.$([guid]::NewGuid().ToString('N')).partial"
    )

    try {
        Invoke-WebRequest `
            -Uri $DownloadUrl `
            -OutFile $PartialPath `
            -TimeoutSec 120

        Write-Step "Verifying downloaded archive"

        $ActualHash = Get-LuaArchiveHash -Path $PartialPath

        if (-not $ActualHash.Equals(
            $ExpectedSha256,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw @"
Lua $LuaVersion SHA-256 verification failed.

Expected: $ExpectedSha256
Actual:   $ActualHash

The downloaded archive will not be accepted.
"@
        }

        # Replace the existing archive only after successful verification.
        Move-Item `
            -LiteralPath $PartialPath `
            -Destination $ArchivePath `
            -Force

        Write-Success "Lua $LuaVersion archive downloaded and verified."
    }
    finally {
        if (Test-Path -LiteralPath $PartialPath) {
            Remove-Item -LiteralPath $PartialPath -Force
        }
    }
}

# ------------------------------------------------------------
# 3. Validate existing source or extract archive
# ------------------------------------------------------------

Write-Step "Preparing Lua $LuaVersion source code"

if (Test-LuaSource -Path $SourcePath) {
    Write-Success "Existing Lua source directory passed structural validation."
}
else {
    if (Test-Path -LiteralPath $SourcePath) {
        throw @"
An existing Lua source directory is incomplete or invalid:

$SourcePath

The directory has not been overwritten.
Inspect or remove it before retrying.
"@
    }

    # Locate the Windows tar executable.
    $TarCommand = Get-Command `
        -Name "tar.exe" `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    if (-not $TarCommand) {
        throw "tar.exe was not found. Install or expose Windows tar before continuing."
    }

    # Use a unique extraction directory.
    $ExtractPath = Join-Path $SourceRoot (
        ".extract-lua-$LuaVersion-$([guid]::NewGuid().ToString('N'))"
    )

    New-Item `
        -ItemType Directory `
        -Path $ExtractPath |
        Out-Null

    try {
        Write-Step "Extracting $LuaArchive"

        & $TarCommand.Source -xzf $ArchivePath -C $ExtractPath

        if ($LASTEXITCODE -ne 0) {
            throw "Lua extraction failed. tar exit code: $LASTEXITCODE"
        }

        $ExtractedSource = Join-Path $ExtractPath "lua-$LuaVersion"

        if (-not (Test-LuaSource -Path $ExtractedSource)) {
            throw "Extracted archive does not contain the expected Lua source files."
        }

        # Move only the validated source directory into its permanent location.
        Move-Item `
            -LiteralPath $ExtractedSource `
            -Destination $SourcePath

        Write-Success "Lua $LuaVersion source extracted and validated."
    }
    finally {
        if (Test-Path -LiteralPath $ExtractPath) {
            Remove-Item `
                -LiteralPath $ExtractPath `
                -Recurse `
                -Force
        }
    }
}

# ------------------------------------------------------------
# 4. Validate WinLibs GCC toolchain
# ------------------------------------------------------------

Write-Step "Validating WinLibs GCC toolchain"

# Locate GCC.
$GccCommand = Get-Command `
    -Name "gcc.exe" `
    -CommandType Application `
    -ErrorAction SilentlyContinue

if (-not $GccCommand) {
    throw "GCC (gcc.exe) was not found in PATH."
}

$GccPath = $GccCommand.Source

# ------------------------------------------------------------
# 4.1 GCC version
# ------------------------------------------------------------

$GccVersionOutput = & $GccPath --version 2>&1
$GccVersionExitCode = $LASTEXITCODE

if ($GccVersionExitCode -ne 0) {
    throw "Unable to retrieve GCC version."
}

$GccVersion = ([string]($GccVersionOutput | Select-Object -First 1)).Trim()

Write-Success "GCC version detected: $GccVersion"

# ------------------------------------------------------------
# 4.2 Target architecture
# ------------------------------------------------------------

$GccTargetOutput = & $GccPath -dumpmachine 2>&1
$GccTargetExitCode = $LASTEXITCODE
$GccTarget = ($GccTargetOutput | Out-String).Trim()

if ($GccTargetExitCode -ne 0 -or -not $GccTarget) {
    throw "Unable to determine GCC target architecture."
}

if ($GccTarget -ne "x86_64-w64-mingw32") {
    throw @"
Unsupported GCC target.

Expected: x86_64-w64-mingw32
Actual:   $GccTarget
"@
}

Write-Success "GCC target is Windows x64."

# ------------------------------------------------------------
# 4.3 POSIX thread model
# ------------------------------------------------------------

# GCC -v reports its thread model. Its exit code is not used
# because GCC may also report that no input files were supplied.
$GccDetails = (& $GccPath -v 2>&1 | Out-String)

if ($GccDetails -notmatch '(?im)^\s*Thread model:\s*posix\s*$') {
    throw @"
GCC does not report the expected POSIX thread model.

Expected: Thread model: posix

GCC details:
$GccDetails
"@
}

Write-Success "GCC POSIX thread model confirmed."

# ------------------------------------------------------------
# 4.4 Locate GNU linker and objdump
# ------------------------------------------------------------

$LinkerPath = Get-GccToolPath `
    -ToolName "ld" `
    -GccPath $GccPath

$ObjDumpPath = Get-GccToolPath `
    -ToolName "objdump" `
    -GccPath $GccPath

Write-Success "GNU linker located: $LinkerPath"
Write-Success "GNU objdump located: $ObjDumpPath"

# ------------------------------------------------------------
# 4.5 G++ availability (informational)
# ------------------------------------------------------------

# Lua is written in C. G++ is not required for this build.
$GxxCommand = Get-Command `
    -Name "g++.exe" `
    -CommandType Application `
    -ErrorAction SilentlyContinue

$GxxVersion = "Not available"

if ($GxxCommand) {
    $GxxVersionOutput = & $GxxCommand.Source --version 2>&1

    if ($LASTEXITCODE -eq 0) {
        $GxxVersion = ([string]($GxxVersionOutput | Select-Object -First 1)).Trim()
    }
}

# ------------------------------------------------------------
# 5. Compile, execute and inspect a temporary C program
# ------------------------------------------------------------

Write-Step "Testing GCC compilation, execution and C runtime"

$ToolchainTestPath = Join-Path $BuildPath (
    ".toolchain-check-$([guid]::NewGuid().ToString('N'))"
)

New-Item `
    -ItemType Directory `
    -Path $ToolchainTestPath `
    -Force |
    Out-Null

$TestSource = Join-Path $ToolchainTestPath "toolchain-check.c"
$TestExecutable = Join-Path $ToolchainTestPath "toolchain-check.exe"

$CProgram = @'
#include <stdio.h>

int main(void)
{
    puts("WinLibs GCC toolchain check passed.");
    return 0;
}
'@

try {
    Set-Content `
        -LiteralPath $TestSource `
        -Value $CProgram `
        -Encoding ascii

    # Compile.
    & $GccPath `
        -Wall `
        -Wextra `
        -Werror `
        $TestSource `
        -o $TestExecutable

    if ($LASTEXITCODE -ne 0) {
        throw "GCC compilation test failed. Exit code: $LASTEXITCODE"
    }

    if (-not (Test-Path -LiteralPath $TestExecutable -PathType Leaf)) {
        throw "GCC reported success, but the test executable was not created."
    }

    Write-Success "GCC compiled the test program."

    # Execute.
    $TestOutput = & $TestExecutable
    $TestExitCode = $LASTEXITCODE
    $TestOutputText = ($TestOutput | Out-String).Trim()

    if ($TestExitCode -ne 0) {
        throw "Compiled executable failed. Exit code: $TestExitCode"
    }

    if ($TestOutputText -ne "WinLibs GCC toolchain check passed.") {
        throw "The compiled test executable returned unexpected output: $TestOutputText"
    }

    Write-Success "Compiled Windows executable ran successfully."

    # Inspect executable imports.
    $ImportedDlls = @(
        Get-PeImportedDlls `
            -Executable $TestExecutable `
            -ObjDumpPath $ObjDumpPath
    )

    if ($ImportedDlls.Count -eq 0) {
        throw "No DLL imports were found. The C runtime cannot be established."
    }

    $UcrtImports = @(
        $ImportedDlls | Where-Object {
            $_ -eq "ucrtbase.dll" -or
            $_ -match '^(api|ext)-ms-win-crt-'
        }
    )

    $MsvcrtImports = @(
        $ImportedDlls | Where-Object {
            $_ -eq "msvcrt.dll"
        }
    )

    if ($UcrtImports.Count -gt 0 -and $MsvcrtImports.Count -gt 0) {
        throw @"
The compiled executable imports both UCRT and MSVCRT DLLs.

UCRT imports:
$($UcrtImports -join "`n")

MSVCRT imports:
$($MsvcrtImports -join "`n")

The runtime configuration is mixed.
"@
    }

    if ($UcrtImports.Count -gt 0) {
        $CrtRuntime = "UCRT"
        Write-Success "Compiled executable imports the Universal C Runtime."
    }
    elseif ($MsvcrtImports.Count -gt 0) {
        $CrtRuntime = "MSVCRT"

        throw @"
The compiled executable imports MSVCRT.

Expected runtime: UCRT
Detected runtime: MSVCRT
"@
    }
    else {
        throw @"
The compiled executable does not expose a recognizable UCRT or MSVCRT import.

Imported DLLs:
$($ImportedDlls -join "`n")
"@
    }
}
finally {
    if (Test-Path -LiteralPath $ToolchainTestPath) {
        Remove-Item `
            -LiteralPath $ToolchainTestPath `
            -Recurse `
            -Force
    }
}

# ------------------------------------------------------------
# 6. Build Lua 5.4.9
# ------------------------------------------------------------

Write-Step "Building Lua $LuaVersion"

# ------------------------------------------------------------
# 6.1 Define Lua source files
# ------------------------------------------------------------

$CoreSources = @(
    "lapi.c",
    "lcode.c",
    "lctype.c",
    "ldebug.c",
    "ldo.c",
    "ldump.c",
    "lfunc.c",
    "lgc.c",
    "llex.c",
    "lmem.c",
    "lobject.c",
    "lopcodes.c",
    "lparser.c",
    "lstate.c",
    "lstring.c",
    "ltable.c",
    "ltm.c",
    "lundump.c",
    "lvm.c",
    "lzio.c"
)

$LibrarySources = @(
    "lauxlib.c",
    "lbaselib.c",
    "lcorolib.c",
    "ldblib.c",
    "liolib.c",
    "lmathlib.c",
    "loadlib.c",
    "loslib.c",
    "lstrlib.c",
    "ltablib.c",
    "lutf8lib.c",
    "linit.c"
)

$LuaLibrarySources = @(
    foreach ($File in $CoreSources + $LibrarySources) {
        Join-Path $LuaSourceDirectory $File
    }
)

$LuaMainSource = Join-Path $LuaSourceDirectory "lua.c"
$LuacMainSource = Join-Path $LuaSourceDirectory "luac.c"

$BuildInputs = @(
    $LuaLibrarySources
    $LuaMainSource
    $LuacMainSource
)

foreach ($File in $BuildInputs) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        throw "Required Lua build input is missing: $File"
    }
}

Write-Success "All Lua core, library and executable source files are present."

# Remove only the known output files so stale artifacts cannot
# be mistaken for the result of a successful build.
foreach ($Artifact in @(
    $LuaDllPath,
    $ImportLibraryPath,
    $LuaExePath,
    $LuacExePath
)) {
    if (Test-Path -LiteralPath $Artifact) {
        Remove-Item -LiteralPath $Artifact -Force
    }
}

# ------------------------------------------------------------
# 6.2 Build shared Lua DLL and GCC import library
# ------------------------------------------------------------

Write-Step "Building shared lua54.dll"

$DllArguments = @(
    "-O2",
    "-Wall",
    "-Wextra",
    "-DLUA_BUILD_AS_DLL",
    "-shared",
    "-Wl,--out-implib,$ImportLibraryPath",
    "-o",
    $LuaDllPath
) + $LuaLibrarySources + @(
    "-lm"
)

& $GccPath @DllArguments

if ($LASTEXITCODE -ne 0) {
    throw "Building lua54.dll failed. GCC exit code: $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $LuaDllPath -PathType Leaf)) {
    throw "GCC completed without producing lua54.dll."
}

if (-not (Test-Path -LiteralPath $ImportLibraryPath -PathType Leaf)) {
    throw "GCC did not produce the expected import library: $ImportLibraryPath"
}

Write-Success "Shared Lua runtime and GCC import library built."

# ------------------------------------------------------------
# 6.3 Build Lua interpreter against shared DLL
# ------------------------------------------------------------

Write-Step "Building lua.exe"

# LUA_USE_DLL marks Lua API declarations as DLL imports.
# LUA_BUILD_AS_DLL is reserved for building the DLL itself.
$LuaArguments = @(
    "-O2",
    "-Wall",
    "-Wextra",
    "-DLUA_USE_DLL",
    $LuaMainSource,
    "-L$BuildPath",
    "-llua54",
    "-lm",
    "-o",
    $LuaExePath
)

& $GccPath @LuaArguments

if ($LASTEXITCODE -ne 0) {
    throw "Building lua.exe failed. GCC exit code: $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $LuaExePath -PathType Leaf)) {
    throw "GCC completed without producing lua.exe."
}

Write-Success "Lua interpreter linked against lua54.dll."

# ------------------------------------------------------------
# 6.4 Build standalone luac.exe
# ------------------------------------------------------------

Write-Step "Building standalone luac.exe"

# Lua core and standard-library sources are compiled directly
# into luac.exe. No Lua DLL import library is used.
$LuacArguments = @(
    "-O2",
    "-Wall",
    "-Wextra",
    $LuacMainSource
) + $LuaLibrarySources + @(
    "-lm",
    "-o",
    $LuacExePath
)

& $GccPath @LuacArguments

if ($LASTEXITCODE -ne 0) {
    throw "Building luac.exe failed. GCC exit code: $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $LuacExePath -PathType Leaf)) {
    throw "GCC completed without producing luac.exe."
}

Write-Success "Standalone luac.exe built."

# ------------------------------------------------------------
# 6.5 Verify generated artifacts
# ------------------------------------------------------------

Write-Step "Checking Lua build artifacts"

foreach ($Artifact in @(
    $LuaDllPath,
    $ImportLibraryPath,
    $LuaExePath,
    $LuacExePath
)) {
    if (-not (Test-Path -LiteralPath $Artifact -PathType Leaf)) {
        throw "Expected build artifact is missing: $Artifact"
    }
}

Write-Success "All four expected build artifacts exist."

# ------------------------------------------------------------
# 6.6 Verify interpreter version and execution
# ------------------------------------------------------------

Write-Step "Testing Lua interpreter"

$LuaVersionOutput = & $LuaExePath -v 2>&1
$LuaVersionExitCode = $LASTEXITCODE
$LuaVersionText = ($LuaVersionOutput | Out-String).Trim()

if ($LuaVersionExitCode -ne 0) {
    throw "lua.exe failed its version test."
}

if ($LuaVersionText -notmatch "Lua $([regex]::Escape($LuaVersion))") {
    throw @"
Unexpected Lua interpreter version.

Expected: Lua $LuaVersion
Actual:   $LuaVersionText
"@
}

$LuaRuntimeOutput = & $LuaExePath -e "assert(_VERSION == 'Lua 5.4'); print(_VERSION)"
$LuaRuntimeExitCode = $LASTEXITCODE

if ($LuaRuntimeExitCode -ne 0) {
    throw "lua.exe failed its Lua runtime execution test."
}

if (($LuaRuntimeOutput | Out-String).Trim() -ne "Lua 5.4") {
    throw "lua.exe returned unexpected runtime output."
}

Write-Success "lua.exe reports Lua $LuaVersion and executes Lua code."

# ------------------------------------------------------------
# 6.7 Verify standalone compiler
# ------------------------------------------------------------

Write-Step "Testing standalone luac.exe"

$LuacVersionOutput = & $LuacExePath -v 2>&1
$LuacVersionExitCode = $LASTEXITCODE
$LuacVersionText = ($LuacVersionOutput | Out-String).Trim()

if ($LuacVersionExitCode -ne 0) {
    throw "luac.exe failed its version test."
}

if ($LuacVersionText -notmatch "Lua $([regex]::Escape($LuaVersion))") {
    throw @"
Unexpected Lua compiler version.

Expected: Lua $LuaVersion
Actual:   $LuacVersionText
"@
}

$LuacTestSource = Join-Path $BuildPath ".luac-test.lua"
$LuacTestOutput = Join-Path $BuildPath ".luac-test.luac"

try {
    @'
local message = "Standalone Lua compiler works"
print(message)
'@ | Set-Content -LiteralPath $LuacTestSource -Encoding ascii

    & $LuacExePath -o $LuacTestOutput $LuacTestSource

    if ($LASTEXITCODE -ne 0) {
        throw "luac.exe failed to compile the test Lua file."
    }

    if (-not (Test-Path -LiteralPath $LuacTestOutput -PathType Leaf)) {
        throw "luac.exe did not produce the expected bytecode file."
    }

    Write-Success "luac.exe reports Lua $LuaVersion and compiled a Lua source file."
}
finally {
    foreach ($File in @($LuacTestSource, $LuacTestOutput)) {
        if (Test-Path -LiteralPath $File) {
            Remove-Item -LiteralPath $File -Force
        }
    }
}

# ------------------------------------------------------------
# 6.8 Verify interpreter and compiler DLL dependencies
# ------------------------------------------------------------

Write-Step "Verifying interpreter and compiler DLL dependencies"

$LuaExeImports = @(
    Get-PeImportedDlls `
        -Executable $LuaExePath `
        -ObjDumpPath $ObjDumpPath
)

if (-not (Test-PeImportsDll `
    -ImportedDlls $LuaExeImports `
    -DllName "lua54.dll"
)) {
    throw "lua.exe does not import the expected lua54.dll."
}

Write-Success "lua.exe imports lua54.dll."

$LuacExeImports = @(
    Get-PeImportedDlls `
        -Executable $LuacExePath `
        -ObjDumpPath $ObjDumpPath
)

if (Test-PeImportsDll `
    -ImportedDlls $LuacExeImports `
    -DllName "lua54.dll"
) {
    throw "luac.exe unexpectedly depends on lua54.dll."
}

Write-Success "luac.exe has no lua54.dll dependency."

# ------------------------------------------------------------
# 6.9 Verify exported Lua API symbols
# ------------------------------------------------------------

Write-Step "Verifying lua54.dll exports"

$DllExportOutput = & $ObjDumpPath -p $LuaDllPath 2>&1

if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect lua54.dll exports."
}

$DllExportText = $DllExportOutput | Out-String

if ($DllExportText -notmatch '(?i)Export Table') {
    throw "lua54.dll does not contain a recognizable export table."
}

if ($DllExportText -notmatch '(?m)\bluaL_newstate\b') {
    throw "lua54.dll does not export the expected luaL_newstate API symbol."
}

if ($DllExportText -notmatch '(?m)\blua_close\b') {
    throw "lua54.dll does not export the expected lua_close API symbol."
}

Write-Success "lua54.dll exports the expected Lua API symbols."

# ------------------------------------------------------------
# 6.10 Test an external C application against the DLL
# ------------------------------------------------------------

Write-Step "Testing external C application linkage"

$ApiTestPath = Join-Path $BuildPath (
    ".api-check-$([guid]::NewGuid().ToString('N'))"
)

New-Item `
    -ItemType Directory `
    -Path $ApiTestPath `
    -Force |
    Out-Null

$ApiTestSource = Join-Path $ApiTestPath "lua-api-check.c"
$ApiTestExecutable = Join-Path $ApiTestPath "lua-api-check.exe"

try {
    @'
#include <stdio.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

int main(void)
{
    lua_State *L = luaL_newstate();

    if (L == NULL) {
        fputs("Unable to create Lua state.\n", stderr);
        return 1;
    }

    luaL_openlibs(L);

    if (luaL_dostring(L, "assert(_VERSION == 'Lua 5.4')") != LUA_OK) {
        fprintf(stderr, "%s\n", lua_tostring(L, -1));
        lua_close(L);
        return 2;
    }

    lua_close(L);

    puts("External Lua C API check passed.");
    return 0;
}
'@ | Set-Content -LiteralPath $ApiTestSource -Encoding ascii

    # External consumers must use LUA_USE_DLL.
    $ApiArguments = @(
        "-O2",
        "-Wall",
        "-Wextra",
        "-DLUA_USE_DLL",
        "-I$LuaSourceDirectory",
        $ApiTestSource,
        "-L$BuildPath",
        "-llua54",
        "-lm",
        "-o",
        $ApiTestExecutable
    )

    & $GccPath @ApiArguments

    if ($LASTEXITCODE -ne 0) {
        throw "External C API test failed to compile."
    }

    # Windows searches the executable's directory for dependent DLLs.
    Copy-Item `
        -LiteralPath $LuaDllPath `
        -Destination $ApiTestPath

    $ApiTestOutput = & $ApiTestExecutable
    $ApiTestExitCode = $LASTEXITCODE
    $ApiTestText = ($ApiTestOutput | Out-String).Trim()

    if ($ApiTestExitCode -ne 0) {
        throw "External C API test failed. Exit code: $ApiTestExitCode"
    }

    if ($ApiTestText -ne "External Lua C API check passed.") {
        throw "External C API test returned unexpected output: $ApiTestText"
    }

    Write-Success "External C application linked and executed against lua54.dll."
}
finally {
    if (Test-Path -LiteralPath $ApiTestPath) {
        Remove-Item `
            -LiteralPath $ApiTestPath `
            -Recurse `
            -Force
    }
}

# ------------------------------------------------------------
# 6.11 Build summary
# ------------------------------------------------------------

Write-Step "Lua $LuaVersion build completed"

Write-Host ""
Write-Host "Shared runtime : $LuaDllPath"
Write-Host "Import library : $ImportLibraryPath"
Write-Host "Interpreter    : $LuaExePath"
Write-Host "Compiler       : $LuacExePath"
Write-Host ""

Write-Success "Lua shared runtime build passed."
Write-Success "Lua interpreter validation passed."
Write-Success "Standalone compiler validation passed."
Write-Success "External C API linkage validation passed."

# ------------------------------------------------------------
# 7. Install Lua 5.4.9
# ------------------------------------------------------------

Write-Step "Installing Lua $LuaVersion"

# Do not overwrite an existing installation.
if (Test-Path -LiteralPath $InstallPath) {
    throw @"
The Lua installation directory already exists:

$InstallPath

The existing installation has not been modified.
Inspect or back it up before attempting installation.
"@
}

# Verify all build artifacts before installation.
foreach ($Artifact in @(
    $LuaDllPath,
    $ImportLibraryPath,
    $LuaExePath,
    $LuacExePath
)) {
    if (-not (Test-Path -LiteralPath $Artifact -PathType Leaf)) {
        throw "Cannot install Lua. Required build artifact is missing: $Artifact"
    }
}

# Create a unique staging directory beside the final destination.
$InstallStagingPath = Join-Path $LuaRoot (
    ".5.4-staging-$([guid]::NewGuid().ToString('N'))"
)

$StagingBin = Join-Path $InstallStagingPath "bin"
$StagingInclude = Join-Path $InstallStagingPath "include"
$StagingLib = Join-Path $InstallStagingPath "lib"

try {
    # --------------------------------------------------------
    # 7.1 Prepare staging directories
    # --------------------------------------------------------

    Write-Step "Preparing Lua installation staging area"

    foreach ($Directory in @(
        $StagingBin,
        $StagingInclude,
        $StagingLib
    )) {
        New-Item `
            -ItemType Directory `
            -Path $Directory `
            -Force |
            Out-Null
    }

    # --------------------------------------------------------
    # 7.2 Install executables and shared runtime
    # --------------------------------------------------------

    Write-Step "Installing Lua executables and runtime DLL"

    Copy-Item -LiteralPath $LuaExePath -Destination $StagingBin
    Copy-Item -LiteralPath $LuacExePath -Destination $StagingBin
    Copy-Item -LiteralPath $LuaDllPath -Destination $StagingBin

    Write-Success "Lua executables and shared runtime copied."

    # --------------------------------------------------------
    # 7.3 Install public headers
    # --------------------------------------------------------

    Write-Step "Installing Lua development headers"

    $LuaHeaders = @(
        "lua.h",
        "luaconf.h",
        "lauxlib.h",
        "lualib.h",
        "lua.hpp"
    )

    foreach ($Header in $LuaHeaders) {
        $HeaderSource = Join-Path $LuaSourceDirectory $Header

        if (-not (Test-Path -LiteralPath $HeaderSource -PathType Leaf)) {
            throw "Required Lua header is missing: $HeaderSource"
        }

        Copy-Item `
            -LiteralPath $HeaderSource `
            -Destination $StagingInclude
    }

    Write-Success "Lua development headers copied."

    # --------------------------------------------------------
    # 7.4 Install GCC import library
    # --------------------------------------------------------

    Write-Step "Installing GCC import library"

    Copy-Item `
        -LiteralPath $ImportLibraryPath `
        -Destination $StagingLib

    Write-Success "GCC import library copied."

    # --------------------------------------------------------
    # 7.5 Validate staged installation files
    # --------------------------------------------------------

    Write-Step "Validating staged installation"

    $RequiredInstalledFiles = @(
        (Join-Path $StagingBin "lua.exe"),
        (Join-Path $StagingBin "luac.exe"),
        (Join-Path $StagingBin "lua54.dll"),
        (Join-Path $StagingInclude "lua.h"),
        (Join-Path $StagingInclude "luaconf.h"),
        (Join-Path $StagingInclude "lauxlib.h"),
        (Join-Path $StagingInclude "lualib.h"),
        (Join-Path $StagingInclude "lua.hpp"),
        (Join-Path $StagingLib "liblua54.dll.a")
    )

    foreach ($File in $RequiredInstalledFiles) {
        if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
            throw "Staged installation is incomplete: $File"
        }
    }

    Write-Success "All expected installation files are present."

    # --------------------------------------------------------
    # 7.6 Test staged Lua interpreter
    # --------------------------------------------------------

    Write-Step "Testing staged Lua interpreter"

    $StagedLua = Join-Path $StagingBin "lua.exe"

    $LuaTestOutput = & $StagedLua -e "print(_VERSION)"
    $LuaTestExitCode = $LASTEXITCODE
    $LuaTestText = ($LuaTestOutput | Out-String).Trim()

    if ($LuaTestExitCode -ne 0) {
        throw "Staged lua.exe failed. Exit code: $LuaTestExitCode"
    }

    if ($LuaTestText -ne "Lua 5.4") {
        throw "Unexpected staged Lua interpreter version: $LuaTestText"
    }

    Write-Success "Staged interpreter runs and reports Lua 5.4."

    # --------------------------------------------------------
    # 7.7 Test staged standalone compiler
    # --------------------------------------------------------

    Write-Step "Testing staged standalone compiler"

    $StagedLuac = Join-Path $StagingBin "luac.exe"

    $LuacVersionOutput = & $StagedLuac -v 2>&1
    $LuacVersionExitCode = $LASTEXITCODE
    $LuacVersionText = ($LuacVersionOutput | Out-String).Trim()

    if ($LuacVersionExitCode -ne 0) {
        throw "Staged luac.exe failed its version test."
    }

    if ($LuacVersionText -notmatch "Lua $([regex]::Escape($LuaVersion))") {
        throw "Unexpected staged compiler version: $LuacVersionText"
    }

    $StagedLuacSource = Join-Path $InstallStagingPath ".install-test.lua"
    $StagedLuacOutput = Join-Path $InstallStagingPath ".install-test.luac"

    try {
        @'
local value = 5
assert(value == 5)
'@ | Set-Content -LiteralPath $StagedLuacSource -Encoding ascii

        & $StagedLuac -o $StagedLuacOutput $StagedLuacSource

        if ($LASTEXITCODE -ne 0) {
            throw "Staged luac.exe could not compile the test source."
        }

        if (-not (Test-Path -LiteralPath $StagedLuacOutput -PathType Leaf)) {
            throw "Staged luac.exe did not produce bytecode."
        }
    }
    finally {
        foreach ($File in @($StagedLuacSource, $StagedLuacOutput)) {
            if (Test-Path -LiteralPath $File) {
                Remove-Item -LiteralPath $File -Force
            }
        }
    }

    Write-Success "Staged standalone compiler passed."

    # --------------------------------------------------------
    # 7.8 Verify staged executable DLL dependencies
    # --------------------------------------------------------

    Write-Step "Verifying staged executable DLL dependencies"

    $StagedLuaImports = @(
        Get-PeImportedDlls `
            -Executable $StagedLua `
            -ObjDumpPath $ObjDumpPath
    )

    if (-not (Test-PeImportsDll `
        -ImportedDlls $StagedLuaImports `
        -DllName "lua54.dll"
    )) {
        throw "Staged lua.exe does not import lua54.dll."
    }

    $StagedLuacImports = @(
        Get-PeImportedDlls `
            -Executable $StagedLuac `
            -ObjDumpPath $ObjDumpPath
    )

    if (Test-PeImportsDll `
        -ImportedDlls $StagedLuacImports `
        -DllName "lua54.dll"
    ) {
        throw "Staged luac.exe unexpectedly depends on lua54.dll."
    }

    Write-Success "Staged executable linkage checks passed."

    # --------------------------------------------------------
    # 7.9 Commit installation
    # --------------------------------------------------------

    Write-Step "Committing Lua installation"

    # Recheck immediately before moving the staging directory.
    if (Test-Path -LiteralPath $InstallPath) {
        throw "Installation destination appeared during staging: $InstallPath"
    }

    Move-Item `
        -LiteralPath $InstallStagingPath `
        -Destination $InstallPath

    Write-Success "Lua $LuaVersion installed successfully."
}
finally {
    # Remove staging data if installation did not complete.
    if (Test-Path -LiteralPath $InstallStagingPath) {
        Remove-Item `
            -LiteralPath $InstallStagingPath `
            -Recurse `
            -Force
    }
}

# ------------------------------------------------------------
# 8. Verify final installation
# ------------------------------------------------------------

Write-Step "Verifying final Lua installation"

$InstalledLua = Join-Path $InstallBin "lua.exe"
$InstalledLuac = Join-Path $InstallBin "luac.exe"
$InstalledDll = Join-Path $InstallBin "lua54.dll"
$InstalledImportLibrary = Join-Path $InstallLib "liblua54.dll.a"

# Verify installed interpreter.
$InstalledLuaOutput = & $InstalledLua -e "print(_VERSION)"
$InstalledLuaExitCode = $LASTEXITCODE
$InstalledLuaText = ($InstalledLuaOutput | Out-String).Trim()

if ($InstalledLuaExitCode -ne 0) {
    throw "Installed Lua interpreter failed."
}

if ($InstalledLuaText -ne "Lua 5.4") {
    throw "Installed Lua interpreter returned an unexpected version."
}

Write-Success "Installed Lua interpreter passed."

# Verify installed compiler.
$InstalledLuacOutput = & $InstalledLuac -v 2>&1
$InstalledLuacExitCode = $LASTEXITCODE
$InstalledLuacText = ($InstalledLuacOutput | Out-String).Trim()

if ($InstalledLuacExitCode -ne 0) {
    throw "Installed Lua compiler failed."
}

if ($InstalledLuacText -notmatch "Lua $([regex]::Escape($LuaVersion))") {
    throw "Installed Lua compiler reports an unexpected version."
}

Write-Success "Installed standalone compiler passed."

# Verify final files.
foreach ($File in @(
    $InstalledLua,
    $InstalledLuac,
    $InstalledDll,
    $InstalledImportLibrary,
    (Join-Path $InstallInclude "lua.h"),
    (Join-Path $InstallInclude "luaconf.h"),
    (Join-Path $InstallInclude "lauxlib.h"),
    (Join-Path $InstallInclude "lualib.h"),
    (Join-Path $InstallInclude "lua.hpp")
)) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        throw "Final installation file is missing: $File"
    }
}

Write-Success "All final installation files are present."

# ------------------------------------------------------------
# 9. Final report
# ------------------------------------------------------------

Write-Step "Lua $LuaVersion installation completed"

Write-Host ""
Write-Host "Lua version    : $LuaVersion"
Write-Host "Installation   : $InstallPath"
Write-Host "Executables    : $InstallBin"
Write-Host "Headers        : $InstallInclude"
Write-Host "Libraries      : $InstallLib"
Write-Host ""

Write-Host "GCC version    : $GccVersion"
Write-Host "Target         : $GccTarget"
Write-Host "Thread model   : POSIX"
Write-Host "C runtime      : $CrtRuntime"
Write-Host ""

Write-Host "Shared runtime : $InstalledDll"
Write-Host "Interpreter    : $InstalledLua"
Write-Host "Compiler       : $InstalledLuac"
Write-Host "Import library : $InstalledImportLibrary"
Write-Host ""

Write-Success "Lua source preparation passed."
Write-Success "WinLibs GCC toolchain validation passed."
Write-Success "Lua $LuaVersion build validation passed."
Write-Success "Lua $LuaVersion installation validation passed."

Write-Host ""
Write-Host "Next step: configure PATH and validate Lua from a new PowerShell session."

