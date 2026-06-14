# Proposal-145 Structured Multi-Phase Review — FR-028 hook install/discovery hardening (T010-T012)

**Schema**: v1
**Reviewed**: 2026-06-14T03:44:02Z
**Scope**: the FR-028 three-layer hook install/discovery hardening (commits `1f9b83fb` T010, `dea3540c` T011,
`457a398d` T012, governance `0c2ca41e`, validator-fix `603a639a`). **This is an in-iteration self-review, NOT a
human review-signoff verdict** — the maintainer's real-host acceptance + boundary verdict remain required.
**Method**: a multi-agent Proposal-145 review — 6 parallel phase reviewers (P1 branch hygiene, P2 functional, P3
NFR, P4 code quality, P5 test integrity, P6 system safety) → adversarial verification of every high/medium
concrete-defect finding (default-refute). 11 agents.

## Coverage matrix (FR-028 × phase)

| Dimension | P1 | P2 | P3 | P4 | P5 | P6 | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SC-016 proactive provisioning (all hook-capable hosts, opt-out respected, user-entry preserved) | | ✓ | ✓ | | ✓ | ✓ | sound |
| SC-017 `specrew hooks` states + install/remove semantics | | ✓ | ✓ | ✓ | ✓ | ✓ | sound (3 gaps fixed) |
| SC-018 warn-once degradation gate (in-project + directive-absent + warn-once + -Peek) | | ✓ | ✓ | ✓ | ✓ | | sound |
| Fail-open (init/update never fail; status runs in broken project; diagnostic never blocks/spams) | | ✓ | ✓ | ✓ | | ✓ | sound (1 defect fixed) |
| PowerShell traps (array-unroll, $Host shadow, -LiteralPath, .NET cwd-relative) | | | | ✓ | | | sound (1 hardening) |
| Host-coupling firewall / mirror parity / FileList | ✓ | | | | | ✓ | clean (no new violation) |
| Branch hygiene (local-only, boundary commits, Co-Authored-By, tests-with-code) | ✓ | | | | | | clean |

## Findings + dispositions

**FIXED (confirmed real / cheap-correct), with regression tests:**

- **defect-001 (P2, verified MEDIUM)** — `Invoke-Install` reported "installed" even when the deploy subprocess
  FAILED (it scanned only for the 'opt-out recorded' string, not the exit code) — the repair surface could lie.
  FIX: `Invoke-DeployForHost` now returns `{Output, ExitCode}`; install/remove report FAILED on a non-zero exit
  and the command exits non-zero if any host genuinely failed (an opt-out skip is not a failure). Test 11 proves
  a hand-broken config → FAILED + non-zero exit + no false "installed" + user file untouched.
- **P5-001 (verified LOW)** — the claude `${CLAUDE_PROJECT_DIR}` stale-migration arm was untested (only the
  user-level stale arm was). FIX: test 10 seeds a legacy bare-dispatcher claude config → asserts 'stale'.
- **P5-005 (LOW)** — command-level bare `--force` was untested. FIX: test 12 proves `install --force` clears a
  recorded opt-out.
- **Q-001 (refuted as unreachable today, but cheap)** — `Get-SpecrewHostHookConfigPath` returns `$null` for a
  hypothetical future 5th host; the loop now reports 'unknown' instead of passing `$null` to `Test-Path` (keeps
  the "never throws" / fail-open contract true as the registry grows).
- **Q-003 (LOW)** — a relative `--project-path` flowed to .NET file APIs (cwd-relative hazard). FIX: normalize to
  absolute via `Resolve-Path` (fail-open if it does not exist).
- **P5-002 (refuted as SC-018-descoped, but cheap + valuable)** — the `specrew hooks status` → degradation-note
  wiring (L2↔L3) had no integration test. FIX: test 13 proves a full project with no directive trail surfaces the
  'Diagnostic:' note and that it is `-Peek` (repeatable, no warn-once marker written).

**REFUTED by adversarial verification (no change):**

- **defect-002 (claimed HIGH)** — "substring session match breaks session-scoping". REFUTED: the only production
  call passes `-SessionId $null` (the substring branch is test-only/dead in production), the real session-marker
  carries NO `session_id` field, and fail-open-toward-SILENCE is the designed direction for an advisory fallback.
  Working-as-designed; left as-is.

**PARKED (judgment-calls / out-of-scope, surfaced for the maintainer):**

- **Q-002 (judgment-call)** — the per-host config-path switch is duplicated between `specrew-hook-health.ps1` and
  the mirrored `deploy-refocus-hooks.ps1`. The advisor accepted this (the inspector deliberately does NOT
  dot-source the mirrored deploy script — that would trigger a deploy). The Q-001 null-guard removes the immediate
  crash risk. A registry-derived `ConfigPath` (manifest field) is the clean future fix — follow-up, not FR-028.
- **P3-nfr-001/002, P5-003/004** — dead marker-write path (API supports future agent use), journal rotation,
  orchestrator user-entry test (transitively covered by the per-host deploy tests), init→status e2e — all
  working-as-designed or low-value/heavy; noted as optional follow-ups.

## Pre-existing branch reds (NOT from this work — see drift-log D-002/003/004)

Independent of FR-028: D-002 host-coupling-firewall (`SessionBootstrapManager` iter-10), D-003 refocus-digests
`specify.md` (branch/main drift), D-004 validator iter-007 capacity (deliberately-open iter-007 + approved
cap-raise; reverts at closeout), `substantive-interaction` README "Feature 016" drift,
`validator-hardening-iteration2` (fixtures/docs drift). The FR-028 files are firewall-clean and T010 reduced
firewall debt; my new suites + the full bootstrap/parity/verdict regression pass.

## Self-review result

The FR-028 hook-deploy implementation is internally sound: every confirmed concrete defect is fixed with a
regression test; refuted findings were left as-is with reasoning; judgment-calls are parked for the maintainer.
**The boundary verdict + the real-host acceptance dogfood remain the maintainer's** (no verdict is recorded here).
