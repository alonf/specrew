# Velocity Dashboard Snapshot

**Schema**: v1
**Capture Kind**: iteration-closeout
**Captured At**: 2026-07-09T07:25:36Z
**Render Mode**: full
**Rendering Mode**: monochrome
**Color Mode**: monochrome
**Historical Notice**: Historical snapshot captured during iteration closeout. Re-running the dashboard later produces a new live view and must not overwrite this file.

## Dashboard

```text
AWAITING YOUR VERDICT: 'iteration-closeout' is committed / in-progress but NOT human-authorized (last authorized: retro). A committed boundary is not an approved one — the gate advances only when you confirm. Give the boundary verdict to authorize it; if you already approved, the session may have ended before your verdict was captured, so please re-confirm.

Boundary enforcement: enabled
Last authorized boundary: retro
Pending next boundary: (none)
Last enforcement timestamp: 07/09/2026 06:58:34
Total enforcement events: 5

SPECREW VELOCITY DASHBOARD
------------------------------------------------------------------------
Today: 2026-07-09 | Captured: 2026-07-09T07:25:36Z
Repo: specrew-197-continuous-co-review | Branch: 197-continuous-co-review
Rendering: monochrome-safe fallback
Summary: > F-197 Continuous Co-Review (In Progress · phase iteration-closeout) | Velocity 6.24 SP/day (10 closed iterations, high)

ACTIVE WORK
Feature: > F-197 | Continuous Co-Review | status In Progress
Iteration: feature-197.iter-010 | phase ITERATION-CLOSEOUT | started 2026-07-01
In-flight: 152.5 SP planned | 144.5 SP delivered | 8 SP remaining
Multi-developer: 5 git authors | 0 machines | mode single

VELOCITY
Headline: 6.24 SP/day | confidence high
Sample basis: Based on 10 closed iteration(s), 218.5 SP across 35 calendar day(s) (avg 3.5 day(s)).
Trend: 26 / 17.5 / 19.5 / 19 / 28 / 10.5 / 24 / 20 / 26 / 28

RECENT SHIPPED
[x] F-197 · iter-010 ##########################..  26.0 SP  7 iter 2026-07-09 Continuous Co-Review
[x] F-197 · iter-009 ##################..........  17.5 SP  7 iter 2026-07-02 Continuous Co-Review
[x] F-197 · iter-001 ###################.........  19.5 SP  7 iter 2026-06-27 Continuous Co-Review
[x] F-197 · iter-006 ###################.........  19.0 SP  7 iter 2026-06-24 Continuous Co-Review
[x] F-197 · iter-005 ############################  28.0 SP  7 iter 2026-06-24 Continuous Co-Review
[x] F-197 · iter-004 ##########..................  10.5 SP  7 iter 2026-06-23 Continuous Co-Review

RECENT ITERATIONS (PLAN VS REALITY)
Iter                  Planned Actual Delta Days
feature-197.iter-010      26     26     0    9
feature-197.iter-009    17.5   17.5     0    5
feature-197.iter-001    19.5   19.5     0   11

FULL HISTORY
feature-197.iter-010    26 SP ###############.
feature-197.iter-009  17.5 SP ##########......
feature-197.iter-001  19.5 SP ###########.....
feature-197.iter-006    19 SP ###########.....
feature-197.iter-005    28 SP ################
feature-197.iter-004  10.5 SP ######..........
feature-197.iter-003    24 SP ##############..
feature-184.iter-002    20 SP ###########.....

ROADMAP
[x] [###############.]   96% 62.5/65 SP   shipped      Phase 1: Foundations
                                                     Bootstrap, governance hardening, validator rigor, and quality-bar groundwork....
[ ] [##########......]   63% 159.5/254 SP in-progress  Phase 2: Developer Experience
                                                     Interaction model, visibility, public-readiness, distribution (two iterations...
[ ] [................]    0% 0/100 SP     queued       Phase 3: Runtime Abstraction & Spec Fidelity
                                                     Multi-Host Runtime Abstraction CORE (Proposal 024) as the swap-Squad foundati...
[ ] [................]    0% 0/50 SP      queued       Phase 4: Token Economy & Autopilot Experiment
                                                     Graduates Token Economy from research-stage to feature (cost guardrails). Run...
[ ] [................]    0% 0/110 SP     queued       Phase 5: Multi-Developer
                                                     Multi-Developer Reconciliation for team adoption; Expertise-Aware Adaptive In...
[ ] [................]    0% 0/110 SP     queued       Phase 6: Ecosystem & Methodology Surface
                                                     Multi-Host SECOND PROVIDER (CAO, demonstrates abstraction works), Methodology...
[ ] [................]    0% 0/100 SP     queued       Phase 7: Brownfield Support
                                                     JIT Codebase Cartography for adopting Specrew in existing large codebases. Di...
[ ] [................]    0% 0/0 SP       queued       Phase 8: Packaging & 1.0
                                                     1.0 readiness: stable distribution channels (winget / Chocolatey / Scoop adde...
[ ] [................]    0% 0/0 SP       queued       Phase 9: Public GA
                                                     Public 1.0 release. Support model, documentation completeness, contributor on...

PROJECTION
Active feature remaining: 8 SP | ETA: 2 calendar day(s) | confidence high
Current phase remaining: n/a | ETA: TBD | confidence high
Roadmap remaining: 566 SP | ETA: 91 calendar day(s) | confidence high

WARNINGS
WARN: Monochrome-safe fallback forced by --no-color / NO_COLOR.
WARN: Multi-developer activity detected: 5 unique git authors; 4 close-together shared-state writes
WARN: Multiple developers detected (5 unique git authors, 4 close-together shared-state writes). Consider enabling multi-session mode: `specrew config set session_mode multi`

FOOTER
i Monochrome-safe fallback is active. Re-run without --ASCII / --no-color in a UTF-8 + ANSI-capable terminal to see the richer view.
```
