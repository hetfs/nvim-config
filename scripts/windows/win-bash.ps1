# Install external dependencies for Neovim Shell language support.
#
# Module:
#   scripts/windows/win-bash.ps1
#
# Entry point:
#   Initialize-WinDependBash
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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Shared state
# ---------------------------------------------------------------------------

function Set-WinDependBashStateProperty {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$Value
    )

    $state = Get-WinDependState

    if (-not $state) {
        throw 'WinDepend shared state is unavailable.'
    }

    $property = $state.PSObject.Properties[$Name]

    if ($null -eq $property) {
        Add-Member `
            -InputObject $state `
            -MemberType NoteProperty `
            -Name $Name `
            -Value $Value `
            -Force
    }
    else {
        $property.Value = $Value
    }
}

function Clear-WinDependBashFailures {
    $state = Get-WinDependState

    if (-not $state) {
        throw 'WinDepend shared state is unavailable.'
    }

    # Remove only failures belonging to this module.
    # Failures from other modules remain untouched.
    $bashFailurePattern = '^(Git for Windows Bash|Bash Language Server|ShellCheck and shfmt|Shell dependency verification):'

    $remainingFailures = @(
        $state.Failures | Where-Object {
            $_ -notmatch $bashFailurePattern
        }
    )

    $state.Failures.Clear()

    foreach ($failure in $remainingFailures) {
        $state.Failures.Add($failure)
    }

    $state.Failed = ($state.Failures.Count -gt 0)
}

function Update-WinDependBashFailureState {
    $state = Get-WinDependState

    if (-not $state) {
        throw 'WinDepend shared state is unavailable.'
    }

    $state.Failed = ($state.Failures.Count -gt 0)
}

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

function Write-WinDependBashStatus {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'OK', 'WARN', 'ERROR')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Status -Level $Level -Message $Message
}

# ---------------------------------------------------------------------------
# Process PATH
# ---------------------------------------------------------------------------

function Add-WinDependBashProcessPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "PATH directory does not exist: $Path"
    }

    $entries = @(
        $env:Path -split ';' |
            Where-Object { $_.Trim() -ne '' }
    )

    $exists = $entries | Where-Object {
        $_.Trim().TrimEnd('\') -ieq $Path.TrimEnd('\')
    }

    if (-not $exists) {
        $env:Path = (@($Path) + $entries) -join ';'
    }
}

# ---------------------------------------------------------------------------
# Command discovery
# ---------------------------------------------------------------------------

function Get-WinDependBashCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue

    if (-not $command) {
        return $null
    }

    if ($command.Source) {
        return $command.Source
    }

    if ($command.Path) {
        return $command.Path
    }

    return $null
}

function Get-WinDependBashRuntime {
    $candidates = @(
        "$env:ProgramFiles\Git\bin\bash.exe"
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return Get-WinDependBashCommand -Name 'bash.exe'
}

# ---------------------------------------------------------------------------
# WinGet installation
# ---------------------------------------------------------------------------

function Install-WinDependBashPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Id
    )

    Write-WinDependBashStatus `
        -Level INFO `
        -Message "Installing $Name through WinGet..."

    Invoke-WingetInstall -Name $Name -Id $Id

    Refresh-ProcessPath
}

# ---------------------------------------------------------------------------
# Git for Windows / Bash
# ---------------------------------------------------------------------------

function Initialize-WinDependBashRuntime {
    Write-WinDependBashStatus `
        -Level INFO `
        -Message 'Checking Git for Windows Bash...'

    $bashPath = Get-WinDependBashRuntime

    if (-not $bashPath) {
        Install-WinDependBashPackage `
            -Name 'Git for Windows' `
            -Id 'Git.Git'

        $bashPath = Get-WinDependBashRuntime
    }

    if (-not $bashPath) {
        throw 'Git Bash was not found after installation.'
    }

    $bashDirectory = Split-Path -Parent $bashPath

    Add-WinDependBashProcessPath -Path $bashDirectory

    Set-WinDependBashStateProperty `
        -Name 'BashPath' `
        -Value $bashPath

    Write-WinDependBashStatus `
        -Level OK `
        -Message "Git Bash: $bashPath"
}

# ---------------------------------------------------------------------------
# Node.js / npm
# ---------------------------------------------------------------------------

function Get-WinDependBashNpm {
    $npmPath = Get-WinDependBashCommand -Name 'npm.cmd'

    if (-not $npmPath) {
        $npmPath = Get-WinDependBashCommand -Name 'npm'
    }

    return $npmPath
}

function Initialize-WinDependBashNpm {
    $npmPath = Get-WinDependBashNpm

    if (-not $npmPath) {
        Write-WinDependBashStatus `
            -Level WARN `
            -Message 'npm was not found. Installing Node.js LTS...'

        Install-WinDependBashPackage `
            -Name 'Node.js LTS' `
            -Id 'OpenJS.NodeJS.LTS'

        $npmPath = Get-WinDependBashNpm
    }

    if (-not $npmPath) {
        throw 'npm was not found after installing Node.js LTS.'
    }

    $nodePath = Get-WinDependBashCommand -Name 'node.exe'

    if (-not $nodePath) {
        $nodePath = Get-WinDependBashCommand -Name 'node'
    }

    if (-not $nodePath) {
        throw 'Node.js was not found, although npm is available.'
    }

    Set-WinDependBashStateProperty `
        -Name 'NpmPath' `
        -Value $npmPath

    Set-WinDependBashStateProperty `
        -Name 'BashNodePath' `
        -Value $nodePath

    Write-WinDependBashStatus `
        -Level OK `
        -Message "Node.js: $nodePath"

    Write-WinDependBashStatus `
        -Level OK `
        -Message "npm: $npmPath"

    return $npmPath
}

# ---------------------------------------------------------------------------
# Bash Language Server
# ---------------------------------------------------------------------------

function Initialize-WinDependBashLanguageServer {
    Write-WinDependBashStatus `
        -Level INFO `
        -Message 'Checking Bash Language Server...'

    # Always verify Node.js and npm and record their paths,
    # even when the language server is already installed.
    $npmPath = Initialize-WinDependBashNpm

    $serverPath = Get-WinDependBashCommand `
        -Name 'bash-language-server'

    if (-not $serverPath) {
        Write-WinDependBashStatus `
            -Level INFO `
            -Message 'Installing Bash Language Server through npm...'

        & $npmPath install --global 'bash-language-server'

        if ($LASTEXITCODE -ne 0) {
            throw "Bash Language Server installation failed (exit code: $LASTEXITCODE)."
        }

        Refresh-ProcessPath

        $serverPath = Get-WinDependBashCommand `
            -Name 'bash-language-server'
    }

    if (-not $serverPath) {
        throw 'Bash Language Server is not available on PATH after installation.'
    }

    Set-WinDependBashStateProperty `
        -Name 'BashLanguageServerPath' `
        -Value $serverPath

    Write-WinDependBashStatus `
        -Level OK `
        -Message "Bash Language Server: $serverPath"
}

# ---------------------------------------------------------------------------
# ShellCheck and shfmt
# ---------------------------------------------------------------------------

function Initialize-WinDependBashShellTools {
    $tools = @(
        @{
            Name = 'ShellCheck'
            Id = 'koalaman.shellcheck'
            Tool = 'shellcheck.exe'
            StateProperty = 'ShellCheckPath'
        },
        @{
            Name = 'shfmt'
            Id = 'mvdan.shfmt'
            Tool = 'shfmt.exe'
            StateProperty = 'ShfmtPath'
        }
    )

    foreach ($tool in $tools) {
        Write-WinDependBashStatus `
            -Level INFO `
            -Message "Checking $($tool.Name)..."

        $toolPath = Get-WinDependBashCommand -Name $tool.Tool

        if (-not $toolPath) {
            Install-WinDependBashPackage `
                -Name $tool.Name `
                -Id $tool.Id

            $toolPath = Get-WinDependBashCommand -Name $tool.Tool
        }

        if (-not $toolPath) {
            throw "$($tool.Name) was not found on PATH after installation."
        }

        Set-WinDependBashStateProperty `
            -Name $tool.StateProperty `
            -Value $toolPath

        Write-WinDependBashStatus `
            -Level OK `
            -Message "$($tool.Name): $toolPath"
    }
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

function Test-WinDependBashDependencies {
    Write-WinDependBashStatus `
        -Level INFO `
        -Message 'Verifying Shell dependencies...'

    $checks = @(
        @{
            Name = 'Bash'
            Tool = 'bash.exe'
        },
        @{
            Name = 'Node.js'
            Tool = 'node.exe'
        },
        @{
            Name = 'npm'
            Tool = 'npm.cmd'
        },
        @{
            Name = 'Bash Language Server'
            Tool = 'bash-language-server'
        },
        @{
            Name = 'ShellCheck'
            Tool = 'shellcheck.exe'
        },
        @{
            Name = 'shfmt'
            Tool = 'shfmt.exe'
        }
    )

    $failed = @()

    foreach ($check in $checks) {
        $commandPath = Get-WinDependBashCommand -Name $check.Tool

        if ($commandPath) {
            Write-WinDependBashStatus `
                -Level OK `
                -Message "$($check.Name): $commandPath"
        }
        else {
            Write-WinDependBashStatus `
                -Level ERROR `
                -Message "$($check.Name) is not available on PATH."

            $failed += $check.Name
        }
    }

    if ($failed.Count -gt 0) {
        throw "Shell dependency verification failed: $($failed -join ', ')"
    }

    Write-WinDependBashStatus `
        -Level INFO `
        -Message 'Installed tool versions...'

    $bashPath = Get-WinDependBashCommand -Name 'bash.exe'
    $nodePath = Get-WinDependBashCommand -Name 'node.exe'
    $npmPath = Get-WinDependBashCommand -Name 'npm.cmd'
    $serverPath = Get-WinDependBashCommand -Name 'bash-language-server'
    $shellCheckPath = Get-WinDependBashCommand -Name 'shellcheck.exe'
    $shfmtPath = Get-WinDependBashCommand -Name 'shfmt.exe'

    & $bashPath --version | Select-Object -First 1
    & $nodePath --version
    & $npmPath --version
    & $serverPath --version

    & $shellCheckPath --version |
        Select-String 'version:'

    & $shfmtPath --version
}

# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

function Initialize-WinDependBash {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if (-not $state -or -not $state.Initialized) {
        throw 'WinDepend core is not initialized. Run Initialize-WinDependCore first.'
    }

    # Clear stale Bash failures from earlier runs.
    # Failures belonging to other modules are preserved.
    Clear-WinDependBashFailures

    Write-Host ''
    Write-Host 'Shell language support - Windows dependencies' -ForegroundColor White
    Write-Host ''

    if (-not $IsWindows) {
        throw 'Bash language support provisioning is supported on Windows only.'
    }

    $steps = @(
        @{
            Name = 'Git for Windows Bash'
            Action = { Initialize-WinDependBashRuntime }
        },
        @{
            Name = 'Bash Language Server'
            Action = { Initialize-WinDependBashLanguageServer }
        },
        @{
            Name = 'ShellCheck and shfmt'
            Action = { Initialize-WinDependBashShellTools }
        },
        @{
            Name = 'Shell dependency verification'
            Action = { Test-WinDependBashDependencies }
        }
    )

    foreach ($step in $steps) {
        Invoke-Step -Name $step.Name -Action $step.Action | Out-Null
    }

    # Recalculate from the complete failure collection.
    Update-WinDependBashFailureState

    return Get-WinDependState
}

