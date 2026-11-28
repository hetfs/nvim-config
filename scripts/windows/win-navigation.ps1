
# Provision navigation tools.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependNavigation
#
# Tools:
#   - fd (fd.exe)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Navigation tools initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependNavigation {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if (-not $state.Initialized) {
        throw "Core infrastructure has not been initialized. Run Initialize-WinDependCore first."
    }

    if (-not ($state.PSObject.Properties.Name -contains "FdPath")) {
        $state | Add-Member -MemberType NoteProperty -Name FdPath -Value $null
    }

    Invoke-Step -Name "Install and verify fd" -Action {

        $fdPath = Ensure-Command `
            -Name "fd.exe" `
            -PackageId $script:WinDependPackages.Fd

        $versionOutput = & $fdPath --version 2>&1

        if ($LASTEXITCODE -ne 0 -or "$versionOutput" -notmatch '^fd\s+\d+\.\d+\.\d+') {
            throw "fd could not be verified. Output: $versionOutput"
        }

        $state.FdPath = $fdPath

        Write-Status -Level OK -Message "fd verified: $versionOutput"
        Write-Status -Level OK -Message "Executable: $fdPath"
    } | Out-Null

    return $state
}
