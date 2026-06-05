# Hardening Gate: Iteration 010

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/010`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-05T16:15:00Z

**Pre-Implementation Readiness**: Iteration 10 relocates the A4/A5/A6 lens conduct out of the one-shot launch
prompt into a re-invokable `specrew-design-workshop` skill + per-lens conduct co-located in each
`design-lenses/<id>.md` + a trimmed launch prompt. Same intent, changed implementation; no FR change.
Grounded by per-host research (all five hosts share the agentskills.io open standard — "just folders"; skills
re-invoke on-demand). 17/20 SP. The deploy is unchanged (the skill auto-discovers via the existing flat-`.md`
path; the skill-templates test enumerates skills dynamically). SC-024 (does the relocated delivery make the
agent reliably surface in-conversation?) is behavioral → the runtime **re-confirm dogfood** is the acceptance.
Authorized by the maintainer ("Yes, implement it. all since i am going to sleep. I will test tomorrow.").

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The change is a markdown skill template + per-lens md content + prompt-pointer text + deploy auto-discovery; no auth, secrets, network, eval, or credential persistence. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | The skill is **self-contained per load** and **self-reinvoking** (the four hosts that do not document reload still get the full method from one load); the launch-prompt pointer remains so the conduct is reachable even if a host does not auto-invoke the skill; the deploy and skill-templates test degrade gracefully (enumerate dynamically). | `true` | Defect class is a host not auto-loading the skill or not reloading per lens; controls are self-containment + the prompt pointer fallback, verified by the lens-conduct-delivery test (skill self-contained, prompt points to it). | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries/transactions/idempotency surface; the skill deploy is an idempotent file copy (re-deploy overwrites the managed `SKILL.md`). | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | The lens-conduct-delivery suite asserts the relocation STRUCTURE (skill frontmatter trigger description + relocated conduct; all 9 lens md carry Workshop Conduct; the prompt points to the skill + is trimmed) and the skill-templates / design-gate-runtime-hardening / design-analysis-gate / selector suites stay green. PLUS the **SC-024 re-confirm dogfood** — whether the agent now surfaces in-band reliably is NOT unit-provable. | `true` | The relocation is pure/deterministic structure → unit-testable green; the behavioral payoff (reliable in-band surfacing) must be exercised in a real run (SC-024). | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | The skill + lens md + prompt are LLM/network-free; `index.yml` stays pure; the deploy enumerates skills dynamically (no hardcoded list to drift); the skill ships to `.claude/skills` + `.agents/skills` (the two-folder covering set for all five hosts); no release/publish/push; the deferred Proposal 156 scope stays out. | `true` | Operability = no network/LLM, dynamic enumeration, host-portable open-standard packaging, honest framing that the reliability payoff is the dogfood's. | `—` |

## Release-Blocking Items

- No beta/stable publishing in scope; no push/PR while Feature 141 is in progress.
- Implementation review must confirm the deploy is unchanged (auto-discovery), `index.yml` was NOT modified, the
  skill is self-contained + self-reinvoking, the launch prompt retains a pointer (no orphaned conduct), and the
  deferred Proposal 156 scope stays out.
- The review MUST include the **SC-024 re-confirm runtime dogfood** — a real run where the relocated delivery
  drives a reliably-surfaced workshop — not only the structural unit tests.

## Notes

- The three `addressed` concerns are promoted to `runtime-evidence` / `recorded` at this gate on the strength of
  the structural test suites (the relocation is locked in); the behavioral payoff is the SC-024 dogfood at
  review-signoff.
- Overall Verdict `ready`; the in-band-surfacing reliability bar is the dogfood, not the unit tests (the
  i6/i7/i8/i9 lesson — and the i9 retro's PoC-up-front rule: this iteration's structure is testable, but a
  short downstream run is what confirms the agent obeys focused delivery where it skimmed the mega-prompt).
