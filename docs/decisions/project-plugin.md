# ADR: Dedicated Project-Management Plugin

- **Status:** Deferred
- **Date:** 2026-10-24

## Context

The `nvim-config` project aims to provide useful project-aware workflows while preserving a native-first, modular architecture.

Project-management plugins can provide features such as project discovery, root detection, project switching, and integration with file navigation or session management. However, adding a dedicated plugin introduces another dependency and may duplicate behavior already available through Neovim, the shell environment, or existing navigation tools.

Stage 12 of the roadmap covers Git, project-root behavior, and sessions. The project must decide whether a dedicated project-management plugin is necessary before admitting one into the configuration.

The project's governing principle is:

> **Minimum installation. Compose the rest.**

## Decision

Defer the admission of a dedicated project-management plugin until Stage 12 evaluates the actual project-root and project-switching requirements.

No dedicated project-management plugin is approved for installation by this record.

The configuration should first establish which project-aware behaviors are required and determine whether existing native capabilities and admitted plugins already satisfy them.

## Alternatives Considered

### 1. Use native capabilities and existing tools

Prefer Neovim's built-in functionality and the existing navigation configuration where they satisfy the requirement.

**Advantages:**

- Fewer dependencies.
- Less plugin-specific configuration.
- Lower maintenance overhead.
- Consistency with the native-first architecture.

**Trade-offs:**

- Some project-discovery or switching workflows may require explicit configuration.
- Native functionality may not provide every convenience offered by a dedicated project plugin.

### 2. Admit a dedicated project-management plugin

Evaluate a plugin such as `project.nvim` for project discovery, root detection, and project-aware workflows.

**Advantages:**

- Potentially provides integrated project detection and switching.
- May simplify workflows that would otherwise require custom configuration.
- Could provide useful integration with sessions or navigation.

**Trade-offs:**

- Adds another dependency and configuration surface.
- May overlap with existing navigation, root-detection, or session behavior.
- Requires compatibility and maintenance evaluation.
- May introduce behavior that is unnecessary for the project's intended scope.

This alternative remains a candidate, not an accepted implementation.

## Consequences

### Positive

- Project-root behavior can be evaluated against concrete requirements before selecting a dependency.
- The configuration avoids installing a plugin solely because it is common in other Neovim distributions.
- Stage 12 remains responsible for the relevant architectural decision.
- Existing navigation tools remain independent of any future project-management plugin.

### Negative

- A dedicated project-switching workflow may remain unavailable until the evaluation is complete.
- Stage 12 must define and validate the required project-root behavior before deciding whether a plugin is warranted.

## Evaluation Criteria

During Stage 12, evaluate the following questions:

1. What behavior is required for identifying a project root?
2. Which root markers should be recognized, and should the behavior vary by language or repository?
3. Is project switching a required workflow or merely a convenience?
4. Can existing navigation tools operate adequately with the required root behavior?
5. Is session management required, and does it need project-plugin integration?
6. Would a dedicated plugin reduce complexity compared with a small native implementation?
7. Does the candidate support the project's minimum Neovim version?
8. Can the behavior be tested reliably and documented clearly?

The evaluation should compare actual requirements and behavior rather than relying on feature lists alone.

## Validation

Before admitting a project-management plugin:

- Define the required project-root and switching behavior.
- Verify how the existing configuration handles those workflows.
- Test representative repository layouts and root markers.
- Check for conflicts with Snacks, fzf-lua, and session behavior.
- Review compatibility, dependencies, maintenance, and configuration complexity.
- Document the resulting decision and update the plugin inventory.

If a plugin is selected, validate its behavior before marking the relevant roadmap stage complete.

## Follow-up

Revisit this decision during Stage 12 — **Git, Root, and Sessions**.

Until that evaluation is complete, treat `project.nvim` and other dedicated project-management plugins as deferred candidates. Do not install them merely because they appear in the roadmap or plugin inventory.

If a concrete requirement emerges earlier, document the requirement and its impact before changing this decision.
