
# Provision search tools.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependSearch
#
# Tools:
#   - ripgrep (rg.exe)
#   - fzf (fzf.exe)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Search tools initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependSearch {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if (-not $state.Initialized) {
        throw "Core infrastructure has not been initialized. Run Initialize-WinDependCore first."
    }

    foreach ($property in @("RipgrepPath", "FzfPath")) {
        if (-not ($state.PSObject.Properties.Name -contains $property)) {
            $state | Add-Member -MemberType NoteProperty -Name $property -Value $null
        }
    }

    # Verify ripgrep independently.
    Invoke-Step -Name "Install and verify ripgrep" -Action {

        $rgPath = Ensure-Command `
            -Name "rg.exe" `
            -PackageId $script:WinDependPackages.Ripgrep

        $versionOutput = & $rgPath --version 2>&1

        if ($LASTEXITCODE -ne 0 -or "$versionOutput" -notmatch '^ripgrep\s+\d+\.\d+\.\d+') {
            throw "ripgrep could not be verified. Output: $versionOutput"
        }

        $state.RipgrepPath = $rgPath

        Write-Status -Level OK -Message "ripgrep verified: $versionOutput"
        Write-Status -Level OK -Message "Executable: $rgPath"
    } | Out-Null

    # Verify fzf independently. A ripgrep failure must not prevent this check.
    Invoke-Step -Name "Install and verify fzf" -Action {

        $fzfPath = Ensure-Command `
            -Name "fzf.exe" `
            -PackageId $script:WinDependPackages.Fzf

        $versionOutput = & $fzfPath --version 2>&1

        if ($LASTEXITCODE -ne 0 -or "$versionOutput" -notmatch '^\d+\.\d+\.\d+') {
            throw "fzf could not be verified. Output: $versionOutput"
        }

        $state.FzfPath = $fzfPath

        Write-Status -Level OK -Message "fzf verified: $versionOutput"
        Write-Status -Level OK -Message "Executable: $fzfPath"
    } | Out-Null

    return $state
}
