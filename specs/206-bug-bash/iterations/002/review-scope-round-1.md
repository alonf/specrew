# Review Scope: Feature 206, Iteration 002, Round 1

This file is for the reviewer: what this round covers, and what to attack first. It is passed with
`--design-context-ref`, so it comes first in the review frame. It adds to the spec, the plan and the design analysis
and does not replace them.

- **Feature:** 206 (bug bash). **Iteration:** 002, Phase 5 (start and checks), tasks T020 to T025.
- **Iteration baseline:** `8875e8834e8f334d8e55cf42147dbb66cc1a773c`. The branch base is `d3e33550` on main.
- **Requirements:** FR-001 and FR-003, SC-001 and SC-002 (the two criteria iteration 001 did not meet), and SC-007
  (no test writes the real home folder).
- **Design:** Option B, decisions D5-a (start records the whole files it wrote) and D6-a (no session files means a
  first start): `specs/206-bug-bash/iterations/002/design-analysis.md`.
- `.specify/**` is excluded from the frozen tree; no Phase 5 change touches `extensions/` or `.specify/`.
- **Not in scope:** `scripts/internal/continuous-co-review/**` and the capture stores under `scripts/internal/bootstrap/`
  are feature 203's and were not changed. T023 calls the path-identity helper there and does not edit it.

## What This Round Covers

Each fix landed with a failing test first, then the fix, one bug per commit.

| Task | Item | Change | Test |
| --- | --- | --- | --- |
| T020 | 21 | `specrew start` snapshots the session-loaded files before its first write and records, in the git-ignored `.specrew/runtime/start-written-files.json`, the SHA-256 of each one the run created or changed; a changed file whose committed content still matches its recorded hash is not a pause trigger (`scripts/internal/instruction-file-merge.ps1`, `scripts/specrew-start.ps1`) | `tests/unit/start-written-files-record.tests.ps1` |
| T021 | 29 | `validator-hardening-iteration2.ps1` builds its fixtures in a temp folder and copies only what git does not ignore; green (17 checks, SC-002); release manifest | the script itself; the census guard's pin |
| T022 | 22 | with neither `last-start-prompt.md` nor `start-context.json` on disk, their absence is not stale state (`scripts/internal/session-recovery.ps1`); every other stale check is unchanged | `tests/unit/fresh-clone-first-start.tests.ps1`, with the reviewer's fresh-clone combination case |
| T023 | 23 | a resume path outside `-ProjectPath` is refused; the saved session path is adopted only inside the project; the tracked identity file records the feature path relative to the project (`scripts/specrew-start.ps1`, `scripts/internal/sync-boundary-state.ps1`, `scripts/internal/session-recovery.ps1`); the inside-project check takes case from the path-identity helper | `tests/unit/resume-path-inside-project.tests.ps1`; `tests/continuous-co-review/unit/path-identity.Tests.ps1` |
| T025 | 25 | `specrew init`'s Squad probe runs in a temp folder of its own, and a folder its cleanup cannot remove is reported (`scripts/init/squad-deploy.ps1`, `scripts/specrew-init.ps1`) | `tests/unit/squad-probe-temp-folder.tests.ps1` |
| T024 | 24, 25 | SC-001's script runs again on a fixture a fresh checkout would hold, starting with no recovery choice; a dry run's summary names its folder (`scripts/init/post-bootstrap-output.ps1`) | `tests/integration/project-path-resolution-regression.ps1` (supervised run 5: six checks pass); `tests/unit/init-dry-run-names-project.tests.ps1` |

Also:

- **SC-001's script is not registered yet:** iteration 001's ruling holds it out of the automated lists until the
  maintainer has seen its supervised run, and that answer is open with them.
- **Known and deferred:** this repository's own `.squad/identity/now.md` still holds an absolute feature path until its
  next boundary sync rewrites it relative.

## What to Attack First

1. **The record of files start wrote (T020).** A file that matches its record although the user changed it (line
   endings, a BOM, trailing newlines, a rename); a user's edit that start then heals back, so the committed content and
   the working tree differ; a record entry that survives a file's deletion, or follows a file across features; machine
   data (a path, a user name) in the record.
2. **A first start that hides stale state (T022).** One session file present and the other absent; a present but
   unreadable file; a fresh clone whose tracked identity names another machine's feature; any other stale check the
   change silences.
3. **A path that escapes the project (T023).** A sibling whose name starts the same, `..` segments, a junction or
   symlink, a relative identity path that resolves outside, a case variant on a case-sensitive volume, recovery
   choice A with an outside path.
4. **Writes outside the fixture or temp folders (T021, T024, T025).** Anything these suites, the probe or SC-001's
   script leave in this repository or the real home folder, and any fixture that still copies what git ignores.

**Two standing instructions from iteration 001's retro (T037):**

- **For any text-matching rule, try a phrasing that matches the pattern but denies or conditions it.** In iteration
  001, rounds 1 to 3 each found one.
- **For any test that reads workflow or script files, try each YAML and shell construct that can hide or fake a
  line:** comments, block scalars, keys of the same name at other levels, and statement delimiters (rounds 2 to 4).
