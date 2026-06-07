# Retro: Iteration 001 — engine, channels, dispatcher, breaker, Claude binding

**Schema**: v1
**Date**: 2026-06-07
**Status**: complete

## What Went Well

- **The workshop-driven spec eliminated mid-build design churn.** Every implementation decision (engine placement, B3 detection, payload structure, breaker semantics, settings placement) was already human-bound before T001 — twelve tasks landed without a single design re-open.
- **The feature dogfooded itself live.** The review-signoff boundary sync's own stdout delivered the retro-stage digest (general + boundary.next), `{{project_root}}` resolved to clickable URLs — channel 1 worked in production on its first real firing, before the review even concluded.
- **Per-task boundary commits + suites held.** Twelve `boundary(implement)` commits, each with its tests run before "done"; 330 asserts re-run green at review.
- **The gate preflight (rule 8, maintainer-added mid-feature) paid for itself immediately**: it caught the non-canonical phase enum and the missing `verdict_history` BEFORE the human saw a packet — exactly the discipline's promise.
- **TG-004 worked as designed**: the latency bar was missed, measured honestly, and returned to the human with data and options instead of a silent fallback.

## What Was Hard

- **Gate-schema conformance at design-analysis took 3 fix rounds** — the validator's canonical section names, typed option fields, and own-line `Addressed:` format were discovered by failing, not by reading (a template existed at `extensions/specrew-speckit/templates/design-analysis.template.md` and was not used).
- **Four PowerShell traps each cost a debug cycle**: `Start-Process` mangles quoted JSON arguments (fix: stdin redirection — also the production-faithful path); dynamic member-assignment (`$obj.($name) =`) trips the binder on deserialized JSON (fix: `PSPropertyInfo.Value` setters); .NET file APIs resolve relative paths against the process CWD, not the PowerShell location; empty-array pipeline unrolling under StrictMode.
- **The pwsh process-spawn cost (~900ms) collided with the hook-latency bar** — a runtime-platform constant that the design phase priced as a risk but did not measure until review.

## Lessons Learned

1. **Measure the runtime's process-model cost at DESIGN time for hook-shaped features.** A 150ms bar against a 900ms spawn floor was decided-by-measurement one phase too late. Owner: design-workshop conduct (candidate question for the NFR lens: "what does one fire cost on this runtime?"). Next action: iteration-002 research runs measurement-first for every candidate host event.
2. **Scaffold/template first, author second.** The design-analysis template would have prevented all 3 gate-conformance rounds. Owner: me (process); applies to every canonical artifact. Next action: recorded in the plan-stage digest candidate list (iteration-002 docs task).
3. **The PowerShell trap catalog grew 4 entries** (above). Next action: fold into the implement-stage digest's known-traps line (iteration-002 docs task — digest `reviewed_at` bump rides the same commit).
4. **Answering methodology questions from memory is the drift class this feature remediates** — the maintainer's mid-feature refocus instruction (read Proposal 145 in source) materially improved the shipped digest content. Already promoted: digest rule 8 + the 145 source declaration with drift-watch.

## Calibration

| Metric | Value |
| --- | --- |
| Planned / Actual | 18.5 / 18.5 SP (per-task Actuals = estimates across T001-T012) |
| Variance | 0 SP recorded |
| Honesty note | Actuals were recorded at estimate on completion; the real calibration signal is that NO task was split, deferred, or re-scoped — the workshop-priced decomposition held. Wall-clock: a single continuous session. |

## Triage: Reviewer-Instruction Candidates

- **PROMOTE**: "Scaffold-emitted warnings require explicit disposition notes, never deletion" (this review's form-vs-meaning warning was dispositioned with a decomposition; deleting it would have hidden the signal).
- **PROMOTE**: "Validator gate schemas are templates — read/scaffold them before authoring the artifact" (plan-stage digest candidate).
- **DROP** (duplicate): "Re-run suites at review rather than quoting implementation counts" — already shipped as review-signoff digest rule 9.

## Signals for Next Iteration

- **Research-first ordering is binding**: T013 (host surface matrix incl. Copilot re-verification + per-event latency measurement) gates every T014 binding.
- **Latency re-evaluation inputs ready**: UserPromptSubmit as a B3 event candidate; engine inlining (single-spawn dispatcher) to pull B1/B2 under ~1.1s.
- **Carries (defer-approved at review-signoff)**: init/update call-site wiring for hook deploy; catalog managed-with-overlay merge; SC-008 beta validation needs ≥2 hook-bound hosts — research gates it.
- **Tooling friction filed**: `scaffold-iteration-artifacts.ps1` no longer emits the quality/ tree (hardening gate needed a separate helper run + arrived with rejected `tbd` placeholders) — defect candidate for the maintainer's tooling list.
