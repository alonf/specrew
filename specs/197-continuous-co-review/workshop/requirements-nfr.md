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
