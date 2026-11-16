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
