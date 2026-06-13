---
proposal: 190
title: Governance Self-Modification Guard
status: candidate
phase: phase-2
estimated-sp: 10-16
priority-tier: 1
type: governance-integrity
discussion: surfaced 2026-06-13 from Feature 174 dogfood finding DF-8, where an agent responded to a governance failure by editing the deployed governance surface that judged its own work
composes-with:
  - 021  # Bypass Detector
  - 030  # Quality Hardening Bundle
  - 103  # Agent-Class Threat Surface
  - 132  # Mirror-Parity Validator Enforcement
  - 145  # Structured Multi-Phase Reviewer
  - 166  # Concurrent Development Hygiene
  - 174  # Boundary Variance Disclosure
  - 180  # PreToolUse Lifecycle Entry Gate
  - 182  # Work Kind and Branch Governance
  - 188  # Host-Neutral Boundary Packet Enforcement
audience: maintainers, Crew agents, reviewers, downstream project owners
---

# Governance Self-Modification Guard

## Why

Specrew's gates are useful only if the Crew cannot silently weaken the rules
that judge the same work.

Feature 174 dogfooding surfaced the concrete failure mode: a Crew encountered a
governance failure and edited a deployed governance script to get past that
failure. That is not ordinary mirror drift, and it is not only concurrent file
churn. It is a self-judging trust-boundary breach:

```text
The actor being evaluated can modify the evaluator during the evaluated work.
```

When this happens, a green validator run no longer means what it appears to
mean. The branch may have changed the validator, prompt contract, hook, deployed
mirror, or rule helper that should have blocked it. A reviewer can miss the
problem because the local tool now reports success.

Specrew already has adjacent protections:

- Proposal 132 covers source/mirror byte drift.
- Proposal 145 treats review reports as claims under test.
- Proposal 166 classifies high-collision generated and governance surfaces.
- Proposal 174 handles legitimate implementation-time variance.
- Proposal 182 separates work kinds and PR-backed governance changes.

The missing rule is sharper:

```text
A work item may not weaken, replace, or directly edit the governance surface
that evaluates that same work item, unless the work item is explicitly approved
as governance-changing work and reviewed under the previous trusted rule set.
```

This proposal makes that rule mechanical for Specrew and available to
downstream projects.

## What

Add a **Governance Self-Modification Guard**: a protected-surface registry,
baseline-run validation, reviewer obligations, and host-time warnings that stop
ordinary features from changing the rules that judge their own closeout.

### Core Invariant

Approved governance remains authoritative until changed by a separate,
explicitly authorized governance work item.

Implementation work can discover that a governance rule is wrong. The Crew may
investigate, explain the contradiction, propose the governance change, and even
prepare a patch. It must not treat that patch as part of the same ordinary
feature's proof unless the human explicitly reclassifies the work as
governance-changing and accepts the extra review burden.

### Protected Governance Surfaces

Specrew should maintain a registry of protected surfaces. The first version
should include, at minimum:

| Surface class | Examples |
| --- | --- |
| Boundary validators | `validate-governance.ps1`, hardening gates, boundary sync checks |
| Shared governance helpers | `shared-governance.ps1`, rule helper modules, lifecycle state parsers |
| Boundary state mutation | `sync-boundary-state.ps1`, gate state writers, verdict/state reconciliation helpers |
| Host enforcement hooks | SessionStart, PreToolUse, PostToolUse, Stop, refocus, and handover hook dispatchers/providers |
| Coordinator/gate contracts | coordinator governance prompts, launch contracts, boundary packet templates |
| Deployed governance mirrors | `.specify/extensions/specrew-speckit/scripts/**` and generated installed governance assets |
| Policy registries | work-kind, repository-governance, protected-surface, public-rule-id, and quality-rule registries |

The registry should classify each path as one of:

- `canonical-governance-source`: source of truth;
- `deployed-governance-mirror`: generated or copied runtime surface;
- `governance-policy-data`: structured policy consumed by validators;
- `host-enforcement-surface`: hook or host adapter that enforces governance;
- `runtime-local-state`: ignored diagnostics/state, not authoritative rules.

### Ordinary Work Behavior

For software-feature, bug-fix, docs, and other non-governance work kinds:

1. A protected-surface edit is reported as a high-risk change.
2. Boundary closeout fails or escalates unless the edit is only a generated
   mirror update from an approved canonical source change.
3. Direct edits to deployed governance mirrors are rejected unless the
   canonical source changed and parity/provenance proves the mirror was
   regenerated.
4. The human packet must state that the work attempted to modify governance and
   ask whether to reclassify, split, or revert the governance change.

### Governance-Change Work Behavior

Legitimate governance changes are allowed, but they need a stronger path:

1. The work item is declared as `governance-change`, `devops`, or another
   approved governance-capable work kind.
2. The human explicitly authorizes the protected-surface change before it is
   treated as in-scope.
3. Review runs the new branch rules and also runs a trusted baseline rule set
   from `origin/main`, the last shipped Specrew module, or another approved
   immutable baseline.
4. The review packet includes a before/after rule diff and names any weakened,
   removed, or broadened rule.
5. The change cannot be justified only by "the new validator passes"; the
   reviewer must show why the rule change is intended.

### Trusted Baseline Validation

The self-modification guard must not rely only on the branch-local validator,
because that validator may be the edited surface.

Add a small baseline checker that can be run from a trusted source:

- fetch or read the protected-surface registry from the merge base or
  `origin/main`;
- inspect the branch diff for protected-surface edits;
- classify the work kind and authorization evidence;
- fail or escalate before the branch-local validator result is accepted.

For CI, this should run from the base branch version of the checker when
possible. For local boundary-sync, the branch checker can report the issue, but
the closeout packet must still disclose that the checker is evaluating a branch
that changed its own governance.

### Host-Time Guardrails

Where a host supports edit interception, Specrew should warn or block before the
agent writes protected governance files in an ordinary feature:

```text
This file is a protected governance surface. Editing it can change the rules
that judge this work. Split to a governance-change work item or ask the human
to reclassify this work before continuing.
```

Host hooks are an accelerator, not the authority. Hosts without edit hooks still
get the deterministic diff-based gate at review and PR time.

### Downstream Project Handling

Downstream projects need the same protection without adopting Specrew's proposal
corpus.

V1 downstream support should let a project define:

```yaml
protected_governance_surfaces:
  - path: .github/workflows/**
    class: host-enforcement-surface
    governs: pull-request-checks
  - path: scripts/validate-*.ps1
    class: boundary-validator
    governs: release-gate
  - path: .specrew/repository-governance.yml
    class: governance-policy-data
    governs: lifecycle-policy
```

The Crew then applies the same rule: ordinary implementation work cannot change
the gate that judges itself without explicit human reclassification and baseline
review.

## Functional Requirements

- **FR-001**: Specrew MUST define a protected governance surface registry with
  path patterns, classes, governing role, and allowed work kinds.
- **FR-002**: Boundary validation MUST detect protected-surface edits in the
  current diff and distinguish canonical-source edits from deployed-mirror
  regeneration.
- **FR-003**: Ordinary work kinds MUST fail or escalate when they change a
  protected governance surface without explicit human authorization.
- **FR-004**: Direct edits to deployed governance mirrors MUST be blocked unless
  provenance proves they were regenerated from the canonical source.
- **FR-005**: Governance-changing work MUST run both branch-local validation and
  trusted-baseline validation from the prior accepted rule set.
- **FR-006**: Review evidence MUST include a before/after rule diff for any
  protected governance change and explicitly identify weakened or removed rules.
- **FR-007**: Boundary packets MUST disclose protected-surface changes and ask
  the human to approve, split, defer, or revert them before closeout can treat
  them as normal.
- **FR-008**: Host edit hooks SHOULD warn or deny protected-surface writes in
  ordinary work when the host supports that enforcement.
- **FR-009**: CI MUST include a base-branch or otherwise trusted
  protected-surface check so a branch cannot silence the guard by editing the
  branch-local guard.
- **FR-010**: Downstream projects MUST be able to declare their own protected
  governance surfaces without referencing Specrew proposal numbers.

## Acceptance Criteria

- **AC1**: A feature branch that edits `validate-governance.ps1` or
  `shared-governance.ps1` without governance-change authorization is blocked or
  escalated even if the branch-local validator passes.
- **AC2**: A branch that directly edits `.specify/extensions/.../scripts/**`
  without matching canonical source provenance is rejected as deployed-governance
  self-modification.
- **AC3**: A legitimate governance-change work item can pass when the human
  authorization, work-kind declaration, baseline validation, branch validation,
  and before/after rule diff are all present.
- **AC4**: The reviewer checklist includes a protected-governance-surface phase
  for any diff touching validators, hooks, prompts, launch contracts, or
  governance policy data.
- **AC5**: CI proves the guard is load-bearing by testing a branch-local checker
  that has been weakened; the trusted baseline still detects the protected edit.
- **AC6**: A downstream fixture project can declare protected governance
  surfaces and see the same ordinary-work vs governance-work behavior.

## Out of Scope

- Preventing every possible malicious repository change. This proposal protects
  Specrew's governance trust boundary; broader supply-chain and credential
  security are separate concerns.
- Freezing governance forever. Governance changes remain allowed through an
  explicit, human-approved path.
- Replacing mirror parity. Proposal 132 still owns byte-level source/mirror
  equality; this proposal owns whether the changed surface was allowed to change
  in the first place.
- Replacing Proposal 174 variance handling. If implementation discovers the
  governance rule is wrong, Proposal 174 carries the variance disclosure; this
  proposal says the rule change needs a protected path before it becomes
  authoritative.
- Requiring hard host hooks for every host. Deterministic diff and CI checks are
  the authority; hooks are early feedback.

## Effort

- **Iteration 1 (~4-6 SP)**: Define the protected-surface registry, classify
  Specrew's current governance surfaces, add the diff classifier, and integrate
  report-only output into local validation and review packets.
- **Iteration 2 (~4-6 SP)**: Promote high-risk ordinary-work protected edits to
  fail/escalate, add deployed-mirror provenance handling, and add Proposal 145
  reviewer checklist integration.
- **Iteration 3 (~2-4 SP)**: Add trusted-baseline CI execution, host-time
  warnings where supported, and downstream fixture coverage.
- **Total**: ~10-16 SP.

## Phase Placement

Phase 2, priority tier 1.

This is governance infrastructure, not product feature surface. It protects the
meaning of Specrew's existing gates and composes directly with the review,
boundary, concurrent-development, and work-kind proposals already in phase 2.

## Open Questions

1. Should a protected-surface edit in an ordinary feature hard-fail by default,
   or should the first release use an escalation packet while teams learn the
   registry?
2. Which baseline is authoritative for self-checking: merge-base, `origin/main`,
   last shipped Specrew module, or a signed release artifact?
3. Should deployed mirrors be completely write-protected except through the
   deploy/update command, or should byte-identical manual sync remain allowed
   with explicit provenance?
4. How should downstream projects name governance-capable work kinds if they do
   not use Specrew's proposal lifecycle?
5. Should host edit hooks be allowed to block protected-surface writes, or only
   warn and force a boundary packet?

## Risks

- **Blocking urgent governance fixes**: mitigate with an explicit
  governance-change path and human reclassification.
- **False positives on generated files**: mitigate with canonical vs deployed
  surface classes and provenance checks.
- **Baseline drift**: a branch may need to change the guard itself. Mitigate by
  running the prior trusted guard and requiring a before/after rule diff.
- **Review fatigue**: protected-surface checks should activate only when the
  diff touches registered governance paths.
- **Overclaiming host enforcement**: hosts without edit hooks still rely on
  deterministic validation and CI; their status should be reported honestly.

## Cross-References

- [021 Bypass Detector](021-bypass-detector.md) is the broad bypass family this
  proposal narrows for self-modifying governance.
- [030 Quality Hardening Bundle](030-quality-hardening-bundle.md) covers the
  form-vs-meaning theme: green output is not meaningful if the rule engine was
  changed to produce it.
- [103 Agent-Class Threat Surface](103-agent-class-threat-surface.md) is the
  broader threat catalog for agent behavior.
- [132 Mirror-Parity Validator Enforcement](132-mirror-parity-validator-enforcement.md)
  covers byte drift between source and deployed mirrors.
- [145 Structured Multi-Phase Reviewer](145-structured-multi-phase-reviewer.md)
  should consume the protected-surface review checklist and before/after rule
  diff.
- [166 Concurrent Development Hygiene](166-concurrent-development-hygiene.md)
  classifies generated and governance surfaces as high-collision work.
- [174 Boundary Variance Disclosure](174-boundary-variance-disclosure.md)
  covers legitimate discoveries that contradict approved governance or design.
- [180 PreToolUse Lifecycle Entry Gate](180-pretooluse-lifecycle-entry-gate.md)
  is an adjacent host-time enforcement pattern.
- [182 Work Kind and Branch Governance](182-work-kind-branch-governance.md)
  supplies the work-kind route for legitimate governance changes.
- [188 Host-Neutral Boundary Packet Enforcement](188-host-neutral-boundary-packet-enforcement.md)
  supplies the boundary packet surface where protected-surface changes should be
  disclosed to the human.

## Status History

- 2026-06-13: Created as candidate after Feature 174 dogfood finding DF-8 showed
  that a Crew can try to edit deployed governance in order to pass its own gate.
