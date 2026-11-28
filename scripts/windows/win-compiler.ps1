
# Provision and configure the WinLibs GCC/G++ compiler toolchain.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependCompiler
#
# Toolchain:
#   - WinLibs GCC
#   - GCC C compiler (gcc.exe)
#   - G++ C++ compiler (g++.exe)
#
# Environment changes:
#   - PATH changes are process-scoped.
#   - No persistent Windows environment variables are modified.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Compiler initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependCompiler {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if (-not $state.Initialized) {
        throw "Core infrastructure has not been initialized. Run Initialize-WinDependCore first."
    }

    foreach ($property in @("WinLibsRoot", "GccPath", "GppPath")) {
        if (-not ($state.PSObject.Properties.Name -contains $property)) {
            $state | Add-Member -MemberType NoteProperty -Name $property -Value $null
        }
    }

    Invoke-Step -Name "Install and configure WinLibs GCC/G++" -Action {

        # Locate an existing GCC installation.
        $gccPath = Get-Application -Name "gcc.exe"

        if ([string]::IsNullOrWhiteSpace($gccPath)) {
            Invoke-WingetInstall -PackageId $script:WinDependPackages.WinLibs
            Refresh-ProcessPath

            $gccPath = Get-Application -Name "gcc.exe"
        }

        if ([string]::IsNullOrWhiteSpace($gccPath)) {
            throw "GCC was not found after installing $($script:WinDependPackages.WinLibs)."
        }

        # Determine the WinLibs installation directory.
        $compilerBin = Split-Path -Parent $gccPath
        $winLibsRoot = Split-Path -Parent $compilerBin

        # Ensure the compiler directory takes precedence in this process.
        $existingEntries = @(
            $env:Path -split [IO.Path]::PathSeparator |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )

        $remainingEntries = @(
            $existingEntries | Where-Object {
                -not [string]::Equals(
                    $_.Trim().Trim('"').TrimEnd("\"),
                    $compilerBin.TrimEnd("\"),
                    [StringComparison]::OrdinalIgnoreCase
                )
            }
        )

        $env:Path = @($compilerBin) + $remainingEntries -join [IO.Path]::PathSeparator

        # Resolve the compiler executables from the selected installation.
        $gccPath = Join-Path $compilerBin "gcc.exe"
        $gppPath = Join-Path $compilerBin "g++.exe"

        if (-not (Test-Path -LiteralPath $gccPath -PathType Leaf)) {
            throw "GCC executable was not found: $gccPath"
        }

        if (-not (Test-Path -LiteralPath $gppPath -PathType Leaf)) {
            throw "G++ executable was not found: $gppPath"
        }

        # Verify GCC.
        $gccVersion = & $gccPath --version 2>&1

        if ($LASTEXITCODE -ne 0 -or "$gccVersion" -notmatch '^gcc\.exe\s+\(.*\)\s+\d+\.\d+') {
            throw "GCC could not be verified. Output: $gccVersion"
        }

        # Verify G++.
        $gppVersion = & $gppPath --version 2>&1

        if ($LASTEXITCODE -ne 0 -or "$gppVersion" -notmatch '^g\+\+\.exe\s+\(.*\)\s+\d+\.\d+') {
            throw "G++ could not be verified. Output: $gppVersion"
        }

        # Confirm the compiler executables resolve to this installation.
        $resolvedGcc = Get-Application -Name "gcc.exe"
        $resolvedGpp = Get-Application -Name "g++.exe"

        if (-not [string]::Equals(
            $resolvedGcc,
            $gccPath,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            throw "PATH resolves gcc.exe to an unexpected executable: $resolvedGcc"
        }

        if (-not [string]::Equals(
            $resolvedGpp,
            $gppPath,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            throw "PATH resolves g++.exe to an unexpected executable: $resolvedGpp"
        }

        $state.WinLibsRoot = $winLibsRoot
        $state.GccPath = $gccPath
        $state.GppPath = $gppPath

        Write-Status -Level OK -Message "WinLibs root: $winLibsRoot"
        Write-Status -Level OK -Message "GCC verified: $gccPath"
        Write-Status -Level OK -Message "G++ verified: $gppPath"
    } | Out-Null

    return $state
}
