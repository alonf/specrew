# Hardening Gate: Iteration 001

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/050-cursor-host-support/spec.md`  
**Iteration Ref**: `specs/050-cursor-host-support/iterations/001`  
**Requested Review Class**: `phase-1-custom-composition`  
**Effective Review Class**: phase-1-custom-composition  
**Overall Verdict**: ready  
**Approval Ref**: —  
**Reviewed By**: Specrew Crew Coordinator  
**Reviewed At**: 2026-05-28  
**Post-Implementation Verification**: pending — to be completed after implement (unit tests for all 5 contract functions, manifest validity, registry auto-discovery, structural firewall, FileList coverage).  
**Verified At**: —

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `auto-approve-flag-safety` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `New-CursorLaunchInvocation` + `ConvertTo-CursorFlag` emit `--force`/`--trust`/`--yolo` ONLY when the user passed `--allow-all`/`--autonomous`; never default-on. Unit test asserts the flags are ABSENT in the default invocation. | `false` | These flags make cursor-agent run shell/write tools without prompting. The only acceptable control is gating them strictly behind explicit user opt-in, verified by test. | — |
| `secret-handling` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Specrew MUST NOT read, log, or persist `CURSOR_API_KEY` or `--api-key`; key material is user-managed by cursor-agent. No code path captures it. | `false` | Auth is delegated entirely to cursor-agent's own login/keychain; Specrew only builds an invocation. No secret is handled. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Test-CursorRuntimeInstalled` returns `$false` (never throws) on missing binary; missing-binary path yields actionable `InstallGuidance`, not a stack trace; `ConvertTo-CursorFlag` returns Notice+SuppressWarning on unknown flags. | `false` | The dominant failure path is "binary not on PATH" — it must degrade to guidance. Covered by US1 scenarios 2/3 + tests. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | All 5 contract functions get assertion-driven unit tests with mock AND real-`cursor-agent` fixtures (real cases skip-guarded); negative paths (missing binary, unknown flag, dry-run no-write, idempotent re-sync) explicitly asserted. | `false` | Verification-confidence dimension demands tests prove behavior, not just "ran". SC-004 = 5/5 functions covered. | — |
| `design-quality-soc` | `design-quality` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Cursor logic confined to `hosts/cursor/`; only the contract-sanctioned `Get-ActiveSkillRoots` entry touches a shared script (FR-003); structural firewall test ensures no `cursor` enum tuple leaks into host-neutral core. | `false` | The architecture's whole point (F-044) is that a new host needs no core edits. Keeping the blast radius inside `hosts/cursor/` validates SC-006. | — |
| `maintainability` | `maintainability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Follows the established 3-file package shape (host.psd1 + handlers.ps1 + coordinator-rules.psd1) idiomatic with the codex analog, so future host additions stay mechanical. | `false` | Maintainability bar is "next host is still half-a-day". Mirroring codex keeps the pattern uniform. | — |
| `mirror-parity-integrity` | `governance-compliance` | `deferred-with-approval` | `planning-time-analysis` | `pending-post-implementation` | FR-003 edits the **source** `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`. The deployed mirror `.specify/extensions/specrew-speckit/**` is intentionally NOT edited in this worktree (Parallel-Work Charter Items 2+3 forbid touching the framework mirror + running `specrew update` mid-flight). Mirror re-sync happens at the controlled post-merge deploy step. | `false` | This is a known, charter-sanctioned divergence for the parallel-development pilot. Surfacing it here so the human approves the deferred mirror-sync explicitly rather than discovering a validator WARN later. **Requires human acknowledgement at before-implement.** | — |
| `non-interactive-launch-correctness` | `verification-confidence` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `New-CursorLaunchInvocation` builds `cursor-agent --print --workspace <proj> "<prompt>"`; unit test asserts `--print` + `--workspace` present (non-interactive headless contract, FR-011). | `false` | FR-011's resolved answer (non-interactive supported) is only real if the invocation actually requests headless mode. Test pins it. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | No retry/reconnect mechanism ships. The only idempotency surface — `Install-CursorCrewRuntime` re-sync without duplication — is covered under `test-integrity-targets`. | `false` | Launch + manifest are stateless; there is no shared-state retry workflow in this slice. | — |
| `concurrency-correctness` | `concurrency` | `not-applicable` | `not-applicable` | `not-needed` | Quality profile marked concurrency not-applicable; no shared mutable state, no parallelism in the host package. | `false` | Pure functions + declarative manifest + idempotent file writes; no concurrency surface. | — |

## Planning Evidence Notes

- Iteration 001 scope is limited to T001–T010 (core package + skill target): FR-001, FR-002, FR-003, FR-004, FR-009, FR-010, FR-011.
- Test coverage hardening (FR-005/006/007) is iteration 002; documentation (FR-008) is iteration 003. Per-function unit tests are still authored alongside the functions in iteration 001 to keep verification-confidence honest.
- The five canonical hardening concerns (security, error-handling, test-integrity, plus design/maintainability dimensions from the resolved profile) appear with explicit expected controls.
- **One item requires explicit human acknowledgement**: `mirror-parity-integrity` is `deferred-with-approval` — the FR-003 source edit's mirror sync is deferred to the controlled post-merge deploy step per the Parallel-Work Charter, not performed in this worktree.

## Hardening-Gate Status

**Overall Verdict**: ready — all material risks for the iteration-001 core slice are planned with expected controls or marked not-applicable for scope, with one charter-sanctioned `deferred-with-approval` item (mirror parity) surfaced for explicit human acknowledgement at the before-implement gate.

**Scope**: Iteration 001 — Cursor host package (manifest + 5 contract functions + skill-root entry + FileList + registry verification), ~4–6 story_points.
