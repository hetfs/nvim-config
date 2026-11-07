# Install the Python command-line tools used by nvim-config:
# uv (project/environment management), ty (language server), and Ruff (lint/format).
# Run explicitly from PowerShell. Neovim never installs these tools.
#
# Optional:
#   .\python.ps1 -ConfigureTyCompletion
#   .\python.ps1 -Force

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$ConfigureTyCompletion
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This installer supports Windows only.'
}

$Tools = @(
    [pscustomobject]@{ Name = 'uv'; Command = 'uv'; Url = 'https://astral.sh/uv/install.ps1' },
    [pscustomobject]@{ Name = 'ty'; Command = 'ty'; Url = 'https://astral.sh/ty/install.ps1' },
    [pscustomobject]@{ Name = 'Ruff'; Command = 'ruff'; Url = 'https://astral.sh/ruff/install.ps1' }
)
$Results = [System.Collections.Generic.List[object]]::new()

function Write-Status {
    param(
        [ValidateSet('INFO', 'OK', 'SKIP', 'FAIL')][string]$Level,
        [string]$Message
    )
    $color = switch ($Level) {
        'INFO' { 'Cyan' }
        'OK'   { 'Green' }
        'SKIP' { 'Yellow' }
        'FAIL' { 'Red' }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Update-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($machinePath, $userPath) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    $localBin = Join-Path $HOME '.local\bin'
    if (Test-Path -LiteralPath $localBin -PathType Container) {
        $parts += $localBin
    }

    $current = @($env:Path -split ';' |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $env:Path = (@($parts) + $current | Select-Object -Unique) -join ';'
}

function Get-ToolCommand {
    param([string]$Name)
    Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Get-ToolVersion {
    param([string]$Name)
    switch ($Name) {
        'uv'   { & uv --version }
        'ty'   { & ty --version }
        'ruff' { & ruff --version }
    }
    if ($LASTEXITCODE -ne 0) {
        throw "The $Name version check failed."
    }
}

function Invoke-AstralInstaller {
    param([string]$Name, [string]$Url)

    Write-Status INFO "Downloading the official $Name installer: $Url"
    $installer = Invoke-RestMethod -Uri $Url -Method Get
    if ([string]::IsNullOrWhiteSpace($installer)) {
        throw "The $Name installer download was empty."
    }

    # This executes the installer script published by Astral over HTTPS.
    Invoke-Expression $installer
}

foreach ($tool in $Tools) {
    try {
        $command = Get-ToolCommand -Name $tool.Command

        if ($command -and -not $Force) {
            $version = Get-ToolVersion -Name $tool.Command
            Write-Status SKIP "$($tool.Name) is already available: $version"
            $Results.Add([pscustomobject]@{
                Tool = $tool.Name; Status = 'Already available'
                Version = ($version | Out-String).Trim(); Path = $command.Source
            })
            continue
        }

        if ($command) {
            Write-Status INFO "$($tool.Name) is available; -Force requested installer execution."
        }

        Invoke-AstralInstaller -Name $tool.Name -Url $tool.Url
        Update-ProcessPath

        $command = Get-ToolCommand -Name $tool.Command
        if (-not $command) {
            throw "$($tool.Name) installer finished, but '$($tool.Command)' is not discoverable in PATH."
        }

        $version = Get-ToolVersion -Name $tool.Command
        Write-Status OK "$($tool.Name) verified: $version"
        $Results.Add([pscustomobject]@{
            Tool = $tool.Name; Status = 'Installed and verified'
            Version = ($version | Out-String).Trim(); Path = $command.Source
        })
    }
    catch {
        Write-Status FAIL "$($tool.Name): $($_.Exception.Message)"
        $Results.Add([pscustomobject]@{
            Tool = $tool.Name; Status = 'Failed'; Version = ''; Path = ''
        })
    }
}

if ($ConfigureTyCompletion) {
    try {
        if (-not (Get-ToolCommand -Name 'ty')) {
            throw 'ty is not available; cannot configure its shell completion.'
        }

        $completionLine = '(& ty generate-shell-completion powershell) | Out-String | Invoke-Expression'
        $profileDirectory = Split-Path -Parent $PROFILE

        if (-not (Test-Path -LiteralPath $profileDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
        }
        if (-not (Test-Path -LiteralPath $PROFILE -PathType Leaf)) {
            New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        }

        $profileContent = Get-Content -LiteralPath $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($profileContent -notmatch [regex]::Escape($completionLine)) {
            Add-Content -LiteralPath $PROFILE -Value $completionLine
            Write-Status OK "Added ty completion to $PROFILE"
        }
        else {
            Write-Status SKIP "ty completion is already configured in $PROFILE"
        }
    }
    catch {
        Write-Status FAIL "Ty shell completion: $($_.Exception.Message)"
        $Results.Add([pscustomobject]@{
            Tool = 'ty shell completion'; Status = 'Failed'
            Version = ''; Path = $PROFILE
        })
    }
}

Update-ProcessPath

Write-Host ''
Write-Host 'Python tool installation summary' -ForegroundColor Cyan
$Results | Format-Table -AutoSize

$failed = @($Results | Where-Object { $_.Status -eq 'Failed' })
if ($failed.Count -gt 0) {
    Write-Status FAIL "$($failed.Count) step(s) failed."
    exit 1
}

Write-Status OK 'Python tool checks completed.'
if ($ConfigureTyCompletion) {
    Write-Host 'Restart PowerShell or reload the profile to enable ty completion.'
}
