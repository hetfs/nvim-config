# Configuring `tar` for Neovim on Windows

This guide explains how to verify `tar`, make it available through `PATH`, and validate its integration with Neovim and `nvim-treesitter`.

The goal is to resolve a missing `tar` dependency without changing unrelated Neovim configuration or installing unnecessary tools.

## 1. Check whether `tar` is installed

Modern Windows installations commonly include `tar.exe`, based on the `bsdtar` implementation from libarchive. A common location is:

```text
C:\Windows\System32\tar.exe
```

Verify that the executable exists and that PowerShell can discover it:

```powershell
$tarPath = Join-Path $env:WINDIR 'System32\tar.exe'

Test-Path $tarPath
Get-Command tar -ErrorAction SilentlyContinue
```

If `Test-Path` returns `True`, test the executable directly:

```powershell
& $tarPath --version
```

To test archive listing, use an existing archive:

```powershell
tar -tf .\archive.tar.gz
```

Replace the example filename with the path to a real archive. A successful listing confirms that `tar` can read that archive. This test is not required to verify executable availability.

If `tar.exe` exists but PowerShell cannot find `tar`, continue to Section 2.

If it does not exist at the expected location, check whether another usable copy is installed before proceeding to Section 3.

Reference: [Tar on Windows — Microsoft Learn](https://learn.microsoft.com/en-us/windows/tar/).

## 2. Make `tar` available through `PATH`

Neovim inherits its environment from the process that launches it. If the directory containing `tar.exe` is missing from Neovim's inherited `PATH`, Neovim may report that `tar` is unavailable even when the executable exists.

### Option A: Temporarily update `PATH`

Use this method first. It changes only the current PowerShell session.

```powershell
$tarDir = Join-Path $env:WINDIR 'System32'
$tarPath = Join-Path $tarDir 'tar.exe'

if (-not (Test-Path $tarPath)) {
    throw "tar.exe was not found at $tarPath"
}

if (-not (($env:PATH -split ';') -contains $tarDir)) {
    $env:PATH = "$tarDir;$env:PATH"
}

Get-Command tar -ErrorAction Stop
tar --version
```

If both commands succeed, launch Neovim from this same PowerShell session:

```powershell
Set-Location 'C:\Users\Administrator\Desktop\nvim-config'
nvim
```

Replace the repository path if your local checkout is elsewhere.

Then verify executable lookup inside Neovim using Section 4.

**If this works, do not make a permanent environment change unless you need one.**

### Option B: Add the directory to your user `PATH` permanently

Use this option only if the executable exists and the temporary test confirms that the directory needs to be added.

First, inspect the existing user `PATH`:

```powershell
[Environment]::GetEnvironmentVariable('Path', 'User')
```

If the directory is absent, add it through Windows environment settings:

1. Press `Win + R`.
2. Enter `rundll32 sysdm.cpl,EditEnvironmentVariables`.
3. Under **User variables**, select `Path`, then choose **Edit**.
4. Choose **New** and enter the actual directory containing `tar.exe`.
5. Confirm the dialogs.
6. Open a new terminal and restart Neovim.

For the standard Windows location, the directory is:

```text
C:\Windows\System32
```

Do not add a directory merely because it is conventional. Verify that it contains the executable.

**Important:** Adding a directory to `PATH` does not install a missing executable. If `tar.exe` is absent, continue to Section 3.

## 3. Install `tar` only if it is missing

If no usable `tar.exe` exists on the system, choose a trusted package or archive utility that provides a compatible command-line `tar` executable.

You can inspect packages available through Windows Package Manager:

```powershell
winget search tar
```

Review the package name, publisher, and installation details before installing anything. You can also consult the documentation for a package manager already installed on your system, such as Scoop or Chocolatey.

Do not assume that a search result is an appropriate package or that every package provides an executable named `tar.exe`.

After installation, open a new PowerShell session and verify:

```powershell
Get-Command tar -ErrorAction Stop
tar --version
```

If PowerShell still cannot find the executable, locate its actual installation directory and follow Section 2.

## 4. Verify `tar` from inside Neovim

Launch Neovim from the PowerShell session in which `tar` works.

Run:

```vim
:echo executable('tar')
```

Interpret the result:

- `1` — Neovim can resolve an executable named `tar`.
- `0` — Neovim cannot resolve `tar` through its current executable lookup.

To inspect the resolved executable path:

```vim
:lua print(vim.fn.exepath("tar"))
```

An empty result means Neovim did not resolve the executable.

If PowerShell can find `tar` but Neovim cannot, check that Neovim was launched from the updated terminal rather than an older terminal, shortcut, or GUI process with a different inherited environment.

Do not proceed to parser troubleshooting until executable lookup succeeds.

## 5. Validate `nvim-treesitter`

The current `nvim-treesitter` setup has prerequisites beyond `tar`. These include a compatible Neovim version, download and extraction tools, the Tree-sitter CLI, and a compatible C compiler.

Check the plugin's health report:

```vim
:checkhealth nvim-treesitter
```

Check executable discovery individually:

```vim
:echo executable('tar')
:echo executable('curl')
:echo executable('tree-sitter')
:lua print(vim.fn.exepath("gcc"))
```

A result of `1` confirms that Neovim can resolve the named executable. It does not prove that downloads, extraction, or parser compilation will succeed.

### Windows `tar` discovery in Stage 08

The Stage 08 module includes a Windows-only fallback for the built-in Windows `tar.exe`. It runs only when Neovim cannot already resolve `tar`:

```lua
-- On Windows, expose the built-in tar when it is missing from PATH.
if vim.fn.has("win32") == 1 and vim.fn.executable("tar") == 0 then
  local windir = vim.env.WINDIR

  if windir and windir ~= "" then
    local tar = vim.fs.joinpath(windir, "System32", "tar.exe")

    if vim.fn.executable(tar) == 1 then
      local dir = vim.fs.dirname(tar)
      vim.env.PATH = dir .. ";" .. (vim.env.PATH or "")
    end
  end
end
```

This resolves the Windows directory through `%WINDIR%` instead of hardcoding a particular installation path. If the executable exists at that location, the code prepends its directory to Neovim's process-level `PATH`.

It does not permanently change the Windows user or system `PATH`, install `tar`, or search arbitrary directories.

After restarting Neovim, verify the result:

```vim
:lua print("tar=" .. vim.fn.exepath("tar"))
:lua print("tar available=" .. vim.fn.executable("tar"))
```

Expected results:

- A non-empty executable path.
- `tar available=1`.

If `tar` is installed elsewhere and is not already on `PATH`, this fallback will not discover that copy. Add its actual directory to `PATH` instead.

### Windows compiler selection

Parser compilation is a separate concern from `tar`.

On Windows, a build may fail with an error such as `cl.exe` not found if the build process selects the Microsoft compiler but the required compiler environment is unavailable. Having GCC installed does not, by itself, guarantee that the build will select it.

For this configuration, MinGW GCC was verified at the following executable location:

```text
C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin\gcc.exe
```

The Stage 08 Tree-sitter module sets `vim.env.CC` to the discovered `gcc` path on Windows when `CC` is not already configured. This allows the parser build to use GCC without requiring a separate manual command every time Neovim starts.

After restarting Neovim, verify compiler selection:

```vim
:lua print("CC=" .. tostring(vim.env.CC))
```

The value should identify the GCC executable. If it is `nil` or points to an unexpected compiler, investigate compiler configuration separately.

### Install and verify the Python parser

Once the prerequisites pass, install the Python parser explicitly:

```vim
:lua print(vim.inspect(require("nvim-treesitter").install({"python"}):wait(300000)))
```

This waits up to five minutes and prints the returned result. A result of `true` indicates that the installation completed successfully. Inspect any preceding messages for download, extraction, or compilation errors.

To force a fresh installation when troubleshooting an existing parser:

```vim
:lua print(vim.inspect(require("nvim-treesitter").install({"python"}, {force = true}):wait(300000)))
```

Use the forced installation only when a fresh rebuild is needed.

Verify that the parser file exists:

```vim
:lua print(vim.fn.glob(vim.fn.stdpath("data") .. "/site/parser/*python*"))
```

For this configuration, the expected result includes:

```text
C:\Users\Administrator\AppData\Local\nvim-data\site\parser\python.so
```

The parser's presence confirms that a parser file was installed. To verify that Neovim can load the grammar, run:

```vim
:lua print(vim.inspect(vim.treesitter.language.inspect("python")))
```

Finally, open a Python file and verify that the Tree-sitter highlighter is active for the current buffer:

```vim
:lua print("highlighter active=" .. tostring(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil))
```

The expected result is:

```text
highlighter active=true
```

This check assumes the buffer's file type is `python` and the Stage 08 `FileType` autocmd is configured to call `vim.treesitter.start(event.buf)` for Python files.

For the plugin's supported setup and installation API, consult the [official nvim-treesitter README](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md).

## 6. Troubleshooting checklist

| Symptom | Likely cause | Next action |
| --- | --- | --- |
| `tar.exe` does not exist at the expected location | The executable is absent from that location. | Check for another usable copy or install a trusted package. |
| PowerShell cannot find `tar` | The executable is missing or its directory is absent from `PATH`. | Check `Test-Path`, then inspect `Get-Command tar`. |
| `:echo executable('tar')` returns `0` | Neovim cannot resolve `tar`. | Relaunch Neovim from the corrected terminal and inspect `vim.fn.exepath("tar")`. |
| `:checkhealth nvim-treesitter` reports `tar` missing | The plugin cannot resolve the executable. | Fix executable lookup before retrying parser installation. |
| Download or extraction fails | A download, network, or archive extraction problem may exist. | Inspect the actual error and verify `curl` and `tar`. |
| Compilation fails with `cl.exe` not found | The build selected MSVC, but its compiler environment is unavailable. | Verify compiler selection and configure a compatible toolchain. |
| Compilation fails despite GCC being installed | The build may be selecting a different compiler, or the toolchain may be incompatible. | Inspect `CC`, `vim.fn.exepath("gcc")`, and the actual build error. |
| `tar` remains unavailable after the Stage 08 fallback | The built-in executable is absent, or `WINDIR` or the expected path is unavailable. | Check `%WINDIR%\System32\tar.exe` and configure the actual directory if needed. |
| The parser file is missing | Parser installation may not have completed. | Inspect installation output and rerun installation after fixing the reported failure. |
| The parser exists but highlighting is inactive | The grammar may not be loaded, the file type may be wrong, or the autocmd may not be active. | Inspect the grammar, file type, autocmd, and highlighter state. |
| A permanent `PATH` change appears ineffective | The running process inherited an older environment. | Open a new terminal and restart Neovim. |

For additional diagnostics, consult the plugin's health report and its documented logging commands, including `:TSLog` where available.

## Summary

1. Verify that `tar.exe` exists and runs.
2. If needed, make its containing directory available through `PATH`, testing a temporary change first.
3. The Stage 08 fallback checks `%WINDIR%\System32\tar.exe` when Neovim cannot resolve `tar`. It only adjusts Neovim's process-level `PATH`.
4. Install a trusted command-line archive utility only if no usable copy exists.
5. Confirm that `:echo executable('tar')` returns `1` and `vim.fn.exepath("tar")` returns a path.
6. Run `:checkhealth nvim-treesitter` and resolve any remaining prerequisites.
7. Verify compiler selection separately from `tar` availability.
8. Install the parser and verify that it persists and highlighting is active.

Keep executable lookup, archive extraction, compiler configuration, parser installation, and highlighting validation as separate troubleshooting steps. Fixing one prerequisite does not guarantee that the others are configured correctly.
