# Follow-up seed: proposal 220's remaining scope

**Written**: 2026-11-16, at feature 205's Amendment A4 (DRIFT-205-INTAKE-008).
**Starts**: after feature 203 is on main. Feature 205 merges first; the maintainer's order is 206, 205, 203.
**Source**: proposal 220 (`proposals/220-workshop-lens-order-and-cross-lens-consistency.md`), status
`partially-shipped`.

This note seeds the follow-up feature's intake. It is input, not a spec: the follow-up runs its own design workshop.

## Scope

From proposal 220:

- **FR-002 / FR-003, the two-pass split**: problem sections at intake, before the spec is written; solution sections
  at design-analysis.
- **FR-006 / FR-007, the end-of-lens back-check**: after each confirmed lens, check every earlier confirmed lens for
  contradiction, mootness, a new constraint or a changed threshold. When nothing changed, render one line and ask
  nothing.
- **FR-008 / FR-009, the amendment flow**: an amendment is recorded only on the human's typed reply, with its receipt,
  and the original decision and receipt are kept. A `bindings` conflict enters this flow, and an unresolved one still
  blocks the workshop from finishing.
- **FR-010 / FR-011, the final sweeps**: one before the spec is written (problem space), and one at the end of
  design-analysis (every solution decision traces to an NFR, constraint or requirement).
- **FR-012**: an externally fixed solution fact can be recorded as a problem-space constraint.
- **FR-014, the fixtures**: scripted workshop runs in which the back-check catches a changed constraint, the final
  sweep catches a contradiction made without a binding, and a lens with no influence adds no human turn.

## What closes on main when it ships

Feature 205 shipped one pass, problem-first inside each lens. A lens with questions in both spaces still asks its
solution questions at intake, before architecture-core runs (`workshop/architecture-core.md:16`). The two-pass split
closes this gap.

## The one dependency on feature 203

The amendment flow (FR-008/FR-009) depends on 203's code. An amendment needs the human's typed reply with its
receipt, and 203 changes the receipt store, `extensions/specrew-speckit/scripts/workshop-authority-store.ps1` (T013,
B5F-066: `Test-SpecrewWorkshopRecordSender` and a turn identity on each receipt). Build on the store as 203 leaves it.

The rest of the scope does not need 203's code; it is scheduled after 203.

## Shared merge surface

Feature 203 also edits the design-workshop skill:

- `extensions/specrew-speckit/squad-templates/skills/design-workshop.md`;
- the host copies under `.claude/`, `.agents/`, `.cursor/` and `.github/skills/specrew-design-workshop/`.

The two-pass split rewrites the same skill, so start from main after 203's merge.

## Items carried from feature 205's iteration 001 gap list

- The short-name lens lists outside the id sweep: the skill's frontmatter description and launch-contract rule 9a.
- **In 203's protected folder** (`scripts/internal/continuous-co-review/`). Feature 205 did not touch these:
  - The short-name lens list in the reviewer prompt, `worktree-reviewer.ps1`.
  - The comment at `review-signoff-evidence-gate.ps1:589` (line number as of 205's branch) needs reordering, and its
    temporary exemption removing.

## Practice notes carried from feature 205

- **Changes after a review round**: the sign-off gate classes Markdown outside `specs/` and all of `.specify/**` as
  records (205's iteration 003, DRIFT-013). Any lens, skill, template, conduct or deployed-copy change made after a
  round gets a new round, whatever the gate says.
- **Major and blocking findings**: until 203's review engine is on main, a major or blocking finding is demoted to
  minor unless its description contains the literal clause "Failure scenario:". The round scope file must tell the
  reviewer to state a concrete failure scenario, with that clause, for every blocking or major finding. 203 fixes
  this, so check whether the rule is still needed when the follow-up starts.
- **Retro lessons from feature 205's iteration 003**:
  - Run the parity check after each lens, skill or template task, and read every failing item.
  - The Capacity line is the sum of the task efforts; the rework buffer goes in the Phase Baseline.
  - Keep per-item checks with self-tests that remove, swap and reword.
  - Write a zero-finding Gap Ledger as one line ending "fixed-now".
