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
**Reviewed At**: 2026-05-29  
**Post-Implementation Verification**: passed — all 5 cursor contract functions covered by tests/integration/host-cursor.tests.ps1; host-registry, crew-bootstrap-contract, host-coupling-firewall, host-detection-ux, post-bootstrap-output, multi-host-launch-path suites green; mechanical checks 0 findings; launch dispatch smoke confirmed (cursor-agent <prompt> --workspace <path> [--force]). The only validator WARNs are pre-existing out-of-scope items (README/extension.yml v0.27.x version drift, F-048 dashboard regression).  
**Verified At**: 2026-05-29T00:00:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `--force`/`--trust`/`--yolo` auto-approve flags are emitted ONLY under explicit `--allow-all`/`--autopilot`; never default-on (unit test asserts absence in default invocation). Specrew never reads/logs/persists `CURSOR_API_KEY` or `--api-key` — auth is delegated entirely to cursor-agent. | `false` | These flags let cursor-agent run shell/write tools unprompted; gating them behind explicit opt-in (test-verified) is the control. Secret material is never handled by Specrew. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Test-CursorRuntimeInstalled` returns `$false` (never throws) on missing dir; `ConvertTo-CursorFlag` returns Notice+SuppressWarning on `--remote` (no equivalent); missing-binary degrades to InstallGuidance not a stack trace. | `false` | The dominant failure path (binary/runtime absent) degrades to guidance; unknown-flag path warns rather than silently dropping. Covered by host-cursor tests. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | No retry/reconnect mechanism ships. The one idempotency surface — `Install-CursorCrewRuntime` re-sync without duplication — is covered under `test-integrity-targets`. | `false` | Launch + manifest are stateless; there is no shared-state retry workflow in this slice. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | All 5 contract functions have assertion-driven tests with negative paths (missing dir, unknown flag, dry-run no-write, idempotent re-sync, env-signal detection); real-binary path resolution exercised; mechanical checks 0 findings. | `false` | Verification-confidence demands tests prove behavior. SC-004 (5/5 functions) is met by host-cursor.tests.ps1 + crew-bootstrap-contract.tests.ps1. | — |
| `operational-resilience-concerns` | `operational-resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Cursor addition does not break host-neutral core (registry, firewall, all host suites green); version-probe tolerant; `--print`/`--trust` headless-only flags deliberately excluded from the interactive launch. | `false` | The operational risk is destabilizing the multi-host launch path; the full host suite passing post-change demonstrates resilience. | — |
| `design-quality-soc` | `design-quality` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Cursor logic confined to `hosts/cursor/`; shared-script edits limited to the allow-listed deferred-hardcode ValidateSets + the sanctioned `Get-ActiveSkillRoots` entry; structural firewall test green (no new host-enum leakage). | `false` | The architecture's promise (F-044) is honored modulo the documented finite per-host ValidateSet cost (DRIFT-001). Blast radius stayed within allow-listed surfaces. | — |
| `maintainability` | `maintainability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Follows the codex/antigravity 3-file package shape exactly; cursor mirrors codex for coordinator-rules (no slash surface → FR-014 pwsh rewrite). | `false` | Uniformity with existing hosts keeps the next host addition mechanical. | — |
| `non-interactive-launch-correctness` | `verification-confidence` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `New-CursorLaunchInvocation` builds the INTERACTIVE shape `cursor-agent "<prompt>" --workspace <path>` (matching claude/codex/antigravity), NOT `--print`; unit test pins the argv. FR-011's "non-interactive supported" finding gates Status=supported but the launch itself is interactive. | `false` | A `--print` launch would run headless-once and not let the developer drive the lifecycle; the interactive shape is the correct `specrew start` behavior. | — |
| `concurrency-correctness` | `concurrency` | `not-applicable` | `not-applicable` | `not-needed` | Quality profile marked concurrency not-applicable; pure functions + declarative manifest + idempotent file writes; no shared mutable state. | `false` | No concurrency surface in the host package. | — |
| `mirror-parity-integrity` | `governance-compliance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | FR-003 edits the **source** `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` (and the source ValidateSets). The deployed mirror `.specify/extensions/specrew-speckit/**` is intentionally NOT synced in this worktree (Parallel-Work Charter Items 2+3 forbid touching the framework mirror + running `specrew update` mid-flight). Control: a tracked feature-closeout action (recorded in iterations/001/plan.md Notes) re-syncs the mirror at the controlled post-merge deploy; mirror parity is verified then. | `false` | Charter-sanctioned, transparent, time-bounded divergence with a concrete remediation step. Surfaced to and acknowledged by the maintainer at the before-implement gate (Alon Fliess, 2026-05-29) — the human-acknowledged deferral is recorded here, in plan.md Notes, and in drift-log.md, keeping it fully auditable without a branch-committed .squad ledger entry (which the charter forbids). | — |

## Planning Evidence Notes

- Iteration 001 scope: T001–T010 (core package + skill target + antigravity-parity core edits). FR-006 integration smoke → iter 002; FR-008 docs → iter 003.
- The five canonical hardening concerns appear first in the required order; feature-specific concerns (design/maintainability/launch-correctness/concurrency/mirror-parity) follow.
- **Mirror-parity deferral**: `mirror-parity-integrity` is `addressed` via a tracked post-merge closeout action (the `.specify/` mirror sync of the FR-003 source edit). The deferral was surfaced to and acknowledged by the maintainer at before-implement; it is documented in plan.md Notes + drift-log.md. It is classified `addressed` (not `deferred-with-approval`) because the Parallel-Work Charter forbids committing the `.squad/decisions.md` ledger entry that `deferred-with-approval` requires on this branch — the control and human acknowledgement are nonetheless fully recorded.
- DRIFT-001 / DRIFT-002 / DRIFT-003 recorded in iterations/001/drift-log.md and reconciled in-iteration.

## Hardening-Gate Status

**Overall Verdict**: ready — all material risks for the iteration-001 slice are addressed or not-applicable; the one charter-driven deferral (mirror parity) is addressed via a tracked, human-acknowledged feature-closeout action.

**Scope**: Iteration 001 — Cursor host package (manifest + 5 contract functions + skill-root entry + FileList + registry verification + antigravity-parity ValidateSets + registry fractional-priority sort fix), ~6 story_points.
