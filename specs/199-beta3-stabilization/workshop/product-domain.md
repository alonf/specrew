# Product-Domain Record: 199-beta3-stabilization

**Feature**: 199-beta3-stabilization
**Depth**: Light
**Captured**: 2026-08-10
**Confirmation**: human-confirmed (scoped product-domain confirmation, option 1, 2026-08-10)

## Why Light

Later feature in a deeply known product. Discovery already happened empirically — the T067
blind-consumer dogfood on published beta2 bits is the user research, and the maintainer's
2026-08-09/10 rulings settled the design and closed the scope. Deeper discovery would
re-litigate decided rulings.

## User, operator, harmed party

- **User**: the consumer developer — installs Specrew from the PowerShell Gallery, runs their
  first governed feature, has never read Specrew docs or internals (the T067 persona). [known]
- **Operator/customer**: the maintainer, who ships the release and adjudicates gates. [known]
- **Harmed party**: the consumer whose first feature burns hours and tokens in an unbounded
  review loop or wedges at signoff; the ledger records that their rational response is to
  disable the campaign. [known — F8]

## Pain

Beta2 has review quality but no review economics. T067's planning digest took 20 runs and
15 fix rounds resolving 79 findings before a line of code existed, with continuation
self-minted from one grant, the console held mid-spend, and the endgame wedged because
accepted-residuals-on-an-unreviewed-tree was inexpressible. Plus: OneDrive cloud-placeholder
installs refused by the integrity check (F1), fresh projects with no verification plan
(F2/F3), infrastructure failures consuming the round allowance (F4), and stop messages in
internal vocabulary a consumer cannot decode (F6). [known — every clause has a ledger
evidence line]

## MVP / acceptance bar

A consumer completes their first feature without hitting an endless review loop, a wedged
gate, or a sentence they cannot understand. The ten Beta3-section ledger items are the
slice; the bar doubles as the release acceptance test. [known]

## Out of scope

The ledger's entire beta4 section: disposition-vocabulary cluster, evidence-pipeline choke
point, path-identity containment, full link/reparse hardening, full instrument panel,
author-attributed turn deltas, amendment-diff-at-boundary, small-fix tail. Scope is CLOSED:
new discoveries route to the beta4 list unless they block the acceptance bar itself. [known]

## Binding constraints

- One iteration, ~10–12 SP planned against the 20 SP convention. [known]
- Bridge items stay minimal; each bridge design record names what beta4 replaces. [known]
- 198 method rules: RED-first instance-pinned fixtures through the shipped entry points;
  proof lines transcribed from measurements, never drafted ahead; records state facts and
  never evaluate Specrew's own components; evidence tools verified before trusted. [known]
- Release discipline mirrors beta2: certification review before the tag, tag at the merge
  commit, publish workflow, Gallery verification; release notes must state explicitly that
  the two certify design owners (evidence-pipeline choke point, path-identity containment)
  ship in beta4. [known]

## Recorded gap

The item-10 "009/010 registry-vs-claim wording inconsistency" is records-only; specifics to
be pulled from the 198 records during implementation. [research-needed, load_bearing: false]

## Sources

- file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta3-carry-ledger.md
  (committed at b9c5bacb, read-only input of record)
- file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/closeout.md
