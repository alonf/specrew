# Drift Log: 001-nightly-appointment-export

Feature-level drift record for the design workshop. No iteration exists yet, so this log lives at the
feature level until the first iteration is scaffolded.

## D-001 Turn-end declaration not recorded for one workshop turn

- **Date**: 2026-11-14
- **Stage**: design workshop, product-domain step (question open, before the human's answer)
- **What happened**: The turn in which the human corrected the reviewer session name (to
  specrewreviewer-98) could not record its turn-end declaration. `declare-turn-end.ps1` refused with
  "the token ... matches no live session in this project (0 live tokens)". The token passed was the one
  from the most recent `[specrew-turn]` line of that turn, which carried the same value as the previous
  turn's token.
- **Impact**: One turn is missing from the turn-end record. No workshop answer was involved: the
  product-domain question was re-rendered unchanged in that turn and answered in the following turn, with
  a typed-turn receipt on record.
- **Action taken**: Not retried. Reported to the human, who approved carrying on and asked for this note.
- **Status**: recorded; no repair needed for the workshop artifacts.
