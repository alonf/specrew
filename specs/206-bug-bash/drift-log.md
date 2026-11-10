# Drift Log: 206-bug-bash

**Feature**: 206-bug-bash
**Scope**: feature-level findings recorded before the first iteration exists

## DRIFT-206-001 — the workshop hook stored a receipt for a message that answered no workshop question

- **Recorded**: 2026-11-10, at the maintainer's instruction. Evidence for feature 203's capture work; not
  fixed in 206.
- **What happened**: `.specrew/runtime/workshop-authority.jsonl` holds two `product-domain` receipts for this
  feature, both `human-confirmed` / `lens-question`:
  - `4c7eca3aec78a8a729bb723114182a366c9075e9e132f95eb858ae12da963c43`, recorded 03:28:23 local
    (01:28:23Z), for the maintainer's message beginning "Recovery: not an override yet…". That message
    ruled on the specify-gate recovery and the triage; no product-domain question had been asked yet.
  - `fa0b6d95b75e59ce61cf183afa0f0b64ee0d0b0459307e901910c1c2ddf38982`, recorded 03:30:24 local
    (01:30:24Z), for the maintainer's "confirm - Light depth and this picture are right…", the real answer
    to the product-domain question.
- **Consequence avoided**: only the second receipt is cited in `lens-applicability.json` and the
  product-domain record. A writer that took "any receipt for this lens" would have bound the lens to a
  message that never answered it.
- **Same class, next message**: on the maintainer's push approval ("Approved: push 206-bug-bash to
  origin…"), the prompt hook reported "your agenda confirmation was received but NOT bound". No agenda had
  been presented and none was confirmed; the hook read an approval of a push as an agenda confirmation.
  Nothing was recorded, so nothing needs undoing.
- **Owner**: feature 203's follow-up (capture work).
