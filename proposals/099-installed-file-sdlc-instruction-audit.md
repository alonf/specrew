---
proposal: 099
title: Installed-File SDLC Instruction Audit (Close the Dogfooding Deficit Between Maintainer Prompts and Installed Methodology)
status: candidate
phase: phase-2
estimated-sp: 5-8 (audit + closure chores)
discussion: ad-hoc 2026-05-22 session
---

# Installed-File SDLC Instruction Audit (Close the Dogfooding Deficit Between Maintainer Prompts and Installed Methodology)

## Why

Specrew's methodology guarantees depend on **two layers** working together:

1. **Mechanical layer** (in flight as F-039 / Proposal 065): tool-call refusal, schema-validated state, hard fail-closed semantics.
2. **Educational layer** (the installed instruction files): `coordinator/specrew-governance.md`, agent charters, sync command docs, directives. These tell the Crew what discipline to apply, what verdict shapes to expect, when to surface a question vs auto-resolve, how to write a boundary handoff.

The 2026-05-22 F-039 implementation session exposed a third layer that should not exist long-term: **the maintainer's paste-prompt scaffolding**. Across this session I (the maintainer-via-Claude) carried roughly 20 distinct SDLC disciplines into the Crew through paste prompts — verdict shape requirements, ambiguous-verdict rejection rules, compound-verdict syntax, reconciliation rules, done-condition lockdowns, drift-log update requirements, concurrent-activity disclosure conventions, file:/// URL formatting, and more.

Those disciplines didn't fail to land in the Crew's behavior — most of them landed correctly *because of the paste scaffolding*. That is the deficit. **We don't currently know whether Specrew's installed files alone would drive the same correct behavior**. The scaffolding masks the gap between what the installed files actually say and what the Crew actually needs to know.

A real downstream Specrew developer will not paste-prompt every verdict. They will type "approved for tasks-boundary entry" and expect Specrew's installed instruction surfaces to govern the rest. If those surfaces are silent on critical disciplines, every downstream session degrades into the same incident pattern we documented in memory (`project-wsl-trial-autopilot-clarify-gap-2026-05-18`, `project-gym-test-intake-questioning-gap-2026-05-19`, `project-f024-boundary-compaction-breach-2026-05-20`, and the meta-ironic 2026-05-22 F-039 chain-past-plan).

This proposal closes the gap by **auditing every SDLC discipline I've been hand-feeding and either confirming installed-file coverage or specifying the exact edit needed to add it**.

### What this is NOT

- This is NOT a re-litigation of F-039 / Proposal 065. F-039 mechanizes the *enforcement floor*; this proposal documents the *educational ceiling*. Both layers are required.
- This is NOT a rewrite of the installed files. It's a targeted closure of identified gaps with file:line citations.
- This is NOT scope expansion. The audit findings drive small-fix slices, not feature work.

## Audit Method

I walked these installed instruction surfaces:

- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md (166 lines)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md (62 lines)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/agents/implementer/charter.md (61 lines)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md (65 lines)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md (60 lines)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/agents/planner/charter.md (41 lines)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/directives/drift-reporting.md (58 lines)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/directives/spec-authority.md (55 lines)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/directives/traceability.md (60 lines)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-*.md (15-21 lines each)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/prompts/coordinator-decision-guidance.md
- file:///C:/Dev/Specrew/extensions/specrew-speckit/governance/validation-lane.md (36 lines)

For each SDLC discipline I'd been carrying through paste prompts, I categorized as one of:

- **PRESENT** — installed files have the instruction in a form that a Crew with no maintainer scaffolding would discover and apply
- **PARTIALLY PRESENT** — installed files address part of the discipline but leave material gaps (often: the rule is stated but the operationalization is implicit)
- **MISSING** — no installed file carries the discipline; the Crew currently learns it only via paste-prompt scaffolding
- **CORRECTLY MISSING (will mechanize)** — discipline is the F-039 mechanical layer's responsibility; documentation in installed files is supplementary not primary

## Gap Matrix

### Cluster 1 — Verdict discipline (5 items)

| Discipline | Status | Evidence |
|---|---|---|
| **Single-boundary verdict** ("one human authorization advances at most one boundary") | PRESENT | `coordinator/specrew-governance.md:97` — Rule 14A states this verbatim |
| **`continue` semantics** ("means advance to the next single boundary stop, then halt and ask again") | PRESENT | `coordinator/specrew-governance.md:97` — same Rule 14A |
| **Exact verdict shape** (e.g., `approved for X-boundary entry`) | PARTIALLY PRESENT | `coordinator/specrew-governance.md:91` says "ask the human developer to explicitly start implementation" — but no installed file enumerates the recognized verdict shapes. Charters mention "make verdicts explicit" (reviewer:21) without saying which shapes are recognized. **Closure**: add a "Recognized Verdict Shapes" section to coordinator-governance.md listing the canonical forms (`approved for <boundary>-boundary entry`, `approved for <boundary>`, `rejected for <boundary>`, `parked`). Cite Proposal 065 Pillar 2 once F-039 ships. |
| **Ambiguous-verdict rejection** ("looks good", "yep", "continue", "fine", "okay" parse as unauthorized) | MISSING | No installed file states this. Even Rule 14A's "continue means advance one boundary" still treats "continue" as authorization — which contradicts the exact-shape principle. **Closure**: add a "Verdict Disambiguation" subsection enumerating the rejected forms. Resolves the internal contradiction with Rule 14A's `continue` semantics by separating "ambiguous prose advances one boundary" (acceptable historical default) from "post-F-039 mechanical rejection of ambiguity" (the new floor). |
| **Compound verdict syntax** (`approved for X AND Y` for legitimate two-boundary progression) | MISSING | No installed file mentions the AND-form. **Closure**: document under the "Recognized Verdict Shapes" section above. Cite when it's appropriate (substantive single-review covering two boundaries; mechanical-scope plan-completion bundled with one-row clarify fix). |

### Cluster 2 — Boundary-stop discipline (3 items)

| Discipline | Status | Evidence |
|---|---|---|
| **Stop-at-boundary discipline + 9-boundary list** | PARTIALLY PRESENT | `coordinator/specrew-governance.md:96` lists 7 boundaries (planning, hardening-gate-and-implementation-auth, implementation, review-boundary, review-verdict-signoff, retro-boundary, iteration-closeout). Proposal 065's canonical 9 boundaries (specify, clarify, plan, tasks, before-implement, review-signoff, retro, iteration-closeout, feature-closeout) is the modern set. **Closure**: align Rule 14A boundary list to the 9-boundary set after F-039 ships. |
| **No-spillover after verdict** ("DO NOT invoke next-boundary skill until next verdict") | PARTIALLY PRESENT | Implicit via Rule 14A "halt and ask again" but no per-skill instruction. Sync command files (`sync-*.md`) currently say nothing about waiting for the maintainer between boundaries. **Closure**: F-039 lands this mechanically. Until then, add a one-line boilerplate to each `sync-*.md` body: "After persisting boundary state, do NOT invoke the next boundary's skill until the maintainer provides an explicit single-boundary verdict per coordinator rule 14A." |
| **Don't auto-resolve ambiguity** (surface scope questions explicitly, don't infer) | PARTIALLY PRESENT | `coordinator/specrew-governance.md:60-63` addresses intake-stage scope ("ask explicit interactive question"); Rule 23 (critical review) says "stop closure, ask the human targeted clarification". But no rule generalizes the principle to clarify-boundary, plan-completion, or implementation boundaries. **Closure**: add a generic rule "Surface scope ambiguity at every boundary; do not silently infer" to coordinator-governance.md or to each charter's "When I'm unsure" section. |

### Cluster 3 — Audit-trail discipline (4 items)

| Discipline | Status | Evidence |
|---|---|---|
| **Drift-log entry per verdict** | PARTIALLY PRESENT (different purpose) | `directives/drift-reporting.md` defines drift detection between delivered output and source requirement. It does NOT define "every verdict creates a drift-log entry recording the verdict text". This session demonstrated that practice naturally; installed files don't ask for it. **Closure**: add a new directive `verdict-audit-trail.md` OR extend `drift-reporting.md` with a "Verdict ledger entries" section. |
| **.squad/decisions.md per boundary advancement** | PRESENT | `coordinator/specrew-governance.md:98` (Rule 14A) says "create two .squad/decisions.md entries that preserve the same verbatim authorization text". Implementer, Reviewer, Retro Facilitator charters all reference writing to `.squad/decisions.md`. |
| **Mirror parity** (extensions/ ↔ .specify/extensions/) | PARTIALLY PRESENT | `agents/implementer/charter.md` mentions in commit-discipline context; `agents/reviewer/charter.md` doesn't enforce; sync command files don't mention. **Closure**: add a one-line "Mirror parity is mandatory for any touched extensions/specrew-speckit/ file" to Implementer charter (currently implicit) and to Reviewer charter (currently absent). Sync command files should also note this when they touch shared code. |
| **Boundary-name canonical strings** (avoid `feature-closed`; use `feature-closeout`) | PRESENT | `coordinator/specrew-governance.md:36` (Rule 5) explicitly enumerates the trap and references the validator rule. Spec Steward / Implementer / Reviewer / Retro Facilitator charters each carry the closeout-sync section. |

### Cluster 4 — Reconciliation discipline (4 items)

| Discipline | Status | Evidence |
|---|---|---|
| **Reconciliation rule** (spec silence vs proposal = clarify regression, not advance) | MISSING | This is a procedural pattern I invented during F-039 to handle the "Proposal 065 missing → ship it → reconcile spec → discover gaps" cycle. No installed file states it. **Closure**: add a new directive `spec-vs-proposal-reconciliation.md` if proposal-driven design is in scope (per Proposal 096 — opt-in profile). Otherwise, keep this proposal-specific to Specrew itself and not push to downstream installs. |
| **Done-condition lockdown** (final clarify pass; no infinite micro-divergence loops) | MISSING | Invented this session as the "this is the LAST clarify pass" rule. **Closure**: same directive as above; document the "after the final reconciliation pass, residual gaps become scope questions, not silent return-to-clarify". |
| **Reconciliation report format** (line-by-line proposal-to-spec walk) | MISSING | The format I asked Squad to produce for F-039 is a useful pattern. **Closure**: include a template in the directive above, or scaffold via a new scaffolder script. |
| **Compound-verdict audit** (record two-boundary verdicts as such) | MISSING | The "Compound-Verdict Audit 2026-05-22" section Squad added to F-039's drift-log is currently a one-off. **Closure**: integrate into the verdict-audit-trail directive above. |

### Cluster 5 — Format discipline (3 items)

| Discipline | Status | Evidence |
|---|---|---|
| **file:/// URL format** for all file references | PRESENT | `coordinator/specrew-governance.md:100-101` (Rule 14A) — "Use file:/// artifact references in authored narration and handoffs". The rule also requires a stale-reference scan. |
| **Three-section handoff** (What I just did / Why I stopped / What I need from you) | PRESENT | `coordinator/specrew-governance.md:99` (Rule 14A) — "Boundary handoffs stay in the three-section format". Also reinforced by `prompts/coordinator-decision-guidance.md` which prescribes the same format. |
| **Substantive `What I just did`** (not status-only) | PRESENT | `coordinator/specrew-governance.md:99` (Rule 14A) — "make `What I just did` substantive". |

### Cluster 6 — Terminology and concurrent activity (3 items)

| Discipline | Status | Evidence |
|---|---|---|
| **"the Crew" vs "Squad" terminology** | MISSING | Memory (`feedback-no-squad-in-new-proposals-2026-05-21`) says new prose should use "the Crew" for the team-role and "Squad" for the npm product. No installed file states this. **Closure**: add a brief "Terminology" preamble to `coordinator/specrew-governance.md` AND/OR to `squad-templates/README.md`. Currently downstream Crews learn this only by reading the maintainer's prose by accident. |
| **Concurrent activity disclosure** ("I'm doing X concurrently while you're parked at Y") | MISSING | Invented this session. Probably belongs in the maintainer's prose, not in installed files — the maintainer surfaces concurrent activity to the Crew, not vice versa. **Closure**: SKIP — this is correctly absent from installed files. |
| **Recognized verdict catalog surfaced in handoffs** ("Recognized verdicts: ..." enumeration in directive output) | MISSING | The four-line directive shape Squad emits at boundary stops (or could emit, once F-039 lands) is currently maintainer-supplied. **Closure**: when F-039 ships `Write-SpecrewBoundaryAuthorizationDirective`, the directive output IS the canonical surface. Documented by F-039's contract; this proposal just notes the composition. |

### Cluster 7 — Mechanical layer (1 item)

| Discipline | Status | Evidence |
|---|---|---|
| **Per-tool-call mechanical enforcement** | CORRECTLY MISSING (will mechanize) | This is exactly what F-039 ships. Installed files SHOULD remain silent on the mechanism (it should be invisible from the user-facing instruction layer) and load-bearing on the *contract* (recognized verdict shapes, where the audit trail lives, etc.). |

## Summary

Of ~20 SDLC disciplines audited:

- **PRESENT**: 7 (single-boundary verdict, continue semantics, .squad/decisions.md per boundary, boundary-name canonical strings, file:/// URL format, three-section handoff format, substantive WJD)
- **PARTIALLY PRESENT**: 6 (exact verdict shape, 9-boundary list alignment, no-spillover, auto-resolve generalization, drift-log per verdict, mirror parity)
- **MISSING**: 7 (ambiguous-verdict rejection, compound verdict syntax, reconciliation rule, done-condition lockdown, reconciliation report format, compound-verdict audit, "the Crew" vs "Squad" terminology)
- **CORRECTLY MISSING (will mechanize)**: 1 (per-tool-call enforcement)

## Closure Plan

Group the closure work into three slices, each ~2-3 SP:

### Slice 1 — Recognized Verdict Shapes catalog (post-F-039 ship)

After F-039 lands (so verdict shapes are mechanically validated):

- Add a "Recognized Verdict Shapes" subsection to `coordinator/specrew-governance.md` enumerating the canonical forms with examples.
- Add the matching content to `agents/spec-steward/charter.md` (Spec Steward authors verdicts) and `agents/reviewer/charter.md` (Reviewer recognizes them).
- Update Rule 14A's `continue` semantics to clarify that "continue" is ambiguous and not the canonical advancement form post-F-039.
- Document the compound `AND` shape with a concrete example (the F-039 clarify→plan-completion verdict is the historical reference case).

### Slice 2 — Reconciliation directive (only if proposal-driven design profile activates)

This is conditional on Proposal 096 (Proposal-Driven Design Profile) activating:

- Add a new directive `squad-templates/directives/spec-vs-proposal-reconciliation.md` codifying:
  - The "silence = clarify regression" rule
  - The reconciliation-report format (line-by-line proposal-to-spec walk with three-category mapping)
  - The done-condition lockdown (after the final exhaustive pass, residual gaps surface as scope questions, not silent return-to-clarify)
  - The compound-verdict audit format

If Proposal 096 doesn't activate downstream, this directive doesn't ship downstream. It stays Specrew-internal documentation only.

### Slice 3 — Smaller refinements (one PR)

- Add the no-spillover boilerplate to each `sync-*.md` command body
- Add the "auto-resolve generalization" rule to coordinator-governance.md
- Add mirror parity reminder to Reviewer charter (currently only in Implementer)
- Add a verdict-audit-trail directive OR extend drift-reporting.md with the verdict-ledger section
- Add a Terminology preamble to `squad-templates/README.md` or `coordinator/specrew-governance.md`
- Align Rule 14A's boundary list to the 9-boundary canonical set after F-039 ships

Each refinement is 0.25-0.5 SP and easy to bundle.

## Composition with Other Proposals

| Proposal | Relationship |
|---|---|
| **Proposal 065 (Launch-Mode Boundary Enforcement)** | Strong composition. F-039 ships the mechanical floor; this proposal ships the educational ceiling. The two are complementary — neither suffices alone. Slice 1 of this proposal must ship AFTER F-039 to avoid stale documentation. |
| **Proposal 066 (Gate-Respecting Default, shipped)** | Compatible. 066 introduced `--autonomous` opt-in; this proposal's verdict-shape catalog assumes 066's gate-respecting baseline. |
| **Proposal 096 (Proposal-Driven Design Profile)** | Conditional composition. Slice 2 (reconciliation directive) only activates downstream if Proposal 096's opt-in profile is active. For Specrew itself, slice 2 always lands. |
| **Proposal 090 (Closeout Lifecycle Sync Commands)** | Composes with Cluster 3's mirror-parity refinement — Proposal 090 already established the closeout-sync slash-command pattern; this proposal extends it with one-line no-spillover boilerplate. |
| **Proposal 098 (Launch Posture Visibility — candidate)** | Adjacent. 098 surfaces enforcement state at launch; this proposal documents the verdict shapes that drive that state. Composable. |

## Acceptance Signals

- **AC1**: After Slice 1 ships, a Crew session run with NO maintainer paste-prompt scaffolding past the kickoff produces correct boundary handoffs (three-section format, file:/// URLs, exact verdict-shape requests). Verified by a controlled session (the maintainer types only verdict text, no procedural reminders).
- **AC2**: After Slice 2 ships, a proposal-to-spec reconciliation cycle (analogous to the F-039 cycle) completes without maintainer reminders about silence-vs-explicit or done-condition lockdown. Verified by a controlled cycle.
- **AC3**: After Slice 3 ships, downstream `specrew init` projects with no prior Specrew knowledge can run a feature end-to-end without their maintainer needing to invent SDLC discipline through prompts. Verified empirically when the next downstream project tries Specrew.
- **AC4**: This proposal itself is testable by counting paste-prompt SDLC scaffolding lines in maintainer-Crew conversations. Before Slice 1+2+3 ship: O(20+ lines per verdict). After Slice 1+2+3 ship: O(1-3 lines per verdict, only the verdict + feature-level commentary).
- **AC5**: Mirror parity preserved across all touched files.

## Out of Scope

- **Concurrent activity disclosure** is correctly absent from installed files (it's a maintainer→Crew prose convention, not a Crew→Crew rule). Don't add it.
- **Per-tool-call mechanical enforcement documentation** in installed files. F-039 owns the mechanism; installed files document the *contract* (verdict shapes, etc.) not the mechanism.
- **Rewriting installed files wholesale.** Closure happens via targeted small-fix slices.
- **Downstream-only adjustments.** This proposal documents the closure for the Specrew repo. Downstream installs receive the updated files via the normal `specrew update` flow.
- **Auto-detection of paste-prompt scaffolding in maintainer messages.** Too meta; the audit-by-empirical-comparison method (AC4) is sufficient.

## Cross-References

- **Empirical motivation**: 2026-05-22 ad-hoc session with Squad working F-039. ~20 SDLC disciplines hand-fed through paste prompts; user observation triggered this audit.
- **In-flight feature**: F-039 / Proposal 065 (Launch-Mode Boundary Enforcement) — the mechanical complement to this proposal's educational closure.
- **Composes-with**: Proposals 065, 066, 090, 096, 098.
- **Memory anchors**:
  - `feedback-no-squad-in-new-proposals-2026-05-21` (terminology rule)
  - `feedback-verdict-boundary-naming-2026-05-22` (verdict shape rule)
  - `feedback-paste-ready-with-start-stop-markers` (paste-prompt convention — maintainer-facing, doesn't belong in installed files)
  - `feedback-file-url-format-for-paths` (file:/// rule)
  - `project-f024-boundary-compaction-breach-2026-05-20` (one of four motivating incidents)
- **Installed-file audit raw notes**: see `## Audit Method` section above for the full surface list.
- **INDEX**: file:///C:/Dev/Specrew/proposals/INDEX.md
