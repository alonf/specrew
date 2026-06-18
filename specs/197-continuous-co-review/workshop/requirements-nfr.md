# Requirements and NFR Lens Workshop

## Lens

- **Lens ID**: `requirements-nfr`
- **Depth**: medium
- **Confirmation**: human-confirmed
- **Confirmation scope**: lens-question

## Decision Agenda

- Which NFRs are design drivers for Iteration 001?
- Which constraints are mandatory rather than preferences?
- Which requirements need a measurable threshold?
- Which requirements are unknown enough to require clarification?
- Which acceptance criteria prove the quality, not only the happy path?

## Agreed Requirements-NFR Direction

Iteration 001 treats deterministic failure handling, auditability, finding traceability, fix verification,
bounded review/fix convergence, compatibility with F-184 sibling work, least-privilege honesty, concurrency
safety, cost control, and maintainability/testability as the quality drivers for the first slice.

The review gate is not satisfied merely because a blackboard file exists or because no blocking finding is
currently listed. A checkpoint is safe to advance only when every blocking finding is either fixed with evidence,
explicitly rejected with rationale, or escalated to a human after the bounded review/fix loop is exhausted.

The review/fix loop is capped at two rounds for Iteration 001: the initial review plus one fix-verification
round. If the same blocking finding remains unresolved after that limit, checkpoint advancement stops and the
finding escalates to a human decision instead of continuing automatically.

## Quality Attribute Priorities

```text
+-----------------------------+----------+------------------------------------------------+
| Binding NFR                 | Threshold / acceptance evidence                  |
+-----------------------------+----------+------------------------------------------------+
| Deterministic failure       | Timeout, nonzero exit, empty output, invalid     |
| handling                    | JSON, malformed findings, or unknown blocking    |
|                             | disposition blocks advancement as structured     |
|                             | infrastructure failure or unsafe gate state.     |
+-----------------------------+----------+------------------------------------------------+
| Auditability                | Each review run records run id, checkpoint       |
|                             | baseline, diff summary/hash, request summary/    |
|                             | hash, findings, dispositions, and gate verdict.  |
+-----------------------------+----------+------------------------------------------------+
| Finding traceability        | Every finding has stable id, source run id,      |
|                             | design/spec reference, applicable file location, |
|                             | disposition, fix evidence, and resolution state. |
+-----------------------------+----------+------------------------------------------------+
| Fix verification            | A blocking finding is resolved only by changed   |
|                             | diff evidence, reviewer re-check evidence, or    |
|                             | explicit human escalation/defer rationale.       |
+-----------------------------+----------+------------------------------------------------+
| Review/fix convergence      | Maximum 2 rounds: initial review plus one fix    |
|                             | verification. If the same blocking finding       |
|                             | remains unresolved, stop and escalate to human.  |
+-----------------------------+----------+------------------------------------------------+
| Compatibility               | Iteration 001 stays new-file host-neutral and    |
|                             | avoids F-184-protected hook/provider/runtime/    |
|                             | refocus/shared governance surfaces.              |
+-----------------------------+----------+------------------------------------------------+
| Least-privilege honesty     | Reviewer is read-only by contract and receives   |
|                             | only an explicit review bundle; no V1 hard       |
|                             | filesystem/OS sandbox claim.                     |
+-----------------------------+----------+------------------------------------------------+
| Concurrency safety          | Unique run ids/workspaces, no bundle reuse, and  |
|                             | cleanup owned by ReviewRunWorkspaceManager.      |
+-----------------------------+----------+------------------------------------------------+
| Cost control                | Explicit provider/model config and user          |
|                             | authorization before paid or non-default review  |
|                             | process spawn.                                   |
+-----------------------------+----------+------------------------------------------------+
| Maintainability/testability | Stable schemas/adapters and standalone gate      |
|                             | validator evidence; no host integration needed   |
|                             | to test contract semantics.                      |
+-----------------------------+----------+------------------------------------------------+
```

## Binding Requirements-NFR Decisions

- Deterministic infrastructure failures and malformed reviewer results are unsafe gate states, not warnings.
- Audit evidence must trace from checkpoint baseline through run id, request summary/hash, findings,
  dispositions, and gate verdict.
- Findings must be traceable from reviewer output to fix evidence or explicit human escalation/defer rationale.
- Blocking findings require evidence-based resolution; text-only "fixed" markers are insufficient.
- Review/fix convergence is bounded to two rounds in Iteration 001.
- The first slice remains host-neutral and new-file-only relative to F-184-protected surfaces.
- Reviewer least privilege is represented honestly as policy plus review bundle only; hard sandboxing is deferred.
- Per-run workspaces and bundles are unique and cleanup-owned; bundles are not reused across runs.
- Paid or non-default reviewer provider/model spawning requires explicit configuration and user authorization.
- Stable schemas, provider adapter seams, and a standalone deterministic gate validator are required for
  maintainability and testability.

## Iteration 002 Send-Back Addendum: Reviewer Definition Quality Bar

### Send-Back Quality Agenda

- Should prompt completeness be a binding NFR, and which reviewer-definition fields must be asserted in the
  actual outbound host prompt?
- Should `ReviewRequest.v2` structured observability be binding, and which fields must schema/fixture evidence
  expose?
- How do deterministic fixture tests prove the prompt is complete instead of hiding an empty or skeletal prompt
  behind a successful fake `FindingsResult.v1`?
- How should review-only behavior, supported host read-only flags, isolated workspaces, and mutation detection
  be measured?
- How should the host-neutral injected-prompt path relate to non-authoritative native host mirrors?
- How should SC-012 manual validation and no-scope-creep constraints be made measurable for the send-back?

### Send-Back Quality Attribute Priorities

```text
+---------------------------+----------+----------------------------------------------------------+
| Quality / constraint      | Priority | Measurable acceptance target                             |
+---------------------------+----------+----------------------------------------------------------+
| Prompt completeness       | Binding  | Outbound host prompt contains Proposal 145 rubric,       |
|                           |          | design context content, exact diff, round number,        |
|                           |          | prior findings, visibility policy, and do-policy.        |
+---------------------------+----------+----------------------------------------------------------+
| Contract observability    | Binding  | ReviewRequest.v2 fixtures expose the same fields as      |
|                           |          | structured data; tests fail if fields are missing.       |
+---------------------------+----------+----------------------------------------------------------+
| Fixture cannot hide empty | Binding  | Fake/fixture adapter tests assert the actual prompt       |
| prompt                    |          | passed to the adapter, not just normalized result output. |
+---------------------------+----------+----------------------------------------------------------+
| Review-only behavior      | Binding  | Prompt/do-policy forbids modify/stage/commit; supported  |
|                           |          | host readonly flags are used where available.            |
+---------------------------+----------+----------------------------------------------------------+
| Mutation detection        | Binding  | Isolated workspace pre/post guard detects any reviewer    |
|                           |          | file mutation, records diff evidence, invalidates result, |
|                           |          | and discards workspace.                                  |
+---------------------------+----------+----------------------------------------------------------+
| Host neutrality           | Binding  | Same prompt-composition path feeds Claude, Codex,         |
|                           |          | Copilot, Cursor, Antigravity, and fixture adapters.      |
+---------------------------+----------+----------------------------------------------------------+
| Native host mirrors       | Important| code-review-agent.md is copied to managed host folders   |
|                           |          | for consistency, but tests prove runtime does not depend  |
|                           |          | on auto-loading those mirrors.                           |
+---------------------------+----------+----------------------------------------------------------+
| Manual SC-012 alignment   | Binding  | Manual runbook invokes the same injected-prompt path,     |
|                           |          | not a hand-written host prompt.                          |
+---------------------------+----------+----------------------------------------------------------+
| No dependency/scope creep | Binding  | No new dependencies; no live-host CI; no rung-1 hook;     |
|                           |          | no Proposal 139/196/181/194 implementation.              |
+---------------------------+----------+----------------------------------------------------------+
```

### Binding Send-Back Requirements-NFR Decisions

- Prompt completeness is binding. Every outbound reviewer prompt sent to any adapter must include the canonical
  `code-review-agent.md` content, Proposal 145 rubric phases, workshop-decision conformance expectations,
  claim/design trace checks, report-falsification checks, supplied design context content, exact diff/change-set
  content, `round_number`, `prior_findings`, visibility policy, do-policy, and an instruction to output only a
  `FindingsResult.v1` JSON object.
- Prompt-composition tests must inspect the actual prompt passed to the adapter. They must fail if the prompt is
  empty, skeletal, or missing the rubric marker, known design-context phrase, known diff phrase, round semantics,
  known prior blocking finding, visibility/do-policy text, or `FindingsResult.v1`-only output instruction.
- `ReviewRequest.v2` structured observability is binding. Fixtures and schema evidence must expose reviewer
  instruction metadata/content hash, `design_context.content`, `design_context.sources`, diff/change-set content,
  `round_number`, `prior_findings`, `visibility_policy`, and `do_policy`. `FindingsResult.v1` remains the only
  valid stdout output contract.
- Fake/fixture reviewer tests must prove the full path from request to composed prompt to adapter input to
  findings/gate output. A successful fake finding result is insufficient if the captured outbound prompt did not
  carry the reviewer definition and context.
- Review-only behavior is binding. The policy/request/prompt must forbid modifying, staging, committing,
  formatting, or repairing files; adapters must apply supported read-only or permission flags where available;
  unsupported host limitations must be represented as explicit capability facts rather than silent assumptions.
- Mutation detection is binding. Reviewer execution uses an isolated review workspace with pre/post baseline
  capture; any reviewer mutation is captured as diff evidence, classified as invalid review execution, and
  discarded with the workspace. The active feature worktree is never reverted as the recovery path.
- Host-neutral prompt injection is binding for Claude, Codex, Copilot, Cursor, Antigravity, and fixture adapters.
  Host adapters remain transport/read-only capability edges and do not own rubric wording, policy wording, round
  verification logic, or durable writes.
- Native host mirrors are useful but non-authoritative. The canonical `code-review-agent.md` should be copied to
  managed host folders for consistency, but runtime correctness depends on injected prompt content, not host
  auto-loading.
- Manual SC-012 validation must invoke the same injected-prompt reviewer path that automated fixtures exercise,
  using the planted design-violation fixture and expecting a parseable blocking finding that names the violated
  design decision.
- Scope exclusions remain binding: no new dependencies, no automated live cross-host CI, no rung-1/PostToolUse
  trigger execution, no Proposal 139 foundation, no Proposal 196 provenance, and no Proposal 181/194 live canary
  automation in this iteration.

### Done Interpretation

```text
A reviewer-definition run is acceptable only if:
  ReviewRequest.v2 contains the structured review inputs
  AND ReviewPromptComposer renders them into the outbound prompt
  AND an adapter receives that composed prompt
  AND the reviewer output is FindingsResult.v1 or a deterministic failure
  AND no mutation occurred in the isolated review workspace
```
