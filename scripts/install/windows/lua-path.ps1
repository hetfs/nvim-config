

#requires -Version 7.0

<#
.SYNOPSIS
    Configure and validate the standalone Lua 5.4 Windows PATH.

.DESCRIPTION
    1. Adds Lua's bin directory to the persistent Windows user PATH.
    2. Updates PATH in the current PowerShell process.
    3. Validates lua.exe and luac.exe.
    4. Validates Lua's C module search path.

.NOTES
    Requires an existing Lua 5.4 installation.
    Does not install, modify, or remove Lua files.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$LuaInstallPath = "C:\DevTools\Lua\5.4"
$LuaBin = Join-Path $LuaInstallPath "bin"

$LuaExe = Join-Path $LuaBin "lua.exe"
$LuacExe = Join-Path $LuaBin "luac.exe"
$LuaDll = Join-Path $LuaBin "lua54.dll"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Section {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Pass {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Test-PathEntry {
    param(
        [Parameter(Mandatory)]
        [string]$PathValue,

        [Parameter(Mandatory)]
        [string]$Directory
    )

    foreach ($Entry in ($PathValue -split ";")) {
        if (
            -not [string]::IsNullOrWhiteSpace($Entry) -and
            $Entry.Trim().TrimEnd("\") -ieq $Directory.TrimEnd("\")
        ) {
            return $true
        }
    }

    return $false
}

# ---------------------------------------------------------------------------
# Check existing Lua installation
# ---------------------------------------------------------------------------

Write-Section "Checking Lua 5.4 installation"

foreach ($File in @($LuaExe, $LuacExe, $LuaDll)) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        throw "Required Lua installation file is missing: $File"
    }
}

Write-Pass "Lua 5.4 installation files are present."

# ---------------------------------------------------------------------------
# Configure persistent Windows user PATH
# ---------------------------------------------------------------------------

Write-Section "Configuring persistent user PATH"

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

if (-not (Test-PathEntry -PathValue $UserPath -Directory $LuaBin)) {
    $NewUserPath = if ([string]::IsNullOrWhiteSpace($UserPath)) {
        $LuaBin
    }
    else {
        "$UserPath;$LuaBin"
    }

    [Environment]::SetEnvironmentVariable(
        "Path",
        $NewUserPath,
        "User"
    )

    Write-Pass "Lua bin directory added to persistent user PATH."
}
else {
    Write-Pass "Lua bin directory already exists in persistent user PATH."
}

# ---------------------------------------------------------------------------
# Update current PowerShell process PATH
# ---------------------------------------------------------------------------

Write-Section "Updating current PowerShell PATH"

if (-not (Test-PathEntry -PathValue $env:Path -Directory $LuaBin)) {
    $env:Path = "$LuaBin;$env:Path"
}

Write-Pass "Current PowerShell PATH updated."

# ---------------------------------------------------------------------------
# Validate Lua interpreter
# ---------------------------------------------------------------------------

Write-Section "Validating Lua interpreter"

$LuaCommand = Get-Command lua -ErrorAction Stop

if ($LuaCommand.Source -ine $LuaExe) {
    throw "Unexpected Lua executable resolved: $($LuaCommand.Source)"
}

$LuaVersionOutput = & lua -v 2>&1

if ($LASTEXITCODE -ne 0) {
    throw "Lua interpreter execution failed."
}

$LuaVersionText = $LuaVersionOutput -join "`n"

if ($LuaVersionText -notmatch 'Lua 5\.4\.9') {
    throw "Expected Lua 5.4.9, but received: $LuaVersionText"
}

Write-Host $LuaVersionText
Write-Pass "Lua interpreter validation passed."

# ---------------------------------------------------------------------------
# Validate Lua bytecode compiler
# ---------------------------------------------------------------------------

Write-Section "Validating Lua bytecode compiler"

$LuacCommand = Get-Command luac -ErrorAction Stop

if ($LuacCommand.Source -ine $LuacExe) {
    throw "Unexpected Lua compiler resolved: $($LuacCommand.Source)"
}

$LuacVersionOutput = & luac -v 2>&1

if ($LASTEXITCODE -ne 0) {
    throw "Lua bytecode compiler execution failed."
}

$LuacVersionText = $LuacVersionOutput -join "`n"

if ($LuacVersionText -notmatch 'Lua 5\.4\.9') {
    throw "Expected Lua 5.4.9, but received: $LuacVersionText"
}

Write-Host $LuacVersionText
Write-Pass "Lua bytecode compiler validation passed."

# ---------------------------------------------------------------------------
# Validate Lua C module search path
# ---------------------------------------------------------------------------

Write-Section "Validating Lua C module search path"

$LuaRuntimeOutput = & lua -e "print(_VERSION); print(package.cpath)" 2>&1

if ($LASTEXITCODE -ne 0) {
    throw "Lua runtime configuration validation failed."
}

$LuaRuntimeText = $LuaRuntimeOutput -join "`n"

if ($LuaRuntimeText -notmatch 'Lua 5\.4') {
    throw "Unexpected Lua runtime version: $LuaRuntimeText"
}

if ($LuaRuntimeText -notmatch [regex]::Escape($LuaBin)) {
    throw "Lua C module search path does not contain: $LuaBin"
}

Write-Host $LuaRuntimeText
Write-Pass "Lua C module search path validation passed."

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Section "Lua PATH configuration completed"

Write-Host ""
Write-Host "Lua installation : $LuaInstallPath"
Write-Host "Lua bin          : $LuaBin"
Write-Host "Persistent PATH  : Configured"
Write-Host "Process PATH     : Updated"
Write-Host "Lua version      : 5.4.9"
Write-Host ""

Write-Pass "Persistent user PATH configuration passed."
Write-Pass "Current PowerShell PATH configuration passed."
Write-Pass "Lua interpreter validation passed."
Write-Pass "Lua compiler validation passed."
Write-Pass "Lua C module search path validation passed."
