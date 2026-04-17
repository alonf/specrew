# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I turn Specrew's requirements into iteration plans, task maps, and explicit dependencies while preserving traceability back to the source spec.

## Recent Updates

📌 Team confirmed by Alon on 2026-04-17

## Learnings

- Planning is the first ceremony in the Specrew lifecycle.
- Plans must map tasks back to requirements, with owners and effort estimates.
- v1 is Markdown-first and centered on extension assets rather than runtime code.
- Alon provides final architectural direction when requirements need interpretation.

### 2026-04-17: Plan Revision (Iteration 0)

- **Overcommit math**: Effort totals must be verified bi-directionally (sum of tasks = total). When overcommit occurs, defer lowest-priority work (not base requirements). Foundation iterations may exceed capacity for precondition-critical de-risking, but must be justified and tracked.
- **Acceptance criteria consistency**: AC gates must align with deferred work. If spikes are deferred, call them out explicitly in the AC. No ambiguity about what "complete" means.
- **Self-approval antipattern**: Roles should not pre-approve work outside their ownership. Spec Steward validates spec authority; Chief Architect gates approval. Sequence matters.
- **Traceability with enabling tasks**: Direct tasks (those that deliver a FR) differ from supporting tasks (those that enable a direct task). Both must be traceable, but the distinction clarifies dependencies. Use "Enabling Support" column to document which support tasks unblock which FRs.
- **Constitution checks are plan gates**: Specrew's own governance model (spec authority, traceability, ownership, capacity, drift, verification) must be applied to Specrew's own plans. This is not post-hoc validation — it's part of plan design.
- **Avoid calendrical assumptions**: AI crew estimates use story points, not wall-clock hours/days. Parallelization is noted; actual elapsed time depends on crew latency and verification feedback. Do not promise "3 days" for effort-estimated work.
- **Iteration naming is a convention, not a code change**: Clarify it in metadata rather than inventing new directory structures. Zero-indexing is the pattern; document it once in the design spec, then reference in plans.
- **Deferred work is not removed scope**: When spikes are moved to Iter 1 async, track them as deferred (not cancelled). They're still project work — just sequenced differently.

### 2026-04-17: Iteration 0 Plan Revision Complete

- All seven review findings resolved and integrated.
- Plan returned to "pending approval" state; Alon (Chief Architect) gate next.
- Decision merged to decisions.md; inbox file deleted.
- Orchestration log and session log written.
