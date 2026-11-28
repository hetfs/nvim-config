#requires -Version 7.0
<#
.SYNOPSIS
    Build, install, configure PATH, and validate Lua 5.4.9 on Windows x64.

.DESCRIPTION
    Builds Lua 5.4.9 as a shared DLL and standalone bytecode compiler using
    WinLibs GCC/G++ targeting x86_64-w64-mingw32, POSIX threads, and UCRT.

    Installs to C:\DevTools\Lua\5.4, adds the bin directory to the persistent
    user PATH and current process PATH, then validates the installed tools.

    Does not install GCC/WinLibs or modify an existing Lua installation.

.OUTPUTS
    bin\lua54.dll
    bin\lua.exe
    bin\luac.exe
    lib\liblua54.dll.a
    include\lua.h, luaconf.h, lauxlib.h, lualib.h, lua.hpp

.EXAMPLE
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File .\lua54-install.ps1
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$script:LuaVersion = '5.4.9'
$script:LuaRoot = 'C:\DevTools\Lua'
$script:InstallPath = Join-Path $script:LuaRoot '5.4'
$script:InstallBin = Join-Path $script:InstallPath 'bin'
$script:InstallInclude = Join-Path $script:InstallPath 'include'
$script:InstallLib = Join-Path $script:InstallPath 'lib'

$script:ArchiveName = "lua-$($script:LuaVersion).tar.gz"
$script:DownloadRoot = Join-Path $script:LuaRoot 'downloads'
$script:SourceRoot = Join-Path $script:LuaRoot 'source'
$script:BuildRoot = Join-Path $script:LuaRoot 'build'
$script:ArchivePath = Join-Path $script:DownloadRoot $script:ArchiveName
$script:SourcePath = Join-Path $script:SourceRoot "lua-$($script:LuaVersion)"
$script:BuildPath = Join-Path $script:BuildRoot "lua-$($script:LuaVersion)"
$script:LuaSourceDirectory = Join-Path $script:SourcePath 'src'
$script:DownloadUrl = "https://www.lua.org/ftp/$($script:ArchiveName)"

# Only versions with an explicitly registered SHA-256 checksum are accepted.
$script:LuaChecksums = @{
    '5.4.9' = '2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6'
}

if (-not $script:LuaChecksums.ContainsKey($script:LuaVersion)) {
    throw "Lua $($script:LuaVersion) has no registered SHA-256 checksum."
}

$script:ExpectedSha256 = $script:LuaChecksums[$script:LuaVersion]
if ($script:ExpectedSha256 -notmatch '^[A-Fa-f0-9]{64}$') {
    throw "The registered SHA-256 checksum for Lua $($script:LuaVersion) is invalid."
}

# Build outputs
$script:LuaDllPath = Join-Path $script:BuildPath 'lua54.dll'
$script:ImportLibraryPath = Join-Path $script:BuildPath 'liblua54.dll.a'
$script:LuaExePath = Join-Path $script:BuildPath 'lua.exe'
$script:LuacExePath = Join-Path $script:BuildPath 'luac.exe'

# Toolchain paths are initialized during validation.
$script:GccPath = $null
$script:ObjDumpPath = $null
$script:GccVersion = $null
$script:GccTarget = $null
$script:CrtRuntime = $null

# ---------------------------------------------------------------------------
# Output and common helpers
# ---------------------------------------------------------------------------

function Write-Section {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Status {
    param(
        [ValidateSet('PASS', 'INFO', 'SKIP', 'WARN', 'FAIL')]
        [string]$Status,
        [Parameter(Mandatory)][string]$Message
    )

    $color = switch ($Status) {
        'PASS' { 'Green' }
        'INFO' { 'Cyan' }
        'SKIP' { 'DarkGray' }
        'WARN' { 'Yellow' }
        'FAIL' { 'Red' }
    }

    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Get-Application {
    param([Parameter(Mandatory)][string[]]$Names)

    foreach ($name in $Names) {
        $command = Get-Command -Name $name -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($command) {
            return $command
        }
    }

    return $null
}

function Test-PathEntry {
    param(
        [AllowEmptyString()][string]$PathValue,
        [Parameter(Mandatory)][string]$Entry
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $false
    }

    $expected = $Entry.Trim().TrimEnd('\', '/')

    foreach ($item in ($PathValue -split ';')) {
        if ([string]::IsNullOrWhiteSpace($item)) {
            continue
        }

        $current = $item.Trim().TrimEnd('\', '/')
        if ([string]::Equals($current, $expected, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Add-LuaBinToPath {
    param([Parameter(Mandatory)][string]$Directory)

    Write-Section 'Configuring Lua user PATH'

    $userPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)

    if (-not (Test-PathEntry -PathValue $userPath -Entry $Directory)) {
        $existingEntries = @(
            $userPath -split ';' |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )

        $newUserPath = (@($existingEntries) + $Directory) -join ';'
        [Environment]::SetEnvironmentVariable(
            'Path',
            $newUserPath,
            [EnvironmentVariableTarget]::User
        )
        Write-Status PASS "Added $Directory to the persistent user PATH."
    }
    else {
        Write-Status SKIP 'Lua bin directory is already in the persistent user PATH.'
    }

    if (-not (Test-PathEntry -PathValue $env:PATH -Entry $Directory)) {
        $env:PATH = "$Directory;$env:PATH"
        Write-Status PASS 'Added Lua bin directory to the current PowerShell PATH.'
    }
    else {
        Write-Status SKIP 'Lua bin directory is already in the current PowerShell PATH.'
    }
}

function Test-RequiredFiles {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string[]]$Files
    )

    foreach ($file in $Files) {
        if (-not (Test-Path -LiteralPath (Join-Path $Directory $file) -PathType Leaf)) {
            return $false
        }
    }

    return $true
}

# ---------------------------------------------------------------------------
# Source archive and extraction
# ---------------------------------------------------------------------------

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Test-LuaSource {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $false
    }

    $required = @(
        'Makefile', 'README',
        'src\lua.h', 'src\luaconf.h', 'src\lauxlib.h',
        'src\lualib.h', 'src\lua.hpp', 'src\lua.c', 'src\luac.c'
    )

    foreach ($relativePath in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $relativePath) -PathType Leaf)) {
            return $false
        }
    }

    return $true
}

function Get-VerifiedLuaSource {
    Write-Section "Preparing Lua $($script:LuaVersion) source"

    foreach ($directory in @(
        $script:LuaRoot,
        $script:DownloadRoot,
        $script:SourceRoot,
        $script:BuildRoot,
        $script:BuildPath
    )) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if (Test-Path -LiteralPath $script:ArchivePath -PathType Leaf) {
        $existingHash = Get-Sha256 -Path $script:ArchivePath
        if (-not $existingHash.Equals(
            $script:ExpectedSha256,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            Write-Status WARN 'Existing Lua archive has an invalid checksum; it will be replaced.'
            Remove-Item -LiteralPath $script:ArchivePath -Force
        }
        else {
            Write-Status PASS 'Existing Lua source archive passed SHA-256 verification.'
        }
    }

    if (-not (Test-Path -LiteralPath $script:ArchivePath -PathType Leaf)) {
        Write-Section "Downloading official Lua $($script:LuaVersion) source"

        $partialPath = Join-Path $script:DownloadRoot (
            ".$($script:ArchiveName).$([guid]::NewGuid().ToString('N')).partial"
        )

        try {
            Invoke-WebRequest -Uri $script:DownloadUrl -OutFile $partialPath -TimeoutSec 120

            $actualHash = Get-Sha256 -Path $partialPath
            if (-not $actualHash.Equals(
                $script:ExpectedSha256,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                throw "Lua archive SHA-256 mismatch. Expected $($script:ExpectedSha256); received $actualHash."
            }

            Move-Item -LiteralPath $partialPath -Destination $script:ArchivePath -Force
            Write-Status PASS 'Lua source archive downloaded and checksum verified.'
        }
        finally {
            if (Test-Path -LiteralPath $partialPath) {
                Remove-Item -LiteralPath $partialPath -Force
            }
        }
    }

    if (Test-LuaSource -Path $script:SourcePath) {
        Write-Status PASS 'Existing Lua source tree passed structural validation.'
        return
    }

    if (Test-Path -LiteralPath $script:SourcePath) {
        throw "Lua source directory exists but is incomplete: $($script:SourcePath). It was not overwritten."
    }

    $tar = Get-Application -Names @('tar.exe', 'tar')
    if (-not $tar) {
        throw 'tar.exe was not found. Install or expose Windows tar before continuing.'
    }

    $extractPath = Join-Path $script:SourceRoot (
        ".extract-$($script:LuaVersion)-$([guid]::NewGuid().ToString('N'))"
    )

    New-Item -ItemType Directory -Path $extractPath | Out-Null

    try {
        Write-Section "Extracting $($script:ArchiveName)"
        & $tar.Source -xzf $script:ArchivePath -C $extractPath

        if ($LASTEXITCODE -ne 0) {
            throw "Lua archive extraction failed. tar exit code: $LASTEXITCODE"
        }

        $extractedSource = Join-Path $extractPath "lua-$($script:LuaVersion)"
        if (-not (Test-LuaSource -Path $extractedSource)) {
            throw 'Extracted archive does not contain the expected Lua source files.'
        }

        Move-Item -LiteralPath $extractedSource -Destination $script:SourcePath
        Write-Status PASS 'Lua source extracted and validated.'
    }
    finally {
        if (Test-Path -LiteralPath $extractPath) {
            Remove-Item -LiteralPath $extractPath -Recurse -Force
        }
    }
}

# ---------------------------------------------------------------------------
# WinLibs GCC validation: x64, POSIX, UCRT
# ---------------------------------------------------------------------------

function Get-GccToolPath {
    param([Parameter(Mandatory)][string]$ToolName)

    $output = & $script:GccPath "-print-prog-name=$ToolName" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "GCC could not locate its $ToolName executable."
    }

    $reportedPath = ($output | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($reportedPath)) {
        throw "GCC returned an empty path for $ToolName."
    }

    if (Test-Path -LiteralPath $reportedPath -PathType Leaf) {
        return (Resolve-Path -LiteralPath $reportedPath).Path
    }

    $resolved = Get-Application -Names @($reportedPath, "$reportedPath.exe")
    if (-not $resolved) {
        throw "GCC reported '$reportedPath' for $ToolName, but it could not be resolved."
    }

    return $resolved.Source
}

function Get-PeImportedDlls {
    param([Parameter(Mandatory)][string]$Executable)

    $output = & $script:ObjDumpPath -p $Executable 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect PE imports: $Executable"
    }

    $imports = @(
        foreach ($line in $output) {
            $lineText = [string]$line
            if ($lineText -match '^\s*DLL Name:\s*(?<Name>\S+)\s*$') {
                $Matches.Name.ToLowerInvariant()
            }
        }
    )

    return $imports
}

function Test-DllImported {
    param(
        [Parameter(Mandatory)][string[]]$ImportedDlls,
        [Parameter(Mandatory)][string]$DllName
    )

    return ($ImportedDlls -contains $DllName.ToLowerInvariant())
}

function Test-GccToolchain {
    Write-Section 'Validating WinLibs GCC toolchain'

    $gcc = Get-Application -Names @('gcc.exe', 'gcc')
    if (-not $gcc) {
        throw 'GCC (gcc.exe) was not found in PATH.'
    }

    $script:GccPath = $gcc.Source

    $versionOutput = & $script:GccPath --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to retrieve GCC version.'
    }
    $script:GccVersion = ([string]($versionOutput | Select-Object -First 1)).Trim()

    $targetOutput = & $script:GccPath -dumpmachine 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to determine GCC target architecture.'
    }
    $script:GccTarget = ($targetOutput | Out-String).Trim()

    if ($script:GccTarget -ne 'x86_64-w64-mingw32') {
        throw "Unsupported GCC target. Expected x86_64-w64-mingw32; received $($script:GccTarget)."
    }

    $details = (& $script:GccPath -v 2>&1 | Out-String)
    if ($details -notmatch '(?im)^\s*Thread model:\s*posix\s*$') {
        throw "GCC does not report the required POSIX thread model.`n$details"
    }

    $script:ObjDumpPath = Get-GccToolPath -ToolName 'objdump'
    $linkerPath = Get-GccToolPath -ToolName 'ld'

    Write-Status PASS "GCC: $($script:GccVersion)"
    Write-Status PASS "Target: $($script:GccTarget)"
    Write-Status PASS 'GCC POSIX thread model confirmed.'
    Write-Status PASS "GNU linker: $linkerPath"
    Write-Status PASS "GNU objdump: $($script:ObjDumpPath)"

    $gxx = Get-Application -Names @('g++.exe', 'g++')
    if ($gxx) {
        $gxxVersion = & $gxx.Source --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status INFO "G++ available: $(([string]($gxxVersion | Select-Object -First 1)).Trim())"
        }
    }
    else {
        Write-Status INFO 'G++ is not present; it is not required to build Lua, which is written in C.'
    }

    Test-GccUcrtRuntime
}

function Test-GccUcrtRuntime {
    Write-Section 'Testing GCC compilation, execution, and UCRT linkage'

    $testDirectory = Join-Path $script:BuildPath (
        ".toolchain-check-$([guid]::NewGuid().ToString('N'))"
    )
    New-Item -ItemType Directory -Path $testDirectory | Out-Null

    $source = Join-Path $testDirectory 'toolchain-check.c'
    $executable = Join-Path $testDirectory 'toolchain-check.exe'

    @'
#include <stdio.h>
int main(void)
{
    puts("WinLibs GCC toolchain check passed.");
    return 0;
}
'@ | Set-Content -LiteralPath $source -Encoding ascii

    try {
        & $script:GccPath -Wall -Wextra -Werror $source -o $executable
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $executable -PathType Leaf)) {
            throw 'GCC failed to compile the toolchain test program.'
        }

        $output = & $executable
        if ($LASTEXITCODE -ne 0 -or ($output | Out-String).Trim() -ne 'WinLibs GCC toolchain check passed.') {
            throw 'The compiled GCC test executable failed.'
        }

        $imports = @(Get-PeImportedDlls -Executable $executable)
        if ($imports.Count -eq 0) {
            throw 'No DLL imports were found; the C runtime could not be established.'
        }

        $ucrtImports = @($imports | Where-Object {
            $_ -eq 'ucrtbase.dll' -or $_ -match '^(api|ext)-ms-win-crt-'
        })
        $msvcrtImports = @($imports | Where-Object { $_ -eq 'msvcrt.dll' })

        if ($ucrtImports.Count -gt 0 -and $msvcrtImports.Count -gt 0) {
            throw "The test executable imports both UCRT and MSVCRT; runtime configuration is mixed."
        }

        if ($ucrtImports.Count -eq 0) {
            throw "Expected UCRT imports, but none were detected. Imports: $($imports -join ', ')"
        }

        $script:CrtRuntime = 'UCRT'
        Write-Status PASS 'GCC compiled and ran a Windows executable linked against UCRT.'
    }
    finally {
        if (Test-Path -LiteralPath $testDirectory) {
            Remove-Item -LiteralPath $testDirectory -Recurse -Force
        }
    }
}

# ---------------------------------------------------------------------------
# Lua build
# ---------------------------------------------------------------------------

function Build-Lua {
    Write-Section "Building Lua $($script:LuaVersion)"

    $coreSources = @(
        'lapi.c', 'lcode.c', 'lctype.c', 'ldebug.c', 'ldo.c',
        'ldump.c', 'lfunc.c', 'lgc.c', 'llex.c', 'lmem.c',
        'lobject.c', 'lopcodes.c', 'lparser.c', 'lstate.c',
        'lstring.c', 'ltable.c', 'ltm.c', 'lundump.c', 'lvm.c', 'lzio.c'
    )

    $librarySources = @(
        'lauxlib.c', 'lbaselib.c', 'lcorolib.c', 'ldblib.c',
        'liolib.c', 'lmathlib.c', 'loadlib.c', 'loslib.c',
        'lstrlib.c', 'ltablib.c', 'lutf8lib.c', 'linit.c'
    )

    $luaLibrarySources = @(
        foreach ($name in ($coreSources + $librarySources)) {
            Join-Path $script:LuaSourceDirectory $name
        }
    )

    $luaMain = Join-Path $script:LuaSourceDirectory 'lua.c'
    $luacMain = Join-Path $script:LuaSourceDirectory 'luac.c'

    foreach ($file in @($luaLibrarySources) + @($luaMain, $luacMain)) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
            throw "Required Lua build input is missing: $file"
        }
    }

    foreach ($artifact in @(
        $script:LuaDllPath,
        $script:ImportLibraryPath,
        $script:LuaExePath,
        $script:LuacExePath
    )) {
        if (Test-Path -LiteralPath $artifact) {
            Remove-Item -LiteralPath $artifact -Force
        }
    }

    Write-Section 'Building shared lua54.dll and import library'

    $dllArguments = @(
        '-O2', '-Wall', '-Wextra',
        '-DLUA_BUILD_AS_DLL',
        '-shared',
        "-Wl,--out-implib,$($script:ImportLibraryPath)",
        '-o', $script:LuaDllPath
    ) + $luaLibrarySources + @('-lm')

    & $script:GccPath @dllArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Building lua54.dll failed. GCC exit code: $LASTEXITCODE"
    }

    foreach ($artifact in @($script:LuaDllPath, $script:ImportLibraryPath)) {
        if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) {
            throw "Expected build artifact was not produced: $artifact"
        }
    }
    Write-Status PASS 'Shared Lua DLL and GCC import library built.'

    Write-Section 'Building Lua interpreter'

    $luaArguments = @(
        '-O2', '-Wall', '-Wextra',
        '-DLUA_USE_DLL',
        $luaMain,
        "-L$($script:BuildPath)",
        '-llua54', '-lm',
        '-o', $script:LuaExePath
    )

    & $script:GccPath @luaArguments
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $script:LuaExePath -PathType Leaf)) {
        throw 'Building lua.exe failed.'
    }
    Write-Status PASS 'Lua interpreter linked against lua54.dll.'

    Write-Section 'Building standalone luac.exe'

    $luacArguments = @(
        '-O2', '-Wall', '-Wextra',
        $luacMain
    ) + $luaLibrarySources + @('-lm', '-o', $script:LuacExePath)

    & $script:GccPath @luacArguments
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $script:LuacExePath -PathType Leaf)) {
        throw 'Building standalone luac.exe failed.'
    }

    foreach ($artifact in @(
        $script:LuaDllPath,
        $script:ImportLibraryPath,
        $script:LuaExePath,
        $script:LuacExePath
    )) {
        if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) {
            throw "Expected build artifact is missing: $artifact"
        }
    }

    Write-Status PASS 'All four expected build artifacts exist.'

    Test-LuaBuildOutputs
    Test-LuaExternalApi -LuaLibrarySources $luaLibrarySources
}

function Test-LuaBuildOutputs {
    Write-Section 'Testing Lua interpreter and standalone compiler'

    $luaVersionOutput = & $script:LuaExePath -v 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'lua.exe failed its version check.'
    }

    $luaVersionText = $luaVersionOutput -join "`n"
    if ($luaVersionText -notmatch "Lua $([regex]::Escape($script:LuaVersion))") {
        throw "Unexpected Lua interpreter version: $luaVersionText"
    }

    $runtimeOutput = & $script:LuaExePath -e "assert(_VERSION == 'Lua 5.4'); print(_VERSION)"
    if ($LASTEXITCODE -ne 0 -or ($runtimeOutput | Out-String).Trim() -ne 'Lua 5.4') {
        throw 'lua.exe failed its Lua runtime execution test.'
    }

    $luacVersionOutput = & $script:LuacExePath -v 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'luac.exe failed its version check.'
    }

    $luacVersionText = $luacVersionOutput -join "`n"
    if ($luacVersionText -notmatch "Lua $([regex]::Escape($script:LuaVersion))") {
        throw "Unexpected Lua compiler version: $luacVersionText"
    }

    $testSource = Join-Path $script:BuildPath '.luac-test.lua'
    $testOutput = Join-Path $script:BuildPath '.luac-test.luac'

    try {
        @'
local message = "Standalone Lua compiler works"
print(message)
'@ | Set-Content -LiteralPath $testSource -Encoding ascii

        & $script:LuacExePath -o $testOutput $testSource
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $testOutput -PathType Leaf)) {
            throw 'luac.exe failed to compile the test Lua source.'
        }
    }
    finally {
        foreach ($file in @($testSource, $testOutput)) {
            if (Test-Path -LiteralPath $file) {
                Remove-Item -LiteralPath $file -Force
            }
        }
    }

    Write-Status PASS "lua.exe and luac.exe report Lua $($script:LuaVersion) and execute successfully."

    Write-Section 'Checking DLL dependencies and Lua DLL exports'

    $luaImports = @(Get-PeImportedDlls -Executable $script:LuaExePath)
    if (-not (Test-DllImported -ImportedDlls $luaImports -DllName 'lua54.dll')) {
        throw 'lua.exe does not import the expected lua54.dll.'
    }

    $luacImports = @(Get-PeImportedDlls -Executable $script:LuacExePath)
    if (Test-DllImported -ImportedDlls $luacImports -DllName 'lua54.dll') {
        throw 'luac.exe unexpectedly depends on lua54.dll.'
    }

    $exportOutput = & $script:ObjDumpPath -p $script:LuaDllPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to inspect lua54.dll exports.'
    }

    $exportText = $exportOutput | Out-String
    if ($exportText -notmatch '(?i)Export Table' -or
        $exportText -notmatch '(?m)\bluaL_newstate\b' -or
        $exportText -notmatch '(?m)\blua_close\b') {
        throw 'lua54.dll does not expose the expected Lua API exports.'
    }

    Write-Status PASS 'lua.exe imports lua54.dll; luac.exe is standalone; required Lua API exports exist.'
}

function Test-LuaExternalApi {
    param([Parameter(Mandatory)][string[]]$LuaLibrarySources)

    Write-Section 'Testing external C application linkage'

    $testDirectory = Join-Path $script:BuildPath (
        ".api-check-$([guid]::NewGuid().ToString('N'))"
    )
    New-Item -ItemType Directory -Path $testDirectory | Out-Null

    $source = Join-Path $testDirectory 'lua-api-check.c'
    $executable = Join-Path $testDirectory 'lua-api-check.exe'

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
'@ | Set-Content -LiteralPath $source -Encoding ascii

    try {
        $arguments = @(
            '-O2', '-Wall', '-Wextra',
            '-DLUA_USE_DLL',
            "-I$($script:LuaSourceDirectory)",
            $source,
            "-L$($script:BuildPath)",
            '-llua54', '-lm',
            '-o', $executable
        )

        & $script:GccPath @arguments
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $executable -PathType Leaf)) {
            throw 'External C API test failed to compile.'
        }

        Copy-Item -LiteralPath $script:LuaDllPath -Destination $testDirectory
        $output = & $executable
        if ($LASTEXITCODE -ne 0 -or ($output | Out-String).Trim() -ne 'External Lua C API check passed.') {
            throw 'External C API test failed to execute against lua54.dll.'
        }

        Write-Status PASS 'External C application linked and executed against lua54.dll.'
    }
    finally {
        if (Test-Path -LiteralPath $testDirectory) {
            Remove-Item -LiteralPath $testDirectory -Recurse -Force
        }
    }
}

# ---------------------------------------------------------------------------
# Staged installation
# ---------------------------------------------------------------------------

function Install-Lua {
    Write-Section "Installing Lua $($script:LuaVersion)"

    if (Test-Path -LiteralPath $script:InstallPath) {
        throw "Installation directory already exists and will not be overwritten: $($script:InstallPath)"
    }

    $stagingPath = Join-Path $script:LuaRoot (
        ".5.4-staging-$([guid]::NewGuid().ToString('N'))"
    )

    $stagingBin = Join-Path $stagingPath 'bin'
    $stagingInclude = Join-Path $stagingPath 'include'
    $stagingLib = Join-Path $stagingPath 'lib'

    try {
        foreach ($directory in @($stagingBin, $stagingInclude, $stagingLib)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }

        Copy-Item -LiteralPath $script:LuaExePath -Destination $stagingBin
        Copy-Item -LiteralPath $script:LuacExePath -Destination $stagingBin
        Copy-Item -LiteralPath $script:LuaDllPath -Destination $stagingBin
        Copy-Item -LiteralPath $script:ImportLibraryPath -Destination $stagingLib

        foreach ($header in @('lua.h', 'luaconf.h', 'lauxlib.h', 'lualib.h', 'lua.hpp')) {
            $headerPath = Join-Path $script:LuaSourceDirectory $header
            if (-not (Test-Path -LiteralPath $headerPath -PathType Leaf)) {
                throw "Required Lua header is missing: $headerPath"
            }
            Copy-Item -LiteralPath $headerPath -Destination $stagingInclude
        }

        if (-not (Test-RequiredFiles -Directory $stagingBin -Files @('lua.exe', 'luac.exe', 'lua54.dll')) -or
            -not (Test-RequiredFiles -Directory $stagingInclude -Files @('lua.h', 'luaconf.h', 'lauxlib.h', 'lualib.h', 'lua.hpp')) -or
            -not (Test-RequiredFiles -Directory $stagingLib -Files @('liblua54.dll.a'))) {
            throw 'Staged Lua installation is incomplete.'
        }

        # Run the staged interpreter and compiler before committing the directory.
        $stagedLua = Join-Path $stagingBin 'lua.exe'
        $stagedOutput = & $stagedLua -e "print(_VERSION)"
        if ($LASTEXITCODE -ne 0 -or ($stagedOutput | Out-String).Trim() -ne 'Lua 5.4') {
            throw 'Staged lua.exe failed its runtime check.'
        }

        $stagedLuac = Join-Path $stagingBin 'luac.exe'
        $stagedLuacVersion = & $stagedLuac -v 2>&1
        if ($LASTEXITCODE -ne 0 -or (($stagedLuacVersion -join "`n") -notmatch "Lua $([regex]::Escape($script:LuaVersion))")) {
            throw 'Staged luac.exe failed its version check.'
        }

        $stagedLuaImports = @(Get-PeImportedDlls -Executable $stagedLua)
        if (-not (Test-DllImported -ImportedDlls $stagedLuaImports -DllName 'lua54.dll')) {
            throw 'Staged lua.exe does not import lua54.dll.'
        }

        $stagedLuacImports = @(Get-PeImportedDlls -Executable $stagedLuac)
        if (Test-DllImported -ImportedDlls $stagedLuacImports -DllName 'lua54.dll') {
            throw 'Staged luac.exe unexpectedly depends on lua54.dll.'
        }

        if (Test-Path -LiteralPath $script:InstallPath) {
            throw "Installation destination appeared during staging: $($script:InstallPath)"
        }

        Move-Item -LiteralPath $stagingPath -Destination $script:InstallPath
        Write-Status PASS "Lua $($script:LuaVersion) installed to $($script:InstallPath)."
    }
    finally {
        if (Test-Path -LiteralPath $stagingPath) {
            Remove-Item -LiteralPath $stagingPath -Recurse -Force
        }
    }
}

# ---------------------------------------------------------------------------
# Final PATH and installed-tool validation
# ---------------------------------------------------------------------------

function Test-InstalledLua {
    Write-Section 'Configuring PATH and validating final Lua installation'

    foreach ($file in @(
        (Join-Path $script:InstallBin 'lua.exe'),
        (Join-Path $script:InstallBin 'luac.exe'),
        (Join-Path $script:InstallBin 'lua54.dll'),
        (Join-Path $script:InstallLib 'liblua54.dll.a'),
        (Join-Path $script:InstallInclude 'lua.h'),
        (Join-Path $script:InstallInclude 'luaconf.h'),
        (Join-Path $script:InstallInclude 'lauxlib.h'),
        (Join-Path $script:InstallInclude 'lualib.h'),
        (Join-Path $script:InstallInclude 'lua.hpp')
    )) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
            throw "Final installation file is missing: $file"
        }
    }

    Add-LuaBinToPath -Directory $script:InstallBin

    $luaCommand = Get-Application -Names @('lua.exe', 'lua')
    if (-not $luaCommand) {
        throw 'lua.exe is not discoverable on PATH after PATH configuration.'
    }

    $expectedLua = [System.IO.Path]::GetFullPath((Join-Path $script:InstallBin 'lua.exe'))
    $actualLua = [System.IO.Path]::GetFullPath($luaCommand.Source)
    if (-not $actualLua.Equals($expectedLua, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unexpected Lua executable resolved. Expected '$expectedLua'; received '$actualLua'."
    }

    $luaOutput = & $luaCommand.Source -v 2>&1
    if ($LASTEXITCODE -ne 0 -or (($luaOutput -join "`n") -notmatch "Lua $([regex]::Escape($script:LuaVersion))")) {
        throw 'Installed Lua interpreter failed its final version check.'
    }

    $runtimeOutput = & $luaCommand.Source -e "assert(_VERSION == 'Lua 5.4'); print(_VERSION); print(package.cpath)"
    if ($LASTEXITCODE -ne 0) {
        throw 'Installed Lua runtime or C module search path check failed.'
    }

    $runtimeLines = @($runtimeOutput | ForEach-Object { [string]$_ })
    if ($runtimeLines.Count -lt 2 -or $runtimeLines[0].Trim() -ne 'Lua 5.4' -or
        [string]::IsNullOrWhiteSpace($runtimeLines[1])) {
        throw "Lua returned an invalid runtime or empty C module search path: $($runtimeLines -join "`n")"
    }

    $luacCommand = Get-Application -Names @('luac.exe', 'luac')
    if (-not $luacCommand) {
        throw 'luac.exe is not discoverable on PATH after PATH configuration.'
    }

    $expectedLuac = [System.IO.Path]::GetFullPath((Join-Path $script:InstallBin 'luac.exe'))
    $actualLuac = [System.IO.Path]::GetFullPath($luacCommand.Source)
    if (-not $actualLuac.Equals($expectedLuac, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unexpected Lua compiler resolved. Expected '$expectedLuac'; received '$actualLuac'."
    }

    $luacOutput = & $luacCommand.Source -v 2>&1
    if ($LASTEXITCODE -ne 0 -or (($luacOutput -join "`n") -notmatch "Lua $([regex]::Escape($script:LuaVersion))")) {
        throw 'Installed Lua bytecode compiler failed its final version check.'
    }

    Write-Status PASS "lua resolves to $actualLua"
    Write-Status PASS "luac resolves to $actualLuac"
    Write-Status PASS "Lua runtime: $($runtimeLines[0])"
    Write-Status PASS "Lua C module search path is available: $($runtimeLines[1])"
    Write-Status PASS 'All installed binaries, headers, and libraries are present.'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Write-Host ''
    Write-Status INFO "Starting Lua $($script:LuaVersion) x64 build and installation."

    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw 'This script supports Windows only.'
    }

    if (Test-Path -LiteralPath $script:InstallPath) {
        throw "Lua installation already exists: $($script:InstallPath). Existing installations are never overwritten."
    }

    Get-VerifiedLuaSource
    Test-GccToolchain
    Build-Lua
    Install-Lua
    Test-InstalledLua

    Write-Section "Lua $($script:LuaVersion) installation completed"

    Write-Host "Installation   : $($script:InstallPath)"
    Write-Host "Executables    : $($script:InstallBin)"
    Write-Host "Headers        : $($script:InstallInclude)"
    Write-Host "Libraries      : $($script:InstallLib)"
    Write-Host "GCC            : $($script:GccVersion)"
    Write-Host "Target         : $($script:GccTarget)"
    Write-Host "Thread model   : POSIX"
    Write-Host "C runtime      : $($script:CrtRuntime)"
    Write-Host ''
    Write-Status PASS 'Lua source preparation, toolchain validation, build, installation, PATH configuration, and final verification completed.'
    Write-Host 'Open a new PowerShell or Neovim process to inherit the persistent user PATH.'
    Write-Host ''
    exit 0
}
catch {
    Write-Status FAIL $_.Exception.Message
    exit 1
}
