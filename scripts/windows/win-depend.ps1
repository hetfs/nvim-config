
# Provision all Windows dependencies for the Neovim configuration.
#
# Usage:
#   .\scripts\win-depend.ps1
#
# Each module is dot-sourced to define its functions.
# Initialization is then performed in dependency order.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$WindowsDirectory = $PSScriptRoot

# ---------------------------------------------------------------------------
# Load and initialize shared infrastructure
# ---------------------------------------------------------------------------

$CoreModule = Join-Path $WindowsDirectory 'win-core.ps1'

if (-not (Test-Path -LiteralPath $CoreModule -PathType Leaf)) {
    throw "Core module not found: $CoreModule"
}

. $CoreModule

Initialize-WinDependCore | Out-Null

# ---------------------------------------------------------------------------
# Load all remaining modules
# ---------------------------------------------------------------------------

$Modules = @(
    @{
        File     = 'win-neovim.ps1'
        Function = 'Initialize-WinDependNeovim'
    }
    @{
        File     = 'win-node.ps1'
        Function = 'Initialize-WinDependNode'
    }
    @{
        File     = 'win-python.ps1'
        Function = 'Initialize-WinDependPython'
    }
    @{
        File     = 'win-navigation.ps1'
        Function = 'Initialize-WinDependNavigation'
    }
    @{
        File     = 'win-search.ps1'
        Function = 'Initialize-WinDependSearch'
    }
    @{
        File     = 'win-compiler.ps1'
        Function = 'Initialize-WinDependCompiler'
    }
    @{
        File     = 'win-treesitter.ps1'
        Function = 'Initialize-WinDependTreeSitter'
    }
    @{
        File     = 'win-shellcheck.ps1'
        Function = 'Initialize-WinDependShellCheck'
    }
    @{
        File     = 'win-lua-tools.ps1'
        Function = 'Initialize-WinDependLuaTools'
    }
    @{
        File     = 'win-bash.ps1'
        Function = 'Initialize-WinDependBash'
    }
    @{
        File     = 'win-external.ps1'
        Function = 'Initialize-WinDependExternal'
    }
)

foreach ($Module in $Modules) {
    $ModulePath = Join-Path $WindowsDirectory $Module.File

    if (-not (Test-Path -LiteralPath $ModulePath -PathType Leaf)) {
        throw "Module not found: $ModulePath"
    }

    . $ModulePath
}

# ---------------------------------------------------------------------------
# Initialize all modules
# ---------------------------------------------------------------------------

foreach ($Module in $Modules) {
    $FunctionName = $Module.Function

    if (-not (Get-Command $FunctionName -CommandType Function -ErrorAction SilentlyContinue)) {
        throw "Initialization function not found: $FunctionName"
    }

    try {
        & $FunctionName | Out-Null
    }
    catch {
        $State = Get-WinDependState
        $Message = "$FunctionName`: $($_.Exception.Message)"

        if ($State.Failures -notcontains $Message) {
            $State.Failures.Add($Message)
        }

        $State.Failed = $true
        Write-Status -Level ERROR -Message $Message
    }
}

# ---------------------------------------------------------------------------
# Final report
# ---------------------------------------------------------------------------

$FinalState = Get-WinDependState

Write-Host ''
Write-Host '=== WINDOWS DEPENDENCY SUMMARY ===' -ForegroundColor Cyan

$FinalState | Format-List

if ($FinalState.Failed) {
    Write-Status -Level ERROR -Message 'Dependency provisioning completed with failures.'
    exit 1
}

Write-Status -Level OK -Message 'All Windows dependencies are initialized successfully.'
exit 0
