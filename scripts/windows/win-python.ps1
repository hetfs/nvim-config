# Provision and configure the Neovim Python provider.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependPython
#
# Requirements:
#   - Shared infrastructure from win-core.ps1
#   - Python 3.14 or newer
#   - Python package: pynvim

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Python configuration
# ---------------------------------------------------------------------------

$script:WinDependPythonMinimumVersion = [version]"3.14.0"

# ---------------------------------------------------------------------------
# Shared state helpers
# ---------------------------------------------------------------------------

function Set-WinDependPythonStateProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [AllowNull()]
        [object] $Value
    )

    $state = Get-WinDependState

    if ($null -eq $state) {
        throw "WinDepend shared state is unavailable."
    }

    $property = $state.PSObject.Properties[$Name]

    if ($null -eq $property) {
        Add-Member -InputObject $state `
            -MemberType NoteProperty `
            -Name $Name `
            -Value $Value `
            -Force
    }
    else {
        $property.Value = $Value
    }
}

function Clear-WinDependPythonFailures {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if ($null -eq $state -or $null -eq $state.Failures) {
        return
    }

$pattern = '^(Python interpreter|Python provider|Python dependency verification|Configure Neovim Python provider):'
    $remainingFailures = @(
        $state.Failures |
            Where-Object { $_ -notmatch $pattern }
    )

    $state.Failures.Clear()

    foreach ($failure in $remainingFailures) {
        $state.Failures.Add($failure)
    }

    $state.Failed = ($state.Failures.Count -gt 0)
}

function Update-WinDependPythonFailureState {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if ($null -eq $state) {
        return
    }

    $state.Failed = ($state.Failures.Count -gt 0)
}

# ---------------------------------------------------------------------------
# Python discovery
# ---------------------------------------------------------------------------

function Get-WinDependPythonCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]] $Names
    )

    foreach ($name in $Names) {
        $command = Get-Command -Name $name `
            -CommandType Application `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($null -ne $command) {
            return $command.Source
        }
    }

    return $null
}

function Invoke-WinDependPythonProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Executable,

        [string[]] $PrefixArguments = @(),

        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
        throw "Python executable not found: $Executable"
    }

    $allArguments = @($PrefixArguments) + @($Arguments)

    $output = @(
        & $Executable @allArguments 2>&1
    )

    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $details = ($output | Out-String).Trim()

        throw "Python command failed with exit code $exitCode. $details"
    }

    return ($output | Out-String).Trim()
}

function Get-WinDependPythonInterpreter {
    [CmdletBinding()]
    param()

    $candidates = [System.Collections.Generic.List[object]]::new()

    # Prefer the Python 3.14 launcher.
    $launcher = Get-WinDependPythonCommand -Names @(
        "py.exe",
        "py"
    )

    if ($launcher) {
        $candidates.Add(@{
            Executable  = $launcher
            PrefixArgs  = @("-3.14")
            Description = "Python launcher -3.14"
        })

        # Fallback to the latest Python 3 installation.
        # The minimum version check below still applies.
        $candidates.Add(@{
            Executable  = $launcher
            PrefixArgs  = @("-3")
            Description = "Python launcher -3"
        })
    }

    # Check directly discoverable Python executables.
    $python = Get-WinDependPythonCommand -Names @(
        "python.exe",
        "python"
    )

    if ($python) {
        $candidates.Add(@{
            Executable  = $python
            PrefixArgs  = @()
            Description = "Python executable"
        })
    }

    foreach ($candidate in $candidates) {
        try {
            $output = Invoke-WinDependPythonProcess `
                -Executable $candidate.Executable `
                -PrefixArguments $candidate.PrefixArgs `
                -Arguments @(
                    "-c",
                    "import sys; print('.'.join(map(str, sys.version_info[:3])))"
                )

            $version = [version]$output.Trim()

            if ($version -lt $script:WinDependPythonMinimumVersion) {
                continue
            }

            return @{
                Executable  = $candidate.Executable
                PrefixArgs  = $candidate.PrefixArgs
                Version     = $version
                Description = $candidate.Description
            }
        }
        catch {
            continue
        }
    }

    return $null
}

# ---------------------------------------------------------------------------
# Python initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependPythonInterpreter {
    [CmdletBinding()]
    param()

    Write-Status -Level INFO -Message "Checking Python..."

    $interpreter = Get-WinDependPythonInterpreter

    if ($null -eq $interpreter) {
        Write-Status -Level INFO -Message "Installing Python 3.14 through WinGet..."

        if (-not $script:WinDependPackages.Python) {
            throw "The Python WinGet package ID is not configured in win-core.ps1."
        }

        Invoke-WingetInstall -PackageId $script:WinDependPackages.Python

        Refresh-ProcessPath

        $interpreter = Get-WinDependPythonInterpreter
    }

    if ($null -eq $interpreter) {
        throw "Python 3.14 or newer was not found after installation."
    }

    Set-WinDependPythonStateProperty `
        -Name "PythonPath" `
        -Value $interpreter.Executable

    Set-WinDependPythonStateProperty `
        -Name "PythonPrefixArgs" `
        -Value $interpreter.PrefixArgs

    Set-WinDependPythonStateProperty `
        -Name "PythonVersion" `
        -Value $interpreter.Version.ToString()

    Write-Status -Level OK -Message (
        "Python $($interpreter.Version) verified: $($interpreter.Executable)"
    )

    Write-Status -Level INFO -Message (
        "Interpreter selection: $($interpreter.Description)"
    )
}

# ---------------------------------------------------------------------------
# Python provider initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependPythonProvider {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if ($null -eq $state -or [string]::IsNullOrWhiteSpace($state.PythonPath)) {
        throw "A verified Python interpreter is required before installing pynvim."
    }

    $pythonPath = $state.PythonPath
    $prefixArgs = @($state.PythonPrefixArgs)

    Write-Status -Level INFO -Message "Checking pip..."

    $pipOutput = $null

    try {
        $pipOutput = Invoke-WinDependPythonProcess `
            -Executable $pythonPath `
            -PrefixArguments $prefixArgs `
            -Arguments @("-m", "pip", "--version")
    }
    catch {
        Write-Status -Level WARN -Message "pip is unavailable. Bootstrapping pip..."

        Invoke-WinDependPythonProcess `
            -Executable $pythonPath `
            -PrefixArguments $prefixArgs `
            -Arguments @("-m", "ensurepip", "--upgrade") |
            Out-Null

        $pipOutput = Invoke-WinDependPythonProcess `
            -Executable $pythonPath `
            -PrefixArguments $prefixArgs `
            -Arguments @("-m", "pip", "--version")
    }

    Set-WinDependPythonStateProperty `
        -Name "PipVersion" `
        -Value $pipOutput

    Write-Status -Level OK -Message "pip verified: $pipOutput"

    Write-Status -Level INFO -Message "Upgrading pip..."

    Invoke-WinDependPythonProcess `
        -Executable $pythonPath `
        -PrefixArguments $prefixArgs `
        -Arguments @(
            "-m",
            "pip",
            "install",
            "--upgrade",
            "pip"
        ) |
        Out-Null

    Write-Status -Level OK -Message "pip upgraded."

    Write-Status -Level INFO -Message "Installing pynvim..."

    Invoke-WinDependPythonProcess `
        -Executable $pythonPath `
        -PrefixArguments $prefixArgs `
        -Arguments @(
            "-m",
            "pip",
            "install",
            "--upgrade",
            "pynvim"
        ) |
        Out-Null

    Set-WinDependPythonStateProperty `
        -Name "PythonProviderPackage" `
        -Value "pynvim"

    Write-Status -Level OK -Message "pynvim installation completed."
}

# ---------------------------------------------------------------------------
# Python dependency verification
# ---------------------------------------------------------------------------

function Test-WinDependPythonDependencies {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if ($null -eq $state -or [string]::IsNullOrWhiteSpace($state.PythonPath)) {
        throw "Python interpreter state is missing."
    }

    $pythonPath = $state.PythonPath
    $prefixArgs = @($state.PythonPrefixArgs)

    Write-Status -Level INFO -Message "Verifying Python version..."

    $versionOutput = Invoke-WinDependPythonProcess `
        -Executable $pythonPath `
        -PrefixArguments $prefixArgs `
        -Arguments @(
            "-c",
            "import sys; print('.'.join(map(str, sys.version_info[:3])))"
        )

    $version = [version]$versionOutput.Trim()

    if ($version -lt $script:WinDependPythonMinimumVersion) {
        throw "Python $version does not meet the minimum requirement of $script:WinDependPythonMinimumVersion."
    }

    Write-Status -Level OK -Message "Python $version"

    Write-Status -Level INFO -Message "Verifying pip..."

    $pipOutput = Invoke-WinDependPythonProcess `
        -Executable $pythonPath `
        -PrefixArguments $prefixArgs `
        -Arguments @("-m", "pip", "--version")

    Write-Status -Level OK -Message $pipOutput

    Write-Status -Level INFO -Message "Verifying pynvim..."

    $providerOutput = Invoke-WinDependPythonProcess `
        -Executable $pythonPath `
        -PrefixArguments $prefixArgs `
        -Arguments @(
            "-c",
            "import importlib.metadata; import pynvim; print(importlib.metadata.version('pynvim'))"
        )

    if ([string]::IsNullOrWhiteSpace($providerOutput)) {
        throw "The pynvim package could not be verified."
    }

    Set-WinDependPythonStateProperty `
        -Name "PynvimVersion" `
        -Value $providerOutput

    Write-Status -Level OK -Message "pynvim $providerOutput"
}

# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

function Initialize-WinDependPython {
    [CmdletBinding()]
    param()

    $state = Get-WinDependState

    if ($null -eq $state -or -not $state.Initialized) {
        throw "Core infrastructure has not been initialized. Run Initialize-WinDependCore first."
    }

    Clear-WinDependPythonFailures

    Write-Host ""
    Write-Host "Python provider - Windows dependencies" -ForegroundColor White
    Write-Host ""

    Invoke-Step `
        -Name "Python interpreter" `
        -Action {
            Initialize-WinDependPythonInterpreter
        } |
        Out-Null

    Invoke-Step `
        -Name "Python provider" `
        -Action {
            Initialize-WinDependPythonProvider
        } |
        Out-Null

    Invoke-Step `
        -Name "Python dependency verification" `
        -Action {
            Test-WinDependPythonDependencies
        } |
        Out-Null

    Update-WinDependPythonFailureState

    return (Get-WinDependState)
}

