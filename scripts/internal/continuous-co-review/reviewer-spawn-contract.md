# Reviewer spawn contract (continuous co-review)

**FR-010 / FR-013 (203 W3/W6), F-198 iteration 003, T015.** This is the durable statement of the
confinement contract the reviewer is spawned under. Its RUNTIME carrier is the slim prompt
(`Get-ContinuousCoReviewSlimPrompt` in `worktree-reviewer.ps1`); this file is the human-readable
source of truth for what that prompt promises and why.

## Worktree confinement

- The reviewer's working directory is a **disposable, isolated copy** materialized OUTSIDE the origin
  repository — no upward directory or git walk from inside it resolves the real project (T013).
- The governance machinery (`.squad/`, `.specrew/`, `.specify/`) is **stripped**, and origin-absolute
  paths in the reviewer-visible context are **relativized to `<project>`** (T014).
- Anything intentionally absent — stripped machinery, a relativized path — is **expected, never a
  defect**; a reference to it is treated as unverifiable-here, not false.
- The reviewer is **read-only on the source**: it finds issues, it does not fix them.

## Bounded in-worktree verification (the REQUIRED verification step)

When the reviewer runs tests/build to verify a claim, it runs **only the implementer's DECLARED
verification commands** — never an unrestricted whole-repository sweep. Each run is executed by
`Invoke-ContinuousCoReviewBoundedVerification` with:

1. **Timeout + process containment** — a per-command timeout; on expiry the ENTIRE child process tree
   is killed (`Kill(entireProcessTree)`), not just the direct child.
2. **Capped output** — captured stdout+stderr is truncated at a UTF-8 **byte** limit
   (`MaxOutputBytes`); `output_truncated` records when the cap was hit.
3. **Pre/post mutation evidence** — the worktree's existing-file hashes are compared before and after.
   **Added, deleted, and modified files ALL count as mutations** (the reviewer is read-only); a NEW
   file is exempt **only** when it matches the explicit output-path allowlist (`AllowedOutputPaths`,
   e.g. `*.log`, `coverage/*`). Any other new file is a mutation — a reviewer must not plant new
   source that steers the verification it then runs.

Each command yields a record: `{ command, exit_code, timed_out, output, output_truncated,
source_mutated, mutated_paths }`. A run whose `source_mutated` is true is itself a finding.
