---
proposal: 209
title: Regression-Registry Performance - Per-Suite Timing, Throttled Parallel Dispatch, Change-Scoped Selection
status: candidate
phase: phase-2
priority-tier: 2
estimated-sp: 2-4
discussion: maintainer question 2026-07-16 during F-198 Iteration 007 - "Can you check why running 47 tests takes so long? maybe we can improve it by running concurrently, or by reducing the number of tests, or have a better match of tests to the changes we have made?"
---

# Regression-Registry Performance

## Why

The F-198 honesty regression registry (`tests/f198-regression-suite.ps1`, ~46 explicit suites) takes
about 432 seconds per full run and runs strictly serially: a `foreach` loop spawns one fresh child
`pwsh` per suite and waits for it. During an active iteration the registry runs many times - the
Iteration 006 T050 review alone re-ran it at least six times (one per correction/verification
cycle), roughly 45 minutes of wall time spent on registry reruns in a single task.

A profiling pass on 2026-07-16 established three facts:

1. **Nobody has ever measured it.** The runner records no per-suite durations, and the digest-bound
   evidence JSONs under `.specrew/review/test-evidence/` carry only the aggregate foundation-suite
   timing. Every prior intuition about which suites are slow was unverified.
2. **The intuition is wrong.** Sampled the runner's exact invocation shape: a `script`-kind suite
   costs 1.2 s; the multi-process CreateNew race suite (`review-authority-store.Tests.ps1`, which
   spawns barrier-synchronized contender processes) costs only 4.5 s; while a "small" resolver
   suite (`trunk-resolver.Tests.ps1`) costs 11.9 s. Cost concentrates in external-process churn
   inside fixtures - repeated `git init`/`commit` child processes (~100-300 ms each on Windows) and
   full co-review engine dot-sourcing per suite - not in test count and not in the visibly "heavy"
   suites.
3. **The fixed floor is real but secondary.** Child `pwsh` spawn measures ~0.26 s and Pester import
   ~0.68 s, so ~1 s x 46 suites is roughly 45 s (~10%) of the total. The remaining ~90% is suite
   work, dominated by the fixture process churn above plus deliberate waits (timeout-ordering and
   liveness tests).

The registry's serial shape is pure implementation history: every suite already runs in an isolated
child process with `TestDrive:`/temp-directory state, which is exactly the shape a parallel
dispatcher needs. The repository has shipped this pattern before (Proposal 084 parallelized the
governance validator with `ForEach-Object -Parallel`; Proposal 086 bundled validator performance
work), so both the technique and its pitfalls are documented in-repo.

## What

- **W1 - Per-suite timing instrumentation (do this first).** The runner stamps each suite's wall
  duration on its PASS/FAIL line and optionally emits a machine-readable timing summary. Zero
  behavior change; converts all later optimization from guesswork to measurement. The evidence
  contract is untouched.
- **W2 - Throttled parallel dispatch.** Replace the serial `foreach` with a bounded worker pool
  (default ~4 workers; configurable; `-Serial` escape hatch preserved). Suites keep their isolated
  child processes, buffered output, and per-suite timeout. Expected wall time drops from ~7 minutes
  to ~2 minutes, bounded by the slowest suite tail. Two guardrails from the F-198 dogfood record:
  timing-sensitive multi-process race fixtures (the lineage-lease flake class fixed on 2026-07-16)
  may be tagged `serial` so they run alone after the pool drains; and the proof obligation follows
  the Proposal 084 pattern - repeated consecutive green runs of the parallel path before it becomes
  the default.
- **W3 - Change-scoped selection for the inner loop.** Add a `covers` glob column to each registry
  row mapping the suite to the source paths it guards. A selector mode
  (`-ChangedPaths <paths>` or derived from `git diff --name-only <baseline>`) runs only affected
  suites during development - formalizing what the F-198 Crew already does informally with
  hand-picked "focused suites". **Honesty constraint:** digest-bound evidence recording and every
  boundary/signoff gate keep requiring the FULL registry; selection accelerates the inner loop and
  is never valid evidence input. A selector miss therefore costs latency at the next full run, not
  trust.
- **W4 - Fixture-level fixes for measured hotspots.** After W1 data exists, the worst suites get
  targeted fixture work - e.g., a git-fixture-heavy suite building one shared repository per
  container instead of per test. Bounded to the measured top offenders; no speculative rewrites.
- **W5 - Retirement rider (not a performance action).** The legacy-lease suites (T019
  characterization contracts, lineage-lease, lease-gated spawn, navigator reap) become historical
  when F-198 Iteration 007 commits the campaign cutover. Their retirement from the registry happens
  WITH that cutover and is recorded as supersession - architecture retires suites; performance
  never does.

### Functional requirements

High-level capabilities (candidate form):

- Every registry run reports per-suite wall duration; optional machine-readable timing output.
- A bounded-concurrency dispatch mode with serial escape hatch, per-suite isolation preserved,
  and serial-tagged suites honored.
- A change-scoped selection mode driven by per-row `covers` globs, valid for the inner loop only.
- Full-registry-only evidence recording and gate consumption, unchanged and explicitly asserted.
- Measured-hotspot fixture optimizations with before/after timing evidence.

### Out of scope

- Removing or weakening any suite for performance reasons - the registry header's bounded-list
  contract stands; only the W5 architecture-driven retirement touches membership.
- Changing the digest-bound evidence schema or letting selected-subset runs produce evidence.
- Parallelizing inside suites (Pester `-Parallel` blocks) or rewriting fixtures speculatively.
- CI topology changes (job sharding across runners) - a later step if local wins are insufficient.

## Effort

- **Iteration 1 (~2-4 SP)**: W1 instrumentation (~0.5 SP); W2 dispatcher + serial tags + repeated
  green-run proof (~1-1.5 SP); W3 covers column + selector (~0.5-1 SP); W4 top-offender fixture
  fixes, bounded (~0.5-1 SP). W5 rides the F-198 Iteration 007 cutover, not this proposal.
- **Total**: ~2-4 SP.

## Phase placement

Phase-2. Natural timing: immediately after (or late inside) F-198 Iteration 007, whose live-smoke
and correction cycles multiply full-registry reruns - every cycle saved ~5 minutes. Not a Beta2
release blocker.

## Open questions

1. Should parallel become the default after the proof runs, or stay opt-in for one release?
2. Worker-count policy: fixed default (4) versus derived from `[Environment]::ProcessorCount`
   minus headroom for suites that spawn their own contender processes?
3. Should the `covers` selector also gate the pre-commit/inner-loop guidance in the methodology
   docs, or remain an undocumented developer accelerator?
4. Is the timing summary worth persisting (e.g., appended to the evidence JSON as non-authoritative
   diagnostics), or is console output enough?

## Risks

- **Race-fixture flakiness under CPU oversubscription**: the exact class just fixed in the
  lineage-lease fixture. Mitigated by the modest default worker count, `serial` tags, and the
  Proposal 084 repeated-green proof obligation before default-on.
- **Selection false confidence**: a developer trusts a green subset that missed an affected suite.
  Mitigated structurally - subsets are never evidence; the full registry still gates every
  boundary, so the failure surfaces at the next full run.
- **Interleaved diagnostics**: parallel children failing simultaneously could garble failure tails.
  Mitigated by the existing per-child output capture; tails print only after a child exits.

## Cross-references

- Related proposals: 084 (validator parallelization - shipped precedent and pattern), 086
  (validation-pipeline performance bundle), 208 (same-day sibling; both from F-198 dogfood
  observations).
- Source artifacts: `tests/f198-regression-suite.ps1` (the runner and its bounded-list contract);
  the 2026-07-16 profiling numbers recorded in this proposal's Why section; F-198 Iteration 006
  retro's operational-cost calibration (registry reruns per correction cycle).
- Composability with: F-198 Iteration 007 (W5 retirement rides its campaign cutover; the
  deterministic three-OS matrix multiplies registry runs and benefits first).

## Status history

- 2026-07-16: created as candidate. Maintainer performance question during F-198 Iteration 007,
  answered with a profiling pass whose numbers are recorded above.
