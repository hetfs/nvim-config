# Rust installation guide for Windows

This guide documents the Windows MSVC toolchain installation required to develop and build Rust projects on Windows.

It covers Rustup, the Rust toolchain, Rust components, Visual Studio Build Tools, the Windows SDK, and the verification of the native build environment.

Rust installation is independent of Neovim. Editor configuration does not install the Rust compiler, linker, Windows SDK, or external utilities.

This guide records the verified installation state as of **7 November 2026**.

## 1. Installation requirements

The Rust environment uses the native Windows MSVC target.

| Component | Purpose | Required state |
| --- | --- | --- |
| `rustup` | Rust toolchain manager | Installed |
| `rustc` | Rust compiler | Installed |
| `cargo` | Build and package manager | Installed |
| `rust-analyzer` | Rust language server executable | Installed |
| `rustfmt` | Rust formatter | Installed |
| `rust-src` | Rust standard-library source | Installed |
| `clippy` | Rust linter | Installed |
| `rust-docs` | Local Rust documentation | Installed |
| MSVC C++ Build Tools | Native compiler and linker | Installed |
| Windows SDK | Windows headers and libraries | Installed |

The active toolchain is:

```text
stable-x86_64-pc-windows-msvc
```

The target architecture is:

```text
x86_64-pc-windows-msvc
```

Keep this target unless you deliberately decide to maintain a separate GNU-based Rust environment.

## 2. Install Visual Studio Build Tools

The MSVC Rust toolchain requires Microsoft's C++ build tools. Installing Rust alone is not sufficient for projects that depend on native Windows compilation.

Download the installer:

- [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)

In Visual Studio Installer:

1. Select **Desktop development with C++**.
2. Ensure the MSVC x64/x86 build tools are selected.
3. Ensure a Windows 10 or Windows 11 SDK is selected.
4. Install the selected components.

The full Visual Studio IDE is not required.

Alternatively, locate the WinGet package:

```powershell
winget search --id Microsoft.VisualStudio.BuildTools --exact
```

If it is available, install it:

```powershell
winget install --id Microsoft.VisualStudio.BuildTools --exact
```

After installation, open Visual Studio Installer and select the C++ workload and required components.

Installing the package alone does not guarantee that the complete C++ workload is installed.

## 3. Verify Visual Studio Build Tools and the Windows SDK

### 3.1 Locate Visual Studio

Use `vswhere.exe` to locate the Visual Studio Build Tools installation:

```powershell
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

Test-Path $vswhere

& $vswhere -latest -products * -property installationPath
```

To check whether the Visual C++ workload is registered:

```powershell
& $vswhere -latest -products * `
    -requires Microsoft.VisualStudio.Workload.VCTools `
    -property installationPath
```

A returned installation path confirms that `vswhere` found an installation containing the requested workload.

No output means the workload was not confirmed by this query. It does not, by itself, prove that MSVC files are absent.

### 3.2 Inspect the MSVC toolset

Set the installation path returned by `vswhere`:

```powershell
$vsPath = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools'
$msvcPath = Join-Path $vsPath 'VC\Tools\MSVC'

Get-ChildItem $msvcPath -Directory
```

Check for the x64-hosted compiler and linker:

```powershell
Get-ChildItem "$msvcPath\*\bin\Hostx64\x64\cl.exe"
Get-ChildItem "$msvcPath\*\bin\Hostx64\x64\link.exe"
```

The expected executables are:

- `cl.exe`: Microsoft C/C++ compiler.
- `link.exe`: Microsoft linker.

Finding these files confirms that the executables exist on disk. It does not confirm that they are available through the current shell's `PATH`.

### 3.3 Inspect the Windows SDK

Check the standard Windows SDK installation directory:

```powershell
$sdkPath = "${env:ProgramFiles(x86)}\Windows Kits\10"

Test-Path "$sdkPath\Include"
Test-Path "$sdkPath\Lib"
Test-Path "$sdkPath\bin"

Get-ChildItem "$sdkPath\Include" -Directory -ErrorAction SilentlyContinue
Get-ChildItem "$sdkPath\Lib" -Directory -ErrorAction SilentlyContinue
```

The SDK's `Include`, `Lib`, and `bin` directories should exist. The versioned `Include` and `Lib` directories identify the installed SDK version.

### 3.4 Verified installation on this machine

The following results were observed:

| Item | Verified result |
| --- | --- |
| Visual Studio installation | `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools` |
| Visual Studio Build Tools version | `18.11.3` |
| MSVC toolset directories | `14.44.35207` and `14.51.36231` |
| `cl.exe` | Found under `14.44.35207\bin\Hostx64\x64` |
| `link.exe` | Found under `14.44.35207\bin\Hostx64\x64` |
| Windows SDK | `10.0.22621.0` |
| C++ workload query | No installation path returned by the `vswhere -requires` query |

The compiler and linker were found on disk using:

```powershell
$vsPath = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools'
$msvcPath = Join-Path $vsPath 'VC\Tools\MSVC'

Get-ChildItem "$msvcPath\*\bin\Hostx64\x64\cl.exe"
Get-ChildItem "$msvcPath\*\bin\Hostx64\x64\link.exe"
```

## 4. Verify the MSVC environment

Visual Studio provides a developer-shell initialization script that configures the environment for native development.

The following command was used to launch the Visual Studio 2026 Developer PowerShell environment:

```powershell
$vsPath = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools'
$devShell = Join-Path $vsPath 'Common7\Tools\Launch-VsDevShell.ps1'

. $devShell -Arch amd64 -HostArch amd64
```

The script displayed the Visual Studio 2026 Developer PowerShell `18.11.3` banner.

However, these checks still did not resolve the executables in that session:

```powershell
Get-Command cl.exe
Get-Command link.exe

where.exe cl.exe
where.exe link.exe
```

The commands did not find the compiler or linker through the current `PATH`.

Record this as an environment-discovery issue. Do not report that `cl.exe` and `link.exe` are available through the current PowerShell `PATH` merely because their files exist on disk.

The successful Cargo build documented in Section 7 confirms that the tested Rust project can build. It does not establish that arbitrary native build scripts or other tools can discover MSVC executables through the current shell environment.

If a future dependency requires direct MSVC executable discovery, investigate the Visual Studio environment setup and workload/component selection.

## 5. Install and verify Rust

### 5.1 Install Rustup

Download Rustup from the official installation page:

- [Rustup installation](https://rustup.rs/)

For Windows, use the installer appropriate for the MSVC toolchain.

Rustup manages Rust toolchains and their components. It allows Rust to be updated without manually replacing compiler binaries.

### 5.2 Verify Rustup

Check the installed Rustup version:

```powershell
rustup --version
```

Check the active toolchain:

```powershell
rustup show
```

Verify the compiler and Cargo:

```powershell
rustc --version
cargo --version
rustc -vV
```

Confirm that the host is:

```text
x86_64-pc-windows-msvc
```

### 5.3 Verify the active toolchain

The expected active toolchain is:

```text
stable-x86_64-pc-windows-msvc
```

If it is not installed, install it:

```powershell
rustup toolchain install stable-x86_64-pc-windows-msvc
```

Set it as the default only if that is your intended system-wide Rust toolchain:

```powershell
rustup default stable-x86_64-pc-windows-msvc
```

Check the active toolchain again:

```powershell
rustup show
```

## 6. Install and verify Rust components

Install the components required for Rust development:

```powershell
rustup component add rust-analyzer rustfmt rust-src
```

Install Clippy if it is not already installed:

```powershell
rustup component add clippy
```

Install local Rust documentation if required:

```powershell
rustup component add rust-docs
```

Check the installed components:

```powershell
rustup component list --installed
```

### 6.1 Verified installed components

The following output was observed:

```text
cargo-x86_64-pc-windows-msvc
clippy-x86_64-pc-windows-msvc
rust-analyzer-x86_64-pc-windows-msvc
rust-docs-x86_64-pc-windows-msvc
rust-src
rust-std-x86_64-pc-windows-msvc
rustc-x86_64-pc-windows-msvc
rustfmt-x86_64-pc-windows-msvc
```

The installed Rust tool versions reported were:

```text
rust-analyzer 1.99.1 (58cf8f9c 2026-10-13)
rustfmt 1.10.0-stable (58cf8f9c35 2026-10-13)
```

The Rust executables were found in:

```text
C:\Users\Administrator\.cargo\bin
```

### 6.2 Verified Rust versions

The following versions were observed:

| Tool | Verified version |
| --- | --- |
| Rustup | `1.29.3` |
| Rust compiler | `1.99.1` |
| Cargo | `1.99.1` |
| Rust Analyzer | `1.99.1` |
| Rustfmt | `1.10.0-stable` |

The compiler reported:

```text
rustc 1.99.1 (58cf8f9c3 2026-10-13)
```

Cargo reported:

```text
cargo 1.99.1 (5f94df478 2026-08-27)
```

References:

- [Rustup components](https://rust-lang.github.io/rustup/concepts/components.html)
- [rust-analyzer installation](https://rust-analyzer.github.io/book/installation.html)

## 7. Test a Rust project

Before relying on the installation, verify that Cargo can create, compile, test, and execute a Rust project.

Run these commands in PowerShell:

```powershell
cargo new hello
Set-Location hello

cargo build
cargo test
cargo run
```

Expected results:

- `cargo build` compiles the project successfully.
- `cargo test` completes successfully.
- `cargo run` executes the generated application and prints `Hello, world!`.

You can also check formatting:

```powershell
cargo fmt --check
```

If formatting needs correction, run:

```powershell
cargo fmt
```

### 7.1 Verified test results

The following workflow was completed successfully:

```powershell
cargo new hello
Set-Location hello

cargo build
cargo test
cargo run
```

The project compiled, the test harness completed with zero failures, and the application printed:

```text
Hello, world!
```

A clean rebuild was also verified:

```powershell
cargo clean
cargo build
cargo test
cargo run
```

The clean command removed the previous build artifacts. The subsequent build, test, and run all succeeded.

This confirms that the tested Rust project can build and run with the installed MSVC-targeted Rust toolchain.

It does not prove that `cl.exe` and `link.exe` are discoverable by every process through the current PowerShell `PATH`.

## 8. Manage Rust dependencies with the Windows installer

The repository provides a PowerShell script for checking and updating the Rust toolchain and its required components.

Script location:

```text
scripts/core/windows/rust.ps1
```

Run the script from the repository root.

The script manages Rustup, the configured Rust toolchain, Rust components, and verification of the Windows native build environment.

It does not install Visual Studio Build Tools or the Windows SDK.

### 8.1 Check the existing installation

Use check mode to inspect the installed Rust environment without installing or updating components:

```powershell
pwsh -NoProfile -File .\scripts\core\windows\rust.ps1 -Check
```

Check mode verifies:

- Windows platform detection.
- Rustup availability and version.
- Active Rust toolchain.
- Required Rust components.
- Rust executable availability and versions.
- MSVC compiler and linker files.
- Visual C++ workload discovery through `vswhere`.
- Windows SDK installation.

A successful check returns exit code `0`. A failed required check returns exit code `1`.

Check mode does not install or update Rust components.

To inspect the exit code after execution:

```powershell
$LASTEXITCODE
```

### 8.2 Update the Rust toolchain

Use update mode to update the configured toolchain and ensure the required Rust components are installed:

```powershell
pwsh -NoProfile -File .\scripts\core\windows\rust.ps1 -Update
```

The script:

1. Detects the existing Rustup installation.
2. Ensures the configured Rust toolchain is installed.
3. Updates the toolchain.
4. Installs required components that are missing.
5. Skips components that are already installed.
6. Verifies Rust tools and components after the update.
7. Checks MSVC and Windows SDK availability.

The script does not reinstall components that are already present.

### 8.3 Verified check execution

The following command completed successfully on 7 November 2026:

```powershell
pwsh -NoProfile -File .\scripts\core\windows\rust.ps1 -Check
```

The script confirmed:

```text
[PASS] Windows platform detected.
[PASS] Rustup found
[PASS] rustup 1.29.3
[PASS] rust-analyzer is installed.
[PASS] rustfmt is installed.
[PASS] rust-src is installed.
[PASS] clippy is installed.
[PASS] rust-docs is installed.
[PASS] Active toolchain: stable-x86_64-pc-windows-msvc (default)
```

It also found the MSVC compiler, linker, and Windows SDK.

The following warnings remained:

```text
[WARN] The Visual C++ workload was not confirmed by vswhere.
[WARN] cl.exe exists on disk but is not discoverable through PATH.
[WARN] link.exe exists on disk but is not discoverable through PATH.
```

The script completed with:

```text
[PASS] Rust dependency installation and verification completed.
```

The PowerShell exit code was verified separately:

```powershell
$LASTEXITCODE
0
```

**Result:** Check mode passed.

### 8.4 Verified update execution

The following command also completed successfully:

```powershell
pwsh -NoProfile -File .\scripts\core\windows\rust.ps1 -Update
```

The script detected the existing stable toolchain:

```text
[SKIP] stable-x86_64-pc-windows-msvc is already installed.
```

Rustup checked for updates and reported:

```text
stable-x86_64-pc-windows-msvc unchanged - rustc 1.99.1 (58cf8f9c3 2026-10-13)
```

The script skipped the five components that were already installed:

```text
[SKIP] rust-analyzer is already installed.
[SKIP] rustfmt is already installed.
[SKIP] rust-src is already installed.
[SKIP] clippy is already installed.
[SKIP] rust-docs is already installed.
```

Post-update verification confirmed the required tools, components, active toolchain, MSVC compiler and linker files, and Windows SDK.

The same three MSVC environment warnings remained.

The script completed with:

```text
[PASS] Rust dependency installation and verification completed.
```

**Result:** Update mode completed successfully. The stable toolchain was already current, and no missing components required installation.

## 9. Verify the Windows environment

### 9.1 Verify Rust executable discovery

Check the Rust commands from the PowerShell environment in which Rust applications will be built:

```powershell
Get-Command rustup, rustc, cargo, rust-analyzer, rustfmt
```

The standard Rustup binary directory on Windows is:

```text
%USERPROFILE%\.cargo\bin
```

If Rust commands are missing, inspect the active toolchain and process PATH:

```powershell
rustup show
$env:Path -split ';'
```

Add the Cargo binary directory to the user `PATH` if it is missing, then open a new terminal.

### 9.2 Verify MSVC executable discovery

Check compiler and linker discovery:

```powershell
Get-Command cl.exe -ErrorAction SilentlyContinue
Get-Command link.exe -ErrorAction SilentlyContinue

where.exe cl.exe
where.exe link.exe
```

If the files exist on disk but command discovery fails:

1. Confirm the Visual Studio installation path with `vswhere.exe`.
2. Check the Visual C++ workload and individual MSVC components in Visual Studio Installer.
3. Launch the developer shell using `Launch-VsDevShell.ps1`.
4. Repeat the command-discovery checks.
5. Investigate developer-shell initialization and required Visual Studio components if the issue remains.

Do not conclude that the compiler or linker is absent solely because `Get-Command` cannot find it.

Conversely, do not claim that the shell is configured merely because the files exist on disk.

## 10. Troubleshooting

### 10.1 `cl.exe` or `link.exe` is not found

First distinguish between a missing executable and an executable that is not available through the current shell's `PATH`.

Check the MSVC installation directory:

```powershell
$vsPath = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools'
$msvcPath = Join-Path $vsPath 'VC\Tools\MSVC'

Get-ChildItem "$msvcPath\*\bin\Hostx64\x64\cl.exe"
Get-ChildItem "$msvcPath\*\bin\Hostx64\x64\link.exe"
```

Then check command discovery:

```powershell
Get-Command cl.exe -ErrorAction SilentlyContinue
Get-Command link.exe -ErrorAction SilentlyContinue

where.exe cl.exe
where.exe link.exe
```

If the files exist but command discovery fails:

1. Confirm the Visual Studio installation path.
2. Check the Visual C++ workload and MSVC components.
3. Launch the Visual Studio developer shell.
4. Repeat the command-discovery checks.
5. Investigate the developer-shell initialization if the problem remains.

Do not add hardcoded Visual Studio paths to application or editor configuration.

### 10.2 Rust commands are not recognized

Cause: Rust's binary directory is not available through `PATH`.

Check:

```powershell
rustup show
Get-Command rustup, rustc, cargo
```

The standard Rustup binary directory on Windows is:

```text
%USERPROFILE%\.cargo\bin
```

Add it to the user `PATH` if it is missing, then restart the terminal.

### 10.3 `rust-analyzer` is unavailable

Check whether the component is installed:

```powershell
rustup component list --installed
```

Install it if necessary:

```powershell
rustup component add rust-analyzer
```

Confirm executable discovery:

```powershell
Get-Command rust-analyzer
```

### 10.4 Cargo builds but a native dependency fails

A simple Rust application may build without exercising every native dependency or build script.

If a dependency requires MSVC directly:

1. Confirm that `cl.exe` and `link.exe` exist.
2. Confirm that the Windows SDK headers and libraries are installed.
3. Verify that the shell launching Cargo has the required Visual Studio environment.
4. Re-run the failing Cargo command and inspect the first native-toolchain error.

Do not treat a successful `hello` project as proof that every native dependency is configured.

## 11. Updating the toolchain

Update Rust and its installed toolchain components:

```powershell
rustup update
```

Alternatively, use the repository's Windows installer:

```powershell
pwsh -NoProfile -File .\scripts\core\windows\rust.ps1 -Update
```

Update Visual Studio Build Tools and the Windows SDK separately through Visual Studio Installer.

These are independent update mechanisms. Updating Rust does not update the MSVC compiler or Windows SDK.

## 12. Installation checklist

Use this checklist to track the Windows Rust installation and verification state.

### Rust toolchain

- [x] Install Rustup.
- [x] Verify the active `stable-x86_64-pc-windows-msvc` toolchain.
- [x] Verify `rustc` and Cargo.
- [x] Install and verify `rust-analyzer`.
- [x] Install and verify `rustfmt`.
- [x] Install and verify `rust-src`.
- [x] Install and verify Clippy.
- [x] Install and verify Rust documentation.
- [x] Run `cargo build` successfully.
- [x] Run `cargo test` successfully.
- [x] Run `cargo run` successfully.
- [x] Verify a clean Cargo rebuild.

### Windows native build environment

- [x] Locate the Visual Studio Build Tools installation.
- [x] Locate MSVC compiler and linker executables on disk.
- [x] Verify the Windows SDK installation.
- [ ] Confirm Visual C++ workload registration through `vswhere`.
- [ ] Resolve direct `cl.exe` and `link.exe` discovery in the intended developer shell.

### Repository installer

- [x] Verify `scripts/core/windows/rust.ps1 -Check`.
- [x] Verify `scripts/core/windows/rust.ps1 -Update`.
- [x] Confirm that existing Rust components are skipped during update.
- [x] Confirm that post-update tool and component checks pass.
- [x] Confirm successful check-mode exit code `0`.

**Installation status:** Rustup, the stable MSVC-targeted Rust toolchain, required Rust components, and the Windows SDK are installed and verified. The repository's Rust installer has passed both check and update execution. The remaining items concern Visual Studio workload confirmation and direct compiler/linker discovery through the developer shell.

## References

- [Rustup: Windows MSVC prerequisites](https://rust-lang.github.io/rustup/installation/windows-msvc.html)
- [Rustup: Installation](https://rustup.rs/)
- [Rustup: Components](https://rust-lang.github.io/rustup/concepts/components.html)
- [Microsoft: Visual Studio Build Tools workload and component IDs](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools)
- [Microsoft: Install MSVC](https://learn.microsoft.com/en-us/cpp/build/vscpp-step-0-installation)
- [rust-analyzer: Installation](https://rust-analyzer.github.io/book/installation.html)

---

**Scope:** This document covers Rust installation and Windows toolchain management only. It does not document Neovim language-server configuration, editor keymaps, formatting integration, Tree-sitter, or language-pack activation. Those implementation details belong in the separate `rust-support.md` document.
