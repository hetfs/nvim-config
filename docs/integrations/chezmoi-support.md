# chezmoi Support and Integration

## 1. Purpose

This document defines the chezmoi integration baseline for the Neovim configuration project.

The objective is to provide a predictable way to deploy, maintain, and update the existing `nvim-config` repository across supported machines using chezmoi.

The integration must preserve the project's existing architecture and operational principles:

- Native-first Neovim configuration.
- Modular and explicit configuration loading.
- Native `vim.pack` plugin management.
- External dependency management through the existing installation workflow.
- No silent installation of development tools.
- No Mason-based dependency installation.
- No replacement of the existing Git workflow.
- No unnecessary coupling between chezmoi and Neovim startup.

chezmoi will manage the deployment location of the Neovim configuration repository. It will not manage the internal files of that repository.

## 2. Support Classification

chezmoi is classified as an **optional dotfile deployment and configuration-management integration**.

It is not a Neovim plugin, language server, formatter, or runtime dependency.

| Area | Decision |
|---|---|
| Support category | Dotfile deployment |
| Integration target | Existing `nvim-config` repository |
| Deployment tool | chezmoi |
| Repository type | Independent Git repository |
| Deployment mechanism | `git-repo` external |
| Target directory | `~/.config/nvim` |
| Plugin management | Native `vim.pack` |
| External tools | Existing dependency-management workflow |
| Windows support | Supported through native chezmoi |
| Linux support | Supported |
| macOS support | Supported |
| Required at runtime | No |
| Installation | Explicit external installation |

chezmoi must remain optional. A user must be able to clone `nvim-config` directly into the expected Neovim configuration directory and use it without installing chezmoi.

## 3. Integration Architecture

The existing `nvim-config` repository remains the authoritative source for Neovim configuration.

Repository:

https://github.com/hetfs/nvim-config

The recommended deployment architecture is:

```text
chezmoi source repository
        |
        | .chezmoiexternal.toml
        |
        v
chezmoi git-repo external
        |
        | Git clone / Git pull
        |
        v
~/.config/nvim
        |
        v
nvim-config repository
        |
        +-- init.lua
        +-- lua/
        +-- after/
        +-- ftplugin/
        +-- scripts/
        +-- docs/
        +-- mise.toml
        +-- nvim-pack-lock.json
```

The responsibilities remain separate.

| Component | Responsibility |
|---|---|
| chezmoi | Deploys the Neovim repository |
| Git | Tracks Neovim configuration history |
| `nvim-config` | Owns Neovim configuration |
| `vim.pack` | Manages Neovim plugins |
| `nvim-pack-lock.json` | Records plugin versions |
| mise | Manages declared external development tools |
| Installation scripts | Install explicitly approved external dependencies |
| Neovim | Loads and executes the configuration |

This separation prevents chezmoi from becoming another plugin manager or dependency installer.

## 4. Repository Management Strategy

### 4.1 Preserve the Existing Repository

The existing `nvim-config` repository must remain independent.

chezmoi should not copy the repository into its own source directory or convert the Neovim configuration into a collection of individually managed dotfiles.

The recommended approach is a `git-repo` external.

This approach provides:

- Independent Git history.
- Normal Git branches and commits.
- Existing repository structure.
- Existing development workflow.
- Independent releases and updates.
- No duplicated configuration files.

### 4.2 Why a Git External?

chezmoi supports external Git repositories through `.chezmoiexternal.toml`.

A Git external allows chezmoi to clone a repository into a specified destination directory and update an existing checkout through Git.

Official documentation:

https://www.chezmoi.io/user-guide/include-files-from-elsewhere/

A `git-repo` external delegates management of the repository's contents to Git. chezmoi cannot manage additional files inside that external directory.

This is desirable for `nvim-config` because the repository already has its own source-control workflow.

### 4.3 Approaches Not Selected

The following approaches are not part of the initial integration:

| Approach | Decision | Reason |
|---|---|---|
| Copy every Neovim file into chezmoi | Rejected | Duplicates the existing repository |
| Manage the entire Neovim directory with `exact_` | Rejected | Can remove unmanaged files and interfere with the existing checkout |
| Replace Git with chezmoi | Rejected | Removes the repository's independent development workflow |
| Use symlinks as the default deployment mechanism | Deferred | Adds unnecessary platform-specific behavior |
| Use a `git-repo` external | Approved as the proposed approach | Preserves repository ownership and Git history |

## 5. chezmoi External Configuration

The integration will use a `.chezmoiexternal.toml` file in the chezmoi source state.

### 5.1 Proposed Configuration

```toml
[".config/nvim"]
    type = "git-repo"
    url = "https://github.com/hetfs/nvim-config.git"
```

The external target is:

```text
~/.config/nvim
```

On Windows, the corresponding target is:

```text
%USERPROFILE%\.config\nvim
```

The default `refreshPeriod` is zero, which disables periodic refreshes. This is intentional for the initial integration.

The configuration does not automatically pull new changes during every chezmoi application.

Updates should remain explicit and controlled.

### 5.2 Optional Git Pull Configuration

If fast-forward-only updates are desired, the external can specify:

```toml
[".config/nvim"]
    type = "git-repo"
    url = "https://github.com/hetfs/nvim-config.git"

    [".config/nvim".pull]
        args = ["--ff-only"]
```

This prevents the external update operation from creating an unintended merge commit.

The pull configuration should be validated with the installed chezmoi version before adoption.

### 5.3 Existing Repository Handling

If `~/.config/nvim` does not exist, chezmoi can clone the repository.

If the directory already exists as a Git repository, chezmoi can use the existing checkout and perform a Git pull when the external is refreshed.

The working tree must be clean before an external update.

Local changes must be committed, stashed, or otherwise preserved through the normal Git workflow before refreshing the external.

The integration must never rely on chezmoi to resolve Git conflicts or preserve uncommitted changes.

## 6. Deployment Workflow

### 6.1 Initial Deployment

Install chezmoi using the official installation instructions:

https://www.chezmoi.io/install/

Initialize the existing dotfiles repository:

```bash
chezmoi init <dotfiles-repository>
```

Review the planned changes:

```bash
chezmoi status
chezmoi diff
```

Apply the configuration:

```bash
chezmoi apply
```

The expected result is:

```text
~/.config/nvim
```

containing the existing `nvim-config` repository.

The initial deployment must be reviewed before applying changes to an existing home directory.

### 6.2 Verify the Deployment

Check the repository:

```bash
git -C ~/.config/nvim status
```

Check its remote:

```bash
git -C ~/.config/nvim remote -v
```

Check the Neovim configuration:

```bash
nvim --version
```

Open Neovim and run:

```vim
:checkhealth
```

The configuration must load independently of chezmoi after deployment.

### 6.3 Updating Neovim Configuration

Normal Neovim development remains a Git operation.

```bash
cd ~/.config/nvim

git pull --ff-only
```

After updating, validate the configuration using the existing project checks.

chezmoi does not need to run for ordinary Neovim configuration changes.

### 6.4 Refreshing the External

When an explicit chezmoi refresh is required:

```bash
chezmoi apply --refresh-externals
```

This allows chezmoi to refresh configured external repositories.

The command must only be used when the target repository is ready for an update.

A normal `chezmoi apply` must not be treated as a Neovim configuration update command.

## 7. Windows Support

chezmoi provides native Windows installation and execution support.

Official installation documentation:

https://www.chezmoi.io/install/

The proposed Windows target is:

```text
%USERPROFILE%\.config\nvim
```

The integration must preserve the existing Windows development workflow.

### 7.1 Windows Requirements

The Windows environment must provide:

- chezmoi.
- Git.
- Neovim.
- Access to the `nvim-config` repository.
- The external development tools required by the configuration.

The Git executable must be available in `PATH` because chezmoi uses Git to manage `git-repo` externals.

### 7.2 PowerShell Deployment

The initial deployment can be performed from PowerShell:

```powershell
chezmoi init <dotfiles-repository>

chezmoi status
chezmoi diff

chezmoi apply
```

Verify the repository:

```powershell
$NvimConfig = Join-Path $HOME ".config\nvim"

git -C $NvimConfig status
git -C $NvimConfig remote -v

nvim --version
```

The integration must be validated on the project's supported Windows environment.

### 7.3 WSL2

WSL2 may use its own chezmoi installation and source directory.

The Windows and WSL2 environments must be treated as separate deployment targets unless a shared configuration arrangement is explicitly designed and tested.

The integration must not assume that a Windows Neovim configuration directory and a WSL2 Neovim configuration directory are interchangeable.

Each environment must resolve its own home directory and configuration target.

## 8. Linux and macOS Support

The same `git-repo` external can be used on Linux and macOS.

The target remains:

```text
~/.config/nvim
```

The external repository URL does not need to change between operating systems.

chezmoi should deploy the repository without modifying its internal configuration.

Platform-specific behavior must remain inside the existing Neovim configuration and external dependency-management workflow.

## 9. Integration Boundaries

chezmoi must not take responsibility for the following areas.

### 9.1 Plugin Management

Neovim plugins remain managed through native `vim.pack`.

chezmoi must not:

- Install Neovim plugins.
- Replace `vim.pack`.
- Manage the plugin lockfile.
- Introduce lazy.nvim.
- Run plugin installation during deployment.

### 9.2 External Dependencies

External tools remain managed through the project's existing dependency workflow.

This includes:

- Language servers.
- Formatters.
- Linters.
- Debug adapters.
- Treesitter CLI.
- Navigation utilities.
- Other command-line tools.

The existing `mise.toml` and installation scripts remain authoritative for these dependencies.

chezmoi may deploy the repository containing these declarations, but it must not silently install the tools.

### 9.3 Configuration Startup

chezmoi is not a Neovim runtime dependency.

The following command must continue to work after deployment:

```bash
nvim
```

Neovim must not execute chezmoi commands during startup.

### 9.4 Project Documentation

The Neovim repository continues to own its documentation, including:

- Installation instructions.
- External dependency requirements.
- Windows support.
- Language support.
- Plugin decisions.
- Configuration architecture.
- Validation procedures.

chezmoi-specific deployment instructions may be documented in a dedicated integration document without moving the project's existing documentation into another repository.

## 10. Security and Operational Requirements

The integration must follow safe configuration-management practices.

### 10.1 Review Before Applying

Use:

```bash
chezmoi status
chezmoi diff
```

before applying changes to an existing environment.

The user must review the proposed changes before allowing chezmoi to modify the home directory.

### 10.2 Secrets

No credentials, access tokens, private keys, or infrastructure secrets may be committed to the public `nvim-config` repository.

If a future chezmoi integration requires secrets, it must use an explicitly configured secret-management mechanism.

The initial integration does not require secret management.

### 10.3 Git State

The `nvim-config` checkout must remain a normal Git working tree.

The integration must not:

- Force-reset the repository.
- Automatically discard local changes.
- Rewrite Git history.
- Automatically commit changes.
- Automatically push changes.

### 10.4 External Updates

External repository updates must be explicit.

The initial configuration uses no periodic refresh.

A future refresh policy must be documented and tested before adoption.

## 11. Validation Requirements

The integration must pass the following tests before it is considered complete.

### 11.1 chezmoi Validation

- [ ] chezmoi installs successfully.
- [ ] `chezmoi doctor` reports no relevant environment problems.
- [ ] The source repository initializes successfully.
- [ ] `.chezmoiexternal.toml` is recognized.
- [ ] The external repository clones successfully.
- [ ] The target directory is correct.
- [ ] `chezmoi status` reports the expected state.
- [ ] `chezmoi diff` does not propose unintended changes.
- [ ] A normal `chezmoi apply` does not unexpectedly refresh the repository.

### 11.2 Git Validation

- [ ] The deployed directory is a Git repository.
- [ ] The remote points to `https://github.com/hetfs/nvim-config.git`.
- [ ] Git status works normally.
- [ ] Local commits remain intact.
- [ ] Fast-forward-only updates work if enabled.
- [ ] Refreshing the external does not discard local changes.

### 11.3 Neovim Validation

- [ ] Neovim starts from the deployed configuration.
- [ ] `init.lua` loads successfully.
- [ ] Explicit module loading remains unchanged.
- [ ] Native `vim.pack` works.
- [ ] `nvim-pack-lock.json` remains under the Neovim repository's control.
- [ ] External dependencies resolve through the existing workflow.
- [ ] Existing smoke tests pass.
- [ ] Neovim works without chezmoi installed or running.

### 11.4 Platform Validation

- [ ] Windows deployment works.
- [ ] Linux deployment works.
- [ ] macOS deployment works.
- [ ] WSL2 deployment is tested independently if supported.
- [ ] Each environment resolves the correct Neovim configuration directory.

## 12. Scope Boundaries

The initial integration covers repository deployment and maintenance.

The following capabilities are outside its scope:

- Replacing the existing `nvim-config` Git repository.
- Managing individual Neovim configuration files through chezmoi.
- Managing Neovim plugin installation.
- Installing external development tools.
- Managing Python or Node.js environments.
- Running Neovim configuration tests automatically during every chezmoi application.
- Automatically updating the Neovim repository.
- Managing private infrastructure credentials.
- Replacing the existing shell configuration project.
- Introducing another package manager.

These capabilities may be evaluated separately if future requirements justify them.

## 13. Completion Criteria

The chezmoi integration can be marked complete when:

1. The external repository configuration is implemented.
2. The existing `nvim-config` repository deploys to `~/.config/nvim`.
3. The repository retains its independent Git history and workflow.
4. Normal chezmoi application does not unexpectedly update the external.
5. Explicit external refresh works safely.
6. Windows deployment passes validation.
7. Linux deployment passes validation.
8. Neovim starts and passes existing configuration checks.
9. Plugin management remains under native `vim.pack`.
10. External dependencies remain under the existing installation workflow.
11. Neovim works without chezmoi at runtime.
12. Deployment instructions are documented.

## 14. Final Architecture Summary

| Area | Decision |
|---|---|
| Integration | chezmoi |
| Classification | Optional dotfile deployment |
| Neovim repository | `hetfs/nvim-config` |
| Repository ownership | Independent Git repository |
| Deployment mechanism | `git-repo` external |
| External configuration | `.chezmoiexternal.toml` |
| Target | `~/.config/nvim` |
| Windows target | `%USERPROFILE%\.config\nvim` |
| Plugin manager | Native `vim.pack` |
| Plugin lockfile | `nvim-pack-lock.json` |
| External tools | Existing mise and installation workflow |
| Automatic refresh | Disabled |
| Runtime dependency | None |
| Security | Review changes before applying |
| Approval | Proposed integration pending implementation and platform validation |

The integration keeps chezmoi responsible for deploying the Neovim repository while preserving the repository's independent development workflow.

It does not introduce another layer of plugin management, dependency installation, or Neovim startup orchestration.

**Final status: Proposed integration — chezmoi `git-repo` external is the recommended deployment strategy, pending implementation and Windows/Linux validation.**
