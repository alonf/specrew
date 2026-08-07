# Consumer Feedback Register (F-items)

**Feature**: 198-beta2-hardening
**Status**: landed; FR mapping complete, with three findings that change Iteration 011's shape
**Authored**: 2026-08-02, discharging the obligation recorded in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/010/plan.md
("F-register, before Iteration 011 opens")

## Why this file exists

The F-labels F1..F17 have governed real scheduling decisions in this feature — they set
Iteration 011's scope, they gate the beta2 tag, and they appear in two approved maintainer
decisions. Until this file existed, **they resolved to nothing in the repository.** They lived
in the reviewer's session-local ledger from the maintainer's consumer manual test, and the
repository carried only their classification, never their definitions.

That is a traceability hole of exactly the kind this feature's spec exists to close: a plan
cannot cite an identifier a reader cannot resolve. Iteration 010's plan recorded the obligation
rather than papering over it; this file discharges it.

## What this register is, and is not

It **is** a resolution table: each F-label, the behaviour it names, where that behaviour is
recorded in the repository, its consumer-reachability classification, and whether an existing
functional requirement already governs it.

It is **not** a new requirement set. The maintainer's instruction was explicit — *map to
existing FRs first, before minting new ones.* That instruction was followed, and the answer it
produced is the most important content in this file: **for most of the consumer-severe items,
no existing FR covers the mechanism, and for one of them the spec actively mandates the
behaviour the consumer reported as a defect.** See "What the mapping found" below.

Where an F-item has no covering FR, this file says so and marks it for the maintainer's ruling
at Iteration 011's planning boundary. It does not invent an FR to fill the gap.

## Provenance and evidentiary status

These entries are **reconstructed from what the repository records**, not from the original
ledger — which is why the register was owed in the first place. Each row cites its source. Rows
whose description comes only from a classification table are marked `class-only`: a
classification is not a definition, and the difference matters when Iteration 011 has to build
against them.

**Three F-items have no recorded description anywhere in the repository: F3, F8, and F14.** They
appear only in the beta3 classification row. They are listed as gaps rather than guessed at.
Reconstructing them requires the maintainer, and they are not in the beta2 tag path, so this
register does not block on them.

## Classification (maintainer, 2026-07-30, confirmed and narrowed 2026-08-01)

The authoritative source is the approved decision recorded in
file:///C:/Dev/specrew-beta2-hardening/.squad/decisions.md.

| Class | Items | Disposition |
| --- | --- | --- |
| Already delivered in Iteration 009 | F6, F12, F13, F15, F16 | done |
| **Consumer-severe, must precede the beta2 tag** | F11, F10, F17, F1 | **Iteration 011** |
| Cheap and consumer-visible | F2, F9, F7 | Iteration 011 stretch; NOT pulled in by default |
| Beta3, after the tag | F3, F4/F4b, F5, F8, F14 | after the tag |

A correction Iteration 011's planning boundary must honour: Iteration 010 deferred "stream B" as
F11, F1, F4/F4b, F5/F9. Under the final classification **F4/F4b and F5 are beta3**, while **F10
and F17 are new to 011 and consumer-severe**. Iteration 011 re-cuts against this table rather
than inheriting the stream-B list verbatim.

## Register — consumer-severe (Iteration 011, gate the tag)

| F | What it names | Source of record | Existing FR coverage |
| --- | --- | --- | --- |
| **F1** | First-boundary arrival sync / verdict-marker. A brand-new project hits this at its very first lifecycle boundary. | `iterations/010/plan.md` (class + parenthetical gloss) | **NONE.** FR-002 is the nearest: it forbids recording a *second* crossing while the first lacks authorization, and mentions the first crossing only in a parenthetical saying it is recorded mechanically. It prescribes nothing about a fresh project arriving at boundary #1 with no cursor baseline. The marker FRs that exist (FR-045, FR-045a) govern *suppression*, never first emission. |
| **F10** | Round-ceiling tax. Every consumer whose lifecycle produces findings at two or more checkpoints is penalized; every run halts at the ceiling. | `iterations/009/plan.md:27-29`, `iterations/010/plan.md` | **The ceiling is FULLY specified — and the spec mandates the reported behaviour.** See finding 1 below. |
| **F11** | Premature verdict demand plus contradictory hook composition. A hook demands a human verdict for a stage with no evidence, risking a false human authorization. | `iterations/010/plan.md` | **PARTIAL.** FR-045 forbids rendering a verdict packet while a required co-review is pending/stale — but F11's case is a stage that has produced *no evidence at all*, which is not FR-045's subject. **Contradictory hook composition is covered nowhere:** FR-006 states only that hooks are surfacing-only, FR-045a orders stop-intent classes *within one decision*, and no FR reconciles two providers' conflicting simultaneous emissions. The false-authorization risk is covered from the capture side by FR-041/042/043. |
| **F17** | Non-convergent finality — the finality/closeout check never converges. This is what stopped the maintainer's manual test. | `iterations/010/plan.md` | **NONE.** No FR requires the finality/closeout check to converge, bound its rounds, or reach a terminal state. The one termination-adjacent clause is FR-045's single controller-owned carry-forward, which is limited to the six generated review artifacts and **explicitly excludes `state`/`plan`/`tasks`** — precisely the files a closeout writes. FR-030 is closeout *teaching*, a different mechanism. |

## Register — cheap and consumer-visible (Iteration 011 stretch, not default)

| F | What it names | Source of record | Existing FR coverage |
| --- | --- | --- | --- |
| **F2** | Workshop schema drift. | `iterations/010/plan.md` (`class-only` gloss) | **PARTIAL.** FR-056 defines the strict workshop artifact contract, but only as authority for Stop classification — it says nothing about the schema a consumer receives matching the schema the engine validates, nor about syncing it downstream. The one deployed-artifact-drift MUST, FR-032, covers a different file (`refocus-scopes.json`). |
| **F7** | Draft-checkpoint placeholders flagged as blocking. | `iterations/010/plan.md` (`class-only` gloss) | **NONE.** The spec contains no requirement about placeholder or incomplete checkpoint content. FR-019 and FR-062 touch blocking-finding semantics but not how an incomplete artifact is classified. |
| **F9** | Verdict-phrase inconsistency. | `iterations/010/plan.md` (`class-only` gloss) | **NONE.** FR-042 is a false-positive rule — approval-shaped text that merely quotes or teaches must not parse as a verdict. It does not require one canonical `approved for <boundary>` phrasing rendered and recognized identically across surfaces. That requirement exists **only in `tasks.md`** (T033 addendum, T069), never in an FR. |

## Register — already delivered in Iteration 009

| F | Task | What it names | Traced FR |
| --- | --- | --- | --- |
| **F6** | T076 | Review-engine version handshake — a stale installed engine cannot silently run when a different project engine is authoritative | **None of record.** No FR governs engine-version resolution between installed and project engines. |
| **F12** | T075 | Codex file-primary delivery without duplicate invocation — a Codex run that exits zero with empty stdout and a valid result file invokes the provider exactly once | **None of record.** Same-file inference reaches FR-060/063/064. |
| **F13** | T074 + T078 | Canonical candidate inclusion/exclusion identity, with a frozen-evidence regression | **None of record.** Same-file inference reaches FR-059/065; machinery-strip identity is FR-012. |
| **F15** | T077 | Consumer review-runtime ignore classification — consumer templates ignore/classify `.specrew/review/` runtime evidence | **None of record.** Same-file inference reaches FR-027. |
| **F16** | T074 + T078 | Canonical candidate identity, paired with F13 | **None of record.** As F13. |

"None of record" here is not a claim that the work was untraceable — it is the literal state of the
traceability tables. See finding 3.

## Register — beta3

| F | What it names | Status |
| --- | --- | --- |
| **F4 / F4b** | Pre-iteration window (F4) and lost exception text (F4b) | Described in `iterations/010/plan.md`; re-classified from stream B to beta3 |
| **F5** | Recorded only as "as originally scoped" — no independent description | `class-only`; needs a definition before it can be built |
| **F3** | *(no description recorded anywhere in the repository)* | **GAP — needs the maintainer** |
| **F8** | *(no description recorded anywhere in the repository)* | **GAP — needs the maintainer** |
| **F14** | *(no description recorded anywhere in the repository)* | **GAP — needs the maintainer** |

## What the mapping found

Mapping to existing FRs first was the right instruction, and it produced three findings that
Iteration 011's planning boundary has to absorb.

### Finding 1 — F10 is not an implementation gap. The spec mandates the behaviour.

FR-019 states, as a MUST: *"The round ceiling is an AI-usage spend allowance: EVERY review round
counts toward it, including fix-responsive rounds"*, and *"resolving a finding
(`resolved-against-disk`) clears the blocking finding + its lineage but MUST **PRESERVE the
spent-round count** — it NEVER implicitly replenishes the allowance."* FR-058 adds that only a
human may grant more allowance; FR-062 that a rerun consumes another authorized slot.

Nothing in the spec scopes or scales the ceiling per checkpoint or per boundary. So the
round-ceiling tax F10 reports is the specified design working as written, and the maintainer's
own consumer test hit the ceiling on every run because the requirement says it should.

**Consequence: F10 cannot be implemented in Iteration 011 as a fix. It requires amending FR-019**
— which is a specify-boundary change, not implementation work. That amendment carries a real
design question (per-checkpoint scoping? auto-scaling with checkpoint count? a distinct allowance
class for fix-responsive rounds?) that FR-019's two prior amendments were specifically about.
Iteration 009's plan already flagged the adjacent version of this: *"Proposal 209 does not define
verification-evidence reuse or ceiling auto-scaling."*

### Finding 2 — three of the four consumer-severe items have no covering FR at all

F1, F17, and half of F11 are not partially covered; they are absent. There is no requirement that
the finality check converges, none about first-boundary arrival, and none about composing
contradictory hook emissions.

That is not a criticism of the spec — these are behaviours a consumer found by running the tool,
which is what a consumer test is for. But it means **Iteration 011 is not a pure implementation
iteration.** Its scope, as currently written, is four items of which three need requirements
written before they can be built and verified, and the fourth needs an existing requirement
amended. Planning it as implementation-only would repeat Iteration 009's capacity failure in a
new form: work whose real shape was discovered after the estimate.

### Finding 3 — `tasks.md` stopped being maintained at Iteration 008

The feature-level `tasks.md` ends its task inventory at Iteration 008 and its bidirectional
traceability checks at the Iteration 008 section. **T072–T079 (Iteration 009) and T080–T085
(Iteration 010) appear nowhere in it** — verified by direct search: zero matches for either range.
Iteration 009's plan used the F-labels themselves in its Requirement column instead of FR IDs,
which is the root of the whole problem this register exists to fix: an iteration was planned
against identifiers that resolved to nothing, and the feature-level traceability check that would
have caught it was never extended to cover that iteration.

This is recorded as a drift entry rather than fixed here, because backfilling two iterations of
traceability is real work with a real estimate, and quietly absorbing it is the pattern this
feature has spent nine iterations learning not to repeat.

## What Iteration 011's planning boundary must decide

1. **F10's vehicle**: an FR-019 amendment at a specify boundary, with the design question named,
   or a deliberate decision to tag beta2 with the round-ceiling tax standing as a documented
   limitation alongside limitation 1.
2. **Whether F1, F17, and F11's composition half get FRs written in 011** or are built against
   the register's descriptions with the FRs backfilled — the former is honest, the latter is how
   Iteration 009 got into trouble.
3. **F3, F8, F14 descriptions** — needed before beta3, not before the tag.
4. **The `tasks.md` backfill** for Iterations 009 and 010 — scope and vehicle.

## Provenance

- Classification source: file:///C:/Dev/specrew-beta2-hardening/.squad/decisions.md
- Obligation recorded at:
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/010/plan.md
- Requirement register: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/spec.md
  (FR-001..FR-065 plus FR-045a — note that the Traceability Map inside it stops at FR-040, which
  is the staleness that produced the incorrect "FR-001..FR-040" figure in Iteration 010's plan
  packet)
- Release claim gated by these items:
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md
