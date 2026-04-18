# Specrew Squad Extension

## Overview

This is the **Squad extension** component of Specrew. It provides skills, ceremonies, and directives that govern crew composition, iteration delivery, roles, and structured ceremonies for spec-governed AI crew operations.

## Purpose

The Specrew Squad extension enables:

- **Spec-driven iteration planning**: Skills that plan tasks from specification requirements
- **Drift detection**: Skills that check implementation alignment with specifications
- **Governance ceremonies**: Planning, Review/Demo, and Retrospective ceremonies
- **Traceability enforcement**: Directives ensuring every task traces to a requirement
- **Capacity planning**: Skills for effort estimation and iteration capacity management

## Structure

```
skills/          # Skills for planning, drift detection, capacity management, traceability
ceremonies/      # Ceremonies for Planning, Review/Demo, Retrospective
directives/      # Directives for spec authority, traceability, drift reporting
README.md        # This file
```

## Extension Architecture

This extension follows Squad's documented extension structure (skills/, ceremonies/, directives/, README.md). It integrates with Squad >= 0.9.1 using Markdown-based extension surfaces only. No `squad.config.ts` is used in v1.

### Skills

Skills are invoked by ceremonies or directly by the Spec Steward and crew members:

- **drift-check.md**: Detect divergence between implementation and specification
- **capacity-planning.md**: Estimate effort and plan iteration capacity
- **traceability-check.md**: Verify task-to-requirement mapping
- **iteration-resume.md**: Resume interrupted iterations from last completed task

### Ceremonies

Ceremonies provide structured workflows for iteration lifecycle:

- **planning.md**: Plan iteration tasks from spec requirements with effort estimates
- **review-demo.md**: Review completed tasks against spec, produce pass/needs-work verdicts

### Directives

Directives define governance rules and enforcement:

- **spec-authority.md**: The specification is authoritative; drift requires reconciliation
- **traceability.md**: Every task must map to a requirement
- **drift-reporting.md**: Drift findings must be documented with evidence and resolution

## Integration Points

- **Spec Kit Extension**: Receives governance artifacts and templates from `specrew-speckit`
- **Squad Runtime**: Loaded as a Squad plugin, invoked via Squad ceremonies and skills
- **GitHub Copilot**: Skills and ceremonies are exposed to Copilot agents via Squad

## Development Status

**Phase**: Foundation (Iteration 0)  
**Status**: Skeleton scaffolded; skill/ceremony/directive stubs pending (Planner tasks T-009, T-010, T-011)

## Installation

Installation instructions will be available after Iteration 0 platform validation completes.

## License

TBD

## Extension Authoring

For extension authors building on top of Specrew:

- **Stable surfaces**: Skills, ceremonies, directives (Markdown-based)
- **Hook integration**: Skills can be invoked by custom ceremonies
- **Naming conventions**: Prefix custom skills/ceremonies with your extension name to avoid collisions
- **Collision detection**: Use `collision-detect.ps1` (Spec Kit extension) to check for naming conflicts

Detailed extension authoring guidelines will be published post-MVP.
