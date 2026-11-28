
# Provision and verify ShellCheck.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependShellCheck
#
# Tool:
#   - ShellCheck (shellcheck.exe)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# ShellCheck initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependShellCheck {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if (-not $state.Initialized) {
        throw "Core infrastructure has not been initialized. Run Initialize-WinDependCore first."
    }

    if (-not ($state.PSObject.Properties.Name -contains "ShellCheckPath")) {
        $state | Add-Member -MemberType NoteProperty -Name ShellCheckPath -Value $null
    }

    Invoke-Step -Name "Install and verify ShellCheck" -Action {

        $shellCheckPath = Ensure-Command `
            -Name "shellcheck.exe" `
            -PackageId $script:WinDependPackages.ShellCheck

        $versionOutput = & $shellCheckPath --version 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "ShellCheck version check failed. Output: $versionOutput"
        }

        $versionText = $versionOutput -join "`n"

        if ($versionText -notmatch '(?m)^version:\s*(?<Version>\d+\.\d+\.\d+)') {
            throw "Unable to determine the ShellCheck version. Output: $versionText"
        }

        $installedVersion = [version]$Matches.Version

        $state.ShellCheckPath = $shellCheckPath

        Write-Status -Level OK -Message "ShellCheck $installedVersion verified."
        Write-Status -Level OK -Message "Executable: $shellCheckPath"
    } | Out-Null

    return $state
}
