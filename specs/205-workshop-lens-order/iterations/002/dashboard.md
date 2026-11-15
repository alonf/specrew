# Velocity Dashboard Snapshot

**Schema**: v1
**Capture Kind**: iteration-closeout
**Captured At**: 2026-11-15T02:58:25Z
**Render Mode**: full
**Rendering Mode**: monochrome
**Color Mode**: monochrome
**Historical Notice**: Historical snapshot captured during iteration closeout. Re-running the dashboard later produces a new live view and must not overwrite this file.

## Dashboard

```text
Boundary enforcement: enabled
Last authorized boundary: iteration-closeout
Pending next boundary: (none)
Last enforcement timestamp: 11/15/2026 02:54:27
Total enforcement events: 14

SPECREW VELOCITY DASHBOARD
------------------------------------------------------------------------
Today: 2026-11-15 | Captured: 2026-11-15T02:58:25Z
Repo: specrew-220-workshop-lens-order | Branch: 205-workshop-lens-order
Rendering: monochrome-safe fallback
Summary: > F-205 Workshop Lens Order (Proposal 220) (Implementation Complete · phase iteration-closeout) | Velocity 2.22 SP/day (10 closed iterations, high)

ACTIVE WORK
Chosen: Feature 205-workshop-lens-order, as requested with --feature.
Feature: > F-205 | Workshop Lens Order (Proposal 220) | status Implementation Complete
Iteration: feature-205.iter-002 | phase ITERATION-CLOSEOUT | started 2026-11-13
In-flight: 38 SP planned | 38 SP delivered | 0 SP remaining
Multi-developer: 2 git authors | 0 machines | mode single

VELOCITY
Headline: 2.22 SP/day | confidence high
Sample basis: Based on 10 closed iteration(s), 170.6 SP across 77 calendar day(s) (avg 7.7 day(s)).
Trend: 20 / 18 / 5.8 / 17 / 25.5 / 0 / 13.1 / 19 / 40.3 / 12

RECENT SHIPPED
[x] F-205 · iter-002 ######################......  20.0 SP  2 iter 2026-11-14 Workshop Lens Order (Proposal...
[x] F-205 · iter-001 ####################........  18.0 SP  2 iter 2026-11-11 Workshop Lens Order (Proposal...
[x] F-202 · iter-003 ######......................   5.8 SP  3 iter 2026-10-24 beta4.1 UX stabilization
[x] F-202 · iter-002 ###################.........  17.0 SP  3 iter 2026-10-18 beta4.1 UX stabilization
[x] F-202 · iter-001 ############################  25.5 SP  3 iter 2026-10-16 beta4.1 UX stabilization
[x] F-199 · iter-003 ............................   0.0 SP  3 iter 2026-09-08 Beta3 Stabilization (v0.40.0-...

RECENT ITERATIONS (PLAN VS REALITY)
Iter                  Planned Actual Delta Days
feature-205.iter-002      20     20     0    2
feature-205.iter-001      18     18     0    2
feature-202.iter-003     5.8    5.8     0    4

FULL HISTORY
feature-205.iter-002    20 SP #############...
feature-205.iter-001    18 SP ###########.....
feature-202.iter-003   5.8 SP ####............
feature-202.iter-002    17 SP ###########.....
feature-202.iter-001  25.5 SP ################
feature-199.iter-003     0 SP ................
feature-199.iter-001  13.1 SP ########........
feature-199.iter-002    19 SP ############....

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
Active feature remaining: 0 SP | ETA: implementation complete | confidence high
Current phase remaining: n/a | ETA: TBD | confidence high
Roadmap remaining: 566 SP | ETA: 255 calendar day(s) | confidence high

WARNINGS
WARN: Monochrome-safe fallback forced by --no-color / NO_COLOR.
WARN: Multi-developer activity detected: 2 unique git authors; 13 feature branches; 3 close-together shared-state writes
WARN: Multiple developers detected (2 unique git authors, 13 feature branches, 3 close-together shared-state writes). Consider enabling multi-session mode: `specrew config set session_mode multi`

FOOTER
i Monochrome-safe fallback is active. Re-run without --ASCII / --no-color in a UTF-8 + ANSI-capable terminal to see the richer view.
```
