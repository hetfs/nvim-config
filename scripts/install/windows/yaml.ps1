[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Stage 13: YAML external tools.
# Install globally through npm; never run automatically during Neovim startup.

$Tools = @(
    @{
        Name    = "yaml-language-server"
        Package = "yaml-language-server"
        Version = "2.0.0"
    },
    @{
        Name    = "prettier"
        Package = "prettier"
        Version = "3.9.10"
    }
)

function Get-ToolVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue

    if (-not $command) {
        return $null
    }

    try {
        $output = & $command.Source --version 2>&1

        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        return (($output | Out-String).Trim())
    }
    catch {
        return $null
    }
}

function Install-NpmTool {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tool
    )

    $installedVersion = Get-ToolVersion -Name $Tool.Name

    if ($installedVersion -eq $Tool.Version) {
        Write-Host "[OK] $($Tool.Name) $installedVersion is already installed."
        return
    }

    if ($installedVersion) {
        Write-Host "[UPDATE] $($Tool.Name): $installedVersion -> $($Tool.Version)"
    }
    else {
        Write-Host "[INSTALL] $($Tool.Name) $($Tool.Version)"
    }

    $packageSpec = "$($Tool.Package)@$($Tool.Version)"

    & $script:Npm.Source install --global $packageSpec

    if ($LASTEXITCODE -ne 0) {
        throw "npm failed to install $packageSpec (exit code $LASTEXITCODE)."
    }

    # Verify the installed executable and its version.
    $verifiedVersion = Get-ToolVersion -Name $Tool.Name

    if ($verifiedVersion -ne $Tool.Version) {
        throw "Verification failed for $($Tool.Name). Expected $($Tool.Version); found '$verifiedVersion'."
    }

    Write-Host "[OK] $($Tool.Name) $verifiedVersion installed and verified."
}

try {
    Write-Host "`nYAML external tools"
    Write-Host "==================="

    # Node.js and npm are prerequisites.
    $node = Get-Command node -ErrorAction SilentlyContinue

    if (-not $node) {
        throw "Node.js is not installed or is not available on PATH."
    }

    $script:Npm = Get-Command npm -ErrorAction SilentlyContinue

    if (-not $script:Npm) {
        throw "npm is not installed or is not available on PATH."
    }

    Write-Host "[INFO] Node.js: $(& $node.Source --version)"
    Write-Host "[INFO] npm: $(& $script:Npm.Source --version)"

    foreach ($tool in $Tools) {
        Install-NpmTool -Tool $tool
    }

    Write-Host "`nYAML tool verification"
    Write-Host "======================"

    foreach ($tool in $Tools) {
        $version = Get-ToolVersion -Name $tool.Name

        if (-not $version) {
            throw "$($tool.Name) is not discoverable on PATH."
        }

        Write-Host "[OK] $($tool.Name): $version"
    }

    Write-Host "`nYAML external tools are ready." -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}
