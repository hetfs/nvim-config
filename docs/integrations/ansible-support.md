# Ansible Support

## 1. Purpose

This document defines the Ansible infrastructure-automation support baseline for Stage 13 (Language Packs) of the Neovim configuration project.

The objective is to provide a consistent development environment for writing, editing, validating, navigating, and maintaining Ansible automation content.

Ansible support will remain separate from the programming-language packs while reusing the project's shared Language Server Protocol (LSP), Treesitter, and formatting infrastructure.

The integration will provide:

- Ansible-aware language intelligence through Neovim's native LSP client.
- YAML syntax highlighting and Ansible-specific filetype detection.
- Static analysis through `ansible-lint`.
- Playbook syntax validation through Ansible Core.
- Jinja2-aware editing support where supported by the language server.
- Explicit Windows and WSL2 interoperability.
- Manual formatting through the shared formatting infrastructure.

The implementation must follow the project's established principles:

- Native-first Neovim configuration.
- Explicit module loading.
- `vim.pack` for plugin management.
- No Mason-based installation.
- No silent installation of external dependencies.
- No duplicate YAML infrastructure.
- No automatic format-on-save by default.

## 2. Support Classification

Ansible is classified as **infrastructure automation support**, not a programming-language pack.

Its implementation will reuse the existing language infrastructure without introducing another language-management framework.

| Area | Decision |
|---|---|
| Support category | Infrastructure automation |
| Implementation module | `lua/langs/ansible.lua` |
| Language server | Ansible Language Server (`ansiblels`) |
| LSP client | Neovim native LSP |
| Configuration API | `vim.lsp.config()` and `vim.lsp.enable()` |
| Primary file format | YAML |
| Treesitter parser | Existing YAML parser |
| Static analysis | `ansible-lint` |
| Runtime | Ansible Core |
| Formatting | Shared Conform infrastructure |
| Template language | Jinja2 |
| Windows execution | WSL2 preferred |
| Installation | Explicit external installation |

**Approval status:** Proposed baseline. `ansiblels` remains the preferred language-server candidate. Formal approval is conditional on successful installation, language-server validation, and Windows/WSL2 interoperability testing.

## 3. Proposed Tooling

The integration will use the following tools:

| Component | Tool | Responsibility |
|---|---|---|
| Language server | Ansible Language Server | Ansible language intelligence |
| LSP client | Neovim native LSP | Language-server communication |
| Syntax highlighting | Treesitter YAML | YAML syntax highlighting |
| Static analysis | `ansible-lint` | Ansible best-practice and correctness checks |
| Runtime | `ansible-core` | Playbook execution and syntax validation |
| Formatting | Conform | Shared formatting workflow |
| Template language | Jinja2 | Ansible template expressions |

The language server and runtime tools are external dependencies. They must be installed and maintained independently of Neovim.

### 3.1 Ansible Language Server

The preferred candidate is the Ansible Language Server maintained by the Ansible VS Code extension project.

Repository:

https://github.com/ansible/vscode-ansible

Documentation:

https://docs.ansible.com/projects/vscode-ansible/als/

The standalone npm package is:

```bash
npm install -g @ansible/ansible-language-server
```

The expected executable is:

```text
ansible-language-server
```

The expected startup command is:

```bash
ansible-language-server --stdio
```

The language server provides Ansible-aware completion, validation, hover documentation, module navigation, and Jinja expression support in supported Ansible YAML documents.

Its installation requirements, runtime dependencies, executable discovery, and compatibility with the development environment must be verified before approval.

### 3.2 Ansible Core

Ansible Core provides the command-line runtime used to validate and execute playbooks.

The primary commands are:

```bash
ansible --version
ansible-playbook --version
ansible-playbook --syntax-check playbook.yml
```

Ansible Core must be installed in an explicitly managed Python environment.

The Neovim configuration must not create Python environments or install Ansible automatically.

### 3.3 Ansible Lint

`ansible-lint` provides static analysis for Ansible projects.

The primary command is:

```bash
ansible-lint
```

The tool should run from the Ansible project root so that it can discover the relevant configuration and project context.

The integration must avoid duplicate diagnostics if the language server also invokes `ansible-lint`.

The `--fix` option must remain an explicit user action. It must never run automatically during normal editing or formatting.

Documentation:

https://docs.ansible.com/projects/lint/

## 4. Language Server Configuration

### 4.1 Server Selection

The proposed server identifier is:

```text
ansiblels
```

The configuration will use Neovim's native LSP API.

The existing `nvim-lspconfig` project provides the server definition. Its documented configuration includes the following defaults:

| Property | Value |
|---|---|
| Server name | `ansiblels` |
| Command | `ansible-language-server --stdio` |
| Filetype | `yaml.ansible` |
| Root markers | `ansible.cfg`, `.ansible-lint` |
| Validation | Enabled |
| Lint integration | Enabled |
| Execution environment | Disabled |

Reference:

https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.txt

These defaults must be checked against the installed `nvim-lspconfig` version before implementation. The project will retain its native LSP configuration approach rather than adopting the legacy `require("lspconfig")` setup API.

### 4.2 Proposed Configuration

The initial configuration candidate is:

```lua
vim.lsp.config("ansiblels", {
  cmd = {
    "ansible-language-server",
    "--stdio",
  },

  filetypes = {
    "yaml.ansible",
  },

  root_markers = {
    "ansible.cfg",
    ".ansible-lint",
  },

  settings = {
    ansible = {
      ansible = {
        path = "ansible",
      },

      executionEnvironment = {
        enabled = false,
      },

      python = {
        interpreterPath = "python",
      },

      validation = {
        enabled = true,

        lint = {
          enabled = true,
          path = "ansible-lint",
        },
      },
    },
  },
})

vim.lsp.enable("ansiblels")
```

This is a proposed native LSP configuration, not the final approved implementation.

The command, Python interpreter, and linter paths must be adjusted to match the validated execution environment.

For native Windows Neovim using WSL2-hosted tools, the command may need to invoke the language server through `wsl.exe`.

That configuration must not be adopted until the interoperability tests in Section 9 pass.

### 4.3 LSP Responsibilities

The language server should provide the following capabilities where supported:

- Ansible-aware completion.
- Module and module-option suggestions.
- Hover documentation.
- Go-to-definition for supported Ansible modules and symbols.
- Diagnostics and validation.
- Jinja expression support within supported Ansible YAML documents.
- Ansible-specific document intelligence.

The integration must not enable the server for every YAML buffer.

Ansible-specific activation must depend on reliable filetype detection.

## 5. Filetype Detection

Ansible uses YAML as its primary playbook and configuration format.

Common file extensions include:

```text
.yml
.yaml
```

These extensions are also used by ordinary YAML configuration files. File extensions alone cannot reliably identify Ansible content.

The integration must distinguish Ansible YAML from general YAML.

### 5.1 Ansible Filetype

The intended Ansible filetype is:

```text
yaml.ansible
```

This allows the Ansible language server to attach only to recognized Ansible buffers.

### 5.2 Detection Strategy

Detection should consider project structure, known Ansible directories, and recognized filenames.

Examples include:

```text
ansible.cfg
playbooks/
roles/
  example/
    tasks/
    handlers/
    defaults/
    vars/
    meta/
site.yml
playbook.yml
```

The implementation should support explicit filetype assignment for standalone Ansible files that cannot be identified through project structure.

It must not classify every YAML file inside an Ansible repository as Ansible content.

Examples of YAML files that should remain ordinary YAML unless explicitly identified otherwise include:

```text
.github/workflows/ci.yml
docker-compose.yml
config/application.yml
```

### 5.3 Root Detection

The initial root markers are:

```text
ansible.cfg
.ansible-lint
```

Additional project markers may be evaluated during implementation.

Root detection must not introduce a separate project-root framework or conflict with the existing Stage 12 `project.nvim` integration.

## 6. Treesitter Support

Ansible playbooks and configuration files are primarily YAML.

The integration will reuse the existing YAML Treesitter parser.

Required parser:

```text
yaml
```

The Ansible module must not install or configure a second YAML parser.

### 6.1 Parser Registration

If required by the filetype implementation, the existing YAML parser can be associated with the Ansible filetype:

```lua
vim.treesitter.language.register("yaml", {
  "yaml.ansible",
})
```

This registration must be validated against the project's installed Neovim and Treesitter versions.

The implementation must confirm that syntax highlighting, indentation-related queries, and existing YAML functionality continue to work.

### 6.2 Jinja2 Expressions

Ansible uses Jinja2 expressions inside YAML documents.

Example:

```yaml
- name: Create an application directory
  ansible.builtin.file:
    path: "{{ application_path }}"
    state: directory
```

The Ansible Language Server provides Jinja expression support in supported Ansible YAML documents.

Dedicated Jinja2 template-file support is outside the initial Ansible integration scope.

It can be evaluated separately if the project later introduces a dedicated template-language pack.

## 7. Static Analysis and Validation

### 7.1 Ansible Lint

`ansible-lint` is the preferred static-analysis tool.

It should detect:

- Ansible best-practice violations.
- Deprecated or problematic patterns.
- Incorrect module usage.
- YAML-related issues covered by its rules.
- Playbook and role structure problems.

The initial configuration should use the project's standard Ansible Lint behavior without introducing unnecessary custom rules.

Configuration may be provided through:

```text
.ansible-lint
```

or another configuration format supported by the installed Ansible Lint version.

Linting must execute from the project root.

### 7.2 Playbook Syntax Validation

Ansible Core provides playbook syntax validation:

```bash
ansible-playbook --syntax-check playbook.yml
```

This check validates playbook syntax without executing the playbook's tasks.

It should be available as an explicit project validation command.

### 7.3 Inventory Validation

Inventory parsing can be checked with:

```bash
ansible-inventory --list
```

The command must use the intended inventory and configuration context.

Inventory files may contain sensitive infrastructure information. Validation must not expose credentials or secrets in logs.

### 7.4 Diagnostic Ownership

The integration must avoid duplicate diagnostics.

The preferred responsibility split is:

| Tool | Responsibility |
|---|---|
| Ansible Language Server | Editor diagnostics and language intelligence |
| `ansible-lint` | Static analysis |
| Ansible Core | Runtime and syntax validation |
| Treesitter | Syntax highlighting and parsing |

If the language server invokes `ansible-lint`, a separate editor lint integration must not report the same findings again.

Standalone lint execution remains available through the project's external validation workflow.

## 8. Formatting

Ansible formatting will reuse the existing Conform infrastructure.

No independent formatting framework will be introduced.

The formatter selection must preserve valid YAML and avoid damaging Jinja2 expressions or Ansible-specific syntax.

Potential formatters must be evaluated against:

- Playbooks.
- Task files.
- Role files.
- Inventory files.
- Jinja2 expressions embedded in YAML.
- Multiline YAML values.

`ansible-lint --fix` is not the default formatter. It can apply automatic fixes and modify files beyond ordinary formatting.

Formatting must remain manual through the project's existing `:Format` workflow.

Format-on-save remains disabled by default.

A formatter will not be approved until it passes representative Ansible fixtures.

## 9. Windows and WSL2 Support

### 9.1 Platform Constraint

Ansible does not natively support Windows as a control node.

The official installation documentation identifies WSL as an environment through which Ansible can run on Windows.

Reference:

https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html

For this project, WSL2 is the preferred environment for:

- Ansible Core.
- `ansible-lint`.
- Python dependencies.
- Ansible execution and validation.

The WSL environment must be treated as an explicitly managed external development environment.

### 9.2 Proposed WSL2 Environment

The proposed tool arrangement is:

| Component | Environment |
|---|---|
| Neovim | Native Windows |
| Node.js | WSL2 |
| npm | WSL2 |
| Ansible Language Server | WSL2 |
| Python | WSL2 |
| Ansible Core | WSL2 |
| `ansible-lint` | WSL2 |

Ansible dependencies should be isolated in a dedicated Python virtual environment.

The language server should use the intended Ansible environment when it requires Ansible or Python tooling.

### 9.3 WSL2 Interoperability

Windows can launch Linux commands through `wsl.exe`.

Microsoft documentation:

https://learn.microsoft.com/en-us/windows/dev-environment/wsl-interop

This makes it possible to investigate launching the Ansible Language Server from native Windows Neovim.

However, successful command execution alone does not establish LSP compatibility.

The following areas must be validated:

1. Standard input and output forwarding.
2. Language-server process lifetime.
3. File URI conversion.
4. Workspace root resolution.
5. Windows and Linux path translation.
6. Diagnostics returned for Windows-hosted files.
7. Completion and hover requests.
8. Go-to-definition paths.
9. Python interpreter and `ansible-lint` discovery.
10. Behavior when the WSL distribution is stopped or unavailable.

### 9.4 Workspace Location

The workspace location is an important interoperability decision.

Two arrangements will be evaluated.

**Windows-hosted project**

```text
C:\Users\<user>\Projects\ansible-project
```

The WSL environment accesses the project through its mounted Windows filesystem, usually under `/mnt/c/`.

This arrangement preserves the existing Windows project workflow but requires testing path translation and performance.

**WSL-hosted project**

```text
/home/<user>/projects/ansible-project
```

The Windows editor accesses the project through the WSL filesystem.

This arrangement keeps Linux tools and project files in the same filesystem but requires validating how native Windows Neovim opens the files and how LSP file URIs are interpreted.

Neither arrangement is approved as the default until the interoperability tests pass.

### 9.5 Fallback Strategy

If native Windows Neovim cannot communicate reliably with the WSL-hosted language server, the preferred fallback is to run Neovim and the Ansible tooling inside the same WSL2 distribution.

The project must not introduce fragile path-conversion workarounds merely to preserve native Windows execution.

## 10. Installation Requirements

All dependencies must be installed explicitly.

The configuration must not install Node.js, Python, Ansible Core, Ansible Lint, or the language server automatically.

### 10.1 WSL2 Prerequisites

The environment must provide:

- A registered and functional WSL2 distribution.
- A supported Linux distribution.
- Python 3.
- Node.js and npm.
- A dedicated Python virtual environment.
- Access to the required project files.

Check WSL availability from PowerShell:

```powershell
wsl.exe --status
wsl.exe --list --quiet
```

Check the WSL development environment:

```bash
node --version
npm --version
python3 --version
```

### 10.2 Python Environment

Create a dedicated environment inside WSL2:

```bash
python3 -m venv ~/.venvs/ansible
source ~/.venvs/ansible/bin/activate
```

Install Ansible Core and Ansible Lint explicitly:

```bash
python -m pip install --upgrade pip
python -m pip install ansible-core ansible-lint
```

Verify the installations:

```bash
ansible --version
ansible-playbook --version
ansible-lint --version
```

The exact versions should be recorded in the project's external dependency documentation after validation.

The environment must remain isolated from the system-managed Python installation.

### 10.3 Language Server Installation

Install the language server in the WSL2 Node.js environment:

```bash
npm install -g @ansible/ansible-language-server
```

Verify executable discovery:

```bash
command -v ansible-language-server
ansible-language-server --help
```

The resolved executable path must be recorded for the Windows-to-WSL2 LSP test.

The installation must not be considered successful merely because npm reports that the package was installed. The executable must start with the documented stdio command and remain available for an LSP client.

## 11. Proposed File Organization

The initial integration should remain small and consistent with the existing language registry.

```text
lua/
  langs/
    init.lua
    ansible.lua

docs/
  languages/
    ansible-support.md
```

The Ansible module should contain only Ansible-specific metadata and setup.

It should not duplicate:

- Shared LSP infrastructure.
- YAML Treesitter configuration.
- Conform setup.
- External dependency installation.
- Project-root management.

The language registry should remain responsible for loading the module according to the existing architecture.

The implementation must preserve the project's explicit top-level module loading and existing language registry conventions.

## 12. Validation Requirements

The Ansible integration must pass the following validation stages before approval.

### 12.1 Installation Validation

- [ ] WSL2 distribution is available.
- [ ] Node.js and npm are available in WSL2.
- [ ] Python is available in WSL2.
- [ ] Ansible Core installs successfully.
- [ ] `ansible-lint` installs successfully.
- [ ] The Ansible Language Server installs successfully.
- [ ] The server executable resolves to the expected path.
- [ ] The server starts with the documented stdio command.
- [ ] The required Python environment is discoverable.
- [ ] All installed tool versions are recorded.

### 12.2 Native Windows Neovim Validation

- [ ] Windows Neovim can launch the WSL-hosted language server.
- [ ] Standard input and output are forwarded correctly.
- [ ] The server remains alive during an editing session.
- [ ] Ansible filetypes are detected correctly.
- [ ] Workspace roots are resolved correctly.
- [ ] File URIs and paths are handled correctly.
- [ ] Diagnostics are returned to the correct buffers.
- [ ] Completion works.
- [ ] Hover documentation works.
- [ ] Go-to-definition works.
- [ ] Python and `ansible-lint` paths resolve correctly.
- [ ] Server failure is reported clearly when WSL is unavailable.
- [ ] No orphaned language-server processes remain after Neovim exits.

### 12.3 Ansible Project Validation

Use a representative project:

```text
ansible-validation/
  ansible.cfg
  inventory/
    hosts.yml
  playbooks/
    site.yml
  roles/
    example/
      tasks/
        main.yml
      handlers/
        main.yml
      defaults/
        main.yml
```

Validate:

- [ ] Playbook syntax.
- [ ] Role task files.
- [ ] Handler files.
- [ ] Defaults and variables.
- [ ] Inventory parsing.
- [ ] Ansible module completion.
- [ ] Jinja expression handling.
- [ ] Ansible Lint diagnostics.
- [ ] Formatting without damaging Jinja expressions.

### 12.4 YAML Isolation Validation

Ansible support must not interfere with ordinary YAML files.

Test at least:

```text
.github/workflows/ci.yml
docker-compose.yml
config/application.yml
```

Expected behavior:

- [ ] Ordinary YAML files retain the normal YAML filetype.
- [ ] The Ansible language server does not attach to unrelated YAML files.
- [ ] Existing YAML Treesitter support remains unchanged.
- [ ] Existing YAML language support continues to work.
- [ ] Ansible-specific settings do not leak into ordinary YAML buffers.

### 12.5 Regression Validation

Run the existing project checks after integration:

- [ ] Configuration syntax checks.
- [ ] Language registry validation.
- [ ] LSP configuration checks.
- [ ] Treesitter parser checks.
- [ ] Existing smoke-test suites.
- [ ] Windows environment validation.
- [ ] Existing Lua and Python language-pack validation.
- [ ] Existing YAML language-support validation.
- [ ] Conform formatter regression checks.
- [ ] Startup and module-loading regression checks.

The Ansible integration must not introduce regressions in existing language packs or shared infrastructure.

## 13. Dependency Management

Ansible dependencies must follow the project's external dependency management policy.

The following tools are external dependencies:

| Dependency | Installation environment | Management |
|---|---|---|
| Node.js | WSL2 | Explicit external installation |
| npm | WSL2 | Bundled with or managed alongside Node.js |
| Ansible Language Server | WSL2 | npm |
| Python 3 | WSL2 | Explicit external installation |
| Ansible Core | WSL2 | Dedicated Python environment |
| `ansible-lint` | WSL2 | Dedicated Python environment |

The Neovim configuration must not:

- Install external dependencies automatically.
- Create or activate Python environments during startup.
- Modify the system PATH.
- Install Node.js or Python packages silently.
- Use Mason as a dependency manager.
- Assume that a Windows executable is available inside WSL2 or vice versa.

Dependency installation and verification must remain separate from Neovim startup.

## 14. Implementation Boundaries

The initial Ansible integration will remain focused on core infrastructure-automation editing and validation.

The following capabilities are included:

- Ansible YAML filetype detection.
- Ansible Language Server integration.
- YAML Treesitter reuse.
- Ansible Lint integration.
- Ansible Core syntax validation.
- Manual formatting through Conform.
- Windows/WSL2 interoperability.

The following capabilities are outside the initial implementation scope:

- Automatic playbook execution.
- Automatic infrastructure deployment.
- Automatic dependency installation.
- Automatic format-on-save.
- Automatic `ansible-lint --fix`.
- Ansible execution-environment management.
- Dedicated Jinja2 template-language support.
- Ansible-specific project-root management.
- Inventory and secret-management frameworks.
- Automatic credential discovery.

These capabilities may be evaluated independently if future requirements justify them.

## 15. Approval Criteria

Ansible support will move from proposed to approved status only after the following requirements are satisfied:

1. The Ansible Language Server installs and starts successfully.
2. The proposed `ansiblels` configuration works with Neovim's native LSP API.
3. Ansible-specific filetype detection works without affecting ordinary YAML files.
4. The existing YAML Treesitter parser is reused successfully.
5. Ansible Lint diagnostics are available without duplication.
6. Ansible Core syntax validation works from the intended project environment.
7. Manual formatting passes representative Ansible fixtures.
8. Windows-to-WSL2 LSP interoperability is validated, or a documented WSL-native fallback is selected.
9. Existing configuration and smoke-test suites pass without regressions.
10. External dependencies and installation requirements are documented.

Until these conditions are met, `ansiblels` remains a preferred candidate rather than an approved Stage 13 dependency.

## 16. Final Decision Record

| Decision | Status |
|---|---|
| Ansible classification as infrastructure automation | Approved |
| Separate `lua/langs/ansible.lua` module | Proposed |
| Ansible Language Server (`ansiblels`) | Preferred candidate; pending validation |
| Native Neovim LSP API | Approved architectural approach |
| `nvim-lspconfig` server definitions | Approved architectural dependency |
| YAML Treesitter parser reuse | Approved |
| `ansible-lint` for static analysis | Preferred tool |
| Ansible Core for runtime and syntax validation | Preferred tool |
| Conform for manual formatting | Approved architectural approach; formatter pending evaluation |
| WSL2 as the preferred Ansible environment | Proposed |
| Native Windows-to-WSL2 LSP interoperability | Pending validation |
| WSL-native Neovim fallback | Approved fallback strategy |
| Automatic dependency installation | Rejected |
| Mason-based installation | Rejected |
| Automatic format-on-save | Disabled by default |
| Automatic lint fixes | Rejected |

### Final Status

**Ansible Support: Proposed — Pending Installation and Interoperability Validation**

The Ansible integration will remain a separate Stage 13 infrastructure-automation module.

The preferred implementation uses `ansiblels` through Neovim's native LSP client, reuses the existing YAML Treesitter infrastructure, uses `ansible-lint` for static analysis, and relies on Ansible Core for playbook validation.

WSL2 is the preferred environment for Ansible tooling on Windows. However, native Windows Neovim interoperability must be demonstrated before that arrangement becomes the standard configuration.

Implementation and formal approval must follow the validation requirements defined in this document.

---

**Related documentation**

- [Stage 13: Language Packs](../roadmap.md)
- [Optional Language Packs](optional-packs.md)
- [Docker and Docker Compose Support](docker-support.md)
- [SQL Support](sql-support.md)
- [YAML Support](yaml-support.md)
- [External Dependency Management](../install-scripts.md)

**External references**

- [Ansible Language Server](https://docs.ansible.com/projects/vscode-ansible/als/)
- [Ansible VS Code Extension Repository](https://github.com/ansible/vscode-ansible)
- [Ansible Lint Documentation](https://docs.ansible.com/projects/lint/)
- [Ansible Installation Guide](https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html)
- [Microsoft WSL Interoperability](https://learn.microsoft.com/en-us/windows/dev-environment/wsl-interop)
- [Neovim LSP Configuration Definitions](https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.txt)
