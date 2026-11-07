# Rust installation guide for `nvim-config`

This guide documents the Windows MSVC toolchain setup required to develop and build Rust projects for the `nvim-config` Rust language pack.

Rust installation is deliberately separate from Neovim. Neovim configures Rust tooling, but it does not install the Rust compiler, linker, Windows SDK, or external utilities.

This guide records the verified Windows installation state as of 7 November 2026. It covers external prerequisites and toolchain verification only. The separate `rust-support.md` document defines the Stage 13 Neovim integration.

## 1. Installation requirements

The Rust setup uses the native Windows MSVC target:

| Component | Purpose | Verified state |
| --- | --- | --- |
| `rustup` | Rust toolchain manager | Installed |
| `rustc` | Rust compiler | Installed |
| `cargo` | Build and package manager | Installed |
| `rust-analyzer` | Language server executable | Installed |
| `rustfmt` | Rust formatter | Installed |
| `rust-src` | Rust standard-library source | Installed |
| `clippy` | Rust linter | Installed |
| `rust-docs` | Local Rust documentation | Installed |
| MSVC C++ Build Tools | Native compiler and linker | Executables found on disk |
| Windows SDK | Windows headers and libraries | Installed |

The active toolchain is `stable-x86_64-pc-windows-msvc`, with target `x86_64-pc-windows-msvc`.

Keep this target unless you deliberately decide to maintain a separate GNU-based Rust environment.

## 2. Install Visual Studio Build Tools

The MSVC toolchain requires Microsoft's C++ build tools. Installing Rust alone is not sufficient.

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

Then open Visual Studio Installer and select the C++ workload and required components. Installing the package alone does not guarantee that the complete workload is installed.

## 3. Verify Visual Studio Build Tools and the Windows SDK

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

A returned installation path confirms that `vswhere` found an installation containing that workload. No output means the workload was not confirmed by this query. It does not, by itself, prove that no MSVC files are installed.

Set the installation path returned by `vswhere` and inspect the MSVC toolset:

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

Check the standard Windows SDK location:

```powershell
$sdkPath = "${env:ProgramFiles(x86)}\Windows Kits\10"

Test-Path "$sdkPath\Include"
Test-Path "$sdkPath\Lib"
Test-Path "$sdkPath\bin"

Get-ChildItem "$sdkPath\Include" -Directory -ErrorAction SilentlyContinue
Get-ChildItem "$sdkPath\Lib" -Directory -ErrorAction SilentlyContinue
```

The SDK's `Include`, `Lib`, and `bin` directories should exist. The versioned `Include` and `Lib` directories identify the installed SDK version.

### Verified installation on this machine

The following results were observed:

| Item | Verified result |
| --- | --- |
| Visual Studio installation | `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools` |
| Visual Studio Build Tools version | Visual Studio 2026 Developer PowerShell reported `18.11.3` |
| MSVC toolset directories | `14.44.35207` and `14.51.36231` |
| `cl.exe` | Found under `14.44.35207\bin\Hostx64\x64` |
| `link.exe` | Found under `14.44.35207\bin\Hostx64\x64` |
| Windows SDK | `10.0.22621.0` |
| C++ workload query | No installation path returned by the `vswhere -requires` query |

The compiler and linker were found on disk with:

```powershell
$vsPath = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools'
$msvcPath = Join-Path $vsPath 'VC\Tools\MSVC'

Get-ChildItem "$msvcPath\*\bin\Hostx64\x64\cl.exe"
Get-ChildItem "$msvcPath\*\bin\Hostx64\x64\link.exe"
```

## 4. Verify the MSVC environment

Visual Studio provides a developer-shell initialization script. The following command was used to launch the Visual Studio 2026 Developer PowerShell environment:

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
```

Both commands reported that the executables were not recognized. `where.exe cl.exe` and `where.exe link.exe` also returned no matches in the ordinary PowerShell session.

Record this as an environment-discovery issue. Do not report that `cl.exe` and `link.exe` are available through the current PowerShell `PATH` merely because their files exist on disk.

The successful clean Cargo build documented in Section 6 confirms that the tested Rust project can build. It does not establish that arbitrary native build scripts or other tools can discover MSVC executables through the current shell environment.

If a future dependency requires direct MSVC executable discovery, investigate the Visual Studio environment setup and workload/component selection. Do not add hardcoded Visual Studio paths to the Neovim configuration.

## 5. Verify and install Rust components

The active toolchain and host can be checked with:

```powershell
rustup show
rustc --version
cargo --version
rustc -vV
```

Confirm that the host is:

```text
x86_64-pc-windows-msvc
```

Install the components used by the Neovim Rust integration:

```powershell
rustup component add rust-analyzer rustfmt rust-src
```

Install Clippy if it is not already installed and the project will use it:

```powershell
rustup component add clippy
```

The corresponding `nvim-config` setting controls whether the Rust pack uses Clippy:

```lua
tools = {
  rust_clippy = false,
},
```

Set `rust_clippy = true` only when Clippy is installed and the Rust pack is configured to use it. Component installation and pack activation are separate decisions.

Check the installed components:

```powershell
rustup component list --installed
```

### Verified installed components

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

References: [Rustup components](https://rust-lang.github.io/rustup/concepts/components.html) · [rust-analyzer installation](https://rust-analyzer.github.io/book/installation.html).

## 6. Test a Rust project

Before configuring Rust support in Neovim, verify that Cargo can create, compile, test, and execute a Rust project.

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

### Verified test results

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

This confirms that the tested Rust project can build and run with the installed MSVC-targeted Rust toolchain. It does not prove that `cl.exe` and `link.exe` are discoverable by every process through the current PowerShell `PATH`.

## 7. Verify the intended Neovim launch environment

Neovim must be able to discover the Rust tools it uses. Check the Rust executables in the same shell from which Neovim will be launched:

```powershell
Get-Command rustc, cargo, rust-analyzer, rustfmt
```

The standard rustup binary directory on Windows is:

```text
%USERPROFILE%\.cargo\bin
```

If Rust commands are missing, check:

```powershell
rustup show
$env:Path -split ';'
```

Add the Cargo binary directory to the user `PATH` if it is missing, then open a new terminal.

The Rust language server and formatter should be available to Neovim through `PATH`. Cargo should also be available for project workflows.

The current machine has a separate MSVC executable-discovery issue: `cl.exe` and `link.exe` exist on disk, but `Get-Command` and `where.exe` did not resolve them, even after the Visual Studio developer-shell script displayed its startup banner. The clean Cargo test project nevertheless built successfully. Keep these facts distinct when diagnosing native dependencies.

Do not add hardcoded Visual Studio installation paths to the Neovim configuration. System toolchain installation and environment initialization remain outside Neovim's ownership.

## 8. Rust support in `nvim-config`

Once the Rust tools are available in the intended Neovim launch environment and the Cargo workflow has been tested, configure the Rust language pack.

The intended responsibilities are:

| Area | Implementation |
| --- | --- |
| Language server | `rust-analyzer` |
| Formatting | `rustfmt` through Conform |
| Syntax parsing | Tree-sitter `rust` parser |
| Build and tests | Native Cargo commands |
| Linting | Optional Clippy |
| Source navigation | Neovim LSP |
| Formatting on save | Disabled by default |

The configuration should use Neovim's native LSP API:

```lua
vim.lsp.config("rust_analyzer", {
  -- Rust Analyzer settings
})

vim.lsp.enable("rust_analyzer")
```

The server definition is supplied by `nvim-lspconfig`. Neovim's native API remains responsible for configuring and enabling it. Do not use the legacy `require("lspconfig")` setup interface.

Formatting should use the existing Conform integration. Keep manual formatting available through `:Format`; do not enable format-on-save by default.

Cargo commands should remain available through the native terminal workflow. No additional Rust-specific plugin is required for the initial language pack.

This installation guide does not activate the Rust pack or define its implementation details. Those belong to `rust-support.md` and the Stage 13 integration work.

## 9. Troubleshooting

### `link.exe` or `cl.exe` is not found

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

1. Confirm the Visual Studio installation path with `vswhere.exe`.
2. Check the Visual C++ workload and individual MSVC components in Visual Studio Installer.
3. Launch the developer shell using `Launch-VsDevShell.ps1`.
4. Repeat the command-discovery checks.
5. If the issue remains, investigate the developer-shell initialization and required Visual Studio components.

Do not conclude that the compiler or linker is absent solely because `Get-Command` cannot find it. Conversely, do not claim that the shell is configured merely because the files exist on disk.

### Rust commands are not recognized

Cause: Rust's binary directory is not available through `PATH`.

Check:

```powershell
rustup show
Get-Command rustup, rustc, cargo
```

The standard rustup binary directory on Windows is:

```text
%USERPROFILE%\.cargo\bin
```

Add it to the user `PATH` if it is missing, then restart the terminal.

### `rust-analyzer` is unavailable

Check whether the component is installed:

```powershell
rustup component list --installed
```

Install it if necessary:

```powershell
rustup component add rust-analyzer
```

Also confirm that the executable is discoverable:

```powershell
Get-Command rust-analyzer
```

### Cargo builds but a native dependency fails

A simple Rust application may build without exercising every native dependency or build script.

If a dependency requires MSVC directly:

1. Confirm that `cl.exe` and `link.exe` exist.
2. Confirm that the Windows SDK headers and libraries are installed.
3. Verify that the shell launching Cargo has the required Visual Studio environment.
4. Re-run the failing Cargo command and inspect the first native-toolchain error.

Do not treat a successful `hello` project as proof that every native dependency is configured.

## 10. Updating the toolchain

Update Rust and its installed toolchain components:

```powershell
rustup update
```

Update Visual Studio Build Tools and the Windows SDK separately through Visual Studio Installer.

These are independent update mechanisms. Updating Rust does not update the MSVC compiler or Windows SDK.

## 11. Installation checklist

Use this checklist before marking the Rust system prerequisites complete.

- [x] Install Visual Studio Build Tools.
- [x] Locate MSVC compiler and linker executables on disk.
- [x] Install a Windows SDK.
- [x] Verify the active Rust MSVC target.
- [x] Install `rust-analyzer`, `rustfmt`, and `rust-src`.
- [x] Install Clippy.
- [x] Run `cargo build` successfully.
- [x] Run `cargo test` successfully.
- [x] Run `cargo run` successfully.
- [ ] Resolve direct `cl.exe` and `link.exe` discovery in the Visual Studio developer shell.
- [ ] Verify the complete tool environment from the intended Neovim launch shell.

The Cargo workflow is verified. The two remaining items track environment discovery and Neovim launch-environment verification; they do not invalidate the successful clean Cargo test project.

## References

- [Rustup: Windows MSVC prerequisites](https://rust-lang.github.io/rustup/installation/windows-msvc.html)
- [Microsoft: Visual Studio Build Tools workload and component IDs](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools)
- [Microsoft: Install MSVC](https://learn.microsoft.com/en-us/cpp/build/vscpp-step-0-installation)
- [Rustup: Installation](https://rustup.rs/)
- [Rustup: Components](https://rust-lang.github.io/rustup/concepts/components.html)
- [rust-analyzer: Installation](https://rust-analyzer.github.io/book/installation.html)

---

**Project boundary:** This guide covers external Windows prerequisites and Rust toolchain verification. It does not install or configure Neovim plugins, modify the language registry, or activate the Rust pack. Those responsibilities belong to the Stage 13 Rust integration work documented separately in `rust-support.md` and `rust-win-install.md`.
