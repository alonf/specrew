# `specrew start` Against the Session Hooks: Facts for Iteration 002 Planning

Feature 206. Facts only, for the maintainer's decision: keep `specrew start`, freeze it to bug fixes, or retire it.
Read-only inventory of `scripts/specrew-start.ps1` (3,562 lines) and the hook path
(`specrew-hook-dispatcher.ps1` → `specrew-bootstrap-provider.ps1` → `bootstrap/SessionBootstrapManager.ps1`).
Line numbers are approximate where marked "~".

## What Only `specrew start` Does

| Responsibility | Hook does it? | Elsewhere |
| --- | --- | --- |
| Host selection, PATH check and host launch with per-host flag translation (~3034-3156, 2877-3000) | no (the host is already running) | — |
| First-run user-profile capture (3017-3028) | no: reads the profile, points to `/specrew-user-profile` | init, interactive only |
| Instruction-file heal (3007-3013) | no | init, update |
| Skill catalog repair (~3160-3194) | no | init |
| Crew runtime sync on every launch (3465-3480) | no | — |
| Session-loaded-file change detection and PAUSE-AND-CONFIRM (2136-2257) | no: the hook writes no baseline | — |
| Stale-session A/B/C recovery and stale-anchor cleanup (3220-3288) | partly: reports an invalid anchor, offers no choice | — |
| Multi-session lock and claim conflict (406-456) | partly: an advisory marker, never blocks | — |
| Full `start-context.json`, delegated routing, approval mode, boundary bypass, post-restart directive | no or partly | — |
| Version and PSGallery warnings (3291-3295) | no | init, update |

`last-start-prompt.md`: both write it, but the hook's is thinner, with empty roster, routing and project-state stubs.

## Hosts

All five supported hosts declare hook bindings (claude, codex, copilot, cursor, antigravity). The docs name
`specrew start --host antigravity` as the fallback when its hooks do not fire (`docs/getting-started.md:131-157`).
Copilot in VS Code and cloud surfaces are "unsupported" and Cursor desktop "unverified"
(`host-support-tier.ps1:124-134`); untrusted headless Codex skips hooks. The dispatcher's own failure message tells
users to run `specrew start --host` (`specrew-hook-dispatcher.ps1:501`).

## What Depends on It

Module entry points (`Specrew.psm1`, `Specrew.psd1`, `scripts/specrew.ps1:576-582`); the validator
(`validate-governance.ps1:1983, 3690`); user-facing messages that send users to it (user-profile, session-recovery,
post-bootstrap output, init, the dispatcher); `cross-platform-validation.yml`. 44 non-fixture test files reference
`specrew-start.ps1`, and 6 of them are now in the per-push CI step (T015). 22 docs files and the README mention it.

## Feature 206's Items That Are About `specrew start` Only

| Item | State | What a fix would cost (estimate) |
| --- | --- | --- |
| T003 regression: start stopped when copilot-instructions.md was missing on one side (DRIFT-014) | fixed (`30fa853a`) | nothing further |
| SC-002 / bug 21: start pauses on agent and charter files it wrote itself | open, required in iteration 002 | a design (whole files start created or repaired; which files get the matched-block treatment), then about 1.5-2 SP |
| Bug 22, run 2: a governed project with no session files (a fresh clone) is "stale" and refuses with no console | open question | test side: done (`-RecoveryChoice A`). Product side: about 0.5-1 SP if it is ruled a first start |
| Bug 23: start re-anchors to, and writes into, a feature outside its `-ProjectPath`. Route: the tracked `.squad/identity/now.md` holds an absolute `session_state_feature_path`; the session-state snapshot falls back to it when there is no prompt or start context (`session-recovery.ps1:111, 131`); recovery A makes it the resume override (`:519-520, 544`); `Resolve-FeatureDirectory` accepts any rooted path (`specrew-start.ps1:664-669`) | open; SC-001 runs 3 and 4 rewrote this repository's `state.md` | product: keep the resolved feature inside the project root, and stop writing absolute paths into a tracked file: about 1 SP |
| Bug 24: SC-001's fixture was built inside this repository | fixed (`e416edc6`), necessary but not sufficient | nothing further |
| Bug 25 (init, not start): the Squad probe runs in the install root even with `-DryRun`, and its cleanup fails silently (`specrew-init.ps1:755`, `init/squad-deploy.ps1:34`) | open; run 4 left a probe folder in this repository | probe in a temp folder, and a failed cleanup reported: about 0.5 SP |
| Bug 1 (fixed by T001) and the profile write the start-path tests redirect (T015) | fixed or worked around | nothing further |

If start is retired, the start-only items above close with it. SC-001 and SC-002 would then need a ruling of their own,
because both are defined through start; both are required in iteration 002 as things stand, and SC-001's script refuses
to run until items 23, 24 and 25 are fixed. The 6 per-push start scripts and the other start tests would go with it.
