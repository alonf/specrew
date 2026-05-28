# Drift Log: Iteration 001

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 4
**Resolution rate**: 100% (4/4 resolved)
**Specification drift**: 4 events (FR-004/SC-006 blast-radius, registry sort defect, test-file naming, interactive-launch/runtime-detection contract) — all reconciled

## Events

### DRIFT-001 — FR-004/SC-006: host addition requires edits to allow-listed core scripts (NOT "no core edits")

- **Detected**: 2026-05-29, during implementation reconnaissance (antigravity-parity grep).
- **Spec claim**: FR-004 "auto-discover ... without requiring manual registry code changes"; SC-006 "scales to new hosts without requiring framework refactors"; plan implied blast radius confined to `hosts/cursor/` + one sanctioned `Get-ActiveSkillRoots` edit.
- **Empirical reality**: adding a host (mirroring the most-recent host, antigravity) touches ~10 production files beyond `hosts/cursor/`: `scripts/specrew-start.ps1` (`-HostKind` ValidateSet at :3465 rejects unknown kinds at param-binding before the registry sees them), `scripts/internal/host-flag-translation.ps1`, `scripts/internal/coordinator-prompt-surgery.ps1`, `scripts/internal/detect-hosts.ps1`, `scripts/internal/host-history.ps1`, `scripts/init/agent-detection.ps1`, `scripts/init/post-bootstrap-output.ps1`, `Specrew.psd1`, plus ~7 test files. These are the "LAST remaining intentional hardcodes" the firewall test allow-lists for Phase-D cleanup.
- **Resolution**: `human-decision` (advisor-confirmed) + `spec-updated`. This is NOT a contradiction — it is the documented, finite per-host cost (antigravity already lives in those ValidateSets); FR-004 is *literally* true (`hosts/_registry.ps1` needs no registration edit) and adding an enum value to an allow-listed deferred hardcode is not a framework refactor. The ValidateSet files are product source under `scripts/` (NOT `.specify/extensions/specrew-speckit/**`), so editing them is not a Parallel-Work Charter Item-2 violation. **SC-006 nuance recorded for review/retro**: the "just create `hosts/<kind>/`" promise is aspirational; the true per-host integration cost is ~17 files. Candidate follow-up: Phase-D ValidateScript refactor to make these registry-driven (proposal, not in-place here).

### DRIFT-002 — registry MenuPriority sort uses `[int]`, incompatible with spec-mandated fractional `1.5`

- **Detected**: 2026-05-29, reading `hosts/_registry.ps1:77`.
- **Spec claim**: FR-001 + US4 acceptance scenario 2 + SC-002 require `MenuPriority = 1.5` placing Cursor between Claude (1) and Codex (2).
- **Empirical reality**: `hosts/_registry.ps1:77` computes `$priority = [int]$manifest.MenuPriority`. `[int]1.5 = 2` (PowerShell banker's rounding) → cursor ties codex and `Sort-Object Priority, Kind` orders it AFTER codex (claude, codex, cursor, copilot, antigravity), silently violating the spec ordering. `host-registry.tests.ps1:43` has the same `[int]` cast.
- **Resolution**: `spec-updated` (spec-honoring defect fix) — change the registry sort cast (and the test assertion) from `[int]` to `[double]` so fractional priorities sort correctly. This is a latent defect fix (the manifest schema permits decimal MenuPriority; the sort never supported it), NOT host registration — FR-004's auto-discovery promise is unaffected. Recorded as a second SC-006 finding (the architecture had a latent fractional-priority gap exposed by the first non-integer host).

### DRIFT-003 — test-file naming: spec named non-existent paths

- **Detected**: 2026-05-29, locating host tests.
- **Spec claim**: FR-005 `tests/hosts/cursor.tests.ps1`; FR-007 `tests/integration/multi-host-detection.tests.ps1`.
- **Empirical reality**: there is no `tests/hosts/` directory and no `multi-host-detection.tests.ps1`. The established convention is `tests/integration/host-*.tests.ps1` (custom `Write-Pass`/`Write-Fail` scripts, not Pester `Describe/It`). The real files needing cursor coverage/updates are `host-registry.tests.ps1`, `crew-bootstrap-contract.tests.ps1`, `host-coupling-firewall.tests.ps1`, `host-detection-ux.tests.ps1`, `multi-host-launch-path.tests.ps1`, `post-bootstrap-output.tests.ps1`, `non-specrew-session-bypass.tests.ps1`.
- **Resolution**: `spec-updated` — new cursor unit tests land at `tests/integration/host-cursor.tests.ps1` (convention-aligned, discovered); existing host tests are updated for the 5-host reality. FR-005 path reconciled in tasks.md; FR-006/FR-007 iter-002 filenames noted for that iteration.

### DRIFT-004 — interactive-launch + AgentDir-runtime-detection contract (caught at review-signoff by independent cross-reviewer)

- **Detected**: 2026-05-29, independent cross-reviewer at review-signoff (review-signoff DECLINE).
- **Spec claim (clarify-time guess)**: launch = non-interactive `cursor-agent --print --workspace <project> "<prompt>"`; `--allow-all`→`--force --trust`; `Test-CursorRuntimeInstalled` = binary/PATH probe.
- **Empirical reality (implemented + correct)**: `specrew start` launch is INTERACTIVE `cursor-agent "<prompt>" --workspace <path>` (matching claude/codex/antigravity — `--print` is headless one-shot, wrong for a lifecycle session); `--allow-all`→`--force` only (`--trust` is headless-only per `cursor-agent --help`, unused); `Test-CursorRuntimeInstalled` detects `.cursor/rules/*.mdc` (AgentDir detection per host-package contract, mirroring codex/antigravity — binary-on-PATH is the separate `Test-SpecrewHostAvailable`).
- **Why it happened**: the interactive + AgentDir-detection corrections were made during implementation (correct against the host-package contract + sibling hosts) but NOT propagated back to spec/contract/plan/tasks/data-model/quickstart/review-diagrams — a Rule-34 (spec-authoritative) reconciliation miss that the cross-reviewer correctly flagged as a blocking authority mismatch.
- **Resolution**: `spec-updated` — the authoritative artifacts (spec Clarifications + FR-002/FR-011 + Assumptions, contracts/cursor-host.md, plan.md feature + iteration, tasks.md, data-model.md, quickstart.md, review-diagrams.md, checklists) were all reconciled to bless the (correct) interactive + AgentDir-detection contract. The `--print` finding is retained where it belongs: it proves CLI-drivability and gates `Status=supported`, but is not the launch shape. Implementation/tests unchanged (they were already correct).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.