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
| `project-path-resolution-regression.ps1` (SC-001) | see below | | excluded until the maintainer has seen this report |

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
| `tests/integration/project-path-resolution-regression.ps1` | awaits the maintainer: SC-001's supervised run is reported before it is registered |

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
