# Workshop Diagram: architecture-core — Retire Top-Level Evaluation Surface

**Feature**: 170-retire-evaluation-surface
**Lens**: architecture-core (light)
**Date**: 2026-06-06
**Status**: human-confirmed

Before/after structure diagram surfaced in-band during the intake workshop and
confirmed by the maintainer.

```text
BEFORE (public-looking surface)          AFTER (test infrastructure)

evaluation/                              tests/
+- README.md   (stale: promises a       +- support/
|               harness that never      |  +- process-quality-scorer.ps1   <- moved (99% rename)
|               shipped)                |       ^ pure library: no public CLI contract
+- report.md   (stale generated         +- integration/
|               artifact, tracked)         +- process-quality-scorer.ps1  -- CI entry point (AC2)
+- scorers/                                +- process-quality-report.ps1  -- CI entry point (AC3)
   +- process-scorer.ps1                   |    \- generated report -> scratch/test-result space (untracked)
        ^ consumed only by CI tests        +- multi-host-lifecycle-smoke.tests.ps1 -- parses scorer (AC4)
```

## Decision (human-confirmed)

The process-quality scorer is **test infrastructure**: its only consumers are
the two CI integration-test entry points, so its supported contract surface is
"internal test support reachable through `tests/integration/*`", not a public
evaluation harness. `tests/support/` is the long-term home for shared test
infrastructure. The break with the old public surface is clean — no stub or
pointer is left behind; the only docs mention is retirement-explanation wording.
Generated report output moves to untracked scratch/test-result space.

- **Reversibility**: cheap — a future public evaluation surface would be a
  fresh governed slice, named as deferred scope in Proposal 169.
- **Binding constraint**: the two integration-test entry points and CI job
  names stay frozen; the move must be invisible to CI semantics.
