# Implementation Plan — F-044 Per-Host Architecture Refactor

**Feature**: F-044
**Created**: 2026-05-24 (retroactive)
**Source spec**: [`spec.md`](./spec.md)
**Source proposal**: file:///C:/Dev/Specrew/proposals/108-specrew-init-refactor-and-crew-runtime-abstraction.md

## High-level sequencing

This feature shipped across **two iterations on the `multi-host-integration-refactor` branch**, bundled with F-043's PR:

| Iteration | Scope | Story points | Closeout state |
|---|---|---|---|
| **iter-001** | Phases A-D registry refactor + Proposal 108 Slices 1-9 (init split + 5th contract function + 4 Install handlers + canonical team source-of-truth + Slice 9 finalization) | ~22-25 SP | Closed with 22 known issues identified by 4-agent deep review (3 BUG / 11 WARN / 8 NIT) |
| **iter-002** | Deep-analysis bug-fix bundle addressing all 22 findings | ~6 SP | Closed clean |

The two-iteration shape was a deliberate methodology demonstration: iter-001 ships the architectural work with the review-gate finding bugs honestly; iter-002 is the fix-slice that demonstrates the review-gate working. See [`iterations/001/review.md`](./iterations/001/review.md) and [`iterations/002/scope.md`](./iterations/002/scope.md) for the closing rationale.

## iter-001 phase breakdown

The work shipped across multiple architectural phases. Each phase is bit-identical in behavior to the prior state (pure refactor) until Phase D / Slice 9 where new functionality (the 5th contract function) lands.

| Phase | Commits | Scope | Result |
|---|---|---|---|
| **A** | `c61daf5b` | Per-host package registry + 4 manifests | Registry discovers hosts; no behavior change |
| **B** | `b656da6c` | Per-host handler implementations (4 contract functions × 4 hosts) | Handlers exist; dispatch works; behavior bit-identical to legacy switches |
| **C** | `0bf59876`, `d3581bab`, `4170c305` | Replace 3 host-coupled scripts with registry-driven shims (host-flag-translation, host-runtime-inventory, coordinator-prompt-surgery) | All 3 surfaces now registry-driven; legacy switches deleted |
| **C.2** | (within above) | `Get-SpecrewHostLaunchInvocation` → registry dispatch (+ Antigravity added) | Launch path now manifest-driven |
| **C.3** | `4170c305` | Coordinator-prompt surgery → declarative per-host rules engine + 4 `coordinator-rules.psd1` files | Surgery is data-driven; per-host rules declared, not coded |
| **D** | `e281aa17`, `cdd8901e` | detect-hosts manifest-driven + 3 deep-review ship-blockers + truthful-metrics doc pass | Phase A-D complete; deep-review feedback addressed |
| **Slice 1** | `6b3b010c` | Extract `scripts/init/_utilities.ps1` (11 functions, 242 lines) | Leaf file for the init split |
| **Slice 2** | `436f4923` | Extract `scripts/init/preflight.ps1` (2 functions, 207 lines) | |
| **Slice 3** | `58f6a8ac` | Extract `scripts/init/template-deploy.ps1` (3 functions, 228 lines) | |
| **Slice 4** | `a0094d1e` | Extract `scripts/init/spec-kit-deploy.ps1` (9 functions, 250 lines) | |
| **Slice 5** | `7cdaa19a` | Extract `scripts/init/dependency-install.ps1` + fix `Get-SpecrewExecutionLayout` path resolution | Marker-walk pattern established |
| **Slice 6** | `02f54860` | Extract `scripts/init/agent-detection.ps1` + delete duplicate `Get-CopilotSignals` + rewire via registry | Single source of truth for Copilot signals |
| **Slice 7** | `c7534feb` | Extract `scripts/init/squad-deploy.ps1` (3 functions, 214 lines) | |
| **Slice 8** | `4294ca06` | Extract `scripts/init/post-bootstrap-output.ps1` (2 functions, 181 lines) + path-resolution fix | |
| **Slice 9** | `15a472cf`, `70b1da06` | Per-host Crew runtime install + canonical `.specrew/team/` source-of-truth + architecture diagram + implementation review | The architectural payoff — 4 hosts deploy their teams |

After iter-001 closed, a 4-agent deep review surfaced 22 findings (3 BUG / 11 WARN / 8 NIT). iter-002 (commit `dcc4beb7`) addresses all of them.

## iter-002 scope

Single commit `dcc4beb7 chore(F-044 iter-002): deep-analysis bug-fix bundle (22 findings)`. Detailed scope in [`iterations/002/scope.md`](./iterations/002/scope.md). Highlights:

- **BUG** (3): A-1 host-gate `-NoLaunch` carve-out (incidentally fixes F-043 `755c87f1` bug); B-1 Copilot `CrewRuntimePath` shape; B-2 + B-3 manifest `AgentDir` Open-Closed seam closure
- **WARN** (11): contract doc rewrite, sentinel enforcement (with sidecar pattern for Copilot), auto-seed canonical on first start, depth-coupled `Split-Path` → marker-walk, contract-presence tests, doc fixes
- **NIT** (8): dead code removal, helper consolidation (`Get-SpecrewCharterTagline`), stale comment cleanup, asymmetric file filter fix

## Architecture diagrams shipped

Living architecture documentation in this feature:

- **Host-package architecture overview** — file:///C:/Dev/Specrew/docs/architecture/host-package-architecture.md (Mermaid `flowchart TB` showing canonical → registry → per-host translation → generated views)
- **Slice 9 implementation review** — file:///C:/Dev/Specrew/docs/design/proposal-108-slice-9-review.md
- **How-to add a new host** — file:///C:/Dev/Specrew/docs/how-to/add-a-new-host.md

## Methodology disclosure

This feature was implemented BEFORE the spec was written. The user explicitly authorized the unconventional path during a fast-moving multi-host integration push, then asked at closeout: "we work really hard and not so by Specrew methodology... It is time to fix that." This spec + plan + iteration artifacts are retroactive backfill to make the work navigable for future readers and to demonstrate the methodology even when shipped out-of-order. The two-iteration shape (iter-001 ships with known issues from review; iter-002 fixes them) is the methodology pattern Specrew enforces; this feature happens to demonstrate it on retroactive artifacts rather than live ones.

## Risk register at closeout

| Risk | Mitigation | Status |
|---|---|---|
| Squad CLI may not parse Copilot's `charter.md` if a comment header is prepended | Sidecar marker pattern (`.specrew-managed` file) instead of inline comment | Mitigated (W-4) |
| Antigravity subagent format inferred from docs, not smoke-tested | Antigravity host marked "medium-confidence" in handler header; smoke test queued post-Gemini-deadline | Open — tracked as follow-up |
| Coordinator overlay per-host translation deferred | Tracked in [spec.md § Out-of-scope](./spec.md#out-of-scope-deferred-to-future-work) | Open — Proposal 024 Category D work |
| `specrew team` CLI still writes to legacy `.squad/team.md` | Tracked as follow-up small-fix slice; canonical team source-of-truth is the new mechanism | Open — small-fix slice queued |
