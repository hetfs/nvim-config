
#requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$ForceInstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# Configuration
# ============================================================

$LLVMVersion = "23.1.6"

$LLVMInstallerName = "LLVM-$LLVMVersion-win64.msi"

$LLVMDownloadUrl = "https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVMVersion/$LLVMInstallerName"

$LLVMInstaller = Join-Path $env:TEMP $LLVMInstallerName

$LLVMRoot = Join-Path $env:ProgramFiles "LLVM"
$LLVMBin = Join-Path $LLVMRoot "bin"

$LLVMTools = @(
    "clang.exe",
    "clangd.exe",
    "clang-format.exe",
    "clang-tidy.exe"
)

$NativeTools = @(
    "gcc",
    "g++"
)

$InstallerLog = Join-Path $env:TEMP "llvm-install.log"

# ============================================================
# Logging
# ============================================================

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Pass {
    param([string]$Message)
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-Section {
    param([string]$Message)

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor DarkCyan
}

# ============================================================
# PATH management
# ============================================================

function Get-NormalizedPath {
    param([string]$PathEntry)

    if ([string]::IsNullOrWhiteSpace($PathEntry)) {
        return ""
    }

    return $PathEntry.Trim().Trim('"').TrimEnd("\")
}

function Add-LLVMToUserPath {
    param(
        [Parameter(Mandatory)]
        [string]$PathEntry
    )

    $normalizedLLVMPath = Get-NormalizedPath $PathEntry

    if (-not (Test-Path $normalizedLLVMPath -PathType Container)) {
        throw "LLVM directory does not exist: $normalizedLLVMPath"
    }

    $userPath = [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )

    $entries = @(
        $userPath -split ";" |
            ForEach-Object {
                Get-NormalizedPath $_
            } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
    )

    $alreadyExists = @(
        $entries | Where-Object {
            $_ -ieq $normalizedLLVMPath
        }
    ).Count -gt 0

    if (-not $alreadyExists) {
        $updatedPath = (@($entries) + $normalizedLLVMPath) -join ";"

        [Environment]::SetEnvironmentVariable(
            "Path",
            $updatedPath,
            "User"
        )

        Write-Pass "LLVM added to persistent user PATH."
    }
    else {
        Write-Pass "LLVM already exists in user PATH."
    }
}

function Update-ProcessPath {
    param(
        [string]$AdditionalPath
    )

    $userPath = [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )

    $machinePath = [Environment]::GetEnvironmentVariable(
        "Path",
        "Machine"
    )

    $entries = @(
        $AdditionalPath
        $userPath
        $machinePath
        $env:Path
    ) -join ";"

    $uniqueEntries = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in ($entries -split ";")) {
        $normalized = Get-NormalizedPath $entry

        if ([string]::IsNullOrWhiteSpace($normalized)) {
            continue
        }

        if (-not ($uniqueEntries | Where-Object {
            $_ -ieq $normalized
        })) {
            $uniqueEntries.Add($normalized)
        }
    }

    $env:Path = $uniqueEntries -join ";"

    Write-Pass "Current PowerShell PATH refreshed."
}

# ============================================================
# LLVM installation
# ============================================================

function Test-LLVMInstallation {
    if (-not (Test-Path $LLVMBin -PathType Container)) {
        return $false
    }

    foreach ($tool in $LLVMTools) {
        $toolPath = Join-Path $LLVMBin $tool

        if (-not (Test-Path $toolPath -PathType Leaf)) {
            return $false
        }
    }

    return $true
}

function Install-LLVM {
    if ((Test-LLVMInstallation) -and -not $ForceInstall) {
        Write-Pass "LLVM installation already detected."
        return
    }

    if ($Check) {
        throw "LLVM is not fully installed. Run without -Check to install it."
    }

    Write-Info "Preparing LLVM $LLVMVersion installation..."

    if (-not (Test-Path $LLVMInstaller -PathType Leaf)) {
        Write-Info "Downloading $LLVMInstallerName..."

        Invoke-WebRequest `
            -Uri $LLVMDownloadUrl `
            -OutFile $LLVMInstaller `
            -UseBasicParsing

        Write-Pass "LLVM installer downloaded."
    }
    else {
        Write-Pass "Existing LLVM installer found."
    }

    $installerInfo = Get-Item $LLVMInstaller

    if ($installerInfo.Length -lt 100MB) {
        throw "LLVM installer appears incomplete: $($installerInfo.Length) bytes"
    }

    Write-Info "Installer size: $([math]::Round($installerInfo.Length / 1MB, 2)) MB"

    Write-Info "Installing LLVM..."

    $arguments = @(
        "/i"
        "`"$LLVMInstaller`""
        "/passive"
        "/norestart"
        "/L*v"
        "`"$InstallerLog`""
    ) -join " "

    $process = Start-Process `
        -FilePath "msiexec.exe" `
        -ArgumentList $arguments `
        -Wait `
        -PassThru

    if ($process.ExitCode -notin @(0, 1641, 3010)) {
        Write-Fail "LLVM installer exited with code $($process.ExitCode)."
        Write-Info "Installer log: $InstallerLog"

        throw "LLVM installation failed."
    }

    if ($process.ExitCode -in @(1641, 3010)) {
        Write-Warn "Windows restart may be required."
    }

    Write-Pass "LLVM installer completed."

    if (-not (Test-LLVMInstallation)) {
        throw "LLVM installation completed, but one or more required executables are missing from $LLVMBin."
    }

    Write-Pass "All required LLVM executables were detected."
}

# ============================================================
# Executable validation
# ============================================================

function Test-Executable {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$Path
    )

    Write-Host ""
    Write-Host "--- $Name ---" -ForegroundColor Cyan

    if (-not $Path) {
        Write-Fail "$Name is not available."
        return $false
    }

    if (-not (Test-Path $Path -PathType Leaf)) {
        Write-Fail "$Name executable does not exist: $Path"
        return $false
    }

    Write-Host "Path: $Path" -ForegroundColor Gray

    $versionOutput = & $Path --version 2>&1
    $exitCode = $LASTEXITCODE

    $versionOutput | Select-Object -First 2

    if ($exitCode -ne 0) {
        Write-Fail "$Name returned exit code $exitCode."
        return $false
    }

    Write-Pass "$Name is working."

    return $true
}

function Test-LLVMTools {
    Write-Section "LLVM EXECUTABLE VALIDATION"

    $failures = 0

    foreach ($tool in $LLVMTools) {
        $toolName = [System.IO.Path]::GetFileNameWithoutExtension($tool)
        $toolPath = Join-Path $LLVMBin $tool

        if (-not (Test-Executable -Name $toolName -Path $toolPath)) {
            $failures++
        }
    }

    return $failures
}

# ============================================================
# GCC / G++ validation
# ============================================================

function Test-GCC {
    Write-Section "WINLIBS GCC / G++ VALIDATION"

    $failures = 0

    foreach ($tool in $NativeTools) {
        $command = Get-Command $tool `
            -CommandType Application `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if (-not $command) {
            Write-Host ""
            Write-Fail "$tool is not available on PATH."
            $failures++
            continue
        }

        if (-not (Test-Executable -Name $tool -Path $command.Source)) {
            $failures++
        }
    }

    return $failures
}

# ============================================================
# Main
# ============================================================

try {
    Write-Section "C / LLVM WINDOWS TOOLCHAIN SETUP"

    if (-not $IsWindows) {
        throw "This script only supports Windows."
    }

    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "64-bit Windows is required."
    }

    Write-Pass "Windows x64 platform detected."

    if ($Check) {
        Write-Info "Check mode enabled. No installation or persistent PATH changes will be made."
    }
    else {
        Write-Info "Installation mode enabled."
    }

    if (-not $Check) {
        Install-LLVM
    }
    elseif (-not (Test-LLVMInstallation)) {
        throw "LLVM installation is incomplete. Run .\c-install.ps1 to install or repair it."
    }
    else {
        Write-Pass "LLVM installation detected."
    }

    if (-not (Test-Path $LLVMBin -PathType Container)) {
        throw "LLVM binary directory not found: $LLVMBin"
    }

    if (-not $Check) {
        Add-LLVMToUserPath -PathEntry $LLVMBin
    }

    Update-ProcessPath -AdditionalPath $LLVMBin

    Write-Info "LLVM directory: $LLVMBin"

    $llvmFailures = Test-LLVMTools
    $gccFailures = Test-GCC

    Write-Section "INSTALLATION SUMMARY"

    if ($llvmFailures -eq 0) {
        Write-Pass "All LLVM tools passed validation."
    }
    else {
        Write-Fail "$llvmFailures LLVM tool(s) failed validation."
    }

    if ($gccFailures -eq 0) {
        Write-Pass "GCC and G++ passed validation."
    }
    else {
        Write-Fail "$gccFailures GCC/G++ check(s) failed validation."
    }

    if (($llvmFailures + $gccFailures) -gt 0) {
        throw "C toolchain validation completed with failures."
    }

    Write-Host ""
    Write-Pass "C / LLVM toolchain setup completed successfully."

    if (-not $Check) {
        Write-Info "Restart Neovim and open a new terminal to inherit the updated PATH."
    }

    exit 0
}
catch {
    Write-Host ""
    Write-Fail $_.Exception.Message
    exit 1
}
