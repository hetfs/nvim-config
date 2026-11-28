[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [switch]$VerifyOnly,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$tools = @(
    @{
        Name       = "Docker Language Server"
        Module     = "github.com/docker/docker-language-server"
        Package    = "github.com/docker/docker-language-server/cmd/docker-language-server"
        Version    = "v0.20.1"
        Executable = "docker-language-server.exe"
    }
    @{
        Name       = "dockerfmt"
        Module     = "github.com/reteps/dockerfmt"
        Package    = "github.com/reteps/dockerfmt"
        Version    = "v0.6.0"
        Executable = "dockerfmt.exe"
    }
)

function Invoke-Go {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $output = @(
        & $script:GoCommand.Source @Arguments 2>&1 |
            ForEach-Object { $_.ToString() }
    )

    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw (
            "Go command failed: go {0}`n{1}" -f
            ($Arguments -join " "),
            ($output -join [Environment]::NewLine)
        )
    }

    return ,$output
}

function Get-GoInstallDirectory {
    $gobin = (Invoke-Go -Arguments @("env", "GOBIN") | Out-String).Trim()

    if ($gobin) {
        return $gobin
    }

    $gopath = (Invoke-Go -Arguments @("env", "GOPATH") | Out-String).Trim()

    if (-not $gopath) {
        throw "Unable to determine the Go installation directory."
    }

    $firstGoPath = ($gopath -split [regex]::Escape([IO.Path]::PathSeparator))[0]

    return Join-Path $firstGoPath "bin"
}

function Get-InstalledModuleVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Module
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $output = Invoke-Go -Arguments @("version", "-m", $Path)
    $metadata = $output -join [Environment]::NewLine

    $modulePattern = (
        '(?m)^\s*mod\s+{0}\s+(?<version>\S+)' -f
        [regex]::Escape($Module)
    )

    if ($metadata -match $modulePattern) {
        return $Matches["version"]
    }

    return $null
}

# Locate Go.
$script:GoCommand = Get-Command go -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $script:GoCommand) {
    throw "Go is required. Install Go 1.24 or later before running this script."
}

# Validate the Go toolchain version.
$goVersionOutput = Invoke-Go -Arguments @("version") | Out-String

if ($goVersionOutput -notmatch 'go(?<version>\d+\.\d+(?:\.\d+)?)') {
    throw "Unable to determine the installed Go version: $goVersionOutput"
}

$goVersion = [version]$Matches["version"]

if ($goVersion -lt [version]"1.24.0") {
    throw "Go 1.24 or later is required. Found Go $goVersion."
}

$installDirectory = Get-GoInstallDirectory

if (-not (Test-Path -LiteralPath $installDirectory -PathType Container)) {
    if ($VerifyOnly) {
        throw "Go installation directory does not exist: $installDirectory"
    }

    if ($PSCmdlet.ShouldProcess($installDirectory, "Create Go installation directory")) {
        New-Item -ItemType Directory -Path $installDirectory -Force |
            Out-Null
    }
    else {
        throw "Go installation directory was not created: $installDirectory"
    }
}

Write-Host "Go version: $goVersion"
Write-Host "Go installation directory: $installDirectory"
Write-Host ""

$results = foreach ($tool in $tools) {
    $binaryPath = Join-Path $installDirectory $tool.Executable

    $installedVersion = Get-InstalledModuleVersion `
        -Path $binaryPath `
        -Module $tool.Module

    $isCurrent = $installedVersion -eq $tool.Version

    if ($isCurrent -and -not $Force) {
        [PSCustomObject]@{
            Tool             = $tool.Name
            ExpectedVersion  = $tool.Version
            InstalledVersion = $installedVersion
            Status           = "Already installed"
        }

        continue
    }

    if ($VerifyOnly) {
        $actual = if ($installedVersion) {
            $installedVersion
        }
        else {
            "not installed or version metadata unavailable"
        }

        throw "$($tool.Name): expected $($tool.Version), found $actual."
    }

    $action = "Install $($tool.Name) $($tool.Version)"

    if (-not $PSCmdlet.ShouldProcess($binaryPath, $action)) {
        [PSCustomObject]@{
            Tool             = $tool.Name
            ExpectedVersion  = $tool.Version
            InstalledVersion = $installedVersion
            Status           = "Installation not performed"
        }

        continue
    }

    Write-Host "Installing $($tool.Name) $($tool.Version)..."

    Invoke-Go -Arguments @(
        "install",
        "$($tool.Package)@$($tool.Version)"
    ) | Out-Null

    $installedVersion = Get-InstalledModuleVersion `
        -Path $binaryPath `
        -Module $tool.Module

    if ($installedVersion -ne $tool.Version) {
        $actual = if ($installedVersion) {
            $installedVersion
        }
        else {
            "version metadata unavailable"
        }

        throw (
            "Verification failed for {0}. Expected {1}, found {2}." -f
            $tool.Name,
            $tool.Version,
            $actual
        )
    }

    [PSCustomObject]@{
        Tool             = $tool.Name
        ExpectedVersion  = $tool.Version
        InstalledVersion = $installedVersion
        Status           = "Installed and verified"
    }
}

Write-Host ""
$results | Format-Table -AutoSize

Write-Host ""
Write-Host "Docker editor tools processed."

if ($env:PATH -notlike "*$installDirectory*") {
    Write-Warning "Add the Go bin directory to your PATH to use these tools from other processes: $installDirectory"
}
