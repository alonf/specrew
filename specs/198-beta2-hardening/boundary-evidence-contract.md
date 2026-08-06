# The Boundary Evidence Contract

**Feature**: 198-beta2-hardening
**Status**: authored 2026-08-06 under FR-068 (T090); the two orphan boundaries ruled by the maintainer
**Executable expression**: `Get-SpecrewBoundaryStageEvidenceContract` in
file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/scripts/shared-governance.ps1

## Why this document exists separately from the code

This table was authored, not derived. **Before it, nothing in the repository mapped the nine canonical
lifecycle boundaries to the evidence each stage owes** — and four different partial encodings existed,
none of them boundary-keyed:

- the active work-kind lifecycle contract names evidence *categories*, and names only `spec.md` as a
  file;
- the single enumeration of boundaries in code carries no artifact information at all;
- the governance validator's artifact requirements are keyed on `plan.md`'s **Status**
  (`executing`/`reviewing`/…) — five statuses against nine boundaries, with **no mapping between the
  two axes**;
- its one hard-coded artifact list is gated on a git diff, so it cannot answer a static "what does
  stage X owe".

The nearest thing to an authored mapping anywhere in the tree was a list inside a test fixture,
covering one boundary.

It is recorded here rather than only in code because **it outlives the task that needed it.** It is
the spine three separate defects in this feature leaned on without it existing: FR-066's silent first
boundary (nothing could say what the boundary owed), the DRIFT-198-I009-044 closure wall (no way to
express what a stage had and had not satisfied), and DRIFT-198-I010-008's backward-crossing gap (no
per-boundary notion of completeness to reason about). A table living only inside a Stop-hook helper
would be found by the next person only by accident.

## The contract

| Boundary | Owes | Kind | Provenance |
| --- | --- | --- | --- |
| `specify` | `spec.md` | feature-file | The work-kind lifecycle contract names it explicitly — the only artifact named as a file anywhere. |
| `clarify` | a dated Clarifications session block in `spec.md` **OR** a recorded skip-with-rationale | content, **any-of** | **Maintainer ruling 2026-08-06.** Both arms are lived practice. |
| `plan` | `iterations/<NNN>/plan.md` | iteration-file | The iteration scaffolder emits plan/state/drift-log. |
| `tasks` | `iterations/<NNN>/plan.md` | iteration-file | Authored — the task breakdown lives in plan.md's Tasks table in this methodology, so no separate per-iteration tasks file is invented. |
| `before-implement` | `iterations/<NNN>/quality/hardening-gate.md` **and** `plan.md` | iteration-file, all-of | Reconstructed from the launch-contract documentation table; **promoted to contract by this authoring act.** |
| `review-signoff` | `iterations/<NNN>/review.md` | iteration-file | The validator already treats `review.md` as required. |
| `retro` | `iterations/<NNN>/retro.md` | iteration-file | The validator already treats `retro.md` as required. |
| `iteration-closeout` | `iterations/<NNN>/state.md` | iteration-file | The validator already treats `state.md` as required. |
| `feature-closeout` | *(nothing — deliberately ungated)* | none | The closeout record's name and location come from the project's `repository-governance.yml`. Guessing here would block a legitimate closeout on a forge convention the project rejected. |

### Why `clarify` has two arms

A contract with only the session-block arm would force ceremony on projects whose design workshop
legitimately resolved every open question — **the exact noise class this requirement exists to
remove.** Skip-with-rationale is a first-class clarify outcome, so its presence satisfies the boundary
just as a session block does.

### Why `before-implement` is worth noting

The validator already demands hardening-gate follow-through at `complete` status — the Iteration 003
closure surfaced its five concerns that way. So the pair was already half-enforced at the **back**
door. This contract makes the **front** door match it.

## Two design rules, both load-bearing

**1. It fails OPEN, always.** An unknown boundary, an unresolvable feature path, a missing iteration
number, or any read error yields *satisfied*. This contract can suppress a verdict demand, so a bug
in it must never invent a block on a legitimate boundary. Absence is reported only when the paths were
genuinely resolvable and genuinely absent.

**2. It gates the DEMAND, never the CROSSING.** Evidence absence sets a separate flag; it does **not**
clear `HasPendingVerdict`. This is not a style preference — clearing that flag breaks verdict
*capture*: `ConversationCaptureAccessor` returns early when the state is not pending and skips its
marker cross-check, so a human's real verdict on a legitimately-pending boundary would be **silently
dropped**. That would convert an over-demanding gate into a lost authorization, on the very path this
iteration exists to protect.

Every consumer of the flag must honour the same split. The gate reaches three surfaces:

- `Get-SpecrewPendingVerdictState` — both branches, from one shared helper so they cannot drift;
- the conformance provider — a distinct block kind that names what is missing and offers no options
  and no marker;
- the pending-verdict **stop artifact** — suppressed, because that file is what the packet renderer
  reads the marker out of. Suppressing the demand while still supplying the marker through the
  artifact would have been a partial correction under a complete-sounding claim.

## Minimality

Every row is deliberately the smallest checkable thing. **The gate exists to catch "the stage produced
nothing", not to audit completeness.** A too-eager row becomes a false block on legitimate work —
which is the same defect class as the over-demanding gate this requirement corrects, arriving through
the correction itself.

## Changing this contract

It decides product-wide gate semantics. Adding a row, tightening one, or moving a boundary out of
`none` changes what every downstream consumer is blocked on. Treat an amendment as a specify/clarify
boundary change with a recorded human ruling — the way the `clarify` and `before-implement` rows were
themselves ruled — not as an implementation detail.
