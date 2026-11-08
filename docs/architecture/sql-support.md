# SQL Support

## 1. Purpose

This document defines the SQL language-support implementation for Stage 13 (Language Packs) of the Neovim configuration project.

The objective is to provide a consistent SQL editing environment through Neovim's native Language Server Protocol (LSP), Treesitter, shared formatting infrastructure, and independent static analysis.

SQL is an **optional language pack**. It remains outside the core language-pack baseline and is activated through the existing language-pack configuration.

The implementation is maintained independently so SQL-specific tooling, dialect configuration, and optional database integration can evolve without affecting other language packs or shared infrastructure.

The initial dialect targets are:

1. PostgreSQL
2. MySQL
3. SQLite

**Architectural principle:** SQL editing, syntax parsing, formatting, and static analysis must not depend on a running database server. Database-aware capabilities require explicit user configuration and the necessary database infrastructure.

## 2. Implementation Status

The SQL language-pack implementation has integrated SQLS, SQL Formatter, and SQLFluff. The core LSP, formatting, dialect-resolution, and static-analysis workflows have passed their current Windows validation tests.

| Component | Selection | Current status |
|---|---|---|
| Language pack | `lua/langs/sql.lua` | Implemented |
| Language server | SQLS (`sqls`) | Installed and attachment verified |
| LSP client | Native Neovim LSP | Verified |
| LSP definitions | nvim-lspconfig | Definitions provider |
| Syntax parser | Treesitter `sql` | Automatic installation initiated; parser functionality requires final verification |
| Formatter | `sql-formatter` | Installed and formatting verified |
| Formatting integration | Conform.nvim | Verified |
| Dialect resolution | SQL language pack | Implemented and tested |
| Static analysis | SQLFluff | Approved and integrated; real-buffer diagnostics verified |
| Static-analysis integration | Native Neovim diagnostics | Verified |
| Database connections | External SQLS configuration | Not configured or tested |

### 2.1 Verified dependency versions

The following versions were observed in the Windows validation environment:

| Dependency | Verified version |
|---|---|
| Neovim | 0.12.6 |
| Go | 1.27.3 |
| Node.js | 26.12.1 |
| npm | 11.20.0 |
| SQLS | 0.2.48 |
| SQL Formatter | 15.9.0 |
| SQLFluff | 4.5.0 |
| Python | 3.14.7 |

SQLFluff 4.5.0 was installed using `uv tool install --python 3.14 sqlfluff==4.5.0`.

These are verified environment versions, not necessarily the final cross-platform dependency policy. Any future version changes must be validated before updating the project's dependency records.

## 3. SQL Tooling

### 3.1 Language Server: SQLS

SQLS is the selected language server for SQL support.

Official repository: [SQLS](https://github.com/sqls-server/sqls)

The implementation uses Neovim's native LSP configuration and activation APIs:

- `vim.lsp.config()` defines the SQLS configuration.
- `vim.lsp.enable()` activates SQLS.

The SQL pack checks whether the `sqls` executable is available. If it is missing, the pack skips SQLS activation without preventing SQLFluff or other SQL functionality from loading.

The implementation does not use the legacy setup interface:

```lua
require("lspconfig").sqls.setup()
```

SQL-specific configuration remains in `lua/langs/sql.lua`.

#### Workspace-root policy

The implementation uses the following policy:

1. SQL files inside a Git repository use the Git repository root.
2. SQL files outside Git repositories use their containing directory.
3. Unnamed buffers use the current working directory.
4. No SQLS-specific project configuration file is required for basic attachment.
5. No database connection is required for basic LSP startup.

The root callback uses the native Neovim LSP contract and delegates root resolution to `M.workspace_root()`.

This behavior has been tested with:

- An unnamed buffer.
- A standalone SQL file.
- A SQL file inside a temporary Git repository.

The tests confirmed the expected roots. Multiple-file client reuse should remain part of broader workspace regression testing.

#### Runtime verification

The following SQLS behavior has been tested without an active database connection:

| Capability | Result |
|---|---|
| Executable discovery | Verified |
| LSP startup | Verified |
| SQL buffer attachment | Verified |
| Workspace-root resolution | Verified |
| Keyword completion | Verified; 145 completion items returned |
| Document formatting request | Verified; text edits returned |
| Code actions | Verified; seven actions returned |
| Hover | No content returned for the tested position |
| Signature help | No content returned for the tested `COUNT()` expression |

The seven returned code actions were:

- Execute Query
- Show Databases
- Show Schemas
- Show Connections
- Switch Database
- Switch Connections
- Show Tables

These results establish that SQLS exposes the commands through its code-action interface. They do not establish that database-dependent operations execute successfully.

SQLS also reported:

```text
LSP[sqls] no database connection
```

This warning did not prevent LSP attachment, keyword completion, document formatting, or code-action retrieval.

**Capability distinction:** A server advertising an LSP capability does not prove that it returns useful results for every request. Hover and signature help remain unverified beyond the specific test cases described above.

Database-aware completion, schema information, and database-dependent diagnostics remain unverified because no database connection has been configured.

### 3.2 Native LSP Integration

The SQL pack follows the existing language-pack lifecycle:

1. The registry discovers the SQL module.
2. The enabled pack executes its `setup()` function.
3. SQLFluff initializes independently.
4. The module checks for the SQLS executable.
5. If SQLS is available, the module configures it through `vim.lsp.config()`.
6. The module activates SQLS through `vim.lsp.enable()`.

The language-pack registry does not currently define a `servers` metadata contract. SQLS therefore uses the existing `setup()` mechanism rather than introducing new registry behavior.

nvim-lspconfig remains a server-definition provider. Native Neovim LSP owns client configuration and activation.

SQLFluff initialization must not be placed behind the SQLS executable check. The absence of SQLS must not prevent static analysis from starting.

### 3.3 Treesitter

The SQL language pack declares its parser through:

```lua
parser_by_filetype = {
    sql = "sql",
}
```

The existing shared Treesitter infrastructure discovers parser metadata from enabled language packs and handles parser installation.

The SQL pack must not introduce a separate parser installation mechanism.

During SQL integration testing, Neovim reported:

```text
[nvim-treesitter/install/sql]: Downloading tree-sitter-sql...
```

This confirms that the automatic installation workflow was initiated. Successful parser installation, syntax highlighting, and representative dialect parsing still require final verification.

Treesitter is responsible for syntax parsing and syntax-based editor functionality. It does not replace:

- LSP language intelligence.
- Static analysis.
- Database-aware diagnostics.
- Database syntax validation.
- SQL query execution.

PostgreSQL, MySQL, and SQLite syntax should be tested independently. Parser support must not be treated as proof of complete dialect compatibility.

### 3.4 Formatter: SQL Formatter

The approved SQL formatter is `sql-formatter`.

Official repository: [SQL Formatter](https://github.com/sql-formatter-org/sql-formatter)

Dialect documentation: [SQL Formatter dialects](https://github.com/sql-formatter-org/sql-formatter/blob/master/docs/dialect.md)

The external executable is:

```text
sql-formatter
```

Conform identifies its integration as:

```text
sql_formatter
```

The SQL language pack declares the formatter through shared metadata:

```lua
formatters = {
    sql = { "sql_formatter" },
}
```

The shared `lua/config/format.lua` module owns formatter registration and execution.

The SQL-specific formatter definition supplies a dialect-aware argument callback and a working directory based on the buffer being formatted:

```lua
sql_formatter = {
    prepend_args = function(_, ctx)
        return {
            "--language",
            require("langs.sql").resolve_dialect(ctx.buf),
        }
    end,

    cwd = function(_, ctx)
        return ctx.dirname
    end,
}
```

The working directory allows SQL Formatter to discover project configuration relative to the SQL file.

The implementation extends the shared Conform formatter definition rather than introducing another formatting framework.

#### Formatting verification

The following behavior has been verified:

- SQL Formatter 15.9.0 is available to Neovim.
- Conform recognizes `sql_formatter`.
- The custom `prepend_args` callback is registered.
- The custom `cwd` callback is registered.
- The dialect argument is resolved for the buffer being formatted.
- PostgreSQL, MySQL, and SQLite dialect arguments are generated correctly.
- Project-level dialect resolution passes the expected SQLite argument.
- Actual formatting through Conform succeeds.
- SQL formatting works independently of database connectivity.

The implementation retains the existing manual formatting workflow.

Format-on-save remains disabled by default. LSP-formatting fallback also remains disabled by default.

SQLS advertises document-formatting support and returned formatting edits during testing. However, Conform remains the default formatting owner to avoid competing formatting providers.

The SQL pack must not disable SQLS formatting capabilities merely to enforce the default Conform policy.

### 3.5 SQL Dialect Resolution

Dialect resolution belongs to `lua/langs/sql.lua`.

The initial supported formatter dialects are:

| Database | SQL Formatter dialect |
|---|---|
| PostgreSQL | `postgresql` |
| MySQL | `mysql` |
| SQLite | `sqlite` |

The default dialect is:

```text
postgresql
```

The implementation resolves the dialect using this precedence:

1. Buffer-local override: `b:sql_dialect`.
2. Filetype-specific override: `vim.g.sql_dialect_by_ft`.
3. Nearest project configuration: `.sql-formatter.json`.
4. Global override: `vim.g.sql_dialect`.
5. Pack default: `postgresql`.

Example buffer-local configuration:

```lua
vim.b.sql_dialect = "mysql"
```

Example filetype-specific configuration:

```lua
vim.g.sql_dialect_by_ft = {
    sql = "sqlite",
}
```

Example global configuration:

```lua
vim.g.sql_dialect = "postgresql"
```

Example project configuration:

```json
{
    "language": "sqlite"
}
```

The project configuration file is named:

```text
.sql-formatter.json
```

The implementation validates dialect values and rejects unsupported values. Invalid values produce a warning and allow resolution to continue to the next valid source.

Invalid configuration types and malformed project JSON are handled without preventing basic SQL editing.

The implementation reads the project's `language` property for dialect resolution. SQL Formatter also discovers its project configuration through the Conform working directory. Other project-level formatter options should be verified independently rather than assumed to be covered by dialect resolution alone.

Formatter dialect selection is independent of SQLS database connections.

### 3.6 Static Analysis: SQLFluff

SQLFluff is the approved static-analysis tool for the SQL language pack.

Official resources:

- [SQLFluff documentation](https://docs.sqlfluff.com/en/stable/)
- [SQLFluff repository](https://github.com/sqlfluff/sqlfluff)
- [Rule reference](https://docs.sqlfluff.com/en/stable/reference/rules/)
- [Dialect reference](https://docs.sqlfluff.com/en/stable/reference/dialects/)
- [Configuration](https://docs.sqlfluff.com/en/stable/configuration/)

SQLFluff owns static analysis only. It does not own SQL formatting, language-server functionality, database connectivity, or query execution.

The responsibilities remain separate:

| Tool | Responsibility |
|---|---|
| SQLS | Language-server functionality |
| SQL Formatter | SQL formatting |
| SQLFluff | Static analysis |
| Treesitter | Syntax parsing and syntax-based editor functionality |
| Database engine | Database-specific validation and query execution |

#### Dialect mapping

The SQL language pack maps its canonical dialect names to SQLFluff dialect identifiers:

| Database | SQL language-pack dialect | SQLFluff dialect |
|---|---|---|
| PostgreSQL | `postgresql` | `postgres` |
| MySQL | `mysql` | `mysql` |
| SQLite | `sqlite` | `sqlite` |

SQLFluff dialect identifiers must not be confused with SQL Formatter dialect identifiers.

The default SQL dialect remains `postgresql`, which maps to SQLFluff's `postgres` dialect.

SQLFluff obtains the dialect from the SQL language pack's `resolve_dialect()` function. This keeps dialect precedence and validation centralized rather than introducing a second dialect-resolution system.

#### Neovim integration

The SQLFluff implementation is located at:

```text
lua/langs/sql/lint.lua
```

The SQL language-pack entry point initializes it through:

```lua
require("langs.sql.lint").setup()
```

SQLFluff initialization occurs independently of SQLS executable discovery. A missing `sqls` executable must not prevent SQLFluff from registering its automatic linting behavior.

The implementation uses native Neovim functionality:

- `vim.system()` to execute SQLFluff asynchronously.
- `vim.diagnostic` to publish and clear diagnostics.
- `vim.api.nvim_buf_attach()` to observe buffer changes and lifecycle events.
- `vim.defer_fn()` to debounce lint requests.
- `vim.schedule()` to perform editor API operations safely from process callbacks.

No `nvim-lint` plugin is required.

#### Lint behavior

The current implementation:

1. Runs SQLFluff against the SQL buffer content through standard input.
2. Passes the resolved dialect to SQLFluff.
3. Restricts the initial rule selection to `RF02` and `AM05`.
4. Requests JSON output.
5. Supplies `--stdin-filename` for named buffers so SQLFluff can discover project configuration.
6. Converts SQLFluff's one-based source positions to Neovim's zero-based diagnostic positions.
7. Publishes diagnostics under the `sqlfluff` source.
8. Clears stale diagnostics when the buffer changes.
9. Debounces automatic linting by 500 milliseconds.
10. Rejects stale process results when a newer request or buffer edit supersedes them.
11. Stops superseded processes where possible.
12. Handles missing executables and process-start failures without crashing Neovim.

The initial configured rules are:

| Rule | Purpose |
|---|---|
| `RF02` | Detects unqualified column references in queries with multiple referenced tables or views |
| `AM05` | Requires fully qualified join clauses |

These rules are the initial integration baseline, not a complete SQL quality policy. Rule selection can evolve through explicit evaluation and project configuration.

#### Configuration ownership

SQLFluff supports project-level configuration through `.sqlfluff`.

The integration does not add a repository-wide `.sqlfluff` file or hardcode project-specific rule settings. SQLFluff remains responsible for discovering project configuration from the SQL file's location.

The `--stdin-filename` argument is important because the buffer content is sent through standard input. It gives SQLFluff a filename context for configuration discovery.

The SQL language pack supplies the dialect and initial rule selection. Project configuration remains external and can provide additional SQLFluff settings.

#### Evaluation and integration verification

SQLFluff 4.5.0 was evaluated independently before integration approval.

The evaluation covered:

- PostgreSQL, MySQL, and SQLite dialect invocation.
- Parsing and lint-rule behavior.
- Project-level `.sqlfluff` configuration discovery.
- Standard-input linting with `--stdin-filename`.
- JSON diagnostic output.
- Diagnostic source positions and ranges.
- Diagnostic replacement and clearing.
- Asynchronous process handling.
- Stale-result protection.
- Latest-request-wins behavior.
- Process cancellation.
- Missing-executable handling.
- Malformed JSON and process-start error handling.
- Debounced buffer-change linting.
- Separation from SQL Formatter.
- Operation without a live database connection.

The actual Neovim integration was verified with SQLFluff 4.5.0.

The real-buffer test produced two expected diagnostics:

```text
sqlfluff RF02 Unqualified reference 'id' found in select with more than one referenced table/view.
sqlfluff AM05 Join clauses should be fully qualified.
```

After correcting the SQL query, the diagnostic count returned to zero:

```text
Initial diagnostics: 2
Diagnostics after correction: 0
PASS: real SQLFluff integration, diagnostics, and re-linting
```

Additional setup tests verified:

- Initial linting of the current SQL buffer.
- Automatic linting when entering another SQL buffer.
- Idempotent setup without duplicate `BufEnter` autocmds.
- SQLFluff initialization when SQLS is unavailable.

These tests establish the initial static-analysis integration. They do not establish complete SQLFluff rule coverage or database-engine equivalence.

#### Formatting boundary

SQLFluff must remain a linter in the editor workflow.

Its formatting and automatic-fix capabilities must not compete with the approved SQL Formatter workflow.

Conform remains the formatting owner. SQLFluff must not be configured as a formatter or used for automatic fixing as part of the default SQL editing workflow.

## 4. Architecture and Configuration Ownership

### 4.1 Optional Language Pack

The SQL module is:

```text
lua/langs/sql.lua
```

The SQLFluff implementation is:

```text
lua/langs/sql/lint.lua
```

The pack is discovered through the existing language-pack registry and remains inactive unless explicitly enabled.

The registry consumes the following SQL metadata:

- `setup`
- `formatters`
- `parser_by_filetype`

The SQL module is responsible for:

1. SQLS configuration and activation.
2. SQLFluff initialization.
3. SQL parser metadata.
4. SQL formatter metadata.
5. Dialect validation and resolution.
6. SQL workspace-root behavior.

The SQLFluff module is responsible for:

1. SQLFluff process execution.
2. Lint request lifecycle.
3. Buffer-change handling.
4. Diagnostic conversion and publication.
5. Stale-result protection.
6. Debounced automatic linting.

The implementation must not introduce a new language-pack registry contract.

Disabling SQL must prevent its setup function from running and exclude its metadata from shared collection.

### 4.2 Filetype Policy

The mandatory SQL filetype is:

```text
sql
```

The initial formatter and parser metadata must use this filetype.

A separate `mysql` filetype must not be introduced solely to select a formatter or linter dialect. MySQL behavior is selected through the existing dialect configuration mechanism.

Custom filetype registration must only be introduced when required by the project's filetype policy and validated against the selected server definition.

### 4.3 Configuration Ownership

| Configuration | Owner |
|---|---|
| Language-pack discovery and lifecycle | `lua/langs/init.lua` |
| SQL LSP configuration and activation | `lua/langs/sql.lua` |
| SQL workspace-root resolution | `lua/langs/sql.lua` |
| SQLFluff initialization | `lua/langs/sql.lua` |
| SQLFluff execution and diagnostics | `lua/langs/sql/lint.lua` |
| LSP server definitions | nvim-lspconfig |
| LSP client | Native Neovim LSP |
| Parser metadata | `lua/langs/sql.lua` |
| Parser installation | Shared Treesitter infrastructure |
| Formatter metadata | `lua/langs/sql.lua` |
| Formatter registration and execution | Shared Conform infrastructure |
| SQL formatter argument and working-directory callbacks | `lua/config/format.lua` |
| Dialect resolution | `lua/langs/sql.lua` |
| Formatter preferences | `lua/config/languages.lua` |
| Project dialect configuration | `.sql-formatter.json` |
| SQLFluff project configuration | `.sqlfluff` |
| SQLFluff rule selection and dialect mapping | `lua/langs/sql/lint.lua` |
| Database connection settings | External SQLS configuration |
| Database credentials | User-controlled external configuration |
| SQL Formatter installation | `scripts/core/windows/sql-formatter.ps1` |
| SQLS installation | Explicit Go-based installation |
| SQLFluff installation | Explicit external installation; project installer not yet approved |

Shared infrastructure must remain in its existing modules. The SQL pack should contain only the configuration required to integrate SQL with those systems.

## 5. Installation Requirements

SQL tooling follows the project's native-first dependency-management principles.

| Dependency | Purpose | Requirement |
|---|---|---|
| `sqls` | SQL language server | Required for SQLS language intelligence |
| `sql-formatter` | SQL formatting | Required for formatting |
| `sqlfluff` | SQL static analysis | Required for static analysis |
| Treesitter `sql` parser | Syntax parsing | Required editor support through shared infrastructure |
| Go | SQLS installation prerequisite | Required for the selected Go installation method |
| Node.js and npm | SQL Formatter installation prerequisites | Required for the selected npm installation method |
| Python | SQLFluff runtime | Required by the selected SQLFluff installation |
| `uv` | SQLFluff tool installation | Used by the validated Windows installation method |
| SQLS database drivers | Database integration | Validate through the selected SQLS distribution |
| Database clients | Database access | Optional |
| Database servers | Query execution and testing | Optional |

These dependencies are requirements of the optional SQL pack, not requirements of the base Neovim configuration.

The SQL pack must not install external tools during Neovim startup.

### 5.1 SQLS Installation

SQLS is distributed through Go.

The validated installation command was:

```powershell
go install github.com/sqls-server/sqls@v0.2.48
```

The resulting executable was verified:

```powershell
sqls --version
```

Observed version:

```text
sqls version Version:0.2.48, Revision:HEAD
```

The installation environment used Go 1.27.3.

The executable was available through the Go binary directory in the user's PATH.

The SQL pack must not install Go or SQLS during Neovim startup.

The current SQLS installation has been validated on Windows. A dedicated SQLS installer script and finalized dependency-manifest entry must not be assumed to exist until they are implemented and reviewed.

### 5.2 SQL Formatter Installation

The SQL Formatter installer is:

```text
scripts/core/windows/sql-formatter.ps1
```

It installs the pinned npm package:

```text
sql-formatter@15.9.0
```

The installer checks Node.js and npm prerequisites, installs the package globally when necessary, updates PATH according to its installation logic, and verifies the executable version.

The following behavior has been validated:

- PowerShell syntax validation.
- Initial installation.
- Executable discovery.
- Version verification.
- Repeated execution without reinstalling an already installed matching version.

The normal installation and idempotency paths passed. The `-Force` path remains unverified.

### 5.3 Treesitter Parser Installation

The SQL parser follows the existing shared Treesitter installation workflow.

The SQL language pack declares the parser through `parser_by_filetype`. The existing integration discovers and installs parsers for enabled language packs.

No SQL-specific parser installer is required.

Manual parser installation must not become the normal workflow.

### 5.4 Database Dependencies

Database clients, servers, and connection utilities remain optional.

The SQL editing baseline must work without a database server.

The SQL pack must not automatically install database infrastructure or store database credentials in the repository.

Database drivers, connection configuration, server availability, authentication, and schema-aware functionality must be validated as separate requirements.

### 5.5 SQLFluff Installation

The validated Windows installation used `uv`:

```powershell
uv tool install --python 3.14 sqlfluff==4.5.0
```

The installed SQLFluff version was:

```powershell
sqlfluff --version
```

Observed version: `4.5.0`.

The validation environment used Python 3.14.7.

SQLFluff was installed as an external tool. Its executable was available in the user's PATH.

The following boundaries remain in place:

- No SQLFluff installation occurs during Neovim startup.
- No SQLFluff installer script has been approved or added to the repository.
- No SQLFluff dependency-manifest entry has been approved or added.
- SQLFluff installation remains separate from plugin installation.
- The project must not assume that every platform uses the same Python or `uv` installation path.

A future installer and dependency-manifest entry require a separate implementation decision and validation.

## 6. Validation Results and Remaining Work

The primary validation environment is Windows with Neovim 0.12.6.

### 6.1 Lua and Repository Quality

The following checks passed after SQLFluff integration:

```powershell
stylua .\lua\langs\sql.lua
stylua --check .\lua\langs\sql.lua

nvim --headless -u NONE -l .\scripts\check-syntax.lua

git diff --check
```

The repository syntax checker reported:

```text
Syntax check passed: 66 Lua files.
```

The SQLFluff integration also passed formatting and syntax validation for its implementation file.

These checks confirm Lua syntax and formatting quality. They do not replace runtime or feature validation.

### 6.2 SQL Language Pack

Verified:

- SQL module loads.
- SQL formatter metadata is collected.
- SQL parser metadata is collected.
- SQL dialect defaults to PostgreSQL.
- Buffer-local dialect override works.
- Filetype-specific dialect override works.
- Global dialect fallback works.
- Project dialect discovery works.
- Invalid dialect handling is covered by runtime tests.
- Standalone workspace-root resolution works.
- Git workspace-root resolution works.
- Unnamed buffer fallback works.
- SQLS activation safely skips when the executable is unavailable.
- SQLFluff initializes independently of SQLS.

### 6.3 SQLS

Verified:

- SQLS executable discovery.
- SQLS startup through native Neovim LSP.
- Attachment to SQL buffers without a database connection.
- Standalone and Git workspace-root behavior.
- Keyword completion.
- Document formatting response.
- Seven returned code actions.

Not yet verified:

- Useful hover information beyond the tested keyword.
- Useful signature help beyond the tested function call.
- Schema-aware completion.
- Database-dependent diagnostics.
- Successful execution of database-management code actions.
- PostgreSQL, MySQL, and SQLite database connections.
- Multiple configured connection behavior.
- Database-driver compatibility for each supported database.

The absence of a database connection must not be treated as a SQLS startup failure.

### 6.4 SQL Formatter and Conform

Verified:

- SQL Formatter 15.9.0 installation.
- Executable discovery from Neovim.
- Conform formatter availability.
- Custom formatter callback registration.
- Dialect-aware argument generation for PostgreSQL, MySQL, and SQLite.
- Project-level SQLite dialect resolution.
- Formatter working-directory callback.
- Actual SQL formatting through Conform.

Remaining verification:

- Full project configuration discovery for options beyond `language`.
- Existing per-filetype formatter preference merging.
- Existing `:Format` and `<leader>cf` workflows in the normal interactive environment.
- Format-on-save opt-in behavior.
- LSP-formatting fallback opt-in behavior.
- Missing formatter executable behavior in a clean environment.

Format-on-save and LSP-formatting fallback remain disabled by default.

### 6.5 Treesitter

Automatic SQL parser installation was observed during Neovim testing.

Remaining verification:

- Successful parser installation.
- SQL syntax highlighting.
- Representative SQL parsing.
- PostgreSQL, MySQL, and SQLite syntax coverage.

### 6.6 SQLFluff

Verified:

- SQLFluff 4.5.0 installation and executable discovery.
- PostgreSQL, MySQL, and SQLite dialect mapping.
- SQLFluff lint execution through standard input.
- Project configuration discovery through `--stdin-filename`.
- JSON output parsing.
- Diagnostic position and range conversion.
- Diagnostic publication and replacement.
- Diagnostic clearing after correcting SQL.
- Diagnostic isolation across buffers.
- Changedtick stale-result protection.
- Latest-request-wins behavior.
- Process cancellation.
- Missing-executable handling.
- Malformed JSON and process-start error handling.
- Buffer lifecycle cleanup.
- Automatic linting on SQL buffer entry.
- Debounced linting after edits.
- Idempotent setup.
- Initialization independently of SQLS.
- Real-buffer linting with the actual SQLFluff executable.
- Operation without a live database connection.

The initial configured rules, `RF02` and `AM05`, were verified with real SQL input. Both diagnostics appeared for the deliberately invalid query and disappeared after the query was corrected.

Remaining work:

- Verify SQLFluff behavior with representative project-level `.sqlfluff` configurations.
- Evaluate additional lint rules before changing the initial rule selection.
- Validate the integration on other supported operating systems.
- Decide whether to add a dedicated SQLFluff installer and dependency-manifest entry.
- Verify the final installation workflow from a clean environment.

SQLFluff's formatting and automatic-fix features are not part of the editor integration.

## 7. Scope Boundaries

SQL support is an editor language-support baseline, not a complete database administration environment.

The following capabilities are outside the mandatory initial scope:

- Database server installation and management.
- Database migrations.
- Database administration interfaces.
- Database backup and recovery.
- Database monitoring.
- Database deployment workflows.
- Credential-management frameworks.
- Query execution frameworks.

The SQL pack remains focused on:

1. SQL filetype detection.
2. Language-server integration.
3. Syntax parsing.
4. SQL formatting.
5. Static analysis.
6. Explicit dialect configuration.
7. Optional database-aware language-server functionality.

Database-dependent capabilities must only be described as supported after their respective integration tests pass.

SQLFluff provides static analysis without requiring a live database connection. It does not replace database-engine validation or prove that a query will execute successfully against a particular database schema.

## 8. Completion Criteria

The initial SQL language pack can be marked complete when:

1. The SQL language pack is implemented and remains opt-in.
2. SQLS works through native Neovim LSP.
3. SQL filetype detection and database-independent startup are verified.
4. Standalone and Git workspace-root behavior are verified.
5. SQL Treesitter parser installation and functionality are verified.
6. SQL Formatter works through the existing Conform infrastructure.
7. PostgreSQL, MySQL, and SQLite formatting are verified.
8. Dialect precedence and invalid-value handling are verified.
9. Project-level formatter configuration is handled correctly.
10. Existing formatter preferences merge with pack defaults.
11. Format-on-save and LSP-formatting fallback remain disabled by default.
12. Explicit opt-in behavior for both formatting options is tested.
13. SQLS formatting capabilities remain available where supported.
14. SQLFluff static analysis works through native Neovim diagnostics.
15. SQLFluff dialect mapping and project configuration discovery are verified.
16. SQLFluff diagnostics are correctly published, updated, and cleared.
17. SQLFluff linting remains independent of SQLS and database connectivity.
18. Database connections and credentials remain external and optional.
19. SQL editing works without database infrastructure.
20. Windows installation and executable discovery are documented and reproducible.
21. External dependency versions are recorded in the appropriate dependency documentation.
22. Enabling SQL contributes its formatter and parser metadata.
23. Disabling SQL excludes its setup and metadata without affecting other language packs.
24. No duplicate shared infrastructure or startup installation mechanism is introduced.

Database-aware functionality must only be marked supported for database systems that pass their respective connection and integration tests.

SQLFluff integration is approved and has passed its initial real-buffer validation. Final cross-platform installation policy and any dedicated installer or dependency-manifest changes remain separate work.

Any behavior that has not been verified must remain explicitly documented as unverified or deferred.

## 9. Final Architecture Summary

| Area | Decision |
|---|---|
| Stage | 13 — Language Packs |
| Language pack | Optional, `lua/langs/sql.lua` |
| Registry contract | `setup`, `formatters`, `parser_by_filetype` |
| Language server | SQLS (`sqls`), approved |
| LSP implementation | Native Neovim LSP |
| LSP definitions | nvim-lspconfig |
| LSP configuration | `vim.lsp.config()` |
| LSP activation | `vim.lsp.enable()` |
| Workspace root | Git root or containing directory; cwd for unnamed buffers |
| Mandatory filetype | `sql` |
| Syntax parser | Treesitter `sql` |
| Parser installation | Shared Treesitter integration |
| Formatter | `sql-formatter` 15.9.0 |
| Conform formatter name | `sql_formatter` |
| Formatting integration | Existing Conform infrastructure |
| Formatter metadata | SQL pack |
| Formatter configuration | `lua/config/format.lua` |
| Dialect resolution | SQL pack |
| Default dialect | PostgreSQL |
| Initial dialects | PostgreSQL, MySQL, SQLite |
| Project dialect configuration | `.sql-formatter.json` |
| Manual formatting | Existing `:Format` and `<leader>cf` |
| Format-on-save | Disabled by default |
| LSP-formatting fallback | Disabled by default |
| Static-analysis tool | SQLFluff 4.5.0 |
| Static-analysis status | Approved and integrated |
| Static-analysis implementation | `lua/langs/sql/lint.lua` |
| Static-analysis execution | Native `vim.system()` |
| Diagnostic integration | Native `vim.diagnostic` |
| Initial SQLFluff rules | `RF02`, `AM05` |
| SQLFluff dialects | `postgres`, `mysql`, `sqlite` |
| SQLFluff project configuration | `.sqlfluff` |
| SQLFluff installation | External `uv` tool installation |
| SQLFluff project installer | Not yet implemented or approved |
| Database connections | Explicit, external, user-controlled |
| Database clients | Optional |
| Database servers | Optional |
| Plugin management | Native `vim.pack` |
| External tool installation | Explicit installation workflow |
| Mason | Not permitted |
| lazy.nvim | Not permitted |

---

## Upstream References

### Language server

- [SQLS repository](https://github.com/sqls-server/sqls)
- [SQLS README and configuration](https://github.com/sqls-server/sqls/blob/master/README.md)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)

### Formatting

- [SQL Formatter repository](https://github.com/sql-formatter-org/sql-formatter)
- [SQL Formatter dialect documentation](https://github.com/sql-formatter-org/sql-formatter/blob/master/docs/dialect.md)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)

### Static analysis

- [SQLFluff documentation](https://docs.sqlfluff.com/en/stable/)
- [SQLFluff repository](https://github.com/sqlfluff/sqlfluff)
- [SQLFluff rule reference](https://docs.sqlfluff.com/en/stable/reference/rules/)
- [SQLFluff dialect reference](https://docs.sqlfluff.com/en/stable/reference/dialects/)
- [SQLFluff configuration](https://docs.sqlfluff.com/en/stable/configuration/)
- [uv documentation](https://docs.astral.sh/uv/)

### Editor infrastructure

- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [Neovim Treesitter documentation](https://neovim.io/doc/user/treesitter.html)

Upstream documentation must be checked against the actual dependency versions selected by the project. Moving upstream branches must not be treated as proof that a pinned version provides identical behavior.

---

**Document:** `docs/architecture/sql-support.md`

**Document status:** SQL language-server, formatting, and initial static-analysis integrations implemented and verified. Final Treesitter and database-dependent validation remains in progress.

**Stage:** 13 — Language Packs.

**Dependency decisions:**

- SQLS: Approved.
- `sql-formatter`: Approved.
- SQL Treesitter parser: Shared integration.
- SQLFluff: Approved and integrated for static analysis.

**Implementation status:** Core LSP, formatting, dialect resolution, and SQLFluff diagnostic integration verified. Treesitter functionality and database-dependent capabilities remain subject to the outstanding validation requirements.
