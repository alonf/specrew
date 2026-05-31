# Review: Iteration 001 — Session Mode Configuration & File Classification

**Schema**: v1
**Reviewed**: 2026-05-31
**Overall Verdict**: accepted

## Summary

Iteration 1 delivers the multi-session foundation's opt-in switch (US1, FR-001–003) and per-session file classification (US2, FR-004–006). All 19 tasks complete; both acceptance suites green; governance validator clean (no FAIL/medium/hard). Reviewed against the structured-reviewer bar (Props 145/140/142): branch hygiene, functional correctness, test integrity, capacity arithmetic, and cross-artifact consistency.

### Capacity arithmetic verification (Shape-9 vigilance)

Summed the per-task `[effort]` markup directly rather than trusting the summary: T001-T019 = 0.5+0.5+0.5+1.0+0.5+0.5+0.5+0.5+1.0+1.0+0.5+0.5+0.5+0.5+0.5+0.5+0.5+0.5+0.5 = **11.0 SP**. Matches the iteration plan capacity `11/20 story_points` and is within the TG-005 ≤20 SP cap. No overcommit (the D-001 class defect does not recur here).

### Branch hygiene (Phase 1)

HEAD == `origin/051-multi-session-foundation` at `4141a892` (no working-tree-only evidence — Shape 5 clear). Every file cited below is committed. Out-of-scope working-tree drift (`.claude/agents/*.md` auto-deploy churn) is classified + parked per state.md, to be handled at the next boundary commit.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001 | pass | Both new scripts registered in `Specrew.psd1` FileList (alphabetical); FileList↔disk parity verified bidirectionally (recurring-omission guard). |
| T002 | FR-001 | pass | `session_mode` key added to config.yml template; read path returns it via `Get-SessionMode`. |
| T003 | FR-004 | pass | Classification schema is the data-driven `Get-FileClassification` rule set (4 categories); per D-002 idiom, not a separate `.specify/config.yml`. |
| T004 | FR-001, FR-002 | pass | `Set-SessionMode` validates `single`/`multi` (throws on invalid, no mutation), atomic write-temp-rename per research R3. |
| T005 | FR-002 | pass | `config get`/`set session_mode` command + `config` dispatch case in `specrew.ps1` (mirrors host/team positional pattern); CLI dispatch smoke-verified end-to-end. |
| T006 | FR-003 | pass | `session_mode: "single"` default in BOTH scaffold-governance.ps1 mirrors; `specrew-init.ps1` → extensions/ scaffold writes it on real init. |
| T007 | FR-002 | pass | Acceptance test asserts set→multi, revert→single, invalid→reject (exit 1, unchanged) against real config. |
| T008 | FR-003 | pass | Acceptance test drives the REAL scaffold writer (not a stub) and asserts default single; fail-first verified. |
| T009 | FR-004 | pass | `Get-FileClassification` returns all 4 categories + 8 canonical per-session patterns. |
| T010 | FR-005 | pass | `Update-GitignoreForSession` is idempotent + non-destructive (preserves comments/unrelated entries; no duplicates). |
| T011 | FR-005 | pass | Wired into `specrew-init.ps1` after governance scaffold (DryRun-aware). Coverage caveat below. |
| T012 | FR-006 | pass | `Remove-TrackedPerSessionFiles` runs `git rm --cached` only; keeps working copies; safe no-op outside a repo. |
| T013 | FR-006 | pass | Wired into init alongside T011. Coverage caveat below. |
| T014 | FR-005 | pass | Acceptance test verifies all per-session patterns present, idempotency, and pre-existing-entry preservation. |
| T015 | FR-006 | pass | Acceptance test runs against a REAL temp git repo: index entry removed, working copy kept, unrelated file untouched; fail-first verified. |
| T016 | FR-001..006 | pass | quickstart.md verified + fixed (stale `specrew-cli.ps1` → `specrew.ps1`, a D-002 residue). |
| T017 | FR-001..006 | pass | data-model.md SessionModeConfig + FileClassificationRule match the shipped `Get-FileClassification` schema. |
| T018 | FR-001..006 | pass | Both F-051 acceptance suites pass; slash-command-arg-whitelist regression pass. |
| T019 | FR-001..006 | pass | Validator clean (no FAIL/medium/hard); only pre-existing soft warnings. |

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements (FR-001..006, SC-001/SC-005 partial) verified: fixed-now.

## Notes

- **Known coverage-edge (disclosed, not papered over):** T011/T013 (init *wiring*) are verified by direct helper tests (against real temp dirs/repos) + PowerShell parse-check + code-read, NOT by a full end-to-end `specrew init` execution (init is a heavy multi-deploy operation). The helper logic itself is fully exercised. Candidate follow-up: an init-flow integration test that asserts `.gitignore` + index state after a real `specrew init` (Iteration-1 retro signal / small-fix slice). Recorded in coverage-evidence.md.
- **Mechanical checks:** `quality/mechanical-findings.json` — zero findings (no dead-field / anti-pattern / test-integrity issues).
- **Test integrity:** both acceptance suites are fail-first-verified and assert observed reality (config bytes, gitignore lines, real git index state) — not declared success, not mocked.
- **SC coverage:** SC-001 (per-session merge-conflict elimination) — foundation laid (gitignore + cleanup); full multi-developer concurrent-cycle proof lands with Iteration 2a. SC-005 (version sync) — partial; full coverage in Iteration 3.
- **Drift:** D-001 (capacity) + D-002 (path convention) both closed (drift-log.md), 2/2 resolved.
