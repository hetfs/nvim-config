
# Provision and configure the Neovim Node.js provider.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependNode
#
# Requirements:
#   - Shared infrastructure from win-core.ps1
#   - Node.js
#   - npm
#   - Global npm package: neovim

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Node.js provider initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependNode {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if (-not $state.Initialized) {
        throw "Core infrastructure has not been initialized. Run Initialize-WinDependCore first."
    }

    foreach ($property in @("NodePath", "NpmPath", "NodeProviderPackage")) {
        if (-not ($state.PSObject.Properties.Name -contains $property)) {
            $state | Add-Member -MemberType NoteProperty -Name $property -Value $null
        }
    }

    Invoke-Step -Name "Configure Neovim Node.js provider" -Action {

        # Ensure Node.js is installed.
        $nodePath = Ensure-Command `
            -Name "node.exe" `
            -PackageId $script:WinDependPackages.Node

        Refresh-ProcessPath

        # Verify Node.js.
        $nodeVersionOutput = & $nodePath --version 2>&1

        if ($LASTEXITCODE -ne 0 -or "$nodeVersionOutput" -notmatch '^v\d+\.\d+\.\d+') {
            throw "Node.js could not be verified. Output: $nodeVersionOutput"
        }

        # Locate npm.
        $npmPath = Get-Application -Name "npm.cmd"

        if ([string]::IsNullOrWhiteSpace($npmPath)) {
            $npmPath = Get-Application -Name "npm"
        }

        if ([string]::IsNullOrWhiteSpace($npmPath)) {
            throw "npm was not found after installing Node.js."
        }

        # Verify npm.
        $npmVersionOutput = & $npmPath --version 2>&1

        if ($LASTEXITCODE -ne 0 -or "$npmVersionOutput" -notmatch '^\d+\.\d+\.\d+') {
            throw "npm could not be verified. Output: $npmVersionOutput"
        }

        Write-Status -Level OK -Message "Node.js verified: $nodeVersionOutput"
        Write-Status -Level OK -Message "npm verified: $npmVersionOutput"

        # Install the Neovim Node.js provider globally.
        & $npmPath install --global neovim

        if ($LASTEXITCODE -ne 0) {
            throw "Global installation of the neovim npm package failed with exit code $LASTEXITCODE."
        }

        # Verify the global package installation.
        $packageOutput = & $npmPath list --global --depth=0 neovim 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "The global neovim npm package could not be verified. Output: $packageOutput"
        }

        $packageText = $packageOutput -join "`n"

        if ($packageText -notmatch '(?m)neovim@') {
            throw "The global npm package listing did not confirm neovim. Output: $packageText"
        }

        $state.NodePath = $nodePath
        $state.NpmPath = $npmPath
        $state.NodeProviderPackage = "neovim"

        Write-Status -Level OK -Message "Neovim Node.js provider package verified."
    } | Out-Null

    return $state
}
