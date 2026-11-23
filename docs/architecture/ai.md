## AI Integration Architecture

| Field | Value |
|---|---|
| **Project** | `nvim-config` |
| **Document** | `docs/architecture/ai.md` |
| **Status** | Proposed |
| **Target Neovim version** | 0.13 |
| **Minimum Neovim version** | 0.12 |
| **Audience** | Maintainers and contributors |

## 1. Purpose

This document defines the architecture, responsibilities, activation policies, integration boundaries, and implementation requirements for AI capabilities in `nvim-config`.

AI is an editor-wide capability, not a language-specific feature. AI integrations MUST remain independent of language-pack activation and MUST NOT replace native Neovim functionality or existing language tooling.

The architecture follows the project's core principle:

> Minimum installation. Compose the rest.

The implementation MUST prioritize:

- Native Neovim functionality.
- Explicit configuration and activation.
- Minimal dependencies.
- Independent provider lifecycle management.
- Reuse of the existing `vim.pack` installation mechanism.
- Local inference support without mandatory cloud services.
- Predictable startup behavior.
- Clear separation between AI providers and language packs.

## 2. Design principles

### 2.1 Native-first integration

AI integrations MUST complement the existing Neovim architecture.

They MUST NOT replace:

- Native LSP configuration and activation.
- Native diagnostics.
- Blink completion.
- Conform formatting.
- Tree-sitter syntax parsing.
- Existing language-pack workflows.
- Native keymap management.

AI-assisted editing MUST remain an optional workflow.

### 2.2 Independent activation

AI providers MUST be controlled independently of language packs.

The AI registry MUST NOT be placed inside `lua/config/languages.lua`.

Language-pack activation remains controlled by:

`lua/config/languages.lua`

AI activation is controlled by:

`lua/config/ai.lua`

This separation allows users to enable AI without activating additional language packs.

### 2.3 Explicit provider ownership

Each AI provider MUST own its:

- Plugin installation declaration.
- Plugin initialization.
- Provider-specific configuration.
- Model and backend settings.
- Provider-specific dependencies.

The shared AI registry MUST only control activation decisions.

Provider configuration MUST NOT be duplicated in the shared registry.

### 2.4 Optional infrastructure

An inference server MUST NOT become a mandatory Neovim startup dependency.

If a local inference server is unavailable:

- Neovim MUST still start normally.
- Other plugins MUST remain operational.
- Language packs MUST remain unaffected.
- AI requests MAY fail with a clear connection error.

The configuration MUST NOT attempt to install, start, or manage an inference server automatically.

## 3. Architecture overview

AI integrations consist of three independent layers.

| Layer | Responsibility |
|---|---|
| AI registry | Controls global and provider activation |
| Provider modules | Install, initialize, and configure individual AI plugins |
| Inference backend | Executes model inference outside Neovim |

The architecture is:

```text
                    init.lua
                       |
                       v
                 config.ai.lua
                       |
                Global AI switch
                       |
             +---------+---------+
             |                   |
             v                   v
        blink-edit          CodeCompanion
             |                   |
             v                   v
       Next-edit             Chat and
       predictions         inline editing
             |                   |
             +---------+---------+
                       |
                       v
                Inference backend
                       |
                       v
                 Local models
```

The AI registry controls provider activation. It does not control the inference server or language-pack lifecycle.

## 4. Directory structure

The AI implementation uses the existing configuration and plugin module conventions.

```text
lua/
├── config/
│   ├── ai.lua
│   └── languages.lua
│
├── langs/
│   ├── init.lua
│   └── ...
│
└── plugins/
    ├── blink-edit.lua
    └── codecompanion.lua

docs/
└── architecture/
    └── ai.md
```

Responsibilities:

| File | Responsibility |
|---|---|
| `lua/config/ai.lua` | Global AI and provider activation |
| `lua/plugins/blink-edit.lua` | Next-edit prediction provider |
| `lua/plugins/codecompanion.lua` | AI chat and inline editing provider |
| `init.lua` | Conditional provider initialization |
| `docs/architecture/ai.md` | AI architecture and implementation requirements |

No separate AI plugin manager or language-specific AI registry is required.

## 5. AI registry

### 5.1 Configuration

The AI registry is defined in `lua/config/ai.lua`.

```lua
-- User-defined AI integration preferences.
--
-- AI providers are independent of language-pack activation.
--
-- Policy:
--   enabled:
--     Enable or disable AI integrations globally.
--
--   providers:
--     Enable or disable individual AI providers.
--     A provider is initialized only when both the
--     global switch and its provider switch are enabled.

return {
  -- Global AI activation.
  -- Disabled by default.
  enabled = false,

  -- Individual provider activation.
  providers = {
    blink_edit = false,
    codecompanion = false,
  },
}
```

### 5.2 Activation policy

A provider MUST only initialize when both conditions are satisfied:

1. `ai.enabled` is `true`.
2. Its corresponding provider entry is `true`.

| Global AI | Provider | Result |
|---|---|---|
| Disabled | Disabled | Provider remains inactive |
| Disabled | Enabled | Provider remains inactive |
| Enabled | Disabled | Provider remains inactive |
| Enabled | Enabled | Provider initializes |

All providers MUST be disabled by default.

### 5.3 Configuration validation

The registry MUST be validated before provider initialization.

The following conditions MUST be enforced:

- `enabled` MUST be a boolean.
- `providers` MUST be a table.
- Provider names MUST be non-empty strings.
- Provider activation values MUST be booleans.

Unknown provider entries SHOULD be rejected rather than silently ignored. This prevents misspelled configuration keys from appearing to work.

## 6. Startup integration

### 6.1 Explicit initialization

AI providers MUST be initialized explicitly from `init.lua`.

The initialization MUST remain conditional and MUST NOT depend on `require("langs").setup()`.

The intended implementation is:

```lua
-- Optional AI integrations.
--
-- AI activation is independent of language-pack activation.
local ai = require("config.ai")

assert(
  type(ai.enabled) == "boolean",
  "AI configuration 'enabled' must be boolean"
)

assert(
  type(ai.providers) == "table",
  "AI configuration must define a 'providers' table"
)

for name, enabled in pairs(ai.providers) do
  assert(
    type(name) == "string" and name ~= "",
    "AI provider names must be non-empty strings"
  )

  assert(
    type(enabled) == "boolean",
    string.format(
      "AI provider configuration for '%s' must be boolean",
      name
    )
  )
end

if ai.enabled then
  if ai.providers.blink_edit then
    require("plugins.blink-edit").setup()
  end

  if ai.providers.codecompanion then
    require("plugins.codecompanion").setup()
  end
end
```

This replaces unconditional initialization of `blink-edit`.

### 6.2 Startup requirements

When AI is disabled:

- Provider modules MUST NOT be initialized.
- Provider setup functions MUST NOT execute.
- AI-specific configuration MUST NOT interfere with startup.
- The existing language and plugin initialization sequence MUST remain unchanged.

When AI is enabled, only explicitly enabled providers MUST initialize.

The configuration MUST NOT attempt to connect to an inference server during startup merely to determine whether the server is available.

## 7. AI providers

### 7.1 blink-edit.nvim

**Purpose:** AI-powered next-edit predictions.

`blink-edit.nvim` provides predictive editing functionality through an inference backend.

Its responsibility is limited to suggesting likely next edits based on editor context and the configured model.

It MUST remain independent of CodeCompanion.

#### Configuration ownership

`lua/plugins/blink-edit.lua` owns:

- Plugin initialization.
- Backend configuration.
- Model selection.
- Request parameters.
- Context collection.
- Prediction behavior.
- UI settings.

The existing configuration uses:

```lua
llm = {
  provider = "sweep",
  backend = "openai",
  url = "http://localhost:8000",
  model = "sweep",
}
```

This configuration represents the existing Sweep-compatible inference endpoint.

The endpoint MUST be verified before enabling the provider. It MUST NOT be assumed to be available simply because CodeCompanion has been configured.

#### Activation

```lua
providers = {
  blink_edit = false,
}
```

`blink-edit` remains disabled by default.

Its backend and model settings MUST NOT be copied into `lua/config/ai.lua`.

### 7.2 CodeCompanion.nvim

**Purpose:** AI chat, contextual assistance, and inline editing.

CodeCompanion provides an interaction layer between Neovim and language models or external coding agents.

Its responsibilities include:

- Interactive AI conversations.
- Code explanations.
- Refactoring assistance.
- Inline code generation.
- Inline code editing.
- Editor-context integration.
- Review of AI-generated changes.
- Optional extensions and tools.

CodeCompanion MUST remain independent of language-pack activation.

#### Installation

CodeCompanion is installed through Neovim's native `vim.pack` mechanism.

The provider module owns its installation declaration and initialization.

Required dependency:

- `plenary.nvim`

Core installation:

```lua
local function install()
  vim.pack.add({
    "https://github.com/nvim-lua/plenary.nvim",
  })

  vim.pack.add({
    {
      src = "https://github.com/olimorris/codecompanion.nvim",
      version = vim.version.range("^19.0.0"),
    },
  })
end
```

The plugin MUST be pinned to a release range rather than tracking an unrestricted development branch.

The Plenary dependency MUST remain available on its compatible default branch, as recommended by CodeCompanion's installation documentation.

#### Initialization

CodeCompanion MUST be initialized only after its plugin and required dependency are available.

```lua
require("codecompanion").setup({
  interactions = {
    chat = {
      adapter = {
        name = "ollama",
        model = "qwen2.5-coder:7b",
      },
    },

    inline = {
      adapter = {
        name = "ollama",
        model = "qwen2.5-coder:7b",
      },
    },
  },
})
```

The selected model MUST exist in the local Ollama installation.

The model name MUST match the tag reported by:

```powershell
ollama list
```

#### Chat interaction

The chat interaction provides a dedicated conversation buffer.

Command:

```vim
:CodeCompanionChat
```

Users can ask questions, provide editor context, and discuss code without directly modifying the current buffer.

#### Inline interaction

The inline interaction provides AI-assisted editing in the current buffer.

Command:

```vim
:CodeCompanion
```

Users can request changes to the current buffer or a visual selection.

Inline editing uses the model's tool-calling capabilities to apply changes. The configured model MUST support the required tool-calling behavior.

Generated changes MUST remain reviewable. Users MUST be able to accept or reject proposed changes.

CodeCompanion's inline interaction and chat interaction are separate workflows. A model working successfully in chat does not automatically prove that it supports inline editing.

#### Activation

```lua
providers = {
  codecompanion = false,
}
```

CodeCompanion remains disabled by default.

## 8. Inference backend architecture

### 8.1 Separation of concerns

An inference backend is an external service responsible for running a model and processing requests.

Neovim plugins act as clients.

The architecture MUST distinguish:

| Component | Responsibility |
|---|---|
| Neovim | Editor and integration host |
| AI provider | User interaction and request construction |
| Inference backend | Model execution and request processing |
| Language model | Text generation and code assistance |

The inference backend MUST NOT be treated as a Neovim plugin.

It MUST NOT be installed or managed by the AI registry.

### 8.2 Ollama

Ollama is the selected local inference backend for the initial CodeCompanion integration.

Official website:

https://ollama.com/

Windows installation:

https://ollama.com/download/windows

Ollama provides a local HTTP API and supports model execution without requiring a remote AI service.

Its default local API endpoint is:

```text
http://localhost:11434
```

The initial model selection is:

```text
qwen2.5-coder:7b
```

The model MUST be downloaded before use:

```powershell
ollama pull qwen2.5-coder:7b
```

Verify installed models:

```powershell
ollama list
```

Verify connectivity:

```powershell
Test-NetConnection localhost -Port 11434
```

Expected result:

```text
TcpTestSucceeded : True
```

The Ollama server MUST be running before AI requests are sent.

### 8.3 Backend independence

The backend MUST remain independently managed.

The AI provider configuration MUST NOT:

- Start Ollama automatically.
- Stop Ollama when Neovim exits.
- Install models automatically.
- Modify system-level backend settings.
- Require an active network connection during Neovim startup.

Other compatible backends MAY be integrated later without changing the AI registry architecture.

Potential future backends include:

- llama.cpp server.
- LM Studio.
- Other OpenAI-compatible local inference servers.
- Remote model providers.

A future backend integration MUST preserve the separation between provider configuration and backend management.

## 9. Security and privacy

AI integrations can transmit source code, editor context, selected text, diagnostics, and other project information.

The configuration MUST make this behavior explicit.

### 9.1 Local inference

Local inference SHOULD be preferred when source code must remain on the local machine.

However, local inference does not automatically guarantee complete isolation.

Users MUST understand that:

- Editor context can be included in requests.
- Model servers receive submitted content.
- External integrations may communicate with remote services.
- Plugin debugging can expose prompts and source code in logs.

### 9.2 Context sharing

Providers MUST share only the context required for their intended operation.

The following data SHOULD be treated as potentially sensitive:

- Current buffer contents.
- Visual selections.
- Project files.
- LSP diagnostics.
- Referenced definitions.
- Editor history.
- Terminal output.
- Environment variables and credentials.

Credentials, access tokens, passwords, and private keys MUST NOT be intentionally included in prompts or shared editor context.

### 9.3 Tool execution and editing

AI-generated changes MUST be reviewable.

Unrestricted command execution MUST NOT be enabled as an initial default.

Users MUST review proposed code changes and any requested external actions.

AI-generated code MUST be treated as untrusted until reviewed and tested.

### 9.4 Debug logging

Verbose provider logging MUST remain disabled by default.

Debug logs can contain prompts, editor context, source code, and request details.

Temporary debugging MUST use an explicit user-controlled setting.

## 10. Integration boundaries

AI integrations MUST respect existing configuration ownership.

| Existing component | AI integration boundary |
|---|---|
| `config.languages` | No dependency |
| `langs` | No dependency |
| Native LSP | AI may consume context but does not replace it |
| Blink completion | Separate completion workflow |
| Conform | AI does not replace formatting |
| Tree-sitter | Existing parser ownership remains unchanged |
| Keymaps | AI mappings require explicit registration |
| `vim.pack` | Existing native plugin installation mechanism |
| Project management | AI does not own project discovery |

### 10.1 Language independence

AI providers MUST NOT be implemented as language packs.

A provider MAY use language-specific context or tooling, but its activation MUST remain editor-wide.

### 10.2 Completion independence

CodeCompanion and `blink-edit` MUST NOT replace Blink completion.

Completion suggestions and AI-assisted editing are different workflows.

### 10.3 Formatting independence

AI-generated code MUST NOT automatically invoke formatting on save.

Conform remains responsible for formatting.

The existing manual formatting policy MUST remain unchanged:

- `:Format` remains available.
- Automatic formatting on save remains disabled by default.
- AI integrations MUST NOT modify formatter selection.

## 11. Keymap policy

AI integrations MUST NOT introduce global keymaps without explicit approval.

The existing centralized keymap architecture MUST remain authoritative.

Any future AI keymaps MUST:

- Be registered through the existing keymap module.
- Include descriptive labels.
- Avoid existing language, navigation, editing, and terminal namespaces.
- Be documented and tested before activation.

CodeCompanion's built-in commands MAY be used without adding custom global mappings.

Initial commands:

| Command | Purpose |
|---|---|
| `:CodeCompanionChat` | Open an AI chat |
| `:CodeCompanion` | Start inline editing |
| `:CodeCompanionActions` | Open the action palette |
| `:checkhealth codecompanion` | Check plugin health |

## 12. Dependencies

### 12.1 Required dependencies

| Dependency | Used by | Requirement |
|---|---|---|
| Neovim 0.12+ | AI integration | Required |
| `curl` | CodeCompanion HTTP requests | Required |
| `plenary.nvim` | CodeCompanion | Required |
| `blink-edit.nvim` | Predictive editing | Optional provider |
| `codecompanion.nvim` | AI chat and editing | Optional provider |
| Ollama | Local inference | Required for the selected local backend |

### 12.2 Optional dependencies

| Dependency | Purpose |
|---|---|
| Tree-sitter YAML parser | Prompt library and skills support |
| `ripgrep` | Search-related CodeCompanion tools |
| `MarkItDown` | Webpage retrieval with supported adapters |
| `sqlite3` | Reading Copilot tokens from a SQLite database |
| Image utilities | Image MIME-type detection |

Optional dependencies MUST NOT become mandatory startup requirements.

## 13. Error handling

AI failures MUST remain isolated from the rest of the configuration.

### 13.1 Plugin installation failure

If a provider cannot be installed, the failure SHOULD identify the provider and installation problem.

The configuration MUST NOT silently treat an unavailable plugin as initialized.

### 13.2 Module loading failure

If a provider module cannot be loaded, the error MUST identify the missing module.

For example:

```text
module 'codecompanion' not found
```

This indicates a plugin installation or runtime-path problem, not necessarily an inference backend problem.

### 13.3 Backend connection failure

A connection error such as:

```text
curl: (7) Failed to connect to localhost port 11434
```

indicates that the configured backend is unreachable.

The user SHOULD verify:

1. The backend is installed.
2. The backend process is running.
3. The configured port is correct.
4. The requested model is available.

### 13.4 Model errors

If a backend responds but cannot find the requested model, the user SHOULD verify the model name and installation.

If chat works but inline editing fails, model tool-calling support MUST be investigated separately.

### 13.5 Startup isolation

A backend connection failure MUST NOT prevent Neovim from starting.

Provider initialization SHOULD configure the client without requiring a successful inference request.

## 14. Installation and configuration workflow

The recommended implementation sequence is:

1. Create `lua/config/ai.lua`.
2. Add the AI registry validation and conditional initialization to `init.lua`.
3. Preserve the existing `lua/plugins/blink-edit.lua` module.
4. Add `lua/plugins/codecompanion.lua`.
5. Install CodeCompanion and Plenary through `vim.pack`.
6. Configure CodeCompanion to use the selected local Ollama model.
7. Install Ollama independently.
8. Download the selected model.
9. Verify backend connectivity.
10. Test CodeCompanion chat.
11. Test CodeCompanion inline editing.
12. Test `blink-edit` independently if enabled.
13. Document verified behavior and any remaining limitations.

Plugin installation and backend installation MUST remain separate operations.

## 15. Validation and testing

AI integrations MUST be validated independently.

### 15.1 Registry tests

- [ ] AI disabled: no AI provider initializes.
- [ ] AI enabled with both providers disabled: no provider initializes.
- [ ] AI enabled with only `blink_edit` enabled: only `blink-edit` initializes.
- [ ] AI enabled with only `codecompanion` enabled: only CodeCompanion initializes.
- [ ] Both providers enabled: both initialize independently.
- [ ] Invalid global activation values are rejected.
- [ ] Invalid provider activation values are rejected.
- [ ] Unknown provider entries are rejected.

### 15.2 Installation tests

- [ ] Plenary is installed.
- [ ] CodeCompanion is installed.
- [ ] The configured release is available.
- [ ] CodeCompanion is discoverable on the runtime path.
- [ ] `require("codecompanion")` succeeds.
- [ ] CodeCompanion setup completes.
- [ ] `:checkhealth codecompanion` reports no required dependency failures.

### 15.3 CodeCompanion chat tests

- [ ] `:CodeCompanionChat` opens a chat buffer.
- [ ] The configured Ollama adapter is selected.
- [ ] The requested model is available.
- [ ] A basic prompt receives a response.
- [ ] Editor context can be shared intentionally.
- [ ] Chat failure does not affect normal Neovim operation.

### 15.4 CodeCompanion inline tests

- [ ] `:CodeCompanion` opens the inline prompt.
- [ ] A simple code explanation request works.
- [ ] A small refactoring request produces a proposed change.
- [ ] The selected model supports the required tool-calling behavior.
- [ ] Proposed changes can be reviewed.
- [ ] Changes can be accepted.
- [ ] Changes can be rejected.
- [ ] Inline failure does not affect normal Neovim operation.

### 15.5 Backend tests

- [ ] Ollama is installed.
- [ ] Ollama starts independently of Neovim.
- [ ] The configured port is reachable.
- [ ] The selected model appears in `ollama list`.
- [ ] The Ollama API responds.
- [ ] Neovim starts when Ollama is unavailable.
- [ ] Backend connection errors are reported clearly.

### 15.6 Regression tests

- [ ] Language-pack activation remains unchanged.
- [ ] Native LSP remains operational.
- [ ] Blink completion remains operational.
- [ ] Conform formatting remains operational.
- [ ] Manual `:Format` remains available.
- [ ] Format-on-save remains disabled by default.
- [ ] Existing keymaps remain unchanged.
- [ ] No duplicate plugin installation mechanism is introduced.

## 16. Current implementation status

The following table distinguishes implemented configuration from behavior that still requires validation.

| Component | Status |
|---|---|
| Independent AI registry | Implemented |
| Global AI activation | Implemented |
| Independent provider switches | Implemented |
| Conditional provider initialization | Implemented |
| `blink-edit` provider module | Existing configuration |
| CodeCompanion provider module | Implemented |
| Native `vim.pack` installation | Implemented |
| Plenary dependency declaration | Implemented |
| CodeCompanion chat commands | Verified working |
| CodeCompanion inline command | Registered and executable |
| Ollama backend installation | Pending verification |
| Ollama model availability | Pending verification |
| CodeCompanion chat through Ollama | Pending verification |
| CodeCompanion inline editing through Ollama | Pending verification |
| `blink-edit` backend connectivity | Pending verification |
| AI-specific custom keymaps | Not implemented |

The status of individual components MUST be updated as testing progresses.

A command being registered does not establish that its model backend is operational.

## 17. Future considerations

Future integrations MAY include:

- Additional local inference backends.
- Remote AI providers.
- Additional CodeCompanion adapters.
- Project-specific AI rules.
- Reusable prompt collections.
- Model Context Protocol integrations.
- Agent Client Protocol integrations.
- AI-assisted code review.
- Explicit AI workflow keymaps.

These capabilities MUST be introduced only when there is a concrete requirement.

They MUST NOT introduce duplicate plugin managers, unnecessary abstraction layers, or coupling with language-pack activation.

## 18. Acceptance criteria

The AI architecture is considered complete when:

1. AI activation is independent of language-pack activation.
2. AI providers can be enabled and disabled independently.
3. Provider configuration remains owned by individual plugin modules.
4. Plugin installation uses the existing native `vim.pack` mechanism.
5. CodeCompanion supports the selected local inference backend.
6. Chat and inline editing are validated independently.
7. AI failures do not prevent Neovim startup.
8. Existing LSP, completion, formatting, and language workflows remain unchanged.
9. AI-specific keymaps do not conflict with existing mappings.
10. The implementation introduces no unnecessary plugin managers or framework dependencies.

## 19. References

### Project documentation

- [CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim)
- [CodeCompanion installation](https://codecompanion.olimorris.dev/installation)
- [CodeCompanion getting started](https://codecompanion.olimorris.dev/getting-started)
- [CodeCompanion running local models](https://codecompanion.olimorris.dev/guides/running-local-models)
- [CodeCompanion inline interaction](https://codecompanion.olimorris.dev/configuration/inline)
- [Neovim documentation](https://neovim.io/doc/user/)

### Inference backend

- [Ollama](https://ollama.com/)
- [Ollama Windows installation](https://ollama.com/download/windows)
- [Ollama API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)

### AI provider

- [blink-edit.nvim](https://github.com/BlinkResearchLabs/blink-edit.nvim)

---

**Architecture principle:** AI is an optional, editor-wide capability. Providers own their integrations, inference backends remain external, and native Neovim workflows remain authoritative. AI Integration Architecture

| Field | Value |
|---|---|
| **Project** | `nvim-config` |
| **Document** | `docs/architecture/ai.md` |
| **Status** | Proposed |
| **Target Neovim version** | 0.13 |
| **Minimum Neovim version** | 0.12 |
| **Audience** | Maintainers and contributors |

## 1. Purpose

This document defines the architecture, responsibilities, activation policies, integration boundaries, and implementation requirements for AI capabilities in `nvim-config`.

AI is an editor-wide capability, not a language-specific feature. AI integrations MUST remain independent of language-pack activation and MUST NOT replace native Neovim functionality or existing language tooling.

The architecture follows the project's core principle:

> Minimum installation. Compose the rest.

The implementation MUST prioritize:

- Native Neovim functionality.
- Explicit configuration and activation.
- Minimal dependencies.
- Independent provider lifecycle management.
- Reuse of the existing `vim.pack` installation mechanism.
- Local inference support without mandatory cloud services.
- Predictable startup behavior.
- Clear separation between AI providers and language packs.

## 2. Design principles

### 2.1 Native-first integration

AI integrations MUST complement the existing Neovim architecture.

They MUST NOT replace:

- Native LSP configuration and activation.
- Native diagnostics.
- Blink completion.
- Conform formatting.
- Tree-sitter syntax parsing.
- Existing language-pack workflows.
- Native keymap management.

AI-assisted editing MUST remain an optional workflow.

### 2.2 Independent activation

AI providers MUST be controlled independently of language packs.

The AI registry MUST NOT be placed inside `lua/config/languages.lua`.

Language-pack activation remains controlled by:

`lua/config/languages.lua`

AI activation is controlled by:

`lua/config/ai.lua`

This separation allows users to enable AI without activating additional language packs.

### 2.3 Explicit provider ownership

Each AI provider MUST own its:

- Plugin installation declaration.
- Plugin initialization.
- Provider-specific configuration.
- Model and backend settings.
- Provider-specific dependencies.

The shared AI registry MUST only control activation decisions.

Provider configuration MUST NOT be duplicated in the shared registry.

### 2.4 Optional infrastructure

An inference server MUST NOT become a mandatory Neovim startup dependency.

If a local inference server is unavailable:

- Neovim MUST still start normally.
- Other plugins MUST remain operational.
- Language packs MUST remain unaffected.
- AI requests MAY fail with a clear connection error.

The configuration MUST NOT attempt to install, start, or manage an inference server automatically.

## 3. Architecture overview

AI integrations consist of three independent layers.

| Layer | Responsibility |
|---|---|
| AI registry | Controls global and provider activation |
| Provider modules | Install, initialize, and configure individual AI plugins |
| Inference backend | Executes model inference outside Neovim |

The architecture is:

```text
                    init.lua
                       |
                       v
                 config.ai.lua
                       |
                Global AI switch
                       |
             +---------+---------+
             |                   |
             v                   v
        blink-edit          CodeCompanion
             |                   |
             v                   v
       Next-edit             Chat and
       predictions         inline editing
             |                   |
             +---------+---------+
                       |
                       v
                Inference backend
                       |
                       v
                 Local models
```

The AI registry controls provider activation. It does not control the inference server or language-pack lifecycle.

## 4. Directory structure

The AI implementation uses the existing configuration and plugin module conventions.

```text
lua/
├── config/
│   ├── ai.lua
│   └── languages.lua
│
├── langs/
│   ├── init.lua
│   └── ...
│
└── plugins/
    ├── blink-edit.lua
    └── codecompanion.lua

docs/
└── architecture/
    └── ai.md
```

Responsibilities:

| File | Responsibility |
|---|---|
| `lua/config/ai.lua` | Global AI and provider activation |
| `lua/plugins/blink-edit.lua` | Next-edit prediction provider |
| `lua/plugins/codecompanion.lua` | AI chat and inline editing provider |
| `init.lua` | Conditional provider initialization |
| `docs/architecture/ai.md` | AI architecture and implementation requirements |

No separate AI plugin manager or language-specific AI registry is required.

## 5. AI registry

### 5.1 Configuration

The AI registry is defined in `lua/config/ai.lua`.

```lua
-- User-defined AI integration preferences.
--
-- AI providers are independent of language-pack activation.
--
-- Policy:
--   enabled:
--     Enable or disable AI integrations globally.
--
--   providers:
--     Enable or disable individual AI providers.
--     A provider is initialized only when both the
--     global switch and its provider switch are enabled.

return {
  -- Global AI activation.
  -- Disabled by default.
  enabled = false,

  -- Individual provider activation.
  providers = {
    blink_edit = false,
    codecompanion = false,
  },
}
```

### 5.2 Activation policy

A provider MUST only initialize when both conditions are satisfied:

1. `ai.enabled` is `true`.
2. Its corresponding provider entry is `true`.

| Global AI | Provider | Result |
|---|---|---|
| Disabled | Disabled | Provider remains inactive |
| Disabled | Enabled | Provider remains inactive |
| Enabled | Disabled | Provider remains inactive |
| Enabled | Enabled | Provider initializes |

All providers MUST be disabled by default.

### 5.3 Configuration validation

The registry MUST be validated before provider initialization.

The following conditions MUST be enforced:

- `enabled` MUST be a boolean.
- `providers` MUST be a table.
- Provider names MUST be non-empty strings.
- Provider activation values MUST be booleans.

Unknown provider entries SHOULD be rejected rather than silently ignored. This prevents misspelled configuration keys from appearing to work.

## 6. Startup integration

### 6.1 Explicit initialization

AI providers MUST be initialized explicitly from `init.lua`.

The initialization MUST remain conditional and MUST NOT depend on `require("langs").setup()`.

The intended implementation is:

```lua
-- Optional AI integrations.
--
-- AI activation is independent of language-pack activation.
local ai = require("config.ai")

assert(
  type(ai.enabled) == "boolean",
  "AI configuration 'enabled' must be boolean"
)

assert(
  type(ai.providers) == "table",
  "AI configuration must define a 'providers' table"
)

for name, enabled in pairs(ai.providers) do
  assert(
    type(name) == "string" and name ~= "",
    "AI provider names must be non-empty strings"
  )

  assert(
    type(enabled) == "boolean",
    string.format(
      "AI provider configuration for '%s' must be boolean",
      name
    )
  )
end

if ai.enabled then
  if ai.providers.blink_edit then
    require("plugins.blink-edit").setup()
  end

  if ai.providers.codecompanion then
    require("plugins.codecompanion").setup()
  end
end
```

This replaces unconditional initialization of `blink-edit`.

### 6.2 Startup requirements

When AI is disabled:

- Provider modules MUST NOT be initialized.
- Provider setup functions MUST NOT execute.
- AI-specific configuration MUST NOT interfere with startup.
- The existing language and plugin initialization sequence MUST remain unchanged.

When AI is enabled, only explicitly enabled providers MUST initialize.

The configuration MUST NOT attempt to connect to an inference server during startup merely to determine whether the server is available.

## 7. AI providers

### 7.1 blink-edit.nvim

**Purpose:** AI-powered next-edit predictions.

`blink-edit.nvim` provides predictive editing functionality through an inference backend.

Its responsibility is limited to suggesting likely next edits based on editor context and the configured model.

It MUST remain independent of CodeCompanion.

#### Configuration ownership

`lua/plugins/blink-edit.lua` owns:

- Plugin initialization.
- Backend configuration.
- Model selection.
- Request parameters.
- Context collection.
- Prediction behavior.
- UI settings.

The existing configuration uses:

```lua
llm = {
  provider = "sweep",
  backend = "openai",
  url = "http://localhost:8000",
  model = "sweep",
}
```

This configuration represents the existing Sweep-compatible inference endpoint.

The endpoint MUST be verified before enabling the provider. It MUST NOT be assumed to be available simply because CodeCompanion has been configured.

#### Activation

```lua
providers = {
  blink_edit = false,
}
```

`blink-edit` remains disabled by default.

Its backend and model settings MUST NOT be copied into `lua/config/ai.lua`.

### 7.2 CodeCompanion.nvim

**Purpose:** AI chat, contextual assistance, and inline editing.

CodeCompanion provides an interaction layer between Neovim and language models or external coding agents.

Its responsibilities include:

- Interactive AI conversations.
- Code explanations.
- Refactoring assistance.
- Inline code generation.
- Inline code editing.
- Editor-context integration.
- Review of AI-generated changes.
- Optional extensions and tools.

CodeCompanion MUST remain independent of language-pack activation.

#### Installation

CodeCompanion is installed through Neovim's native `vim.pack` mechanism.

The provider module owns its installation declaration and initialization.

Required dependency:

- `plenary.nvim`

Core installation:

```lua
local function install()
  vim.pack.add({
    "https://github.com/nvim-lua/plenary.nvim",
  })

  vim.pack.add({
    {
      src = "https://github.com/olimorris/codecompanion.nvim",
      version = vim.version.range("^19.0.0"),
    },
  })
end
```

The plugin MUST be pinned to a release range rather than tracking an unrestricted development branch.

The Plenary dependency MUST remain available on its compatible default branch, as recommended by CodeCompanion's installation documentation.

#### Initialization

CodeCompanion MUST be initialized only after its plugin and required dependency are available.

```lua
require("codecompanion").setup({
  interactions = {
    chat = {
      adapter = {
        name = "ollama",
        model = "qwen2.5-coder:7b",
      },
    },

    inline = {
      adapter = {
        name = "ollama",
        model = "qwen2.5-coder:7b",
      },
    },
  },
})
```

The selected model MUST exist in the local Ollama installation.

The model name MUST match the tag reported by:

```powershell
ollama list
```

#### Chat interaction

The chat interaction provides a dedicated conversation buffer.

Command:

```vim
:CodeCompanionChat
```

Users can ask questions, provide editor context, and discuss code without directly modifying the current buffer.

#### Inline interaction

The inline interaction provides AI-assisted editing in the current buffer.

Command:

```vim
:CodeCompanion
```

Users can request changes to the current buffer or a visual selection.

Inline editing uses the model's tool-calling capabilities to apply changes. The configured model MUST support the required tool-calling behavior.

Generated changes MUST remain reviewable. Users MUST be able to accept or reject proposed changes.

CodeCompanion's inline interaction and chat interaction are separate workflows. A model working successfully in chat does not automatically prove that it supports inline editing.

#### Activation

```lua
providers = {
  codecompanion = false,
}
```

CodeCompanion remains disabled by default.

## 8. Inference backend architecture

### 8.1 Separation of concerns

An inference backend is an external service responsible for running a model and processing requests.

Neovim plugins act as clients.

The architecture MUST distinguish:

| Component | Responsibility |
|---|---|
| Neovim | Editor and integration host |
| AI provider | User interaction and request construction |
| Inference backend | Model execution and request processing |
| Language model | Text generation and code assistance |

The inference backend MUST NOT be treated as a Neovim plugin.

It MUST NOT be installed or managed by the AI registry.

### 8.2 Ollama

Ollama is the selected local inference backend for the initial CodeCompanion integration.

Official website:

https://ollama.com/

Windows installation:

https://ollama.com/download/windows

Ollama provides a local HTTP API and supports model execution without requiring a remote AI service.

Its default local API endpoint is:

```text
http://localhost:11434
```

The initial model selection is:

```text
qwen2.5-coder:7b
```

The model MUST be downloaded before use:

```powershell
ollama pull qwen2.5-coder:7b
```

Verify installed models:

```powershell
ollama list
```

Verify connectivity:

```powershell
Test-NetConnection localhost -Port 11434
```

Expected result:

```text
TcpTestSucceeded : True
```

The Ollama server MUST be running before AI requests are sent.

### 8.3 Backend independence

The backend MUST remain independently managed.

The AI provider configuration MUST NOT:

- Start Ollama automatically.
- Stop Ollama when Neovim exits.
- Install models automatically.
- Modify system-level backend settings.
- Require an active network connection during Neovim startup.

Other compatible backends MAY be integrated later without changing the AI registry architecture.

Potential future backends include:

- llama.cpp server.
- LM Studio.
- Other OpenAI-compatible local inference servers.
- Remote model providers.

A future backend integration MUST preserve the separation between provider configuration and backend management.

## 9. Security and privacy

AI integrations can transmit source code, editor context, selected text, diagnostics, and other project information.

The configuration MUST make this behavior explicit.

### 9.1 Local inference

Local inference SHOULD be preferred when source code must remain on the local machine.

However, local inference does not automatically guarantee complete isolation.

Users MUST understand that:

- Editor context can be included in requests.
- Model servers receive submitted content.
- External integrations may communicate with remote services.
- Plugin debugging can expose prompts and source code in logs.

### 9.2 Context sharing

Providers MUST share only the context required for their intended operation.

The following data SHOULD be treated as potentially sensitive:

- Current buffer contents.
- Visual selections.
- Project files.
- LSP diagnostics.
- Referenced definitions.
- Editor history.
- Terminal output.
- Environment variables and credentials.

Credentials, access tokens, passwords, and private keys MUST NOT be intentionally included in prompts or shared editor context.

### 9.3 Tool execution and editing

AI-generated changes MUST be reviewable.

Unrestricted command execution MUST NOT be enabled as an initial default.

Users MUST review proposed code changes and any requested external actions.

AI-generated code MUST be treated as untrusted until reviewed and tested.

### 9.4 Debug logging

Verbose provider logging MUST remain disabled by default.

Debug logs can contain prompts, editor context, source code, and request details.

Temporary debugging MUST use an explicit user-controlled setting.

## 10. Integration boundaries

AI integrations MUST respect existing configuration ownership.

| Existing component | AI integration boundary |
|---|---|
| `config.languages` | No dependency |
| `langs` | No dependency |
| Native LSP | AI may consume context but does not replace it |
| Blink completion | Separate completion workflow |
| Conform | AI does not replace formatting |
| Tree-sitter | Existing parser ownership remains unchanged |
| Keymaps | AI mappings require explicit registration |
| `vim.pack` | Existing native plugin installation mechanism |
| Project management | AI does not own project discovery |

### 10.1 Language independence

AI providers MUST NOT be implemented as language packs.

A provider MAY use language-specific context or tooling, but its activation MUST remain editor-wide.

### 10.2 Completion independence

CodeCompanion and `blink-edit` MUST NOT replace Blink completion.

Completion suggestions and AI-assisted editing are different workflows.

### 10.3 Formatting independence

AI-generated code MUST NOT automatically invoke formatting on save.

Conform remains responsible for formatting.

The existing manual formatting policy MUST remain unchanged:

- `:Format` remains available.
- Automatic formatting on save remains disabled by default.
- AI integrations MUST NOT modify formatter selection.

## 11. Keymap policy

AI integrations MUST NOT introduce global keymaps without explicit approval.

The existing centralized keymap architecture MUST remain authoritative.

Any future AI keymaps MUST:

- Be registered through the existing keymap module.
- Include descriptive labels.
- Avoid existing language, navigation, editing, and terminal namespaces.
- Be documented and tested before activation.

CodeCompanion's built-in commands MAY be used without adding custom global mappings.

Initial commands:

| Command | Purpose |
|---|---|
| `:CodeCompanionChat` | Open an AI chat |
| `:CodeCompanion` | Start inline editing |
| `:CodeCompanionActions` | Open the action palette |
| `:checkhealth codecompanion` | Check plugin health |

## 12. Dependencies

### 12.1 Required dependencies

| Dependency | Used by | Requirement |
|---|---|---|
| Neovim 0.12+ | AI integration | Required |
| `curl` | CodeCompanion HTTP requests | Required |
| `plenary.nvim` | CodeCompanion | Required |
| `blink-edit.nvim` | Predictive editing | Optional provider |
| `codecompanion.nvim` | AI chat and editing | Optional provider |
| Ollama | Local inference | Required for the selected local backend |

### 12.2 Optional dependencies

| Dependency | Purpose |
|---|---|
| Tree-sitter YAML parser | Prompt library and skills support |
| `ripgrep` | Search-related CodeCompanion tools |
| `MarkItDown` | Webpage retrieval with supported adapters |
| `sqlite3` | Reading Copilot tokens from a SQLite database |
| Image utilities | Image MIME-type detection |

Optional dependencies MUST NOT become mandatory startup requirements.

## 13. Error handling

AI failures MUST remain isolated from the rest of the configuration.

### 13.1 Plugin installation failure

If a provider cannot be installed, the failure SHOULD identify the provider and installation problem.

The configuration MUST NOT silently treat an unavailable plugin as initialized.

### 13.2 Module loading failure

If a provider module cannot be loaded, the error MUST identify the missing module.

For example:

```text
module 'codecompanion' not found
```

This indicates a plugin installation or runtime-path problem, not necessarily an inference backend problem.

### 13.3 Backend connection failure

A connection error such as:

```text
curl: (7) Failed to connect to localhost port 11434
```

indicates that the configured backend is unreachable.

The user SHOULD verify:

1. The backend is installed.
2. The backend process is running.
3. The configured port is correct.
4. The requested model is available.

### 13.4 Model errors

If a backend responds but cannot find the requested model, the user SHOULD verify the model name and installation.

If chat works but inline editing fails, model tool-calling support MUST be investigated separately.

### 13.5 Startup isolation

A backend connection failure MUST NOT prevent Neovim from starting.

Provider initialization SHOULD configure the client without requiring a successful inference request.

## 14. Installation and configuration workflow

The recommended implementation sequence is:

1. Create `lua/config/ai.lua`.
2. Add the AI registry validation and conditional initialization to `init.lua`.
3. Preserve the existing `lua/plugins/blink-edit.lua` module.
4. Add `lua/plugins/codecompanion.lua`.
5. Install CodeCompanion and Plenary through `vim.pack`.
6. Configure CodeCompanion to use the selected local Ollama model.
7. Install Ollama independently.
8. Download the selected model.
9. Verify backend connectivity.
10. Test CodeCompanion chat.
11. Test CodeCompanion inline editing.
12. Test `blink-edit` independently if enabled.
13. Document verified behavior and any remaining limitations.

Plugin installation and backend installation MUST remain separate operations.

## 15. Validation and testing

AI integrations MUST be validated independently.

### 15.1 Registry tests

- [ ] AI disabled: no AI provider initializes.
- [ ] AI enabled with both providers disabled: no provider initializes.
- [ ] AI enabled with only `blink_edit` enabled: only `blink-edit` initializes.
- [ ] AI enabled with only `codecompanion` enabled: only CodeCompanion initializes.
- [ ] Both providers enabled: both initialize independently.
- [ ] Invalid global activation values are rejected.
- [ ] Invalid provider activation values are rejected.
- [ ] Unknown provider entries are rejected.

### 15.2 Installation tests

- [ ] Plenary is installed.
- [ ] CodeCompanion is installed.
- [ ] The configured release is available.
- [ ] CodeCompanion is discoverable on the runtime path.
- [ ] `require("codecompanion")` succeeds.
- [ ] CodeCompanion setup completes.
- [ ] `:checkhealth codecompanion` reports no required dependency failures.

### 15.3 CodeCompanion chat tests

- [ ] `:CodeCompanionChat` opens a chat buffer.
- [ ] The configured Ollama adapter is selected.
- [ ] The requested model is available.
- [ ] A basic prompt receives a response.
- [ ] Editor context can be shared intentionally.
- [ ] Chat failure does not affect normal Neovim operation.

### 15.4 CodeCompanion inline tests

- [ ] `:CodeCompanion` opens the inline prompt.
- [ ] A simple code explanation request works.
- [ ] A small refactoring request produces a proposed change.
- [ ] The selected model supports the required tool-calling behavior.
- [ ] Proposed changes can be reviewed.
- [ ] Changes can be accepted.
- [ ] Changes can be rejected.
- [ ] Inline failure does not affect normal Neovim operation.

### 15.5 Backend tests

- [ ] Ollama is installed.
- [ ] Ollama starts independently of Neovim.
- [ ] The configured port is reachable.
- [ ] The selected model appears in `ollama list`.
- [ ] The Ollama API responds.
- [ ] Neovim starts when Ollama is unavailable.
- [ ] Backend connection errors are reported clearly.

### 15.6 Regression tests

- [ ] Language-pack activation remains unchanged.
- [ ] Native LSP remains operational.
- [ ] Blink completion remains operational.
- [ ] Conform formatting remains operational.
- [ ] Manual `:Format` remains available.
- [ ] Format-on-save remains disabled by default.
- [ ] Existing keymaps remain unchanged.
- [ ] No duplicate plugin installation mechanism is introduced.

## 16. Current implementation status

The following table distinguishes implemented configuration from behavior that still requires validation.

| Component | Status |
|---|---|
| Independent AI registry | Implemented |
| Global AI activation | Implemented |
| Independent provider switches | Implemented |
| Conditional provider initialization | Implemented |
| `blink-edit` provider module | Existing configuration |
| CodeCompanion provider module | Implemented |
| Native `vim.pack` installation | Implemented |
| Plenary dependency declaration | Implemented |
| CodeCompanion chat commands | Verified working |
| CodeCompanion inline command | Registered and executable |
| Ollama backend installation | Pending verification |
| Ollama model availability | Pending verification |
| CodeCompanion chat through Ollama | Pending verification |
| CodeCompanion inline editing through Ollama | Pending verification |
| `blink-edit` backend connectivity | Pending verification |
| AI-specific custom keymaps | Not implemented |

The status of individual components MUST be updated as testing progresses.

A command being registered does not establish that its model backend is operational.

## 17. Future considerations

Future integrations MAY include:

- Additional local inference backends.
- Remote AI providers.
- Additional CodeCompanion adapters.
- Project-specific AI rules.
- Reusable prompt collections.
- Model Context Protocol integrations.
- Agent Client Protocol integrations.
- AI-assisted code review.
- Explicit AI workflow keymaps.

These capabilities MUST be introduced only when there is a concrete requirement.

They MUST NOT introduce duplicate plugin managers, unnecessary abstraction layers, or coupling with language-pack activation.

## 18. Acceptance criteria

The AI architecture is considered complete when:

1. AI activation is independent of language-pack activation.
2. AI providers can be enabled and disabled independently.
3. Provider configuration remains owned by individual plugin modules.
4. Plugin installation uses the existing native `vim.pack` mechanism.
5. CodeCompanion supports the selected local inference backend.
6. Chat and inline editing are validated independently.
7. AI failures do not prevent Neovim startup.
8. Existing LSP, completion, formatting, and language workflows remain unchanged.
9. AI-specific keymaps do not conflict with existing mappings.
10. The implementation introduces no unnecessary plugin managers or framework dependencies.

## 19. References

### Project documentation

- [CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim)
- [CodeCompanion installation](https://codecompanion.olimorris.dev/installation)
- [CodeCompanion getting started](https://codecompanion.olimorris.dev/getting-started)
- [CodeCompanion running local models](https://codecompanion.olimorris.dev/guides/running-local-models)
- [CodeCompanion inline interaction](https://codecompanion.olimorris.dev/configuration/inline)
- [Neovim documentation](https://neovim.io/doc/user/)

### Inference backend

- [Ollama](https://ollama.com/)
- [Ollama Windows installation](https://ollama.com/download/windows)
- [Ollama API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)

### AI provider

- [blink-edit.nvim](https://github.com/BlinkResearchLabs/blink-edit.nvim)

---

**Architecture principle:** AI is an optional, editor-wide capability. Providers own their integrations, inference backends remain external, and native Neovim workflows remain authoritative.
