# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-01
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-001 | FR-002, FR-013 | pass | `specrew-init.ps1` now probes prerequisite commands before bootstrap and distinguishes missing, broken, and incompatible dependency states. |
| T-002 | FR-002 | pass | `specrew-init.ps1` installs missing Spec Kit and Squad CLIs through `uv` and `npm`, then re-validates the tools before continuing. |
| T-003 | FR-002, FR-011 | pass | The bootstrap path runs `specify init` for greenfield setup and preserves existing downstream `.specify` state instead of overwriting it. |
| T-004 | FR-002 | pass | The bootstrap path runs `squad init --non-interactive` when supported and falls back to direct `.squad` scaffolding only when the CLI lacks that path. |
| T-005 | FR-002, FR-001 | pass | Specrew's Spec Kit extension is deployed into downstream `.specify/extensions/` and the `-SpecKitExtensionOnly` slice is supported for targeted bootstrap. |
| T-006 | FR-002, FR-001 | pass | `deploy-squad-runtime.ps1` copies the active Specrew skills into downstream `.copilot/skills/specrew-*` without promoting deferred sources into runtime. |
| T-007 | FR-002, FR-001 | pass | `deploy-squad-runtime.ps1` appends Specrew Planning and Review/Demo ceremony entries into downstream `.squad/ceremonies.md` additively. |
| T-008 | FR-002, FR-004 | pass | The bootstrap runtime merges the five baseline roles into downstream `.squad/team.md` and creates the matching baseline charter structure. |
| T-009 | FR-002, FR-011 | pass | Governance scaffolding now produces downstream `.specrew/config.yml`, `constitution.md`, `iteration-config.yml`, and `role-assignments.yml` without clobbering reruns. |
| T-010 | FR-002, FR-013 | pass | `validate-versions.ps1` and `specrew-init.ps1` normalize version-probe failures into actionable remediation, including dry-run-safe reporting. |
| V-R7-1 | FR-022 | pass | `research.md` documents the live Copilot and delegated-agent detection surface, including `copilot help config` and graceful degradation when metadata is unavailable. |
| T-011 | FR-022 | pass | `specrew-init.ps1` detects Copilot-accessible agents, supports interactive and non-interactive consent, and persists the resulting agent state into `iteration-config.yml`. |
| T-012 | FR-008, FR-018 | pass | The `specrew-drift-check` skill requires requirement-cited evidence, supports the defined resolution paths, and emits drift-log-ready output. |
| T-013 | FR-003, FR-004 | pass | The `spec-authority.md` directive is present and `deploy-squad-runtime.ps1` merges it into the downstream Spec Steward charter. |
| T-014 | FR-006, FR-018 | pass | The `traceability.md` directive is present and merged into the downstream Planner charter to gate planning before execution starts. |
| T-015 | FR-008, FR-018 | pass | The `drift-reporting.md` directive is present and merged into downstream Implementer and Reviewer charters, including the review-time batch fallback. |
| T-016 | FR-005, FR-006 | pass | `planning.md` plus `scaffold-iteration-plan.ps1` provide the planning ceremony path: the helper seeds a contract-aligned stub and the ceremony requires replacement with a traced task table before approval. |
| T-017 | FR-005, FR-009 | pass | `review-demo.md` plus `scaffold-review-artifact.ps1` seed a contract-valid `review.md` from `plan.md` and define the per-task and overall verdict flow. |
| T-018 | FR-005, FR-010 | pass | `retro.md` guidance and `scaffold-retro-artifact.ps1` integrate Specrew's retrospective requirements into Squad's built-in retrospective ceremony with proper review gating. |
| T-019 | FR-018 | pass | `scaffold-iteration-artifacts.ps1` creates the iteration directory along with contract-aligned `state.md` and `drift-log.md` without overwriting existing work. |
| T-020 | FR-002, FR-005 | pass | `docs/getting-started.md` and `docs/user-guide.md` now describe the downstream bootstrap and lifecycle flow using the installed helper paths and current script interfaces. |
| T-021 | FR-005, FR-006 | pass | `bootstrap-to-iteration.ps1` now bootstraps a fresh downstream project, creates a spec, scaffolds a traceable iteration plan through the installed helper path, and carries the sample iteration through review and retro artifact generation; the script shape and CI wiring close the prior gap even though this local shell skipped runtime execution because `squad` is unavailable here. |
| T-022 | FR-008, FR-009 | pass | `drift-scenario.ps1` now exercises the real `drift-diff.ps1` helper, proves contradicting executed output produces drift, and verifies the resolved output clears drift before retro starts. |
| T-023 | FR-013 | pass | `.github/workflows/specrew-ci.yml` now runs markdown lint, PowerShell lint, governance validation, and both integration scripts with the required CLI toolchain installed first. |
| T-024 | DD-366, DD-369, DD-371, DD-373 | pass | `.github/scripts/sync-specrew-board.ps1`, `.github/workflows/specrew-project-sync.yml`, and `docs/github-project.md` now codify the GitHub mirror as a derivative of local authoritative iteration artifacts. |
| T-025 | DD-369, DD-370 | pass | `.squad/protocol.md` and `docs/github-project.md` now codify the `squad/{issue-number}-{slug}` branch, optional worktree, and standard PR review path while keeping local artifacts authoritative. |

## Gap Ledger

No known gaps remain.

## Notes

- Review completed against the live tracked repo state on 2026-05-01.
- Recheck result: `drift-scenario.ps1` passed locally and `validate-governance.ps1` passed for Iteration 001.
- Recheck result: `bootstrap-to-iteration.ps1` now covers the missing downstream bootstrap -> spec -> iteration-plan -> review/retro lifecycle path; evidence comes from prior local verification and the CI-configured runtime path with the required toolchain.
- All Iteration 001 tasks pass against the current implementation and tracked artifacts.
