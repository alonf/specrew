# Product-Domain Workshop: Proposal 197 Continuous Co-Review

**Depth**: Standard  
**Context Scope**: feature_standalone  
**Confirmation**: human-confirmed / lens-question  
**Confirmed By**: Alon Fliess  
**Recorded At**: 2026-06-17T17:11:00Z

## Depth Rationale

Proposal 197 is a normal Specrew product feature with host-neutral behavior,
lifecycle trust implications, and active sibling-branch coordination risk. It is
not a brand-new product or regulated domain, so Deep discovery is not warranted,
but Light would miss the product risk around F-184 overlap and reviewer trust.

## Users, Customers, Operators, and Stakeholders

- **known**: Primary users are Specrew implementers, Spec Stewards, reviewers,
  and maintainers working through lifecycle checkpoints.
- **known**: Alon / maintainer is the chief architect and final reviewer.
- **assumed**: Downstream Specrew project teams benefit indirectly because fewer
  design violations reach late review.

## Pain, Job, and Current Workaround

- **known**: Proposal 145 review runs at `review-signoff`, after design drift and
  abstraction leaks are already expensive.
- **known**: AI coding agents may forget or deprioritize design rules mid-flow.
- **known**: Current mitigation is late structured review plus human review.
- **job**: Re-check checkpoint change-sets against the design contract while the
  fix is still cheap.

## Existing System and Context

- **known**: This is an extension to Specrew's existing Spec Kit / Squad
  lifecycle in the Specrew repository.
- **known**: First-iteration work must stay additive and avoid the F-184
  host-runtime, hook, provider, registry, refocus, and shared governance
  surfaces.
- **known**: The sibling worktree at
  `C:\Dev\183-stability-quality-bundle` is read-only context for this feature.
  It currently reports branch `184-full-antigravity-refocus` and identity state
  stopped at the iteration-closeout verdict, while iteration 002 planning covers
  persistent host instructions and bootstrap guard work.

## Constraints

- **known**: Run against this worktree's Specrew module; do not use the globally
  installed module as the implementation baseline.
- **known**: Never run `specrew update` in this repository.
- **known**: Use markdownlint before every commit.
- **known**: Main is PR-protected; feature close must go through PR.
- **known**: Do not update any code or documents in
  `C:\Dev\183-stability-quality-bundle`.
- **known**: Proposal 197 will need to merge with the F-184 branch later.

## Outcomes and Success Metrics

- **known**: Blocking design violations stop checkpoint advancement.
- **known**: Advisory and nit findings remain auditable but do not block.
- **known**: Blackboard records preserve finding, disposition, rationale, and
  escalation trail.
- **assumed**: First success should be measured through deterministic fixtures
  and validator behavior, not live hook integration.

## MVP, Non-Goals, and Vision

### MVP

- **known**: Iteration 001 delivers the host-neutral spine: reviewer contract,
  forced findings JSON schema, git-diff change-set, blackboard review-thread
  protocol, standalone blocking gate, orchestrator checkpoint loop trigger,
  headless-floor adapters, and rung 2b fresh-context reviewer.

### Non-Goals

- **known**: Do not implement rung 1 in Iteration 001.
- **known**: Do not implement PostToolUse hook triggers in Iteration 001.
- **known**: Do not implement the Proposal 139 heavy foundation in Iteration 001.
- **known**: Do not edit F-184-protected host-runtime, hook, provider, registry,
  refocus, or shared governance surfaces in Iteration 001.

### Vision

- **assumed**: The stable contract should allow later graduation to richer
  host-native and cross-model review without changing the blackboard/gate spine.

## Alternatives and Differentiation

- **known**: The main alternative is relying on late Proposal 145 review only.
- **known**: Another alternative is host-specific hook behavior, rejected for
  this slice because host neutrality and a stable contract come first.
- **assumed**: The feature must beat the current workaround on earlier detection,
  auditability, and host neutrality.

## Adoption, Rollout, and Change Impact

- **known**: Dogfood rung 2b in Specrew first.
- **known**: Proposal 145 remains the final aggregate backstop.
- **known**: Re-check / merge with F-184 before integrating anything that depends
  on rewritten host-runtime or provider surfaces.

## Follow-Up Research

None recorded for product-domain. The F-184 branch relationship is a known
coordination and merge constraint, not an unknown research gap.
