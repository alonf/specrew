# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-11-14
**Overall Verdict**: accepted: two rounds; round 1's three minor findings fixed failing-test first; round 2 passed with
no findings on `b15c5dd1`; the sign-off gate found the change after round 2 records-only, so round 2 covers the
sign-off without a partial-coverage approval

## Independent review

Campaign `cmp-205-workshop-lens-order-i002`, reviewer codex, code writer Claude. Each round was started by the
maintainer's own typed `approved for review round`. Each launch had a 1800 s budget (round 2's preflight alone took
582 s) and passed a committed scope file as design context.

| Round | Run | Target | Findings | Outcome |
| --- | --- | --- | --- | --- |
| 1 | `run-20261114-192351085-49d20b6b` | `3ddcd185` | 3 minor (one reported as major, demoted by the engine) | All three fixed, each after a red test commit (DRIFT-018) |
| 2 | `run-20261114-205542888-e1efcdea` | `b15c5dd1` | none | Pass; current when it ran |

Round 1's findings, all in `tests/unit/workshop-length-budget.tests.ps1`:

- **finding-738b1c957e7e1dce** (reported major, engine minor): SC-009 was not checked fact by fact. Exchanging the
  `compliance_regime` and `data_residency` suffixes left every total unchanged and passed. Red `8347d9d5` (6
  self-tests failing), fix `598d0836`: `Test-ProductDomainFacts` checks each fact by its key against FR-023 and
  FR-024. The swap is proven on a copy of the real catalog.
- **finding-af58489dbcbd1f64** (minor): a `lens: <id>` consumer was accepted on catalog order alone. Red `3a13eaa4` (4
  failing), fix `22c0a583`: the target must hold a hand-forward line for that source and key.
- **finding-edc22c04f8dcbb60** (minor): exempt questions without a suffix were exempted by count. Red `335de732` (3
  failing), fix `398e9520`: they are listed by identity; 68 of 69 are identical to `d4c11236`, and product-domain
  area 4 is recorded at its current text by the reviewer session's ruling.

No lens file, skill or template changed in the fixes. The red and green runs are in `quality/quality-evidence.md`.

## How the Review Stopped

- Round 2 found nothing and covered the files exactly as they were (`b15c5dd1`). A clean round completes without a
  pause question.
- This record and the drift entries written with it landed after round 2. The sign-off gate classed that change as
  records only ("records-only-delta-does-not-stale", matched to round 2's run), so no partial-coverage approval was
  needed, unlike iteration 001. An earlier version of this record said the sign-off rested on such an approval; that
  was corrected after the verdict (DRIFT-022).
- This record is pushed with plan.md still at `executing`, which the governance check refuses beside `review.md`. The
  maintainer allowed that for this push only (DRIFT-021); the push after the sign-off verdict is fully green.

## What This Sign-off Claims, and What It Does Not

- **It claims** every round 1 finding is fixed behind a test that failed first, and a second round read the fixes and
  found nothing.
- **It claims** the 205 verification plan passes (re-pointed to iteration 002, DRIFT-017), and all three workflows
  passed on `8ee7b109` and on `b15c5dd1` (Specrew CI after one ruled rerun of `empty-result-retry`, DRIFT-020).
- **It claims** SC-012 only as far as `quality/t026-recorded-run.md` states: the workshop replies were sent by the
  reviewer session, each confirmed by the maintainer first; "accept" closing a list was shown only together with
  answers to must-answer questions.
- **It does not claim** a round read the records written after round 2; the gate accepted them as records only.
- **It does not claim** FR-030 or FR-031 (iteration 003) or the two-pass split, back-check and amendments (iteration
  004).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T018 | FR-028, FR-029, SC-007, SC-008 | pass | The length and consumer test, red first (5 recorded numbers); strengthened by all three round 1 fixes. |
| T019 | FR-023, FR-027, SC-009 | pass | product-domain areas 9 to 14 with keys and suffixes; checked fact by fact since `598d0836`. |
| T020 | FR-024, SC-009 | pass | Hand-forward lines in six lenses; FR-024's source widened by the placement ruling (DRIFT-007, DRIFT-010). |
| T021 | FR-025, FR-026, FR-029, SC-008, SC-010 | pass | Twelve questions placed by subject (DRIFT-007); each names a consumer that exists. |
| T022 | FR-027 | pass | `## Depth Model` in each touched lens. |
| T023 | FR-026, FR-023 | pass | One recommendation list per lens, closed by one reply; compliance asked at every depth. |
| T024 | FR-029 | pass | `## Problem Context` with eleven consumer lines in the template source; the deployed copy is left as is (DRIFT-008). |
| T025 | FR-025, FR-028, SC-007, SC-010 | pass | Copies and hashes refreshed; extractor counts updated; CI step added; 32 of 32 workshop tests pass. |
| T026 | SC-012 | pass, with its stated limit | `quality/t026-recorded-run.md`: one list per lens closed by one reply; compliance asked at Light with no default; answers handed forward. Replies relayed by the reviewer session, each confirmed by the maintainer first (DRIFT-011). |

## Gap Ledger

- **finding-738b1c957e7e1dce**: fixed-now in `598d0836` (red `8347d9d5`); round 2 read the fix.
- **finding-af58489dbcbd1f64**: fixed-now in `22c0a583` (red `3a13eaa4`); round 2 read the fix.
- **finding-edc22c04f8dcbb60**: fixed-now in `398e9520` (red `335de732`); round 2 read the fix.

## Open Outside This Review

These are drift-log items, not review findings:

- **Later iterations**:
  - DRIFT-014: the agenda shows no problem/solution grouping (proposed for iteration 003).
  - DRIFT-015 and DRIFT-019: the scratch workshop's records — a stale open point, unlabelled inferences, a
    hand-forward outside its lens file, a post-close correction (the back-check and amendments, iteration 004).
- **Feature 203 hand-overs**:
  - H-015 to H-021, raised during this iteration;
  - H-022: the `empty-result-retry` failure on `b15c5dd1`, a sighting of HO-206-1 and B5F-051.
- **Spec wording**: TG-003 still lists FR-031 under iteration 002, while the approved plan moved it to iteration 003.

## Independence

This record carries no derived independence block. As in iteration 001 (DRIFT-012), the block is computed from a
review store that exists only on the machine that ran the review, so the local check and CI derive different text. In
plain words, this record's independence rests on:

- **The two Codex rounds, for the trees they read.** Round 1 read `3ddcd185` and round 2 read `b15c5dd1`.
- **The sign-off gate's records-only finding, for the records after round 2.** No campaign run read them.
- **Not on the record itself.** This record was written by the implementing session (Claude, the code writer), not by
  the reviewer, so it adds no independence of its own.
