# External Tools and Dependencies

## Overview

This document describes the external tools used by the Neovim configuration for document processing, image rendering, LaTeX compilation, and diagram generation.

These tools are managed independently of Neovim and its plugin manager. Their installation, updates, and system configuration remain explicit user-controlled operations.

The Windows provisioning workflow provides:

- Detection of existing dependencies.
- Installation of missing dependencies.
- User-level PATH configuration.
- Ghostscript compatibility configuration for Snacks.
- Post-installation verification.
- Clear reporting of successful, failed, and skipped operations.

External dependencies are not installed through `vim.pack` or during Neovim startup.

## Dependency Inventory

| Tool | Purpose | Required |
| --- | --- | --- |
| Tectonic | LaTeX compilation and PDF generation | Yes |
| Mermaid CLI | Mermaid diagram rendering | Yes |
| ImageMagick | Image processing and rendering | Yes |
| Ghostscript | PDF processing and rendering | Yes |
| Puppeteer | Browser automation used by Mermaid CLI | Indirect |

Puppeteer is an implementation dependency of Mermaid CLI. It is not managed independently by Neovim.

## Repository Structure

```text
nvim-config/
├── docs/
│   └── architecture/
│       └── external-tools.md
└── scripts/
    └── core/
        └── windows/
            ├── setup-external-deps.ps1
            └── check-external-deps.ps1
```

## Windows Setup

### Prerequisites

The provisioning script requires:

- Windows PowerShell 7.
- Internet access for downloading missing dependencies.
- WinGet for ImageMagick installation.
- Node.js and npm for Mermaid CLI installation.
- Permission to install applications and configure user environment variables.
- Administrator approval when an installer requires elevation.

Check the available commands:

```powershell
$PSVersionTable.PSVersion

Get-Command winget, npm -ErrorAction SilentlyContinue
```

### Provisioning

Run the setup script from the repository root:

```powershell
.\scripts\core\windows\setup-external-deps.ps1
```

The script detects existing installations and attempts to install only missing dependencies.

| Dependency | Installation method |
| --- | --- |
| Tectonic | Official Windows bootstrap procedure |
| Mermaid CLI | npm global installation |
| ImageMagick | WinGet |
| Ghostscript | Official Artifex Windows installer |
| Puppeteer | Mermaid CLI npm dependency |

Existing installations are preserved when their executables are detected. The script does not intentionally upgrade existing installations.

Some installation operations require explicit confirmation. Ghostscript installation may also request administrator approval.

### Setup Options

#### Default setup

Install missing dependencies, configure PATH, and verify the environment:

```powershell
.\scripts\core\windows\setup-external-deps.ps1
```

#### Check only

```powershell
.\scripts\core\windows\setup-external-deps.ps1 -CheckOnly
```

This mode is intended to skip installation and verify existing dependencies.

**Implementation note:** The current script still executes PATH configuration in this mode unless `-SkipPath` is supplied. Use `check-external-deps.ps1` for strictly read-only verification until this behavior is corrected.

#### Configure PATH only

```powershell
.\scripts\core\windows\setup-external-deps.ps1 -ConfigurePathOnly
```

This mode skips dependency installation and configures PATH for detected installations.

#### Skip PATH configuration

```powershell
.\scripts\core\windows\setup-external-deps.ps1 -SkipPath
```

This mode skips adding installation directories to PATH. Installation operations may still create the Ghostscript compatibility shim.

## Installation Details

The following sections document the installation methods and configuration choices used by the provisioning script.

### Tectonic

Tectonic provides LaTeX compilation and PDF generation.

The provisioning script uses the official Windows bootstrap procedure and installs the executable in a user-level directory:

```text
%LOCALAPPDATA%\Programs\Tectonic\tectonic.exe
```

The installation directory is added to the user PATH.

Verify the installation:

```powershell
tectonic --version
```

**Security considerations:**

The bootstrap procedure downloads and executes a remote PowerShell script. Downloaded scripts must be inspected and their source verified before execution.

Avoid silently executing remote scripts or granting them unnecessary privileges.

### Mermaid CLI

Mermaid CLI renders Mermaid diagrams into formats such as SVG and PNG.

The provisioning script installs Mermaid CLI globally through npm:

```powershell
npm install -g @mermaid-js/mermaid-cli --allow-scripts=puppeteer
```

The `--allow-scripts=puppeteer` option explicitly authorizes Puppeteer's installation script instead of enabling lifecycle scripts for every package.

The npm global executable directory must be available through PATH.

Verify the installation:

```powershell
mmdc --version
```

Inspect Puppeteer when troubleshooting:

```powershell
npm ls -g puppeteer --depth=0
```

A missing top-level global Puppeteer package does not necessarily indicate a broken Mermaid CLI installation. Verify Mermaid CLI by executing `mmdc` and rendering an actual diagram.

### ImageMagick

ImageMagick provides image processing and rendering capabilities.

The provisioning script uses WinGet:

```powershell
winget install --exact --id ImageMagick.Q16-HDRI
```

The installation is discovered through the Windows package registration:

```powershell
$package = Get-AppxPackage -Name 'ImageMagick.Q16-HDRI'

if (-not $package) {
    throw 'ImageMagick package was not found.'
}

$package.InstallLocation
```

The discovered package installation directory is added to the user PATH.

Verify the installation:

```powershell
magick -version
```

Discover the executable:

```powershell
Get-Command magick -All
```

Use the actual package installation directory instead of hardcoding a version-specific WindowsApps path.

### Ghostscript

Ghostscript provides PDF processing and rendering support.

The provisioning script uses the official 64-bit Windows distribution from Artifex.

[Ghostscript official downloads](https://www.ghostscript.com/releases/gsdnld.html)

The validated environment uses Ghostscript 10.08.0.

Expected executable:

```text
C:\Program Files\gs\gs10.08.0\bin\gswin64c.exe
```

The installation directory is added to the user PATH.

Verify the installation:

```powershell
Get-Command gswin64c
gswin64c --version
```

#### Snacks compatibility shim

The official Windows installation provides `gswin64c.exe`, while Snacks expects the `gs` command.

The provisioning script creates a compatibility shim:

```text
%USERPROFILE%\.local\bin\gs.cmd
```

The shim forwards arguments to the Ghostscript console executable:

```batch
@echo off
"C:\Program Files\gs\gs10.08.0\bin\gswin64c.exe" %*
exit /b %ERRORLEVEL%
```

The shim directory is added to the user PATH.

Verify:

```powershell
Get-Command gs -All
gs --version
```

The shim must point to the actual Ghostscript installation. Update it when changing the Ghostscript version or installation directory.

### Puppeteer

Puppeteer provides browser automation for Mermaid CLI.

It is installed through Mermaid CLI's npm dependency installation process:

```powershell
npm install -g @mermaid-js/mermaid-cli --allow-scripts=puppeteer
```

Puppeteer does not require an independent PATH entry.

Verify Mermaid CLI functionality with:

```powershell
mmdc --version
```

For additional diagnostics:

```powershell
npm ls -g puppeteer --depth=0
```

## PATH Configuration

External executables must be available through the user or system PATH so Neovim can discover them.

| Tool | Executable | Installation location |
| --- | --- | --- |
| Tectonic | `tectonic.exe` | `%LOCALAPPDATA%\Programs\Tectonic` |
| Mermaid CLI | `mmdc.cmd` | npm global executable directory |
| ImageMagick | `magick.exe` | Package installation directory |
| Ghostscript | `gs.cmd` | `%USERPROFILE%\.local\bin` |
| Ghostscript | `gswin64c.exe` | Ghostscript installation directory |

The provisioning script configures user-level PATH entries and updates the current PowerShell process where possible.

After installation or PATH changes, restart Neovim and any terminal sessions that do not inherit the updated environment.

The script must avoid duplicate PATH entries and preserve existing user PATH values.

## Verification

### Read-only dependency check

Run the external dependency checker from the repository root:

```powershell
.\scripts\core\windows\check-external-deps.ps1
```

The checker validates:

- Tectonic.
- Mermaid CLI.
- ImageMagick.
- Ghostscript.

A successful run returns exit code `0`. A missing executable or failed version command returns exit code `1`.

The checker is read-only. It does not install dependencies, download files, or modify PATH.

### Provisioning verification

The setup script performs post-installation verification:

```powershell
.\scripts\core\windows\setup-external-deps.ps1
```

A successful provisioning run should confirm that all required executables are available and can execute their version commands.

### Verified Windows Environment

The following versions have been verified in the development environment:

| Tool | Verified version | Status |
| --- | --- | --- |
| Tectonic | 0.17.0 | Passed |
| Mermaid CLI | 12.2.0 | Passed |
| ImageMagick | 7.1.2-34 Q16-HDRI x64 | Passed |
| Ghostscript | 10.08.0 | Passed |

These are verified environment versions, not mandatory version pins for every installation.

## Troubleshooting

### Executable not found

Check whether PowerShell can resolve the required commands:

```powershell
Get-Command tectonic, mmdc, magick, gs -All
```

If an executable is missing:

1. Confirm that the application is installed.
2. Confirm that its installation directory is in PATH.
3. Restart the terminal.
4. Run the read-only dependency checker again.

### WinGet installation problems

Check WinGet availability:

```powershell
Get-Command winget
winget --version
```

Check the ImageMagick package:

```powershell
Get-AppxPackage -Name 'ImageMagick.Q16-HDRI'
```

If the package was updated, its installation directory may have changed. Refresh the user PATH accordingly.

### Mermaid CLI or Puppeteer problems

Check Mermaid CLI:

```powershell
mmdc --version
```

Inspect the global Puppeteer package:

```powershell
npm ls -g puppeteer --depth=0
```

If Mermaid CLI reports browser or rendering errors, investigate its Puppeteer installation and perform an actual diagram-rendering test.

### Ghostscript command resolution

If `gswin64c` works but `gs` does not, verify the compatibility shim and its PATH entry:

```powershell
Get-Command gswin64c, gs -All
```

Inspect the shim:

```powershell
Get-Content (Join-Path $HOME '.local\bin\gs.cmd')
```

### Tectonic installation problems

Check the executable:

```powershell
Get-Command tectonic -All
tectonic --version
```

Confirm that the executable exists in:

```text
%LOCALAPPDATA%\Programs\Tectonic
```

## Maintenance

- Keep installation procedures aligned with tested Windows behavior.
- Keep the read-only checker separate from the provisioning script.
- Do not move external tool installation into Neovim startup.
- Do not use `vim.pack` to install system executables.
- Avoid hardcoding version-specific installation paths when package discovery is available.
- Pin installer versions and verify downloaded artifacts before execution.
- Preserve existing user PATH values and avoid duplicate entries.
- Do not silently upgrade existing dependencies.
- Update this document whenever a dependency, executable name, or installation procedure changes.
- Revalidate the Windows environment after updating external tools.
- Test fresh installations, existing installations, missing dependencies, and failed installation scenarios.
