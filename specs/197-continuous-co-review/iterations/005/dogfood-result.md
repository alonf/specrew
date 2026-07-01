# Iteration 005 Dogfood — running the navigator on its OWN code

**Feature**: 197-continuous-co-review
**Iteration**: 005
**Date**: 2026-06-24
**What**: drove the async co-review navigator MECHANISM on iteration 005's own navigator code,
with a REAL `claude -p` reviewer (not the stub), on this real repo.

## Outcome: the mechanism WORKS end-to-end — and the dogfood caught 2 real bugs the unit tests missed

### The mechanism ran end-to-end

`Invoke-ContinuousCoReviewNavigator` (forced checkpoint) -> `action=fired` -> the launcher
materialized the live tree into a `$TEMP` worktree -> a fresh-context `claude -p` reviewed the
navigator file FROM the worktree (a real **51-second** review) -> emitted a substantive verdict ->
the supervisor captured it (`status=done`, `child_exit=0`, no orphan) -> the reap surfaced it.

The reviewer's real verdict (4 genuine findings, disposition `pass`, non-blocking): degraded-path
worktree-metadata cleanup; the supersede loop runs before the launcher-availability guard; the
reap treats a transient Get-Process failure as crashed-and-kill (slightly aggressive); no outer
try/catch on `Invoke-ContinuousCoReviewNavigator` (fail-open leans on the loader). -> T081 follow-ups.

### 2 production bugs CAUGHT + FIXED (the dogfood's real value)

1. **`& git` encoding error in the provider context.** The dispatcher's providers set a non-console
   UTF-8 `[Console]::OutputEncoding`; with the provider stdout redirected (the hook context),
   PowerShell's `& git` throws *"StandardOutputEncoding is only supported when standard output is
   redirected."* The navigator is the first provider to run git after that, so it was the first to
   hit it. FIX: `Invoke-ContinuousCoReviewGit` now uses an explicit `System.Diagnostics.Process`
   (redirect + UTF-8), immune to the ambient `[Console]` state.
2. **Huge git-diff argument.** The reviewable diff passed every changed path as an explicit `git
   diff -- <paths>` arg; a real repo's change-set blows the OS command-line limit ("filename or
   extension is too long"). (`git diff` has NO `--pathspec-from-file`.) FIX: batch the paths — a
   small set is one batch = the original byte-identical command; larger sets concatenate
   deterministically.

Both fixes validated: checkpoint-diff-provider 6/0, digest 10/0, gate 11/0, navigator 8/0; the
full reap cycle re-run clean on the real repo (`action=fired`, no errors).

## Still open (T081 / closeout)

- The 4 reviewer findings above (minor navigator hardening).
- The 3 implementer-flagged gaps: FileList packaging (closeout blocker), stop-block collision +
  `--event-json` codex arg (dispatcher/F-184).
- PASS->runs/ promotion (so auto-fired PASS verdicts feed the Iteration-004 gate) — deferred.
- The formal T081 test pass + closeout-validation + a Proposal 145 review.

## Honest assessment

The dogfood did exactly what dogfooding is for: it proved the always-on co-review mechanism works
on real code with a real reviewer, AND it surfaced two real bugs that every green unit test had
missed (both only manifest in the redirected-provider context on a real-sized repo). The core is
sound; the integration tail (the gaps + findings) is the remaining closeout work.
