# Install and validate the tools used by the Neovim data language pack.
# Individual scripts own their installation logic.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$Installers = @(
    "yaml.ps1"
    "json.ps1"
    "jq-lsp.ps1"
    "toml.ps1"
)

Write-Host ""
Write-Host "Preparing data-pack installation..." -ForegroundColor Cyan

# jq is installed separately from jq-lsp.
if (-not (Get-Command "jq" -CommandType Application -ErrorAction SilentlyContinue)) {
    throw "jq is required but was not found in PATH. Install jq before running this script."
}

Write-Host "jq is available." -ForegroundColor Green

foreach ($Name in $Installers) {
    $Installer = Join-Path $PSScriptRoot $Name

    if (-not (Test-Path -LiteralPath $Installer -PathType Leaf)) {
        throw "Required installer not found: $Installer"
    }

    Write-Host ""
    Write-Host "Installing through $Name..." -ForegroundColor Cyan

    try {
        & $Installer
        Write-Host "$Name completed successfully." -ForegroundColor Green
    }
    catch {
        throw "Data-pack installation failed in ${Name}: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Data-pack installation completed successfully." -ForegroundColor Green
