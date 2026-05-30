# Retrospective: Iteration 005

**Schema**: v1
**Date**: 2026-05-28

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.4 | 0.4 | 0.0 |
| T002 | 0.8 | 0.8 | 0.0 |
| T003 | 0.8 | 0.8 | 0.0 |
| T004 | 0.6 | 0.6 | 0.0 |
| T005 | 0.8 | 0.9 | +0.1 |
| T006 | 0.9 | 0.9 | 0.0 |
| T007 | 0.5 | 0.5 | 0.0 |
| T008 | 0.6 | 0.5 | -0.1 |
| T009 | 0.6 | 0.6 | 0.0 |
| T010 | 0.6 | 0.9 | +0.3 |

**Average variance**: +0.03 SP/task (≈ +0.3 SP total; planned 6.6 → actual ≈ 6.9, inside the 6–8 SP band with the 0.8 reserve). The T010 overrun came entirely from working around the A-001 tooling crash (hand-authoring evidence + the canonical defer entry the validator demanded).

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.6 | 0.6 | 0.0 | Plan/tasks were already refreshed; this session added the missing governance scaffold. |
| Implementation | 2.5-3.2 | 2.8 | 0.0 | Runtime contract + wording + skills + prompt landed cleanly; no rework. |
| Review Guidance | 0.8-1.2 | 0.9 | 0.0 | Reviewer-charter focus block added to four surfaces. |
| Verification / Evidence | 1.6-2.0 | 2.2 | +0.2 | Over band: A-001 forced hand-authoring of evidence + canonical defer record + review.md. |
| Rework Buffer | 0.2-0.8 | 0.0 | 0.0 | No requirement rework; tests went RED→GREEN on first implementation pass. |

## Drift Summary

- Total drift events: 0 (no specification drift)
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0
- Non-drift tooling anomalies logged: 2 (A-001 StrictMode crash; A-002 expected phase-two skip) — see `drift-log.md`.

## What Went Well

- **RED-first discipline held.** New contract assertions failed against current code (`Get-CrewInteractionProfileAreas` missing) before implementation, then passed — meaningful coverage, not after-the-fact tests.
- **Single source of truth.** Four duplicated persona-label maps were consolidated into one `$script:CrewInteractionProfileAreas` metadata table, so display labels, persona IDs, and expertise keys can never drift apart again.
- **Parity preserved by restraint.** The intake engine was left untouched (its `persona_name` use is internal only), so shipped ↔ `.specify` SHA256 parity held with zero risk; skill copies kept byte-identical.
- **Honest, bounded disclosures.** Same-session self-review, A-001 blast-radius growth, and the FR-038 in-situ caveat were surfaced at the gate — and the independent cross-reviewer confirmed all three accurate.
- **Committed-work check.** Verified production files were committed (no working-tree-only verdict), closing the Shape-5 failure mode.

## What Didn't Go Well

- **A-001 blocked governance machinery at three entry points.** The shared `Get-QualityEvidenceContent` helper crashes under StrictMode on the `| Gate | Target | Notes |` quality-gate table convention that Feature 049 actually uses, breaking `scaffold-iteration-artifacts.ps1`, `run-mechanical-checks.ps1` (cosmetic regen only — findings still wrote), AND `scaffold-reviewer-artifacts.ps1`. This forced hand-authoring of the evidence envelope and review, and **prevented generating the reviewer-artifact set entirely** (code-map, coverage-evidence, review-diagrams, dependency-report). Bigger blast radius than the original defer scope.
- **Validator-demanded canonical defer schema is undiscoverable from the artifact alone.** The human-readable iter-001 gap-deferral entry format did not match the machine parser (`**Type**: defer`, `**Affected Iteration**: <repo\rel\path>`, `**Approving Human**:`, plus a literal backslash `.squad\decisions.md` link in review.md). Two validator round-trips were needed to discover the exact contract.

## Improvement Actions

1. Owner: framework maintainer | Phase: next framework slice | Type: bug-fix | **Elevated priority** — A-001: make `Get-QualityEvidenceContent` strict-safe (defensive property access) and reconcile the canonical quality-gate table schema (`| Gate | Target | Notes |` vs the `Required Quality Gate / Evidence Source` columns the helper expects). Larger blast radius than at defer time (now blocks the full reviewer-artifact set). Candidate to fold into the framework-file-protection proposal. Mirror to `extensions/specrew-speckit/scripts/`.
2. Owner: maintainer | Phase: F-049 feature-closeout | Type: verification | FR-038 in-situ: exercise `specrew start` start-context.json generation end-to-end during beta install and confirm the `user_profile` soft-guidance block renders as expected. Add to the feature-closeout beta-install validation checklist.
3. Owner: maintainer | Phase: F-049 feature-closeout | Type: housekeeping | `Specrew.psd1` FileList addition for `test-publish-harness.ps1` (carryover originating from iter-001, commit `f857da4c`) — accept as-is or fold into feature-closeout cleanup.
4. Owner: framework maintainer | Phase: next framework slice | Type: docs/validation | Surface the canonical gap-deferral schema (machine fields + the backslash `.squad\decisions.md` link requirement) in the reviewer charter or a template so reviewers don't discover it via validator round-trips.

## Calibration Suggestion

- Suggested capacity adjustment: keep current baseline (`25`) for now; **flag for F-049 feature-closeout** that `25` is itself a never-reverted "temporary" bump (the root cause of the 58 repo-wide capacity-drift FAILs). The cleanup should decide whether to revert to `20` (and reconcile historical plans) or make `25` permanent.
- Rationale: this slice's variance was near-zero on the work itself; the only overrun was tooling friction (A-001), not estimation error, so no velocity-based capacity change is warranted.

## Notes

- Iteration 003 + Iteration 004 protected zones were not touched; Proposal 120 (iteration 004) commitments preserved.
- Next boundary is iteration-closeout (human gate); not auto-advanced. Cross-reviewer available for that boundary too.
