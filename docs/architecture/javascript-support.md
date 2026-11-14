# JavaScript and TypeScript Support

## 1. Overview

The JavaScript and TypeScript integration provides language tooling and project-aware workflows for JavaScript-based development.

It supports:

- JavaScript
- JSX
- TypeScript
- TSX
- React
- React Native
- Expo
- Next.js

The architecture reuses the existing language infrastructure rather than introducing separate language packs, language servers, formatters, or completion engines for individual frameworks.

The integration follows the project's core philosophy:

**Minimum installation. Compose the rest.**

Its primary objectives are:

1. Preserve the existing JavaScript and TypeScript language foundations.
2. Provide consistent React, JSX, and TSX editing support.
3. Identify supported frameworks from project evidence.
4. Support project-aware development workflows.
5. Respect project-local dependencies and package-manager configuration.
6. Avoid automatic dependency installation and unnecessary framework-specific infrastructure.
7. Keep language configuration independent from project execution.

## 2. Architectural principles

### 2.1 Shared language foundation

JavaScript and TypeScript remain the owners of their respective language infrastructure.

The existing language packs provide:

- Language-specific configuration.
- Filetype support.
- Tree-sitter parser metadata.
- Formatter metadata.
- Language-server activation through the shared LSP integration.

React, React Native, Expo, and Next.js reuse this foundation.

No framework should introduce a duplicate language server, formatter, parser, or completion engine.

| Capability | Existing owner |
|---|---|
| Language configuration | JavaScript and TypeScript language packs |
| JSX and TSX parsing | Tree-sitter |
| Language intelligence | Shared VTSLS integration |
| Formatting | Conform |
| Completion | blink.cmp |
| Project detection | JavaScript project context |
| Framework classification | Framework detection |
| Package-manager resolution | Package-manager resolver |
| Script discovery | Package-script resolver |
| Script execution | Project workflow |
| Keymap registration | `lua/config/keymaps.lua` |

### 2.2 Framework ownership

Each technology has a defined responsibility.

| Technology | Responsibility |
|---|---|
| React | Shared JSX and TSX development support |
| React Native | Native mobile project context and workflows |
| Expo | Expo-specific project context and development workflows |
| Next.js | Next.js application context and development workflows |

React is a shared integration, not an independent language pack.

Expo extends the React Native ecosystem. An Expo project must not activate duplicate generic React Native workflows.

Next.js is independently detectable and may coexist with Expo or React Native classifications.

Framework detection should report the technologies declared by a package without assuming that they are mutually exclusive.

### 2.3 Separation of concerns

The integration separates four responsibilities:

1. Language infrastructure.
2. Project context discovery.
3. Framework classification.
4. Project workflow execution.

This prevents framework-specific behavior from leaking into language-server configuration or language-pack metadata.

A framework detector should not become a command runner. A language pack should not become a project manager.

## 3. Language infrastructure

### 3.1 JavaScript language pack

Location:

```text
lua/langs/javascript.lua
```

The JavaScript language pack owns JavaScript-specific metadata and activates the shared VTSLS integration.

Its responsibilities include:

- JavaScript and JSX formatter configuration.
- JavaScript Tree-sitter parser mappings.
- Shared language-server activation.

The current implementation is:

```lua
-- Stage 13: JavaScript language pack.
-- JavaScript owns its formatter and Tree-sitter parser metadata.
-- The shared vtsls integration owns server configuration and activation.

local M = {
  formatters = {
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
  },

  parser_by_filetype = {
    javascript = "javascript",
    javascriptreact = "javascript",
  },
}

function M.setup()
  require("lsp.servers.vtsls").setup()
end

return M
```

### 3.2 TypeScript language pack

The TypeScript language pack owns TypeScript-specific metadata.

It supports:

- TypeScript (`.ts`).
- TSX (`.tsx`).
- TypeScript formatter configuration.
- TypeScript and TSX Tree-sitter parser mappings.

Both JavaScript and TypeScript reuse the shared VTSLS integration.

### 3.3 Language support matrix

| Language | File extension | Filetype | Formatter | Tree-sitter parser |
|---|---|---|---|---|
| JavaScript | `.js` | `javascript` | Prettier | `javascript` |
| JSX | `.jsx` | `javascriptreact` | Prettier | `javascript` |
| TypeScript | `.ts` | `typescript` | Prettier | `typescript` |
| TSX | `.tsx` | `typescriptreact` | Prettier | `tsx` |

### 3.4 Language server

The shared VTSLS integration is located at:

```text
lua/lsp/servers/vtsls.lua
```

It owns the server configuration and activation for JavaScript and TypeScript.

The implementation uses Neovim's native LSP interfaces:

- `vim.lsp.config()`
- `vim.lsp.enable()`

It must not introduce the legacy `require("lspconfig")` setup pattern.

Framework-specific language-server configurations are outside the scope of this integration.

### 3.5 Formatting and completion

The existing shared integrations remain authoritative.

| Component | Responsibility |
|---|---|
| Conform | Formatting |
| blink.cmp | Completion |
| Tree-sitter | Syntax parsing |
| VTSLS | JavaScript and TypeScript language intelligence |

Prettier remains the configured formatter for JavaScript, JSX, TypeScript, and TSX.

Formatting follows the existing manual formatting policy. Framework detection must not introduce automatic format-on-save behavior.

## 4. Project context and framework detection

### 4.1 Purpose

Project context discovery identifies the package associated with the current buffer and provides information needed by project workflows.

Framework detection identifies the supported frameworks declared by that package.

These responsibilities provide useful project context without coupling framework identification to command execution.

### 4.2 Project evidence

Project context may use the following evidence:

- `package.json` files.
- Workspace manifests.
- Framework configuration files.
- Project-local scripts.
- Package-manager declarations.
- Package-manager lockfiles.

However, these sources have different responsibilities.

| Evidence | Responsibility |
|---|---|
| Nearest `package.json` | Package identity and declared dependencies |
| `dependencies` | Framework dependency evidence |
| `devDependencies` | Development dependency evidence |
| `optionalDependencies` | Optional framework dependency evidence |
| Framework configuration files | Additional project context |
| Package scripts | Available project operations |
| `packageManager` | Explicit package-manager declaration |
| Workspace lockfiles | Package-manager inference when declarations are absent |

**Framework classification must remain dependency-based.**

Configuration files, scripts, lockfiles, directory names, and globally installed CLIs must not independently establish that a package uses a particular framework.

This keeps classification deterministic and prevents unrelated files from producing false positives.

### 4.3 Package resolution

The nearest applicable `package.json` determines the current package context.

For example:

```text
workspace/
├── package.json
├── pnpm-workspace.yaml
└── packages/
    ├── mobile/
    │   ├── package.json
    │   └── src/
    │       └── index.js
    ├── web/
    │   ├── package.json
    │   └── src/
    │       └── index.js
    └── shared/
        └── package.json
```

When a buffer belongs to `packages/mobile`, the workflow must use the mobile package's dependencies and scripts.

It must not:

- Classify the package using dependencies declared only by `packages/web`.
- Execute scripts from a sibling package.
- Assume that every package in the workspace uses the same framework.

The workspace root is resolved separately for workspace-level metadata and package-manager discovery.

### 4.4 Dependency sections

Framework detection examines:

- `dependencies`
- `devDependencies`
- `optionalDependencies`

A dependency is considered declared when its package name exists in one of these sections.

The detector does not need the dependency to be installed.

It does not need to inspect `node_modules`.

It does not need to access the network.

## 5. Framework detection rules

The detection layer recognizes three framework classifications:

- Expo.
- React Native.
- Next.js.

Each framework has a dedicated detection flag.

### 5.1 Detection rules

| Dependency evidence | `expo` | `react_native` | `react_native_dependency` | `nextjs` |
|---|---:|---:|---:|---:|
| `expo` + `react-native` | `true` | `false` | `true` | `false` |
| `react-native` only | `false` | `true` | `true` | `false` |
| `next` only | `false` | `false` | `false` | `true` |
| `expo` + `react-native` + `next` | `true` | `false` | `true` | `true` |
| `expo` only | `true` | `false` | `false` | `false` |
| No matching dependencies | `false` | `false` | `false` | `false` |

The flags are independent except for the intentional Expo precedence rule applied to generic React Native classification.

### 5.2 Expo detection

A package is classified as an Expo project when it declares the `expo` dependency.

Example:

```json
{
  "dependencies": {
    "expo": "^54.0.0",
    "react-native": "0.81.0"
  }
}
```

Expected result:

```lua
{
  expo = true,
  react_native = false,
  react_native_dependency = true,
  nextjs = false,
}
```

**Rule:** If `expo` is declared, set `expo = true`.

Expo applications commonly declare React Native as a dependency. Therefore, the presence of `react-native` must not cause an Expo application to be classified as a generic React Native project.

Expo takes precedence for framework classification, but the underlying React Native dependency evidence must be preserved.

### 5.3 React Native detection

A package is classified as a generic React Native project when it declares `react-native` but does not declare `expo`.

Example:

```json
{
  "dependencies": {
    "react-native": "0.81.0"
  }
}
```

Expected result:

```lua
{
  expo = false,
  react_native = true,
  react_native_dependency = true,
  nextjs = false,
}
```

**Rule:** Set `react_native = true` only when `react-native` is declared and `expo` is not declared.

This distinguishes generic React Native classification from the presence of the React Native dependency itself.

### 5.4 Next.js detection

A package is classified as a Next.js project when it declares `next`.

Example:

```json
{
  "dependencies": {
    "next": "^16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
```

Expected result:

```lua
{
  expo = false,
  react_native = false,
  react_native_dependency = false,
  nextjs = true,
}
```

**Rule:** If `next` is declared, set `nextjs = true`.

Next.js detection is independent of Expo and React Native detection.

### 5.5 Preserve React Native dependency evidence

The detector must retain `react_native_dependency` separately from `react_native`.

These flags represent different concepts.

| Flag | Meaning |
|---|---|
| `react_native` | The package is classified as a generic React Native project. |
| `react_native_dependency` | The package explicitly declares the `react-native` dependency. |

For example, an Expo application may produce:

```lua
{
  expo = true,
  react_native = false,
  react_native_dependency = true,
  nextjs = false,
}
```

Retaining this distinction preserves dependency evidence for future integrations and workflow decisions.

### 5.6 Combined framework detection

Framework detection must support multiple matching dependencies in the same package.

For example:

```json
{
  "dependencies": {
    "expo": "^54.0.0",
    "react-native": "0.81.0",
    "next": "^16.0.0"
  }
}
```

Expected result:

```lua
{
  expo = true,
  react_native = false,
  react_native_dependency = true,
  nextjs = true,
}
```

The detection layer reports declared dependencies. It must not reject combinations or assume that supported frameworks are mutually exclusive.

This is important for monorepos and packages supporting multiple application targets.

### 5.7 Detection implementation

The framework detection function should remain small, deterministic, and independent of filesystem traversal.

```lua
local function javascript_frameworks(package_json)
  local dependencies = {}

  for _, section in ipairs({
    "dependencies",
    "devDependencies",
    "optionalDependencies",
  }) do
    for name in pairs(package_json[section] or {}) do
      dependencies[name] = true
    end
  end

  local frameworks = {
    expo = dependencies.expo == true,
    react_native_dependency = dependencies["react-native"] == true,
    nextjs = dependencies.next == true,
  }

  frameworks.react_native = frameworks.react_native_dependency
    and not frameworks.expo

  return frameworks
end
```

The function receives an already-resolved package manifest.

It must not:

- Search directories.
- Read package manifests.
- Traverse workspaces.
- Inspect sibling packages.
- Execute commands.
- Install dependencies.

Those responsibilities belong to their respective modules.

## 6. Package-manager resolution

### 6.1 Supported package managers

The workflow supports:

- npm
- pnpm
- Yarn
- Bun

Package-manager resolution must be deterministic and must respect the project's existing configuration.

### 6.2 Resolution priority

The resolution process follows this order:

1. Inspect the nearest package's `packageManager` declaration.
2. Inspect the workspace root's `packageManager` declaration when applicable.
3. If no explicit declaration exists, inspect recognized lockfiles at the workspace root.
4. If the available evidence is ambiguous, stop and notify the user.

An explicit declaration takes precedence over lockfile inference.

When package and workspace declarations conflict, the resolver must report the inconsistency rather than silently selecting one.

### 6.3 Recognized lockfiles

| Package manager | Lockfile |
|---|---|
| npm | `package-lock.json` |
| pnpm | `pnpm-lock.yaml` |
| Yarn | `yarn.lock` |
| Bun | `bun.lock` or `bun.lockb` |

Lockfile discovery should occur at the resolved workspace root, not indiscriminately across sibling packages.

### 6.4 Conflicting lockfiles

If multiple package-manager lockfiles exist and no explicit declaration resolves the conflict, the workflow must not guess.

Example:

```text
workspace/
├── package.json
├── pnpm-lock.yaml
└── yarn.lock
```

Expected behavior:

- Detect conflicting metadata.
- Display an actionable notification.
- Stop execution.
- Do not open a terminal.
- Do not choose a package manager arbitrarily.

### 6.5 Executable availability

Resolving a package manager does not guarantee that its executable is available.

Before execution, the workflow must check that the selected executable can be found.

If the executable is unavailable, the workflow should report the issue and stop.

It must not silently substitute another package manager or install the missing executable.

### 6.6 Corepack policy

Corepack must not be used as an implicit package-manager installation mechanism.

Corepack can download package-manager releases. This conflicts with the project's explicit dependency-management policy.

Any future Corepack integration must have an explicit, controlled policy that does not introduce unexpected network activity or automatic installation.

## 7. Project workflows

### 7.1 Workflow ownership

Project workflows are independent of language-server configuration and language-pack metadata.

Their responsibilities include:

- Resolving the current package.
- Identifying the workspace root.
- Reading package scripts.
- Resolving the package manager.
- Checking executable availability.
- Building platform-appropriate commands.
- Executing scripts in terminal buffers.

Framework detection provides project context to these workflows but does not own their execution.

### 7.2 Existing workflow mappings

The JavaScript and TypeScript integration provides five buffer-local mappings.

| Mapping | Action | Script resolution |
|---|---|---|
| `<leader>cR` | Start development | `dev`, then `start` |
| `<leader>ct` | Run tests | `test` |
| `<leader>cb` | Build project | `build` |
| `<leader>cl` | Run linting | `lint` |
| `<leader>cc` | Run type checking | `typecheck`, then `check` |

These mappings are registered through:

```lua
M.javascript(bufnr)
```

in:

```text
lua/config/keymaps.lua
```

Mappings must remain buffer-local and must be registered through the existing keymap architecture.

### 7.3 Package scripts as the source of truth

Framework detection must not generate commands such as:

```text
expo start
react-native start
next dev
```

Instead, workflows resolve existing scripts from the current package's `scripts` section.

For example, development resolves:

1. `dev`
2. `start`

The first existing, non-empty script is selected.

This approach supports:

- Custom project scripts.
- Different package managers.
- Different framework versions.
- Project-specific command arguments.
- Monorepo package boundaries.

The workflow must not invent a command when no matching script exists.

### 7.4 Missing scripts

If the requested script does not exist or is empty:

- Display a clear notification.
- Do not open a terminal.
- Do not start a process.
- Do not substitute an unrelated command.

### 7.5 Workspace isolation

The package containing the current buffer determines the script configuration and execution directory.

For example:

```text
workspace/
├── package.json
├── pnpm-workspace.yaml
└── packages/
    ├── mobile/
    │   └── package.json
    └── web/
        └── package.json
```

When executing a script from `packages/mobile`, the workflow must:

- Read scripts from `packages/mobile/package.json`.
- Resolve package-manager metadata using the workspace context.
- Execute from `packages/mobile`.
- Avoid executing scripts from `packages/web`.

This separation is essential for reliable monorepo behavior.

### 7.6 Framework-specific workflows

The architecture allows future framework-aware workflows without creating framework-specific language infrastructure.

Potential capabilities include:

| Framework | Potential workflow capabilities |
|---|---|
| React | React project navigation and development tasks |
| React Native | Metro development workflows and mobile project operations |
| Expo | Expo development and platform-specific workflows |
| Next.js | Development, production build, and application workflows |

These are potential capabilities, not a requirement to introduce framework-specific commands immediately.

The implementation should first reuse existing package scripts and shared workflow infrastructure.

## 8. Terminal execution and platform compatibility

### 8.1 Execution requirements

The workflow executes package scripts in terminal buffers.

Execution must preserve:

- The selected package manager.
- The selected package script.
- The package directory as the working directory.
- Correct argument boundaries.
- Platform-specific executable handling.

### 8.2 Windows execution

On Windows, package-manager executables may resolve to `.cmd` shims.

These require appropriate `cmd.exe` handling and argument quoting.

The implementation must support:

- Paths containing spaces.
- Package-manager executables resolved through Windows shims.
- Script arguments with correct boundaries.
- Correct working-directory selection.

Command construction must not rely on blindly concatenating untrusted path or argument strings.

Windows-specific behavior must be validated on an actual Windows environment.

### 8.3 Cross-platform behavior

The workflow should preserve the same logical behavior across supported platforms.

Platform-specific differences should be isolated in command construction and process execution rather than duplicated throughout the project workflow.

## 9. Dependency and plugin policy

The integration reuses existing infrastructure.

| Capability | Existing dependency or integration |
|---|---|
| Language intelligence | VTSLS |
| Syntax parsing | Tree-sitter |
| Formatting | Conform |
| Completion | blink.cmp |
| Plugin management | Native `vim.pack` |

The following rules apply:

1. Reuse the existing language packs.
2. Reuse existing LSP infrastructure.
3. Reuse existing formatter resolution.
4. Respect project-local dependencies.
5. Do not install npm packages automatically.
6. Do not download package managers automatically.
7. Do not introduce Mason.
8. Do not introduce duplicate framework-specific language servers.
9. Keep language-pack activation explicit.
10. Keep plugin loading eager until the planned lazy-loading stage.

Missing dependencies must produce actionable diagnostics rather than trigger automatic installation.

## 10. Debugging integration

Debugging integration belongs to Stage 14.

Stage 13 must not introduce a framework-specific debugger.

Future debugging support should reuse the project's shared debugging architecture and should not create separate language infrastructure for Expo, React Native, or Next.js without a concrete technical requirement.

The framework context established by this integration may inform future debugging workflows.

## 11. Architectural boundaries

The following ownership boundaries should remain explicit.

| Responsibility | Owner |
|---|---|
| JavaScript and TypeScript language metadata | Language packs |
| JSX and TSX parser configuration | Language packs and Tree-sitter |
| Language-server configuration | Shared VTSLS integration |
| Formatting | Shared Conform integration |
| Completion | Shared blink.cmp integration |
| Resolve nearest `package.json` | JavaScript project context |
| Resolve workspace root | Project context |
| Read declared dependencies | Package context |
| Detect Expo, React Native, and Next.js | Framework detection |
| Inspect framework configuration files | Project context, when needed |
| Resolve package manager | Package-manager resolver |
| Discover package scripts | Package-script resolver |
| Execute package scripts | Project workflow |
| Register buffer-local mappings | `M.javascript(bufnr)` |

### 11.1 Non-goals

The current integration does not aim to:

- Determine whether a package is an application or a library.
- Detect every JavaScript framework.
- Infer frameworks from directory names.
- Classify a framework using sibling package dependencies.
- Generate framework commands when package scripts are missing.
- Install project dependencies.
- Install or download package managers.
- Manage framework SDK versions.
- Replace package-level configuration.
- Replace existing project-management tools.
- Create independent language packs for React, React Native, Expo, or Next.js.
- Introduce framework-specific debugging during Stage 13.

These capabilities should be considered only when a concrete workflow requires them.

## 12. Testing strategy

Testing must cover language infrastructure, framework classification, package context, package-manager resolution, and actual workflow execution.

### 12.1 Language foundation tests

Validate that existing JavaScript and TypeScript functionality remains unchanged.

| Test | Expected result |
|---|---|
| JavaScript language pack | Enabled through the language registry |
| TypeScript language pack | Enabled through the language registry |
| JavaScript formatter | Prettier |
| JSX formatter | Prettier |
| TypeScript formatter | Prettier |
| TSX formatter | Prettier |
| JavaScript parser | `javascript` |
| JSX parser | `javascript` |
| TypeScript parser | `typescript` |
| TSX parser | `tsx` |
| VTSLS | Shared integration is activated correctly |

### 12.2 Framework detection tests

| Test case | Expected result |
|---|---|
| Expo and React Native declared | Expo detected; React Native dependency retained; generic React Native classification disabled |
| React Native only | Generic React Native detected |
| Next.js only | Next.js detected |
| Expo, React Native, and Next.js | Expo and Next.js detected; React Native dependency retained |
| Expo only | Expo detected |
| No matching dependencies | All framework flags are `false` |
| Dependency in `devDependencies` | Dependency detected |
| Dependency in `optionalDependencies` | Dependency detected |
| Dependency absent from supported sections | Dependency not detected |
| Dependency declared only in sibling package | Must not affect the current package |

### 12.3 Project context tests

Validate:

- Nearest package manifest resolution.
- Workspace root resolution.
- Nested package isolation.
- Workspace package-manager metadata.
- Correct execution directory.
- No sibling-package contamination.

### 12.4 Package-manager tests

Validate:

- Explicit package-manager declaration.
- Workspace-level package-manager declaration.
- Lockfile-based inference.
- Conflicting lockfiles.
- Conflicting package-manager declarations.
- Missing executable.
- No implicit Corepack downloads.
- Supported npm, pnpm, Yarn, and Bun resolution.

### 12.5 Workflow tests

Validate:

| Test case | Expected behavior |
|---|---|
| Development script exists | Resolve `dev` |
| Development script missing, `start` exists | Resolve `start` |
| Test script exists | Resolve `test` |
| Build script exists | Resolve `build` |
| Lint script exists | Resolve `lint` |
| Type-check script missing, `check` exists | Resolve `check` |
| Requested script missing | Notify without opening a terminal |
| Requested script empty | Notify without starting a process |
| Package manager unavailable | Stop execution |
| Package-manager metadata ambiguous | Stop execution |
| Nested package workflow | Execute from the nearest package root |

### 12.6 Windows execution tests

Validate `.cmd` package-manager shims using a project directory containing spaces.

The tests must confirm:

- Executable resolution.
- Correct command construction.
- Correct argument boundaries.
- Correct working directory.
- Successful script execution.

These tests require real Windows validation. A Unix-based test cannot establish that Windows `cmd.exe` quoting and `.cmd` shim handling work correctly.

### 12.7 Interactive regression tests

Headless tests are not sufficient for every workflow behavior.

Interactive checks should verify:

- Buffer-local mapping registration.
- Correct mapping descriptions.
- Terminal buffer creation.
- Notifications.
- Script execution.
- Correct working directory.
- Behavior when switching between packages in a monorepo.

### 12.8 Test environment

Workflow integration tests should use a standalone JavaScript workspace outside the `nvim-config` repository.

The fixture should include:

- An Expo package.
- A React Native package.
- A Next.js package.
- A package containing Expo and Next.js dependencies.
- A plain JavaScript package.
- A conflicting-lockfile scenario.
- A missing-script scenario.
- A Windows path containing spaces.

The test environment should not require framework dependencies to be installed for metadata detection tests.

No automatic dependency installation or network access should be necessary.

## 13. Implementation order

Implementation should progress incrementally, preserving the existing Stage 13 architecture.

| Order | Task | Objective |
|---:|---|---|
| 1 | Validate existing JavaScript and TypeScript foundations | Preserve current functionality |
| 2 | Validate React JSX and TSX support | Confirm shared language infrastructure |
| 3 | Implement React Native project detection | Establish mobile project context |
| 4 | Extend detection with Expo | Preserve Expo precedence |
| 5 | Implement Next.js project detection | Support independent Next.js classification |
| 6 | Validate combined framework detection | Support multiple frameworks in one package |
| 7 | Validate package and workspace resolution | Ensure monorepo isolation |
| 8 | Implement deterministic package-manager resolution | Respect project configuration |
| 9 | Validate project-script workflows | Execute existing scripts safely |
| 10 | Validate Windows execution | Confirm `.cmd` handling |
| 11 | Add automated regression tests | Protect established behavior |
| 12 | Complete interactive checks | Validate real Neovim workflows |

Each task should be tested before introducing additional responsibilities.

## 14. Compatibility and project constraints

| Area | Requirement |
|---|---|
| Minimum Neovim version | 0.12 |
| Plugin management | Native `vim.pack` |
| Language-pack activation | Explicit registry |
| Language-server integration | Native `vim.lsp.config()` and `vim.lsp.enable()` |
| Formatter resolution | Existing shared resolver |
| Completion | Existing blink.cmp integration |
| External dependencies | User-managed |
| Package installation | Never automatic |
| Package-manager downloads | Never implicit |
| Lazy loading | Deferred until Stage 16 |
| Debugging | Stage 14 |

The existing language-pack registry remains authoritative.

The existing formatter resolution remains authoritative.

No framework integration should bypass these established ownership boundaries.

## 15. Acceptance criteria

The integration is considered complete when the following conditions are satisfied.

### Language infrastructure

- Existing JavaScript functionality remains unchanged.
- Existing TypeScript functionality remains unchanged.
- JSX and TSX use the correct parser metadata.
- JavaScript and TypeScript reuse VTSLS.
- Formatting uses the existing Conform integration.
- Completion uses the existing blink.cmp integration.

### Framework support

- React editing support works through the shared language foundation.
- React Native projects are detected correctly.
- Expo projects are identified without generic React Native misclassification.
- React Native dependency evidence is preserved.
- Next.js projects are detected correctly.
- Multiple framework classifications can coexist.

### Project workflows

- The nearest package manifest determines the current package.
- Workspace metadata is resolved independently.
- Package scripts execute from the correct package directory.
- Package-manager resolution is deterministic.
- Missing scripts produce actionable notifications.
- Missing executables stop execution.
- Conflicting metadata never results in arbitrary selection.
- Windows `.cmd` execution works with paths containing spaces.

### Safety and maintainability

- No automatic package installation occurs.
- No implicit package-manager downloads occur.
- No framework-specific language infrastructure is duplicated.
- Language-pack activation remains explicit.
- Existing configuration ownership boundaries are preserved.
- Automated smoke tests pass.
- Interactive regression checks pass.

## 16. Current implementation status

The following status distinguishes existing implementation decisions from work that still requires validation.

| Area | Status |
|---|---|
| JavaScript language pack | Implemented |
| TypeScript language pack | Existing shared foundation |
| VTSLS integration | Existing shared integration |
| Prettier formatter metadata | Implemented |
| Tree-sitter parser metadata | Implemented |
| JavaScript workflow mappings | Implemented locally |
| Framework detection rules | Defined |
| Package-manager resolution | Implementation requires regression validation |
| Workspace isolation | Requires regression validation |
| Windows `.cmd` execution | Requires real Windows validation |
| Standalone test workspace | Planned; creation paused |
| Complete automated workflow validation | Pending |
| Interactive regression validation | Pending |
| Framework-specific debugging | Deferred to Stage 14 |
| Lazy loading | Deferred to Stage 16 |

The standalone test workspace is intentionally separate from the configuration repository. Its creation and validation are pending and must not be treated as completed.

## 17. Design principle

JavaScript and TypeScript support should remain language-oriented at the configuration level and project-oriented at the workflow level.

Language packs describe how Neovim supports a language.

Project context describes the package and workspace associated with the current buffer.

Framework detection identifies declared framework dependencies.

Project workflows interact with the existing project configuration.

These responsibilities should remain independent while sharing well-defined interfaces.

**Detect declared dependencies, preserve the evidence, resolve project context deterministically, and execute only the commands that the project explicitly provides.**
