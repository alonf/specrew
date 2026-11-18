# T015: The Held Scripts Registered or Excluded (Stop for SC-001)

Feature 206, iteration 001, task T015 (FR-012; SC-001, SC-002). Built on the maintainer's T014 ruling of 2026-11-12
and the rulings after it (the two dashboard scripts; SC-002 option 1). Report for the maintainer, written on
`015593cb`.

## Where the 36 Held Scripts Went

| Destination | Count | Scripts |
| --- | --- | --- |
| Per-push CI step (Specrew CI, Deterministic gate) | 23 | the 17 read-safe green scripts and the six `specrew-start-*` |
| Release manifest (`.specrew/release-gate-suites.txt`) | 1 | `validator-hardening-iteration1.ps1` (98 s) |
| Excluded, with reasons (`tests/support/test-census.ps1`) | 12 | listed below |
| **Total** | **36** | the held list is empty, and the lane guard requires it |

Registration rule used for "by duration": a script under 60 s alone on this machine runs per push; a slower one goes
to the release manifest.

**Per-push time added:** 293 s serial on this machine: the 17 scripts take 78 s (T014's timings) and the six
`specrew-start-*` take 215 s (29, 28, 27, 44, 46, 41 s, after the T003 fix). CI runners are slower than this machine.

## Commits

| Commit | What |
| --- | --- |
| `963fc149` | test: RED 9/34, the eight start-path scripts do not set the profile override themselves |
| `8f1e5f0c` | fix: each sets `SPECREW_USER_PROFILE_PATH` to a temp file at its top (GREEN 33/34) |
| `968022f3` | test: RED 2/10, `specrew start` stops when copilot-instructions.md is missing on one side (T003 regression) |
| `30fa853a` | fix: the absent side is compared as empty, as before T003 (GREEN 10/10) |
| `ec541bae` | test: RED 16/49, the held list is not empty and no held script is where the rulings put it |
| `95c28953` | fix: the CI step, the manifest line, the 12 exclusions, the held list emptied (GREEN 49/49) |
| `015593cb` | records: bug list items 15-21, DRIFT-206-I001-013 and -014, tasks, plan, state |

## Runs at T015

Each script was run alone, with the home hook files hashed before and after (unchanged every time), no interactive
console (stdin from an empty file, `-NonInteractive`), and `git status` compared (unchanged every time).

| Script | Result | Seconds | Where it went |
| --- | --- | --- | --- |
| `specrew-start-auto-continue-preservation.ps1` | green | 29 | per push |
| `specrew-start-baseline-tracking.ps1` | green | 28 | per push |
| `specrew-start-change-detector.ps1` | green | 27 | per push |
| `specrew-start-end-to-end.ps1` | green | 44 | per push |
| `specrew-start-parameter-handling.ps1` | green | 46 | per push |
| `specrew-start-pause-and-confirm.ps1` | green | 41 | per push |
| `feature-017-dashboard-core.ps1` | **red** | 1 | excluded (bug list item 19) |
| `feature-018-rich-dashboard.ps1` | **red** | 2 | excluded (bug list item 20) |
| `validator-hardening-iteration2.ps1` (SC-002) | **red** | 944 | excluded (bug list item 21) |
| `project-path-resolution-regression.ps1` (SC-001) | red, and wrote into this repository (runs 3 and 4) | | excluded; SC-001 not met in iteration 001 |

Before the T003 fix, four of the six `specrew-start-*` scripts were red (change-detector, end-to-end,
parameter-handling, pause-and-confirm): see "The T003 Regression" below.

## The Red Scripts

- **`feature-017-dashboard-core.ps1`**: "FAIL: Healthy fixture: specrew where should succeed." `scripts/specrew.ps1
  where --project-path <fixture copy>` exits 1: "ERROR: 'specrew where' requires a Specrew-managed project" and
  "WARNING: Specrew project setup is missing". The fixture was last changed on 2026-05-15; the check's message first
  appears in `29a130b2` (2026-05-18). The script stops at its first failure.
- **`feature-018-rich-dashboard.ps1`**: "FAIL: Rich-capable replay should match the expected rich dashboard contract."
  A probe with the same fixture and renderer: 59 lines against 57 expected; velocity 6.08 against 3.65 SP/day (12
  against 20 calendar days for the same 73 SP); an added "Chosen: Feature 018-..., from an older feature pointer that
  does not record its branch." line. Whether the golden file or the renderer is wrong is not established.
- **`validator-hardening-iteration2.ps1`** (SC-002): 14 of its first 15 checks pass; assertion 3 fails:
  "Bookkeeping-only copilot-instructions changes should not trigger pause-and-confirm." The second start run pauses on
  `.github/agents/squad.agent.md` and five `.squad/agents/*/charter.md`, which the first start run healed or created
  and the test then committed. SC-002 is not met in iteration 001; it is required in iteration 002.

## The T003 Regression

T003's fix (`0621a076`) called the classifier with content; its mandatory content parameters refuse an empty string,
so when `.github/copilot-instructions.md` was added or deleted since the baseline commit, the second `specrew start`
exited 1: "Cannot bind argument to parameter 'BeforeContent' because it is an empty string." It escaped T003's tests
because the unit suite had content on both sides and read the call site's text without executing it, and the scripts
that execute it ran nowhere. Fixed (`968022f3`, `30fa853a`); DRIFT-206-I001-014.

## The Exclusions Added at T015

| File | Reason |
| --- | --- |
| `tests/integration/substantive-interaction-model-iteration2.ps1` | stale README assertion (section removed by b27f35c4); bug list item 16, fixed in iteration 002 |
| `tests/integration/distribution-module-init.ps1` | writes the real home; not run until feature 203's private test home is merged (specrew-init deploys the hook files) |
| `tests/manual/multi-host-smoke.ps1` | writes the real home; not run until feature 203's private test home is merged (bug list item 18) |
| `tests/integration/team-management.ps1` | writes the real home; not run until feature 203's private test home is merged |
| `tests/integration/update-command.ps1` | writes the real home; not run until feature 203's private test home is merged |
| `tests/integration/validate-baseline-team.ps1` | writes the real home; not run until feature 203's private test home is merged |
| `tests/manual/copilot-squad-smoke.ps1` | writes the real home; not run until feature 203's private test home is merged |
| `tests/integration/distribution-module-publish.ps1` | would publish to PSGallery if PSGALLERY_API_KEY is set; bug list item 17 (severity high) |
| `tests/integration/feature-017-dashboard-core.ps1` | red: its fixture is not a Specrew project to `specrew where`; bug list item 19 |
| `tests/integration/feature-018-rich-dashboard.ps1` | red: the rendered dashboard no longer matches its golden file; bug list item 20 |
| `tests/integration/validator-hardening-iteration2.ps1` | red: start classifies the agent and charter files it wrote itself as user changes; bug list item 21 |
| `tests/integration/project-path-resolution-regression.ps1` | SC-001 not met in iteration 001: supervised runs 3 and 4 wrote into this repository (both rewrote `specs/206-bug-bash/iterations/001/state.md`; run 4 left a `.specrew-squad-probe-*` folder at its root); the script refuses to run until bug list items 23, 24 and 25 are fixed; required in iteration 002 |

## Files Feature 203 Also Changed

Against the branch base `d3e33550`:

- `.specrew/release-gate-suites.txt`: 15 added lines, nothing removed. T014 reported 11 (a two-line comment naming
  206's tasks, a blank line, 8 `tests/unit/*.tests.ps1` suites); T015 adds 4: a blank line, a two-line comment and
  `tests/integration/validator-hardening-iteration1.ps1`.
- `.specrew/verification-plan.json`: unchanged.

## SC-001: The Supervised Run

Run on `015593cb`, alone, 2026-11-12 19:46:17 to 19:46:58 local time (UTC+2): **red, 39 s.** The home hook files
were unchanged and so was the repository's `git status`. The run had the profile override set, no interactive
console, and a 60-minute cap. Per the ruling ("If it is red or anything changed, stop"), T015 stops here, before
the push.

**The failure:** "specrew start --no-launch (default path) exited with code 1." Start prints "Stale state detected.
Session-state file is present but stale or unparseable: last-start-prompt.md", offers A/B/C, and ends with "specrew
start could not continue: this project has stale session state, and no recovery path was chosen." That is item 1's
path working as T001 fixed it: with no console input it refuses instead of looping, which is why the script used
to time out.

**Why the state is stale:** the script builds its fixture by copying this repository's own `.specrew`, `.specify`,
`.squad`, `.github` and `specs` (lines 91-97). That copy includes `.specrew/last-start-prompt.md` and
`.specrew/start-context.json`, which are gitignored session state (`.gitignore:59`, `:61`). This worktree's prompt
was written by a session start on 2026-11-12 00:18 and has no frontmatter, so start reads it as stale. The result
therefore depends on the developer's own session state: a fresh CI checkout has neither file. Proposed bug-list
entry (not written yet): the fixture should copy tracked files only, or remove the two session-state files, so that
SC-001 measures the path resolution it is about.

**The home folders**: every file under `~/.specrew`, `~/.copilot`, `~/.codex`, `~/.claude` and `~/.cursor`, 40,048
before and 40,049 after, listed with size and modified time. The differences:

| Change | File | Attributed to |
| --- | --- | --- |
| new | `.claude/file-history/d8f18eb4-.../aff110a597f115ab@v1` (modified 11:43 UTC) | the Claude session in `C:\Dev\specrew-b4f-142` (session `d8f18eb4`) |
| changed | `.claude/projects/C--Dev-specrew-b4f-142/d8f18eb4-....jsonl` and one of its subagent transcripts | the same session |
| changed | `.claude/projects/C--Dev-specrew-220-workshop-lens-order/d523bc82-....jsonl` | the Claude session in the 220 worktree |
| changed | `.claude/projects/C--Dev-specrew-206-bug-bash/10b872c0-....jsonl` | this session's transcript |
| changed | `.claude/plugins/store/cc-plugin-diff_builtin-....json` (same size) | Claude Code (also written 5 s before the run started) |
| changed | `.codex/.codex-global-state.json` and its `.bak` (same size) | the Codex desktop app (running since 00:19): written 19 s before the run started, and again at 19:47:13 and 19:49:16 with no run going |

Nothing under `~/.specrew`, `~/.copilot` or `~/.cursor` changed, and no file was removed. No change is attributable
to the script. A listing taken twice before the run, with nothing running, already differed by one transcript.

**Not registered.** The script stays excluded ("awaits the maintainer") until your ruling.

## SC-001: Supervised Run 2 (after the fixture fix)

By the reviewer's ruling of 2026-11-12, given under the maintainer's delegation, the fixture's `.specrew` copy takes
only the files git tracks: RED 1/50 in `b9354aff`, GREEN 50/50 in `7c8b5cf7`, DRIFT-206-I001-015, bug-list item 22.
Run 2 used the same protocol as run 1: on `7c8b5cf7`, alone, override set, no console, home hook files hashed, and
the five folders listed. It ran from 19:55:02 to 19:55:37 local time.

**Red, 33 s.** The home hook files were unchanged and so was the repository's `git status`.

**The failure has moved.** With no session files copied, start reports "Session-state file missing on disk:
last-start-prompt.md" and "... start-context.json (re-anchor will recreate it from the current spec)". It then
refuses because there is no console: "specrew start could not continue: this project has stale session state, and
no recovery path was chosen ... run specrew start again with a choice, for example: specrew start --recovery-choice
A". The fixture also copies `specs/` (features with iterations), so to start it is a governed project whose session
files are missing. A fresh checkout of this repository meets the same refusal. The script's other cases pass: init
--dry-run, update --info, team list, review, and the static GetFullPath scan.

**The home folders:** 40,055 files before and 40,055 after. These are the differences, and the paths I treat as
other activity:

| Change | File | Attributed to |
| --- | --- | --- |
| new | `.claude/backups/.claude.json.backup.1794506118180` (modified 17:52 UTC, before the run) | Claude Code's rotation of its `.claude.json` backups |
| removed | `.claude/backups/.claude.json.backup.1794504635593` | the same rotation (the oldest backup dropped) |
| changed | `.claude/plugins/store/cc-plugin-diff_builtin-....json` (same size) | Claude Code (rewritten 39 s before the run, too) |
| changed | `.claude/projects/C--Dev-specrew-206-bug-bash/10b872c0-....jsonl` | this session's transcript |
| changed | `.claude/projects/C--Dev-specrew-220-workshop-lens-order/d523bc82-....jsonl` | the Claude session in the 220 worktree |
| changed | `.claude/projects/C--Dev-specrew-b4f-142/d8f18eb4-....jsonl`, its subagent transcript and `.meta.json` | the Claude session in `C:\Dev\specrew-b4f-142` |

Nothing under `~/.specrew`, `~/.copilot`, `~/.codex` or `~/.cursor` changed. No change is attributable to the script.
The paths I treat as other activity are `~/.claude/projects/**`, `~/.claude/backups/**`, `~/.claude/file-history/**`,
`~/.claude/plugins/store/**`, and `~/.codex/.codex-global-state.json` with its `.bak`. Every change in either run
falls under one of these.

**Not registered; no third run** (the reviewer's ruling). For the maintainer, SC-001 has two possible fixes:

1. The test passes a recovery choice, for example `--recovery-choice A`, so start re-anchors in the fixture. This is
   a test change, and SC-001 then measures path resolution after a re-anchor.
2. `specrew start` treats a governed project with no session files, as in a fresh clone, as a first start rather than
   stale state. This is a product change on item 1's path, and new design.

## SC-001: Supervised Runs 3 and 4, and the Outcome

**Run 3** (on `3e3ae481`; the start case passes `-RecoveryChoice A` by the maintainer's option 1; RED 1/51 in
`0b54a3e6`, GREEN 51/51 in `3e3ae481`; DRIFT-206-I001-016). **Green on all 7 checks, 44 s**, home hook files
unchanged, but **it wrote into this repository**: `specs/206-bug-bash/iterations/001/state.md` was rewritten at
21:29:17 UTC, during the start case. A task-progress summary block was added, the task lines and `Updated` stamp were
changed, and the escalation block's closing marker line was removed. Nothing under the five host folders was
attributable to it.

**Run 4** (on `e416edc6`; the fixture under the temp folder as its own git repository; RED 1/52 in `e29b179f`, GREEN
52/52 in `e416edc6`; DRIFT-206-I001-018; the repository fingerprinted before and after). **Red, 61 s**: "specrew init
--dry-run (default path) did not emit expected output pattern"; the other five checks passed. Home hook files
unchanged. **It wrote into this repository again**:

- `specs/206-bug-bash/iterations/001/state.md`, the same change, at 21:44:52 UTC during the start case;
- `.specrew-squad-probe-51b037d112c14c728e686658de66bba0/.github/skills/cross-squad-communication/SKILL.md`, untracked
  at the repository root, created at 21:44:58 UTC during the init case.

Under the five host folders, nothing changed in `~/.specrew`, `~/.copilot` or `~/.cursor`. The `~/.claude` and
`~/.codex` changes all fell under the paths treated as other activity: `~/.claude/projects/**` (including the reviewer
session's transcript), `sessions/*.json`, `backups/**`, `file-history/**`, `plugins/store/**`, and the Codex app's
`.codex-global-state.json` with its `.bak`.

**Why:** run 4's fixture had its own git repository, so the enclosing git was not the route (run 3's first diagnosis
was incomplete). The route, read without running anything, is bug list item 23. The tracked `.squad/identity/now.md`
holds an absolute `session_state_feature_path` to this repository's feature, and the fixture copies `.squad` whole.
With no prompt or start context, the session-state snapshot falls back to that file. Recovery A makes the path the
resume override, and `Resolve-FeatureDirectory` accepts any rooted path. The probe folder is item 25: `specrew init`
probes Squad in the install root, which is this repository in a dev checkout, even with `-DryRun`, and its cleanup
fails silently.

**Outcome (maintainer, option 1, 2026-11-12; reviewer's conditions):**

- `state.md` was restored from git after each run, and the probe folder was deleted. Both diffs and the probe file are
  kept as evidence.
- SC-001 is not met in iteration 001. It is a required item for iteration 002, with bug list items 23, 24 and 25.
- The script refuses to run: its first statement names the three items and exits 1, before any fixture is built,
  with no bypass. Run with the temp folder pointed at an empty directory, it writes nothing in the repository or the
  temp folder. RED 2/54 in `4f8205ff`, GREEN 54/54 in `f0201deb`; DRIFT-206-I001-019.
- Its census exclusion reason now says what runs 3 and 4 wrote (RED 1/54 in `8f8e34cb`, GREEN 54/54 in `3977131d`).
- No further run of this script in iteration 001.

For iteration 002 planning: `specrew-start-facts.md` in this folder (one page, facts only) and DRIFT-206-I001-017,
which records the maintainer's remark that `specrew start` is no longer used since the startup hook.
