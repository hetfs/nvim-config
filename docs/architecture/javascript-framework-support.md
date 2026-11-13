# JavaScript Framework Support

## Objective

Extend the existing JavaScript and TypeScript language packs to support React, React Native, Expo, and Next.js without duplicating language infrastructure.

## Architecture decisions

### 1. Shared language foundation

The existing language packs remain the owners of:

- JavaScript and TypeScript filetypes.
- JSX and TSX parser mappings.
- VTSLS integration.
- Prettier formatter metadata.
- Language-specific configuration.

No separate TypeScript language server or formatter should be introduced for individual frameworks.

### 2. Framework ownership

| Technology   | Responsibility                         |
| ------------ | -------------------------------------- |
| React        | JSX/TSX editing support                |
| React Native | Mobile project workflows               |
| Expo         | Expo project and development workflows |
| Next.js      | Next.js project workflows              |

React is a shared integration, not an independent language pack.

Expo extends React Native. An Expo project must not activate duplicate React Native workflows.

### 3. Project detection

Framework detection must use project evidence:

- `package.json` dependencies.
- Framework configuration files.
- Project-local scripts.
- Package-manager lockfiles.

Detection must be deterministic and must not depend on globally installed framework CLIs.

### 4. Dependency policy

- Reuse VTSLS.
- Reuse Tree-sitter.
- Reuse Conform.
- Reuse blink.cmp.
- Respect project-local dependencies.
- Never install npm packages automatically.
- Never introduce Mason.

### 5. Project workflows

Framework-specific workflows should be separated from language-server configuration.

Potential capabilities:

- Development server commands.
- Project-aware file navigation.
- Expo development workflows.
- Next.js development and build workflows.
- React Native Metro workflows.

Commands should use the project's package manager and declared scripts where appropriate.

### 6. Debugging

Debugging integration belongs to Stage 14. Do not introduce a framework-specific debugger during Stage 13.

## Implementation order

1. Validate existing JavaScript and TypeScript foundations.
2. Validate React JSX/TSX support.
3. Implement React Native project support.
4. Extend React Native support with Expo.
5. Implement Next.js project support.
6. Add project-aware workflows.
7. Add automated and interactive regression tests.

## Acceptance criteria

- Existing JavaScript and TypeScript functionality remains unchanged.
- JSX and TSX receive correct parser and LSP support.
- React Native projects are detected correctly.
- Expo projects are identified without duplicate React Native activation.
- Next.js projects are detected correctly.
- Project-local tooling is respected.
- Missing dependencies produce actionable diagnostics.
- No automatic package installation occurs.
- Existing language-pack activation remains explicit.
- Smoke tests and interactive checks pass.

## Compatibility

- Minimum Neovim version: 0.12.
- Plugin management: native `vim.pack`.
- Existing language-pack registry remains authoritative.
- Existing formatter resolution remains authoritative.
- Lazy loading remains deferred to Stage 16.

## Status

Architecture proposal. Runtime implementation and validation are pending.
