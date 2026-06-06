# Feature Specification: Managed-Skill "Stuck Preserving" Guard

**Feature Branch**: `161-managed-skill-preserving-guard`
**Created**: 2026-06-06
**Status**: Draft
**Input**: User description: "Confirm + fix the managed-skill stuck-preserving risk in
deploy-squad-runtime.ps1 (Proposal 161): Tier 0 deterministic repro to confirm or refute the
`.specrew-managed` marker-absent misclassification (managed skill silently frozen as
user-edited); Tier 1 marker-authoritative fix only if confirmed; genuinely user-authored
skills must remain preserved."

## Context: what Feature 160 already shipped (baseline for this feature)

Feature 160 partially addressed Proposal 161 at the **classifier level**:

- `Test-IsManagedLegacySkillDirectory` in `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`
  gained a provenance-by-content recovery: a marker-less directory whose `SKILL.md` exactly
  (ordinal) matches the **current** canonical content is classified managed.
- `tests/integration/managed-runtime-sidecar.tests.ps1` covers Cases A–D (current-canonical
  without marker, canonical with marker, pre-front-matter legacy signature, genuinely
  user-edited) plus source/`.specify`-mirror parity — all via AST-extracted functions, with
  **zero side effects and no actual deploy execution**.

What Feature 160 did **not** do — and what this feature owns:

1. **Deploy-level deterministic repro** (Proposal 161 Tier 0 as written): fresh project state →
   introduce divergence → re-run the real deploy path → observe refresh vs. preserve outcomes
   end-to-end, not just the extracted classifier function.
2. **The residual stuck-preserving hypothesis**: a marker-less legacy directory holding a
   **stale older canonical version** (front-matter content from a previous Specrew release that
   no longer exactly matches current canonical) fails the exact-match recovery, hits the
   front-matter heuristic, and is classified user-edited → preserved forever. Whether any real
   upgrade path produces such a directory is unconfirmed.
3. **Confirm/refute verdict + conditional narrow fix** for any residual reachable
   stuck-preserving path, with the preservation guarantee for genuinely user-authored skills
   proven by tests.

Known mechanics (verified in source, 2026-06-06):

- The classifier is invoked **only** for legacy `.copilot/skills/specrew-*` cleanup
  (remove-if-managed / preserve-if-user). Active skill roots (`.claude/skills`,
  `.cursor/rules`, `.github/skills`, `.agents/skills`) are deployed unconditionally:
  `Set-ManagedFile` overwrites `SKILL.md` on content difference and always (re)writes the
  `.specrew-managed` marker. The "frozen skill" surface is therefore the legacy root.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Confirm or refute the residual stuck-preserving risk (Priority: P1)

As a Specrew maintainer, I need a deterministic, deploy-level reproduction around
`deploy-squad-runtime.ps1` that either demonstrates a reachable path where a Specrew-managed
skill directory is misclassified as user-edited and silently frozen, or proves that after the
Feature 160 fix every reachable path refreshes/cleans managed skills correctly — so the
Proposal 161 hypothesis stops being an open risk and becomes recorded evidence.

**Why this priority**: This is the gate for everything else. Without a confirmed repro, any
fix is speculative — explicitly prohibited by the proposal and by intake.

**Independent Test**: Run the repro harness on a fresh temp project; it must produce the same
classification/refresh outcomes on every run and emit a recorded verdict per scenario.

**Acceptance Scenarios**:

1. **Given** a fresh project with deployed managed skills, **When** the deploy runs again with
   no divergence, **Then** managed surfaces are reported preserved/refreshed (no spurious
   user-edited classification) and markers exist in all active roots.
2. **Given** a legacy `.copilot/skills/specrew-*` directory holding the **current** canonical
   content without a marker, **When** the deploy runs, **Then** it is classified managed and
   removed (Feature 160 regression guard at deploy level).
3. **Given** a legacy `.copilot/skills/specrew-*` directory holding a **stale older canonical**
   front-matter `SKILL.md` without a marker, **When** the deploy runs, **Then** the observed
   outcome (preserved-as-user-edited vs. cleaned-as-managed) is captured and drives the
   confirm/refute verdict for the residual hypothesis.
4. **Given** the investigation completes, **Then** a documented verdict exists naming the exact
   code path: either CONFIRMED (with the reachable scenario) or REFUTED (with evidence that no
   reachable deploy path freezes a managed skill).

---

### User Story 2 - Managed skills refresh when provenance says managed (Priority: P2, conditional on US1 = CONFIRMED)

As a Specrew user on an upgraded installation, when Specrew owns a skill (provenance says
managed), `specrew update` must bring it current with canonical content or clean up its legacy
copy — it must never silently freeze at an old version — while anything I authored myself
stays untouched.

**Why this priority**: This is the Tier 1 fix; it only exists if US1 confirms a reachable bug.
If US1 refutes, this story closes as not-applicable with no code change.

**Independent Test**: With the fix in place, re-run the US1 repro: the previously-frozen
scenario now refreshes/cleans the managed skill, and the user-authored scenario still
preserves.

**Acceptance Scenarios**:

1. **Given** the confirmed stuck-preserving scenario from US1, **When** the deploy runs with
   the fix, **Then** the managed skill is refreshed/cleaned per canonical and the run reports
   the managed classification.
2. **Given** a genuinely user-authored skill directory (no marker, front-matter content that
   never matched any canonical), **When** the deploy runs with the fix, **Then** it is
   preserved exactly as before (no data loss, no reclassification).
3. **Given** the fix, **When** the existing `managed-runtime-sidecar.tests.ps1` fixture runs,
   **Then** all Feature 160 cases (A–D + mirror parity) still pass.

---

### User Story 3 - Evidence and tests survive the feature regardless of outcome (Priority: P3)

As a future maintainer, I can read why this risk was confirmed or refuted, and CI exercises
both the refresh-managed and preserve-user-edited paths so the behavior cannot silently
regress.

**Why this priority**: The proposal's value is closing the question durably; an unrecorded
verdict reopens the same investigation later.

**Independent Test**: The repro/regression tests run in the repo test harness; the verdict and
code-path citation are recorded in the feature's iteration artifacts (review/retro/evidence).

**Acceptance Scenarios**:

1. **Given** the feature closes, **Then** tests covering refresh-managed and
   preserve-user-edited paths exist and pass in the repo harness.
2. **Given** the feature closes REFUTED, **Then** no speculative behavior change shipped and
   the evidence states why each suspected path is unreachable.

---

### Edge Cases

- Legacy directory with `SKILL.md` whose content is an older canonical version that predates
  front matter (legacy-signature fallback must keep recognizing it as managed).
- Legacy directory with a marker present but user-edited `SKILL.md` content: marker wins →
  removed. The investigation must note whether this existing semantic risks user data and, if
  so, record it as a finding (fix only with human approval — it may be out of narrow scope).
- `SKILL.md` differing from canonical only in line endings or encoding/BOM (ordinal exact-match
  fails on CRLF/LF differences) — does any real deploy/checkout path produce this divergence?
- Skill directory without `SKILL.md`, or with empty/whitespace `SKILL.md`.
- Re-running the deploy twice in a row (idempotency: second run must report
  preserved/no-change for managed surfaces).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The feature MUST provide a deterministic, re-runnable, deploy-level repro
  harness around `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` that executes
  the real deploy logic against an isolated temp project (no mutation of the working repo) and
  records per-scenario classification/refresh outcomes.
- **FR-002**: The repro MUST cover at minimum: (a) marker-present managed directory →
  refreshed/cleaned; (b) marker-absent genuinely user-authored directory → preserved;
  (c) marker-less directory with current canonical content → managed (Feature 160 regression
  guard); (d) marker-less directory with stale older-canonical front-matter content → outcome
  captured as the residual-hypothesis probe.
- **FR-003**: The investigation MUST end in a recorded verdict — CONFIRMED with the exact
  reachable code path and triggering scenario, or REFUTED with evidence that every reachable
  deploy path refreshes/cleans managed skills — written into the feature's iteration evidence
  artifacts.
- **FR-004** *(conditional: only if FR-003 = CONFIRMED)*: Provenance MUST be authoritative for
  the managed/preserve decision: when Specrew owns a skill, the deploy MUST refresh/clean it
  from canonical; the content heuristic remains strictly a fallback for genuinely pre-marker
  legacy directories. The fix MUST stay narrow to the classification/marker behavior — no
  change to which skills are canonical, no new deploy surfaces.
- **FR-005**: Genuinely user-authored skill directories MUST remain preserved in every state
  (pre-fix, post-fix, refuted-no-fix). Any change that could delete or overwrite
  user-authored content is out of scope without explicit human approval.
- **FR-006**: Tests MUST cover both the refresh-managed and preserve-user-edited paths and run
  in the repo test harness; the existing `tests/integration/managed-runtime-sidecar.tests.ps1`
  cases MUST continue to pass unchanged.
- **FR-007**: The feature MUST NOT touch Feature 141 design-lens/workshop work, Proposal 160 /
  Feature 160 resolver-sidecar work (read-only context allowed), or Feature 159
  update/version-message work (read-only context allowed); and MUST NOT release, tag, merge,
  open a PR, or push to main.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: US1 → FR-001, FR-002, FR-003; US2 → FR-004, FR-005; US3 → FR-005, FR-006;
  scope guard → FR-007.
- **TG-002**: Owners — Implementer (repro harness, conditional fix, tests), Reviewer
  (verdict-evidence integrity, data-loss guard), Spec Steward (scope guard FR-007).
- **TG-003**: Delivery window — single iteration (001); Tier 0 first, Tier 1 in the same
  iteration only if confirmed early enough, otherwise close REFUTED or carry the fix
  explicitly.
- **TG-004**: Known overlap with Feature 160 is reconciled in the Context section above: this
  feature builds on the shipped classifier fix and owns only the deploy-level repro plus the
  residual stale-canonical hypothesis. Any further conflict found during planning goes to the
  drift log and stops at the next boundary.

### Key Entities

- **Managed skill directory**: a `specrew-*` skill folder Specrew deploys and owns; provenance
  signal is the `.specrew-managed` sidecar marker, recovery signal is exact-canonical content.
- **Legacy skill root**: `.copilot/skills` — cleanup-only; the only surface where the
  managed/preserve classifier runs.
- **Active skill roots**: `.claude/skills`, `.cursor/rules`, `.github/skills`,
  `.agents/skills` — deployed unconditionally with marker rewrite.
- **Verdict record**: the documented CONFIRMED/REFUTED outcome with code-path citation, stored
  in iteration evidence.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The repro harness produces identical scenario outcomes across two consecutive
  runs on a fresh temp project (determinism), with zero writes outside its temp sandbox.
- **SC-002**: A CONFIRMED or REFUTED verdict with exact code-path citation exists in the
  iteration evidence before review-signoff.
- **SC-003**: If CONFIRMED and fixed: the previously-frozen scenario refreshes/cleans under
  the fix while the user-authored scenario remains preserved — demonstrated by tests that
  fail pre-fix and pass post-fix.
- **SC-004**: All pre-existing `managed-runtime-sidecar.tests.ps1` assertions still pass after
  any change (zero regressions on Feature 160 coverage).
- **SC-005**: No commits in this feature touch Feature 141, Feature/Proposal 160, or Feature
  159 surfaces beyond read-only context; no release/tag/merge/PR/push-to-main occurs.

## Assumptions

- Feature 160's provenance-by-content classifier fix is on this branch's baseline (verified:
  present in `deploy-squad-runtime.ps1` and covered by the existing sidecar fixture).
- The legacy `.copilot/skills` root is cleanup-only; no current deploy writes new content
  there. Active roots are always refreshed, so the freeze surface is legacy-only unless the
  investigation discovers otherwise (such a discovery would itself be a CONFIRMED finding).
- Windows + PowerShell 7+ repo harness is sufficient; no OS-specific behavior is in scope
  (the classifier logic is platform-neutral string/file logic).
- "Stale older canonical" fixtures may be synthesized from git history of
  `extensions/specrew-speckit/squad-templates/skills/` when a real historical version is
  needed; synthetic near-canonical content is acceptable for reachability probes when history
  is impractical.

## Clarifications

### Session 2026-06-06 (self-answered from repo evidence; confirm at clarify→plan boundary)

- Q: Does Proposal 161's original Tier 0 hypothesis still need confirming from scratch?
  → A: No — it was already CONFIRMED and fixed at the **classifier level** during Feature 160:
  `tests/integration/managed-runtime-sidecar.tests.ps1` Case A ("canonical content + NO
  marker") explicitly failed pre-fix and passes post-fix, and the provenance-by-content
  recovery in `deploy-squad-runtime.ps1` carries a "Feature 160 (Proposal 161)" comment.
  F-161's open questions are therefore: (a) deploy-level end-to-end confirmation, and
  (b) the residual stale-older-canonical scenario the exact-match recovery cannot catch.
- Q: Which surface can actually freeze a managed skill? → A: Only the legacy
  `.copilot/skills/specrew-*` cleanup path — `Test-IsManagedLegacySkillDirectory` has exactly
  one call site (the legacy-root loop). Active skill roots are deployed unconditionally:
  `Set-ManagedFile` overwrites `SKILL.md` on any content difference and always (re)writes the
  `.specrew-managed` marker. If the investigation finds an additional freeze surface, that is
  itself a CONFIRMED finding.
- Q: What does "refresh" mean for a legacy directory? → A: Removal. Current deploys never
  write content into `.copilot/skills`; "stuck preserving" there means the stale directory is
  never cleaned up and remains visible to the Copilot host alongside the current skills in
  active roots.
- Q: What determinism bar must the repro meet? → A: Isolated temp sandbox (zero writes
  outside it), identical outcomes across consecutive runs, no dependence on wall-clock or
  environment state; synthesized stale-canonical fixtures are acceptable where extracting a
  real historical template version is impractical (recorded in evidence either way).

## Governance Alignment *(mandatory)*

- **Spec Steward**: accountable for spec integrity and the FR-007 scope guard.
- **Iteration Facilitator**: Planner role per the baseline roster; single-iteration cadence.
- **Capacity Model**: story points (SP); iteration cap 20 SP; this feature targets ~2 SP
  (Tier 0) + ~3–6 SP (conditional Tier 1) — within a single iteration.
- **Drift Signals**: drift-log.md per iteration; `validate-governance.ps1` before each
  boundary commit; traceability check at after-tasks.
- **Human Oversight Points**: standard policy boundaries (specify, clarify→plan, plan→tasks,
  before-implement, review-signoff, retro, iteration-closeout, feature-closeout) — all
  human-judgment-required per `.specrew/config.yml`; additionally, any Tier 1 fix proceeds
  only after the CONFIRMED verdict is visible to the human at a boundary stop.
