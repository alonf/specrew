# Hardening Gate: Iteration 001

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/159-update-ux-small-fixes/spec.md`  
**Iteration Ref**: `specs/159-update-ux-small-fixes/iterations/001`  
**Requested Review Class**: `strongest-available`  
**Effective Review Class**: `strongest-available`  
**Overall Verdict**: `ready`  
**Approval Ref**: —
**Reviewed By**: Reviewer (codex)  
**Reviewed At**: 2026-06-06T00:00:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Stale running Specrew fails closed before project mutation; refusal occurs before extension/runtime/template refresh and dependency update actions; remediation points to Update-Module Specrew or SPECREW_MODULE_PATH; no new network calls, credentials, or privilege changes.` | `true` | `A stale module can currently downgrade a project. The guard protects project integrity and prevents old code from rewriting newer governance/runtime assets.` | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Older running module exits non-zero with actionable output; unparsable present project baseline fails closed before mutation; absent baseline keeps existing behavior; equal/newer behavior continues unchanged; --info remains read-only.` | `true` | `Failure semantics must be clear and early so the user does not see a partial update or silent downgrade.` | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `The feature adds a preflight refusal and message cleanup. It does not add retry loops, background recovery, or repeated distributed operations beyond existing update behavior; equal/newer no-regression tests cover unchanged existing rerun behavior.` | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Tests must prove stale refusal exit code, remediation text, deterministic protected-surface no-mutation, equal/newer no-regression, --info read-only behavior, active-message cleanup, and Select-String fallback when rg is unavailable.` | `true` | `The feature is a guard and message cleanup. Tests must exercise the negative path and evidence strength, not just a happy-path update.` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `This iteration ships local PowerShell and markdown/test changes only. It introduces no service, daemon, telemetry pipeline, or runtime operational dependency.` | `—` |
| `protected-surface-no-mutation` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `T003 must deterministically snapshot/hash before and after stale refusal: .specrew/config.yml, .specify/extensions/**, .squad/**, .claude/skills/**, .github/skills/**, .agents/skills/**, .cursor/rules/** if present, .github/agents/** generated runtime/agent surfaces when touched by update logic, .codex/agents/** when present and touched by update logic, .github/workflows/**, .github/prompts/**, .specify/templates/**, and any other path returned by update command template refresh mappings. Git status alone is insufficient.` | `true` | `The core acceptance criterion is no project downgrade. A status-only assertion can miss byte-level rewrites, generated churn, or untracked generated assets.` | `—` |
| `generated-active-surface-limit` | `maintainability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Prefer canonical source/template edits. Generated active surfaces such as .github/agents/squad.agent.md may be touched only if parity/tests require it; record the reason and limit the diff to stale 0.24.0 compatibility wording. Do not carry unrelated six-section packet or broad governance drift.` | `true` | `Parallel Feature 141 work owns adjacent governance/intake surfaces. This feature must not import unrelated generated governance drift while cleaning a narrow active-message issue.` | `—` |
| `collision-scope-check` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Before implementation approval and at review-signoff, run changed-file review against Feature 141 design-lens intake/runtime surfaces and Proposal 160 resolver/sidecar surfaces. Existing stashes remain unapplied and outside Feature 159.` | `true` | `This branch is intentionally parallel to Feature 141 and Proposal 160. Scope collision would create merge and governance ambiguity.` | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/159-update-ux-small-fixes/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/159-update-ux-small-fixes/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/159-update-ux-small-fixes/iterations/001/quality/lenses/test-integrity.md` |

## Before-Implement Readiness

- The protected-surface snapshot set is explicitly named.
- Changed-file collision checks against Feature 141 and Proposal 160 are mandatory.
- The 2026-06-06 before-implement collision check found only `.specify/feature.json` overlap with Feature 141 and no Proposal 160 overlap in current Feature 159 changed files.
- Feature 141 already changes `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`; implementation may touch it only for unavoidable stale `0.24.0` active-governance wording, with a recorded reason and narrow diff.
- Generated active surfaces are conditional and narrow.
- Existing stashes must stay out of Feature 159.
- Overall Verdict is `ready`: every concern is `addressed` or `not-applicable`.

## Notes

- Runtime evidence is complete in `coverage-evidence.md` and `review.md`.
- This gate does not authorize implementation by itself; explicit human implementation approval is still required.
