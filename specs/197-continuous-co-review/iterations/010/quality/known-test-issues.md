# Known Test Issues — pre-existing, NOT F-197 regressions (verified by commit comparison)

**Schema**: v1
**Recorded**: 2026-07-08 (during the T111 evidence-recording sweep); public-readiness item
ROOT-CAUSED AND FIXED 2026-07-09.

## `tests/unit` — public-readiness drift warnings: ROOT-CAUSED and FIXED (fixture lag, not validator defect)

- **Symptom**: `validate-governance public-readiness warnings — emits additive soft warnings for
  drifted fixtures` failed on both validator copies: expected 5 `WARN [public-readiness]` lines from
  the deliberately-incomplete fixture; got 0 (exit 0, PASS otherwise).
- **NOT an F-197/T111 regression — proven twice**: identical signature (8/2, same two tests) in a
  detached worktree at pre-T111 commit `2bd508c7`; and on `main` (`5bca4fdf`) the same test file is
  WORSE (all 6 fail, including clean-fixture and hard-fail cases — main has its own additional
  breakage on this surface, not diagnosed here).
- **Root cause (maintainer-prompted diagnosis, 2026-07-09)**: the F-040 dogfooding fix (2026-05-23)
  made public-readiness checks OPT-IN via `.specrew/config.yml#public_readiness.enabled` (new
  projects default private). Both test fixtures were bootstrapped 2026-05-04 and were never migrated
  to the opt-in contract — so the check silently skipped and emitted zero warnings. The VALIDATOR is
  correct; the FIXTURES lagged a behavior change.
- **Fix (2-line test data, zero production code)**: `public_readiness:\n  enabled: true` appended to
  both fixture configs (`public-readiness-clean` + `public-readiness-drift`). The clean fixture now
  genuinely exercises the enabled-but-clean path; the drift fixture exercises all 5 warnings.
  Verified: the test file passes 6/6; `tests/unit` is 10/10.
- **Left for main**: `main`'s additional failures on this file (clean + hard-fail cases) are a
  separate, undiagnosed breakage to reconcile at PR time.

## `tests/unit` plain-script discovery noise

Several `*.tests.ps1` files under `tests/unit` are plain scripts (Write-Pass/Write-Fail + exit
codes), not Pester containers. A directory-level `Invoke-Pester tests/unit` EXECUTES their bodies
during discovery — they do real work (including spawning `specrew review --live` probes, ~5 min)
and one (`instruction-file-merge.tests.ps1`) reports a discovery error. Their results do not enter
the Pester counts and they pass when run directly as scripts (their intended invocation). Also
pre-existing behavior, identical at `2bd508c7`.
