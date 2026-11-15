# Velocity Dashboard Snapshot

**Schema**: v1
**Capture Kind**: iteration-closeout
**Captured At**: 2026-11-14T21:24:15Z
**Render Mode**: full
**Rendering Mode**: monochrome
**Color Mode**: monochrome
**Historical Notice**: Historical snapshot captured during iteration closeout. Re-running the dashboard later produces a new live view and must not overwrite this file.

## Dashboard

```text
AWAITING YOUR VERDICT: crossing 'crossing-e704b0eb78c1b09803a34e74c706b3dcde0bacac1aa683aad879d7ddaee9172c' (retro -> iteration-closeout) at commit 825b186f88196f90a536374f2420ab21cebf93cf, Git tree ec7775c555897da617cd60a954fe1b0d97c3c62c, is NOT human-authorized (last authorized: retro). Give the explicit verdict 'approved for iteration-closeout' to authorize this exact crossing; numeric replies are not authority.

Boundary enforcement: enabled
Last authorized boundary: retro
Pending next boundary: iteration-closeout
Last enforcement timestamp: 11/14/2026 20:54:50
Total enforcement events: 7

SPECREW VELOCITY DASHBOARD
------------------------------------------------------------------------
Today: 2026-11-14 | Captured: 2026-11-14T21:24:15Z
Repo: specrew-206-bug-bash | Branch: 206-bug-bash
Rendering: monochrome-safe fallback
Summary: > F-206 206-bug-bash (In Progress · phase retro) | Velocity 3.09 SP/day (10 closed iterations, high)

ACTIVE WORK
Chosen: Feature 206-bug-bash, as requested with --feature.
Feature: > F-206 | 206-bug-bash | status In Progress
Iteration: feature-206.iter-001 | phase RETRO | started 2026-11-10
In-flight: 20 SP planned | 0 SP delivered | 20 SP remaining
Multi-developer: 2 git authors | 0 machines | mode single

VELOCITY
Headline: 3.09 SP/day | confidence high
Sample basis: Based on 10 closed iteration(s), 157.6 SP across 51 calendar day(s) (avg 5.1 day(s)).
Trend: 5.8 / 17 / 25.5 / 0 / 13.1 / 19 / 20 / 17 / 20 / 20.3

RECENT SHIPPED
[x] F-202 · iter-003 ######......................   5.8 SP  3 iter 2026-10-24 beta4.1 UX stabilization
[x] F-202 · iter-002 ###################.........  17.0 SP  3 iter 2026-10-18 beta4.1 UX stabilization
[x] F-202 · iter-001 ############################  25.5 SP  3 iter 2026-10-16 beta4.1 UX stabilization
[x] F-199 · iter-003 ............................   0.0 SP  3 iter 2026-09-08 Beta3 Stabilization (v0.40.0-...
[x] F-199 · iter-001 ##############..............  13.1 SP  3 iter 2026-08-29 Beta3 Stabilization (v0.40.0-...
[x] F-199 · iter-002 #####################.......  19.0 SP  3 iter 2026-08-29 Beta3 Stabilization (v0.40.0-...

RECENT ITERATIONS (PLAN VS REALITY)
Iter                  Planned Actual Delta Days
feature-202.iter-003     5.8    5.8     0    4
feature-202.iter-002      17     17     0    2
feature-202.iter-001    25.5   25.5     0    4

FULL HISTORY
feature-202.iter-003   5.8 SP ####............
feature-202.iter-002    17 SP ###########.....
feature-202.iter-001  25.5 SP ################
feature-199.iter-003     0 SP ................
feature-199.iter-001  13.1 SP ########........
feature-199.iter-002    19 SP ############....
feature-198.iter-011    20 SP #############...
feature-198.iter-010    17 SP ###########.....

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
Active feature remaining: 20 SP | ETA: 7 calendar day(s) | confidence high
Current phase remaining: n/a | ETA: TBD | confidence high
Roadmap remaining: 566 SP | ETA: 184 calendar day(s) | confidence high

WARNINGS
WARN: Monochrome-safe fallback forced by --no-color / NO_COLOR.
WARN: Multi-developer activity detected: 2 unique git authors; 13 feature branches; 4 close-together shared-state writes
WARN: Multiple developers detected (2 unique git authors, 13 feature branches, 4 close-together shared-state writes). Consider enabling multi-session mode: `specrew config set session_mode multi`

FOOTER
i Monochrome-safe fallback is active. Re-run without --ASCII / --no-color in a UTF-8 + ANSI-capable terminal to see the richer view.
```
