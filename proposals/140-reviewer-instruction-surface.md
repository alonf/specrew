---
proposal: 140
title: Reviewer Instruction Surface (Project-Local Review Playbook + Learning Candidate Pipeline)
status: candidate
phase: phase-2
estimated-sp: 5-8
priority-tier: 1
discussion: surfaced 2026-05-28 by F-049 iter-3 review-signoff cross-reviewer pass; independent reviewer with explicit playbook context caught 4 substantive gaps that single-reviewer Pillar 5 form check missed; standalone fast-shippable slice that parallel-tracks broader amendments to Proposals 099 / 017 / 102
---

# Reviewer Instruction Surface (Project-Local Review Playbook + Learning Candidate Pipeline)

## Why

F-049 iter-3 review-signoff (2026-05-28) provided concrete empirical proof: an independent reviewer agent with access to an explicit playbook context (the contents of `docs/methodology/review-instructions.md` shipped 2026-05-28 at commit `01df228a`) correctly rejected an iteration that the first-pass reviewer had approved on Pillar 5 form check (tests pass + files committed). The independent reviewer caught **4 substantive gaps**:

1. **FR-024 schema mismatch** — implementation wrote `schema_version`, `updated_at`, `expertise_dials` while spec required `schema`, `last_updated_at`, nested `expertise.*` + missing required fields `specrew_version_at_creation`, `user_name`, `preferences.preferred_intake_depth`.
2. **FR-023 auto path executable-broken** — `Resolve-PerLensMode` parameter declared `[ValidateRange(1, 10)] [int]$ExpertiseDial`; engine passes `"auto"` string from profile-reading codepath; direct call fails with `Cannot convert value "auto" to type "System.Int32"`. Tests pass because they invoke engine with hardcoded integer dials via `-ExpertiseDial` override, never exercising auto path through profile-reading.
3. **SC-005 no-regression clause unevidenced** — quality-evidence.md covered question-reduction + decision-count-reduction; the third clause (no regression in spec quality via clarify-question count OR per-lens Mode-A rate ≥70%) had no measurement row.
4. **Lifecycle artifact inconsistency** — iter-3 plan.md said `Status: planning`, `Completed:` blank, task table rows `planned`; tasks-progress.yml said all 34 tasks `completed`.

The differentiator was **review-context quality, not model quality**. Both reviewers were AI; both ran on the same committed tree. The first-pass reviewer used Pillar 5 form check ("files committed + tests green = approve"); the independent reviewer used the explicit techniques from the methodology catalog (schema diff, type-contract trace, escape-hatch end-to-end check, SC-clause-by-clause evidence audit). Same model class, dramatically different review quality.

### The structural gap

Specrew's Reviewer agent today is structurally under-informed. The current reviewer charter (`extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, 65 lines) covers high-level disciplines (cite evidence, verify boundary state) but does NOT carry the operational reviewer playbook:

- The 8-Shape Form-Without-Runtime-Compliance catalog (lifecycle-discipline.md Shape Catalog)
- Type-contract trace technique
- Schema-diff technique (implementation vs spec field names)
- Escape-hatch end-to-end verification
- Multi-altitude verification (Shape 8)
- Agent-diagnosis empirical verification
- Cross-reviewer independence + playbook loading (Proposal 102 scope)
- Verdict-shape boundary-naming discipline

These disciplines were captured in `docs/methodology/{review-instructions,lifecycle-discipline,proposal-discipline}.md` shipped 2026-05-28 — but as **human-facing documentation**. The Reviewer agent has no installed-file surface that loads it. This is the SAME pattern Proposal 099 names: methodology knowledge present in maintainer prompts (or docs) that doesn't reach installed files that the Crew actually consumes.

### Why standalone, not just amendments

The architectural answer is amendments to Proposals 099 (Cluster 8 + Slice 4), 017 (broaden learning-loop inputs), and 102 (require loading playbook). Those amendments are landing alongside this proposal.

This proposal exists as a **standalone fast-shippable slice** because:

- Empirical evidence is concrete and recent (F-049 iter-3, 2026-05-28)
- The cost is small (~5-8 SP) and self-contained
- Broader 099/017/102 amendments are valuable but slot into longer-running feature work
- Shipping the playbook surface in days, not weeks, captures immediate review-quality lift across all in-flight features

The standalone proposal NAMES the closure work; the amendments codify the longer-term architecture.

## What — 5 Pillars

### Pillar 1: Canonical installed default

Ship `extensions/specrew-speckit/squad-templates/review/reviewer-instructions.md` as the Specrew-installed default reviewer playbook. Content sourced from `docs/methodology/review-instructions.md` (single source of truth) + targeted excerpts from `docs/methodology/lifecycle-discipline.md` (Shape Catalog, spec coverage verification, committed-tree durability) + `docs/methodology/proposal-discipline.md` (for reviewers of proposal-touching commits).

Format: agent-facing playbook (more operational, less narrative than the docs/methodology/ human-facing version). Same content, different presentation density. Sections:

- Reviewer Bootstrap (cold-start orientation)
- Source of Truth Order
- 8-Step Review Method
- 8-Shape Form-Without-Runtime-Compliance Catalog (with detection methods per shape)
- Spec Coverage Verification techniques (schema diff, type-contract trace, escape-hatch end-to-end, SC-clause audit, production-path-vs-test-path)
- Multi-Altitude Verification
- Verifying Agent Diagnoses (against hallucination chains)
- Verdict Format with boundary-naming discipline
- Severity Guidance
- Cross-Reviewer Recommendation triggers
- **State-Truth Integrity Audit at iteration-closeout + feature-closeout** (added 2026-05-29 after second empirical instance in F-049): boundary-specific mandatory checklist — at iteration-closeout / feature-closeout gates, reviewer MUST audit cross-artifact lifecycle-state consistency BEFORE substance review. Required checks: (1) `state.md` prose claims about current/next boundary match `state.md` "Current Phase" field; (2) `.squad/identity/now.md` `focus_area` + body prose match current lifecycle position; (3) `.specrew/start-context.json` `boundary_enforcement.last_authorized_boundary` matches `verdict_history[-1].to_boundary`; (4) no false-already-crossed claims in any state file. Catches the "state-artifact-truth inconsistency" failure mode empirically documented in F-049 iter-3 + iter-5 iteration-closeout cycles (memory `[[cross-reviewer-3rd-empirical-instance-2026-05-28]]` Instances 2 + 5). This audit is HUMAN-discipline backstop for Proposal 142 (State-Truth Integrity Validator) which provides mechanical Layer 1 enforcement.
- **Per-Boundary Checklist Matrix** (added 2026-05-29 after 6 empirical cross-review instances in single session): boundary classes have DISTINCT load-bearing review disciplines. A single uniform 8-step review method is insufficient — the playbook MUST ship a checklist matrix keyed by boundary class, with the load-bearing discipline for each class explicitly named. See "Per-Boundary Checklist Matrix" subsection below for the v1 matrix.

### Per-Boundary Checklist Matrix (added 2026-05-29)

Empirically validated 2026-05-28/29 across 6 cross-review instances in F-049 + F-050: different boundary classes have qualitatively different failure modes. Pillar 5 (commit-state form check) + generic substance audit don't substitute for the boundary-specific load-bearing discipline. The playbook ships per-boundary checklists keyed to the actual failure-mode pattern observed at each class:

| Boundary class | Load-bearing discipline | Failure-mode pattern caught | Empirical evidence |
|---|---|---|---|
| **plan-boundary** | Scope-vs-proposal alignment audit | Plan authored against stale proposal version; scope drift between proposal evolution and feature-iteration package | Instance 3 (F-049 iter-5 plan refreshed against 4-round Proposal 141 evolution) |
| **before-implement** | Hardening-gate completeness + deferred-with-approval explicit ack | Hardening concerns not surfaced for human ack OR silently bypassed | F-050 iter-1 (mirror-parity deferred-with-approval surfaced explicitly per pattern) |
| **review-signoff** | **Spec-vs-implementation diff** (load-bearing) | Implementation drifted from spec contract; tests pass against drifted implementation; self-review accepts drift instead of flagging (Shape 7 substance variant) | Instance 6 (F-050 iter-1: spec says `cursor-agent --print --workspace`, code does interactive `cursor-agent <prompt> --workspace`; self-review blessed; Codex caught) |
| **retro** | Estimation honesty + improvement-action capture for carry-items | Estimation overrun mischaracterized; carry-items from prior verdict missed | F-049 iter-5 retro (honest 6.6→6.9 SP attribution to A-001 tooling friction; 4 actions captured) |
| **iteration-closeout** | **State-truth integrity audit** (load-bearing) | Lifecycle-state inconsistency across state.md / now.md / start-context.json; false-already-crossed claims; verdict_history vs last_authorized_boundary mismatch | Instances 2 + 5 (F-049 iter-3 + iter-5 iteration-closeouts; same failure mode twice in single feature) |
| **feature-closeout** | All-iterations-closed verification + carry-forward checklist completeness | Iteration not actually closed but feature-closeout requested; carry-items lost between iteration retros and feature retro | (anticipated; no empirical instance yet) |

**Discipline composition principle**: each boundary's load-bearing discipline is ADDITIVE on top of Pillar 5 (commit-state form check) + 8-step review method base, not a substitute. Reviewer at iteration-closeout still verifies Pillar 5 + 8-step base + ADDS state-truth audit. Reviewer at review-signoff still verifies Pillar 5 + 8-step base + ADDS spec-vs-implementation diff. The matrix names what's DISTINCTIVE about each boundary, not what's universal.

**Methodology insight (single-session empirical observation 2026-05-29)**: the boundary class itself determines the dominant failure mode. State-truth issues are dominant at state-sync-heavy boundaries (iteration-closeout); spec-drift issues are dominant at shipping-shipped-behavior boundaries (review-signoff); scope-drift issues are dominant at planning-decision boundaries (plan). A reviewer applying the wrong discipline at the wrong boundary will miss the load-bearing class of issues even with diligent execution of the wrong checklist. **The boundary-checklist mismatch is itself a methodology gap that the matrix closes.**

The installed default is the floor; project overlays add to it (Pillar 3).

### Pillar 2: Project-local active copy

Deploy `.specrew/review/reviewer-instructions.md` to downstream projects:

- `specrew init` writes the file from the installed default at first-run
- `specrew update` propagates updates while preserving downstream edits per the existing update-discipline pattern
- Listed in `Specrew.psd1 FileList` so it ships with the module install on Mac/Linux
- Project-local copy is the file the Reviewer agent actually loads at review-signoff (Pillar 4)

The project-local copy can drift from the installed default if a downstream project wants project-specific patterns added. Drift is intentional and managed via Pillar 3 overlay; updates flow through `specrew update`.

### Pillar 3: Optional downstream/user overlay

Support `.specrew/review/reviewer-instructions.local.md` as an optional overlay:

- Project-specific reviewer patterns (e.g., "this project's domain catalog adds Shape 9 for our regulated-industry patterns")
- Additive to the base playbook (does NOT overwrite)
- Reviewer loads BOTH base (`.specrew/review/reviewer-instructions.md`) AND overlay if present
- Composes with Proposal 052 profile system (`.local` suffix is the standard overlay convention)
- Downstream-maintained; not propagated by `specrew update`

Two-tier load order: base methodology (from Specrew via Pillar 2) + project-specific overlay (Pillar 3 user-maintained). Drift between projects is expected and acceptable; the base remains consistent.

### Pillar 4: Reviewer charter + /specrew-review skill integration

Update `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` with the directive:

> **Before any review-signoff, read `.specrew/review/reviewer-instructions.md`. If absent, use the installed default at `extensions/specrew-speckit/squad-templates/review/reviewer-instructions.md`. If `.specrew/review/reviewer-instructions.local.md` exists, load that ALSO (additive overlay). State in `review.md` output which instruction-file version(s) were used. Apply the verification techniques + 8-Shape catalog + spec coverage verification to the review work product.**

Update `/specrew-review` skill (when present per F-021 / Proposal 064 slash-command machinery) to surface the file load + version-citation requirement at session start.

Validator rule (composes with Proposal 030 / 132 family): `review.md` MUST cite the instruction-file version explicitly; missing citation flagged as form-not-meaning per Proposal 073 pattern.

### Pillar 5: Learning candidate pipeline (review.md → retro.md → durable methodology)

The user observation that motivated this proposal: **reviewers discover lessons BEFORE retro, in more precise form**. Currently retro.md is the only formal channel for methodology lessons; this misses the precise-capture window that review-time provides.

New flow (composes with Proposal 017 amendment):

1. **review.md "## Reviewer Instruction Candidates" subsection** — Reviewer captures methodology lessons DURING review-signoff (not waiting for retro):
   - Form-without-runtime-compliance patterns observed
   - Verification techniques that caught (or would have caught) a gap
   - Spec coverage holes
   - Cross-altitude verification gaps
2. **retro.md "## Triage Reviewer Instruction Candidates" subsection** — Retro processes the review.md inputs:
   - **PROMOTE → durable methodology** (`.specrew/review/reviewer-instructions.md` via this proposal's channel; promotion eventually flows upstream to Specrew core via Pillar 2 amendments)
   - **PROMOTE → defect catalog** (`.specrew/quality/known-traps.md`)
   - **PROMOTE → validator proposal** (mechanical enforcement; new proposal candidate)
   - **DEFER → recurring observation; revisit next iteration**
   - **DROP → not actionable**

This creates a clean distinction (per the other-reviewer's analysis 2026-05-28):

- `known-traps.md` = compact defect catalog (what bugs look like)
- `reviewer-instructions.md` = how to review (operational discipline)
- `retro.md` = how the team learned (the journey)
- validators = mechanical enforcement (what's automatable)

Each artifact has a distinct purpose and lifecycle.

### Optional Pillar 6 (deferred V2 scope): retro → upstream-Specrew promotion automation

When a project's retro triages a candidate to PROMOTE → durable methodology, the candidate is currently project-local (lands in `.specrew/review/reviewer-instructions.local.md`). For Specrew-applicable patterns (vs project-specific), the promotion path should flow UPSTREAM to Specrew core's installed default.

Mechanism: triaged candidates flagged "promote-upstream" land in a queue (`docs/methodology/promote-candidates.md` or similar); become Proposal candidates per the proposal-discipline pattern; ship via standard Specrew lifecycle to update the installed default.

This is V2 scope — manual triage is sufficient for v1. Captured here so the architectural intent is visible.

## How

V1 ships across 2 iterations; total ~5-8 SP. Splittable.

| Iteration | Scope | SP |
|---|---|---|
| **Iter 1** | Pillars 1+2+3+4: canonical content + project deployment + overlay support + reviewer charter integration | 3-5 |
| **Iter 2** | Pillar 5: review.md + retro.md template updates; codify triage flow | 2-3 |

Iter 1 is the MVP — Reviewer loads the playbook and applies the techniques. Iter 2 closes the learning loop.

Could compress to single iteration if appetite supports; recommended split because templates are a distinct surface from script deployment.

## Acceptance criteria

- **AC1**: `extensions/specrew-speckit/squad-templates/review/reviewer-instructions.md` exists with substantive content covering 8-Shape catalog + 5 verification techniques + verdict-shape discipline + agent-diagnosis verification + cross-reviewer triggers
- **AC2**: `specrew init` deploys to `.specrew/review/reviewer-instructions.md` on a fresh project
- **AC3**: `specrew update` propagates updates to existing projects while preserving downstream edits (per existing update-discipline pattern)
- **AC4**: `Specrew.psd1 FileList` includes the new file paths
- **AC5**: `.specrew/review/reviewer-instructions.local.md` overlay loads in addition to base (Reviewer loads BOTH when both exist)
- **AC6**: Reviewer charter directive: "Before review-signoff, read .specrew/review/reviewer-instructions.md (+ .local.md overlay if present); state version(s) in review.md"
- **AC7**: `/specrew-review` skill loads the file at session start (where applicable per host)
- **AC8**: review.md template includes "## Reviewer Instruction Candidates" subsection
- **AC9**: retro.md template includes "## Triage Reviewer Instruction Candidates" subsection with the 5-action triage flow (PROMOTE-methodology / PROMOTE-defect / PROMOTE-validator / DEFER / DROP)
- **AC10**: Empirical proof: a feature-closeout review post-shipping cites the instruction-file version explicitly in review.md, demonstrating the loading discipline works in practice
- **AC11**: Mirror parity preserved (`extensions/specrew-speckit/squad-templates/review/*` ↔ no `.specify/extensions/` mirror needed since this is a Squad-template surface, not a Spec Kit extension surface; verify scope at implementation time)
- **AC12**: Validator rule (composes with Proposal 030 family) detects review.md without instruction-file-version citation as form-not-meaning

## Out of scope

- **Cross-model reviewer enforcement** — Proposal 102 territory; this proposal ships the playbook content + deployment; 102 mandates loading it
- **Full automation of validator promotion from triage** — Pillar 5 codifies the triage flow; automating the "candidate → validator-proposal" step is separate proposal scope
- **Reviewer agent model swap** — separate concern; Proposal 068 / 069 / 102 territory
- **Per-host slash-command deployment beyond `/specrew-review`** — Proposal 064 / 105 / 124 territory
- **Retro → upstream-Specrew automation** (Pillar 6) — V2 deferred
- **Single-source-of-truth derivation between `docs/methodology/` and `.specrew/review/`** — both can exist independently in v1; future consolidation if maintenance burden warrants

## Composition

| Proposal | Relationship |
|---|---|
| **Proposal 099 (Installed-File SDLC Instruction Audit)** | DIRECT PARENT. This proposal is the standalone fast-shippable expression of 099's Slice 4 + Cluster 8 (Reviewer Discipline). 099 amendment names the gap; 140 ships the closure. Two artifacts because empirical urgency favors fast standalone delivery; architectural correctness favors amendment integration. Both. |
| **Proposal 017 (Learning Loop Closure)** | DIRECT EXTENSION. Pillar 5 codifies the new review.md → retro.md learning-candidate channel that 017's amendment broadens. 140 ships the channel; 017 amendment broadens learning-loop inputs across review.md + retro.md + pr-review-resolution.md. |
| **Proposal 102 (Cross-Model Independent Reviewer)** | REQUIRED COMPLEMENT. 102 mandates that all commissioned reviewers (primary + independent) load this playbook. Without 140, 102's independence claim is empty (two ignorant reviewers ≠ structurally improved review). 102 cannot deliver value without 140; 140 ships standalone but 102 cannot ship without it. |
| **Proposal 133 (Specrew Primer — Persistent Host Instructions)** | DIRECT COMPOSER. CLAUDE.md / AGENTS.md / .github/copilot-instructions.md primer points at `.specrew/review/reviewer-instructions.md` for Reviewer context. 133 ships the pointer; 140 ships the content the pointer references. |
| **Proposal 052 (Specrew Profile System)** | OVERLAY PATTERN. Pillar 3 (.local.md overlay) uses the standard profile overlay convention; composes naturally. |
| **Proposal 047 (Project Governance Profile)** | PROJECT-SPECIFIC GOVERNANCE. Downstream projects can configure reviewer overlay content via profile; 047 sets per-project defaults; 140 ships the surface they configure. |
| **Proposals 074 + 081 + 120 + 132 + 117** | CONTENT SOURCES. Each of these contributes specific reviewer-charter clauses or shape-catalog entries to the playbook. 074 = code commentary verification; 081 = reviewer visual evidence; 120 = Pillar 5 absorbed Shape 5; 132 = mirror parity enforcement; 117 = iteration-level lifecycle enforcement. The playbook aggregates them. |
| **Proposal 073 (Review Evidence Integrity)** | FORM-VS-MEANING COMPOSER. AC12 validator rule (instruction-file-version citation required) follows the form-vs-meaning pattern 073 established. |
| **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning Verification)** | NATURAL ABSORPTION OF VALIDATOR RULES. The AC12 validator rule (citation required) could land as part of 030's bundle when 030 ships. |
| **Proposal 089 (PR Review Integration)** | COMPOSES VIA 017 AMENDMENT. 017 expands learning-loop inputs to include pr-review-resolution.md; reviewer instruction candidates discovered during PR review (rather than internal review-signoff) feed the same triage. |
| **Proposal 064 (Slash-Command Multi-Host Correctness)** | DEPLOYMENT MACHINERY. `/specrew-review` slash command integration uses 064's deployment pattern. |
| **Proposal 124 (Multi-Host Catalog Expansion)** | FORWARD-COMPATIBLE. New hosts added per 124 get reviewer charter + playbook loading via the same pattern. |
| **`docs/methodology/` (shipped 2026-05-28 commit `01df228a`)** | SINGLE SOURCE OF TRUTH for content. Pillar 1's installed default sources from `docs/methodology/review-instructions.md` + `lifecycle-discipline.md` + `proposal-discipline.md`. v1 accepts content duplication; future could derive one from the other if maintenance burden warrants. |

## Strategic upside

- **Specrew differentiation** — Squad's Reviewer agent is structurally informed only by base charter; Specrew shipping a comprehensive reviewer playbook is a genuine methodology innovation
- **Brady Gaster channel** (per `[[reference-brady-gaster-squad-inventor-2026-05-25]]`) — Squad's Reviewer could similarly benefit from a methodology catalog; this is a concrete upstream-contribution candidate same pattern as Proposals 137 + 138 + 139
- **External-tester window readiness** — when external testers adopt Specrew (~September 2026), the Reviewer's review quality directly affects user trust; this proposal materially improves that

## Risks

- **Content duplication between `docs/methodology/` and `.specrew/review/`** — two surfaces, same content. Mitigation: pick canonical source + derive (TBD); or accept independent maintenance with periodic reconciliation (v1 default).
- **Catalog grows unwieldy over time** — risk that 8 shapes becomes 20 shapes becomes unreadable. Mitigation: Pillar 5 triage discipline (DEFER / DROP options) + periodic curation chore; catalog format is structured (table) so growth stays scannable.
- **Reviewer charter directive is prose-only enforcement** — Reviewer agent might forget to load the file. Mitigation: AC12 validator rule for instruction-file-version citation in review.md; missing citation flagged as form-not-meaning per Proposal 073 pattern.
- **Project overlays diverge from base** — downstream projects' `.local.md` overlays accumulate project-specific content that drifts from Specrew base. Mitigation: clear precedence (base + overlay = additive); periodic re-baseline review at iteration retrospectives; promote-upstream channel for Specrew-applicable patterns (Pillar 6 V2).
- **Per-host slash-command deployment friction** — `/specrew-review` integration may differ across Claude / Codex / Copilot / Antigravity. Mitigation: Pillar 4 v1 ships charter directive only (no slash-command requirement); slash-command integration deferred to follow-up per Proposal 064 pattern.

## Acceptance signals (operational)

- **Signal 1**: review.md outputs from feature-closeout reviews consistently cite the instruction-file version (AC10)
- **Signal 2**: Reviewer agent catches Shape 7-class issues (tests pass but don't cover spec) without external prompting; F-049 iter-3-style gaps no longer require independent reviewer cross-check
- **Signal 3**: Pillar 5 learning pipeline produces actionable candidates per iteration (≥1 candidate per substantive iteration on average)
- **Signal 4**: External adopters (post-September 2026) cite "rich Reviewer methodology" as a Specrew differentiator
- **Signal 5**: Brady Gaster channel upstream conversation lands the methodology-catalog pattern as candidate for Squad core

## Status history

- **2026-05-28**: candidate drafted after F-049 iter-3 cross-reviewer review-signoff empirically demonstrated the value. Other-reviewer analysis (independent agentic reviewer) crystallized the architectural shape: 3-tier file pattern (`extensions/.../squad-templates/review/` installed default + `.specrew/review/` project-local + `.specrew/review/*.local.md` overlay), Pillar 5 learning candidate pipeline, distinction between known-traps.md / reviewer-instructions.md / retro.md / validators as 4 artifacts with distinct purposes. Drafted as standalone fast-shippable slice (5-8 SP) parallel-tracked with amendments to Proposals 099 + 017 + 102 (architectural correctness).
- **2026-05-29**: amended. Pillar 1 section list extended with "State-Truth Integrity Audit at iteration-closeout + feature-closeout" — boundary-specific mandatory checklist captured as the human-discipline backstop for Proposal 142 (State-Truth Integrity Validator, 3-5 SP, drafted same day). Amendment empirically motivated by 2nd state-truth integrity gap at F-049 iter-5 iteration-closeout (Codex caught state.md prose stale + now.md focus_area stale + start-context.json `last_authorized_boundary` false-already-crossed claim), confirming the failure-mode pattern from F-049 iter-3 iteration-closeout (Instance 2 in memory `[[cross-reviewer-3rd-empirical-instance-2026-05-28]]`). Two empirical instances of the same failure mode in same feature establishes iteration-closeout as a specific boundary class with **state-artifact-truth inconsistency** as its dominant failure mode. Reviewer playbook now codifies the audit checklist; Proposal 142 ships the mechanical enforcement; defense-in-depth across both layers.
- **2026-05-29 (second amendment, same day)**: Pillar 1 section list extended with **Per-Boundary Checklist Matrix** and a new subsection codifying the matrix. Empirically motivated by 6 cross-review instances in single F-049 + F-050 session converging on a structural finding: different boundary classes have qualitatively different load-bearing failure modes, and a single uniform 8-step review method is insufficient. The matrix names load-bearing disciplines per class: plan = scope-vs-proposal alignment; before-implement = hardening-gate completeness; **review-signoff = spec-vs-implementation diff (load-bearing)**; retro = estimation honesty + carry-item capture; **iteration-closeout = state-truth integrity audit (load-bearing)**; feature-closeout = all-iterations-closed + carry-forward completeness. Direct empirical motivation: Instance 6 (F-050 iter-1 review-signoff 2026-05-29) where Claude (single-reviewer) applied state-truth audit + Pillar 5 + charter compliance but missed the spec-vs-implementation drift; Codex (cross-reviewer) caught the actual review-signoff blocker. The boundary-checklist mismatch is itself a methodology gap; the matrix closes it. Composition with reviewer-charter discipline list in memory `[[cross-reviewer-3rd-empirical-instance-2026-05-28]]` (item 6 added same day captures the spec-vs-implementation diff discipline specifically).

## Cross-references

- **Empirical motivation**: F-049 iter-3 review-signoff 2026-05-28; independent reviewer cross-verification caught 4 substantive gaps
- file:///C:/Dev/Specrew/proposals/099-installed-file-sdlc-instruction-audit.md — DIRECT PARENT (Slice 4 + Cluster 8 amendment ships alongside 140)
- file:///C:/Dev/Specrew/proposals/017-learning-loop-closure.md — Pillar 5 codifies the new channel; amendment broadens inputs
- file:///C:/Dev/Specrew/proposals/102-cross-model-independent-reviewer.md — REQUIRES this playbook (amendment adds FR-016)
- file:///C:/Dev/Specrew/proposals/133-specrew-primer-persistent-host-instructions.md — primer composes with playbook content
- file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md — overlay pattern
- file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md — per-project governance composition
- file:///C:/Dev/Specrew/proposals/074-code-commentary-standards.md — content source
- file:///C:/Dev/Specrew/proposals/081-reviewer-visual-evidence.md — content source
- file:///C:/Dev/Specrew/proposals/120-handoff-block-validator-enforcement.md — Pillar 5 absorbed Shape 5
- file:///C:/Dev/Specrew/proposals/132-mirror-parity-validator-enforcement.md — content source
- file:///C:/Dev/Specrew/proposals/117-iteration-level-lifecycle-enforcement.md — content source
- file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md — AC12 validator rule absorption target
- file:///C:/Dev/Specrew/proposals/073-review-evidence-integrity.md — form-vs-meaning pattern composer
- file:///C:/Dev/Specrew/proposals/089-pr-review-integration-address-pr-review-gate.md — pr-review-resolution.md inputs via 017 amendment
- file:///C:/Dev/Specrew/proposals/064-slash-command-multi-host-correctness.md — `/specrew-review` deployment machinery
- file:///C:/Dev/Specrew/proposals/124-multi-host-catalog-expansion-tier-1.md — forward-compatible host coverage
- file:///C:/Dev/Specrew/docs/methodology/README.md — human-facing methodology (shipped 2026-05-28 `01df228a`)
- file:///C:/Dev/Specrew/docs/methodology/review-instructions.md — single source of truth for Pillar 1 content
- file:///C:/Dev/Specrew/docs/methodology/lifecycle-discipline.md — single source of truth for Shape Catalog excerpt
- file:///C:/Dev/Specrew/docs/methodology/proposal-discipline.md — single source of truth for proposal-reviewer content excerpt
- Memory: [[shape5-reviewer-approves-working-tree-only-state-2026-05-27]]
- Memory: [[shape7-tests-pass-but-dont-cover-spec-2026-05-28]]
- Memory: [[reference-brady-gaster-squad-inventor-2026-05-25]]
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
