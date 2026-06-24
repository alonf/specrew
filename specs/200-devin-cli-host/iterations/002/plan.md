# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 19/20 story_points
**Started**: 2026-06-24

## Scope Summary

Iteration 002 delivers **Slice C-1**: the deterministic `hosts/devin/` package
and runtime spine, landing Devin as a discoverable but `experimental` host.
Everything in this iteration is provable with deterministic PowerShell fixtures
on any CI runner. Full Slice C re-estimated at ~29 SP (over the 20 cap), so it is
split at the **live-host firewall** seam (see Split Rationale): the live pinned-
build evidence (FR-021), the FR-011 canary rerun, the `sh.exe`->`pwsh` attempt,
and the experimental->supported promotion move to **iteration 003 (Slice C-2)**;
Slice D (FR-013–FR-016) moves to **iteration 004**.

| Requirement (clause) | Summary | Stories |
| --- | --- | --- |
| FR-005 | `hosts/devin/` manifest + coordinator rules; registry discovery/validation with no shared-core Devin branch. | US1, US2 |
| FR-006 | Tested-build/compat metadata; `Status=experimental`; promotion-gate metadata. | US6 |
| FR-007 | Interactive launch (positional bootstrap) + permission flag translation (auto/smart/dangerous, dangerous precedence + notice). | US1 |
| FR-008 | Five-handler contract; root `AGENTS.md` dedup; dual skill surface; nested `.devin/agents/<name>/AGENT.md` Crew runtime. | US1, US5 |
| FR-009 | Generic host-neutral root-level direct-event-map hook ConfigShape + Devin `.devin/hooks.v1.json` bindings. | US1, US5 |
| FR-010 | Manifest `SpeckitAiFlag = devin` (no shared-core conditional). | US1 |
| FR-011 (in-package) | Production in-package ATIF->Claude-like-JSONL normalizer; deterministic replay of the spike-proven path through the unchanged parser. | US4 |
| FR-012 | Parser-collision boundary guard: accessor zero-diff + unchanged parser consumes normalized JSONL. | US4 |
| FR-016 (start clause) | `specrew start` discovers Devin via the registry, not a hardcoded host list. | US1 |
| FR-017 (deterministic) | Hook-merge user preservation; refuse unreadable config; redaction of prompts/transcripts/credentials from evidence/logs. | US5 |
| FR-018 | The five existing hosts + unchanged parser goldens stay green across registry/launch/hooks/instructions/Crew/coordinator. | US2, US5 |
| FR-019 (deterministic gates) | CI registry/manifest, multi-host launch, firewall, FileList parity gates incl. Devin package membership. | US2 |

**Deferred to iteration 003 (Slice C-2)**: FR-021 (seven live pinned-build
checks + promotion), FR-011 canary rerun, FR-017 live security/diagnostics
evidence, FR-019 cross-platform/prepublish live wiring, the `sh.exe`->`pwsh`
host-neutral attempt, and the experimental->supported flip.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- | ---: | --- |
| T007 | Devin package skeleton: manifest + coordinator-rules; registry discovery/validation; `SpeckitAiFlag=devin`; `Status=experimental` + tested-build/compat metadata | FR-005, FR-006, FR-010 | US1, US6 | 2 | Implementer | hosts/devin/host.psd1; hosts/devin/coordinator-rules.psd1; tests/integration/** | planned | | | |
| T008 | In-package ATIF->Claude-like-JSONL handover normalizer (production `DevinHandoverAdapter`); deterministic replay of spike fixture through unchanged parser | FR-011 | US4 | 3 | Implementer, Reviewer | hosts/devin/**; specs/200-devin-cli-host/iterations/002/research/**; tests/integration/** | planned | | | |
| T009 | Parser-collision boundary guard: assert `ConversationCaptureAccessor.ps1` zero-diff + unchanged parser consumes normalized JSONL | FR-012 | US4 | 1 | Implementer, Reviewer | tests/integration/** | planned | | | |
| T010 | Five-handler contract: `New-DevinLaunchInvocation`, `ConvertTo-DevinFlag` (interactive positional; normal->auto / autopilot->smart / allow-all->dangerous, dangerous precedence + notice), `Test-DevinRuntimeInstalled`, `Get-DevinSignals`, `Install-DevinCrewRuntime` (nested `.devin/agents/<name>/AGENT.md`) | FR-007, FR-008 | US1 | 3 | Implementer | hosts/devin/handlers.ps1; tests/integration/** | planned | | | |
| T011 | Instructions + skills surfaces: root `AGENTS.md` dedup; `.devin/skills/` + shared `.agents/skills/` via `SkillRoot`/`SharedSkillRootWith` | FR-008 | US1, US5 | 2 | Implementer | hosts/devin/host.psd1; tests/integration/** | planned | | | |
| T012 | Generic host-NEUTRAL root-level direct-event-map hook ConfigShape in deployer + Devin `RefocusHookBindings` (`.devin/hooks.v1.json`, `DEVIN_PROJECT_DIR`, SessionStart/UserPromptSubmit/Stop, decision-block Stop, merge-only/preserve-user-entries) | FR-009 | US1, US5 | 3 | Implementer, Reviewer | scripts/internal/deploy-refocus-hooks.ps1; scripts/internal/specrew-hook-health.ps1; hosts/devin/host.psd1; tests/integration/** | planned | | | |
| T013 | Deterministic security/diagnostics + registry-driven start tests: hook-merge preserves user entries, refuses unreadable config; evidence/log redaction; `specrew start` registry-driven (no hardcoded host list) | FR-017, FR-016 | US1, US5 | 2 | Implementer, Security Reviewer | tests/integration/**; scripts/specrew-start.ps1 | planned | | | |
| T014 | Existing-host compatibility regression backstop: five existing hosts + unchanged parser goldens stay green across registry/launch/hooks/instructions/Crew/coordinator after the T012 shared-seam change | FR-018 | US2, US5 | 2 | Implementer, Reviewer | tests/integration/**; tests/unit/** | planned | | | |
| T015 | Iteration review, traceability, drift-log, expected-rework reserve | SC-012 | US1, US4, US5 | 1 | Reviewer, Spec Steward | specs/200-devin-cli-host/iterations/002/**; tests/** | planned | | | |

## Split Rationale

- **Full Slice C ~29 SP** (FR-005–FR-012 + FR-016/017/018/019/021 contributions),
  re-estimated above the design-analysis 15 SP because it folds in the production
  ATIF normalizer (the spike used a scratch one), the generic FR-009 deployer
  extension, and FR-021's seven live checks plus the `sh.exe`->`pwsh` attempt.
- **The seam is the live-host firewall, not "foundational vs integration."**
  FR-021 cannot run until the package physically exists AND must not be mocked
  (TG-005 + the Feature-197 "don't mock real-host behavior" lesson). That is the
  hard cut: iteration 002 is everything deterministically testable in CI on any
  runner; iteration 003 is everything requiring the actual pinned binary
  `devin 2026.7.23 (3bd47f77)` and the human promotion verdict.
- **Clause-level FR splits** (so no task half-claims an FR): FR-011 in-package
  normalizer/replay -> 002, canary rerun -> 003; FR-016 `specrew start` clause ->
  002, `specrew update`/managed-config clause -> Slice D (004); FR-017
  deterministic tests -> 002, live evidence -> 003; FR-019 deterministic gates ->
  002, cross-platform/prepublish-live wiring -> 003.

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Hard cap confirmed by the maintainer. |
| Iteration Bounding | scope | Scope fixed to Slice C-1; live-host work is iteration 003. |
| Time Limit (hours) | n/a | Not time-bounded. |
| Overcommit Threshold | 1.0 | Any plan above 20 SP requires a human split/defer decision. |
| Defer Strategy | manual | Do not silently move or add requirements. |
| Calibration Enabled | true | Retro records actual effort and planning variance. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
  (plus Security Reviewer checkpoints on T012/T013).
- Sequencing: **T007 (skeleton) -> T008/T009 (FR-011 de-risk) -> T010/T011
  (handlers + surfaces) -> T012 (hook seam) -> T013 (security/start) -> T014
  (compat backstop) -> T015 (review)**. Execute serially.
- Shared-surface conflict risk: high around `scripts/internal/deploy-refocus-hooks.ps1`
  (the only shared-core change, T012) and `tests/integration/`. No review fan-out
  that can change authorship without verification (Slice A concurrency lesson).
- Reviewer checkpoints after T012 (shared seam) and T014 (compatibility).

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | ---: | --- |
| Package skeleton + metadata | 2 | T007. |
| Handover normalizer + collision guard | 4 | T008, T009 — FR-011 proven path, no re-spike. |
| Handlers + instruction/skill surfaces | 5 | T010, T011. |
| Generic hook seam (host-neutral) | 3 | T012 — the only shared-core change. |
| Deterministic security + compat backstop | 4 | T013, T014. |
| Review and traceability | 1 | T015. |
| **Total** | **19** | 1 SP headroom under the 20 cap. |

## Required Quality Gates

| Required Quality Gate | Category | Evidence Source |
| --- | --- | --- |
| host-package-contract | mechanical | Registry discovers/validates `hosts/devin/` (manifest, five handlers, coordinator rules) with no shared-core Devin branch. |
| handover-normalizer-parser-collision | mechanical | In-package ATIF->JSONL replay consumed by the unchanged parser; `ConversationCaptureAccessor.ps1` zero-diff. |
| host-purity-firewall | mechanical | Planted `devin` literal on the FR-009 shared seam fails; no-adapter host preserves exact pre-feature hook output. |
| hook-merge-safety | mechanical | Merge preserves non-Specrew entries; refuses to overwrite unreadable config; redaction holds. |
| existing-host-compatibility | mechanical | Five existing hosts + transcript-parser goldens stay green (SC-005). |
| ci-deterministic-gates | tooling | Registry/manifest, multi-host launch, firewall, FileList parity incl. Devin package. |

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: Iteration 002 Devin package, runtime spine, in-package
handover normalizer, host-neutral hook seam, and deterministic CI gates.

**Hardening Gate Artifact**: `specs/200-devin-cli-host/iterations/002/quality/hardening-gate.md`

- This gate **re-addresses the adapter-seam purity concern** carried forward from
  iteration 001 (`future-adapter-contract` / `host-adapter-seam-purity-and-compatibility`):
  a planted host-specific literal on the FR-009 seam MUST fail (T012), and a
  package with no adapter MUST preserve exact pre-feature behavior (T014).
- The later live-host validation (FR-021) repeats on the actual pinned build at
  its own iteration 003 hardening gate.

## Traceability Summary

- Requirement scope (002): FR-005, FR-006, FR-007, FR-008, FR-009, FR-010,
  FR-011 (in-package), FR-012, FR-016 (start clause), FR-017 (deterministic),
  FR-018, FR-019 (deterministic gates).
- Success criteria represented: SC-001 (partial, deterministic surfaces),
  SC-005, SC-007 (in-package handover), SC-009, SC-012.
- User stories represented: US1, US2, US4, US5, US6 (metadata).
- Capacity check: 19/20 story_points; 1 SP headroom is NOT permission to pull
  iteration 003/004 work forward.
- Split guard: no live-host evidence, promotion, `sh.exe`->`pwsh` attempt, Slice D
  coordinator/migration, or docs-rollout work enters iteration 002 unless the
  human explicitly re-baselines.

## Notes

- Design-analysis verdict: `approved for plan with Option B` (three-iteration
  split; now four iterations after the Slice C split confirmed at this plan).
- FR-011 is spike-resolved (outcome 2): the in-package normalizer implements the
  proven path; the spike's `UNCHANGED_PARSER_CAPTURE_PASS` is replayed
  deterministically. No re-spike.
- FR-012: `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` remains
  forbidden to edit throughout the feature.
- The only shared-core change is the generic root-level direct-event-map
  ConfigShape in `deploy-refocus-hooks.ps1` (T012); it stays host-neutral and is
  firewall-covered (no `devin` literal in shared code).
- Devin ships `experimental` in this iteration by design: the Windows `sh.exe`
  hook-runner prerequisite is unresolved and its host-neutral `pwsh` attempt +
  live validation are iteration 003.

## Risks (for the before-implement gate)

1. **T012 shared-seam regression (highest)**: the deployer today always wraps the
   event map under `hooks` and treats a root-level map only as a legacy-migration
   source. Adding a steady-state root-level variant touches code all five hosts
   depend on. T014 is the backstop; reviewer checkpoint after T012 is mandatory.
   If the generic variant needs more than a focused addition, this could bust the
   20 cap -> drift-log + human verdict.
2. **Devin Crew nested shape**: `Install-DevinCrewRuntime` writes
   `.devin/agents/<name>/AGENT.md` (per-agent subdirectory), unlike claude's flat
   `<role>.md`. The write-path is owned in-package (no shared-core change);
   confirm the canonical role helpers need no change.
3. **Only 1 SP headroom**: any discovered work risks the cap. The defer valve is
   the documented FR-019/FR-017-live -> 003 boundary; do not pull 003 forward.
4. **`sh.exe` prerequisite deferred**: 002 ships a deterministically-green but
   `experimental` package whose Windows hooks may not fire live until the 003
   `pwsh` attempt validates. Confirm the maintainer accepts this.
5. **FR-018 parser-golden scope**: T014 must explicitly include the transcript-
   parser goldens, since T008's normalizer feeds the same parser. Golden drift
   here is a Feature-197-ownership collision signal -> stop for verdict.
