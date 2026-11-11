#Requires -Version 7.0

<#
.SYNOPSIS
    Checks and installs Markdown tooling dependencies.

.DESCRIPTION
    Checks for markdownlint-cli2 and markdown-toc.

    When -InstallMissing is supplied, installs missing dependencies
    globally through npm and verifies the installations.

    The script does not modify persistent PATH settings.

.EXAMPLE
    # Check dependencies only.
    ./scripts/core/windows/markdown-deps.ps1

.EXAMPLE
    # Install missing dependencies and verify them.
    ./scripts/core/windows/markdown-deps.ps1 -InstallMissing
#>

[CmdletBinding()]
param(
    [switch]$InstallMissing
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

$tools = @(
    @{
        Name    = "markdownlint-cli2"
        Command = "markdownlint-cli2"
        Package = "markdownlint-cli2"
        Purpose = "Markdown linting"
    }
    @{
        Name    = "markdown-toc"
        Command = "markdown-toc"
        Package = "@frat/markdown-toc"
        Purpose = "Table of contents generation"
    }
)

function Get-ToolCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    Get-Command `
        -Name $Name `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Test-MarkdownTool {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tool
    )

    $command = Get-ToolCommand -Name $Tool.Command

    if ($null -eq $command) {
        return [PSCustomObject]@{
            Available = $false
            Version   = $null
            Message   = "Executable not found."
        }
    }

    try {
        $output = @(& $command.Source --version 2>&1)
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            throw "Version check failed with exit code $exitCode."
        }

        $version = $output |
            ForEach-Object { "$_".Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -First 1

        if ([string]::IsNullOrWhiteSpace($version)) {
            throw "No version information returned."
        }

        return [PSCustomObject]@{
            Available = $true
            Version   = $version
            Message   = "Available"
        }
    }
    catch {
        return [PSCustomObject]@{
            Available = $false
            Version   = $null
            Message   = $_.Exception.Message
        }
    }
}

function Install-MarkdownTool {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tool,

        [Parameter(Mandatory)]
        [string]$NpmPath
    )

    Write-Host "Installing $($Tool.Package)..." -ForegroundColor Cyan

    & $NpmPath install --global $Tool.Package

    if ($LASTEXITCODE -ne 0) {
        throw "npm failed to install $($Tool.Package). Exit code: $LASTEXITCODE"
    }
}

Write-Host ""
Write-Host "Markdown dependencies" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Resolve npm only when installation is requested.
$npm = $null

if ($InstallMissing) {
    $npm = Get-ToolCommand -Name "npm"

    if ($null -eq $npm) {
        Write-Host "[FAIL] npm is required to install missing dependencies." `
            -ForegroundColor Red
        Write-Host "Install Node.js and npm, then run this script again."
        exit 1
    }
}

$results = foreach ($tool in $tools) {
    $check = Test-MarkdownTool -Tool $tool

    if ($check.Available) {
        [PSCustomObject]@{
            Name    = $tool.Name
            Status  = "PASS"
            Details = "$($check.Version) - $($tool.Purpose)"
        }

        continue
    }

    if (-not $InstallMissing) {
        [PSCustomObject]@{
            Name    = $tool.Name
            Status  = "MISSING"
            Details = "$($check.Message) $($tool.Purpose)"
        }

        continue
    }

    try {
        Install-MarkdownTool -Tool $tool -NpmPath $npm.Source

        # Refresh the current process PATH using npm's global prefix.
        $prefixOutput = @(& $npm.Source prefix --global 2>&1)

        if ($LASTEXITCODE -ne 0) {
            throw "Unable to resolve npm's global installation prefix."
        }

        $npmPrefix = ($prefixOutput | Select-Object -Last 1).ToString().Trim()

        if (-not [string]::IsNullOrWhiteSpace($npmPrefix)) {
            $pathEntries = $env:PATH -split [regex]::Escape([IO.Path]::PathSeparator)

            if ($npmPrefix -notin $pathEntries) {
                $env:PATH = "$npmPrefix$([IO.Path]::PathSeparator)$env:PATH"
            }
        }

        $verification = Test-MarkdownTool -Tool $tool

        if (-not $verification.Available) {
            throw "Installation completed, but verification failed: $($verification.Message)"
        }

        [PSCustomObject]@{
            Name    = $tool.Name
            Status  = "INSTALLED"
            Details = "$($verification.Version) - $($tool.Purpose)"
        }
    }
    catch {
        [PSCustomObject]@{
            Name    = $tool.Name
            Status  = "FAIL"
            Details = $_.Exception.Message
        }
    }
}

Write-Host ""
Write-Host "Results" -ForegroundColor Cyan
Write-Host "-------" -ForegroundColor Cyan

foreach ($result in $results) {
    $color = switch ($result.Status) {
        "PASS"      { "Green" }
        "INSTALLED" { "Green" }
        "MISSING"   { "Yellow" }
        default     { "Red" }
    }

    Write-Host "[$($result.Status)] $($result.Name): $($result.Details)" `
        -ForegroundColor $color
}

$failed = @($results | Where-Object Status -eq "FAIL").Count
$missing = @($results | Where-Object Status -eq "MISSING").Count

Write-Host ""
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "-------" -ForegroundColor Cyan
Write-Host "Checked: $($results.Count)"
Write-Host "Missing: $missing"
Write-Host "Failed:  $failed"

if ($failed -gt 0 -or $missing -gt 0) {
    exit 1
}

Write-Host ""
Write-Host "All Markdown dependencies are available." -ForegroundColor Green
exit 0

