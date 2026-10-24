# ADR: Zen Mode Plugin

- **Status:** Deferred
- **Date:** 2026-10-24

## Context

This project follows a native-first approach to Neovim configuration. Built-in functionality and existing plugins should be evaluated before adding dependencies for optional interface enhancements.

Zen mode is a focused-editing presentation that reduces visual distractions while working in a buffer. A dedicated plugin such as `zen-mode.nvim` may provide a convenient way to manage that presentation, but its usefulness must be assessed against the project's existing configuration and dependency policy.

The project has not approved a dedicated zen-mode plugin for installation. This decision record preserves the question for evaluation during **Stage 15 — UI Polish**.

## Decision

**Defer the decision on `zen-mode.nvim` until Stage 15.**

Do not add the plugin solely to provide a distraction-free editing mode before evaluating the relevant native options and existing UI configuration.

The evaluation must establish whether a dedicated plugin provides meaningful functionality beyond what the project can reasonably implement with built-in Neovim options and existing configuration.

This record does not authorize installation. Any eventual adoption must be explicit and reflected in the plugin inventory, dependency documentation, and relevant configuration.

## Alternatives Considered

### 1. Use native Neovim options

Implement a focused-editing mode using relevant built-in options and reversible state changes.

**Advantages**
- Avoids an additional plugin dependency.
- Aligns with the project's native-first architecture.
- Keeps behavior close to the configuration it modifies.
- Allows the implementation to be tailored to the project's actual requirements.

**Trade-offs**
- Requires careful handling of option state and restoration.
- May require additional logic to coordinate window layout and other interface elements.
- Can become unnecessarily complex if it attempts to reproduce a dedicated plugin's broader behavior.

### 2. Adopt `zen-mode.nvim`

Evaluate a dedicated plugin for managing a distraction-free editing layout.

**Advantages**
- May provide a more complete and convenient focused-editing workflow.
- Could reduce the amount of custom configuration required.
- May handle layout and state restoration more comprehensively than a minimal native implementation.

**Trade-offs**
- Adds a third-party dependency.
- Introduces external behavior and maintenance considerations.
- May overlap with existing UI configuration or built-in capabilities.
- Requires compatibility and integration testing against the project's supported Neovim version.

### 3. Do not provide a dedicated zen mode

Keep the current interface configuration and use existing window-management commands and options when a less distracting layout is needed.

**Advantages**
- Adds no dependencies or custom implementation.
- Keeps the configuration minimal.
- Avoids maintaining a feature that may not justify its complexity.

**Trade-offs**
- Provides less convenience than a coordinated focused-editing workflow.
- May leave a useful interface improvement unaddressed if the need is established later.

## Evaluation Criteria

Evaluate the alternatives against the following criteria during Stage 15:

1. **Functional need:** Identify the specific distractions the mode should remove and whether the project genuinely needs a dedicated workflow.
2. **Native capability:** Determine which requirements can be met reliably with built-in options and existing configuration.
3. **State restoration:** Verify that entering and leaving the mode restores the user's previous option values and relevant window state.
4. **Integration:** Check for conflicts with existing window management, statusline, tabline, and other UI behavior.
5. **Complexity:** Compare the maintenance cost of a native implementation with the cost of adopting and configuring a plugin.
6. **Compatibility:** Confirm that the selected approach works with the minimum supported Neovim version, currently Neovim 0.12 or later.
7. **Usability:** Ensure that entering and exiting the mode is predictable, discoverable, and documented.
8. **Reversibility:** Ensure that the feature does not permanently alter unrelated configuration or user preferences.

## Consequences

Until the evaluation is complete:

- `zen-mode.nvim` is not an approved dependency.
- No plugin installation or configuration change is implied by this ADR.
- The project may continue using native window-management features and its existing UI configuration.
- The decision can be revisited when Stage 15 establishes the actual requirements for UI polish.

If the native approach meets the requirements with acceptable complexity, prefer it. Adopt a dedicated plugin only when its demonstrated benefits justify the additional dependency.

## Validation

Before accepting a final implementation:

- Test entering and exiting the mode in a real Neovim session.
- Verify that relevant option values and window state are restored correctly.
- Check integration with existing UI and window-management behavior.
- Run the project's applicable syntax and smoke checks.
- Verify behavior on the minimum supported Neovim version.
- Document any limitations and the reasoning behind the final choice.

Validation must reflect the implementation actually selected. Do not mark the decision accepted based on a proposed design alone.

## Follow-up

Revisit this ADR during **Stage 15 — UI Polish**.

At that point, choose one outcome:

- **Accepted:** Adopt `zen-mode.nvim` after evaluating and validating its benefits.
- **Rejected:** Keep the feature native or omit a dedicated zen mode because the plugin does not justify its cost.
- **Deferred:** Retain the decision for a clearly documented reason if the requirements or evidence remain insufficient.

Update the status and document the final rationale when the decision is made.
