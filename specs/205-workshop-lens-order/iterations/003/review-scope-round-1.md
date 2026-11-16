# Review Scope: Feature 205, Iteration 003, Round 1

**Iteration**: 003, the code-implementation lens refresh, proposal 220's status history, the grouped agenda
**Baseline**: `a764c403` (iteration 003's baseline ref in `state.md`)
**Written**: 2026-11-16, before the round, and committed in the reviewed tree

## What iteration 003 changed

Product files, from the baseline to the reviewed commit:

- **Code lens catalog**: `extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml`. Each of the six
  per-stack rules gains `sources_checked` and `current`; the C/C++ rule's default no longer names editions.
- **Code lens**: `extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md`. Two conduct bullets:
  show the resolved stack's last-checked line (with a snippet that finds the helper), and confirm a version the
  human's choice depends on at the point of choice (Amendment A3). Source Notes list each stack's sources with URL and
  date.
- **Lens helper**: `scripts/internal/code-implementation-lens.ps1` gains `Get-SpecrewCodeStackFreshnessLines`.
- **Agenda writer**: `extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1`. The canonical agenda groups
  the selected lenses under three headings from index.yml's `space` tags, refuses a selected lens with no space, and
  writes its output as UTF-8.
- **Workshop skill**: `extensions/specrew-speckit/squad-templates/skills/design-workshop.md`. The agenda template
  shows the headings; a lens's opening repeats its group's marker; the "not invoked mid-workshop" sentence names the
  one read-only exception.
- **Proposal**: `proposals/220-workshop-lens-order-and-cross-lens-consistency.md` (status history) and its
  `proposals/INDEX.md` row.
- **Tests** (new): `tests/unit/code-lens-freshness.tests.ps1` (11 self-tests) and
  `tests/unit/workshop-agenda-grouping.tests.ps1` (10 self-tests, including a non-UTF-8 console probe).
- **CI**: two steps in `.github/workflows/specrew-ci.yml`.
- **Deployed copies**: `.specify/` copies of the four changed extension files, the four host `SKILL.md` copies, and
  the hash record `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json`.
- **Verification plan**: `.specrew/verification-plan.json`, re-pointed to iteration 003 with the two new tests (14
  suites).

## The contract

- **Requirements**: FR-030 (with Amendment A3's two sentences), FR-031, FR-032 (Amendment A2).
- **Success criteria**: SC-011, as amended by A3, and FR-032's test clause.
- **Design**: Option A of `iterations/003/design-analysis.md`: data on the catalog entry, rendered by one pure
  function with today as a parameter; no CI freshness gate (Option C was not chosen).
- **Version facts**: what the official sources said on 2026-11-16 (`quality/quality-evidence.md`, "T029 to T033").
  A fact they did not confirm is left out.

## Known limit of the evidence

- **The terminal view**: T034 (`quality/t034-render-check.md`) proves the bytes, the UTF-8 round trip and the
  provider binding. How a terminal draws the markers is the maintainer's to confirm from the review packet.
- **The conduct**: the two conduct bullets are proven present by the file test. No workshop run exercised them; the
  next code-lens workshop does.

## Not defects of this iteration

- **Later work**: iteration 004 (the two-pass split, the back-check, amendments, sweeps, the items carried from
  iteration 001).
- **Feature 203's area**, handed over and not changed here: H-023 to H-025, and the conformance provider, which is
  not edited (the agenda keeps its `Selected lenses:` line).
- **The deploy restamps** outside the copies (203's `continuous-co-review/.specrew-runtime.json`, the `.squad`
  charters, `squad.agent.md`): restored by exact path, not committed.
- **Standing exceptions**: local governance fails only on iterations 001 and 002's missing derived independent-review
  block, which is not added; the CI rerun exception for `co-review-service.Tests.ps1:129` and
  `empty-result-retry.Tests.ps1`.

## Where to attack first

1. **`Get-SpecrewCodeStackFreshnessLines`.** Is it pure and read-only? Is "more than 90 days" exact at 90 and 91? What
   does a rule with no date or a malformed date print? Does it find each stack by its `language:` scope, and does it
   skip non-stack rules?
2. **`code-lens-freshness.tests.ps1`.** Can a rule pass with a version left in its title or default? Is the version
   pattern too narrow (a format it misses) or too wide (a false hit like "PEP 8")? Do the self-tests prove each
   check can fail, and does each failure name its rule or sentence?
3. **The grouped agenda.** Is the heading order fixed, an empty heading left out, and index.yml order kept inside
   each heading? Does forcing `[Console]::OutputEncoding` have side effects on the caller's session that matter?
4. **`workshop-agenda-grouping.tests.ps1`.** Is the Latin-1 round trip a real check (the probe), and would it catch a
   writer that stops forcing UTF-8?
5. **The version facts** in `current` against the cited sources.
6. **Copies and hashes.** The deployed copies match their sources; the hash record matches the copies (CR-stripped
   SHA-256); and the specrew_version stamp is unchanged.
