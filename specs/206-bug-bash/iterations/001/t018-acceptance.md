# T018: Acceptance Checks (Iteration 001)

Feature 206, iteration 001, task T018 (SC-007). Run 2026-11-13 on `66d70fa3` (CI green on all three workflows: Specrew
CI 43324451186, Test 43324451149, Cross-Platform Validation 43324451185; no job skipped). Branch base: `d3e33550`,
the merge base with `origin/main` (the local `main` is stale and was not used).

| Check | Result | Evidence |
| --- | --- | --- |
| The branch diff touches nothing under `scripts/internal/continuous-co-review/**` or `scripts/internal/bootstrap/**` | **pass** | `git diff --name-only d3e33550...HEAD` on the two paths: empty |
| `.squad/active-features.yml` is in no commit | **pass** | `git log d3e33550..HEAD -- .squad/active-features.yml`: empty (the file stays modified and uncommitted in the worktree) |
| No commit touches a full-validation trigger path | **fails as worded** | two plan-stage commits touched `.specrew/iteration-config.yml`: `435332da` (OVERRIDE 5, capacity 22) and `a3778f1a` (its revert, at the maintainer's "changes needed: a"); net diff against the base is zero; recorded as DRIFT-206-I001-001 (the revert, pushed alone, turned Specrew CI red on two iterations). No implement-stage commit touches a trigger path |
| The home hook-file hashes match before and after every run (SC-007) | **pass** | `~/.specrew/hooks/**`, `hook-bindings/**`, the launcher, the Codex, Cursor and Copilot hook files: unchanged against the baseline at every check of this iteration, before and after each run (257 recorded hash sets), and again now |
| The 203 hand-over record is closed | **done** | `handover-to-203.md`: closed with ten items, HO-206-1 to HO-206-10 |

**For the maintainer:** the trigger-path check needs a ruling: accept the two plan-stage commits as recorded in
DRIFT-206-I001-001, or hold T018 open.

**SC-007 and the repository, for the record:** SC-007 is about the home hook files, and it held. Two supervised runs of
`project-path-resolution-regression.ps1` (T015, runs 3 and 4) did write into this repository: `state.md` both times,
and an init probe folder in run 4. Both were restored at the maintainer's word, the evidence is kept, and the script
now refuses to run (bug list items 23 to 25, DRIFT-206-I001-018 and -019).

**Iteration 001 does not meet, by ruling:** SC-001 and SC-002. Both are required in iteration 002.
