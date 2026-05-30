---
proposal: 145
title: Structured Multi-Phase Reviewer Skill (7-Phase Checklist + FR×Phase Coverage Matrix + Static Validator)
status: candidate
phase: phase-2
estimated-sp: 30-45
priority-tier: 1
discussion: surfaced 2026-05-30 after F-049 + F-050 dogfooding revealed 8+ "review missed X" instances despite review-signoff verdicts of accepted; pattern is structural (single-pass narrative reviewer with no per-dimension coverage enforcement), not exhortation-fixable
---

# Structured Multi-Phase Reviewer Skill (7-Phase Checklist + FR×Phase Coverage Matrix + Static Validator)

## Why

Reviews keep missing things. The empirical record from this session (~10 days, F-046 through F-050) shows the review-signoff verdict is currently a single-pass narrative assertion that does not structurally guarantee any specific dimension has been evaluated. Concrete instances where review-signoff said `accepted` but real gaps existed:

1. **Shape 8 (FileList directional blind spot) — F-049 → v0.28.0-beta.1.** Phase 2 FileList integrity check was built to prevent v0.27.3-class incidents but only checked one direction (declared files exist on disk), not the inverse (every referenced source file is declared). v0.28.0-beta.1 shipped the exact omission class (`scripts/internal/user-profile.ps1`) F-049 was designed to prevent → runtime crash on first `specrew start`. The gate was reviewed and signed off without anyone asking *"does this gate cover the full failure-mode space its spec claims?"*

2. **Coverage-evidence drift — F-050 iter-002 (2026-05-30).** `coverage-evidence.md` Tests Run table listed framework `reviewer.test_commands` (quality-profile-foundation, mechanical-findings-contract, etc.) but NOT the iter-002-added cursor test files. The deliverable tests were never explicitly recorded as executed at review-boundary. Caught by cross-reviewer code-read; would have passed any pattern-grep check.

3. **State-truth gaps — F-050 iter-002.** `start-context.json` and `feature.json` had empty `iteration_path`, `last_authorized_boundary`, `pending_next_boundary`, `current_iteration` fields. Review passed self-review without anyone validating session-state consistency.

4. **Never-pushed branch — F-050 (2026-05-30).** Entire `050-cursor-host-support` branch was local-only across iter-001 + iter-002 (10+ commits) when discovered. Same `[[project-codex-branch-push-discipline-gap-2026-05-26]]` pattern from F-046/F-048 recurring. Review did not check `git rev-parse HEAD == origin/<branch>`.

5. **Synthetic-fixture stand-in (Shape 6) — PlanningPoC iter-006 (2026-05-27).** 60-sec SLA test was a no-op against synthetic 4-line in-code fixture with English layer names while spec required real Hebrew customer DWGs. Code comment at `UploadRunFlowTests.cs:59-62` openly declared the gap. Across 4 prior iterations no review caught it.

6. **Reviewer-approves-uncommitted-state (Shape 5) — PlanningPoC iter-004 (2026-05-27).** Reviewer issued `accepted` verdict citing committed-hash provenance; 7 production code files cited as evidence were never committed to any branch. Caught by maintainer via `git status` by accident.

7. **Cross-reviewer Instance 11/13/17/18 — F-049 (2026-05-28/29).** I (Claude cross-reviewer) approved things based on metadata/pattern checks without reading content; Codex caught 8 substantive issues across the iteration. Lesson explicitly captured: pattern-grep ≠ verification.

8. **F-049 iter-5 under-coverage — producer/consumer meta-rule (2026-05-29).** Two gaps shipped that review-signoff missed: T009 reviewer-only inline content + first-run prompt hard-coded interactive→CI hang. Emerging meta-rule: producer-side changes need consumer-side demonstration tests at review-signoff.

### The structural gap

Reviews today depend on narrative assertions about quality dimensions, not enforced per-dimension evaluation evidence. Even with `[[proposal-140-reviewer-instruction-surface]]` (project-local review playbook) and `[[proposal-102-cross-model-independent-reviewer]]` (independent reviewer) in flight, the underlying problem is that a reviewer can write `**Overall Verdict**: accepted` without having structurally proven that every relevant dimension (functional / non-functional / code quality / test coverage / system safety / branch hygiene / context-load) was checked against every in-scope FR/SC.

The dimensions a competent reviewer needs to evaluate are large (>20 distinct concerns), specialized (security ≠ performance ≠ accessibility ≠ test isolation ≠ dependency intent), and easy to forget in a single-pass review. Single-agent narrative review is structurally bounded — too many dimensions for one agent to evaluate well in one pass, no enforcement that any specific dimension was actually evaluated.

## What — 7-Phase Structured Reviewer

Each phase has a focused scope, dedicated check list, and per-phase verdict (`pass | rework | reject | n/a + reason`). Phases compose into a machine-readable matrix output validated by a static coverage rule.

### Phase 0 — Context load (before-review surface)

Reviewer skill loads:

- Feature spec (FRs + SCs + acceptance scenarios)
- Iteration plan (tasks + traceability)
- Prior iteration retros + drift logs
- Code-map for the iteration's diff
- Data structures + flows referenced in spec/plan
- Prior boundary commits + their evidence pointers
- Existing reviewer-instructions.md playbook (Proposal 140 surface)

Output: context-pack handed to subsequent phase agents. Memoizable per Proposal 086 Pillar 1.

### Phase 1 — Branch hygiene

Checks:

- Branch pushed to origin? `git rev-parse HEAD == git rev-parse origin/<branch>`?
- Working tree clean OR every dirty file explicitly classified (iter scope vs out-of-scope)?
- Main divergence + conflict topology (does main need to be merged in before next iter)?
- Shape 5 audit: every file cited as evidence in review.md is actually committed (not working-tree-only)
- Boundary commit cadence honored (Proposal 082)
- Upstream parity check

### Phase 2 — Functional correctness

Checks:

- Logic correctness (manual trace + test trace, no auto-pass on test-green alone)
- Error handling (every throw point has a handler OR explicit propagation rationale)
- Edge cases (empty, null, max, concurrent, partial-failure)
- Side effects + system state on failure
- Concurrency + race conditions
- Data integrity (transactional boundaries, atomicity)
- Idempotency (for distributed / retry paths)

### Phase 3 — Non-functional requirements

Checks:

- Security: input validation, secrets handling, injection vectors, authn/authz, sensitive-data redaction in logs
- Logging: every error path logged, structured fields, PII discipline
- Observability: metrics + traces (superset of logging) + audit trail
- Performance: hot-path complexity, allocations, I/O patterns
- Scalability: large-input behavior, resource ceilings
- Cost: cloud spend, AI token usage (per-iteration cost.yml per Proposal 070)
- Accessibility: UI keyboard nav, ARIA, contrast (UI features only)
- i18n + encoding: UTF-8 / RTL / non-Latin (Hebrew filename incident lesson from PlanningPoC)
- Operability: rollback path, feature flags, kill-switch

### Phase 4 — Code quality

Checks:

- Style + linter clean (markdownlint, PSScriptAnalyzer, language-specific)
- SOLID (single responsibility, open/closed, dependency inversion, etc.)
- DRY violations
- DTOs / type discipline at boundaries (no leaking internals)
- Clean code: naming, cognitive complexity, magic numbers, file organization
- Dependency intent (license, cost, alternatives, reversibility) per `[[project-plan-time-dependency-intent-proposal-candidate-2026-05-27]]`
- No dead code / commented-out blocks
- Comment-vs-comment-rot discipline per `[[proposal-074-code-commentary-standards]]`

### Phase 5 — Test coverage + integrity

Checks:

- Coverage breadth: every FR has at least one test
- Test isolation: no shared state, deterministic
- Fixture realism (Shape 6 check): synthetic stand-in vs real anchor dataset
- Skip-guard discipline + provenance: what runs deterministically vs only on dev machine
- Producer/consumer demonstration: new producer code has consumer-side demo test (F-049 iter-005 meta-rule)
- Gate completeness (Shape 8): does the gate cover what its spec CLAIMS, not just exist? Inverse-direction checks?
- Guardrails: explicit assertions on invariants
- Tests-actually-run-at-review evidence (closes coverage-evidence drift from F-050 iter-002)

### Phase 6 — System safety + ops

Checks:

- Failure modes catalogued + tested
- Rollback path documented + reversible
- Backward compatibility: API contract, breaking-change analysis
- Deprecation discipline: timelines + migration notes
- Compliance: privacy, retention, regulatory
- Audit trail: who/when/what
- Multi-developer collision surface per `[[project-multi-dev-constraint-2026-05-27]]`

### Phase 7 — Output synthesis

Machine-readable `review-report.yml` augmenting human-readable `review.md`:

```yaml
matrix:
  - requirement: FR-005
    phases:
      phase_0: { applicable: yes, evidence: [<paths>] }
      phase_1: { applicable: yes, finding: clean }
      phase_2: { applicable: yes, finding: clean, evidence_ref: tests/integration/host-cursor.tests.ps1 }
      phase_3: { applicable: no, reason: "no NFR aspect" }
      phase_4: { applicable: yes, finding: clean }
      phase_5: { applicable: yes, finding: skip-guard-provenance-documented, severity: info }
      phase_6: { applicable: no, reason: "no ops impact" }
verdict:
  per_phase: { phase_0: pass, phase_1: pass, phase_2: pass, phase_3: n/a, phase_4: pass, phase_5: pass, phase_6: n/a }
  overall: APPROVE for review-signoff
```

Verdict aggregation rule:

- Any phase = `reject` → overall `REJECT`
- Any phase = `rework` → overall `REWORK`
- All applicable phases = `pass` → overall `APPROVE for review-signoff` (per `[[feedback-verdict-boundary-naming-2026-05-22]]`)
- Phases marked `n/a` require a populated `reason` field (static validator enforces this)

## Architecture (deliverable shape)

- Invocable Reviewer skill at `extensions/specrew-speckit/squad-templates/skills/specrew-review-structured/SKILL.md` deployed per-host (`.claude/skills/`, `.github/skills/`, etc. per Proposal 058)
- Each phase invoked as a focused sub-agent (per `[[proposal-139-multi-agent-subagent-orchestration]]` / F-051)
- Without F-051: sequential single-agent phase invocation (lower fidelity but functional)
- Output: `review-report.yml` machine-readable + traceable; `review.md` human prose synthesizing the matrix
- Static coverage validator: rule in `validate-governance.ps1` that fails the review-signoff boundary if any FR has phase coverage gaps without explicit `n/a + reason`
- Per-phase memoization (Proposal 086 Pillar 1) — context-load is the most expensive phase; cache per-iteration

## Composition map

- `[[proposal-140-reviewer-instruction-surface]]` — runtime realization of the Per-Boundary Checklist Matrix; 145 makes 140's playbook structurally enforceable
- `[[proposal-102-cross-model-independent-reviewer]]` — different reviewer models per phase (specialty per phase) — Phase 2 functional review could use one model, Phase 3 security review another
- `[[proposal-139-multi-agent-subagent-orchestration]]` (F-051) — runtime substrate for multi-agent dispatch
- `[[proposal-086-validation-pipeline-performance-bundle]]` — Pillar 1 memoization applies per-phase
- `[[proposal-021-bypass-detector]]` — Phase 5 gate-completeness check is structural realization of the bypass-detector concept
- `[[proposal-074-code-commentary-standards]]` — Phase 4 code-quality references the commentary standards
- `[[proposal-070-token-economy-mvp]]` — Phase 3 cost check references the per-iteration cost.yml
- `[[proposal-142-state-truth-integrity-validator]]` — Phase 1 state-truth check composes with 142's validator rule
- `[[project-iter5-undercoverage-producer-consumer-2026-05-29]]` — formalized as Phase 5 sub-check
- `[[project-shape8-filelist-directional-blindspot-2026-05-30]]` — formalized as Phase 5 gate-completeness sub-check
- `[[project-multi-dev-constraint-2026-05-27]]` — Phase 6 collision-class checks
- `docs/methodology/lifecycle-discipline.md` Shape Catalog — Phase 5 references this for each Shape's check (Shape 5 working-tree → Phase 1; Shape 6 synthetic fixture → Phase 5; Shape 8 directional → Phase 5)

## Sizing + sequencing

- ~30-45 SP, 3-iteration decomposition:
  - **Iter 1 (~10-15 SP):** core skill scaffold + Phase 0-2 (context load + branch hygiene + functional correctness) + skeleton matrix output
  - **Iter 2 (~10-15 SP):** Phase 3-5 (NFR + code quality + test coverage + integrity)
  - **Iter 3 (~10-15 SP):** Phase 6-7 + static coverage validator + integration with existing review.md + host deployment
- Natural slot: F-053 or replaces F-052 (Design Alternatives Gate per the post-F-049 sequencing); user decides at sequencing review whether to substitute
- Prerequisite: F-051 multi-agent subagent orchestration (Proposal 139) for multi-agent dispatch; without it, sequential single-agent phase invocation is functional but lower fidelity

## Open questions for proposal-to-spec conversion

- Per-phase reviewer model selection: always same model, or specialty per phase (composing with Proposal 102)?
- Phase ordering enforcement: must run in order, or parallel where independent (e.g., Phase 3 + Phase 4 are independent)?
- Cache strategy for context-load: per-iteration vs per-boundary?
- Threshold tuning: what severity level blocks vs. warns at each phase?
- Integration with existing `review.md` format: does the structured report SUPERSEDE or AUGMENT? Recommendation: augment for migration safety, propose supersede as a follow-up after empirical adoption.
- Backward compatibility for reviewers/Crews that don't have the skill installed: fall back to current narrative review with a soft warning?
- Should the static coverage validator hard-block boundary advancement, or warn? Recommendation: warn during adoption period, hard-block after 3+ features ship through it.

## Open work items (deferred to spec)

- Define the canonical phase-checklist content for each of the 7 phases (this proposal sketches dimensions; the spec defines the exact checks)
- Define the `review-report.yml` JSON Schema for validator-side enforcement
- Define the per-phase agent charter (charter snippet for each phase agent, similar to existing role charters)
- Decide on the host-deployment shape for the invocable skill (Proposal 058 SDK alignment)
- Backfill strategy: do we re-run structured review on closed iterations as a one-shot quality audit?

## Risks

- **Reviewer fatigue / overhead:** 7 phases × per-phase agent invocation is heavier than current single-pass review. Mitigate via memoization (Proposal 086) + n/a-with-reason support + phase-skip when applicability is unambiguous.
- **Phase-agent disagreement:** multi-agent dispatch may produce conflicting verdicts. Mitigate via verdict aggregation rule (defined above) + escalation to human at conflict.
- **Static validator false-positives during adoption:** rules may flag legitimate `n/a` patterns. Mitigate via warn-then-block adoption phasing.
- **Skill installation drift across hosts:** the structured skill needs deployment in `.claude/skills/`, `.github/skills/`, etc. — risk of host drift. Mitigate via Proposal 058 SDK + Proposal 132 mirror-parity validator.
