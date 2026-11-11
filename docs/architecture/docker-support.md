# Docker and Docker Compose Support

## 1. Purpose

This document defines the Docker and Docker Compose support architecture for Stage 13 (Language and Infrastructure Support) of the Neovim configuration.

The objective is to provide a reliable editing environment for Dockerfiles and Docker Compose configurations while keeping Docker runtime infrastructure independent of Neovim.

Docker support follows the project's core principle:

**Minimum installation. Compose the rest.**

The implementation must preserve:

- Native-first Neovim configuration.
- Explicit external dependency management.
- Modular language-pack ownership.
- No silent installation of tools.
- Reuse of existing shared infrastructure.
- Windows compatibility as the primary validation target.
- Optional runtime dependencies that do not prevent basic editing.
- Clear separation between editor dependencies and system-managed Docker infrastructure.

## 2. Scope

### 2.1. Mandatory editor support

The initial Docker editor baseline includes:

- Dockerfile filetype detection.
- Dockerfile Treesitter highlighting.
- Docker Language Server integration.
- Docker Compose filetype detection.
- Compose language-server integration.
- Reuse of the existing YAML language pack.
- Dockerfile formatting through `dockerfmt`.
- Compose formatting through the existing Prettier integration.
- Integration with the existing language registry and smoke-test architecture.
- Explicit installation and verification of Docker editor tools on Windows.

### 2.2. Optional capabilities

The following capabilities remain independent of the core editor configuration:

- Docker CLI commands.
- Docker Compose configuration validation.
- Docker Engine operations.
- Docker Buildx.
- Docker Bake.
- Hadolint.
- Docker Scout and other external image-analysis capabilities.

Users may install these tools independently when they need the corresponding functionality.

Their absence must not prevent basic Dockerfile or Compose editing.

### 2.3. Deferred capabilities

The initial implementation does not include:

- Docker Bake language support.
- Hadolint diagnostics.
- Container lifecycle management.
- Kubernetes integration.
- Registry management.
- Remote container management.
- Deployment automation.
- Docker runtime installation or lifecycle management.

These capabilities require separate evaluation and approval before implementation.

## 3. Dependency Architecture

Docker support uses three independent dependency layers.

### 3.1. Editor dependencies

These dependencies provide editor functionality without requiring Docker Engine.

| Component | Tool | Status |
|---|---|---|
| Language server | Docker Language Server `v0.20.1` | Installed and validated |
| LSP client | Native Neovim LSP | Validated |
| Dockerfile parser | Treesitter `dockerfile` | Validated |
| Compose parser | Existing Treesitter `yaml` | Validated |
| Dockerfile formatter | `dockerfmt` `v0.6.0` | Installed and validated |
| Compose formatter | Prettier | Existing integration preserved |
| Configuration module | `lua/langs/docker.lua` | Implemented |
| Windows installer | `scripts/core/windows/docker.ps1` | Implemented and tested |

These are the Docker-specific external tools managed by the current implementation.

### 3.2. Docker CLI dependencies

These tools provide Docker-specific command-line capabilities.

| Component | Purpose | Requirement | Management |
|---|---|---|---|
| Docker CLI | Docker command execution | Optional | User-managed |
| Docker Compose CLI | Compose validation and operations | Optional | User-managed |
| Docker Buildx | Advanced build functionality | Optional | User-managed |
| Hadolint | Dockerfile static analysis | Deferred | Not currently managed |

The project does not install or update these tools.

Users who require Docker-specific command-line functionality must install and maintain the relevant tools independently.

### 3.3. Runtime dependencies

Docker Engine or a compatible runtime provides container execution.

| Component | Purpose | Requirement | Management |
|---|---|---|---|
| Docker Engine | Container execution | Optional | User-managed |
| Docker Desktop | Windows distribution of Docker tooling and Engine | Optional | User-managed |
| Compatible remote Engine | Remote container execution | Optional | User-managed |

Docker Desktop is not a mandatory dependency of the Neovim configuration.

The project does not install, configure, start, stop, or update Docker Engine or Docker Desktop.

### 3.4. Dependency boundaries

The dependency relationships are:

| Capability | Editor tools | Docker CLI | Docker Engine |
|---|---:|---:|---:|
| Dockerfile highlighting | Yes | No | No |
| Compose highlighting | Yes | No | No |
| Basic LSP integration | Yes | No | No |
| Dockerfile formatting | Yes | No | No |
| Compose formatting | Yes | No | No |
| Compose configuration validation | No | Yes | Generally no |
| Docker image build | No | Yes | Yes |
| Container execution | No | Yes | Yes |
| Compose application startup | No | Yes | Yes |
| Container lifecycle management | No | Yes | Yes |

Some advanced Docker Language Server features may require Buildx, Docker tooling, BuildKit metadata, or external services. Those requirements must be documented at the feature level.

The absence of Docker Engine must not prevent basic editing.

## 4. Docker Language Server

### 4.1. Selected implementation

The project uses the official Docker Language Server.

Repository:

https://github.com/docker/docker-language-server

Validated version:

```text
v0.20.1
```

Executable:

```text
docker-language-server
```

Installation:

```powershell
go install github.com/docker/docker-language-server/cmd/docker-language-server@v0.20.1
```

The installation must remain explicit and user-controlled.

The production dependency declaration must use the validated version rather than `@latest`.

### 4.2. Native LSP integration

The project uses Neovim's native LSP APIs:

```lua
vim.lsp.config()
vim.lsp.enable()
```

The server identifier is:

```text
docker_language_server
```

The upstream startup command is:

```lua
{
  "docker-language-server",
  "start",
  "--stdio",
}
```

The server uses standard input and output for LSP communication.

Telemetry is disabled:

```lua
init_options = {
  telemetry = "off",
}
```

The implementation extends the upstream server definition supplied by `nvim-lspconfig`. It must preserve upstream command arguments, root markers, and language-ID handling.

### 4.3. Supported filetypes

The initial configuration enables:

| Filetype | Language server |
|---|---|
| `dockerfile` | Docker Language Server |
| `yaml.docker-compose` | Docker Language Server and YAML Language Server |
| `yaml` | YAML Language Server only |

Compose files use the language identifier:

```text
dockercompose
```

The configuration must not attach Docker Language Server to ordinary YAML files.

### 4.4. Optional server capabilities

Docker Language Server provides additional capabilities involving Docker build tooling and image analysis.

Features that depend on Buildx, BuildKit, Docker CLI integration, or external services must remain optional.

Missing optional tooling must not prevent basic server startup or Dockerfile and Compose editing.

## 5. Windows External Tool Installation

### 5.1. Installer ownership

The Windows Docker editor-tools installer is:

```text
scripts/core/windows/docker.ps1
```

It manages only the installation of the two pinned Go-based editor tools:

| Tool | Go module | Version |
|---|---|---|
| Docker Language Server | `github.com/docker/docker-language-server` | `v0.20.1` |
| dockerfmt | `github.com/reteps/dockerfmt` | `v0.6.0` |

The installer uses the Go toolchain and installs binaries into the Go binary directory.

### 5.2. Prerequisites

The installer requires:

- Go `1.24.0` or later.
- PowerShell.
- A writable Go binary installation directory.

The script discovers the Go executable and determines the installation directory using `go env GOBIN` and `go env GOPATH`.

It does not require Docker Engine, Docker Desktop, Docker CLI, or Docker Compose CLI.

### 5.3. Installation behavior

Run the installer explicitly:

```powershell
.\scripts\core\windows\docker.ps1
```

The script:

1. Locates the Go executable.
2. Validates the Go toolchain version.
3. Determines the Go binary installation directory.
4. Installs each tool using its pinned Go module version.
5. Reads the installed executable's embedded module metadata.
6. Verifies that the installed module version matches the expected version.
7. Reports the result for each tool.

The installer does not use `@latest`.

It does not install Docker runtime infrastructure or modify the Neovim configuration automatically.

### 5.4. Verification-only mode

The installer supports verification without installation:

```powershell
.\scripts\core\windows\docker.ps1 -VerifyOnly
```

This checks the installed binaries and their embedded Go module versions.

A missing binary or mismatched version causes verification to fail.

### 5.5. Forced installation

The installer supports explicit reinstallation:

```powershell
.\scripts\core\windows\docker.ps1 -Force
```

This reinstalls the pinned versions even when the expected versions are already present.

### 5.6. WhatIf support

The script supports PowerShell's `-WhatIf` parameter:

```powershell
.\scripts\core\windows\docker.ps1 -WhatIf
```

This previews installation actions without executing them.

### 5.7. Version verification

The script uses:

```powershell
go version -m <executable>
```

It checks the embedded Go module path and version rather than relying on the executable's `--version` output.

This is important because the validated tools do not expose their Go module release versions consistently through their version commands.

The installer must fail when it cannot confirm the expected module version.

### 5.8. Runtime tools are not installer responsibilities

The project must not extend this installer to install:

- Docker CLI.
- Docker Compose CLI.
- Docker Engine.
- Docker Desktop.
- Buildx.
- Hadolint.

These tools belong to the user's system-level development environment.

Separate Docker CLI, Compose CLI, Engine, or Docker Desktop installation scripts are not required by the core `nvim-config` project.

This boundary avoids turning a Neovim configuration repository into a Docker environment or container-runtime manager.

### 5.9. Future dependency manifest

The future dependency manifest may describe Docker editor tools and their pinned versions.

The manifest must distinguish editor dependencies from optional system-managed tools.

It must not imply that the project installs or manages Docker runtime infrastructure.

Manifest integration is intentionally deferred and is not part of the current installer implementation.

## 6. Filetype Detection

Docker-specific filetype detection is maintained in:

```text
lua/config/filetypes.lua
```

The Compose filename mappings include:

| Filename | Filetype |
|---|---|
| `compose.yaml` | `yaml.docker-compose` |
| `compose.yml` | `yaml.docker-compose` |
| `docker-compose.yaml` | `yaml.docker-compose` |
| `docker-compose.yml` | `yaml.docker-compose` |

Ordinary YAML files retain the `yaml` filetype.

Dockerfile detection uses Neovim's existing filetype support. The following names have been validated:

- `Dockerfile`
- `Dockerfile.dev`
- `dockerfile`
- `Containerfile`

No additional Dockerfile filetype rules are required.

## 7. Treesitter Integration

Docker support reuses the existing Treesitter infrastructure.

| Filetype | Parser | Ownership |
|---|---|---|
| `dockerfile` | `dockerfile` | Docker support |
| `yaml.docker-compose` | `yaml` | Existing data language pack |

The Compose filetype maps to the existing YAML parser.

The implementation must not introduce another YAML parser or duplicate YAML parser configuration.

The existing parser registry uses:

```lua
parser_by_filetype
```

The Docker pack contributes:

```lua
parser_by_filetype = {
  dockerfile = "dockerfile",
}
```

Compose parser ownership remains with the data language pack.

The project uses its existing on-demand parser installation workflow. Docker support must not introduce a separate parser installer.

Bake HCL parser support remains deferred.

## 8. Formatting

### 8.1. Formatting architecture

Docker formatting uses the existing Conform integration.

The project retains its manual formatting command:

```vim
:Format
```

Format-on-save remains disabled by default.

LSP formatting fallback remains disabled according to the existing global formatting policy.

No Docker-specific formatting framework is introduced.

### 8.2. Dockerfile formatting

The selected Dockerfile formatter is:

```text
dockerfmt
```

Repository:

https://github.com/reteps/dockerfmt

Validated version:

```text
v0.6.0
```

Installation:

```powershell
go install github.com/reteps/dockerfmt@v0.6.0
```

The formatter supports standard input/output and in-place file formatting.

For direct CLI usage:

```powershell
dockerfmt --write Dockerfile
```

The Docker language pack registers:

```lua
formatters = {
  dockerfile = { "dockerfmt" },
}
```

Conform uses the formatter's standard input/output behavior to format the buffer. The direct CLI `--write` option is not required for the Conform integration.

### 8.3. Compose formatting

Compose formatting remains owned by the existing data language pack.

The formatter mapping is:

```lua
["yaml.docker-compose"] = { "prettier" }
```

The Docker pack must not register another Compose formatter.

### 8.4. Formatting ownership

| Filetype | Formatter | Owner |
|---|---|---|
| `dockerfile` | `dockerfmt` | Docker language pack |
| `yaml.docker-compose` | `prettier` | Data language pack |

No competing Docker LSP formatting provider is registered for these workflows.

## 9. Docker Compose Validation

Docker Compose CLI provides external configuration validation.

The validation command is:

```powershell
docker compose config --quiet
```

This command validates and resolves the Compose configuration without starting containers.

Requirements:

- Docker CLI must be installed.
- Docker Compose must be available as a CLI plugin.
- Environment-variable interpolation must be handled correctly.
- Validation must use controlled, non-sensitive test values.
- Resolved configuration and secrets must not be printed or exposed unnecessarily.

A running Docker Engine is generally not required for this configuration-only validation command.

Compose runtime operations, such as `docker compose up`, require a working Engine.

Validation remains separate from ordinary YAML editing and formatting.

Missing Docker Compose must not prevent Compose editing.

The project documents this command as an optional workflow. It does not install or manage the tools needed to execute it.

## 10. Docker Runtime Operations

Docker Engine is required for runtime operations.

Examples include:

```powershell
docker build .
docker run --rm hello-world
docker compose up
docker compose down
```

These commands require the Docker CLI and a functioning Engine. Additional commands may require Buildx or other plugins.

Runtime operations must not be invoked automatically during Neovim startup.

The Neovim configuration must not:

- Install Docker Engine or Docker Desktop.
- Start Docker Desktop automatically.
- Start or stop containers automatically.
- Modify Docker daemon configuration.
- Install Docker CLI or Compose CLI.
- Store registry credentials.
- Perform deployment operations without explicit user action.

The project does not provide Docker runtime installation scripts.

Users are responsible for installing, configuring, updating, and maintaining their Docker runtime environment.

Runtime validation belongs in a separate integration-test layer and is not a prerequisite for the core editor smoke suite.

## 11. Docker Buildx and Bake

Buildx remains optional.

Buildx-dependent capabilities must not prevent basic Dockerfile or Compose editing.

Bake support is deferred until the project evaluates:

- HCL and JSON Bake filetype detection.
- HCL parser requirements.
- Docker Language Server integration.
- Buildx availability.
- Formatting requirements.
- Dedicated smoke tests.

The initial Docker language pack does not enable Bake filetypes.

The project does not install or manage Buildx.

## 12. Static Analysis

Hadolint remains optional and deferred.

Repository:

https://github.com/hadolint/hadolint

Before integration, the project must evaluate:

1. Windows installation requirements.
2. Executable discovery.
3. Diagnostic quality.
4. Integration with the existing diagnostics architecture.
5. Overlap with Docker Language Server diagnostics.
6. Behavior when Hadolint is unavailable.

Hadolint must not become a mandatory dependency for basic Docker editing.

The project does not currently install or manage Hadolint.

## 13. Configuration Ownership

The Docker language pack is located at:

```text
lua/langs/docker.lua
```

Its responsibilities include:

- Dockerfile formatter metadata.
- Dockerfile parser metadata.
- Docker Language Server metadata.
- Docker Language Server activation.
- Docker-specific initialization options.

The pack must not duplicate:

- General YAML language configuration.
- Compose formatter configuration.
- General Treesitter installation logic.
- Global formatting policy.
- External dependency installation logic.

The existing data language pack owns shared YAML functionality.

The existing language registry owns pack discovery and metadata aggregation.

The Windows external-tools installer owns the explicit installation and version verification of Docker Language Server and `dockerfmt`.

Docker CLI, Docker Compose CLI, Docker Engine, Docker Desktop, and other runtime tools remain outside the project's installation and lifecycle-management responsibilities.

## 14. Security Requirements

Docker configuration must not introduce hardcoded credentials, authentication tokens, or environment-specific secrets.

The following must remain outside the Neovim configuration repository:

- Registry credentials.
- Private registry authentication tokens.
- Database passwords.
- Environment-specific secrets.
- Private deployment configuration.

Secrets must not be added to:

- Plugin configuration.
- Language-server configuration.
- Installation scripts.
- Dependency manifests.
- Smoke-test fixtures.

Docker Language Server telemetry must remain disabled where supported.

Compose validation fixtures must use controlled test values rather than real credentials.

The installer must use pinned versions and verify the installed executable's embedded module metadata.

The project must not modify Docker authentication, daemon, or runtime configuration.

## 15. Validation Results

### 15.1. Windows environment

| Check | Result |
|---|---|
| Go executable discovery | Passed |
| Go version | `1.27.3` |
| Go installation directory discovery | Passed |
| Docker Language Server installation | Passed |
| Docker Language Server module version | `v0.20.1` |
| Docker Language Server executable discovery | Passed |
| `dockerfmt` installation | Passed |
| `dockerfmt` module version | `v0.6.0` |
| `dockerfmt` executable discovery | Passed |
| Installer version verification | Passed |
| Installer execution | Passed |

### 15.2. Native LSP integration

| Check | Result |
|---|---|
| Dockerfile LSP attachment | Passed |
| Compose LSP attachment | Passed |
| Compose language ID | `dockercompose` |
| YAML and Docker LSP coexistence | Passed |
| Ordinary YAML isolation | Passed |
| YAML formatting capability disabled | Passed |
| Docker LSP formatting provider absent | Passed |

### 15.3. Filetype and Treesitter

| Check | Result |
|---|---|
| Dockerfile filetype detection | Passed |
| Compose filename detection | Passed |
| Ordinary YAML filetype isolation | Passed |
| Dockerfile parser loading | Passed |
| YAML parser loading | Passed |
| Dockerfile highlighting | Passed |
| Compose highlighting | Passed |

### 15.4. Formatter integration

| Check | Result |
|---|---|
| Docker pack formatter metadata | Passed |
| Registry formatter aggregation | Passed |
| Conform formatter discovery | Passed |
| `dockerfmt` availability | Passed |
| Actual `:Format` workflow | Passed |
| Dockerfile file write | Passed |
| Compose Prettier mapping preserved | Passed |
| Global formatting policy unchanged | Passed |

### 15.5. Deferred validation

The following checks remain deferred:

- Docker CLI installation and discovery.
- Docker Compose CLI installation and validation.
- Docker Engine runtime operations.
- Docker Desktop integration.
- Buildx functionality.
- Hadolint integration.
- Docker Bake support.

Docker Engine and Docker Compose are not required to pass the core editor integration tests.

No Docker runtime installer is required for completion of the core editor baseline.

## 16. Smoke-Test Requirements

Docker smoke tests must integrate with the existing smoke-test architecture.

The mandatory editor tests should verify:

- Docker language pack activation.
- Docker formatter metadata.
- Docker parser metadata.
- Docker Language Server registration.
- Dockerfile LSP attachment.
- Compose LSP attachment.
- YAML LSP coexistence.
- Ordinary YAML isolation.
- Compose language-ID mapping.
- Optional executable detection.
- Graceful behavior when Docker runtime tooling is missing.

Installer verification must check that the expected pinned versions are installed.

Runtime-dependent tests must be separate and conditional.

A missing Docker CLI or Engine must not fail the core editor smoke suite.

Tests that require a runtime must clearly identify their prerequisites and must not run unless those prerequisites are available.

The core smoke suite must not install Docker CLI, Compose CLI, Docker Engine, or Docker Desktop.

## 17. Completion Criteria

The mandatory Docker editor baseline is complete when:

1. Docker Language Server is installed at a validated version.
2. The Windows external-tools installer installs and verifies the pinned editor tools.
3. Native Neovim LSP integration works.
4. Dockerfile filetype detection works.
5. Compose filetype detection works.
6. Ordinary YAML remains isolated from Docker Language Server.
7. Dockerfile Treesitter integration works.
8. Compose reuses the existing YAML parser.
9. Dockerfile formatting works through Conform.
10. Compose formatting remains functional through Prettier.
11. Manual formatting works through `:Format`.
12. Format-on-save remains disabled.
13. Optional dependencies do not prevent basic editing.
14. The language registry and smoke-test integration pass.
15. Documentation reflects the implementation.
16. No credentials or secrets are introduced.
17. Docker runtime installation remains outside the project's responsibilities.

Docker CLI, Compose CLI, Docker Engine, Docker Desktop, Buildx, Hadolint, and Bake are independently scoped capabilities. Their absence does not block completion of the core editor baseline.

## 18. Final Architecture Summary

| Area | Decision |
|---|---|
| Support category | Infrastructure |
| Stage | Stage 13 |
| Configuration module | `lua/langs/docker.lua` |
| Windows installer | `scripts/core/windows/docker.ps1` |
| Language server | Docker Language Server `v0.20.1` |
| LSP implementation | Native Neovim LSP |
| Server identifier | `docker_language_server` |
| Dockerfile filetype | `dockerfile` |
| Compose filetype | `yaml.docker-compose` |
| Compose language ID | `dockercompose` |
| Dockerfile parser | Treesitter `dockerfile` |
| Compose parser | Existing Treesitter `yaml` |
| Dockerfile formatter | `dockerfmt` `v0.6.0` |
| Compose formatter | Existing Prettier integration |
| Formatting framework | Conform |
| Formatting command | `:Format` |
| Format-on-save | Disabled |
| LSP formatting fallback | Disabled by existing policy |
| Docker CLI | Optional, user-managed |
| Docker Compose CLI | Optional, user-managed |
| Docker Engine | Optional, user-managed |
| Docker Desktop | Optional, user-managed |
| Docker Buildx | Optional, user-managed |
| Hadolint | Deferred |
| Bake support | Deferred |
| Docker runtime installer | Not required |
| Plugin management | Native `vim.pack` |
| Mason | Not permitted |
| lazy.nvim | Not permitted |
| Telemetry | Disabled where supported |
| Editor dependency installation | Explicit and user-controlled |
| Runtime dependency management | Outside project scope |
| Primary validation platform | Windows |

## 19. Architectural Principle

Docker editor support must remain independent of container runtime infrastructure.

Users must be able to edit, navigate, format, and maintain Dockerfiles and Compose configurations without installing or running Docker Engine.

Docker Language Server provides language intelligence. Treesitter provides syntax parsing. `dockerfmt` handles Dockerfile formatting, while the existing Prettier integration handles Compose formatting.

The Windows external-tools installer provides explicit, pinned installation and verification of the Docker editor dependencies. It does not manage Docker runtime infrastructure.

Docker CLI validation, Compose runtime operations, Buildx, Hadolint, and container execution remain independent capabilities with explicit prerequisites.

The project must not become a Docker environment manager. It must not install, configure, or maintain Docker CLI, Compose CLI, Docker Engine, or Docker Desktop.

The project must preserve a deterministic, modular, native-first architecture in which optional dependencies are activated only when their corresponding functionality is required.

---

**Document status:** Core editor integration and Windows external-tools installer implemented and validated. Optional runtime integration deferred.

**Stage:** 13 — Language and Infrastructure Support.

**Support category:** Infrastructure.
