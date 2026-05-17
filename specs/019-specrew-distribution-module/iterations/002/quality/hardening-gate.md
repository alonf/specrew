# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/019-specrew-distribution-module/spec.md`
**Iteration Ref**: `specs/019-specrew-distribution-module/iterations/002`
**Requested Review Class**: `post-repair-verification`
**Effective Review Class**: `post-repair-verification`
**Overall Verdict**: ready
**Reviewed By**: Alon Fliess
**Reviewed At**: 2026-05-18T00:00:00Z
**Post-Implementation Verification**: repaired-and-revalidated — R-019-V2-R21 deferred-launch fix + R22 cleanup verified end-to-end on Windows 11 and WSL Ubuntu (native ext4) 2026-05-18; verb-conformance fix applied (commit 7b08dfd); module import emits no "unapproved verbs" warning
**Verified At**: 2026-05-18T00:00:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Iteration 002 focuses on cross-platform launch flow hardening (deferred-launch architecture) and verb conformance — no new trust boundaries, secrets handling, or external service integrations introduced. | `false` | No new security surface compared to Iteration 001 scope. PSGallery API key and signing certificate remain GitHub Actions secrets (T042 human follow-up). | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Deferred launch file cleaned up in `finally` block; missing file treated as no-op (no deferred launch needed); launch arg serialization uses `ConvertTo-Json`/`ConvertFrom-Json` for safe round-trip; `SPECREW_DEFERRED_LAUNCH_FILE` env var cleared after use. | `true` | Verified end-to-end on both Windows 11 and WSL Ubuntu (native ext4) 2026-05-18 by Alon Fliess. Module imports cleanly; specrew start interactive REPL proceeds without errors. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `runtime-evidence` | `recorded` | Deferred-launch temp file cleaned up after use; re-running `specrew start` writes a fresh file and proceeds normally. `specrew init` idempotency carried forward from Iteration 001 verification. Cross-platform path handling (R14) is deterministic. | `true` | Verified on both platforms 2026-05-18. Repeated `specrew start` invocations produce consistent results. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | `tests/integration/start-command.ps1` updated for R21/R22 deferred-launch args and R22 cleanup; passed on Windows 11. WSL Ubuntu end-to-end confirmed by Alon Fliess 2026-05-18. `tests/integration/distribution-module-init.ps1` covers module-mode detection (R8). | `true` | `pwsh -NoProfile -File tests/integration/start-command.ps1` passed on Windows 11; WSL Ubuntu end-to-end confirmed by human 2026-05-18. | — |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | Cross-platform launch flow works identically on Windows 11 and WSL Ubuntu. Module imports without "unapproved verbs" warning (commit 7b08dfd). Bootstrap auto-loads via `-i`; Squad reads `.specrew/last-start-prompt.md` and `.specrew/start-context.json`; intake conversation proceeds normally on both platforms. | `true` | Full end-to-end verified by Alon Fliess on both platforms 2026-05-18. | — |
| `tty-propagation-cross-platform` | `behavioral` | `addressed` | `runtime-evidence` | `recorded` | R-019-V2-R21 deferred-launch: `specrew-start.ps1` writes launch args to `$env:SPECREW_DEFERRED_LAUNCH_FILE`; `Invoke-SpecrewScript` (function context in `Specrew.psm1`) reads and invokes `& copilot @args` from function body. TTY preserved because invocation site is function body called from user's prompt, not script body. Root cause confirmed: `function F { & nano }; F` preserves TTY; same from script body does not. | `true` | Root cause empirically confirmed by Alon Fliess 2026-05-18. R-019-V2-R21 is the minimal correct fix (~5 lines). Commits: 72d3b51 (fix), 6fa14d6 (cleanup). | Alon Fliess |
| `module-verb-conformance` | `behavioral` | `addressed` | `runtime-evidence` | `recorded` | Module exports use approved `Verb-Noun` form: `Invoke-Specrew`, `Initialize-Specrew`, `Start-Specrew`, `Update-Specrew`, `Show-SpecrewReview`, `Invoke-SpecrewTeam`, `Show-SpecrewStatus`. CLI-friendly aliases preserved. `Import-Module Specrew.psd1` emits no "unapproved verbs" warning. | `false` | Verified on both platforms 2026-05-18 after commit 7b08dfd. All CLI aliases functional. | — |

## Post-Implementation Verification Evidence

### Windows 11 Verification (2026-05-18)

- `specrew init`: Correct module-mode messaging confirmed
- `specrew start`: Opens Copilot interactive REPL with Squad selected and `--allow-all` enabled
- Bootstrap auto-loads via `-i`; Squad reads `.specrew/last-start-prompt.md` and `.specrew/start-context.json`; intake conversation proceeds normally
- Module imports without "unapproved verbs" warning (commit 7b08dfd)

### WSL Ubuntu (native ext4) Verification (2026-05-18)

- `specrew init`: Correct module-mode messaging confirmed — identical to Windows behavior
- `specrew start`: Opens Copilot interactive REPL with Squad selected and `--allow-all` enabled
- Bootstrap auto-loads via `-i`; Squad reads `.specrew/last-start-prompt.md` and `.specrew/start-context.json`; intake conversation proceeds normally
- Module imports without "unapproved verbs" warning
- **Root cause confirmed**: `function F { & nano }; F` diagnostic confirmed TTY preservation in function-body context on Linux; R-019-V2-R21 is the minimal correct fix

### Critical Commit Trail

| Commit | Description | Classification |
| --- | --- | --- |
| `e559d65` | R1: Wrong-direction bash TTY shim | reverted by R22 |
| `72d3b51` | R21: Deferred-launch via function body (THE actual fix) | kept |
| `6fa14d6` | R22: Cleanup of R10-R20 wrong-direction artifacts | kept |
| `872b5a8` | Uniform `--allow-all` default restored | kept |
| `f998730` | README WSL-validated | kept |
| `7b08dfd` | Verb conformance (HEAD) | kept |

## Hardening-Gate Status

**Overall Verdict**: ready

**Scope**: Iteration 002 post-repair verification for Feature 019 Specrew Distribution Module — cross-platform launch flow (R-019-V2-R21 deferred-launch fix), R22 wrong-direction artifact cleanup, and verb-conformance (commit 7b08dfd).

**Rationale**: Cross-platform launch flow verified end-to-end on Windows 11 and WSL Ubuntu (native ext4) 2026-05-18 by Alon Fliess. Root cause isolated and fixed via R-019-V2-R21 deferred-launch pattern. R22 reverted all wrong-direction artifacts from the R1-R20 repair chase. Verb-conformance fix eliminates "unapproved verbs" warning on module import. All legitimate cross-platform fixes (R8, R14, R18/R19, R21) preserved; all wrong-direction artifacts removed.

**Repair Chain Summary**: R-019-V2-R1 through R-019-V2-R22 (22 sub-iterations). Root cause: PowerShell on Linux strips TTY for `& nativeCommand` from script-body context; preserves TTY from function-body context. Fix: deferred launch via temp-file coordination to module function body. Full event record in `specs/019-specrew-distribution-module/iterations/002/drift-log.md`.



