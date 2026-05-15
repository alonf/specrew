# Hardening Gate: Iteration 002

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/017-velocity-dashboard/spec.md`  
**Iteration Ref**: `specs/017-velocity-dashboard/iterations/002`  
**Requested Review Class**: `strongest-available`  
**Effective Review Class**: `reviewer-self-review`  
**Overall Verdict**: ready  
**Approval Ref**: `specs/017-velocity-dashboard/iterations/002/review.md` (review-verdict-signoff accepted)  
**Reviewed By**: Reviewer  
**Reviewed At**: 2026-05-16  
**Post-Implementation Verification**: pending-post-implementation  
**Verified At**: —

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `planning-evidence` | `not-needed` | Keep Iteration 002 limited to repository-local PowerShell, Markdown, YAML, JSON, and git-tracked artifact generation. Do not introduce secrets, network I/O, or new trust boundaries. | `false` | The authorized slice only extends local CLI, closeout artifacts, validator rules, and documentation surfaces. No new auth, secret-handling, or external service behavior is required. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `design-review` | `pending-post-implementation` | Missing roadmap data, malformed history, renderer exceptions, or artifact-write failures must yield bounded warnings and a truthful partial result rather than a hard crash or silent success. | `true` | FR-019, FR-022, FR-031, and FR-046 make the dashboard additive to lifecycle work. The dashboard may warn, but it must not turn normal closeout into a brittle second failure gate. | reviewer sign-off |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `design-review` | `pending-post-implementation` | Re-running ad hoc dashboard commands or closeout scaffolds must not silently overwrite historical `dashboard.md` / `closeout-dashboard.md` snapshots. | `true` | FR-020 and FR-021 define the stored artifacts as historical records. A second run may create follow-up evidence or warn, but it must not rewrite history in place. | reviewer sign-off |
| `test-integrity-targets` | `test-integrity` | `addressed` | `design-review` | `pending-post-implementation` | The implementation must prove behavior on healthy, sparse/fresh, malformed, and no-roadmap repositories plus the closeout-path replay that creates immutable artifacts and warning-only validator outcomes. | `true` | FR-032 is not satisfied by renderer tests alone. The closeout hooks, validator, and immutable-artifact rules must be exercised through the real replay paths. | reviewer sign-off |
| `operational-resilience-concerns` | `operational` | `addressed` | `validator-baseline` | `pending-post-implementation` | Validator additions must stay additive, warning-oriented, and repo-wide safe. The committed pre-implementation rerun must stay green, and the earlier dashboard warning themes must remain explicit implementation concerns rather than hidden debt. | `true` | The finalized pre-implementation validator rerun completed cleanly with exit 0 and no WARN/FAIL lines. Earlier ad hoc warning themes (roadmap drift and missing historical dashboard artifacts) are preserved below as review concerns because Iteration 002 still needs truthful runtime handling for them. | reviewer sign-off |
| `auto-invocation-vs-boundary-commit-discipline` | `lifecycle-safety` | `addressed` | `design-review` | `pending-post-implementation` | **Explicit failure mode**: automatic dashboard generation runs during iteration-closeout and feature-closeout, but a missing or failed dashboard artifact must not block lifecycle progression. The boundary must complete, record the warning, and leave an auditable follow-up path instead of silently pretending success. | `true` | FR-019 and the Iteration 001 retro both reject manual-reminder dependence, but they do not authorize turning dashboard generation into a new hard blocker. The artifact is required; blocking the lifecycle on its absence is not. | reviewer sign-off |
| `squad-routing-classifier-safety` | `interaction-safety` | `addressed` | `design-review` | `pending-post-implementation` | Positive examples must route: “show the current project status”, “where are we in this repo”, “summarize roadmap progress for this project”. Negative examples must not route: “what’s your status?”, “what is the reviewer status?”, “show the status of PR #125”. **Uncertain-case rule**: if repository/project-state intent is not explicit, stay on the normal conversational path rather than forcing the dashboard. | `true` | FR-030 is an alignment requirement, not a keyword land-grab. The conservative default prevents false-positive routing on generic status language. | reviewer sign-off |
| `grandfathering-for-historical-iterations` | `governance-compatibility` | `addressed` | `design-review` | `pending-post-implementation` | **Grandfathering rule**: every iteration and feature closeout completed before the first Feature 017 auto-generation rollout commit is exempt from missing-dashboard warnings. That grandfathered set includes all pre-Feature-017 iterations and Feature 017 Iteration 001. Warning expectations begin only after the rollout boundary exists. | `true` | FR-022 and NFR-006 require an explicit cutover. Without this rule, the validator mislabels historically valid boundaries as incomplete. | reviewer sign-off |
| `nfr-001-budget-preservation` | `performance` | `addressed` | `design-review` | `pending-post-implementation` | The implementation must preserve the `<= 1.5s on a 16-feature repo` budget by reusing a single aggregation/render pass per invocation when possible and by measuring the green tree after the closeout hooks and validator changes land. | `true` | Auto-invocation and validator work can accidentally double-scan the repository. NFR-001 remains an acceptance surface, not a stale Iteration 001 number. | reviewer sign-off |
| `documentation-consistency-with-implemented-behavior` | `documentation-accuracy` | `addressed` | `design-review` | `pending-post-implementation` | Help, README, dashboard guide, roadmap maintenance guide, FAQ, and routing guidance must match the shipped behavior exactly: canonical `specrew where`, alias `specrew status`, dedicated script entry point, automatic closeout generation, immutable snapshots, no top-level living dashboard, and `--team` still being a fallback. | `true` | Iteration 002 adds the main user-education surfaces for the feature. Any mismatch here turns documentation into a second drifting source of truth. | reviewer sign-off |
| `backward-compatibility-with-iter-1-dashboard` | `compatibility` | `addressed` | `design-review` | `pending-post-implementation` | Iteration 002 must stay additive to the Iteration 001 renderer: ad hoc `specrew where` / `specrew status` output, semantic sections, summary-line degradation, effective-status handling, and existing monochrome/compact behavior must not regress. | `true` | FR-019..FR-033 add lifecycle integration, docs, and validation around the dashboard. They do not reopen the Iteration 001 renderer contract. | reviewer sign-off |
| `test-coverage-for-iter-2-fr` | `verification` | `addressed` | `design-review` | `pending-post-implementation` | FR-032 coverage for Iteration 002 must include: healthy, sparse/fresh, malformed, and no-roadmap fixtures; auto-generated iteration `dashboard.md`; feature `closeout-dashboard.md`; immutability replay; validator grandfathering behavior; and warning-only drift/schema lanes. | `true` | The iteration closes only if the new behavior is proven through the real lifecycle paths, not inferred from unit tests or documentation alone. | reviewer sign-off |
| `poc-vs-production-statement` | `product-scope` | `addressed` | `design-review` | `pending-post-implementation` | The shipped narrative must say explicitly that the production dashboard improves on the proof of concept by adding structured roadmap input, lifecycle integration, user education, command-surface consistency, validator drift handling, and fixture-backed test coverage. | `false` | FR-033 allows evolution from the proof of concept but forbids calling a lightly polished prototype “done”. The upgrade path must stay explicit in docs and review evidence. | reviewer sign-off |
| `corpus-row-essence-vs-exhaustive-self-enforcement` | `handoff-discipline` | `addressed` | `retro-input` | `pending-post-implementation` | Dashboard-related docs, review packets, and future closeout handoffs must keep curated essence-first inspection targets instead of exhaustive mirror-pair and fixture-file enumeration. Use directory-level evidence plus diff stats when full enumeration is still needed. | `false` | Iteration 001 retro lesson 5 showed the corpus row is already shaping team behavior. Iteration 002 should reinforce that discipline rather than regress into exhaustive handoff noise. | reviewer sign-off |

## Pre-Implementation Planning Evidence

### Requirement Traceability

- **Closeout integration and artifact discipline**: FR-019..FR-023 via the planned iteration-closeout hook, feature-closeout hook, immutable snapshot notices, artifact immutability checks, mirrored extension updates, and boundary-discipline preservation.
- **Education, discovery, and routing**: FR-024..FR-030 via help output, README/user-guide/dashboard-guide updates, roadmap-maintenance guidance, FAQ/onboarding messaging, and explicit repository/project-status routing examples.
- **Validator, traps, tests, and production uplift**: FR-031..FR-033 via dashboard-specific warning rules, known-traps updates, fixture-backed coverage, repo validator replay, and explicit proof-of-concept uplift language.
- **Compatibility with the Iteration 001 renderer contract**: FR-042..FR-046 remain binding because Iteration 002 adds lifecycle and documentation surfaces around the same renderer and must not regress those semantics.

### Stack-Ready Analysis

| Stack Surface | Path | In Scope | Evidence |
| --- | --- | --- | --- |
| `cli-dispatch-and-rendering` | `scripts/specrew.ps1`, `scripts/specrew-where.ps1`, shared dashboard renderer logic | Yes | Iteration 002 must reuse the Iteration 001 renderer rather than fork it |
| `closeout-and-validator-integration` | `extensions/specrew-speckit/scripts/**`, `.specify/extensions/specrew-speckit/scripts/**`, validator surfaces | Yes | FR-019..FR-023 and FR-031 are primarily here |
| `dashboard-data-and-roadmap` | `.specrew/roadmap.yml`, canonical feature/iteration artifacts | Yes | FR-022, FR-031, and FR-042..FR-046 depend on truthful canonical data |
| `docs-and-discovery` | `README.md`, `docs/**`, help output, `.github/copilot-instructions.md` | Yes | FR-024..FR-030 and the FR-033 production-uplift statement live here |
| `test-fixtures-and-replay` | `tests/integration/**`, `tests/unit/**`, fixture repositories | Yes | FR-032 must prove both repository-state resilience and closeout replay behavior |

## Governance Validation Result

- **Command**: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`
- **Committed-tree result**: exit `0` after ~200 seconds; no WARN or FAIL lines on the pre-implementation gate tree
- **Truthful concern carry-forward**: an earlier ad hoc rerun surfaced three advisory dashboard warning themes (roadmap drift, missing `dashboard.md`, missing `closeout-dashboard.md`). Those themes remain recorded as hardening concerns because Iteration 002 implementation still needs explicit runtime handling for grandfathering, artifact generation, and warning-only behavior.
- **Interpretation**: Repo convention is satisfied. Governance validation is green before implementation starts, and the gate keeps the prior dashboard warning modes visible as implementation obligations rather than erasing them from the review story.

## Sign-Off Posture

**Decision**: **READY** — no blocker prevents implementation of the authorized Iteration 002 slice.

**Implementation Authorization Scope**: FR-019..FR-033 plus FR-042..FR-046 only.

**Must stay explicit during implementation**:

1. Automatic dashboard generation is required, but missing dashboard artifacts must not block lifecycle progression.
2. Squad routing stays conservative; ambiguous status requests do not auto-route.
3. Historical iterations are grandfathered through the rollout cutover, including Feature 017 Iteration 001.
4. NFR-001 must be re-measured on the green tree after closeout integration lands.
5. Documentation, review packets, and future handoffs must stay consistent with the implemented behavior and the essence-first corpus rule.

## Sign-Off Evidence

**Authority**: bundled hardening-gate review + implementation authorization requested by Alon Fliess for Feature 017 Iteration 002  
**Reviewed By**: Reviewer  
**Reviewed At**: 2026-05-16  
**Evidence Statement**: "The user has authorized a bundled hardening-gate-and-implementation-auth boundary for Feature 017 Iteration 002. Your scope in this step is ONLY the pre-implementation self-review and hardening-gate signoff surface needed before implementation proceeds. If you identify no blocking issue, say implementation may proceed under the recorded concerns. Do NOT start implementation yourself."

---

**Hardening-Gate Planning Status**: **SIGNED-OFF** — reviewer self-review complete; implementation may proceed under the recorded concerns and later runtime evidence obligations.
