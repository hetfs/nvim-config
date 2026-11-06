# Shell Support

Shell support provides language-server integration, diagnostics, formatting, and script execution for Bash and POSIX shell files.

The implementation follows the project's native-first architecture. Neovim manages LSP activation through its native API, while external tools are installed and maintained outside Neovim.

## Supported file types

| Language | File extensions | Filetypes |
| --- | --- | --- |
| POSIX shell | `.sh` | `sh` |
| Bash | `.sh`, `.bash` | `sh`, `bash` |

Filetype detection determines which language tools and formatters are available.

## Tooling

| Component | Tool | Purpose |
| --- | --- | --- |
| Shell runtime | Bash | Execute shell scripts |
| Language server | Bash Language Server (`bashls`) | Language intelligence and ShellCheck diagnostics |
| Static analysis | ShellCheck | Detect shell scripting issues |
| Formatter | shfmt | Format shell scripts |
| LSP client | Native Neovim LSP | Manage language-server communication |
| Formatting integration | Conform.nvim | Run shfmt through the formatting resolver |

### Language server

The Bash Language Server provides:

- Diagnostics and code analysis.
- Document symbols and language intelligence.
- ShellCheck integration.
- LSP-based editor features supported by the server.

The server is defined through `nvim-lspconfig` and activated with Neovim's native LSP API.

ShellCheck is configured as the diagnostic engine:

```lua
settings = {
  bashIde = {
    shellcheckPath = "shellcheck",
  },
},
```

### Formatting

`shfmt` handles formatting for both supported filetypes:

```lua
formatters = {
  sh = { "shfmt" },
  bash = { "shfmt" },
},
```

Formatting preferences remain outside the language pack. Use `.editorconfig` to define project-level formatting rules.

The formatter receives the filename so it can discover applicable `.editorconfig` settings.

Formatting is explicit through the project's formatting command. Shell support does not independently enable format-on-save.

## Language pack

Entry point:

```text
lua/langs/shell.lua
```

The language pack declares filetypes, LSP configuration, formatter mappings, and external dependencies.

```lua
return {
  name = "shell",

  filetypes = {
    "sh",
    "bash",
  },

  lsp = {
    bashls = {
      cmd = {
        "bash-language-server",
        "start",
      },

      filetypes = {
        "sh",
        "bash",
      },

      settings = {
        bashIde = {
          shellcheckPath = "shellcheck",
        },
      },
    },
  },

  formatters = {
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  tools = {
    "bash",
    "bash-language-server",
    "shellcheck",
    "shfmt",
  },
}
```

## Script execution

The shell plugin provides a buffer-local mapping for running the current shell script:

| Mapping | Description |
| --- | --- |
| `<leader>cr` | Run shell script |

The mapping is registered by the shell plugin setup function:

```lua
require("plugins.shell").setup()
```

The plugin checks whether the shell language pack is enabled before registering its functionality.

### Mapping behavior

The mapping is registered for supported Shell buffers through a `FileType` autocmd.

Its intended execution workflow is:

1. Verify that the current buffer is valid.
2. Check that the buffer has a filename.
3. Save the current buffer before execution.
4. Verify that Bash is available.
5. Open a terminal split at the bottom.
6. Execute the current script using Bash.
7. Report execution failures, including nonzero exit codes.

Bash must be available on `PATH` for script execution.

### Independent validation

The mapping has been tested independently of the complete Shell integration.

The following checks have passed:

- Mapping registration in Normal mode.
- Buffer-local mapping registration.
- Mapping description resolves to `Run shell script`.
- Callback is registered successfully.
- `<leader>cr` resolves to `<Space>cr`.
- A test Bash script executes successfully.
- The terminal displays the expected script output.

The successful execution test used:

```bash
#!/usr/bin/env bash

echo "Shell keymap test"
printf 'Bash version: %s\n' "$BASH_VERSION"
```

Expected output:

```text
Shell keymap test
Bash version: ...
```

Failure-condition testing remains in progress.

## External dependencies

External tools are managed outside Neovim. The language pack declares dependencies but does not install them.

### Required tools

| Tool | Executable | Purpose |
| --- | --- | --- |
| Bash | `bash` | Shell runtime |
| Bash Language Server | `bash-language-server` | LSP integration |
| ShellCheck | `shellcheck` | Static analysis |
| shfmt | `shfmt` | Formatting |

### Windows

On Windows, Git for Windows provides the Bash runtime.

Expected executable:

```text
C:\Program Files\Git\bin\bash.exe
```

Add the Git `bin` directory to the user `PATH`:

```powershell
$gitBin = "$env:ProgramFiles\Git\bin"

$userPath = [Environment]::GetEnvironmentVariable(
    "Path",
    "User"
)

if (($userPath -split ";") -notcontains $gitBin) {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$userPath;$gitBin",
        "User"
    )
}
```

Install the remaining dependencies using the external installer:

```powershell
.\scripts\install\core\bash-shell.ps1
```

The installer provisions missing dependencies and verifies the available executables. It does not install Neovim plugins or modify the Neovim configuration.

### Linux and macOS

Install the dependencies through the operating system's package manager or the project's external provisioning workflow.

The Bash Language Server requires Node.js and npm.

## Validation

Validate each dependency independently before testing the editor integration.

### 1. Check executables

Run:

```powershell
Get-Command bash -ErrorAction SilentlyContinue
Get-Command bash-language-server -ErrorAction SilentlyContinue
Get-Command shellcheck -ErrorAction SilentlyContinue
Get-Command shfmt -ErrorAction SilentlyContinue
```

### 2. Check Bash

```powershell
bash --version
```

### 3. Check the language server

```powershell
bash-language-server --version
```

### 4. Check ShellCheck

```powershell
shellcheck --version
```

### 5. Check shfmt

```powershell
shfmt --version
```

### 6. Validate Neovim integration

Open a Bash or shell file and check the following:

```vim
:checkhealth vim.lsp
```

Verify that the language server is enabled:

```vim
:lua print(vim.lsp.is_enabled("bashls"))
```

Verify that it is attached to the current buffer:

```vim
:lua print(vim.lsp.get_clients({ bufnr = 0, name = "bashls" })[1] ~= nil)
```

Check the formatter:

```vim
:ConformInfo
```

The current buffer should report `shfmt` as ready.

### 7. Validate diagnostics

Create a temporary Bash file:

```bash
#!/usr/bin/env bash

echo $1
```

ShellCheck should report `SC2086` because the variable is not quoted.

Confirm that the diagnostic appears in Neovim and identifies ShellCheck as its source.

Correct the script:

```bash
#!/usr/bin/env bash

echo "$1"
```

The `SC2086` diagnostic should disappear.

### 8. Validate formatting

Create a shell script with intentionally inconsistent formatting and run:

```vim
:Format
```

Confirm that shfmt formats the buffer successfully.

### 9. Validate script execution

Open a valid shell script and execute:

```text
<leader>cr
```

Confirm that:

- The current buffer is saved.
- A terminal split opens at the bottom.
- Bash executes the current script.
- The expected output appears in the terminal.

### 10. Validate mapping registration

Open a `.sh` file and confirm its filetype:

```vim
:set filetype?
```

Inspect the mapping:

```vim
:verbose nmap <leader>cr
```

Inspect its complete mapping metadata:

```vim
:lua vim.print(vim.fn.maparg("<leader>cr", "n", false, true))
```

Expected properties:

| Property | Expected value |
| --- | --- |
| Mode | `n` |
| Buffer | `1` |
| Description | `Run shell script` |
| Callback | Lua function |
| Non-recursive | `1` |

The mapping must be buffer-local and must not appear in unrelated buffers.

### 11. Validate failure conditions

Test the following scenarios independently:

| Test | Expected behavior | Status |
| --- | --- | --- |
| Unsaved changes | Buffer is saved before execution | Pending |
| Unnamed buffer | Warning asks the user to save the script | Pending |
| Bash unavailable | Warning reports that Bash is unavailable | Pending |
| Script exits with code 1 | Warning reports the nonzero exit code | Pending |
| Non-Shell buffer | Mapping is not registered | Pending |

## Design decisions

- Use the Bash Language Server for shell language intelligence.
- Use ShellCheck for static analysis.
- Use shfmt for formatting.
- Use Neovim's native LSP API for server activation.
- Use Conform.nvim for formatter integration.
- Keep external dependency installation outside Neovim.
- Keep formatting preferences in project configuration rather than language-pack defaults.
- Do not install or manage external tools through Mason.
- Keep format-on-save disabled unless explicitly enabled by the user.
- Register script execution as a buffer-local mapping.
- Keep script execution independent of LSP activation and formatting.

## Validation status

The following integration checks have passed in the Windows development environment:

| Validation | Status |
| --- | --- |
| Git for Windows Bash runtime | Passed |
| Bash available on `PATH` | Passed |
| Bash Language Server enabled | Passed |
| Bash Language Server attached to buffer | Passed |
| ShellCheck executable | Passed |
| ShellCheck diagnostics through LSP | Passed |
| `SC2086` diagnostic detection | Passed |
| Formatter registry resolution | Passed |
| Conform detects shfmt | Passed |
| Mapping registration | Passed |
| Buffer-local mapping verification | Passed |
| Mapping description and callback | Passed |
| Successful Bash script execution | Passed |
| Unsaved changes handling | Pending |
| Unnamed buffer handling | Pending |
| Missing Bash handling | Pending |
| Nonzero exit-code handling | Pending |
| Non-Shell buffer isolation | Pending |
| Actual shfmt formatting test | Pending |

The Shell pack is integrated with the language registry and editor tooling. Mapping registration and successful script execution have been independently verified.

The remaining work is to complete the script-execution failure-condition tests and validate actual formatting through Conform.nvim.
