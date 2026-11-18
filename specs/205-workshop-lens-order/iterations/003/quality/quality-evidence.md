# Quality Evidence: Iteration 003

**Profile Ref**: `quality-profile.pending`
**Preset Refs**: (pending preset selection)
**Findings Ref**: `specs/205-workshop-lens-order/iterations/003/quality/mechanical-findings.json`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-11-15T11:29:44Z

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| `dead-field` | mechanical quality bar, unused-state hygiene | `specs/205-workshop-lens-order/iterations/003/quality/mechanical-findings.json` | `planned` | `—` |
| `anti-pattern` | mechanical quality bar, deterministic anti-pattern scan | `specs/205-workshop-lens-order/iterations/003/quality/mechanical-findings.json` | `planned` | `—` |
| `test-integrity` | mechanical quality bar, assertion-driven tests | `specs/205-workshop-lens-order/iterations/003/quality/mechanical-findings.json` | `planned` | `—` |
| `stack-tooling-evidence` | stack tooling evidence | `specs/205-workshop-lens-order/iterations/003/quality/quality-evidence.md` | `planned` | `—` |
| `quality-lens-review` | quality-lens review | `specs/205-workshop-lens-order/iterations/003/quality/quality-evidence.md` | `planned` | `—` |

## T027 red first: `tests/unit/code-lens-freshness.tests.ps1` on today's tree

Run on 2026-11-16 at 02:12 local, on `19a73edf` plus the new test file (no catalog, lens, helper or skill change yet).
The home hook files were hashed before and after; both matched the known-good set (0 differences).

- Self-tests: 10 of 11 passed. They prove each check can fail and names what failed: a date swapped for a non-date, a
  date removed, a version put back into a rule's default and into its title, `current` removed, a stack's Source Notes
  line removed, and each of the three conduct sentences and the skill exception removed. The one failure is the valid
  fixture, which cannot pass until `Get-SpecrewCodeStackFreshnessLines` exists (T030).
- The repository check reports 24 problems, one line each, naming the rule or the sentence:
  - 6 rules with no `sources_checked` date and 6 with no `current` field;
  - the C/C++ rule's default holds version numbers (C11, 17, 23, C++17, 20, 23, 26);
  - the line function is not defined;
  - 6 stacks with no Source Notes line carrying a URL and a date;
  - the three conduct sentences (show the lines, confirm at the point of choice, the no-lookup fallback);
  - the skill's "not invoked mid-workshop" sentence names no exception.
- Exit code 1.

## T028 red first: `tests/unit/workshop-agenda-grouping.tests.ps1` on today's tree

Run on 2026-11-16 at 02:16 local, on `3b85cc06` plus the new test file (no change to the agenda writer or the skill
yet). The home hook files were hashed before and after; both matched the known-good set (0 differences).

- Self-tests: 10 of 10 passed. Nine run the grouping check over synthetic agenda text and prove it names what is
  wrong: a lens under the wrong heading, a tag changed with the text not regrouped, headings out of order, an empty
  heading kept, a marker removed from a heading, two lenses swapped inside a heading, the `Selected lenses:` line
  removed, and the closing question reworded. The tenth is a probe: a child process with a Latin-1 console writes one
  marker unforced, and it does not survive, so the UTF-8 round trip is a real check.
- The repository check renders three agendas through the real writer in scratch projects (the real catalog with all
  three groups, the real catalog with no both-spaces lens, and a fixture index.yml with data-storage tagged
  solution), and reports 13 problems, one per selected lens: "listed before any group heading". The round trip
  passes today only because the block has no marker yet.
- Exit code 1.

## T029 to T033: green, regression and copies

On `ebbe1b9b` (2026-11-16), every run out of process, the home hook files hashed before and after each (0
differences every time).

- **T029** (`babf2cf8`): the six per-stack rules carry `sources_checked: "2026-11-16"` and a `current` field from
  official release data fetched that day (.NET release index and C# language-versioning page; WG14 and isocpp.org;
  the npm registry and Node's index; the Python release-cycle data; Go's release history and download JSON; OpenJDK
  GA dates and Oracle's support roadmap). The C/C++ default no longer names editions. Facts the sources did not
  confirm were left out: Node's active/maintenance split and the next ECMAScript edition.
- **T030** (`79667a2a`): `Get-SpecrewCodeStackFreshnessLines`, the conduct and the skill exception.
  `code-lens-freshness.tests.ps1`: 11 of 11 self-tests and the repository check pass (from 1 and 24 at T027).
- **T031** (`cd5b6ba8`): the grouped agenda and UTF-8 output. `workshop-agenda-grouping.tests.ps1`: 10 of 10
  self-tests and the repository check pass (from 13 problems at T028). Mutation check: with the UTF-8 line removed,
  the Latin-1 round trip fails on all three renders.
- **T032** (`3230e1d5`): proposal 220's status history and INDEX row.
- **T033** (`515a432b`, `ebbe1b9b`): the copies through the two project-only deploy scripts and their four hashes;
  two named CI steps. The deploy's restamps outside the copies were restored by exact path. The parity sweep caught
  T031's three-lens example in the skill, fixed in `ebbe1b9b`.
- Regression on `ebbe1b9b`: 34 of 34 workshop tests pass (the 32 of iteration 002 and the two new ones), parity and
  the length budget pass, markdownlint is clean, and governance fails only on the standing derived-block exception
  (iterations 001 and 002).
