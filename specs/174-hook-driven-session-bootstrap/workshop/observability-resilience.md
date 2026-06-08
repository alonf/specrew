# Observability Resilience Workshop Record

**Lens**: observability-resilience · **Depth**: medium · **Confirmation**: human-confirmed
**Facilitated**: one decision at a time with the human (2026-06-08).

Machine-side counterpart to ui-ux decision 3 (the user-facing state line). LIR-006:
the bootstrap paths must be distinguishable *and provably so* after execution.

```text
Per bootstrap run -> ONE record in the EXISTING F-171 hook journal:
  mode               full | welcome-back | cleared-anchor
  sources            handover{present,valid}, anchor{present,valid}, marker{present}
  validation_findings why full-not-resume; what failed
  anchor_cleared     bool + reason (merged | closed | non-portable | mismatch)
  unclean_exit       bool (start marker newer than handover)
  dedupe_key / session id
```

## Decision 1 - bootstrap classification journal record

**Chosen: option 2 - structured classification record into the F-171 journal.**

- One record per B2 run with: `mode`, `sources` evaluated, `validation_findings`,
  `anchor_cleared` (+ reason: merged | closed | non-portable | mismatch), `unclean_exit`,
  and the dedupe key / session id.
- Reuses F-171's existing journal / breaker / dedupe envelope (integration-api d1) - **no
  new log surface**.
- Makes every mode and warning reconstructable post-hoc, closing the original
  silent-wrong-resume blind spot.

## Decision 2 - diagnosability + test evidence

**Chosen: option 2 - behavior + journal-assertion tests.**

- Every path (full bootstrap / welcome-back / cleared-anchor / unclean-exit /
  invalid-or-missing input) has a test asserting **both** the rendered mode (user-facing)
  **and** its distinguishable journal record (machine-facing: mode + findings +
  `anchor_cleared` reason).
- Explicit **failure-evidence** tests for missing / invalid handover / session-state.
- Rides integration-api d4's per-host empirical baseline; makes LIR-006's "distinguishable
  after execution" a hard, tested property rather than a hope.
