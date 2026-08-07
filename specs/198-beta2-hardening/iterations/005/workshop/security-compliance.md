# Security-compliance reassessment

**Status**: complete
**Iteration**: 005

## Confirmed threat model

The reviewer is trusted but fallible. The design protects against mistakes, prompt confusion, accidental origin access, stale or malformed results, and runaway processes. It does not attempt to withstand a malicious local process with all permissions of the user's OS identity.

The security posture must remain simple and cost-conscious because each review spends human time, provider time, and model tokens. Hardened containers, VMs, network jails, restricted operating-system identities, and equivalent high-complexity isolation are outside the current slice.

## Trust boundaries

```text
TRUSTED CONTROL PLANE
  Human authorization
  Campaign/Run repositories
  Snapshot + workspace preparation
       |
=======|================================================
       v
DISPOSABLE REVIEWER ZONE
  External workspace
  Reviewer CLI + child processes
  Controlled environment and runtime
       |
       | untrusted machine result + Markdown
=======|================================================
       v
VALIDATION BOUNDARY
  schema + run identity + target identity + currentness
```

## Agreed origin-integrity direction

- The reviewer never uses the origin repository as its working directory.
- The review target is an immutable Git tree identity or equivalent synthetic tree identity when uncommitted content is included.
- Before reviewer execution, capture a lightweight origin-integrity baseline covering the current commit/tree identity and the working/index/untracked state relevant to protected project content.
- After reviewer execution, compare the origin with that baseline.
- An unchanged commit ID alone is insufficient because tracked, staged, or untracked content can change without a commit.
- Only explicitly declared Specrew control-plane writes are excluded from the protected-content comparison; any other origin delta is a visible containment violation and the result is non-gateable.
- The physical fingerprint algorithm and allowed-write manifest remain data-storage and security implementation decisions; the goal is deterministic protection without an expensive full security sandbox.

## Confirmed simple integrity algorithm

- Capture the origin HEAD identity and canonical reviewed-state tree digest immediately before reviewer launch.
- Materialize and bind the reviewer target to that same reviewed-state tree digest.
- Recompute HEAD and the canonical reviewed-state digest after the controlled reviewer process tree terminates.
- Equal pre/post identities establish exact currentness; changed identities yield `snapshot-moved` and never silently invalidate otherwise useful findings.
- A changed origin cannot be attributed to the reviewer because the human or another agent may have continued working.
- A strong observation that a reviewer process executed from or entered the origin is a containment violation and rejects the result independently of digest equality.
- Reuse the existing content-addressed reviewed-state algorithm rather than introduce another whole-repository fingerprint.

## Confirmed currentness and relevance semantics

Snapshot movement does not make a review irrelevant. It changes what the review can prove.

```text
reviewed snapshot == current snapshot
  -> currentness: exact
  -> validated result may be gateable

reviewed snapshot != current snapshot
  -> currentness: snapshot-moved
  -> result cannot approve or freshly block the current snapshot
  -> findings remain visible with original severity
  -> findings seed the next incremental re-review
```

For a finding with a precise path, identical reviewed/current blob identity yields `likely-still-relevant`; a changed blob yields `needs-re-evaluation`. A finding without a precise target is `relevance-unassessed`. These hints help the implementer fix likely-relevant findings and reduce the next review's finding count, but they never independently grant gate authority.

The implementer-facing message names both snapshot identities, states that the review does not approve the current snapshot, summarizes how many paths changed, and explains how the preserved findings feed re-review.

## Cost controls carried into the security design

- Perform cheap preflight, target identity, workspace, harness, and contract validation before provider invocation.
- Deduplicate identical target reviews and prevent overlapping runs for the same campaign lineage.
- Reuse digest-bound evidence rather than asking the reviewer to repeat known verification.
- Prefer incremental review from the last accepted snapshot while preserving enough context for correctness.
- Apply explicit time, output, token/provider, and autonomous-round allowances.
- Keep the authoritative result structured so malformed output fails once rather than causing parsing/retry loops.

## Confirmed environment and secret posture

The reviewer is a trusted component. Stable reviewer execution has priority over maximal environment isolation; least exposure is applied only to the extent that it preserves conformance-proven harness behavior.

```text
parent environment
       |
       v
harness-specific stable environment profile
  + minimal OS/runtime baseline
  + required provider authentication/configuration
  + workspace, run identity, and result contract
  + explicit Specrew-disable settings
       |
       v
reviewer process and children
```

- Environment inheritance is explicit rather than wholesale.
- Every included variable or configuration input is justified by harness conformance or runtime necessity.
- A required existing harness configuration directory may remain accessible; creating isolated per-run homes is not required in the current trusted-but-fallible model.
- Sanitization must not break authentication, configuration discovery, tool execution, or known-stable reviewer behavior.
- Provider authentication is an accepted runtime exposure but never enters prompts, results, logs, or persisted output.
- Other ambient credentials are absent unless explicitly required by a declared review command.
- Prompts travel through stdin or a bounded temporary file rather than process-list-visible command arguments where the harness supports it.
- Secret/credential files are excluded from the reviewer snapshot.
- Raw reviewer output remains private by default; audit records contain identities, digests, status, timing, and bounded metadata rather than environment values.
- No network isolation is added for this threat model.
- If a stricter environment profile causes instability, the adapter expands its explicit stable profile with recorded justification and paired conformance tests; it does not silently fall back to unrestricted inheritance.

## Confirmed result-ingress and audit posture

- Each run receives a fresh unique result directory with no pre-existing result.
- The machine result is read only after the controlled process tree terminates and is bounded before parsing.
- Authoritative candidacy requires valid UTF-8 JSON, a closed schema, expected run and target identities, allowed status/severity values, and valid finding references.
- Missing, malformed, prose-wrapped, oversized, or identity-mismatched results become `result-invalid` and are never gateable; the allowance remains spent when provider invocation occurred.
- A valid result is canonicalized and hashed; only `ReviewRunRepository` may attach it to durable run state.
- Markdown remains human-readable and is never parsed for authority.
- No signatures, encryption, or separate attestation service are introduced under the trusted-reviewer model.
- Minimal durable audit lives in campaign/run records: allowance grants/reservations/spend, state revisions, target and harness identity, timing and execution outcome, result digest/validation, currentness/relevance, and containment-monitor health/violations.
- Raw environments, credentials, full prompts, raw reviewer output, and unbounded process details are excluded from the durable audit by default.

**Human-agreed marker**: The maintainer confirmed the trusted-but-fallible, stability-first security posture, simple digest/currentness model, environment policy, result-ingress validation, and minimal audit on 2026-07-16.
