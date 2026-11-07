
# Install external dependencies for Neovim Shell language support.
#
# Usage:
#   .\scripts\install\core\bash-shell.ps1
#
# Dependencies:
#   - Git for Windows (Bash runtime)
#   - Node.js and npm (Bash Language Server)
#   - Bash Language Server
#   - ShellCheck
#   - shfmt
#
# Installation sources:
#   - Git for Windows: WinGet
#   - Node.js LTS: WinGet (only when npm is missing)
#   - Bash Language Server: npm
#   - ShellCheck: WinGet
#   - shfmt: WinGet
#
# No Neovim plugins or Mason packages are installed.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$Packages = @(
    @{
        Name = "Git for Windows"
        Id   = "Git.Git"
        Tool = "bash.exe"
    },
    @{
        Name = "ShellCheck"
        Id   = "koalaman.shellcheck"
        Tool = "shellcheck.exe"
    },
    @{
        Name = "shfmt"
        Id   = "mvdan.shfmt"
        Tool = "shfmt.exe"
    }
)

$BashLanguageServer = "bash-language-server"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

function Write-Info {
    param([string]$Message)

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)

    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param([string]$Message)

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Failure {
    param([string]$Message)

    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ---------------------------------------------------------------------------
# PATH management
# ---------------------------------------------------------------------------

function Update-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable(
        "Path",
        "Machine"
    )

    $userPath = [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )

    $env:Path = @(
        $machinePath
        $userPath
    ) -join ";"
}

function Add-UserPathEntry {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "PATH directory does not exist: $Path"
    }

    $userPath = [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )

    $entries = @(
        $userPath -split ";" |
            Where-Object { $_.Trim() -ne "" }
    )

    $exists = $entries | Where-Object {
        $_.TrimEnd("\") -ieq $Path.TrimEnd("\")
    }

    if (-not $exists) {
        $newPath = (@($entries) + $Path) -join ";"

        [Environment]::SetEnvironmentVariable(
            "Path",
            $newPath,
            "User"
        )

        Write-Success "Added to user PATH: $Path"
    }

    Update-ProcessPath
}

# ---------------------------------------------------------------------------
# Command discovery
# ---------------------------------------------------------------------------

function Test-Command {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-GitBashPath {
    $candidates = @(
        "$env:ProgramFiles\Git\bin\bash.exe"
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    $command = Get-Command bash.exe -ErrorAction SilentlyContinue

    if ($command) {
        return $command.Source
    }

    return $null
}

# ---------------------------------------------------------------------------
# WinGet
# ---------------------------------------------------------------------------

function Install-WinGetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Id
    )

    if (-not (Test-Command "winget.exe")) {
        throw "WinGet is required to install $Name. Install Microsoft App Installer first."
    }

    Write-Info "Installing $Name through WinGet..."

    & winget.exe install `
        --id $Id `
        --exact `
        --source winget `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        throw "WinGet installation failed for $Name (exit code: $LASTEXITCODE)."
    }

    Update-ProcessPath

    Write-Success "$Name installation completed."
}

# ---------------------------------------------------------------------------
# Git for Windows / Bash
# ---------------------------------------------------------------------------

function Install-BashRuntime {
    Write-Info "Checking Git for Windows Bash..."

    $bashPath = Get-GitBashPath

    if (-not $bashPath) {
        Install-WinGetPackage `
            -Name "Git for Windows" `
            -Id "Git.Git"

        $bashPath = Get-GitBashPath
    }

    if (-not $bashPath) {
        throw "Git Bash was not found after installation."
    }

    $bashDirectory = Split-Path -Parent $bashPath

    Add-UserPathEntry -Path $bashDirectory

    Write-Success "Bash runtime found: $bashPath"
}

# ---------------------------------------------------------------------------
# Node.js / npm
# ---------------------------------------------------------------------------

function Ensure-Npm {
    if (Test-Command "npm.cmd") {
        Write-Success "npm is available."
        return
    }

    Write-WarningMessage "npm was not found. Installing Node.js LTS..."

    Install-WinGetPackage `
        -Name "Node.js LTS" `
        -Id "OpenJS.NodeJS.LTS"

    Update-ProcessPath

    if (-not (Test-Command "npm.cmd")) {
        throw "npm was not found after installing Node.js."
    }

    Write-Success "Node.js and npm are available."
}

# ---------------------------------------------------------------------------
# Bash Language Server
# ---------------------------------------------------------------------------

function Install-BashLanguageServer {
    Write-Info "Checking Bash Language Server..."

    if (Test-Command $BashLanguageServer) {
        Write-Success "Bash Language Server is already installed."
        return
    }

    Ensure-Npm

    Write-Info "Installing Bash Language Server through npm..."

    & npm.cmd install --global "bash-language-server"

    if ($LASTEXITCODE -ne 0) {
        throw "Bash Language Server installation failed (exit code: $LASTEXITCODE)."
    }

    Update-ProcessPath

    if (-not (Test-Command $BashLanguageServer)) {
        throw "Bash Language Server was installed but is not available on PATH."
    }

    Write-Success "Bash Language Server installation completed."
}

# ---------------------------------------------------------------------------
# ShellCheck and shfmt
# ---------------------------------------------------------------------------

function Install-ShellTools {
    $tools = @(
        @{
            Name = "ShellCheck"
            Id   = "koalaman.shellcheck"
            Tool = "shellcheck.exe"
        },
        @{
            Name = "shfmt"
            Id   = "mvdan.shfmt"
            Tool = "shfmt.exe"
        }
    )

    foreach ($tool in $tools) {
        if (Test-Command $tool.Tool) {
            Write-Success "$($tool.Name) is already installed."
            continue
        }

        Install-WinGetPackage `
            -Name $tool.Name `
            -Id $tool.Id

        if (-not (Test-Command $tool.Tool)) {
            throw "$($tool.Name) was installed but is not available on PATH."
        }
    }
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

function Test-ShellDependencies {
    Write-Host ""
    Write-Info "Verifying Shell dependencies..."

    $checks = @(
        @{
            Name = "Bash"
            Tool = "bash.exe"
        },
        @{
            Name = "Bash Language Server"
            Tool = "bash-language-server"
        },
        @{
            Name = "ShellCheck"
            Tool = "shellcheck.exe"
        },
        @{
            Name = "shfmt"
            Tool = "shfmt.exe"
        }
    )

    $failed = @()

    foreach ($check in $checks) {
        $command = Get-Command $check.Tool -ErrorAction SilentlyContinue

        if ($command) {
            Write-Success "$($check.Name): $($command.Source)"
        }
        else {
            Write-Failure "$($check.Name) is not available on PATH."
            $failed += $check.Name
        }
    }

    if ($failed.Count -gt 0) {
        throw "Dependency verification failed: $($failed -join ', ')"
    }

    Write-Host ""
    Write-Info "Installed tool versions..."

    & bash.exe --version | Select-Object -First 1

    & bash-language-server --version

    & shellcheck.exe --version |
        Select-String "version:"

    & shfmt.exe --version
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

function Main {
    Write-Host ""
    Write-Host "Shell language support - Windows dependencies" `
        -ForegroundColor White

    Write-Host ""

    if (-not $IsWindows) {
        throw "This installer supports Windows only."
    }

    Install-BashRuntime
    Install-BashLanguageServer
    Install-ShellTools

    Test-ShellDependencies

    Write-Host ""
    Write-Success "All Shell dependencies are installed and available."
}

try {
    Main
}
catch {
    Write-Host ""
    Write-Failure $_.Exception.Message
    exit 1
}
