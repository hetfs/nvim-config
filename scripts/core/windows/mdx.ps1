
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspacePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Stage 13: MDX development toolchain.
#
# Global tools managed by mise:
#   Node.js 26
#   dprint
#   @mdx-js/language-server 0.6.4
#
# Optional workspace dependency:
#   TypeScript 6.0.3
#
# dprint plugins are resolved through dprint.json.
# Tree-sitter CLI and native compiler are verified, not installed.

$RequiredTypescriptVersion = "6.0.3"

$GlobalTools = @(
    "node@26",
    "dprint",
    "npm:@mdx-js/language-server@0.6.4"
)

$RequiredDprintPlugins = @(
    "npm:dprint-plugin-mdx",
    "npm:@dprint/typescript@0.100.0"
)

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Invoke-External {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter()]
        [string[]]$Arguments = @()
    )

    & $Command @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command $($Arguments -join ' ')"
    }
}

function Invoke-Mise {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    Invoke-External -Command "mise" -Arguments $Arguments
}

# ---------------------------------------------------------------------------
# Validate environment
# ---------------------------------------------------------------------------

Write-Step "Validating environment"

if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    throw @"
mise is required but was not found on PATH.

Install mise using its official PowerShell installer:

irm https://mise.run/powershell | iex

Restart PowerShell and run this script again.
"@
}

Write-Success "mise is available"

# ---------------------------------------------------------------------------
# Resolve optional workspace
# ---------------------------------------------------------------------------

$ResolvedWorkspace = $null

if (-not [string]::IsNullOrWhiteSpace($WorkspacePath)) {
    if (-not (Test-Path -LiteralPath $WorkspacePath -PathType Container)) {
        throw "Workspace directory does not exist: $WorkspacePath"
    }

    $ResolvedWorkspace = (Resolve-Path -LiteralPath $WorkspacePath).Path

    $packageJson = Join-Path $ResolvedWorkspace "package.json"
    $dprintConfig = Join-Path $ResolvedWorkspace "dprint.json"

    if (-not (Test-Path -LiteralPath $packageJson -PathType Leaf)) {
        throw "Workspace package.json not found: $packageJson"
    }

    if (-not (Test-Path -LiteralPath $dprintConfig -PathType Leaf)) {
        throw "Workspace dprint.json not found: $dprintConfig"
    }

    Write-Success "Workspace: $ResolvedWorkspace"
}
else {
    Write-Success "No workspace supplied. Global installation only."
}

# ---------------------------------------------------------------------------
# Install global tools through mise
# ---------------------------------------------------------------------------

Write-Step "Installing global MDX tools"

foreach ($tool in $GlobalTools) {
    Write-Host "Installing $tool ..."

    Invoke-Mise -Arguments @(
        "use",
        "--global",
        $tool
    )
}

Write-Success "Global MDX tools installed"

# ---------------------------------------------------------------------------
# Install workspace TypeScript dependency
# ---------------------------------------------------------------------------

if ($ResolvedWorkspace) {
    Write-Step "Checking workspace TypeScript"

    $typescriptPackage = Join-Path $ResolvedWorkspace `
        "node_modules/typescript/package.json"

    $installedTypescript = $null

    if (Test-Path -LiteralPath $typescriptPackage -PathType Leaf) {
        $installedTypescript = Get-Content `
            -LiteralPath $typescriptPackage `
            -Raw |
            ConvertFrom-Json
    }

    if (
        $installedTypescript -and
        $installedTypescript.version -eq $RequiredTypescriptVersion
    ) {
        Write-Success "TypeScript $RequiredTypescriptVersion is already installed"
    }
    else {
        if ($installedTypescript) {
            Write-WarningMessage (
                "Found TypeScript $($installedTypescript.version). " +
                "Expected $RequiredTypescriptVersion."
            )
        }

        Write-Host "Installing TypeScript $RequiredTypescriptVersion ..."

        Push-Location $ResolvedWorkspace

        try {
            Invoke-Mise -Arguments @(
                "exec",
                "--",
                "npm",
                "install",
                "--save-dev",
                "--save-exact",
                "typescript@$RequiredTypescriptVersion"
            )
        }
        finally {
            Pop-Location
        }

        Write-Success "Workspace TypeScript installed"
    }

    # -----------------------------------------------------------------------
    # Validate dprint configuration
    # -----------------------------------------------------------------------

    Write-Step "Validating dprint configuration"

    $config = Get-Content -LiteralPath $dprintConfig -Raw |
        ConvertFrom-Json

    if (-not $config.plugins) {
        throw "No plugins array found in $dprintConfig"
    }

    foreach ($plugin in $RequiredDprintPlugins) {
        if ($config.plugins -notcontains $plugin) {
            throw "Missing dprint plugin in dprint.json: $plugin"
        }

        Write-Success "Configured: $plugin"
    }
}

# ---------------------------------------------------------------------------
# Verify Tree-sitter build tools
# ---------------------------------------------------------------------------

Write-Step "Checking Tree-sitter build tools"

if (Get-Command tree-sitter -ErrorAction SilentlyContinue) {
    Invoke-External -Command "tree-sitter" -Arguments @("--version")
}
else {
    Write-WarningMessage "Tree-sitter CLI is not available on PATH"
}

if (
    (Get-Command gcc -ErrorAction SilentlyContinue) -or
    (Get-Command clang -ErrorAction SilentlyContinue)
) {
    Write-Success "Native compiler is available"
}
else {
    Write-WarningMessage "GCC or Clang was not found. Parser compilation may fail."
}

# ---------------------------------------------------------------------------
# Verify installed tools
# ---------------------------------------------------------------------------

Write-Step "Verifying MDX toolchain"

Invoke-Mise -Arguments @(
    "exec",
    "--",
    "node",
    "--version"
)

Invoke-Mise -Arguments @(
    "exec",
    "--",
    "npm",
    "--version"
)

Invoke-Mise -Arguments @(
    "exec",
    "--",
    "dprint",
    "--version"
)

Write-Success "Global tool verification completed"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host "`nMDX development environment is ready." -ForegroundColor Green

if ($ResolvedWorkspace) {
    Write-Host "Workspace: $ResolvedWorkspace"
}
else {
    Write-Host "Workspace: Not configured"
}

Write-Host "MDX language server: @mdx-js/language-server 0.6.4"
Write-Host "Node.js: 26"
Write-Host "Formatter: dprint"

