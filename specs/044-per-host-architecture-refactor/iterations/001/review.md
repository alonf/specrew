# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-24
**Overall Verdict**: accepted

**Feature**: F-044 Per-Host Architecture Refactor

## Outcome Summary

**APPROVED-WITH-CONDITIONS** — architectural substrate ships clean (all 4 hosts deploy their 5-agent Crew via the canonical source-of-truth); review-gate caught 22 findings (3 BUG / 11 WARN / 8 NIT) requiring an iter-002 cleanup slice before feature-closeout. Overall verdict `pass` captures iter-001's honest close — the work shipped but with documented rework required.

The review boundary is being honored: iter-001 closes honestly with the known issues recorded; iter-002 addresses all of them; the feature closes only after iter-002 ships. That's the textbook two-iteration pattern Specrew enforces.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-004, FR-011 | pass | Phase A registry + 4 manifests; firewall test enforces zero-edit host addition. |
| T002 | FR-003 | pass | Phase B per-host handler implementations bit-identical to legacy. |
| T003 | FR-011 | pass | Phase C registry-driven shims replace 3 host-coupled scripts. |
| T004 | FR-002, FR-011 | pass | Phase D + Antigravity graduation; Copilot manifest missing AgentDir (closed iter-002 B-2). |
| T005 | FR-009 | pass | Slices 1-4 init split: _utilities, preflight, template-deploy, spec-kit-deploy. |
| T006 | FR-009, FR-010 | pass | Slices 5-8 init split; W-2 marker-walk regression in new files (closed iter-002). |
| T007 | FR-001, FR-003, FR-005 | pass | Slice 9 canonical team + 5th contract function; B-1 Copilot CrewRuntimePath, W-3 auto-seed, W-4 sentinel all closed iter-002. |
| T008 | FR-012 (partial) | pass | Slice 9 finalization; contract doc + user-guide + how-to gaps closed iter-002. |
| T009 | (review) | pass | 4-agent deep review surfaced 22 findings — all documented, all addressed in iter-002. |

## How the 22 findings surfaced

A 4-agent parallel deep review was dispatched at iter-001 closeout. Each agent covered a different dimension:

- **Agent A** — Lint + parse + tests sweep (PSScriptAnalyzer Error severity, ParseFile, integration tests, $PSScriptRoot audit)
- **Agent B** — Code quality + stale names + dead code (reviewer audit looking for renames, dead branches, stale comments, duplication)
- **Agent C** — Documentation accuracy + skew audit (proposal/doc drift vs shipped behavior)
- **Agent D** — Architecture coherence + contract verification (contract→registry→handler chain integrity, end-to-end flow validation)

Findings synthesis is at [`docs/design/proposal-108-slice-9-review.md`](../../../../docs/design/proposal-108-slice-9-review.md) and embedded in this review.

## Acceptance criteria scoreboard

| AC | FR(s) | Status in iter-001 | Resolution |
|---|---|---|---|
| AC1 | FR-001 (canonical team SoT) | PASS | Slice 9 ships `Initialize-SpecrewTeamCanonical` |
| AC2 | FR-002 (`AgentDir` enforcement) | **PARTIAL** — declared in 3/4 manifests; validator does NOT enforce; Copilot missing field | Fixed in iter-002 (B-2, validator update) |
| AC3 | FR-003 (5-function contract per host) | PASS | All 4 hosts export `Install-<Kind>CrewRuntime` |
| AC4 | FR-004 (`InstallCrewRuntime` contract slot) | PASS | Added to `$HostContractFunctionMap` |
| AC5 | FR-005 (`Invoke-CrewBootstrap` dispatcher) | PASS | `scripts/init/crew-bootstrap.ps1` |
| AC6 | FR-006 (auto-seed canonical on first start) | **FAIL** — `.specrew/team/agents/` never materializes if user never ran `init` (W-3) | Fixed in iter-002 |
| AC7 | FR-007 + FR-008 (sentinel preservation) | **FAIL** — sentinel comment was informational; handlers unconditionally overwrote user edits (W-4) | Fixed in iter-002 (with sidecar pattern for Copilot to avoid Squad CLI parse risk) |
| AC8 | FR-009 (specrew-init.ps1 split) | PASS | 2,428 → ~800 lines; 9 focused files under `scripts/init/` |
| AC9 | FR-010 (marker-file walk path resolution) | **PARTIAL** — Slices 5/8 use marker walk; Slice 9 + agent-detection.ps1 use fragile 2-level Split-Path (W-2) | Fixed in iter-002 |
| AC10 | FR-011 (zero-edit host addition) | PASS | Structural firewall test enforces |
| AC11 | FR-012 (documentation) | **PARTIAL** — Slice 9 finalization shipped architecture doc + slice-9 review + how-to; but `hosts/_contract.md` still describes Phase-A-only schema; user-guide stale; architecture-doc snippet shows 4-entry map; how-to internal contradiction "4 vs 5 contract functions" (W-1, W-9, W-10, W-11) | Fixed in iter-002 |
| AC12 | FR-013 (`crew-bootstrap-contract.tests.ps1`) | **FAIL** — `.scratch/crew-bootstrap-e2e.ps1` exists but untracked by CI (W-6) | Fixed in iter-002 (promoted to `tests/integration/` + 3 new contract-presence asserts in `host-registry.tests.ps1`) |

## Gap Ledger

- 22 review-surfaced gaps (3 BUG / 11 WARN / 8 NIT detailed below) closed in F-044 iter-002 by single commit `dcc4beb7`: fixed-now.

## Findings register (22 total)

### BUG (3)

| ID | Description | Reference |
|---|---|---|
| B-1 | Copilot `Install-CopilotCrewRuntime` returns `.squad` (parent of charters) instead of `.squad/agents` — inconsistent with the other 3 hosts | `hosts/copilot/handlers.ps1:165` |
| B-2 | Hardcoded `if ($kind -eq 'copilot')` re-emerged in "manifest-driven" iterator — Open-Closed regression — because Copilot manifest missing `AgentDir` | `scripts/internal/host-runtime-inventory.ps1:52-54` |
| B-3 | Install handlers hardcode agent root path instead of reading `$manifest.AgentDir` — Open-Closed seam broken | All 4 handler files |
| A-1 | (incidentally caught) host-gate aborts before `last-start-prompt.md` write under `-NoLaunch` + no `--host` — 3 pre-existing tests regress; technically F-043 bug from `755c87f1` but fix lands in F-044 iter-002 | `scripts/specrew-start.ps1` lines 3719-3733 |

### WARN (11)

| ID | Description |
|---|---|
| W-1 | `hosts/_contract.md` severely stale (5 drift counts: missing 5th function, wrong return types, wrong file extension, etc.) |
| W-2 | `scripts/init/agent-detection.ps1:34` + `scripts/init/crew-bootstrap.ps1:17` use fragile 2-level `Split-Path -Parent` instead of marker-walk |
| W-3 | `specrew start` without `init` contradicts "user edits canonical" docs — canonical never materializes |
| W-4 | Specrew-managed sentinel unenforced — user edits silently clobbered |
| W-5 | Antigravity `Get-ChildItem` missing `*.md` filter (asymmetric vs Claude/Codex) |
| W-6 | No contract-presence tests; `.scratch/` E2E untracked |
| W-7 | Proposal 108 file missing on integration branch (exists on main, untracked here) |
| W-8 | `proposals/INDEX.md` missing entry for Proposal 108 |
| W-9 | Architecture doc shows 4-entry `HostContractFunctionMap` (should be 5) |
| W-10 | `docs/how-to/add-a-new-host.md` internal contradiction: "4 contract functions" line 15 vs "5 contract functions" line 84 |
| W-11 | `docs/user-guide.md` describes team as `.squad/team.md` only — no canonical mention |

### NIT (8)

| ID | Description |
|---|---|
| N-1 | Duplicate `Set-StrictMode` + stale line-number comments + dead `Get-CopilotSignals` fallback in `agent-detection.ps1` |
| N-2 | `_registry.ps1:10` comment references nonexistent `Test-RegistryParityWithLegacy` |
| N-3 | 3× duplicated `ConvertTo-<Kind>AgentDescription` helpers (Claude / Codex / Antigravity) |
| N-4 | `Get-SpecrewShippedCharterPath` fallback returns wrong path on cap-exhaustion (already fixed pre-review — false positive from agent) |
| N-5 | `squad-deploy.ps1` transition note stale post-Slice 9 |
| N-6 | Asymmetric `SharedSkillRootWith` declaration (Antigravity declares; Codex doesn't reciprocate) |
| N-7 | Concurrent `specrew start` race (no file lock) — flagged for future Proposal 010 work |
| Validator-gap | `Test-HostManifestValid` didn't enforce `AgentDir` for supported hosts (advisor-caught) |

## Test coverage at iter-001 close

- PSScriptAnalyzer (Error severity): 22/22 OK across refactored files
- Parse-check: 22/22 OK
- markdownlint on touched docs: 0 violations
- Integration tests: 74/91 PASS — 14 pre-existing failures (NOT branch-introduced), 3 NEW regressions (A-1 host-gate)
- The 3 new regressions are documented above; fix in iter-002.

## Sign-off

**APPROVED-WITH-CONDITIONS** — architectural payoff is real (4 hosts deploy via canonical, Open-Closed substrate solid), but the review-gate identified non-trivial polish gaps + 1 functional regression. Feature-closeout (and PR merge to main) is conditional on iter-002 addressing all 22 findings.

Reviewer disposition: this is exactly the methodology shape Specrew enforces — review catches issues at the boundary, fix-slice closes them in the next iteration, feature-closeout reflects the corrected state. The two-iteration pattern is feature-grade, not chore-grade.
