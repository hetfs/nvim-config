# Architecture Decision Records

## Purpose

This directory contains Architecture Decision Records (ADRs) for significant design choices in `nvim-config`.

ADRs preserve the reasoning behind decisions so future changes can be evaluated against the project's requirements rather than relying on assumptions or familiarity with other Neovim distributions.

The project follows this principle:

> **Minimum installation. Compose the rest.**

## What Belongs Here

Create an ADR when a decision materially affects the configuration's architecture, dependencies, plugin selection, maintenance, or future direction.

Examples include:

- Choosing native Neovim functionality over a plugin.
- Accepting, deferring, or rejecting a plugin.
- Selecting an approach to language-server configuration.
- Deciding whether a project-root or distraction-free editing plugin is justified.
- Establishing a dependency-management or compatibility policy.

Routine implementation details do not need a separate ADR unless they establish a decision that future contributors need to understand.

## Decision Principles

Evaluate decisions against the following principles:

1. **Native-first:** Prefer Neovim's built-in capabilities when they adequately satisfy the requirement.
2. **Explicit admission:** A plugin is not installed merely because it has been proposed or documented.
3. **Minimal dependencies:** Every additional dependency must provide a clear benefit.
4. **Stage alignment:** Decisions should respect the current implementation stage and avoid premature integration.
5. **Compatibility:** Preserve the project's minimum supported Neovim version.
6. **Validation:** Important behavioral and compatibility claims should be supported by appropriate checks.
7. **Reversibility:** Prefer decisions that can be revised without unnecessary architectural disruption.
8. **Documented trade-offs:** Record meaningful disadvantages and unresolved questions, not just benefits.

## Decision Status

Use one of the following statuses:

- **Proposed** — under evaluation; not approved for implementation.
- **Accepted** — approved direction; implementation may still be pending.
- **Deferred** — intentionally postponed until specified conditions are met.
- **Rejected** — evaluated and not selected for the current architecture.
- **Superseded** — replaced by a later decision; retain the record for historical context.

An **Accepted** decision does not by itself prove that implementation is complete.

## ADR Format

Use this structure for new records:

```markdown
# ADR NNN: Decision Title

- **Status:** Proposed
- **Date:** YYYY-MM-DD

## Context

Describe the requirement, problem, and relevant constraints.

## Decision

State the chosen direction clearly.

## Alternatives Considered

List meaningful alternatives and why they were considered.

## Consequences

Describe benefits, trade-offs, risks, and maintenance implications.

## Validation

Describe how the decision or resulting implementation will be verified.

## Follow-up

List remaining work, prerequisites, or conditions for reconsideration.
```

Use sequential numbers for new ADRs and descriptive filenames, for example `001-lspconfig.md`. Do not reuse a number for a different decision.

## Changing a Decision

When a decision changes:

1. Review the original rationale and its consequences.
2. Create a new ADR if the change is architecturally significant.
3. Mark the earlier record **Superseded** and link to the replacement.
4. Update affected implementation and supporting documentation.
5. Validate the resulting configuration before declaring the change complete.

Avoid silently rewriting historical decisions to make them appear as though the current direction had always been chosen.

## Current Decision Records

This directory is intended to contain records for decisions such as:

- `project-plugin.md` — whether a dedicated project-management plugin is justified.
- `zen-mode.md` — whether a dedicated distraction-free editing plugin is justified.
- `lspconfig.md` — whether `nvim-lspconfig` is necessary alongside Neovim's native LSP APIs.

These records must accurately reflect their actual status. A listed filename is not evidence that the decision has been finalized or that a plugin has been admitted.

## Relationship to Other Documentation

- `docs/architecture.md` describes the architecture currently intended for the project.
- `docs/roadmap.md` defines the staged implementation plan.
- `docs/plugin-inventory.md` tracks plugin choices and admission status.
- `docs/dependencies.md` documents external tools and dependency requirements.

ADRs explain *why* a significant decision was made. The other documents describe the resulting architecture, planned work, plugin status, and dependencies.
