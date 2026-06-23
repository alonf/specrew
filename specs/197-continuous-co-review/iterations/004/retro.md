# Retrospective: Iteration 004 (Phase B part 1 — #2885 latency fix + opt-in gate enforcement)

**Feature**: 197-continuous-co-review
**Iteration**: 004
**Date**: 2026-06-23
**Base**: merge `6c502c20` (origin/main = F-185 host-neutral hook surface + 0.39.0-beta1)

## Outcome

Delivered on the post-185-merge base: the **#2885 Stop-hook latency fix** (parse the
transcript tail once and share it across the three handover consumers — **75.5% measured
reduction**, 1,400 ms -> 342 ms on a 2000-line transcript) and the **opt-in co-review gate
enforcement wiring** (`Assert-…SignoffGate` into the boundary chokepoint behind a
default-OFF `co_review_gate_enforcement` flag). Full continuous-co-review suite **192/0**, no
F-184-protected surface touched, zero repo pollution.

## Capacity calibration

- Planned: 12.00 SP. Actual: **10.50 SP** (T071 conformance memo subsumed -1.50 after
  measurement proved it unwarranted). Variance: honest scope reduction, not under-delivery.

## What went well

- **Test-first delegation for the delicate refactor (T070):** the implementer locked
  behavior by dot-sourcing the PRE-refactor function from git and proving byte-identical
  output + a non-vacuous parse-once witness; I re-verified independently before trusting it.
- **The adversarial 145 review earned its keep:** Reviewer B caught a real MAJOR — the
  opt-in flag parser silently dropped `true # comment` / single-quotes (fail-open to operator
  intent), a regression vs the repo's own sibling parser. Fixed + 4 regression tests. All five
  bypass/fail-open probes came back clean.
- **Measurement-driven right-sizing (T071):** rather than build the planned memo, a 60-second
  measurement showed the conformance parse was already 10 ms — so it was dropped honestly.
- **Robustness catch:** pinned the byte-identical goldens to LF so a CRLF checkout can't
  silently kill the regression guard on CI.

## What was hard / lessons

- **The Workflow tool stream-idle-timed-out again** (the T073 implementer's final report was
  lost to the timeout, though all its work landed and verified). Reinforces the standing
  lesson: use direct Agents, not the Workflow tool, for heavy single agents in this env.
- **Latency mis-attribution (my error):** I twice blamed #2885 for a downstream dogfood's
  ~14-minute lens-creation slowness — first via a version error (the dogfood ran the dev tree,
  not the published build), then by over-weighting the parse cost — before the maintainer
  diagnosed it by switching to a faster model. The delay was **model call time**, not Specrew.
  Lesson: model generation speed is a confounder that dwarfs hook latency; isolate the
  variable (measure, or change one thing) before attributing a slowdown to Specrew.
- **Dev-tree-vs-installed resolution ambiguity:** which code a dogfood host actually runs is
  decided by `SPECREW_MODULE_PATH` propagation to the host process, NOT by the config version
  (the dev tree and the published build can share a version number). Pin the env, not the version.

## Action items (carried)

- **Iteration 005 = the async Stop-hook navigator (B):** the approved self-limiting-watchdog
  reviewer + `.specrew/review/pending/<run-id>.json` registry + reaper (next-stop + SessionStart
  sweep), registered as a provider in `refocus-scopes.json` (host-agnostic via 185's dispatcher).
- **Non-blocking 145 follow-ups:** the `TrunkName='main'` default (non-`main`-trunk repos fail
  CLOSED at the gate) and the F2 nested-key fail-safe — fold into 005 or file as proposals.
- **SC-012 maintainer real-host smoke test** after the 005 auto-fire lands.
- **Base-lifecycle observation (not 197-specific):** the lens co-design step's token footprint
  is worth a look on its own merits; surfaced during the dogfood, decoupled from latency.
