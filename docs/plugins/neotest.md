# Neotest

> **Document status:** Refreshed on 2026-11-25. This document records
> the current design and observed test evidence. Proposed registry and
> run-helper revisions are explicitly marked as unvalidated.

Neotest provides a unified test discovery, execution, and
result-management workflow inside Neovim. It integrates
language-specific test frameworks through adapters while providing a
consistent interface for running tests, inspecting results, and
monitoring test changes.

The integration follows the native-first principles of `nvim-config`.
Neovim manages the editor workflow, Neotest orchestrates testing, and
external test runners execute the tests.

## 1. Architecture

### 1.1 Overview

The integration consists of five main components:

  -----------------------------------------------------------------------
  Component                           Responsibility
  ----------------------------------- -----------------------------------
  Neotest                             Test discovery, orchestration,
                                      execution, and result presentation

  Adapter registry                    Detects applicable projects and
                                      registers their adapters

  Language adapters                   Connect Neotest to
                                      language-specific test frameworks

  External test runners               Discover and execute tests

  Neovim                              Provides keymaps, windows,
                                      diagnostics, and editor integration
  -----------------------------------------------------------------------

The execution flow is:

``` text
Neovim
  │
  ▼
Neotest entry point
  │
  ▼
Core initialization
  │
  ├── Package installation
  │     └── vim.pack.add()
  │
  ├── Neotest configuration
  │     └── neotest.setup()
  │
  └── Adapter registry
        │
        ├── Project detection
        │
        ├── Root resolution
        │
        ├── Adapter selection
        │
        └── Project registration
              └── neotest.setup_project()
                    │
                    ▼
                 Test discovery
                    │
                    ▼
                 Test execution
                    │
                    ▼
                 Result presentation
```

### 1.2 Design principles

-   **Native-first:** Use Neovim's built-in capabilities wherever
    practical.
-   **Modular:** Keep core initialization, installation, adapter
    registration, and language-specific configuration separate.
-   **Project-scoped:** Register adapters against recognized project
    roots instead of loading every adapter globally.
-   **Language isolation:** Prevent unrelated language adapters from
    interfering with one another.
-   **Lazy loading:** Load adapter implementations only when their
    projects require them.
-   **Explicit:** Keep test execution and result inspection accessible
    through documented keymaps.
-   **Portable:** Support Windows, Linux, and macOS without hardcoding
    platform-specific paths.
-   **Incremental:** Review each language adapter independently before
    integration testing.

## 2. Directory structure

The Neotest integration uses a modular directory structure.

``` text
lua/
└── plugins/
    ├── neotest.lua
    └── neotest/
        ├── init.lua
        ├── install.lua
        ├── run.lua
        └── adapters/
            ├── init.lua
            ├── python.lua
            ├── javascript.lua
            ├── go.lua
            ├── rust.lua
            ├── lua.lua
            ├── c_cpp.lua
            └── bash.lua
```

### 2.1 Module responsibilities

  -------------------------------------------------------------------------
  File                                  Responsibility
  ------------------------------------- -----------------------------------
  `plugins/neotest.lua`                 Entry point that loads the Neotest
                                        integration

  `plugins/neotest/init.lua`            Core initialization, lifecycle, and
                                        Neotest configuration

  `plugins/neotest/install.lua`         Installs Neotest and adapter
                                        dependencies

  `plugins/neotest/run.lua`             Normalizes the current-buffer or
                                        explicit path before running it
                                        through Neotest

  `plugins/neotest/adapters/init.lua`   Project detection, adapter
                                        aggregation, and project
                                        registration

  `adapters/python.lua`                 Python and pytest configuration

  `adapters/javascript.lua`             JavaScript/TypeScript Jest and
                                        Vitest configuration

  `adapters/go.lua`                     Go test configuration

  `adapters/rust.lua`                   Rust and Cargo test configuration

  `adapters/lua.lua`                    Plenary and Busted configuration

  `adapters/c_cpp.lua`                  C and C++ CTest configuration

  `adapters/bash.lua`                   Bashunit configuration
  -------------------------------------------------------------------------

Each language module exposes a consistent interface:

``` lua
M.find_root(path)
M.get_adapters(root)
```

`find_root(path)` identifies the applicable project root.

`get_adapters(root)` returns the adapter instances required by that
project.

This interface allows the registry to work with language adapters
without depending on their internal implementation details.

## 3. Language support

The integration covers eight language targets through seven adapter
modules. JavaScript and TypeScript share an adapter module, while C and
C++ share another.

  ----------------------------------------------------------------------------
  Language target   Module             Adapter              Test framework
  ----------------- ------------------ -------------------- ------------------
  Python            `python.lua`       `neotest-python`     pytest

  JavaScript /      `javascript.lua`   `neotest-jest`,      Jest, Vitest
  TypeScript                           `neotest-vitest`

  Go                `go.lua`           `neotest-go`         Go testing

  Rust              `rust.lua`         `neotest-rust`       Cargo test

  Lua               `lua.lua`          `neotest-plenary`,   Plenary, Busted
                                       `neotest-busted`

  C                 `c_cpp.lua`        `neotest-ctest`      CTest-compatible
                                                            frameworks

  C++               `c_cpp.lua`        `neotest-ctest`      CTest-compatible
                                                            frameworks

  Bash              `bash.lua`         `neotest-bash`       Bashunit
  ----------------------------------------------------------------------------

An adapter module can expose more than one adapter when a language
supports multiple test frameworks.

## 4. Dependencies

### 4.1 Core packages

The installation module uses Neovim's native `vim.pack.add()` interface.

  Package          Purpose
  ---------------- ------------------------------------------
  `plenary.nvim`   Shared Lua utilities
  `nvim-nio`       Asynchronous operations
  `neotest`        Test orchestration and result management

### 4.2 Adapter packages

  Package             Language                  Purpose
  ------------------- ------------------------- --------------------------
  `neotest-python`    Python                    pytest integration
  `neotest-jest`      JavaScript / TypeScript   Jest integration
  `neotest-vitest`    JavaScript / TypeScript   Vitest integration
  `neotest-go`        Go                        Go test integration
  `neotest-rust`      Rust                      Cargo test integration
  `neotest-plenary`   Lua                       Plenary test integration
  `neotest-busted`    Lua                       Busted test integration
  `neotest-ctest`     C / C++                   CTest integration
  `neotest-bash`      Bash                      Bashunit integration

### 4.3 External requirements

Installing a Neotest adapter does not install its language runtime or
test framework.

  -----------------------------------------------------------------------
  Language                            External requirements
  ----------------------------------- -----------------------------------
  Python                              Python interpreter and pytest

  JavaScript / TypeScript             Node.js and Jest or Vitest

  Go                                  Go toolchain

  Rust                                Rust toolchain and Cargo

  Lua                                 Plenary test harness or Busted

  C / C++                             CMake, CTest, a configured build
                                      directory, and a supported test
                                      framework

  Bash                                Bash and Bashunit
  -----------------------------------------------------------------------

Tree-sitter parsers are also required for languages whose adapters
depend on syntax-tree-based discovery.

## 5. Installation and initialization

### 5.1 Entry point

File: `lua/plugins/neotest.lua`

``` lua
-- Neotest entry point.

require("plugins.neotest.init").setup()
```

The entry point delegates initialization to the main Neotest module.

### 5.2 Run helper

File: `lua/plugins/neotest/run.lua`

The run helper provides a consistent path-handling boundary for
current-file and explicit-path execution.

Its public interface is:

``` lua
require("plugins.neotest.run").run_current()
require("plugins.neotest.run").run(path)
```

The helper is intended to:

-   Resolve the current buffer to an absolute path.
-   Normalize path separators on Windows.
-   Pass the normalized path to `neotest.run.run()`.
-   Leave non-Windows path handling platform-neutral.

This helper addresses the observed `neotest-python` behavior where a
Windows path using backslashes succeeds while an equivalent explicit
path using forward slashes returns `No tests found`.

The helper has been proposed but must not be considered validated until
the current-buffer, explicit Windows path, forward-slash path, and
directory execution cases pass.

### 5.3 Installation module

File: `lua/plugins/neotest/install.lua`

The installation module owns the package installation lifecycle.

It installs:

-   Core dependencies.
-   Neotest.
-   Python adapter.
-   Jest and Vitest adapters.
-   Go and Rust adapters.
-   Plenary and Busted adapters.
-   CTest adapter.
-   Bash adapter.

Package installation is performed through `vim.pack.add()`.

Language-specific modules do not install their own packages. This keeps
dependency ownership centralized.

### 5.4 Initialization lifecycle

The integration follows this order:

1.  Install required packages.
2.  Configure Neotest.
3.  Initialize the adapter registry's autocmds.
4.  Detect projects as buffers and working directories change.
5.  Register applicable adapters for recognized projects.

The core lifecycle is:

``` text
setup()
  │
  ├── install()
  │     └── vim.pack.add()
  │
  └── configure()
        │
        ├── neotest.setup()
        │
        └── adapters.setup_autocmds()
```

The installation and configuration responsibilities remain separate.

## 6. Core configuration

File: `lua/plugins/neotest/init.lua`

### 6.1 Global adapter configuration

The core configuration uses empty global adapter and project
collections:

``` lua
adapters = {},
consumers = {},
projects = {},
```

Language adapters are registered through project-specific configuration.

This prevents all installed adapters from being globally active in every
project.

### 6.2 Discovery

``` lua
discovery = {
  enabled = true,
  concurrent = 0,
},
```

Enables test discovery and allows Neotest to manage discovery
concurrency.

### 6.3 Execution

``` lua
default_strategy = "integrated",

running = {
  concurrent = true,
},

run = {
  enabled = true,
},

strategies = {
  integrated = {
    width = 120,
  },
},
```

The integrated strategy executes tests through Neovim's integrated
terminal interface.

### 6.4 Watch mode

Watch mode is enabled in the core configuration.

``` lua
watch = {
  enabled = true,
  symbol_queries = {},
},
```

Watch mode monitors test-related changes. Its symbol-query configuration
must be reviewed against the installed Neotest version and the supported
language parsers.

Symbol queries do not install adapters or provide test execution
support.

### 6.5 Diagnostics and status

The configuration enables:

-   Test diagnostics.
-   Error-level diagnostic reporting.
-   Test status indicators.
-   Signs.
-   Test state tracking.

Virtual text is disabled to avoid unnecessary inline decorations.

### 6.6 Output and result presentation

The configuration enables the following Neotest interfaces:

  Interface                    Configuration
  ---------------------------- ---------------
  Output                       Enabled
  Automatic output on run      Disabled
  Output panel                 Enabled
  Summary                      Enabled
  Quickfix                     Enabled
  Automatic quickfix opening   Disabled
  Floating windows             Enabled
  Floating border              Rounded

The output panel uses a bottom split with a height of 15 lines.

The summary uses a vertical split with a width of 50 columns.

Floating windows use a maximum height and width of 0.6.

The summary also enables animated updates, counts, error expansion, and
following the active test.

### 6.7 Logging

The configured log level is:

``` lua
log_level = vim.log.levels.WARN,
```

This keeps routine debug output out of the normal editor workflow.

## 7. Adapter registry

File: `lua/plugins/neotest/adapters/init.lua`

The registry coordinates language modules and project-specific adapter
registration. It is responsible for selecting the nearest applicable
project and preventing registry-owned project roots from overlapping.

### 7.1 Registry responsibilities

The registry is responsible for:

1.  Loading the language adapter modules.
2.  Normalizing the current file or directory path.
3.  Asking each module to identify its project root.
4.  Grouping modules that resolve to the same normalized root.
5.  Selecting the deepest applicable project root.
6.  Collecting and deduplicating adapters belonging to the selected
    root.
7.  Registering adapters with `neotest.setup_project()`.
8.  Removing registry-owned overlapping project registrations when
    switching to another applicable root.
9.  Avoiding unnecessary registration when the root and ordered adapter
    list are unchanged.

### 7.2 Project-specific registration

The registry uses:

``` lua
require("neotest").setup_project(root .. "/", {
  adapters = adapters,
})
```

The trailing separator is intentional in the current implementation
because the project-key calculation is aligned with Neotest's
`setup_project()` path normalization.

This allows Neotest to select adapters based on the applicable project
rather than using one global adapter collection.

### 7.3 Project isolation

Project isolation is a core requirement.

For example, opening a Python file in a repository should not activate
the Go, Rust, or Bash adapters merely because those languages have files
elsewhere in the repository.

Each module must identify a credible project boundary. Generic
repository markers alone are insufficient evidence of a
language-specific test project.

### 7.4 Root detection

The current adapter designs use language-specific project markers.

  -----------------------------------------------------------------------
  Language                            Root-detection evidence
  ----------------------------------- -----------------------------------
  Python                              `pyproject.toml`, `pytest.ini`,
                                      `setup.cfg`, `tox.ini`, `setup.py`

  JavaScript / TypeScript             `package.json` and Jest/Vitest
                                      dependencies or scripts

  Go                                  `go.mod`

  Rust                                `Cargo.toml`

  Lua                                 `.busted` or recognized Plenary
                                      bootstrap files

  C / C++                             `CMakePresets.json`,
                                      `compile_commands.json`, `.clangd`,
                                      `.clang-format`, `.clang-tidy`

  Bash                                `.bashunitrc` or a project-local
                                      Bashunit executable
  -----------------------------------------------------------------------

These markers are intended to avoid broad root detection.

For example:

-   A Git repository alone must not activate the Bash adapter.
-   A generic `lua/` directory must not activate the Lua adapter.
-   A `CMakeLists.txt` file alone must not establish a CTest project.
-   A JavaScript package must be checked for a supported test framework
    before registering its adapter.

### 7.5 Path normalization and comparison

The registry normalizes paths to absolute, normalized paths and converts
separators to `/` for internal comparison.

On Windows, comparison keys are lowercased to account for
case-insensitive filesystem behavior. The original normalized path is
retained for registration.

Path containment checks use a separator-aware prefix. This prevents a
root such as `project` from incorrectly matching a sibling such as
`project-tools`.

Filesystem roots are preserved when trailing separators are removed.

### 7.6 Adapter aggregation

Multiple adapter modules may identify the same project root. The
registry groups those modules and combines their adapter instances.

Adapter instances are deduplicated by identity. Their order is preserved
because adapter evaluation order may affect which adapter claims a test
file.

Only modules associated with the selected deepest root contribute
adapters to that project's registration.

### 7.7 Overlapping project roots and lifecycle

Nested projects require particular care.

A repository may contain multiple language projects or nested package
directories. The registry maintains its own record of registrations and
removes registry-owned projects whose roots overlap the newly selected
root.

Neotest does not expose a public project-removal API in the integration
currently being used. Cleanup therefore accesses
`neotest.config.projects`, an internal implementation detail.

The registry isolates this dependency and checks whether the internal
project table is available before removing tracked overlapping entries.
If the table is unavailable, it warns and avoids proceeding with an
overlapping replacement.

Registration through `setup_project()` is protected with `pcall()`. A
failed registration is reported and is not recorded as a successful
local registry entry.

Important limitations:

-   `neotest.config.projects` is a private API and may change between
    Neotest versions.
-   The local registry tracks only registrations created by this
    registry instance. It cannot guarantee cleanup of unrelated or
    externally created project entries.
-   A failed replacement after removing an older overlapping project
    does not currently guarantee rollback of the previous registration.
-   The project-key normalization must be checked against the installed
    Neotest version.

The revised registry implementation is a proposed code revision. Its
cleanup, rollback, repeated-registration, and nested-root behavior must
be tested against the installed Neotest version before being marked
accepted.

## 8. Language adapter behavior

### 8.1 Python

File: `adapters/python.lua`

The Python adapter uses `neotest-python` with pytest as its runner.

Its configuration resolves the Python executable using:

1.  `python3`
2.  `python`

If neither executable is found, the adapter receives no explicit
interpreter path.

The module identifies projects through Python project configuration
files and caches its adapter instance.

External requirements:

-   Python.
-   pytest.
-   Python Tree-sitter parser.

### 8.2 JavaScript / TypeScript

File: `adapters/javascript.lua`

The JavaScript adapter supports Jest and Vitest.

It inspects `package.json` to identify supported test frameworks through
dependencies and scripts.

The adapter module can return both Jest and Vitest adapters when the
project configuration supports them.

Adapter instances are cached by project root.

External requirements:

-   Node.js.
-   Jest or Vitest.
-   Appropriate project dependencies.
-   JavaScript and TypeScript Tree-sitter parsers where required.

### 8.3 Go

File: `adapters/go.lua`

The Go adapter uses `neotest-go`.

The project root is identified through `go.mod`.

The adapter is loaded lazily and cached.

External requirements:

-   Go toolchain.
-   A valid Go module.
-   Go Tree-sitter parser.

### 8.4 Rust

File: `adapters/rust.lua`

The Rust adapter uses `neotest-rust`.

The project root is identified through `Cargo.toml`.

The adapter is loaded lazily and cached.

External requirements:

-   Rust toolchain.
-   Cargo.
-   A valid Cargo project.
-   Rust Tree-sitter parser.

### 8.5 Lua

File: `adapters/lua.lua`

The Lua adapter supports two test frameworks:

  Adapter             Framework
  ------------------- -----------
  `neotest-plenary`   Plenary
  `neotest-busted`    Busted

The module distinguishes between the two frameworks using explicit
project configuration.

Busted projects use `.busted`.

Plenary projects require recognized bootstrap configuration, such as:

-   `minimal_init.lua`
-   `minimal_init.vim`
-   `testrc`
-   Recognized test bootstrap files under `test/` or `tests/`

A generic Lua configuration file or `lua/` directory does not
independently establish a Plenary test project.

Busted takes precedence when both frameworks are configured at the same
project root.

Adapter instances are cached by normalized project root.

### 8.6 C / C++

File: `adapters/c_cpp.lua`

The C/C++ adapter uses `neotest-ctest`.

It supports CTest-based test discovery and execution for supported C and
C++ test frameworks.

The adapter uses CMake and Clang project configuration markers to
identify project roots.

`CMakeLists.txt` alone is not considered sufficient evidence of a CTest
project.

CTest requires a configured build directory containing generated test
metadata. Neotest does not compile the project automatically.

The project must be configured and built separately before CTest can
discover and execute its tests.

External requirements:

-   CMake.
-   CTest.
-   A configured build directory.
-   A supported C/C++ test framework.
-   C or C++ Tree-sitter parser.

### 8.7 Bash

File: `adapters/bash.lua`

The Bash adapter uses `neotest-bash` with Bashunit.

A Git root alone must not activate the Bash adapter.

The project must provide Bashunit-specific evidence, such as
`.bashunitrc` or a project-local Bashunit executable.

External requirements:

-   Bash.
-   Bashunit.
-   Bash Tree-sitter parser.

## 9. Keymaps

Neotest keymaps are defined separately from the plugin implementation.

The `<leader>t` namespace is reserved for testing workflows.

The current keymap contract is:

  ----------------------------------------------------------------------------------------------
  Keymap                  Description             Execution
  ----------------------- ----------------------- ----------------------------------------------
  `<leader>ta`            Attach to running test  `neotest.run.attach()`

  `<leader>tf`            Run current file        `plugins.neotest.run.run_current()`

  `<leader>tT`            Run tests from the      `neotest.run.run(vim.fn.getcwd())`
                          current working
                          directory

  `<leader>tr`            Run nearest test        `neotest.run.run()`

  `<leader>tl`            Run last test           `neotest.run.run_last()`

  `<leader>ts`            Toggle summary          `neotest.summary.toggle()`

  `<leader>to`            Show test output        `neotest.output.open()`

  `<leader>tO`            Toggle output panel     `neotest.output_panel.toggle()`

  `<leader>tS`            Stop test execution     `neotest.run.stop()`

  `<leader>tw`            Toggle watch for        `neotest.watch.toggle(vim.fn.expand("%:p"))`
                          current file
  ----------------------------------------------------------------------------------------------

The current-file mapping uses the dedicated run helper to normalize the
buffer path. The nearest-test mapping remains a direct Neotest call;
these mappings must not be assigned to the same key.

The watch mapping passes the absolute current-buffer path.

The actual keymap definitions remain owned by the main keymap
configuration. Keep this table synchronized with that source.

### 9.1 Summary mappings

The Neotest summary also provides navigation and test-management
mappings.

  Key   Action
  ----- ------------------------
  `a`   Attach to running test
  `m`   Mark test
  `M`   Clear marked tests
  `r`   Run selected test
  `R`   Run marked tests
  `d`   Debug selected test
  `D`   Debug marked tests
  `o`   Open test output
  `O`   Show short output
  `w`   Toggle watch
  `t`   Set test target
  `T`   Clear test target
  `J`   Next failed test
  `K`   Previous failed test
  `?`   Show summary help

The summary also supports expanding nodes, navigating parents and
siblings, and stopping execution.

## 10. Testing and verification

Verification must distinguish package installation, module loading,
project detection, test discovery, and actual test execution.

A successful package installation does not establish that an adapter
works.

### 10.1 Verification stages

  -----------------------------------------------------------------------
  Stage                               Verification
  ----------------------------------- -----------------------------------
  1\. Installation                    Required packages are installed and
                                      active

  2\. Module loading                  Neotest and adapter modules load
                                      successfully

  3\. Core API                        Required Neotest APIs are available

  4\. Root detection                  Each language module identifies the
                                      intended project root

  5\. Adapter selection               Only applicable adapters are
                                      registered

  6\. Test discovery                  Test files and test cases are
                                      discovered

  7\. Test execution                  The external runner executes tests

  8\. Result reporting                Neotest reports successful and
                                      failed tests correctly

  9\. Project switching               Changing buffers and working
                                      directories updates registration
                                      correctly

  10\. Portability                    Supported workflows operate across
                                      Windows, Linux, and macOS
  -----------------------------------------------------------------------

### 10.2 Package installation

Inspect installed packages:

``` vim
:lua vim.print(vim.pack.get())
```

Confirm that the core packages and required adapters are installed.

### 10.3 Module loading

Check the core module:

``` vim
:lua print(pcall(require, "neotest"))
```

Check an adapter module:

``` vim
:lua print(pcall(require, "neotest-python"))
```

Repeat for the adapters being investigated.

### 10.4 API availability

``` vim
:lua local n = require("neotest"); print(type(n.setup), type(n.setup_project), type(n.run.run), type(n.summary.toggle), type(n.output.open))
```

Confirm that the APIs required by the integration are available in the
installed Neotest version.

### 10.5 Project-root detection

Test each language module independently.

For example:

``` vim
:lua print(require("plugins.neotest.adapters.python").find_root(vim.fn.expand("%:p")))
```

Repeat for the other language modules.

The returned root must correspond to the intended project rather than an
unrelated parent directory.

### 10.6 Adapter registration

Inspect project registration and verify:

-   The intended project is registered.
-   The correct adapters are associated with that project.
-   Unrelated adapters are not registered.
-   Repeated buffer events do not produce duplicate registrations.
-   Switching projects does not leave stale adapter configurations.

### 10.7 Test execution

Each adapter must have an isolated smoke test.

Verify the external test runner independently before investigating
Neotest discovery or execution.

For Python:

``` powershell
python --version
python -m pytest --version
python -m pytest -v
```

For JavaScript or TypeScript:

``` powershell
node --version
npm test
```

Use the project's actual Jest or Vitest command.

For Go:

``` powershell
go version
go test ./...
```

For Rust:

``` powershell
cargo test
```

For Lua, execute the project's configured Plenary or Busted test
command.

For C/C++, configure and build the project, then run:

``` powershell
ctest --test-dir build --output-on-failure
```

For Bash, execute the project's Bashunit test command.

These commands validate the external test environment. Neotest
acceptance additionally requires successful discovery and execution
through Neotest.

### 10.8 Windows path handling

A Windows-specific path behavior has been reproduced with the Python
adapter:

-   Running the current buffer path succeeds.
-   An explicit path using Windows backslashes succeeds.
-   An equivalent explicit path using forward slashes returns
    `No tests found`.
-   Python project-root detection succeeds.
-   Python `is_test_file()` recognition succeeds.

This behavior is consistent with the reported [`neotest-python` issue
#107](https://github.com/nvim-neotest/neotest/issues/107).

Use the run helper for current-file execution:

``` lua
require("plugins.neotest.run").run_current()
```

The helper's forward-slash normalization workaround remains unverified.
Retest it with both file and directory paths before relying on it as a
fix.

### 10.9 Health checks

A missing Neotest health-check module is not, by itself, evidence of
failed test execution.

Do not add custom health checks merely to suppress a missing-healthcheck
message.

## 11. Acceptance criteria

An adapter is accepted only after its installation, project detection,
discovery, execution, and result reporting have been verified.

  -----------------------------------------------------------------------
  ID                      Requirement             Acceptance criteria
  ----------------------- ----------------------- -----------------------
  NT-01                   Core installation       Neotest and its core
                                                  dependencies load
                                                  successfully

  NT-02                   Adapter installation    Required adapter
                                                  packages install
                                                  successfully

  NT-03                   Modular architecture    Core and language
                                                  modules load
                                                  independently

  NT-04                   Root detection          Each adapter identifies
                                                  the intended project
                                                  root

  NT-05                   Project registration    Applicable adapters are
                                                  registered per project

  NT-06                   Adapter isolation       Unrelated language
                                                  adapters do not
                                                  interfere

  NT-07                   Registration lifecycle  Repeated events and
                                                  project switching are
                                                  handled correctly

  NT-08                   Path handling           Current-buffer,
                                                  explicit Windows, and
                                                  directory paths execute
                                                  correctly

  NT-09                   Keymaps                 Testing keymaps
                                                  register without
                                                  conflicts

  NT-10                   Summary                 Summary opens and
                                                  displays discovered
                                                  tests

  NT-11                   Output                  Test output can be
                                                  opened and inspected

  NT-12                   Python                  Python tests are
                                                  discovered and executed

  NT-13                   JavaScript / TypeScript Jest or Vitest tests
                                                  are discovered and
                                                  executed

  NT-14                   Go                      Go tests are discovered
                                                  and executed

  NT-15                   Rust                    Rust tests are
                                                  discovered and executed

  NT-16                   Lua                     Plenary or Busted tests
                                                  are discovered and
                                                  executed

  NT-17                   C / C++                 CTest tests are
                                                  discovered and executed

  NT-18                   Bash                    Bashunit tests are
                                                  discovered and executed

  NT-19                   Watch mode              Watch behavior works
                                                  with supported symbol
                                                  queries

  NT-20                   Cross-platform behavior Supported workflows
                                                  work on Windows, Linux,
                                                  and macOS
  -----------------------------------------------------------------------

A package being installed or a module being loadable is not sufficient
to mark an adapter as accepted.

## 12. Current implementation status

The modular integration is implemented in parts and remains under
validation. The status below distinguishes code that exists from
behavior that has been verified.

  -----------------------------------------------------------------------
  Component               Status                  Notes
  ----------------------- ----------------------- -----------------------
  Entry point             Implemented             Delegates to the
                                                  Neotest initialization
                                                  module

  Core initialization     Implemented             Owns Neotest setup and
                                                  lifecycle; preserve
                                                  unless explicitly
                                                  required

  Package installation    Implemented             Uses native
                                                  `vim.pack.add()`

  Adapter module          Implemented             Seven modules covering
  structure                                       eight language targets

  Python adapter          Partially verified      Root detection and
                                                  test-file recognition
                                                  pass; nested pytest
                                                  execution has produced
                                                  a passing result

  JavaScript adapter      Reviewed                Jest and Vitest
                                                  support; end-to-end
                                                  execution still
                                                  requires validation

  Go adapter              Reviewed                `go.mod` project
                                                  detection; end-to-end
                                                  execution still
                                                  requires validation

  Rust adapter            Reviewed                `Cargo.toml` project
                                                  detection; end-to-end
                                                  execution still
                                                  requires validation

  Lua adapter             Under review            Plenary and Busted root
                                                  detection

  C/C++ adapter           Under review            CMake and CTest root
                                                  detection

  Bash adapter            Under review            Bashunit-specific root
                                                  detection; generic
                                                  Git-root fallback must
                                                  not be used

  Adapter registry        Revised; not yet        Deepest-root selection,
                          validated               adapter aggregation,
                                                  Windows path
                                                  comparison, overlap
                                                  cleanup, and guarded
                                                  registration

  Run helper              Proposed; not yet       Normalizes
                          validated               current-buffer and
                                                  explicit paths before
                                                  execution

  Keymaps                 Revised                 `<leader>tf` runs the
                                                  current file through
                                                  the helper;
                                                  `<leader>tr` remains
                                                  nearest-test execution

  Integration testing     In progress             Python nested-project
                                                  execution has passed;
                                                  other adapters and
                                                  registry lifecycle
                                                  cases remain
  -----------------------------------------------------------------------

### 12.1 Root-detection review

The root-detection review focuses on preventing false adapter selection.

The following cases require particular attention:

-   A Git repository must not automatically activate Bash.
-   A generic Lua tooling configuration must not automatically activate
    Plenary or Busted.
-   A generic CMake project must not automatically activate CTest.
-   JavaScript packages must be checked for Jest or Vitest support.
-   Nested projects must not cause unrelated adapters to be registered.

### 12.2 Verified Python behavior

The nested Python fixture under the temporary Neotest test directory has
been discovered and executed successfully through `neotest-python`. The
reported result showed one test passing and no failures.

The following path behavior was also observed:

  Invocation                                    Observed result
  --------------------------------------------- ------------------
  Current buffer path                           Pass
  Explicit Windows path using `\\` separators   Pass
  Explicit path using `/` separators            `No tests found`
  Python `find_root()`                          Pass
  Python `is_test_file()`                       Pass

The passing test confirms the tested Python path, fixture, adapter, and
runner combination. It does not establish that all Python projects or
all supported platforms work.

### 12.3 Remaining integration validation

The revised registry and run helper have been proposed in code but their
latest revisions have not yet been confirmed by execution.

Before marking the integration accepted, validate:

1.  The helper with current-buffer paths.
2.  The helper with explicit Windows paths using both separator styles.
3.  Directory execution through the helper.
4.  Deepest-root selection when multiple adapter modules match.
5.  Adapter aggregation and identity-based deduplication.
6.  Repeated `BufEnter` events without unnecessary registration.
7.  Project switching and overlapping-root cleanup.
8.  Failure handling when `setup_project()` raises an error.
9.  Behavior when `neotest.config.projects` is unavailable or changes
    shape.
10. Regression behavior for the already passing nested Python fixture.

Do not treat the proposed helper or registry revision as validated until
these cases pass against the installed Neotest version.

## 13. Future improvements

Potential improvements should be introduced only when a documented
requirement justifies them.

Areas for future evaluation include:

-   More advanced monorepo and nested-project handling.
-   Additional framework support within existing language modules.
-   Improved watch-mode symbol queries.
-   Debugging integration where supported by the adapter.
-   Better project-level diagnostics for missing external test runners.

Do not introduce another framework or abstraction solely to manage the
existing adapter modules.

## 14. Implementation policy

Before adding or changing an adapter:

1.  Review the adapter's maintenance and compatibility.
2.  Confirm its supported test frameworks.
3.  Add package installation to `install.lua`.
4.  Implement project-root detection.
5.  Implement `get_adapters(root)`.
6.  Preserve the registry interface.
7.  Review project isolation and nested-root behavior.
8.  Create a minimal smoke test.
9.  Verify external runner execution.
10. Verify Neotest discovery and execution.
11. Record the acceptance result.

Keep adapter-specific configuration minimal. Add options only when
required by a documented integration need.

The core Neotest module should remain independent of language-specific
implementation details.

