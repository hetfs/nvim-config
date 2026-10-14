
# nvim-config

A native-first, modular Neovim configuration built incrementally around Neovim's built-in capabilities.

> **Minimum installation. Compose the rest.**

The project prioritizes a minimal installation, explicit plugin evaluation, reproducible setup, and stage-by-stage validation.

## Requirements

- Neovim >= 0.12.0
- Git
- A supported operating system and shell

Additional external tools will be documented as the stages that require them are implemented.

## Design Principles

- **Native-first:** Prefer Neovim's built-in capabilities before adding plugins.
- **Native plugin management:** Use `vim.pack`, not `lazy.nvim`.
- **Modularity:** Keep modules and plugin specifications focused.
- **Explicit plugin admission:** Evaluate dependencies before accepting them.
- **Stage-aware implementation:** Introduce features only at their assigned stage.
- **Reproducibility:** Document requirements, dependencies, and decisions.
- **Testability:** Validate each stage before advancing.
- **Replaceability:** Retire or replace plugins when evidence justifies doing so.

## Current Stage

**Stage 02 — Keymaps and Autocommands: Complete**

This stage establishes:

- Native editor options.
- Centralized keymaps with descriptive `desc` values.
- A focused set of native autocommands.
- Direct loading of configuration modules.
- Syntax, formatting, and startup validation.

No plugins or additional external runtime dependencies are required at this stage.

## Repository Structure

```text
nvim-config/
├── init.lua
├── stylua.toml
├── README.md
├── lua/
│   └── config/
│       ├── options.lua
│       ├── keymaps.lua
│       └── autocmds.lua
└── scripts/
    ├── check-syntax.lua
    └── smoke.lua
```

The structure will expand as later stages introduce additional responsibilities.

## Validation

Run the following commands from the repository root.

### Check Lua syntax

```sh
nvim -l scripts/check-syntax.lua
```

The checker compiles discovered Lua files without executing their contents. It exits with status `0` if all files compile successfully and status `1` if syntax errors are found.

### Run the smoke test

```sh
nvim -u init.lua -l scripts/smoke.lua
```

The smoke test verifies the Neovim version, representative native options, module loading, keymaps, and autocommand registration.

### Check formatting

Install StyLua separately, then run:

```sh
stylua --check .
```

To apply formatting after making changes:

```sh
stylua .
```

Run the syntax check, smoke test, and formatting check after making changes.

## Roadmap

1. First Init
2. Keymaps and Autocommands
3. Modules
4. Native Workflows
5. `vim.pack`
6. which-key
7. Snacks Navigation
8. Treesitter
9. LSP
10. Completion and Snippets
11. Format and Lint
12. Git, Root, and Sessions
13. Language Packs
14. Debugging
15. UI Polish
16. Performance
17. Hardening

Each stage must meet its acceptance criteria before the project advances.

## Plugin Policy

A plugin is not accepted merely because it is popular or appears in another Neovim distribution.

Candidates must be evaluated for necessity, maintenance, compatibility, dependencies, architectural fit, and alternatives.

Accepted plugins may be deferred to their assigned stage. Plugins may also be retired or replaced when evidence justifies the change.

The project uses Neovim's native `vim.pack` rather than `lazy.nvim`.

## Contributing

Contributions should respect the architecture, roadmap, plugin admission policy, and testing requirements.

Changes should be focused, documented, and validated before a stage is marked complete.

## License

A license has not yet been established. Add a `LICENSE` file before distributing the project under an open-source license.
