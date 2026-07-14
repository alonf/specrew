# Shell-safe + cross-platform version-probe verification (F-198 iteration 005)

Durable execution record for the FR-053a shell-safe reconciliation + the trusted-interpreter fix (the third and
fourth co-review rounds). It exists because a `state.md` "green" claim is not self-verifying: this file records the
EXACT commands, their observed results, and the environments, on BOTH supported OSes. The digest-bound MACHINE
record of the registry run (reviewed-tree digest, command, timestamps, exit code, output digests) is written to the
co-review evidence store `.specrew/review/test-evidence/<committed-digest>.json` (`command_succeeded=true`) at the
committed digest via `Invoke-ContinuousCoReviewRecordedRun`.

Scope of the change verified: `scripts/internal/continuous-co-review/hook-health-receipt.ps1` (the shell-safe,
cross-platform, trusted-interpreter version probe), `spec.md` FR-053a, and the four test suites.

## Windows (pwsh 7.6.3)

| Command | Result |
| --- | --- |
| `pwsh -File tests/f198-regression-suite.ps1` | **all 36 suites green**, 0 FAIL |
| `Invoke-Pester tests/continuous-co-review/unit/hook-health-receipt.Tests.ps1` | passed=45 failed=0 skipped=0 |
| `Invoke-Pester tests/continuous-co-review/unit/codex-headless-preflight.Tests.ps1` | passed=10 failed=0 skipped=0 |
| `Invoke-Pester tests/continuous-co-review/unit/host-support-reconciliation.Tests.ps1` | passed=19 failed=0 skipped=0 |
| `pwsh -File tests/integration/f198-iter005-hook-health-production-path.tests.ps1` | all assertions green (incl. the interpreter-hijack falsification) |

The Windows-only falsifications RAN here (not skipped):
- **Injection guard**: a `.cmd` shim whose resolved path bears a shell metacharacter (`&`) is refused → `unknown`,
  and the shim never executes (no `INJECTED.txt`).
- **Trusted interpreter**: a hijacked / empty `$env:ComSpec` is ignored — the probe binds cmd.exe to the trusted
  System32 (`[Environment]::SystemDirectory`) and still returns the shim's version. Proven at both the unit level
  and the production-path level (a SessionStart fire with a bogus `$env:ComSpec` still records the shim version).

## Linux (Docker `mcr.microsoft.com/powershell:latest`, pwsh 7.4.2, Pester 5.6.1)

Command: `docker run --rm -v <repo>:/repo -w /repo mcr.microsoft.com/powershell:latest pwsh -File <linux-verify-all.ps1> /repo`

| Suite | Result |
| --- | --- |
| `tests/integration/f198-iter005-hook-health-production-path.tests.ps1` | all assertions green (exit 0) |
| `hook-health-receipt.Tests.ps1` | passed=43 failed=0 **skipped=2** |
| `codex-headless-preflight.Tests.ps1` | passed=10 failed=0 skipped=0 |
| `host-support-reconciliation.Tests.ps1` | passed=19 failed=0 skipped=0 |

The 2 skipped tests on Linux are the Windows-only interpreter/injection-guard falsifications (`-Skip:(-not $IsWindows)`)
— on Linux there is no `.cmd`/`.bat` shim and no cmd.exe mediation: every host (native binary or shebang script) is
exec'd DIRECTLY by the kernel, so the probe is shell-free by construction and those Windows-only guards do not apply.

CI runs on `ubuntu-latest`, so Linux correctness is a release requirement; this Docker run demonstrates it directly
(the same suites the CI executes, plus the production-path integration).

## Interpretation

- The probe is **shell-safe on every OS**: native executables (Windows `.exe`; all POSIX binaries / shebang scripts)
  are invoked directly (genuinely shell-free); a Windows `.cmd`/`.bat` shim is the only interpreter-mediated case and
  is hardened on both the interpreter (trusted System32 cmd.exe, not ambient `%ComSpec%`/`%PATH%`) and the argument
  (metacharacter-refused path), each falsified by a test rather than asserted.
- Green on Windows (36/36) and Linux (production-path + unit suites), with the Windows-only falsifications correctly
  skipped on Linux.
