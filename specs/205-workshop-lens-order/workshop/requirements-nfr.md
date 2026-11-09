# requirements-nfr: 205-workshop-lens-order

**Depth**: medium. **Confirmation**: human-confirmed (lens-question). All five decision points were answered in one typed reply on 2026-11-09.

## Order surfaces found at intake

```text
Surface that lists lenses in an order            Agrees with index.yml?
-----------------------------------------------  ----------------------
index.yml (catalog)                              -- reference --
skill source squad-templates/skills/design-workshop.md:24      no
  + deployed copies (.claude .agents .github .cursor skills, .specify)  no
methodology docs/methodology/design-workshop-methodology.md (Band 2 table, example agenda :259)  no
before-specify command speckit.specrew-speckit.before-specify.md:11  no (a 5th order)
agenda writer confirm-workshop-agenda.ps1        coverage only; order comes from the crew's JSON
```

## Decisions

1. **Binding constraints:**
   - index.yml is the only definition of the lens order.
   - FR-013: no confirmed agenda changes.
   - Iteration 1 is single-pass.
   - The existing gate readers of `## Design Decision Points` keep working.
   - 203, its pin and C:\Dev\specrew-b4f-142 are untouched.
   - 204 stays reserved.
   - **Deployed copies are produced by the sync, never edited by hand.**

   **Preference:** touch the fewest files.
2. **Out of scope:** everything in iteration 2 (the two-pass split, back-check, amendments, bindings flow, sweeps, FR-014 fixtures), new lenses, rewording questions beyond the two that move from architecture-core, and Proposal 162.
3. **FR-001 parity proof (option b, known surfaces plus a sweep):**
   - The sweep covers shipped text only. `specs/` and `proposals/` are historical records and are never scanned or rewritten.
   - A list passes when its lenses appear in the same relative order as index.yml, so a subset needs no exemption.
   - An exemption is only for a list that must differ, and each one states its reason. The exemption list is shown to the human when it exists; it is expected to be close to empty.
   - A deployed copy that differs from its source fails, and the message says to run the sync.
   - Agenda writer: refuse a new agenda whose selected lenses break index.yml's relative order. Never reorder silently. Agendas confirmed before the release are exempt (FR-013).
4. **FR-005 tagging proof:**
   - a. Every lens file has both a problem section and a solution section, or exactly one plus a line saying the other space has no questions.
   - b. Every decision point sits in exactly one space, and none is left untagged.
   - c. The space each lens has in index.yml matches the sections its file actually has.

   The section shape is decided in data-storage. It must keep both gate readers of `## Design Decision Points` (design-analysis-gate.ps1, lens-applicability.ps1) working, and a test must prove that.
5. **Failure output:** each mismatch names the file and line, the expected order from index.yml, the order found, and the fix. One run reports every mismatch, not only the first. The test runs in the normal Pester suite and in CI.

## Amendment (from architecture-core, human's typed reply on 2026-11-09)

Decision 3's relative-order rule now applies only to **partial** lists, such as an example agenda. Surfaces that present the **full** lens list (the skill's list, the methodology catalog tables and the catalog README) must match index.yml exactly, in order and in membership. The test names which surfaces are full. The original decision above is kept as written.

## Scope amendment (human's typed reply at data-storage, 2026-11-10)

The non-goal "new lenses or questions" applies to **iteration 1**. The feature now has three iterations:

- **Iteration 2 (problem-space completeness):** fill the problem side of the existing lenses where it is thin, for example data-storage never asks what data exists, how sensitive it is, how much there is, or what must be carried over. Iteration 2 has its own short workshop, where the human decides between new questions and a new lens.
- **Iteration 1** adds one output for it: while tagging, list every problem-side gap seen, per lens.
- **Iteration 3:** the back-check, amendments and sweeps, still waiting for 203.

The original text above is left in place.
