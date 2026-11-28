
# Provision and verify Tree-sitter CLI and compiler prerequisites.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependTreesitter
#
# Requirements:
#   - Tree-sitter CLI >= 0.26.1
#   - GCC
#   - G++

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Tree-sitter configuration
# ---------------------------------------------------------------------------

$script:WinDependTreeSitterMinimumVersion = [version]"0.26.1"

# ---------------------------------------------------------------------------
# Tree-sitter initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependTreesitter {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if (-not $state.Initialized) {
        throw "Core infrastructure has not been initialized. Run Initialize-WinDependCore first."
    }

    foreach ($property in @("TreeSitterPath", "TreeSitterVersion")) {
        if (-not ($state.PSObject.Properties.Name -contains $property)) {
            $state | Add-Member -MemberType NoteProperty -Name $property -Value $null
        }
    }

    # Verify the Tree-sitter CLI independently.
    Invoke-Step -Name "Install and verify Tree-sitter CLI" -Action {

        $treeSitterPath = Ensure-Command `
            -Name "tree-sitter.exe" `
            -PackageId $script:WinDependPackages.TreeSitter

        $versionOutput = & $treeSitterPath --version 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Tree-sitter version check failed. Output: $versionOutput"
        }

        $versionText = "$versionOutput".Trim()

        if ($versionText -notmatch '^(?:tree-sitter\s+)?(?<Version>\d+\.\d+\.\d+)') {
            throw "Unable to determine the Tree-sitter CLI version. Output: $versionText"
        }

        $installedVersion = [version]$Matches.Version

        if ($installedVersion -lt $script:WinDependTreeSitterMinimumVersion) {
            throw "Tree-sitter $installedVersion is too old. Required version: $script:WinDependTreeSitterMinimumVersion or newer."
        }

        $state.TreeSitterPath = $treeSitterPath
        $state.TreeSitterVersion = $installedVersion.ToString()

        Write-Status -Level OK -Message "Tree-sitter $installedVersion verified: $treeSitterPath"
    } | Out-Null

    # Verify compiler prerequisites independently.
    Invoke-Step -Name "Verify Tree-sitter compiler prerequisites" -Action {

        $gccPath = $state.GccPath
        $gppPath = $state.GppPath

        if ([string]::IsNullOrWhiteSpace($gccPath) -or
            -not (Test-Path -LiteralPath $gccPath -PathType Leaf)) {
            throw "GCC is unavailable. Run Initialize-WinDependCompiler first."
        }

        if ([string]::IsNullOrWhiteSpace($gppPath) -or
            -not (Test-Path -LiteralPath $gppPath -PathType Leaf)) {
            throw "G++ is unavailable. Run Initialize-WinDependCompiler first."
        }

        Write-Status -Level OK -Message "GCC prerequisite verified: $gccPath"
        Write-Status -Level OK -Message "G++ prerequisite verified: $gppPath"
    } | Out-Null

    return $state
}
