# Implementation Plan: Managed-Skill "Stuck Preserving" Guard

**Branch**: `161-managed-skill-preserving-guard` | **Date**: 2026-06-06 |
**Spec**: `spec.md`
**Input**: Feature specification from
`specs/161-managed-skill-preserving-guard/spec.md`

## Summary

One governed investigation iteration that closes Proposal 161. Feature 160
already confirmed and fixed the classifier-level misclassification
(exact-current-canonical content without a marker); this feature delivers the
deploy-level end-to-end repro the proposal asked for, probes the residual
stale-older-canonical scenario the exact-match recovery cannot catch, and ends
in a recorded CONFIRMED/REFUTED verdict. A narrow Tier 1 fix ships only if the
residual scenario is both misclassified AND reachable through a real upgrade
path; otherwise the feature closes REFUTED with evidence and zero behavior
change.

## Technical Context

**Language/Version**: PowerShell 7 for deploy script, repro harness, and
integration tests
**Primary Dependencies**: PowerShell Core (`pwsh`), existing standalone
integration-test harness pattern (`tests/integration/*.tests.ps1`), the real
`extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`
**Storage**: No product persistence; temp scratch projects + evidence records
**Testing**: Direct `pwsh` integration tests; deploy executed for real against
an isolated scratch project (not AST-extracted functions)
**Target Platform**: Platform-neutral string/file logic; Windows host is
sufficient (spec assumption)
**Performance Goals**: Harness completes in under 30 seconds locally; no
network or package-manager access
**Constraints**: No blind fixes (FR-003 gates FR-004); no release/tag/merge/
PR/push-to-main; no writes outside the temp sandbox; F-141/F-159/F-160
surfaces untouched beyond read-only context (FR-007)
**Scale/Scope**: One investigation slice + one conditional fix slice, single
iteration

## Architecture

### Components

1. **Deploy-level repro harness**
   (`tests/integration/managed-skill-stuck-preserving.tests.ps1`) — creates an
   isolated scratch project (with the `.squad` directory the deploy requires,
   seeded `.copilot/skills/specrew-*` fixtures, and active skill roots), then
   executes the real `deploy-squad-runtime.ps1` against it and asserts on the
   deployment-action record plus on-disk outcomes. Scenarios:
   - S1 marker-present legacy dir → `removed-legacy-managed-skill`;
   - S2 genuinely user-authored legacy dir (front matter, never-canonical
     content, no marker) → `preserved-legacy-unmanaged-skill`;
   - S3 current-canonical content, no marker → removed (F-160 regression guard
     at deploy level);
   - S4 **stale older-canonical** front-matter content, no marker → outcome
     captured (the residual-hypothesis probe);
   - S5 idempotency: second consecutive run reports preserved/no-change for
     managed active-root surfaces;
   - S6 active roots: `SKILL.md` + `.specrew-managed` marker present in all
     four active roots after deploy.
2. **Reachability analysis** — evidence answering whether any real Specrew
   upgrade path produces a marker-less legacy dir holding stale canonical
   front-matter content: when `.copilot/skills` deploys existed, whether they
   wrote markers, and when canonical templates gained front matter (git
   history of `extensions/specrew-speckit/squad-templates/skills/` + deploy
   script history). Misclassification alone is not a bug; misclassification ×
   reachability is.
3. **Verdict record** — CONFIRMED (exact code path + reachable triggering
   scenario) or REFUTED (every reachable path refreshes/cleans correctly),
   written into iteration quality evidence and review.md.
4. **Conditional narrow fix** — only if CONFIRMED. Candidate shapes (decided
   by evidence, not pre-committed): recognize stale-canonical legacy content
   via catalog-derived identity (e.g., front-matter `name:` matching a managed
   catalog directory) strictly inside the legacy-cleanup path, or another
   provenance-strengthening change of equivalent narrowness. Hard constraints:
   classification/marker behavior only; the genuinely-user-authored preserve
   path must be provably unchanged (S2 passes pre- and post-fix).
5. **Regression guard** — the existing
   `tests/integration/managed-runtime-sidecar.tests.ps1` (F-160 Cases A–D +
   mirror parity) must pass unchanged throughout.

### Canonical Flow

Implementation first builds and runs the repro harness (S1–S6) and the
reachability analysis, then records the verdict. Only a CONFIRMED verdict
unlocks fix work; the fix is followed by re-running S1–S6 (S4 flips to
managed/cleaned), the F-160 fixture, and the repo validator. A REFUTED verdict
closes the iteration with evidence and no source change to the deploy script.

### FR to Verification Mapping

| FR | Verification | Authoritative Surface |
| --- | --- | --- |
| FR-001 | Harness runs the real deploy against a temp scratch project; two consecutive runs produce identical outcomes | repro harness + its output record |
| FR-002 | Scenarios S1–S4 asserted individually (S5/S6 supporting) | repro harness |
| FR-003 | Verdict with code-path citation present before review-signoff | iteration quality evidence + review.md |
| FR-004 | Fix diff limited to classification/marker behavior; S4 flips only under CONFIRMED | source diff + harness pre/post evidence |
| FR-005 | S2 (user-authored preserve) passes in every state | repro harness + F-160 fixture Case D |
| FR-006 | Harness + F-160 fixture both pass in repo test flow | test run logs |
| FR-007 | `git status`/diff shows no F-141/F-159/F-160-surface edits; no push/tag/PR | git evidence + review checklist |

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`
**Resolved Quality Profile Output**: `quality-profile.custom-composition.v1`
(`bounded-custom-composition`) from `resolve-quality-profile.ps1` on
2026-06-06.
**Feature-Specific Applicability**: The resolver fell back to a bounded custom
composition (weak preset signals). The active surfaces are PowerShell deploy
logic and integration tests; Node/React/Postgres tooling visible at repo level
is not applicable to this slice.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `squad-runtime-deploy` | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` (+ `.specify` mirror parity) | PowerShell deploy helper | Owns the managed/preserve classification under investigation |
| `skill-templates` | `extensions/specrew-speckit/squad-templates/skills/**` | Markdown templates | Canonical content + front-matter history drive reachability |
| `test-fixtures` | `tests/integration/managed-skill-stuck-preserving.tests.ps1`, `tests/integration/managed-runtime-sidecar.tests.ps1`, temp scratch projects | PowerShell integration harness | Proves behavior before any fix |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| `code-quality` | required | Any fix must stay narrowly scoped and reviewable |
| `design-quality-and-separation-of-concerns` | required | Legacy-cleanup classification must not leak into active-root deploy semantics |
| `verification-confidence` | required | Repro-first rule: proof before change; deploy-level not just function-level |
| `maintainability` | required | Verdict + tests must keep this question closed for future maintainers |
| `security` (custom lens `security-baseline@v1.0.0`) | required | The preserve path protects user-authored content from deletion — data-loss guard |
| `robustness` (custom lens `robustness-baseline@v1.0.0`) | required | Classification fallbacks and idempotent re-runs must be explicit |
| `test-integrity` (custom lens `test-integrity@v1.0.0`) | required | S4 must be a genuine probe, not a test written to pass current behavior |

### Quality Tool Bundle

| Area | Selection |
| --- | --- |
| Bundle ID | `phase1-custom-quality-bundle` |
| Mechanical Checks | dead-field, anti-pattern, test-integrity |
| Ecosystem Tools | direct `pwsh` integration tests; repo validator; markdownlint for boundary commits |
| Manual Evidence | this Phase 1 section; iteration quality evidence; verdict record |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source |
| --- | --- | --- |
| `dead-field` | mechanical | `specs/161-managed-skill-preserving-guard/iterations/001/quality/mechanical-findings.json` |
| `anti-pattern` | mechanical | `specs/161-managed-skill-preserving-guard/iterations/001/quality/mechanical-findings.json` |
| `test-integrity` | mechanical | `specs/161-managed-skill-preserving-guard/iterations/001/quality/mechanical-findings.json` |
| `stack-tooling-evidence` | tooling | `specs/161-managed-skill-preserving-guard/iterations/001/quality/quality-evidence.md` |
| `quality-lens-review` | manual-evidence | `specs/161-managed-skill-preserving-guard/iterations/001/quality/quality-evidence.md` |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable | Follow-up |
| --- | --- | --- |
| `concurrency-correctness` | Single-process deploy script; no shared-state or parallel behavior in scope | None |
| `resiliency` | No retry/reconnect/degraded-recovery workflow beyond idempotent re-run (covered by S5) | None |
| `retry-idempotency-and-recovery` | No material retry workflow; deploy idempotency is asserted directly by S5 | None |
| Node/React/Postgres tooling | No JS/TS or persistence source in scope for this slice | Activate only if implementation unexpectedly touches those stacks |

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: hardening-gate planning only; runtime proof stays
pending until the implementation/review slice.
**Hardening Gate Artifact**:
`specs/161-managed-skill-preserving-guard/iterations/001/quality/hardening-gate.md`
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`

### Hardening Focus Areas

| Focus Area | Why It Matters | Status |
| --- | --- | --- |
| Security surface (user data) | The preserve decision protects user-authored skills from deletion; any fix must be provably data-loss-safe | required |
| Error handling / failure semantics | Misclassification is silent today; the verdict must name where silence hides staleness | required |
| Idempotency | Re-running deploy must be safe (S5) | required |
| Test integrity | Repro-first: S4 written as a probe before any fix exists; no after-the-fact tests that only prove the final implementation | required |

### Lens Activation Plan

| Lens Ref | Activation | Rationale |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | Preserve path = user-data protection |
| `robustness-baseline@v1.0.0` | required | Fallback classification chain must be explicit and reviewed |
| `test-integrity@v1.0.0` | required | The feature's core value is proof before fix |

### Explicit Later Deferrals

- Full lens-row execution is deferred until the implementation/review slice.
- Product documentation updates are deferred unless a confirmed fix changes
  user-visible behavior.
- Historical-template extraction from git history is attempted only if
  synthetic stale-canonical fixtures prove insufficient for reachability
  reasoning.

## Constitution Check

- **Spec Authority Gate**: every planned artifact maps to FR-001..FR-007. PASS.
- **Layering Gate**: probes target deploy-script classification only; no UI,
  API, or persistence work. PASS.
- **Traceability Gate**: FR-to-verification mapping explicit; tasks will each
  tie to ≥1 FR/SC. PASS.
- **Ownership Gate**: Implementer owns harness + conditional fix; Reviewer owns
  verdict-evidence integrity and the data-loss guard; Spec Steward owns the
  FR-007 scope guard. PASS.
- **Capacity Gate**: ~5–8 SP single iteration, well under the 20 SP cap. PASS.
- **Drift/Reconciliation Gate**: drift exists if source changes precede repro
  evidence, or the verdict lacks a code-path citation. PASS.
- **Verification Gate**: deploy-level harness + F-160 fixture regression both
  required. PASS.

## Project Structure

### Documentation and Review Artifacts

```text
specs/161-managed-skill-preserving-guard/
├── spec.md
├── plan.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── managed-skill-preserving-guard.md
├── review-diagrams.md
├── checklists/
│   └── requirements.md
└── tasks.md                    # produced during tasks phase
```

### Planned Source/Test Surfaces

```text
extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1   # conditional fix only
.specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1  # mirror parity, conditional
tests/integration/managed-skill-stuck-preserving.tests.ps1    # new repro harness
tests/integration/managed-runtime-sidecar.tests.ps1           # regression guard (unchanged)
```

**Structure Decision**: The harness creates scratch projects under
`[System.IO.Path]::GetTempPath()` and removes them in `finally`. It never
writes into the working repo's `.squad`, `.copilot`, `.claude`, `.cursor`,
`.github`, `.agents`, or `.specrew` directories.

## Capacity and Iteration Structure

One iteration is planned.

- **Iteration 001 — Deploy-level repro, verdict, conditional fix (~5–8 SP)**:
  repro harness S1–S6 (~2 SP), reachability analysis + verdict record (~1 SP),
  conditional narrow fix + pre/post evidence + mirror parity (~3–5 SP, only if
  CONFIRMED), review evidence and retro. If REFUTED, the iteration closes the
  fix budget unspent.

## Complexity Tracking

No Constitution Check violations. The deploy-level harness is justified over
extending the existing function-level fixture because the proposal's open
question is precisely whether the *composed* deploy behavior (definition
lookup → classification → removal/preserve → active-root overwrite) can freeze
a managed skill — something AST-extracted unit cases cannot witness.
