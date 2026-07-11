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

## Bounded verification — who runs it, and where the boundary is

The reviewer is a full agentic host with **direct tool access**: it runs shell commands itself, so the
engine **cannot** route those runs through a PowerShell wrapper, and the contract does not pretend it
can. Enforcement is split honestly by who controls the run:

- **The reviewer's own runs are contained by the HOST BOUNDARY, not by a wrapper.** They execute inside
  the disposable, isolated worktree the reviewer cannot escape (T013/T014), and the containment monitor
  (T016, on the T100 registry) **records** what the reviewer runs. The prompt tells the reviewer this
  plainly and requires it to stay read-only and run only the change's declared verification commands —
  the boundary is the enforcement, not a claim that each call is wrapped.

- **The orchestrator's runs ARE wrapped, on the real review path.** Before spawning the reviewer,
  `Invoke-ContinuousCoReviewWorktreeReviewRun` runs any **declared verification commands**
  (`-DeclaredVerificationCommands`) through `Invoke-ContinuousCoReviewBoundedVerification` and injects the
  **host-observed** results into the worktree at `.review/verification/results.json`. This is the
  runner-observed complement to the implementer-supplied evidence: it is independently observed by the
  engine, so it carries no forgery spot-check. The reviewer prefers these results over re-running the
  same commands. The prompt block is gated on the injection actually happening (empty command set → no
  file, no block — never a pointer to an absent record).

`Invoke-ContinuousCoReviewBoundedVerification` enforces, per command:

1. **Timeout + process containment** — a per-command timeout; on expiry the ENTIRE child process tree
   is killed (`Kill(entireProcessTree)`), not just the direct child.
2. **Byte-bounded, streaming output cap** — both pipes are drained to disk with `CopyToAsync` (reviewer
   memory stays bounded regardless of output volume — a hostile flood lands on disk, not in the
   process), then at most `MaxOutputBytes` **UTF-8 bytes** are read back; `output_truncated` records the
   overflow.
3. **Pre/post mutation evidence** — the worktree's existing-file hashes are compared before and after.
   **Added, deleted, and modified files ALL count as mutations** (the runner must be read-only); a NEW
   file is exempt **only** when it matches the explicit output-path allowlist (`AllowedOutputPaths`,
   e.g. `*.log`, `coverage/*`). Any other new file is a mutation.

Each command yields a record: `{ command, exit_code, timed_out, output, output_truncated,
source_mutated, mutated_paths }`. A run whose `source_mutated` is true is itself a finding.
