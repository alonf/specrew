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
- The T013 outside-origin guard and the strict design-context validation share **one** physical-path
  canonicalizer (`Get-ContinuousCoReviewPhysicalPath`) **and one containment predicate**
  (`Test-ContinuousCoReviewPathUnderRoot`) so their resolution AND comparison semantics cannot drift.
  The canonicalizer resolves **every** path component — following intermediate directory
  symlinks/junctions, not just the final component — to the real physical path, and **fails closed** if
  any existing component cannot be resolved. The predicate compares with **platform-appropriate case
  sensitivity** (Windows/NTFS case-insensitive; POSIX case-sensitive), so a case-distinct sibling (e.g.
  `/x/repo` vs the repo `/x/Repo`) cannot be falsely accepted as "under root" on Linux. T013 refuses an `EphemeralRoot` (or an intermediate component) whose physical target lands
  under origin; the strict design-context gate refuses a ref whose physical path is not under the
  repo root. **Policy for in-repo links:** a symlink/junction whose physical target is still under the
  repo root (T013: outside origin) **passes** — only targets that resolve outside the boundary are
  rejected.

## Verification and reviewer-invocation integrity

**The orchestrator does NOT run verification for the reviewer.** An earlier design had the orchestrator
re-run declared verification commands (auto-supplied from evidence) in a disposable copy on every
review. It was removed (maintainer decision, 2026-07-11) because it could not be confined in-process and
fought the anti-budget-death design of implementer evidence:

- the copy was **not an OS boundary** — a command runs with ambient filesystem authority and can reach
  the reviewer worktree by absolute/`..` path (finding `4b124d0e`);
- copying the live worktree **raced concurrent reviewer-host churn** (finding `c9abe16d`);
- unbounded output had to be capped (finding `bfc7b5c5`);
- re-running whole suites every review is exactly what implementer evidence exists to avoid.

Those cases survive as **regression evidence** in `bounded-verification.Tests.ps1`, documenting why
automatic reruns were removed.

**Runner-observed verification is T018's job.** Verification commands run **once** through the
recorded-run wrapper (the implementer's tooling), and the digest-bound result is injected as
`.review/implementer-evidence.json` for the reviewer to **read and spot-check** — never re-run wholesale
(see the implementer-evidence block in the prompt). The digest gate means a stale record is never
injected against a different tree.

**Reviewer-invocation integrity (the actual protection).** The reviewer is itself an agentic host with
ambient authority, so the engine hashes the **source + authoritative reviewer inputs** (`.review/changes.diff`,
`design/`, `process/`, `implementer-evidence.json`, and all source) immediately **before and after** the
reviewer runs. The **only** permitted write is the reviewer's own output, `.review/findings.jsonl`. Any
other mutation — editing/adding/deleting source, rewriting a `.review/` input, or leaving build/test
artifacts behind — **fails the review** (`failure_reason: reviewer-tampered-tree`; the model was invoked
so it is the invoked-failed spend class — provider spend + round consumed + a `reviewer-tampered-tree`
disposition — and the findings are discarded). The exemption for volatile reviewer-host runtime dirs
(`.antigravitycli/`, `.codex/`, `.claude/`, `.cursor/`, `.gemini/`, `.copilot/`) is **new-files-only**:
a host may create NEW ephemeral session state there, but a **pre-existing** file under one of those dirs
(e.g. project-tracked config the archive extracted) that is **modified or deleted is still tampering** —
those dirs are hashed, not skipped. This is **monitored confinement, not OS-enforced filesystem
isolation**; the T016 detector likewise monitors and reports, it does not sandbox.

**Future work (out of T015 scope).** Genuinely confining declared/reviewer commands — a dedicated
process identity plus worktree-only ACL isolation — is recorded as a separate future proposal
(`iterations/003/research/reviewer-os-isolation-future.md`).

### The opt-in bounded-verification helper

`Invoke-ContinuousCoReviewBoundedVerification` remains available as an **explicit opt-in API** for
focused caller-supplied commands. **It never runs automatically** — the orchestrator does not call it.
A caller that opts in gets, per command:

1. **Timeout + process containment** — a per-command timeout; on expiry the ENTIRE child process tree
   is killed (`Kill(entireProcessTree)`), not just the direct child.
2. **Byte-bounded, zero-disk streaming cap** — both pipes are pumped into fixed byte buffers capped at
   `MaxOutputBytes` each; overflow is read and **discarded** (the child is always drained, so it can
   never block on a full pipe), memory stays bounded at ~2× cap, and **nothing is written to disk** —
   a sustained flood can exhaust neither memory nor host temp storage. `output_truncated` records the
   overflow; `captured_stdout_bytes` / `captured_stderr_bytes` record what was retained.
3. **Pre/post mutation evidence** — existing-file hashes before vs after. **Added, deleted, and modified
   files ALL count**; a NEW file is exempt **only** via the explicit output-path allowlist
   (`AllowedOutputPaths`). The hashed set **includes the `.review/` authority inputs** — rewriting the
   authority a check depends on is itself a mutation. `.git/` and volatile host-runtime dirs are excluded.

Each command yields `{ command, exit_code, timed_out, output, output_truncated, captured_stdout_bytes,
captured_stderr_bytes, source_mutated, mutated_paths }`. The caller owns confinement of the directory it
points the helper at.
