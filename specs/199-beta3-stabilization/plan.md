# Implementation Plan: Beta3 Stabilization (v0.40.0-beta3)

**Feature**: 199-beta3-stabilization
**Iteration**: 001 (single iteration)
**Date**: 2026-08-10
**Inputs**: spec.md (approved for specify + clarify), iterations/001/design-analysis.md
(approved for plan with Option B, gate Valid), implementation-rules.yml (inherited 198
+ three 199 deltas), resolved quality profile (security-baseline, robustness-baseline,
test-integrity required; strongest-available routing).

## Architecture

Bound by the design gate: existing core/store/orchestrator/navigator layering, no new
layers. Option B: a first-class pending-pause fact in the review authority store.
Bridge work sits at the orchestrator and classifier edges beta4 rebuilds; durable work
lands in capture, store integrity, init, catalog, banner, and the language layer.
Component-to-file anchors:

| Component | Files (source of truth; `.specify`/`extensions` mirrors sync same-commit) |
| --- | --- |
| Pause terminal + landing | `scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1` |
| Budget/spend decisions | `scripts/internal/continuous-co-review/review-authority-core.ps1` |
| Pending-pause fact + reparse policy | `scripts/internal/continuous-co-review/review-authority-store.ps1` |
| Stop authority (stale classifier) | `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1` (:368/:385 emit sites) |
| Decision surface + stop blocks + gloss helper | `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`, `worktree-navigator.ps1` |
| Verdict capture | `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` (:135-:227) |
| Hook wiring reconciliation | `scripts/internal/deploy-refocus-hooks.ps1`, hooks status/doctor |
| Review windows | `scripts/internal/continuous-co-review/reviewer-host-catalog.ps1` (codex row :64) |
| Reviewer prompt contract | `scripts/internal/continuous-co-review/worktree-reviewer.ps1` (prompt assembly) |
| Init scaffold + env_refs + errors | `scripts/specrew-init.ps1` (:919-922), `verification-plan-materializer.ps1`, `verification-plan-contract.ps1`, `verification-plan-runner.ps1`, `review-campaign-orchestrator.ps1` (:441-449) |
| Banner version | `scripts/internal/specrew-bootstrap-provider.ps1` (:438), `coordinator-prompt-surgery.ps1` (:105-110); reference: `specrew-start.ps1:Get-ManifestSpecrewVersionText` |
| One-message stops + sync defense rule | packet templates, `specrew-gate-stop` skill, sync skill instructions |
| CI chore | `.github/workflows` (markdownlint-cli install) |

## Work breakdown, effort, and FR-to-test mapping

20 SP iteration convention; **12.1 SP planned** (~10–12 target) — the unplanned
remainder is deliberate slack for review rounds and release ceremony. Each work item
lands RED-first (FR-023): the fixture reproduces the defect through the shipped entry
point, then the fix turns it green.

| # | Work item | FRs | SP | RED fixture (through the shipped path) |
| --- | --- | --- | --- | --- |
| W1 | Pause as round terminal + pending-pause fact + decision surface + per-campaign budget 4 + single-run continuation + minors never gate | FR-001..004 | 3.0 | `tests/continuous-co-review/unit/pause-terminal.Tests.ps1`: campaign run through `Invoke-ReviewCampaignCommand` in a fixture project — asserts surface content (SC-001), no second round without a decision fact, budget refusal at 5th round (SC-002), minors non-gating |
| W2 | Composed stop-here landing (verification -> residual acceptance -> gate sync as one action) | FR-005 | 1.0 | `stop-here-landing.Tests.ps1`: reproduces the T067 wedge (accepted-residuals-on-unreviewed-tree), asserts single-action landing opens the gate (SC-004) |
| W3 | Single-authority stop surface: consult gate store, in-flight suppression, records-only non-staling, pending-pause quiet | FR-007..009 | 1.0 | `stop-authority.Tests.ps1`: three reproductions from ledger F5 evidence + pending-pause quiet (SC-003) |
| W4 | Verdict capture: phrase-first, scan window, plain-English immunity; prompt-submit primary + wiring reconciliation + drift flag | FR-010 | 1.5 | `tests/bootstrap/ConversationCapture.Tests.ps1` additions: iteration 011 reproductions (SC-005); `hooks-reconcile.Tests.ps1`: stale 3-event settings -> deploy repairs + status flags drift |
| W5 | Reparse-tag discrimination + consumer refusal messages + install docs + advisory sentence | FR-011 | 1.75 | tag-classifier fixtures with real tag constants; junction/symlink refusal fixtures stay green (SC-006); hydration leg by manual measurement, proof line transcribed |
| W6 | Init verification-plan scaffold + env_refs default (N4 list) + failures name the missing piece | FR-012..013 | 1.0 | `init-verification-plan.Tests.ps1`: fresh project -> preflight passes (SC-007); broken env_refs/schema/defer-record -> error names it |
| W7 | Reviewer-invoked-only spend accounting | FR-014 | 0.5 | `spend-accounting.Tests.ps1`: T067 three-infra-failure sequence leaves allowance intact (SC-008) |
| W8 | Consumer-language layer: gloss helper (id+title), banned-machinery-noun check, surface pass over packet templates/stop messages/skills/banner; one-message decision stops instruction rule | FR-015..017 | 1.75 | `consumer-language.Tests.ps1`: rendered surfaces carry zero banned nouns + zero unglossed IDs (SC-009); template lint over instruction surfaces |
| W9 | Codex window 900 s + timeout message names the flag | FR-018 | 0.5 | catalog row fixture + timeout message fixture |
| W10 | Banner full prerelease version (+ mirror lockstep) | FR-019 | 0.25 | banner fixture asserts `0.40.0-beta3` composition (SC-010) |
| W11 | Verdict-goal reviewer prompt contract (blessed clean verdict; findings need failure scenarios; ranked + capped) | FR-006 | 0.5 | prompt-assembly fixture asserts contract text; paired abuse test: finding without failure scenario is rejected at ingest classification |
| W12 | Records: 009/010 wording fix; release-notes draft with the beta4 claim sentence | FR-020..021 | 0.25 | records-only; verified by review |
| W13 | markdownlint-cli CI install (198-carried chore) | FR-022 | 0.1 | CI lane goes green on the PR (measured, not drafted) |

Release leg (FR-021) executes at feature-closeout under the beta-stable model:
certification review before the tag, tag v0.40.0-beta3 at the merge commit, publish
workflow, Gallery verification, maintainer PASS/FAIL on the installed prerelease.
Every external mutation waits for the maintainer's explicit go.

## Test strategy

Deterministic Pester fixtures through shipped entry points (no mocks of the engine's
own layers); paired honesty tests for every economics invariant (legitimate + abuse
path, message-content assertions); executable fixtures for failure paths; the one
manual measurement (OneDrive hydration) recorded with transcribed proof lines and
scope. Mirror parity and psd1 FileList checks ride every commit (inherited custom
rules). Mechanical checks + SelfLeakLintLane on touched templates/skills.

## Quality plan (embedded from the resolved profile)

- security-baseline (required): W5 is the security-sensitive surface — the reparse
  policy must not weaken the beta2 link refusal; denial-path fixtures are the
  evidence. W4's capture changes keep authorization provenance human-only.
- robustness-baseline (required): W1/W3/W7 failure semantics — structured terminal
  outcomes, fail-closed authority contradictions, no silent retries.
- test-integrity (required): RED-first ordering enforced per work item; fixtures pin
  instances, not descriptions; evidence tools verified before trust (FR-023).
- Routing: strongest-available reviewer (codex, human-authorized) reviews the
  implementation; any downgrade needs an approved override record.

## Risks and watch items

- Codex file-delivery quirk (findings via file, empty stdout) may mislabel runs
  "partial" during OUR review-signoff — recorded beta4 watch item; harvest recovers.
- Prompt-submit capture in THIS session: wiring repaired on disk but the host
  snapshots hook config at session start — Stop-fallback + the sync defense rule
  cover until the next session.
- The pending-pause fact is bridge: beta4 replacement notes recorded in
  design-analysis.md; keep the schema minimal (no speculative fields).

## Beta4 replacement notes (bridge items, mandated)

Carried verbatim from design-analysis.md: pause plumbing -> beta4
disposition/economics pipeline; stop-authority point checks -> beta4 stop-surface
state model; composed landing -> beta4 disposition vocabulary. The decision-surface
contract, consult-before-block ordering, pending-decision-quiet semantics, and the
one-action landing UX are durable.
