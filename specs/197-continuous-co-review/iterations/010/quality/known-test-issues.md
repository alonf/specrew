# Known Test Issues — pre-existing, NOT F-197 regressions (verified by commit comparison)

**Schema**: v1
**Recorded**: 2026-07-08 (during the T111 evidence-recording sweep)

## `tests/unit` — 2 pre-existing failures (public-readiness drift warnings)

- **Failing tests**: `validate-governance public-readiness warnings — emits additive soft warnings
  for drifted fixtures` (both `extension` and `specify` validator copies).
  Expected 5 `WARN [public-readiness]` lines from the drifted fixture; got 0 (exit 0, PASS otherwise).
- **NOT an F-197/T111 regression — proven by comparison**: the identical failure signature
  (8 passed / 2 failed, same two tests) reproduces in a detached worktree at commit `2bd508c7`
  (the tree BEFORE T111), run 2026-07-08 with the same Pester 5.8.0 invocation. F-197 touches no
  validator or public-readiness surface.
- **Scope ruling**: the public-readiness soft-warning path belongs to F-006/F-013 validator
  surfaces, out of F-197's charter. Fixing it here would be unreviewed scope at review-signoff.
  Carried as a repo maintenance item (see the 2026-07-08 decisions-ledger note); it does not block
  0.40.0 (the check degrades to fewer soft WARNINGS, never to a false hard-PASS of a hard-fail).
- **Machine evidence honesty**: the T111 evidence record for the `unit` suite carries
  `failed=2` — the recorder writes what the runner reported, and this note is the standing
  explanation.

## `tests/unit` plain-script discovery noise

Several `*.tests.ps1` files under `tests/unit` are plain scripts (Write-Pass/Write-Fail + exit
codes), not Pester containers. A directory-level `Invoke-Pester tests/unit` EXECUTES their bodies
during discovery — they do real work (including spawning `specrew review --live` probes, ~5 min)
and one (`instruction-file-merge.tests.ps1`) reports a discovery error. Their results do not enter
the Pester counts and they pass when run directly as scripts (their intended invocation). Also
pre-existing behavior, identical at `2bd508c7`.
