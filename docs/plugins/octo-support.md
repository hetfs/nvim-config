# Octo.nvim Support

| Field | Value |
|---|---|
| Project | `nvim-config` |
| Document | `docs/architecture/octo-support.md` |
| Status | Implementation in progress |
| Target Neovim version | 0.13 |
| Minimum Neovim version | 0.12 |
| Plugin | `octo.nvim` |
| Repository | <https://github.com/pwntester/octo.nvim> |
| Audience | Maintainers and contributors |

## 1. Purpose

This document defines the architecture, installation requirements, configuration, workflows, keymaps, and validation procedures for Octo.nvim.

Octo.nvim integrates GitHub workflows into Neovim. It provides an interface for managing issues, pull requests, discussions, comments, reactions, and pull request reviews without leaving the editor.

The integration follows the project's native-first architecture:

- Use `vim.pack.add()` for plugin installation.
- Keep plugin configuration in `lua/plugins/octo.lua`.
- Load the plugin explicitly from `init.lua`.
- Keep global keymaps in `lua/config/keymaps.lua`.
- Use the existing Snacks Picker integration.
- Use GitHub CLI (`gh`) for GitHub authentication and API operations.
- Avoid introducing another plugin manager or dependency-management framework.

## 2. Scope and responsibilities

Octo.nvim owns GitHub collaboration workflows.

| Component | Responsibility |
|---|---|
| Octo.nvim | GitHub issues, pull requests, discussions, reviews, and notifications |
| GitHub CLI (`gh`) | Authentication and communication with GitHub |
| `plenary.nvim` | Asynchronous job execution and shared Lua utilities |
| Snacks Picker | Interactive selection and search |
| Gitsigns | Local Git changes, hunks, staging, and blame |
| Diffview | Local Git diffs and file history |

Octo.nvim does not replace Gitsigns or Diffview.

The responsibilities remain separate:

- Use Gitsigns to inspect and manage local Git changes.
- Use Diffview to inspect local commits and file history.
- Use Octo.nvim to interact with GitHub-hosted issues and pull requests.

## 3. Requirements

### 3.1 Neovim

The project targets Neovim 0.13 and maintains compatibility with Neovim 0.12.

Octo.nvim requires Neovim 0.10 or newer.

### 3.2 GitHub CLI

GitHub CLI is a required external dependency.

Official website: <https://cli.github.com/>

On Windows, install it with WinGet:

```powershell
winget install --id GitHub.cli --exact
```

Verify the installation:

```powershell
gh --version
Get-Command gh
```

Neovim must be able to locate the executable through its inherited `PATH`.

Verify this inside Neovim:

```vim
:echo executable('gh')
:echo exepath('gh')
```

Expected result:

- `executable('gh')` returns `1`.
- `exepath('gh')` returns the path to `gh.exe`.

### 3.3 GitHub authentication

Octo.nvim relies on GitHub CLI authentication.

Authenticate with:

```powershell
gh auth login
```

Recommended interactive choices:

1. GitHub.com.
2. Login with a web browser.
3. HTTPS for Git operations.
4. Authenticate Git with GitHub credentials.

Verify authentication:

```powershell
gh auth status
```

The active GitHub account must be authenticated before using Octo.nvim.

Never place personal access tokens or authentication credentials in the Neovim configuration.

### 3.4 Lua dependencies

Octo.nvim requires:

| Dependency | Requirement | Purpose |
|---|---|---|
| `plenary.nvim` | Required | Shared Lua utilities and asynchronous jobs |
| `snacks.nvim` | Existing project dependency | Picker integration |
| `fzf-lua` | Existing project dependency | Alternative picker integration |
| `nvim-web-devicons` | Optional | File panel icons |

The project uses Snacks as the default picker.

The file panel uses `icons = false`, so `nvim-web-devicons` is not required.

**Dependency ownership:** `plenary.nvim` must remain available independently of optional integrations such as CodeCompanion. Octo.nvim must not depend on an AI provider being enabled.

## 4. Plugin installation

Create:

`lua/plugins/octo.lua`

```lua
-- GitHub integration.
-- Manage GitHub issues, pull requests, reviews, and discussions.

vim.pack.add({
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
    name = "plenary.nvim",
  },
  {
    src = "https://github.com/pwntester/octo.nvim",
    name = "octo.nvim",
  },
})

require("octo").setup({
  picker = "snacks",
  enable_builtin = true,

  default_remote = {
    "upstream",
    "origin",
  },

  default_merge_method = "squash",
  default_delete_branch = false,

  file_panel = {
    icons = false,
  },
})
```

### Configuration decisions

| Option | Value | Reason |
|---|---|---|
| `picker` | `"snacks"` | Reuse the existing Snacks Picker integration |
| `enable_builtin` | `true` | Enable Octo's built-in action interface |
| `default_remote` | `{"upstream", "origin"}` | Check the configured remotes when resolving the repository |
| `default_merge_method` | `"squash"` | Use squash as the default merge strategy |
| `default_delete_branch` | `false` | Avoid automatically deleting branches after merging |
| `file_panel.icons` | `false` | Avoid requiring an additional icon dependency |

The `file_panel.icons` option accepts a Boolean or an icon-provider function. Do not configure it as a table.

## 5. Plugin loading

Load Octo.nvim explicitly from `init.lua`.

Place it in the GitHub integration section, after the existing Snacks and FzfLua integrations have loaded:

```lua
-- GitHub integration.
require("plugins.octo")
```

The plugin must load after `plugins.snacks` because the configured picker is Snacks.

Keep the existing plugin loading architecture. Do not introduce automatic plugin discovery.

## 6. Keymaps

Global Octo keymaps belong in:

`lua/config/keymaps.lua`

Use the existing `<leader>o` namespace for GitHub workflows.

```lua
-- ============================================================
-- GitHub (Octo)
-- ============================================================

map("n", "<leader>oi", "<cmd>Octo issue list<CR>", {
  desc = "GitHub: List issues",
})

map("n", "<leader>op", "<cmd>Octo pr list<CR>", {
  desc = "GitHub: List pull requests",
})

map("n", "<leader>od", "<cmd>Octo discussion list<CR>", {
  desc = "GitHub: List discussions",
})

map("n", "<leader>on", "<cmd>Octo notification list<CR>", {
  desc = "GitHub: List notifications",
})

map("n", "<leader>os", function()
  require("octo.utils").create_base_search_command({
    include_current_repo = true,
  })
end, {
  desc = "GitHub: Search",
})
```

### Keymap reference

| Mapping | Action |
|---|---|
| `<leader>oi` | List GitHub issues |
| `<leader>op` | List pull requests |
| `<leader>od` | List discussions |
| `<leader>on` | List notifications |
| `<leader>os` | Start GitHub search |

Octo also provides context-specific mappings inside its buffers. Use `<CR>` to access available actions.

Verify global mappings:

```vim
:verbose nmap <leader>oi
:verbose nmap <leader>op
:verbose nmap <leader>od
:verbose nmap <leader>on
:verbose nmap <leader>os
```

## 7. Supported workflows

### 7.1 Issues

List issues:

```vim
:Octo issue list
```

Create an issue:

```vim
:Octo issue create
```

Open an issue:

```vim
:Octo issue edit 1
```

Close the current issue:

```vim
:Octo issue close
```

Reopen the current issue:

```vim
:Octo issue reopen
```

Filter issues:

```vim
:Octo issue list states=OPEN
:Octo issue list labels=bug
:Octo issue list createdBy=hetfs
```

### 7.2 Pull requests

List pull requests:

```vim
:Octo pr list
```

Open a pull request:

```vim
:Octo pr edit 1
```

Review the current pull request:

```vim
:Octo review
```

Inspect pull request changes:

```vim
:Octo pr changes
```

Inspect CI checks:

```vim
:Octo pr checks
```

Merge the current pull request:

```vim
:Octo pr merge squash
```

Review workflows should be completed deliberately. Do not merge a pull request without inspecting its changes and checks.

### 7.3 Discussions

List discussions:

```vim
:Octo discussion list
```

Create a discussion:

```vim
:Octo discussion create
```

Open a discussion:

```vim
:Octo discussion edit
```

Octo also supports replying to discussions, managing subscriptions, changing categories, and marking answers.

### 7.4 Notifications

List GitHub notifications:

```vim
:Octo notification list
```

### 7.5 Open a GitHub URL

Open an issue or pull request directly:

```vim
:Octo https://github.com/OWNER/REPOSITORY/issues/1
```

```vim
:Octo https://github.com/OWNER/REPOSITORY/pull/1
```

Octo also supports direct `octo://` buffer paths:

```vim
:e octo://OWNER/REPOSITORY/issue/1
:e octo://OWNER/REPOSITORY/pull/1
```

This is useful when opening GitHub resources from notes or other project documentation.

## 8. Pull request review workflow

Octo provides an integrated pull request review interface.

Recommended workflow:

1. Open a pull request using `:Octo pr list` or a GitHub URL.
2. Run `:Octo review` to enter review mode.
3. Inspect the changed files.
4. Navigate between files with `]q` and `[q`.
5. Review the diff and surrounding code.
6. Add comments to relevant lines.
7. Add suggestions where appropriate.
8. Inspect pending review comments.
9. Submit the review when ready.

Useful commands:

```vim
:Octo review start
:Octo review comments
:Octo review submit
:Octo review discard
```

Review submission supports commenting, approving, and requesting changes.

Treat review submission and pull request merging as explicit user actions.

## 9. Authentication scopes

GitHub CLI manages the authentication token used by Octo.

The existing authenticated account has these scopes:

- `gist`
- `read:org`
- `repo`
- `workflow`

These scopes support the current repository and collaboration workflows.

GitHub Projects v2 requires additional permissions.

For read access:

```powershell
gh auth refresh -s read:project
```

For project modifications:

```powershell
gh auth refresh -s project
```

Only request additional scopes when the corresponding functionality is needed.

## 10. Validation

Octo must pass the following checks before the integration is considered complete.

### 10.1 External dependency checks

Run in PowerShell:

```powershell
gh --version
gh auth status
Get-Command gh
```

Expected:

- GitHub CLI is installed.
- The active GitHub account is authenticated.
- PowerShell resolves `gh.exe`.

### 10.2 Neovim dependency checks

Run inside Neovim:

```vim
:echo executable('gh')
:echo exepath('gh')
:checkhealth octo
```

Expected:

- `executable('gh')` returns `1`.
- The executable path is valid.
- Octo reports successful setup and dependency checks.

### 10.3 Plugin loading

Restart Neovim and confirm that:

- Octo loads without startup errors.
- Plenary is available.
- Snacks Picker is available.
- The configured file panel does not require an icon provider.

### 10.4 Functional tests

| Test | Expected result |
|---|---|
| `:Octo` | Opens the built-in Octo action interface |
| `:Octo issue list` | Displays GitHub issues |
| `:Octo pr list` | Displays pull requests |
| `:Octo discussion list` | Displays discussions |
| `:Octo notification list` | Displays notifications |
| `:Octo issue create` | Opens the issue creation workflow |
| Open an issue URL | Displays the selected issue |
| Open a pull request URL | Displays the selected pull request |
| `<CR>` in an Octo buffer | Displays available contextual actions |

### 10.5 Keymap regression tests

Verify the Octo mappings:

```vim
:verbose nmap <leader>oi
:verbose nmap <leader>op
:verbose nmap <leader>od
:verbose nmap <leader>on
:verbose nmap <leader>os
```

Also verify that existing Git mappings remain available:

```vim
:verbose nmap <leader>gD
:verbose nmap <leader>gH
:verbose nmap <leader>gq
```

Octo must not overwrite Gitsigns or Diffview mappings.

## 11. Troubleshooting

### 11.1 `gh: Executable not found`

Example:

```text
plenary/job.lua:108: gh: Executable not found
```

Cause:

Neovim cannot locate the GitHub CLI executable.

Resolution:

```powershell
gh --version
Get-Command gh
```

Then restart the terminal and Neovim.

Inside Neovim:

```vim
:echo executable('gh')
:echo exepath('gh')
```

If the result is `0`, inspect the inherited environment:

```vim
:echo $PATH
```

Ensure the GitHub CLI installation directory is included in the Windows `PATH`.

### 11.2 GitHub authentication errors

Verify the authenticated account:

```powershell
gh auth status
```

If authentication has expired or is missing:

```powershell
gh auth login
```

Octo requires GitHub CLI credentials that are accessible to subprocesses. Avoid relying on credentials available only in an unrelated shell session.

### 11.3 Missing Projects v2 scope

If Octo reports:

```text
Cannot request projects v2, missing scope 'read:project'
```

Refresh the authentication token:

```powershell
gh auth refresh -s read:project
```

Do not request project permissions unless Projects v2 functionality is required.

### 11.4 Incorrect file panel icon configuration

Invalid configuration:

```lua
file_panel = {
  icons = {
    enabled = false,
  },
}
```

Correct configuration:

```lua
file_panel = {
  icons = false,
}
```

The option accepts a Boolean or a function, not a table.

### 11.5 Picker integration problems

Confirm that Snacks loads before Octo:

```lua
require("plugins.snacks")
require("plugins.octo")
```

Confirm that the Snacks Picker is enabled:

```lua
require("snacks").setup({
  picker = {
    enabled = true,
  },
  explorer = {
    enabled = true,
    replace_netrw = true,
  },
})
```

### 11.6 SSH remote aliases

If the Git remote uses a custom SSH alias, configure the corresponding alias mapping in Octo:

```lua
require("octo").setup({
  ssh_aliases = {
    ["github-work"] = "github.com",
  },
})
```

Replace the example alias with the actual alias from the user's SSH configuration.

## 12. Security requirements

The integration must follow these rules:

- Do not store GitHub tokens in Lua files.
- Do not commit authentication credentials.
- Use GitHub CLI's supported authentication mechanism.
- Request only the scopes required by enabled workflows.
- Review changes before submitting pull request reviews.
- Treat pull request merging and issue closure as explicit actions.
- Do not expose authentication output in logs or shared diagnostics.

## 13. Maintenance requirements

When updating Octo.nvim:

1. Review the upstream changelog and configuration documentation.
2. Check for changes to GitHub CLI requirements.
3. Validate the plugin against the supported Neovim versions.
4. Verify picker compatibility with the installed Snacks version.
5. Check for changes to command names and keymap APIs.
6. Run the validation checklist.
7. Update this document when configuration or workflows change.

Do not introduce another picker or icon plugin unless an actual requirement justifies it.

## 14. Acceptance criteria

Octo.nvim is considered fully integrated when:

- [x] Octo.nvim is registered through `vim.pack.add()`.
- [x] GitHub CLI is installed.
- [x] GitHub CLI authentication succeeds.
- [x] Plenary is available independently of optional AI integrations.
- [x] Snacks is configured as the picker.
- [x] File panel icons are disabled without requiring an icon provider.
- [ ] Neovim successfully resolves `gh.exe`.
- [ ] `:checkhealth octo` passes.
- [ ] Issue listing works.
- [ ] Pull request listing works.
- [ ] Discussion listing works.
- [ ] Notification listing works.
- [ ] GitHub URL opening works.
- [ ] Global keymaps pass inspection.
- [ ] Existing Gitsigns and Diffview mappings remain unaffected.
- [ ] Pull request review workflow is validated.

The integration remains in progress until the outstanding runtime and functional checks pass.

## 15. References

- [Octo.nvim repository](https://github.com/pwntester/octo.nvim)
- [Octo.nvim README](https://github.com/pwntester/octo.nvim/blob/master/README.md)
- [Octo.nvim documentation](https://github.com/pwntester/octo.nvim/blob/master/doc/octo.txt)
- [GitHub CLI](https://cli.github.com/)
- [GitHub CLI manual](https://cli.github.com/manual/)
- [GitHub CLI authentication](https://cli.github.com/manual/gh_auth)
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [Snacks.nvim](https://github.com/folke/snacks.nvim)

---

**Design principle:** Octo.nvim provides GitHub collaboration inside Neovim while preserving the project's native Git, editor, and plugin-management architecture.
