# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-07
**Overall Verdict**: implementation-ready-for-review

## Tests Run

| Command | Result | Evidence |
| --- | --- | --- |
| `pwsh -NoProfile -File tests\integration\f049-i003-intake-engine-tests.ps1` | pass | Existing profile/intake suite passed; new P170 assertions passed for setup metadata and input normalization; legacy profile compatibility assertions remained green. |
| `npx --yes markdownlint-cli --config .markdownlint.json proposals/170-new-user-profile-setup-copy.md specs/172-profile-setup-ux-copy/spec.md specs/172-profile-setup-ux-copy/plan.md specs/172-profile-setup-ux-copy/tasks.md specs/172-profile-setup-ux-copy/iterations/001/plan.md specs/172-profile-setup-ux-copy/iterations/001/state.md specs/172-profile-setup-ux-copy/iterations/001/drift-log.md` | pass | No markdownlint findings. |
| `git diff --check` | pass | No whitespace errors. |

## Evidence Scope

- `tests/integration/f049-i003-intake-engine-tests.ps1` is local-only in the
  current repository state; this review therefore claims local runtime evidence,
  not CI-reached evidence.
- The local-only status predates Feature 172 and does not block this slice.
  Proposal 171 records the follow-up to CI-wire it after a Linux-safety audit.

## Claim-To-Evidence Ledger

| Claim | Evidence |
| --- | --- |
| First-run setup now asks for guidance preferences instead of domain self-rating. | `scripts/internal/user-profile.ps1` uses `SetupLabel`, `SetupQuestion`, and `Your preference (1-10, auto, or Enter for auto)`. |
| Enter records recommended defaults. | `Normalize-CrewInteractionProfileSetupInput` returns `auto` for null, blank, and whitespace input; test assertions cover all three. |
| Stable profile schema remains unchanged. | Tests still assert `product_management`, `ui_ux`, `software_architecture`, `ai_research_project_management`, and `ai-researcher-project-manager` behavior. |
| No dependency change was introduced. | Diff touches PowerShell metadata/prompt logic, tests, proposal/index, and feature artifacts only. |

## Notes

- The integration test was run with elevated filesystem permission because the
  requested worktree is outside the default writable root and the test writes a
  scratch directory under `tests/integration/scratch`.
