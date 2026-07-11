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
- This is isolation by **snapshot + origin-reference removal (T013/T014), not an OS-enforced
  filesystem sandbox**: confinement is a contract term the reviewer must honor, and the containment
  detector (T016) monitors for violations and reports them loudly.

## Bounded verification — who runs it, and where the boundary is

The reviewer is a full agentic host with **direct tool access**: it runs shell commands itself, so the
engine **cannot** route those runs through a PowerShell wrapper, and the contract does not pretend it
can. Enforcement is split honestly by who controls the run:

- **The reviewer's own runs are governed by the confinement CONTRACT — not by a wrapper, and not by an
  OS sandbox.** T013 materializes the worktree as an isolated snapshot outside the origin repository and
  T014 removes origin references from the reviewer-visible context. Neither creates an OS-enforced
  filesystem sandbox: nothing OS-level prevents a hostile command from reaching outside the snapshot, so
  the contract makes staying inside it — read-only, declared commands only — a binding term stated
  plainly in the prompt, and the containment detector (T016, on the T100 registry) monitors for
  violations and reports them loudly after the fact (it never kills a reviewer mid-flight).

- **The orchestrator's runs ARE wrapped, on the real review path — and they run in a disposable
  copy.** Before spawning the reviewer, `Invoke-ContinuousCoReviewWorktreeReviewRun` runs the
  **declared verification commands** through `Invoke-ContinuousCoReviewBoundedVerification` **in a
  disposable sibling copy of the worktree, never the tree the reviewer is handed** — a mutating
  declaration is recorded (`source_mutated`, for the reviewer to judge) but is structurally unable to
  alter the certified reviewer inputs (source, `.review/changes.diff`, design context). The
  **host-observed** results are injected into the reviewer worktree at
  `.review/verification/results.json`. This is the runner-observed complement to the
  implementer-supplied evidence: it is independently observed by the engine, so it carries no forgery
  spot-check. The reviewer prefers these results over re-running the same commands. The prompt block is
  gated on the injection actually happening (no commands → no file, no block — never a pointer to an
  absent record).

  **Where the declared commands come from (minimal supply):** the caller's explicit
  `-DeclaredVerificationCommands` wins; when the caller declares none, the engine uses **only**
  commands **explicitly recorded** in the digest-matched implementer evidence
  (`.review/implementer-evidence.json`, `suites[].command`) — **verbatim**. Commands are never inferred
  from suite names, discovered by scanning, or defaulted to repository sweeps; evidence that records no
  command strings supplies nothing, and the run status reports the account honestly
  (`verification_source`, declared vs run counts). Generalized evidence discovery and richer provenance
  are deferred to Proposal 203 W8.

`Invoke-ContinuousCoReviewBoundedVerification` enforces, per command:

1. **Timeout + process containment** — a per-command timeout; on expiry the ENTIRE child process tree
   is killed (`Kill(entireProcessTree)`), not just the direct child.
2. **Byte-bounded, zero-disk streaming cap** — both pipes are pumped into fixed byte buffers capped at
   `MaxOutputBytes` each; overflow is read and **discarded** (the child is always drained, so it can
   never block on a full pipe), memory stays bounded at ~2× cap, and **nothing is written to disk** —
   a sustained flood can exhaust neither reviewer memory nor host temp storage. `output_truncated`
   records the overflow; `captured_stdout_bytes` / `captured_stderr_bytes` record what was retained.
3. **Pre/post mutation evidence** — the worktree's existing-file hashes are compared before and after.
   **Added, deleted, and modified files ALL count as mutations** (the runner must be read-only); a NEW
   file is exempt **only** when it matches the explicit output-path allowlist (`AllowedOutputPaths`,
   e.g. `*.log`, `coverage/*`). Any other new file is a mutation. The hashed set **includes the
   reviewer-authority inputs under `.review/`** (`changes.diff`, design/spec/contracts, process
   context) — a command that rewrites the very authority it verifies against manufactures a pass, so
   that mutation is reported like any other. Excluded are only `.git/` and the narrow engine-owned
   output area `.review/verification/`.

Each command yields a record: `{ command, exit_code, timed_out, output, output_truncated,
captured_stdout_bytes, captured_stderr_bytes, source_mutated, mutated_paths }`. A run whose
`source_mutated` is true is itself a finding.

**Verification infrastructure failure is loud, never silent.** When commands WERE declared but the
runner or the results write itself fails (an engine defect — distinct from a declared command that
runs and fails, which is a result for the reviewer to judge), the run FAILS before the reviewer is
invoked (`failure_reason: verification-not-executed`, diagnosable message, T020 preflight spend class —
neither budget consumed). A declared verification can never silently degrade into "no results" and
still produce a clean review.
