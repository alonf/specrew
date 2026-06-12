# Hardening Gate: Iteration 003

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/182-work-kind-branch-governance/spec.md`
**Iteration Ref**: `specs/182-work-kind-branch-governance/iterations/003`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-12T02:45:00Z
**Post-Implementation Verification**: complete — runtime evidence recorded for every blocking concern (forge-neutral-reviewer 10 + forge-neutralization-sweep 7 groups + pr-review-integration 7 + host-coupling-firewall 2 + work-kind-validator 12 + work-kind-runtime 19 PASS; PSScriptAnalyzer production 0 errors / 0 new warnings; markdownlint 0; validate-governance PASS on iters 001/002/003 on the review state). See Concern Review (Runtime Evidence Status `recorded`).
**Verified At**: 2026-06-12T13:30:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | The migration introduces NO new privileged action: T301–T303 are documentation/prose edits; T304 (G5) routes reviewer detection through the EXISTING read-only adapter capability model. No new secret, token, or network call. The load-bearing control: neutralizing the prose/script must NOT silently drop a governance control — the `review_gate` stays present (human review always-available; Copilot becomes opt-in), proven by T305/T306. | `true` | The only risk is accidentally weakening governance while decoupling; the controls keep review_gate present + opt-in and add no privileged surface. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Fail-open: the G5 reviewer routing degrades to the project's `review_gate` (human review) when no adapter / a non-GitHub provider / no Copilot is present — never an error, never a baked-in Copilot. The genericized closeout prose must not break Specrew's OWN gh + beta-publish flow (T308 guard). Tests: G5 fail-open + non-GitHub path (T305); own-flow parity (T308). | `true` | NFR #5 fail-open is load-bearing; the decouple must degrade honestly on non-GitHub and not regress Specrew's own GitHub path. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | Prose edits are idempotent; reviewer detection is single-pass, read-only; no retry logic, concurrent writers, or shared mutable runtime state introduced. | `false` | Recorded so the omission stays reviewable; the migration adds no retry/concurrency surface. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Behaviour-proving, scope-aware: the SC-008 sweep (T306) asserts downstream-governing surfaces carry no GitHub-only mandate, with an allowlist mirroring the inventory so it does NOT false-positive on the GitHub host-adapter or Specrew's own infra; the G5 tests (T305) prove adapter-mediated routing; T308 proves the own-flow still works. Not file-presence. | `true` | SC-008/SC-013 are the i3 acceptance bars; a naive repo-wide grep would false-positive on legitimate GitHub usage, so the sweep must encode the inventory's change/no-change boundary. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | The migrated surfaces are ALSO dogfooded by Specrew; the operational risk is breaking Specrew's own closeout. Mitigated by the genericize-with-labeled-example approach (DP-1 option b — recommended) and the explicit own-flow parity guard (T308). Specrew's own infra (`.github/`, publish-module.yml, own repo URL, version/deploy scripts) is diff-verified UNCHANGED (T307). | `true` | The i3 operational surface is "don't break Specrew's own usage while decoupling downstream"; T307 (own-infra-unchanged) + T308 (own-flow-works) are the controls. | `—` |

## Notes

- Authored as a PLANNING-TIME pre-implementation gate for **iteration 003 (forge-neutralization
  migration, FR-019)**, then **closed at iteration-closeout with post-implementation runtime evidence
  recorded**: the four runtime-bearing concerns moved from `pending-post-implementation`
  (`planning-time-analysis`) to `recorded` (Evidence Basis `runtime-evidence`) once T304–T308 were built
  and their behaviour proven (forge-neutral-reviewer 10 + sweep 7 groups + pr-review-integration 7 +
  host-coupling 2 + work-kind-validator 12 + work-kind-runtime 19 PASS; G5 added 0 analyzer warnings).
- **Both gate decisions are resolved** (inventory section E): **DP-1 (b)** — genericize the closeout
  shape, keep GitHub + PSGallery as a labeled non-mandatory example that `provider: github` instantiates
  (no new adapter surface); **DP-2** — `docs/methodology/lifecycle-discipline.md` labeled as a
  Specrew-own example, not a downstream mandate.
- **Scope guardrail (binding) held:** downstream-governance neutralization ONLY — NOT a general GitHub
  cleanup. Own-infra, the GitHub host adapter, and false positives stayed out-of-scope (inventory C/D);
  the one borderline (D-303 `proposal-discipline.md`) was carried to the review boundary and
  maintainer-ratified as inheritable methodology.
- **Specrew's own GitHub usage is unchanged**; T307 (own-infra diff-verify) + T308 (own-flow parity)
  proved it.
- T013b stays the release/deploy step (drift-log D-001), resolved at feature-closeout. The Iteration-2
  dashboard WARN is untouched (confirm-not-harden at feature-closeout).
