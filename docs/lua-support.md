### 4.1 Lua

**Language pack:** `lua/langs/lua.lua`

Lua is the first core language pack and provides the baseline for the shared language architecture.

| Capability | Selection |
|---|---|
| Language server | LuaLS (`lua_ls`) |
| Formatter | StyLua |
| Linter | LuaCheck as an optional standalone CLI tool |
| Test framework | Busted as an optional external development dependency |
| Tree-sitter parser | `lua` |
| LSP configuration | Neovim native LSP API |

#### Language server

LuaLS is configured through Neovim's native LSP configuration and activation APIs.

The language pack:

- Uses LuaJIT as the runtime.
- Defines `vim` as a recognized global.
- Includes the Neovim runtime and `luv` library in the workspace library.
- Enables inlay hints.
- Disables LuaLS formatting because formatting is owned by the shared Conform workflow.
- Disables telemetry.
- Allows project-specific `.luarc.json` and `.luarc.jsonc` configuration to take precedence over shared defaults.
- Handles nullable initialization values, including `vim.NIL`, when resolving the workspace root.

Plugin-provided server definitions may be used where appropriate, but Neovim owns configuration and activation.

LuaLS is an external executable and is not installed automatically by the language pack.

#### Formatting

StyLua is the selected Lua formatter.

Formatting uses the shared Conform integration and the manual formatting workflow:

```vim
:Format
```

The associated mapping is:

```text
<leader>cf
```

Lua support does not introduce a separate formatting framework or enable format-on-save by default.

#### Lua execution mappings

Lua-specific execution mappings are registered through `lua/config/keymaps.lua` and are buffer-local to Lua buffers.

| Mapping | Description | Action |
|---|---|---|
| `<leader>cr` | Run Lua file | Execute the saved Lua file using `:luafile %`. |
| `<leader>cb` | Run Lua buffer | Execute the current buffer contents, including unsaved changes. |
| `<leader>ct` | Run Lua tests | Execute the project's Busted test suite. |

`<leader>cr` uses Neovim's native `:luafile %` command. The file must be saved before execution if the latest changes should be included.

`<leader>cb` uses Lua's `load()` and `pcall()` functions to execute the in-memory buffer contents. It does not require the file to be saved.

Compilation and runtime errors are reported through Neovim notifications.

These mappings intentionally share key sequences with other language packs. Their buffer-local registration ensures that the current filetype determines the action.

#### Busted test integration

Busted is the selected Lua test framework.

The test mapping invokes the `busted` executable from the detected Lua project root.

The runner:

- Checks whether Busted is available through `PATH`.
- Uses `.busted`, `.git`, and `spec` markers for project-root discovery.
- Runs Busted asynchronously through Neovim's `vim.system()` API.
- Displays standard output, standard error, and the process exit code in a bottom split.
- Reports successful and unsuccessful test runs.
- Schedules buffer updates and notifications through `vim.schedule()` to avoid calling Neovim UI APIs from a fast event context.

Busted's conventional test layout is:

```text
project/
├── .busted
└── spec/
    └── example_spec.lua
```

The conventional test filename pattern is `*_spec.lua`. Projects may customize test discovery through Busted configuration.

A project without discoverable test files must report the discovery failure rather than treating an empty test run as successful.

Busted is an optional external development dependency. It is not a Neovim plugin and is not installed automatically.

Install it separately:

```powershell
luarocks install busted
```

Verify the executable:

```powershell
busted --version
```

The executable must be available through Neovim's `PATH`.

Documentation: [Busted documentation](https://lunarmodules.github.io/busted/) and [Busted on LuaRocks](https://luarocks.org/modules/lunarmodules/busted).

#### LuaCheck

LuaCheck remains an optional standalone CLI tool.

It is not part of the LuaLS diagnostics workflow unless a separate integration and admission decision is made. Installing LuaCheck does not automatically enable editor diagnostics.

#### Validation

Lua support validation covers:

| Area | Validation |
|---|---|
| LuaLS | Initialization and workspace configuration |
| Formatter | StyLua selection and formatting |
| Tree-sitter | Lua parser availability and parsing |
| File execution | `<leader>cr` executes a saved Lua file |
| Buffer execution | `<leader>cb` executes unsaved buffer contents |
| Test execution | `<leader>ct` runs Busted and reports output and exit status |
| Missing dependency | Busted absence produces an actionable warning |
| Project isolation | Lua test discovery does not select unrelated nested projects |
| Regression | Syntax, formatting, and repository checks pass |

A temporary Lua fixture with a conventional `spec/` directory and `*_spec.lua` file is used to validate Busted independently of unrelated language projects.

Lua support is implemented. Runtime checks for the Lua execution mappings, Busted fixture, and LuaLS initialization have passed. Final repository-wide quality checks remain separate acceptance evidence.
