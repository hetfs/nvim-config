# SQL Support

## 1. Purpose

This document defines the SQL language-support baseline for Stage 13 (Language Packs) of the Neovim configuration project.

The objective is to provide a consistent SQL editing environment through Neovim's native Language Server Protocol (LSP) client, Treesitter, and the shared formatting infrastructure.

SQL support is an **optional language pack**. It is enabled through the opt-in mechanism defined in `optional-packs.md` and remains outside the core language-pack baseline.

The pack is independently maintained, allowing SQL-specific tooling, dialect configuration, and database integration to evolve without affecting other language packs or shared infrastructure.

The initial dialect targets are:

1. PostgreSQL
2. MySQL
3. SQLite

**Architectural principle:** SQL language support must remain independent of database infrastructure. Users must be able to edit, navigate, and format SQL files without installing or running a database server. Database-aware capabilities are activated only when explicitly configured.

## 2. SQL Tooling Baseline

The following tooling is proposed for the SQL language pack.

| Component | Selection | Status |
|---|---|---|
| Language pack | `lua/langs/sql.lua` | Proposed |
| Language server | SQLS (`sqls`) | Pending validation |
| LSP definition source | nvim-lspconfig | Approved architecture |
| LSP client | Native Neovim LSP | Approved |
| Syntax parser | Treesitter `sql` | Proposed |
| Formatter | `sql-formatter` | Proposed |
| Formatting integration | Conform.nvim | Approved architecture |
| Static analysis | Separate evaluation | Deferred |
| Database connections | Explicit user configuration | Approved architecture |
| Initial dialects | PostgreSQL, MySQL, SQLite | Approved scope |

### 2.1 Language Server: SQLS

SQLS is the proposed language server for SQL support.

It provides SQL language intelligence through the Language Server Protocol.

Expected capabilities include:

- SQL completion.
- Database schema-aware completion when a connection is configured.
- Hover information where supported.
- Symbol navigation where supported.
- Diagnostics where supported.
- Signature assistance where supported.

Official repository:

https://github.com/sqls-server/sqls

SQLS remains a candidate dependency until the following validation requirements are satisfied:

1. **Maintenance:** Verify the upstream project's maintenance status and release activity.
2. **Neovim compatibility:** Confirm compatibility with Neovim 0.12.6 and its native LSP implementation.
3. **Windows installation:** Validate installation and executable availability through its Go-based distribution.
4. **Database integration:** Verify connection and schema integration for PostgreSQL, MySQL, and SQLite.
5. **LSP capabilities:** Test the advertised capabilities individually rather than assuming all expected functionality is implemented.
6. **Database-independent startup:** Confirm that SQLS can start and attach without an active database connection.

If SQLS does not satisfy the validation requirements, an alternative language server may be evaluated without changing the SQL pack architecture.

### 2.2 LSP Client: Native Neovim LSP

SQLS integrates through Neovim's native LSP implementation.

The configuration uses:

- `vim.lsp.config()` to define or override the server configuration.
- `vim.lsp.enable()` to activate the server.

Server definitions are sourced from nvim-lspconfig, which serves exclusively as a definitions provider.

The project must not use:

```lua
require("lspconfig").setup()
```

SQL-specific configuration remains inside `lua/langs/sql.lua`.

No additional LSP client, configuration framework, or server-management framework is introduced.

### 2.3 Treesitter

The SQL language pack uses the Treesitter `sql` parser for syntax highlighting and supported syntax-based editor features.

Parser installation and availability follow the existing Stage 8 Treesitter infrastructure.

Responsibilities remain clearly separated:

- Treesitter handles syntax parsing and syntax-based editor functionality.
- The LSP provides language intelligence.
- Database-aware functionality depends on explicit database configuration.
- Formatting remains the responsibility of Conform.nvim.

Treesitter must not be treated as a replacement for SQL diagnostics, database validation, or query execution.

### 2.4 Formatter: sql-formatter

The proposed SQL formatter is `sql-formatter`.

It supports multiple SQL dialects, including PostgreSQL, MySQL, and SQLite.

Official repository:

https://github.com/sql-formatter-org/sql-formatter

Formatting integrates with the existing Conform infrastructure.

The SQL pack registers its formatter defaults, while per-filetype overrides in `lua/config/languages.lua` merge with the pack defaults rather than replacing them.

The implementation must:

- Use the shared Conform configuration.
- Respect the configured SQL dialect.
- Preserve the existing manual formatting workflow.
- Avoid introducing another formatting framework.
- Keep format-on-save disabled by default.

### 2.5 Static Analysis

SQL static analysis is deferred for separate evaluation.

SQLS diagnostics and SQL formatting must not be considered substitutes for comprehensive SQL linting or database-specific validation.

Any additional analyzer must demonstrate clear value before admission into the SQL baseline.

It must also satisfy the Stage 13 lint admission policy:

1. Provide checks that the language server does not adequately cover.
2. Have an executable whose availability can be verified.
3. Use a dedicated diagnostic namespace.
4. Provide verified stale-diagnostic cleanup.
5. Integrate without duplicating existing diagnostics or shared infrastructure.

No SQL static-analysis dependency is approved at this stage.

## 3. Architecture Decisions

The following decisions govern SQL language support.

### 3.1 Independent Optional Language Pack

SQL has its own language-pack module:

```text
lua/langs/sql.lua
```

The module is discovered through the existing language-pack registry and remains inactive until explicitly enabled through the optional-pack mechanism.

The pack is responsible for:

1. SQL-specific LSP configuration.
2. SQL-specific Treesitter integration.
3. SQL formatting registration.
4. SQL dialect defaults and configuration.
5. Integration with explicitly configured database connections.

The implementation must not introduce SQL-specific behavior into unrelated language packs.

Enabling SQL must not change the activation or configuration of other packs.

### 3.2 Configurable Database Dialects

The initial dialect baseline includes:

1. PostgreSQL
2. MySQL
3. SQLite

Dialect selection must be explicit and must be respected by the relevant tooling.

The formatter must not assume that all SQL implementations share identical syntax.

Database-aware LSP functionality must use the appropriate database configuration and supported driver.

The implementation must distinguish between:

- Formatter dialect selection.
- LSP database connection configuration.
- Database-specific language intelligence.

These settings must not be treated as interchangeable.

Additional dialects may be evaluated independently without requiring architectural changes to the language pack.

### 3.3 Explicit Database Connections

Database connections must be configured explicitly for each database.

The SQL language pack must not contain hardcoded:

- Database hostnames.
- Ports.
- Usernames.
- Passwords.
- Database names.
- Connection strings.
- Authentication tokens.

Connection settings belong in separate, user-controlled configuration.

Possible configuration mechanisms include:

- SQLS-supported user configuration.
- Untracked per-project configuration.
- Workspace-specific configuration.

The final mechanism must be determined during SQLS validation.

Regardless of the selected mechanism:

1. Connection configuration must remain outside the repository.
2. Credentials must never be committed to the Neovim configuration.
3. Database connections must be optional.
4. SQL language-server startup must not depend on an active database connection.
5. Missing connection configuration must not prevent basic SQL editing.

### 3.4 Optional Database Infrastructure

Database clients, servers, drivers, and connection utilities remain optional external dependencies.

Users who only need SQL syntax highlighting, language-server functionality, and formatting must not be required to install or run a database server.

Database-aware capabilities require the relevant connection configuration and supported database drivers.

The absence of database infrastructure must not disable the basic SQL editing workflow.

### 3.5 Shared Formatting Infrastructure

SQL formatting uses the existing Conform infrastructure with `sql-formatter`.

The implementation follows the project's established formatting policy:

| Setting | Default |
|---|---|
| Manual formatting | Enabled |
| Formatting command | Existing `:Format` |
| Formatting keymap | Existing `<leader>cf` |
| Format-on-save | Disabled |
| LSP-formatting fallback | Disabled |
| Formatter configuration | SQL pack defaults |
| Per-filetype overrides | `lua/config/languages.lua` |

Additional requirements:

- Manual formatting must use the existing formatting workflow.
- Format-on-save must remain an explicit configuration option.
- LSP-formatting fallback must remain an explicit configuration option.
- Both options must use validated configuration values.
- Both options require opt-in validation tests.
- Per-filetype overrides must merge with pack defaults.
- SQL must not introduce another formatting framework.

### 3.6 Native-First Dependency Management

All SQL tooling must follow the project's native-first dependency-management principles.

The following restrictions apply:

- No Mason.
- No lazy.nvim.
- No additional LSP client.
- No duplicate formatting infrastructure.
- No automatic installation of external tools during Neovim startup.
- No silent installation of missing dependencies.

External tools must have explicit installation and validation procedures.

Plugin management must use the existing native `vim.pack` approach where applicable.

**Approval of a dependency does not automatically authorize its installation.** Installation must follow the project's explicit dependency-management workflow.

## 4. Language Pack Structure

The SQL language pack is located at:

```text
lua/
└── langs/
    └── sql.lua
```

The module integrates with the existing shared infrastructure rather than duplicating it.

Its responsibilities include:

1. Registering SQL-specific server configuration through `vim.lsp.config()`.
2. Enabling SQLS through `vim.lsp.enable()`.
3. Integrating the SQL Treesitter parser.
4. Registering SQL formatting through Conform.
5. Providing SQL-specific dialect defaults.
6. Respecting explicitly configured database connections.

The module must not contain database credentials, connection secrets, or hardcoded infrastructure details.

Shared LSP, Treesitter, and formatting functionality must remain in their respective shared modules.

The SQL pack should contain only the configuration required to integrate SQL with those systems.

## 5. Installation Requirements

The following external dependencies are proposed.

| Tool | Purpose | Requirement |
|---|---|---|
| `sqls` | SQL language server | Required by the SQL pack if approved |
| `sql-formatter` | SQL formatting | Required by the SQL pack |
| Treesitter `sql` parser | SQL syntax parsing | Required editor support |
| Database drivers | Database integration | Optional |
| Database clients | Database administration and access | Optional |
| Database servers | Query execution and testing | Optional |

The term **required by the SQL pack** does not mean required by the base Neovim configuration.

### 5.1 Installation Strategy

Installation methods must be documented and validated before the SQL dependencies are added to the finalized dependency manifest.

Installation follows the existing per-pack installer architecture under:

```text
scripts/
└── install/
    └── optional/
        └── sql/
```

The exact installer filename and directory placement must follow the established installer conventions.

### 5.2 SQLS Installation

SQLS uses Go-based distribution.

The installation process must account for:

- Go availability.
- Installation through the supported Go installation method.
- Executable placement.
- Windows PATH configuration.
- Executable verification.
- Version reporting.

The installer must not silently install Go or modify the user's environment without explicit authorization.

### 5.3 Formatter Installation

`sql-formatter` belongs to the Node.js ecosystem.

The installation process must account for:

- Node.js availability.
- npm or the project's approved Node.js package-management method.
- Executable availability.
- Version verification.
- Windows compatibility.

The formatter must be independently verifiable before Conform attempts to invoke it.

### 5.4 Treesitter Parser Installation

The SQL parser follows the existing Treesitter installation and parser-management workflow.

No separate SQL parser installation framework is permitted.

### 5.5 Database Dependencies

Database drivers, clients, and servers are not part of the mandatory SQL editing installation.

They are installed separately when a user requires database-aware functionality or external database workflows.

## 6. Validation Requirements

SQL support must pass the following validation before being marked complete.

The primary validation environment is Neovim 0.12.6 on Windows.

Other supported platforms should be validated where applicable.

### 6.1 Language Server

- [ ] SQLS installation succeeds on Windows.
- [ ] SQLS executable is discoverable by Neovim.
- [ ] SQLS starts through Neovim's native LSP client.
- [ ] SQL filetype detection works correctly.
- [ ] LSP attachment succeeds without a configured database connection.
- [ ] Basic completion works where supported.
- [ ] Hover functionality works where supported.
- [ ] Symbol navigation works where supported.
- [ ] Diagnostics behave as documented.
- [ ] Database-aware completion works with a valid connection.
- [ ] Missing database configuration does not prevent basic LSP startup.
- [ ] SQL-specific configuration does not affect other language servers.

### 6.2 Treesitter

- [ ] The SQL parser installs successfully.
- [ ] SQL syntax highlighting works.
- [ ] SQL parser validation passes.
- [ ] Parser functionality works with representative SQL files.
- [ ] PostgreSQL-specific syntax is parsed where supported.
- [ ] MySQL-specific syntax is parsed where supported.
- [ ] SQLite-specific syntax is parsed where supported.

### 6.3 Formatting

- [ ] `sql-formatter` installs successfully.
- [ ] The formatter executable is discoverable.
- [ ] Conform detects the SQL formatter.
- [ ] Manual formatting works through `:Format`.
- [ ] Existing `<leader>cf` formatting integration works.
- [ ] PostgreSQL formatting works.
- [ ] MySQL formatting works.
- [ ] SQLite formatting works.
- [ ] Per-filetype overrides in `lua/config/languages.lua` merge with pack defaults.
- [ ] Format-on-save is disabled by default.
- [ ] Format-on-save works when explicitly enabled.
- [ ] LSP-formatting fallback is disabled by default.
- [ ] LSP-formatting fallback works when explicitly enabled.
- [ ] Missing formatter executables produce an understandable error without breaking Neovim startup.

### 6.4 Database Integration

- [ ] PostgreSQL connection configuration works.
- [ ] MySQL connection configuration works.
- [ ] SQLite connection configuration works.
- [ ] Database-specific configuration is external to the repository.
- [ ] Credentials remain outside the repository.
- [ ] Database-aware completion works with a valid connection.
- [ ] Missing connections do not prevent SQL editing.
- [ ] SQL editing works without a running database server.

Database integration tests must distinguish between connection configuration, driver availability, and server availability.

### 6.5 Pack Behavior

- [ ] The SQL pack remains inactive until explicitly opted in.
- [ ] The language-pack registry discovers the SQL module correctly.
- [ ] Enabling SQL does not affect other language packs.
- [ ] Disabling SQL removes its optional configuration from the active language-pack setup.
- [ ] Shared LSP infrastructure is reused.
- [ ] Shared Treesitter infrastructure is reused.
- [ ] Shared formatting infrastructure is reused.
- [ ] No duplicate dependency-management mechanism is introduced.

## 7. Scope Boundaries

SQL support is an editor language-support baseline, not a complete database administration environment.

The following capabilities are outside the mandatory scope:

- Database server installation.
- Database server management.
- Database migrations.
- Database administration interfaces.
- Database backup and recovery.
- Database monitoring.
- SQL query execution frameworks.
- Database deployment workflows.
- Comprehensive database-specific static analysis.

These capabilities may be introduced later as independent optional integrations.

The SQL language pack must remain focused on editing, language intelligence, syntax parsing, and formatting.

## 8. Completion Criteria

SQL support can be marked complete when all the following conditions are satisfied:

1. The independent SQL language pack is implemented and remains opt-in.
2. SQLS or an approved alternative works through Neovim's native LSP client.
3. SQL filetype detection and database-independent LSP startup are validated.
4. Treesitter SQL parser integration is validated.
5. `sql-formatter` works through the existing Conform infrastructure.
6. PostgreSQL, MySQL, and SQLite formatting are validated.
7. Formatter defaults and per-filetype overrides merge correctly.
8. Format-on-save and LSP-formatting fallback remain disabled by default.
9. Both formatting options pass their explicit opt-in tests.
10. Database connections remain external, explicit, and optional.
11. SQL editing works without database infrastructure.
12. Windows installation and validation succeed.
13. The optional-pack registry discovers and activates SQL correctly.
14. No unnecessary duplication of existing language-pack or shared infrastructure is introduced.
15. Installation and validation procedures are documented.

Any functionality that cannot be validated must remain explicitly documented as unsupported or deferred rather than being treated as complete.

## 9. Final Architecture Summary

| Area | Decision |
|---|---|
| Stage | 13 — Language Packs |
| Language pack | Optional, `lua/langs/sql.lua` |
| Language server | SQLS (`sqls`), pending validation |
| LSP implementation | Native Neovim LSP |
| LSP definitions | nvim-lspconfig, definitions only |
| LSP configuration | `vim.lsp.config()` |
| LSP activation | `vim.lsp.enable()` |
| Syntax parsing | Treesitter `sql` |
| Formatter | `sql-formatter` |
| Formatting integration | Conform.nvim |
| Formatter defaults | SQL pack |
| Per-filetype overrides | `lua/config/languages.lua` |
| Manual formatting | Existing `:Format` and `<leader>cf` |
| Format-on-save | Explicit option, off by default |
| LSP-formatting fallback | Explicit option, off by default |
| Static analysis | Deferred; Stage 13 lint admission policy applies |
| Initial dialects | PostgreSQL, MySQL, SQLite |
| Database connections | Explicit, external, user-controlled |
| Database drivers | Optional |
| Database clients | Optional |
| Database servers | Optional |
| Plugin management | Native `vim.pack` |
| External dependency installation | Explicit per-pack installers |
| Mason | Not permitted |
| lazy.nvim | Not permitted |

---

**Document status:** Proposed baseline, pending implementation and validation.

**Stage:** 13 — Language Packs.
