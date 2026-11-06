# Docker and Docker Compose Support

## 1. Purpose

This document defines the Docker and Docker Compose support baseline for Stage 13 (Language and Infrastructure Support) of the Neovim configuration project.

The objective is to establish a consistent infrastructure-development editing environment for working with Dockerfiles, Docker Compose configurations, and related Docker build definitions.

Docker support will remain an independent infrastructure module rather than being treated as a programming-language pack. It will reuse the project's existing native LSP, Treesitter, formatting, dependency-management, and validation infrastructure.

The initial scope covers:

- Dockerfiles.
- Docker Compose files.
- Docker Buildx Bake files as optional support.

The implementation must follow the project's established principles:

- Native-first Neovim configuration.
- Explicit external dependency management.
- Modular, filetype-oriented configuration.
- No silent installation of external tools.
- No unnecessary duplication of shared infrastructure.
- Windows compatibility as the primary validation target.
- Optional runtime dependencies that do not prevent basic editing.

## 2. Proposed Tooling

The following tooling defines the proposed Docker support baseline.

| Component | Selected Tool | Status |
|---|---|---|
| Language server | Docker Language Server | Approved for Windows validation |
| LSP client | Native Neovim LSP | Approved |
| Dockerfile parser | Treesitter `dockerfile` | Proposed |
| Compose parser | Existing Treesitter `yaml` | Approved reuse |
| Bake parser | HCL parser | Pending evaluation |
| Dockerfile static analysis | Hadolint | Optional, pending evaluation |
| Compose validation | Docker Compose CLI | Optional |
| Formatting | Docker Language Server and shared Conform infrastructure | Pending validation |
| Container runtime | Docker Engine or compatible runtime | Optional |
| Build tooling | Docker Buildx | Optional |
| Configuration module | `lua/langs/docker.lua` | Proposed |
| Dependency management | Existing installation manifest and scripts | Approved reuse |

### 2.1. Language Server: Docker Language Server

<badge color="success">Approved for Windows validation</badge>

The selected language server is the official Docker Language Server.

Repository:

https://github.com/docker/docker-language-server

Docker Language Server provides language intelligence for Dockerfiles, Docker Compose files, and Docker Bake files.

Its selection is approved. However, Windows installation, executable discovery, startup behavior, and native Neovim LSP integration must pass validation before implementation is considered complete.

#### Dockerfile capabilities

The documented Dockerfile capabilities include:

- Image hover information.
- Suggested image tag updates.
- Dockerfile linting through BuildKit and Buildx.
- Docker Scout integration for image vulnerability information, where available.

#### Docker Compose capabilities

The documented Compose capabilities include:

- Code completion.
- Definition and navigation.
- Document outline.
- Error reporting.
- Formatting.
- Hover information.
- Named-reference highlighting.
- Rename support for named references.
- Inlay hints for overridden attribute values.

#### Docker Bake capabilities

The documented Bake capabilities include:

- Code completion.
- Navigation.
- Document outline.
- Error reporting.
- Formatting.
- Hover information.
- Variable value inference.

Some capabilities depend on Docker Buildx being available as a Docker CLI plugin.

These features must degrade gracefully when Buildx or other optional Docker tooling is unavailable.

#### Installation requirements

The proposed installation method uses Go 1.24 or later:

```powershell
go install github.com/docker/docker-language-server/cmd/docker-language-server@latest
```

Expected executable:

```text
docker-language-server
```

Expected LSP startup command:

```powershell
docker-language-server start --stdio
```

The server must communicate through standard input and output for native Neovim LSP integration.

The following requirements must be validated on Windows:

1. Go 1.24 or later is available.
2. Installation completes successfully.
3. The executable is installed in the expected Go binary directory.
4. The executable directory is discoverable through the system PATH.
5. The server accepts the documented startup arguments.
6. Standard input/output communication works.
7. The server starts successfully from PowerShell and Neovim.

The executable must not be added to the dependency manifest until local Windows validation succeeds.

### 2.2. LSP Client: Native Neovim LSP

Docker Language Server will integrate through Neovim's native Language Server Protocol implementation.

The project will use:

```lua
vim.lsp.config()
vim.lsp.enable()
```

No additional LSP client or framework will be introduced.

The initial server registration proposal is:

```lua
vim.lsp.config("dockerls", {
  cmd = {
    "docker-language-server",
    "start",
    "--stdio",
  },

  init_options = {
    telemetry = "off",
  },
})

vim.lsp.enable("dockerls")
```

This configuration is an implementation proposal, not a declaration of completed validation.

The final implementation must verify:

- Executable discovery through the system PATH.
- Correct server startup arguments.
- Native LSP client attachment.
- Supported initialization options.
- Correct Dockerfile and Compose filetype detection.
- No unintended attachment to unrelated YAML files.

Docker Compose files use YAML syntax. Therefore, Docker Language Server must not attach indiscriminately to every YAML buffer.

Compose-specific filetype detection must be implemented using a reliable and maintainable mechanism.

The final configuration must follow the existing language registry contract and shared LSP conventions.

### 2.3. Treesitter Integration

Docker support will use the following Treesitter parsers:

| File Type | Parser | Status |
|---|---|---|
| Dockerfile | `dockerfile` | Proposed |
| Docker Compose | `yaml` | Reuse existing parser |
| Docker Bake HCL | `hcl` | Pending evaluation |

Dockerfiles require the dedicated Dockerfile parser.

Docker Compose files use YAML syntax and must reuse the existing YAML parser.

The project must not introduce another YAML parser or duplicate general YAML configuration.

The existing YAML language pack remains responsible for general YAML language support, while Docker Language Server provides Docker-specific Compose intelligence.

Bake syntax support will be evaluated separately. An HCL parser should only be introduced if the required Bake filetype detection and editing capabilities justify the additional dependency.

### 2.4. Dockerfile Static Analysis: Hadolint

The proposed Dockerfile static analyzer is Hadolint.

Repository:

https://github.com/hadolint/hadolint

Hadolint analyzes Dockerfiles against established best practices and identifies potential issues.

Its responsibilities include:

- Dockerfile instruction validation.
- Best-practice enforcement.
- Security-related recommendations.
- Image and package management recommendations.
- Dockerfile style checks.

Hadolint will be evaluated independently from Docker Language Server.

The implementation must avoid unnecessary diagnostic duplication between the two tools.

The evaluation must establish:

1. Windows installation requirements.
2. Executable discovery.
3. Command-line compatibility.
4. Diagnostic quality.
5. Integration options with the existing editor architecture.
6. Whether its diagnostics provide sufficient additional value.

Hadolint will remain optional until its Windows installation and integration requirements have been validated.

It must not become a mandatory dependency solely because Dockerfile analysis is desirable.

### 2.5. Docker Compose Validation

Docker Compose CLI will provide external validation of Compose configurations.

The proposed validation command is:

```powershell
docker compose config --quiet
```

This command validates and resolves the Compose configuration without starting containers.

Validation must remain separate from ordinary YAML editing and formatting workflows.

The implementation must distinguish between:

- Editor diagnostics provided by Docker Language Server.
- External configuration validation provided by Docker Compose CLI.
- Container execution and runtime operations.

Docker Compose CLI remains an optional external dependency.

Users who only require Dockerfile and Compose editing must not be required to install or run Docker Engine.

### 2.6. Formatting

Docker formatting must follow the project's existing shared formatting architecture.

The implementation will evaluate the following:

1. Docker Language Server formatting for Compose files.
2. Shared Conform integration where a suitable formatter exists.
3. Whether Dockerfiles require a dedicated formatting tool.
4. Whether Docker Bake files require separate formatting support.

No additional formatting framework will be introduced.

The project will retain its existing manual formatting workflow through:

```vim
:Format
```

The existing formatting keymap will remain available.

Format-on-save must remain disabled by default.

The final implementation must avoid registering duplicate formatting providers. If Docker Language Server provides formatting for a filetype, Conform must not register a competing formatter for that same workflow without an explicit architectural reason.

Formatting support must be validated independently for Dockerfiles, Compose files, and Bake files.

## 3. Architecture Decisions

### 3.1. Independent Infrastructure Support

Docker will receive an independent infrastructure-support module.

Entry point:

```text
lua/langs/docker.lua
```

Although Docker is not a programming language, placing its editor configuration under `lua/langs/` maintains the project's existing organization around filetype-specific tooling.

The module will provide shared Docker infrastructure configuration for:

- Dockerfiles.
- Docker Compose files.
- Docker Bake files, when enabled.

The module must follow the existing language registry contract and shared configuration conventions.

### 3.2. Dockerfile and Compose Separation

Dockerfile and Docker Compose support must remain logically distinct.

| Area | Responsibility |
|---|---|
| Dockerfile | Container image build instructions |
| Docker Compose | Multi-container application configuration |
| Docker Bake | Advanced build orchestration |

Although these areas may share Docker Language Server, they have different:

- Filetype detection requirements.
- Parser requirements.
- Validation commands.
- Formatting requirements.
- External tooling dependencies.

The implementation must preserve these distinctions rather than treating every Docker-related file as the same filetype.

### 3.3. Compose Reuses YAML Infrastructure

Docker Compose must reuse the existing YAML infrastructure.

The project will not introduce:

- A duplicate YAML parser.
- A separate general-purpose YAML language configuration.
- Duplicate YAML formatting or validation infrastructure without justification.

Docker-specific Compose functionality will be provided by Docker Language Server.

Compose filetype detection must be sufficiently specific to prevent unnecessary Docker LSP attachment to ordinary YAML files.

### 3.4. Optional Container Runtime

Docker Engine and compatible container runtimes will remain optional external dependencies.

Users must be able to:

- Edit Dockerfiles.
- Navigate Dockerfile instructions.
- Edit Compose configurations.
- Receive available language-server diagnostics.
- Use Dockerfile and Compose syntax highlighting.

These capabilities must not require Docker Engine to be installed or running.

Runtime-dependent functionality must only be available when the corresponding external infrastructure is installed and configured.

### 3.5. Buildx Remains Optional

Docker Buildx will remain optional.

Buildx-dependent features must not prevent basic Dockerfile or Compose editing when Buildx is unavailable.

The following must remain independent:

- Basic Dockerfile editing.
- Compose editing.
- Buildx-specific functionality.
- Advanced Bake workflows.

Buildx installation and validation will be documented separately.

### 3.6. Security and Credentials

Docker configuration must not introduce hardcoded credentials, authentication tokens, or environment-specific secrets.

The following must remain outside the Neovim configuration repository:

- Registry credentials.
- Private registry authentication tokens.
- Database credentials referenced by Compose files.
- Environment-specific secrets.
- Private deployment configuration.

Users must rely on Docker-supported authentication mechanisms and external environment configuration.

The project must not add credentials or sensitive environment values to:

- Plugin configuration.
- Language-server configuration.
- Installation scripts.
- Dependency manifests.
- Smoke-test fixtures.

Docker Language Server telemetry will be explicitly disabled where supported by its configuration.

### 3.7. Shared Infrastructure Reuse

Docker support must reuse existing project infrastructure wherever appropriate.

| Existing Infrastructure | Docker Integration |
|---|---|
| Native Neovim LSP | Language-server registration and activation |
| Treesitter | Dockerfile and YAML parser integration |
| Conform | Shared formatting framework |
| Language registry | Module discovery and configuration conventions |
| Dependency manifest | External tooling declarations |
| Windows installation scripts | Explicit dependency installation |
| Validation scripts | Dependency and configuration checks |
| Smoke-test infrastructure | Docker support verification |
| `vim.pack` | Existing plugin-management architecture |

No Mason, lazy.nvim, or additional LSP framework will be introduced.

## 4. Proposed File Organization

The proposed configuration structure is:

```text
lua/
├── langs/
│   ├── docker.lua
│   ├── sql.lua
│   └── ...
└── plugins/
    └── ...
```

The Docker module will be responsible for:

1. Docker Language Server registration.
2. Native LSP activation.
3. Dockerfile filetype support.
4. Docker Compose filetype support.
5. Docker-specific Treesitter integration where needed.
6. Docker-specific formatting integration.
7. Optional Docker-related editor capabilities.

Shared YAML functionality must remain within the existing YAML language pack.

The Docker module must not duplicate general-purpose YAML configuration.

The module must integrate with the existing `lua/langs/init.lua` registry and comply with its established metadata and setup conventions.

External tools must remain independently managed. The Docker module must not silently install Docker Language Server, Docker Engine, Buildx, Hadolint, or other dependencies.

## 5. Installation Requirements

The proposed external tooling is:

| Tool | Purpose | Requirement |
|---|---|---|
| `docker-language-server` | Docker language intelligence | Core editor tooling |
| Dockerfile Treesitter parser | Dockerfile syntax support | Core editor support |
| YAML Treesitter parser | Compose syntax support | Reuse existing baseline |
| `hadolint` | Dockerfile static analysis | Optional, pending evaluation |
| Docker CLI | Docker command execution | Optional |
| Docker Compose | Compose validation and execution | Optional |
| Docker Engine | Container runtime | Optional |
| Docker Buildx | Advanced build functionality | Optional |
| HCL Treesitter parser | Bake syntax support | Optional, pending evaluation |

### 5.1. Docker Language Server Installation

Docker Language Server is approved as the implementation candidate for Windows validation.

The proposed installation method requires Go 1.24 or later.

```powershell
go install github.com/docker/docker-language-server/cmd/docker-language-server@latest
```

Expected executable:

```text
docker-language-server
```

The executable must be discoverable through the system PATH.

The installation procedure must verify:

- Go version.
- Installation success.
- Executable location.
- PATH configuration.
- Executable startup.
- Supported server arguments.
- Standard input/output operation.
- PowerShell compatibility.
- Windows compatibility.
- Native Neovim LSP integration.

The installation procedure must follow the project's external dependency-management policy.

The executable will only be added to the dependency manifest after successful local validation.

Official repository and installation documentation:

https://github.com/docker/docker-language-server

### 5.2. Docker Compose Installation

Docker Desktop is the recommended installation route for Windows users who require Docker Engine, Docker CLI, and Docker Compose together.

Official documentation:

https://docs.docker.com/compose/install/

Docker Compose must remain optional for users who only require editor support.

Installation of Docker Desktop must not be triggered by the Neovim configuration or its installation scripts.

### 5.3. Hadolint Installation

Hadolint installation will be evaluated independently.

Repository:

https://github.com/hadolint/hadolint

The evaluation must identify a reliable Windows installation method and verify executable discovery.

The selected installation method must be documented before Hadolint is added to the dependency manifest.

### 5.4. Dependency Management

All external Docker tooling must follow the existing installation architecture.

The requirements are:

- Explicit installation.
- No silent installation.
- Windows installation scripts where applicable.
- Dependency manifest integration after approval.
- Executable discovery through the system PATH.
- Independent validation of optional dependencies.
- Clear separation between editor tooling and runtime infrastructure.

Approval of Docker Language Server does not automatically authorize installation of:

- Docker Engine.
- Docker Desktop.
- Docker Compose.
- Docker Buildx.
- Hadolint.
- HCL tooling.
- Other optional Docker-related dependencies.

Each dependency must be evaluated according to its own purpose and installation requirements.

## 6. Validation Requirements

Docker support must pass the applicable validation requirements before being marked complete.

Validation must distinguish between mandatory editor functionality and optional external tooling.

### 6.1. Language Server Installation

- [ ] Go 1.24 or later is available.
- [ ] Docker Language Server installs successfully on Windows.
- [ ] Executable discovery works.
- [ ] Executable location can be inspected.
- [ ] Server startup options are verified.
- [ ] Standard input/output startup works.
- [ ] Telemetry can be disabled.
- [ ] PowerShell startup compatibility is verified.

### 6.2. Native Neovim LSP

- [ ] Docker Language Server starts through Neovim's native LSP client.
- [ ] `vim.lsp.config()` registration works.
- [ ] `vim.lsp.enable()` activation works.
- [ ] Dockerfile filetype detection works.
- [ ] Docker Compose filetype detection works.
- [ ] Dockerfile language features work.
- [ ] Compose completion works.
- [ ] Compose navigation works.
- [ ] Compose diagnostics work.
- [ ] Compose formatting works.
- [ ] Ordinary YAML files do not receive unintended Docker LSP attachment.
- [ ] Missing Docker Engine does not prevent basic editing.
- [ ] Missing Buildx does not prevent basic editing.
- [ ] Missing optional dependencies produce no unnecessary startup failures.

### 6.3. Treesitter

- [ ] Dockerfile parser installs successfully.
- [ ] Dockerfile syntax highlighting works.
- [ ] Compose uses the existing YAML parser.
- [ ] Compose syntax highlighting works.
- [ ] Parser validation passes.
- [ ] No duplicate YAML parser configuration is introduced.
- [ ] HCL support is evaluated separately if Bake support is implemented.

### 6.4. Static Analysis

- [ ] Hadolint installation works on Windows.
- [ ] Executable discovery works.
- [ ] Dockerfile analysis produces expected diagnostics.
- [ ] Diagnostic integration is validated.
- [ ] Unnecessary diagnostic duplication is avoided.
- [ ] Hadolint remains independent of Docker Language Server.
- [ ] Missing Hadolint does not prevent basic Dockerfile editing.

### 6.5. Compose Validation

- [ ] `docker compose config --quiet` works when Docker Compose is available.
- [ ] Invalid Compose configurations are detected.
- [ ] Valid Compose configurations pass.
- [ ] Validation does not start containers.
- [ ] Validation remains optional when Docker Compose is unavailable.
- [ ] Missing Docker Compose does not prevent ordinary YAML or Compose editing.

### 6.6. Formatting

- [ ] Compose formatting works.
- [ ] Dockerfile formatting requirements are evaluated.
- [ ] Bake formatting requirements are evaluated if Bake support is implemented.
- [ ] Existing Conform infrastructure is reused where appropriate.
- [ ] Manual formatting works through `:Format`.
- [ ] Duplicate formatting providers are avoided.
- [ ] Format-on-save remains disabled.
- [ ] Missing optional formatters do not prevent basic editing.

### 6.7. Dependency Independence

- [ ] Dockerfiles can be edited without Docker Engine.
- [ ] Compose files can be edited without running containers.
- [ ] Docker Compose CLI remains optional.
- [ ] Buildx remains optional.
- [ ] Hadolint remains optional.
- [ ] No Docker credentials are stored in the repository.
- [ ] No existing language pack is unnecessarily duplicated.
- [ ] External dependencies are not installed silently.

### 6.8. Smoke-Test Integration

Docker validation must integrate with the existing smoke-test architecture.

The smoke tests should verify:

- Docker module loading.
- Docker Language Server registration.
- Docker filetype detection.
- Native LSP activation.
- Treesitter parser availability.
- Optional dependency detection.
- Graceful behavior when Docker runtime tooling is missing.

Tests must not require a running container runtime unless a specific runtime-dependent test is explicitly introduced.

The smoke-test suite must distinguish required editor checks from optional tooling checks.

## 7. Scope Boundaries

Docker support is an infrastructure-development editor baseline, not a complete container-management environment.

The mandatory scope is limited to:

- Dockerfile editing.
- Docker Compose editing.
- Docker language intelligence.
- Dockerfile and Compose syntax support.
- Shared formatting integration.
- Optional Dockerfile static analysis.
- Optional Compose configuration validation.

The following capabilities are outside the mandatory scope:

- Container orchestration.
- Kubernetes integration.
- Container deployment automation.
- Registry management.
- Container monitoring.
- Image vulnerability management platforms.
- Docker Engine administration.
- Remote container management.
- Production deployment pipelines.
- Automated container lifecycle management.

These capabilities may be evaluated later as independent optional integrations.

Docker Bake support is also outside the mandatory baseline until its parser, filetype detection, and tooling requirements have been evaluated.

## 8. Completion Criteria

Docker support can be marked complete when all mandatory implementation and validation requirements have been satisfied.

The completion criteria are:

1. The independent Docker infrastructure module is implemented.
2. Docker Language Server works through Neovim's native LSP client.
3. Dockerfile and Compose filetype detection is validated.
4. Dockerfile Treesitter integration works.
5. Compose reuses the existing YAML parser successfully.
6. Dockerfile static analysis is evaluated and its integration decision documented.
7. Compose validation works when Docker Compose is installed.
8. Formatting follows the shared infrastructure and manual-formatting policies.
9. Windows installation and validation succeed.
10. Docker Engine and Buildx remain optional.
11. Missing optional dependencies do not prevent basic editing.
12. Existing language packs and shared infrastructure remain free from unnecessary duplication.
13. No credentials or secrets are introduced into the repository.
14. Required smoke tests pass.
15. Documentation reflects the final implementation and dependency decisions.

Optional features must be documented separately and must not block completion of the mandatory Docker editor baseline unless they are explicitly promoted into scope.

## 9. Final Architecture Summary

| Area | Decision |
|---|---|
| Support category | Infrastructure |
| Stage | Stage 13 — Language and Infrastructure Support |
| Configuration module | `lua/langs/docker.lua` |
| Language server | Docker Language Server |
| Language server status | Approved for Windows validation |
| LSP implementation | Native Neovim LSP |
| LSP configuration | `vim.lsp.config()` and `vim.lsp.enable()` |
| Dockerfile parser | Treesitter `dockerfile` |
| Compose parser | Existing Treesitter `yaml` |
| Bake parser | HCL support pending evaluation |
| Static analysis | Hadolint, optional and pending evaluation |
| Compose validation | Docker Compose CLI |
| Formatting | Shared Conform infrastructure where appropriate |
| Formatting workflow | Manual through `:Format` |
| Format-on-save | Disabled by default |
| Container runtime | Optional |
| Docker Compose CLI | Optional |
| Docker Buildx | Optional |
| Plugin management | Native `vim.pack` |
| LSP framework | Native Neovim LSP |
| Mason | Not permitted |
| lazy.nvim | Not permitted |
| Telemetry | Disabled where supported |
| Dependency installation | Explicit and user-controlled |
| Primary validation platform | Windows |

## 10. Architectural Principle

Docker editor support must remain independent of container runtime infrastructure.

Users must be able to edit, navigate, and maintain Dockerfiles and Docker Compose configurations without installing or running Docker Engine.

Docker Language Server provides the core language intelligence, while Treesitter supplies syntax parsing and the existing shared formatting infrastructure handles formatting where appropriate.

Docker Compose validation, Hadolint, Docker Buildx, and container runtime functionality remain independent external capabilities.

Optional dependencies must activate only when their corresponding tools are available. Their absence must never compromise basic Docker editing.

The implementation must preserve the project's native-first, modular, explicitly managed architecture.

---

**Document status:** Approved for Windows validation — implementation pending.

**Stage:** 13 — Language and Infrastructure Support.

**Support category:** Infrastructure.

**Implementation status:** Pending Windows validation and integration.
