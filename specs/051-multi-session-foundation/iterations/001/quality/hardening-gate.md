# Hardening Gate: Iteration 001

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/051-multi-session-foundation/spec.md`  
**Iteration Ref**: `specs/051-multi-session-foundation/iterations/001`  
**Requested Review Class**: `phase-1-custom-composition`  
**Effective Review Class**: phase-1-custom-composition  
**Overall Verdict**: ready  
**Approval Ref**: —  
**Reviewed By**: Specrew Crew Coordinator  
**Reviewed At**: 2026-05-31  
**Post-Implementation Verification**: verified at gate level — acceptance suites exercised real config persistence + real `.gitignore` content + real git-index state (feature-051-session-mode 10/0; feature-051-file-classification 29/0); `git rm --cached` data-loss guard confirmed by T015 (working copy kept); governance validator green (no FAIL/medium/hard); see coverage-evidence.md. NOTE: the per-concern **Runtime Evidence Status** column below intentionally stays `pending-post-implementation` because each concern's **Evidence Basis** is `planning-time-analysis` — the validator's contract requires that pairing. Gate-level post-implementation verification is recorded here + in coverage-evidence.md, not by mutating the per-concern rows.  
**Verified At**: 2026-05-31 (review-signoff, accepted)

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `git rm --cached` (T012/T013) MUST be scoped to the classified per-session patterns only and MUST NOT delete working-tree files (no `-f`, no recursive working-tree removal). Config writes touch only `.specrew/config.yml` `session_mode`. No secrets, auth, or network surface in this iteration. | `false` | The one data-loss-capable operation (git index removal) is bounded to a known pattern set and never touches the working tree; everything else is local config text. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Invalid `session_mode` value rejected with a clear message (no partial write); unreadable/missing config degrades to default `single`; `.gitignore` merge preserves existing entries/comments and does not duplicate patterns (Edge Case). | `false` | Each failure path has a defined, non-crashing behavior. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `specrew config set` to the current value is a no-op success; gitignore generation is idempotent (re-running `specrew init` adds no duplicates); `git rm --cached` on an already-untracked path is a no-op. | `false` | All three Iteration-1 mutations are safely repeatable — `specrew init` is expected to be re-run. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Acceptance tests T007/T008 assert real `.specrew/config.yml` content after set/revert and fresh-init default; T014 asserts real `.gitignore` contains every per-session pattern; T015 asserts the file is removed from the git index AND still present on disk (the data-loss guard). No mocking of the filesystem or git index. | `false` | The tests verify observed reality (config bytes, gitignore lines, git index state), not declared success. | — |
| `operational-resilience-concerns` | `operational-resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Backward compatibility: default `session_mode: single` keeps existing single-session projects inert (no behavior change); gitignore merge is additive and structure-preserving; T019 runs the governance validator to confirm no regressions. | `false` | Opt-in design means zero blast radius on existing single-session installs. | — |
| `maintainability` | `maintainability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | New scripts `specrew-config.ps1`, `internal/session-config.ps1`, and `internal/file-classification.ps1` are single-responsibility; classification is data-driven (`Get-FileClassification` rule set), so adding a pattern is a data change, not a code change. | `false` | Keeps the foundation modular and reviewable for the four iterations that build on it. | — |
| `concurrency-correctness` | `concurrency` | `not-applicable` | `not-applicable` | `not-needed` | Iteration 1 has no concurrent-write surface: `specrew config set` and `specrew init` are single-process, single-developer operations. The atomic-write / race-condition controls become load-bearing in Iteration 2a (FR-007–011 session locks) and Iteration 4 (FR-035–037 identity-split migration). | `false` | No shared mutable runtime state is introduced in this iteration; deferring is honest, not a bypass. | deferred to Iteration 2a (concurrency) + Iteration 4 (migration) before-implement |

## Planning Evidence Notes

- **Scope**: Iteration 1 — session-mode config (US1, FR-001–003) + file classification / gitignore / git-rm-cached (US2, FR-004–006), ~11 SP (T001–T019). See iterations/001/plan.md.
- **Explicit deferrals (before-implement load-bearing discipline, per the reviewer standard):** the heavier security-relevant concerns named in plan.md Phase 2 — atomic-write race conditions (Iter 2a), YAML/JSON corruption recovery (Iter 2a), machine-fingerprint privacy / FR-043 (Iter 4), stale-lock clearing (Iter 2a), identity-split migration safety (Iter 4) — are **out of Iteration-1 scope because their code surface does not exist yet**. They are NOT silently bypassed: each lands as a load-bearing concern at its own iteration's before-implement gate, and the **Security Specialist is scheduled to be added at the Iteration 2a before-implement** (deferred per architect decision 2026-05-31 — Iteration 1 has no substantive security surface).
- The five canonical hardening concerns appear in the required order, followed by maintainability and concurrency.
- Capacity precondition: Iteration 1 is 11 SP (honest re-estimate, drift D-001 resolved), within the ≤20 SP cap.

## Hardening-Gate Status

**Overall Verdict**: ready — all material Iteration-1 risks are addressed or genuinely not-applicable; the single data-loss-capable operation (`git rm --cached`) is bounded and guarded by T015, and the concurrency/privacy/migration concerns are explicitly deferred to the iterations where their surface lands (with the Security Specialist scheduled for Iteration 2a).

**Scope**: Iteration 1 — session-mode configuration + file classification + gitignore generation + git-index cleanup, ~11 story_points (T001–T019).
