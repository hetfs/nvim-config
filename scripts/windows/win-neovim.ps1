

# Provision and verify Neovim.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependNeovim
#
# Requirements:
#   - Shared infrastructure from win-core.ps1
#   - Neovim >= 0.12.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Neovim configuration
# ---------------------------------------------------------------------------

$script:WinDependNeovimMinimumVersion = [version]"0.12.0"

# ---------------------------------------------------------------------------
# Neovim initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependNeovim {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if (-not $state.Initialized) {
        throw "Core infrastructure has not been initialized. Run Initialize-WinDependCore first."
    }

    if (-not ($state.PSObject.Properties.Name -contains "NeovimPath")) {
        $state | Add-Member -MemberType NoteProperty -Name NeovimPath -Value $null
    }

    Invoke-Step -Name "Verify Neovim" -Action {
        $nvimPath = Ensure-Command `
            -Name "nvim.exe" `
            -PackageId $script:WinDependPackages.Neovim

        $versionOutput = @(& $nvimPath --version 2>&1)
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            throw "Neovim version check failed with exit code $exitCode."
        }

        if ($versionOutput.Count -eq 0) {
            throw "Neovim returned no version information."
        }

        $versionLine = [string]$versionOutput[0]

        if ($versionLine -notmatch '^NVIM v(?<Version>\d+\.\d+\.\d+)') {
            throw "Unable to determine the Neovim version. Output: $versionLine"
        }

        $installedVersion = [version]$Matches.Version

        if ($installedVersion -lt $script:WinDependNeovimMinimumVersion) {
            throw "Neovim $installedVersion is too old. Required version: $script:WinDependNeovimMinimumVersion or newer."
        }

        $state.NeovimPath = $nvimPath

        Write-Status -Level OK -Message "Neovim $installedVersion verified: $nvimPath"
    } | Out-Null

    return $state
}
