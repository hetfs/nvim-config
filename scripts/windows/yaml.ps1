# Install and verify the YAML tooling used by nvim-config.
#
# Required tools:
#   - yaml-language-server 2.0.0
#   - Prettier 3.9.10
#
# Prerequisites:
#   - Node.js
#   - npm
#
# Installation policy:
#   - Installs tools globally through npm.
#   - Installs the exact versions declared below.
#   - Skips tools that already match the requested version.
#   - Updates tools that are missing or have a different version.
#   - Never runs automatically during Neovim startup.
#
# Usage:
#   .\yaml.ps1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$Tools = @(
    [pscustomobject]@{
        Name    = 'yaml-language-server'
        Package = 'yaml-language-server'
        Version = '2.0.0'
    },
    [pscustomobject]@{
        Name    = 'prettier'
        Package = 'prettier'
        Version = '3.9.10'
    }
)

$script:Npm = $null

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

function Write-Status {
    param(
        [ValidateSet('INFO', 'OK', 'UPDATE', 'INSTALL', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $color = switch ($Level) {
        'INFO'    { 'Cyan' }
        'OK'      { 'Green' }
        'UPDATE'  { 'Yellow' }
        'INSTALL' { 'Cyan' }
        'FAIL'    { 'Red' }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

# ---------------------------------------------------------------------------
# Command and version discovery
# ---------------------------------------------------------------------------

function Get-Application {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return Get-Command `
        -Name $Name `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Get-ToolVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $command = Get-Application -Name $Name

    if (-not $command) {
        return $null
    }

    try {
        $output = @(& $command.Source --version 2>&1)
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            return $null
        }

        return (($output | ForEach-Object { "$_".Trim() } |
                    Where-Object { $_ }) -join ' ').Trim()
    }
    catch {
        return $null
    }
}

# ---------------------------------------------------------------------------
# Node.js and npm prerequisites
# ---------------------------------------------------------------------------

function Initialize-Npm {
    $node = Get-Application -Name 'node'

    if (-not $node) {
        throw 'Node.js is not installed or is not available on PATH.'
    }

    $script:Npm = Get-Application -Name 'npm'

    if (-not $script:Npm) {
        throw 'npm is not installed or is not available on PATH.'
    }

    $nodeVersion = & $node.Source --version
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to determine the Node.js version.'
    }

    $npmVersion = & $script:Npm.Source --version
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to determine the npm version.'
    }

    Write-Status INFO "Node.js: $nodeVersion"
    Write-Status INFO "npm: $npmVersion"
}

# ---------------------------------------------------------------------------
# npm tool installation
# ---------------------------------------------------------------------------

function Install-NpmTool {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Tool
    )

    $installedVersion = Get-ToolVersion -Name $Tool.Name

    if ($installedVersion -eq $Tool.Version) {
        Write-Status OK "$($Tool.Name) $installedVersion is already installed."
        return
    }

    if ($installedVersion) {
        Write-Status UPDATE "$($Tool.Name): $installedVersion -> $($Tool.Version)"
    }
    else {
        Write-Status INSTALL "Installing $($Tool.Name) $($Tool.Version)..."
    }

    $packageSpec = "$($Tool.Package)@$($Tool.Version)"

    $output = @(& $script:Npm.Source install --global $packageSpec 2>&1)
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $details = ($output | ForEach-Object { "$_".Trim() } |
                Where-Object { $_ }) -join [Environment]::NewLine

        throw "npm failed to install $packageSpec (exit code $exitCode). $details"
    }

    $verifiedVersion = Get-ToolVersion -Name $Tool.Name

    if ($verifiedVersion -ne $Tool.Version) {
        throw "Verification failed for $($Tool.Name). Expected '$($Tool.Version)'; found '$verifiedVersion'."
    }

    Write-Status OK "$($Tool.Name) $verifiedVersion installed and verified."
}

# ---------------------------------------------------------------------------
# Final verification
# ---------------------------------------------------------------------------

function Test-YamlTools {
    Write-Host ''
    Write-Status INFO 'Verifying YAML tools...'

    foreach ($tool in $Tools) {
        $command = Get-Application -Name $tool.Name

        if (-not $command) {
            throw "$($tool.Name) is not discoverable on PATH."
        }

        $version = Get-ToolVersion -Name $tool.Name

        if ($version -ne $tool.Version) {
            throw "$($tool.Name) version mismatch. Expected '$($tool.Version)'; found '$version'."
        }

        Write-Status OK "$($tool.Name): $version ($($command.Source))"
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Write-Host ''
    Write-Host 'YAML external tools' -ForegroundColor Cyan
    Write-Host '==================='

    Initialize-Npm

    foreach ($tool in $Tools) {
        Install-NpmTool -Tool $tool
    }

    Test-YamlTools

    Write-Host ''
    Write-Status OK 'YAML external tools are ready.'
    exit 0
}
catch {
    Write-Host ''
    Write-Status FAIL $_.Exception.Message
    exit 1
}
