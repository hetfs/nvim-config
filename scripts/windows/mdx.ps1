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
# mise is automatically installed if it is missing.

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

$script:MiseCommand = $null
$script:MiseShimsDirectory = $null

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Invoke-External {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter()][string[]]$Arguments = @()
    )

    & $Command @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command $($Arguments -join ' ')"
    }
}

function Add-PathEntry {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][ValidateSet("Process", "User")][string]$Scope
    )

    if ([string]::IsNullOrWhiteSpace($Directory)) {
        return
    }

    $normalizedDirectory = [Environment]::ExpandEnvironmentVariables(
        $Directory.Trim().Trim('"')
    ).TrimEnd('\')

    if ($Scope -eq "Process") {
        $entries = @($env:Path -split ';' | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        })

        $exists = $false
        foreach ($entry in $entries) {
            $candidate = [Environment]::ExpandEnvironmentVariables(
                $entry.Trim().Trim('"')
            ).TrimEnd('\')

            if ([string]::Equals(
                $candidate,
                $normalizedDirectory,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                $exists = $true
                break
            }
        }

        if (-not $exists) {
            $env:Path = (@($Directory) + $entries) -join ';'
        }

        return
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $userEntries = @($userPath -split ';' | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    })

    foreach ($entry in $userEntries) {
        $candidate = [Environment]::ExpandEnvironmentVariables(
            $entry.Trim().Trim('"')
        ).TrimEnd('\')

        if ([string]::Equals(
            $candidate,
            $normalizedDirectory,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            return
        }
    }

    $newUserPath = (@($userEntries) + $Directory) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
}

function Initialize-Mise {
    Write-Step "Checking mise installation"

    $miseBin = Join-Path $HOME ".local\bin"
    $miseExe = Join-Path $miseBin "mise.exe"

    $existingCommand = Get-Command mise `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    if (-not $existingCommand -and
        -not (Test-Path -LiteralPath $miseExe -PathType Leaf)) {

        Write-Step "Installing mise"
        Write-Host "Downloading the official mise PowerShell installer ..."

        try {
            $installerScript = Invoke-RestMethod `
                -Uri "https://mise.run/powershell" `
                -ErrorAction Stop

            if ([string]::IsNullOrWhiteSpace($installerScript)) {
                throw "The mise installer returned an empty response."
            }

            Invoke-Expression $installerScript
            Write-Success "mise installer completed"
        }
        catch {
            throw @"
Failed to install mise automatically.

Installer error:
$($_.Exception.Message)

Manual installation:
irm https://mise.run/powershell | iex
"@
        }
    }
    elseif ($existingCommand) {
        Write-Success "mise is already available"
    }
    else {
        Write-Success "Found mise at $miseExe"
    }

    # Make the mise executable visible in this PowerShell process.
    if (Test-Path -LiteralPath $miseBin -PathType Container) {
        Add-PathEntry -Directory $miseBin -Scope Process
        Add-PathEntry -Directory $miseBin -Scope User
    }

    $miseCommand = Get-Command mise `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    if (Test-Path -LiteralPath $miseExe -PathType Leaf) {
        $script:MiseCommand = $miseExe
    }
    elseif ($miseCommand) {
        $script:MiseCommand = $miseCommand.Source
    }
    else {
        throw "mise was not found after installation. Expected: $miseExe"
    }

    # Windows' default mise data/shims directory. Respect an explicit
    # MISE_SHIMS_DIR override if the user has configured one.
    if (-not [string]::IsNullOrWhiteSpace($env:MISE_SHIMS_DIR)) {
        $script:MiseShimsDirectory = [Environment]::ExpandEnvironmentVariables(
            $env:MISE_SHIMS_DIR
        )
    }
    elseif (-not [string]::IsNullOrWhiteSpace($env:MISE_DATA_DIR)) {
        $script:MiseShimsDirectory = Join-Path $env:MISE_DATA_DIR "shims"
    }
    else {
        $script:MiseShimsDirectory = Join-Path $env:LOCALAPPDATA "mise\shims"
    }

    Write-Success "mise executable: $script:MiseCommand"
    Invoke-External -Command $script:MiseCommand -Arguments @("--version")
}

function Invoke-Mise {
    param([Parameter(Mandatory)][string[]]$Arguments)

    if ([string]::IsNullOrWhiteSpace($script:MiseCommand)) {
        throw "mise has not been initialized."
    }

    Invoke-External -Command $script:MiseCommand -Arguments $Arguments
}

function Initialize-MiseShims {
    Write-Step "Configuring mise shims for Windows applications"

    # Rebuild command shims after the npm package has been installed.
    Invoke-Mise -Arguments @("reshim")

    if (-not (Test-Path -LiteralPath $script:MiseShimsDirectory -PathType Container)) {
        throw @"
mise reshim completed, but its shims directory does not exist:
$script:MiseShimsDirectory

Check the mise shims_dir setting or MISE_SHIMS_DIR environment variable.
"@
    }

    # Add shims to both the current process and persistent user PATH.
    Add-PathEntry -Directory $script:MiseShimsDirectory -Scope Process
    Add-PathEntry -Directory $script:MiseShimsDirectory -Scope User

    # Refresh command discovery after changing PATH.
    $env:Path = $env:Path
    Write-Success "mise shims directory: $script:MiseShimsDirectory"
    Write-Success "mise shims added to current and user PATH"
}

# ---------------------------------------------------------------------------
# Validate environment and install mise if necessary
# ---------------------------------------------------------------------------

Write-Step "Validating environment"
Initialize-Mise

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
    Invoke-Mise -Arguments @("use", "--global", $tool)
}

Write-Success "Global MDX tools installed"

# npm-installed executables such as mdx-language-server need a mise shim
# so Neovim and other GUI applications can discover them through PATH.
Initialize-MiseShims

# ---------------------------------------------------------------------------
# Verify MDX language-server executable
# ---------------------------------------------------------------------------

Write-Step "Verifying MDX language server"

$mdxLanguageServer = Get-Command mdx-language-server `
    -CommandType Application `
    -ErrorAction SilentlyContinue

if (-not $mdxLanguageServer) {
    # Try one more shim rebuild in case npm created its bin link late.
    Invoke-Mise -Arguments @("reshim")

    $mdxLanguageServer = Get-Command mdx-language-server `
        -CommandType Application `
        -ErrorAction SilentlyContinue
}

if (-not $mdxLanguageServer) {
    throw @"
The npm package was installed, but mdx-language-server is still not
discoverable through PATH.

Expected mise shim:
$(Join-Path $script:MiseShimsDirectory 'mdx-language-server.exe')

Check the package installation with:
mise ls --installed
mise which mdx-language-server
"@
}

Write-Success "MDX language server: $($mdxLanguageServer.Source)"

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
                "exec", "--", "npm", "install",
                "--save-dev", "--save-exact",
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

Invoke-Mise -Arguments @("exec", "--", "node", "--version")
Invoke-Mise -Arguments @("exec", "--", "npm", "--version")
Invoke-Mise -Arguments @("exec", "--", "dprint", "--version")

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
Write-Host "MDX executable: $($mdxLanguageServer.Source)"
Write-Host "Node.js: 26"
Write-Host "Formatter: dprint"
Write-Host "mise shims: $script:MiseShimsDirectory"
Write-Host "`nRestart Neovim so it inherits the updated Windows PATH." -ForegroundColor Yellow
