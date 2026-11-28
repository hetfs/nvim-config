# Provision and verify Lua development tools.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependLuaTools
#
# Tools:
#   - StyLua

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Shared state helper
# ---------------------------------------------------------------------------

function Set-WinDependLuaToolsStateProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$Value
    )

    $state = Get-WinDependState

    if (-not $state) {
        throw "WinDepend shared state is unavailable."
    }

    $property = $state.PSObject.Properties[$Name]

    if ($null -eq $property) {
        Add-Member -InputObject $state `
            -MemberType NoteProperty `
            -Name $Name `
            -Value $Value
    }
    else {
        $property.Value = $Value
    }
}

# ---------------------------------------------------------------------------
# Lua tools initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependLuaTools {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if (-not $state.Initialized) {
        throw "Core infrastructure has not been initialized. Run Initialize-WinDependCore first."
    }

    # Initialize state properties without reading potentially missing ones.
    Set-WinDependLuaToolsStateProperty -Name "StyLuaPath" -Value $null
    Set-WinDependLuaToolsStateProperty -Name "StyLuaVersion" -Value $null

    Invoke-Step -Name "Install and verify StyLua" -Action {

        # Use the Python interpreter established by win-python.ps1.
        $pythonPath = $state.PythonPath

        if ([string]::IsNullOrWhiteSpace($pythonPath) -or
            -not (Test-Path -LiteralPath $pythonPath -PathType Leaf)) {
            throw "Python is unavailable. Run Initialize-WinDependPython first."
        }

        # Upgrade pip.
        & $pythonPath -m pip install --upgrade pip

        if ($LASTEXITCODE -ne 0) {
            throw "Upgrading pip failed with exit code $LASTEXITCODE."
        }

        # Install StyLua from its GitHub repository.
        & $pythonPath -m pip install --upgrade "git+https://github.com/johnnymorganz/stylua"

        if ($LASTEXITCODE -ne 0) {
            throw "Installing StyLua failed with exit code $LASTEXITCODE."
        }

        Refresh-ProcessPath

        # Locate StyLua.
        $styLuaPath = Get-Application -Name "stylua.exe"

        if ([string]::IsNullOrWhiteSpace($styLuaPath)) {
            $styLuaPath = Get-Application -Name "stylua"
        }

        if ([string]::IsNullOrWhiteSpace($styLuaPath)) {
            throw "StyLua was installed but its executable could not be found."
        }

        # Verify StyLua and extract its version.
        $versionOutput = (& $styLuaPath --version 2>&1 | Out-String).Trim()

        if ($LASTEXITCODE -ne 0 -or
            $versionOutput -notmatch '^stylua\s+(\d+\.\d+\.\d+)') {
            throw "StyLua could not be verified. Output: $versionOutput"
        }

        $styLuaVersion = $Matches[1]

        # Record verified information.
        Set-WinDependLuaToolsStateProperty `
            -Name "StyLuaPath" `
            -Value $styLuaPath

        Set-WinDependLuaToolsStateProperty `
            -Name "StyLuaVersion" `
            -Value $styLuaVersion

        Write-Status -Level OK -Message "StyLua verified: $versionOutput"
        Write-Status -Level OK -Message "Executable: $styLuaPath"
    } | Out-Null

    return $state
}

