---
proposal: 094
title: Documentation Update Discipline (Plan-Time Impact Declaration, Closeout Verification, Reviewer Gate)
status: candidate
phase: phase-2
estimated-sp: 8-12
discussion: ad-hoc 2026-05-22 session
---

# Documentation Update Discipline (Plan-Time Impact Declaration, Closeout Verification, Reviewer Gate)

## Why

Specrew advances rapidly — 36 proposals, 35 features shipped, multiple slice types, multiple host integrations, a maturing methodology. Each iteration potentially changes user-facing behavior: a new CLI command, a renamed flag, a new boundary, a changed default, a new slice type. The `docs/` folder (getting-started, user guide, command reference, etc.), the `README.md`, and inline help **routinely fail to keep pace**.

Empirical signals as of 2026-05-22:

- The "Squad" → "Crew" rename initiative is incomplete across proposals and docs — flagged in `proposals/INDEX.md` line 7 as known drift to be opportunistically cleaned up. This was identified weeks ago and is still open.
- F-021 shipped slash commands that deploy to the wrong path and use the wrong namespace (`.copilot/skills/` with dot-namespace) — a real functional bug, but the docs describing them weren't updated either way. Proposal 064 will fix the code; nothing will fix the docs unless someone notices.
- `specrew where` ships dashboard rendering enhancements iteration after iteration; the corresponding docs section ages out of accuracy almost as fast as code changes.
- New flags (`--autonomous`, `--readonly` candidate), new commands (the closeout-sync commands from F-032), new slice types (small-fix, debt-fix candidate) frequently miss user-facing documentation entirely. Users discover them via the CHANGELOG, retroactive proposals, or word-of-mouth.
- Inline help (`Get-Help`, slash-command frontmatter descriptions) drifts independently from external docs.

User-stated motivation (2026-05-22):

> "We advance Specrew in each iteration, but the documents under the doc folder are not always updated. The getting started, the user guide and all other. This is a debt. We need to add to the Specrew process … the need to update documentation as part of an iteration."

**Doc staleness is debt**, and Proposal 091 (Technology Debt Control) already proposes a `doc-staleness` auto-detector that creates a debt entry when `docs/` mtime falls behind code mtime. **That mechanism catches what slipped past.** This proposal closes the upstream gap: **make sure less slips past in the first place by adding a process gate at plan and closeout boundaries.** The two compose; they are not redundant.

### Why a gate, not just detection

Detection alone fails for the same reason "we should update docs" verbal commitments fail: by the time docs go stale, the iteration that should have updated them is closed, the author has moved on, and the cost of context-recovery to update docs *retroactively* is higher than updating in-flight. The right time to update docs is **while the change is being made**, not weeks later when a detector notices the gap. A gate at plan + closeout forces the question to be asked at the right moment.

## What (3 Pillars)

### Pillar 1 — Plan-time Documentation Impact Declaration

At the `/speckit.plan` boundary, the Planner is required to declare the iteration's documentation impact in the plan.md artifact. New mandatory `## Documentation Impact` section:

```markdown
## Documentation Impact

**User-facing behavior change?**: yes | no

**If yes, affected surfaces** (check all that apply):

- [ ] `docs/getting-started.md` — change required because: …
- [ ] `docs/user-guide.md` — change required because: …
- [ ] `docs/<other>.md` — …
- [ ] `README.md` — change required because: …
- [ ] CLI inline help (`Get-Help`) — change required because: …
- [ ] Slash-command frontmatter — change required because: …
- [ ] Methodology site (when Proposal 013 ships) — change required because: …
- [ ] Other (specify) — …

**If no**, justification: <e.g., "internal refactor, no user-visible change">

**Docs tasks added to tasks.md**: T0NN, T0MM, …
```

The Planner consults a heuristic decision tree (codified in the planner charter):

| Change pattern | Docs almost always required |
|---|---|
| New CLI command, flag, or subcommand | README + docs/command-reference (if exists) + inline help |
| Renamed / deprecated CLI surface | All references in docs/ + README + getting-started + CHANGELOG migration note |
| New slash command | `.github/skills/` frontmatter + docs reference (if exists) |
| New boundary in the lifecycle | docs/getting-started + docs/user-guide methodology section |
| New slice type | docs/methodology page describing slice types |
| New configuration field (`.specrew/*.yml`) | docs/configuration reference (if exists) |
| New auto-detector / validator rule | docs/quality-gates (if exists) + CHANGELOG |
| Default behavior change | README + getting-started + CHANGELOG (highlighted) |
| Bug fix with user-visible behavior change | CHANGELOG + getting-started if examples affected |
| Pure internal refactor | None required (declare "no" + justification) |

Plan-approval handoff surfaces the declaration explicitly to the user. User confirms the declaration's accuracy before approving the plan. This is a **substantive interaction moment** — the user is being asked to validate that "no docs change" is true, not just rubber-stamp it.

### Pillar 2 — Iteration tasks for declared docs work

When Pillar 1 declares affected docs surfaces, **corresponding tasks must appear in tasks.md** with effort estimates rolled into the iteration's SP capacity. Pattern:

```markdown
### T0NN: Update docs/user-guide.md for new `--readonly` flag (0.5 SP)

**Acceptance Criteria**:

- [ ] `docs/user-guide.md` section on `specrew start` describes the `--readonly` flag with: purpose, when to use it, when not to use it, an example invocation
- [ ] Markdown links to `docs/getting-started.md` updated if cross-referenced

**Owner**: Spec Steward
**Trace**: Docs impact declaration (plan.md)
```

Docs tasks have the same first-class status as code/test tasks: their acceptance criteria are checked, they appear in the iteration dashboard, and they cannot be silently skipped. The Implementer (or Spec Steward, depending on docs depth) executes them alongside code changes.

The iteration's SP capacity **absorbs** the docs work as a normal expectation — typically 0.5-1.5 SP per affected docs surface. This is non-negotiable budget; the alternative is "free docs work" that historically doesn't happen.

### Pillar 3 — Reviewer + Closeout Verification

At the `/speckit.review` boundary, the Reviewer charter is updated to verify:

- Every checkbox in the plan's `## Documentation Impact` section is reflected in tasks.md
- Every docs task has corresponding committed changes in the iteration's git diff
- Diff includes the declared docs files (mechanical check via `git diff --name-only origin/main...HEAD | grep -E 'docs/|README\.md'`)
- If the declaration said "no user-facing behavior change", reviewer spot-checks the diff for evidence that's true (e.g., no new CLI parameter additions, no new exported function added to a public module, no frontmatter-described slash-command changes)

**Form-vs-meaning protection**: it's not sufficient to have *some* edit to a docs file — the edit must address the declared scope. Reviewer is responsible for catching cosmetic-only edits that nominally check the box but don't substantively cover the change. Composes with Proposal 073 (Review Evidence Integrity).

At the `feature-closeout` boundary, the closeout-dashboard.md gains a `Documentation Impact` row summarizing what was updated, with paths and link verification. The feature-closeout commit message includes a short docs summary line.

### Sub-pillar — Composition with Proposal 091

This proposal owns the **upstream gate**: declaring + executing + verifying docs updates as part of the iteration. Proposal 091 owns the **downstream safety net**:

- The `doc-staleness` auto-detector catches files this gate missed (e.g., gate declared "no impact" incorrectly, or detector identifies broader staleness like a getting-started example referencing an old flag)
- Detector creates a debt entry with `type=docs`
- Debt entry feeds the repayment pathways (Boy-Scout at next plan that touches the file, or scheduled debt-fix slice)

The two proposals reinforce each other but solve different parts of the problem. **Neither alone is sufficient.**

### Sub-pillar — Charter updates

Three Crew agent charters need updates:

- **Planner** — must include the docs-impact decision tree at plan time; must output the declaration as part of plan.md.
- **Spec Steward** — may be the natural owner for docs tasks (Spec Steward already owns spec authoring; user-guide updates are stylistically similar).
- **Reviewer** — must include the verification checklist at review time; form-vs-meaning protection for docs work.

The Retro Facilitator gains a small responsibility: track whether the iteration's docs declaration matched what was actually shipped (false-negative rate for the gate).

## Functional Requirements

- **FR-001**: `## Documentation Impact` section is required in every iteration plan.md
- **FR-002**: Validator rule enforces the section's presence + structure
- **FR-003**: Declaration enumerates affected docs surfaces (or explicitly declares "none" with justification)
- **FR-004**: Tasks.md must contain a task for each declared docs surface, with SP estimate, owner, and acceptance criteria
- **FR-005**: Validator cross-checks plan declaration against tasks.md task entries (each declared surface has a corresponding task)
- **FR-006**: Reviewer charter updated to verify docs-task completion + diff coverage at review boundary
- **FR-007**: Closeout dashboard includes a Documentation Impact row
- **FR-008**: Feature-closeout commit message includes a docs-summary line
- **FR-009**: Planner charter updated with the docs-impact decision tree
- **FR-010**: Composition adapter with Proposal 091: when a declaration says "no docs impact" but the doc-staleness detector flags a doc that should have been updated post-ship, the resulting debt entry references the iteration's declaration as a false-negative incident (feedback loop)
- **FR-011**: Self-applied: this proposal, when it ships, updates `docs/getting-started.md` and `docs/user-guide.md` to describe the new declaration step

## Out of scope

- Auto-generating docs from code (cmdlet help, CLI man-pages) — separate proposal candidate; this one is about *human-authored* docs discipline
- Cross-language internationalization of docs
- Translating docs for downstream projects using Specrew (their docs are their problem)
- Sophisticated diff-analysis to *automatically detect* what kind of change requires what docs update — relies on Planner judgment + heuristic decision tree; not ML-classified
- A separate docs review boundary — folds into existing review boundary
- Versioning docs per Specrew release — single docs surface tracks current `main`
- Fully gating boundaries on docs (i.e., review hard-fails if docs incomplete) at MVP — soft warning first, then promote to hard fail once stable

## Effort

- **Pillar 1 (plan-time declaration + planner charter update)**: ~3 SP — section template, charter update, decision tree, validator rule for section presence
- **Pillar 2 (tasks.md integration)**: ~2 SP — validator rule cross-checking declaration vs tasks, planner charter for emitting tasks
- **Pillar 3 (reviewer + closeout verification)**: ~2-3 SP — reviewer charter update, closeout-dashboard row, form-vs-meaning verification logic
- **Composition with 091**: ~1 SP — small adapter logic for false-negative feedback loop (only meaningful once both this and 091 have shipped)
- **Self-applied docs update**: ~1 SP — update getting-started + user-guide to describe the new step
- **Total**: ~8-12 SP, single iteration

## Phase placement

**Phase 2 — Tier 1 methodology**. Documentation discipline is core SDLC hygiene, not operational tooling. It should ship before significant external adoption (~late summer 2026) so external users encounter accurate docs from the start. Composes naturally with Proposal 091 (tech debt) — recommended sequencing: ship 091 first (provides the detection safety net + debt-entry mechanism), then 094 (adds the upstream gate that reduces the load on the safety net). Both can also ship in parallel; the composition adapter is the only joining seam and is small.

## Open questions

1. **Single proposal or fold into 091?** User explicitly asked whether this should be part of debt management. Recommendation: **standalone** because the *shape* is different — 094 is boundary discipline (gate), 091 is debt management (detection + repayment). They reinforce each other but their mechanics are different. Folding would muddy 091's scope.
2. **Severity of the validator rule** — soft warning, medium, or hard fail at MVP? Recommendation: **medium warning** at MVP (visible but doesn't block boundaries); promote to hard fail at review boundary after one or two iterations validate the pattern.
3. **Who owns docs tasks — Spec Steward or Implementer?** Recommendation: **Spec Steward by default**; can be overridden per-task in the declaration. Spec Steward already authors specs (stylistically aligned with user-guide prose); Implementer is closer to inline-help / CHANGELOG.
4. **What constitutes "user-facing behavior change"?** The decision tree is heuristic. Edge cases: a refactor that changes performance characteristics measurably (probably docs-worthy if performance is a documented promise); a new optional config field with safe defaults (probably docs-worthy if users would benefit from knowing). Recommendation: bias toward "yes" in ambiguity; the cost of an unnecessary docs line is low, the cost of a missing one is high.
5. **Should the gate apply to chores and small-fix slices** (Proposal 067), or only full features? Recommendation: applies to anything with user-facing impact regardless of slice type, but small-fix slices typically don't have impact and can declare "no" trivially. Debt-fix slices (when Proposal 091 ships) often *do* have impact (they're fixing documented behavior) — should not be exempt.
6. **What about README badge updates, version bumps in docs?** These are typically mechanical and could be auto-applied at release time. Recommendation: out of scope; covered by existing release-prep automation if any.
7. **External documentation surfaces beyond `docs/`** — methodology site (Proposal 013), Medium articles, conference talks, etc. Recommendation: only `docs/` + `README.md` + inline help are gated; external publishing is the maintainer's editorial responsibility.
8. **How does this interact with Proposal 013 (Methodology Site)?** When 013 ships, the methodology site becomes another tracked surface; the declaration adds a checkbox for it. Recommendation: composability built in from MVP via the "Other" checkbox; 013 ship-time chore updates the template to list the methodology site explicitly.
9. **Backfill** — should existing shipped features get retroactive docs declarations? Recommendation: **no** — would be busywork; instead let Proposal 091's `doc-staleness` detector identify gaps and route them through normal debt repayment.

## Risks

1. **Declaration becomes a checkbox ritual** — Planner ticks "no impact" by default without thinking, gate provides false assurance. *Mitigation*: substantive interaction at plan-approval (user reviews the declaration); reviewer verification; retro tracks false-negative rate; aging-bump on repeated false-negatives.
2. **Docs-task SP burden slows iterations** — typical iteration carries 0.5-1.5 SP of docs work that wasn't budgeted before. *Mitigation*: this is the right cost to pay; the alternative is debt that costs more later. Plan-time SP capacity transparently includes docs; if iteration is over-budget, scope is reduced rather than docs cut.
3. **Reviewer fatigue** — adds another verification responsibility on top of existing review work. *Mitigation*: most iterations have small docs impact (or none); the verification is mechanical (diff path matches declaration); composes with form-vs-meaning logic from Proposal 073 which Reviewer already runs.
4. **False-positive detection from Proposal 091** — `doc-staleness` flags an iteration's docs as stale when in fact the gate was correctly applied. *Mitigation*: the composition adapter records "declared as no-impact at <feature>" so detector can suppress; manual override available.
5. **Docs updates lag the *quality* of the code change** — checkbox is ticked, file is touched, but the prose is inadequate. *Mitigation*: form-vs-meaning verification by Reviewer; retro can re-open the entry if real-world feedback shows docs weren't sufficient. Not a perfect solve; some quality is human judgment.
6. **External contributors don't know about the declaration step** — PR-flow contributors miss the gate. *Mitigation*: PR template references the gate; CI runs the validator rule on PR; clear "what's wrong" message points contributors at the docs-impact section.
7. **Decision tree becomes outdated** — new types of changes appear that aren't in the heuristic. *Mitigation*: decision tree lives in planner charter; retro can flag missing categories; periodic charter review (composes with Proposal 017 Learning Loop Closure).
8. **Inline help vs external docs drift independently** — gate covers both surfaces but they're authored separately. *Mitigation*: when a change affects inline help, the same change template usually applies to the docs/ surface; bias toward declaring both whenever one applies.

## Cross-references

- **Composes with**:
  - [091 Technology Debt Control](091-tech-debt-control.md) — primary composition; this proposal is upstream gate, 091 is downstream detection + repayment. The `doc-staleness` detector in 091 catches what this gate misses. Composition adapter records false-negative feedback loop.
  - [013 Methodology Site](013-methodology-site.md) — when 013 ships, the methodology site becomes a declared surface
  - [017 Learning Loop Closure](017-learning-loop-closure.md) — false-negative rate of the gate is a corpus row candidate; recurring missed categories feed back into planner charter updates
  - [073 Review Evidence Integrity](073-review-evidence-integrity.md) — form-vs-meaning verification mechanism is shared
  - [030 Quality Hardening Bundle](030-quality-hardening-bundle.md) — same form-vs-meaning protection pattern
  - [067 Small-Fix Slice Type](067-small-fix-slice-type.md) — gate applies to small-fix slices too (with typical "no impact" declaration)
- **Possibly subsumes**:
  - Ad-hoc "docs need updating" mentions in past retros — those would have become declarations under this gate
- **Sibling consideration**:
  - Auto-generated docs (cmdlet help → docs/, slash-command frontmatter → docs/) is a separate proposal candidate worth drafting; this proposal handles human-authored docs only

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to user observation that `docs/` surfaces routinely fall behind iteration changes. Standalone-vs-fold-into-091 decided in favor of standalone (different shape: boundary discipline vs debt collection), with explicit composition adapter for feedback loop. Awaiting clarify-time decisions on gate severity, docs-task ownership, and scope of declaration heuristic.
