# Feature 203 iteration 001 review, Round A: authority and capture (`scripts/internal/bootstrap`)

This round's focus is the area below. The whole tree is frozen and in scope; spend your time on this area first.

## What this iteration changed

- **What changed**: feature 203 iteration 001, from `fca9067e` (the before-implement baseline) to `32d2af39`:
  298 commits, 330 files, +25,215 / -6,885 lines. The frozen tree has no diff in it. The full list of
  changed files with their line counts is in `docs/review-scope/changed-files.txt`. Read that list before
  choosing what to open.
- **The iteration's contract**: `specs/203-beta5-stabilization/spec.md` and
  `specs/203-beta5-stabilization/iterations/001/plan.md` (the task table: T001 to T013 done, T014 planned).
  The engine resolves both automatically.
- **Not defects of this iteration** (deferred by the maintainer's rulings; do not report them as missing):
  - FR-041: drift entries do not carry the turn identity yet (iteration 002).
  - FR-042: replay through Copilot's and Codex's real hooks across a compaction, and the Codex out-of-tail
    case (iteration-002 three-host walk).
  - The out-of-band boundary approval decision (iteration 002).
  - Two suites known red under B5F-036: `project-path-resolution-regression.ps1` and
    `validator-hardening-iteration2.ps1`.
  - T014 (pin advance): the live hooks still run engine `a56ac787`. This round reviews the source, not the
    deployed engine.
- **Stripped from the frozen tree**: `.specify/**`, `.specrew/**`, `.squad/**`. The `.specify` copies are mirrors of
  `extensions/specrew-speckit/`; review the `extensions/` source.
- **Severity**: a blocking or major finding states a concrete failure scenario. Prefer one proven defect over
  several suspicions.
- **If you have a shell**: the frozen tree is a git worktree at `32d2af39`; `git diff fca9067e -- <path>` shows the
  iteration's change to a file.

## Focus: Round A: authority and capture (`scripts/internal/bootstrap`)

**Files changed in this area:**

| File | +/- | Tasks (requirements) |
|---|---|---|
| `HumanAuthorityStore.ps1` | +1614 / -658 | T003 (FR-014, 015, 018, 020, 023), T004 (FR-021, 022, 025), T006 (FR-026, 027), T012 (FR-024, 041), T013 sender check (FR-042, B5F-066/070) |
| `HandoverStore.ps1` | +447 / -77 | T004, T005 (FR-019, 020), T006, T013 (Stop-backstop turn registration) |
| `AuthorityAudit.ps1` | +195 / -0 | T012 (FR-024, 041) |
| `ConversationCaptureAccessor.ps1` | +124 / -13 | T005, T013 (transcript record reader: `record_*` fields, queued_command turns) |
| `ProjectMetadataAccessor.ps1` | +19 / -1 | T002 (pin with no helper loads no store) |

**Attack these:**

1. **An approval minted without a typed human turn.**
   - Can `Resolve-SpecrewAuthorizationSender` / `Get-SpecrewTranscriptRecordSender` classify a non-human record as
     human? Try: a cross-session peer message with or without the "Another Claude session sent a message:" line;
     a scheduled or task-notification prompt; `isMeta`; a `queued_command` whose `origin.kind`, `humanTurn` or
     `commandMode` is not human, typed, prompt; an unknown field combination; the old desktop shape.
   - Can the text binding be met by a turn whose act or text differs from the record?
2. **A refused approval honoured anyway.**
   - Does any store getter still return a record without the sender check? The getters: allowance reset, pause
     decision, stop answers, partial sign-off, coverage deferral.
   - When the check cannot load, does a getter fall back to accepting?
   - Is `unverified` (no transcript fields; Copilot and Codex) ever granted beyond the text rules?
3. **The partial sign-off one-line rule.** A multi-line message carrying the phrase must be `qualified` and refused
   by the writer (`rationale-not-one-line`). Look for a path where it is accepted.
4. **The audit join (T012).** Look for:
   - a record, refusal or review capture missing its turn identity or campaign id;
   - one typed approval recorded twice, once by the prompt hook and once by the Stop backstop;
   - a turn identity taken from the wrong turn.
