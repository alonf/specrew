# Proposal-145 reviewer-family candidate: `evidence_locus` (build != live)

> **STATUS: DRAFT candidate — file to `proposals/` on `main`, NOT this feature branch.**
> This is the T040 deliverable: the GENERALIZED reviewer-family rule. It is to be reconciled INTO
> Proposal 145 (the Structured Multi-Phase Reviewer) on the **F-174 rebase to main**, then committed to `main`
> as a proposals-dir change (per the proposals-go-to-main discipline). It is captured here in the
> iteration workspace so it does not contaminate the feature branch's `proposals/` tree.

## Problem (the D-009 lesson)

F-174 iteration 005 shipped a review that OVERCLAIMED: the body plumbing was built + unit-tested, but the
live wiring was proven only in the **dev tree**, never in a real installed-module deploy. A "works /
surfaces / drives" claim backed by dev-tree-only evidence is the **build != live** trap — a floor that runs
only in the source tree is not a live-wiring guarantee. The structural reviewer had no field to distinguish
"proven where it ships" from "proven in the dev tree," so the overclaim passed.

## Proposed rule (reviewer-family; reconcile into Proposal 145)

1. **`evidence_locus` field on the 145 claim ledger.** Every claim in the structured reviewer's
   machine-readable claim ledger that asserts a runtime behavior ("surfaces / fires / drives / writes /
   reaches the model") MUST carry `evidence_locus`, one of:
   - `deployed` — the evidence came from a real installed-module run (packed from the FileList, resolved via
     `Get-Module -ListAvailable`), i.e. the path a downstream user actually hits.
   - `dev-tree` — the evidence came from the source tree (dot-sourced in place / `SPECREW_MODULE_PATH` /
     a co-located smoke).
2. **Refusal rule.** The structured reviewer REFUSES a "delivered-live" / runtime-recorded verdict for any
   such claim whose `evidence_locus` is `dev-tree` only. Dev-tree evidence may support a "plumbing-built"
   claim, never a "delivered-live" one. A delivered-live verdict requires `evidence_locus: deployed`.
3. **Plumbing-vs-injection split carries the field.** Where a behavior is auto-provable on disk (plumbing)
   but its last mile is a manual observation (e.g. injection-reaches-model), the auto claim records
   `evidence_locus: deployed` for the plumbing AND the manual observation is tracked separately — the claim
   is "delivered-live" only when BOTH are satisfied (never plumbing-green mistaken for the whole).

## Already-live secondary home (this iteration, in-branch)

The same convention is documented, free-text, in the shipped hardening-gate schema generator
(`extensions/specrew-speckit/scripts/run-hardening-gate.ps1`, the `RuntimeEvidenceStatus` cell): at review,
the cell records the evidence + its locus, and the review refuses delivered-live on dev-tree-only evidence.
That is the iteration-local + schema-doc home; THIS candidate is the generalized, coded reviewer-family
enforcement, deliberately deferred to the 145 family rather than hand-coded into the shared validator now
(a coded change to the shared validator would itself be an unevidenced "delivered-live" governance claim).

## Reconcile / sequencing

- Reconcile into Proposal 145 (Structured Multi-Phase Reviewer) on the **F-174 rebase to main**; do not file as a
  standalone proposal (maintainer instruction: "file as a Proposal-145 reviewer-family candidate, not
  standalone").
- Coded enforcement ships when the 145 reviewer family ships; until then the discipline is carried by the
  hardening-gate cell convention + the reviewer's standing judgment.
