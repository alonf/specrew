---
proposal: 146
title: /specrew.refocus Slash Command + Event-Driven Auto-Refocus (Reactive and Automatic Methodology-Corpus Re-Load for Agent Drift Remediation)
status: draft
phase: phase-2
estimated-sp: 10-15
priority-tier: 1
discussion: surfaced 2026-05-30 as the reactive sibling to Proposal 133 passive primer; addresses empirical agent drift after compaction or in long sessions; ship-first as small-fix slice ahead of F-053 (Proposal 145 structured reviewer) for immediate cross-feature drift-remediation ROI. AMENDED 2026-06-06 (maintainer-directed, pre-implementation) to add Pillar B event-driven auto-refocus — the same scoped re-load fired automatically from host hook events (post-compaction, session start/resume, boundary transitions) instead of waiting for a human or coordinator to remember to invoke it; promoted candidate -> draft for immediate implementation.
---

# `/specrew.refocus` Slash Command + Event-Driven Auto-Refocus (Reactive and Automatic Methodology-Corpus Re-Load for Agent Drift Remediation)

## Why

Long-session and post-compaction agent drift is empirically the dominant source of methodology bypass observed across the 2026-05-26 → 2026-05-30 dogfooding window:

- **Antigravity hallucination + framework editing** — 3 sequential incorrect root-cause diagnoses + edits to Specrew's `validate-governance.ps1` + `shared-governance.ps1` inside a downstream project, all based on misdiagnosis (`powershell` 5.1 vs `pwsh` 7+)
- **Codex+Antigravity branch-push discipline gap** recurring across F-046 / F-048 / F-050 — boundary commits not pushed, branch state local-only despite explicit standing rules
- **Cross-reviewer pattern-grep ≠ verification** — across F-049 cross-review Instances 11-18, the cross-reviewer (Claude) accepted on metadata/pattern checks; Codex caught 8 substantive issues that required actual content reads
- **Compaction empirically drops Squad role definitions** — observed F-049 iter-1 closeout 2026-05-27; Copilot itself reported needing to restart for `squad.agent.md` reload
- **F-049 + F-050 review-signoff missing 8+ structural gaps** despite `accepted` verdicts (full catalog at [Proposal 145](145-structured-multi-phase-reviewer.md))

The Specrew methodology corpus has grown to span roughly 6-8 canonical files: `.specrew/constitution.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, 5 role charters under `extensions/specrew-speckit/squad-templates/agents/`, multiple `directives/` entries, and `docs/methodology/{review-instructions, lifecycle-discipline, proposal-discipline}.md`. Under compaction or long-session attention drift, agents lose fidelity on this corpus and start operating from a degraded mental model.

### Three complementary fixes (this proposal is the reactive + automatic half)

The structural answer to compaction-induced drift is three-pronged (third row added by the 2026-06-06 amendment):

| Mechanism | Coverage | Cost | Failure mode |
| --------- | -------- | ---- | ------------ |
| **Passive primer** (**Proposal 133**) — auto-injection of methodology pointers into host-specific instruction files (`CLAUDE.md` / `AGENTS.md` / `.github/copilot-instructions.md`) every turn | high (every turn) | always-on token cost | none for compaction (re-injected by construction); risk of being ignored at heavy context |
| **Reactive trigger** (Pillar A, THIS PROPOSAL) — user-invoked or coordinator-suggested `/specrew.refocus` slash command that explicitly re-loads scoped methodology content on demand | targeted (per invocation) | only when invoked | requires user awareness OR coordinator hint |
| **Automatic event trigger** (Pillar B, THIS PROPOSAL, 2026-06-06 amendment) — host hook events (post-compaction session start, launch/resume, boundary transition) fire the SAME scoped re-load mechanically, with no human or model discretion in the loop | exactly the moments drift is born (compaction, cold start, gate crossing) | only on event | host must expose a hook surface; degraded hosts fall back to Pillar A advisory |

These are NOT competing. All three should ship. Proposal 133's passive primer is the always-on baseline; `/specrew.refocus` is the explicit recovery surface; the hook layer removes the "requires someone to remember" failure mode of both at the exact events where drift empirically originates. The A8/Proposal-165 lesson generalizes here: conduct text inside the model's context cannot reliably survive the very events (compaction, restart) that destroy context — only a trigger OUTSIDE the model's context can re-arm it.

## What

### CLI surface

```text
/specrew.refocus                              # generic re-ground: constitution + coordinator-governance + active role charter
/specrew.refocus --boundary <name>            # boundary-scoped: review-instructions + Per-Boundary Checklist Matrix entry
/specrew.refocus --role <name>                # role-scoped: role charter + role-specific instructions
/specrew.refocus --shape-catalog              # Shape catalog only: form-without-runtime-compliance discipline
/specrew.refocus --everything                 # full corpus dump (heavy; rarely needed)
```

Valid `--boundary` values: `specify | clarify | plan | tasks | before-implement | implement | review-signoff | retro | iteration-closeout | feature-closeout`

Valid `--role` values: `spec-steward | planner | implementer | reviewer | retro-facilitator | coordinator`

### Content sources (no new authoring)

The slash command aggregates and injects content from existing canonical files. No new methodology content is written; this is a pure aggregation + re-injection surface.

| Scope | Files loaded |
| ----- | ------------ |
| no-args (generic) | `.specrew/constitution.md` + `coordinator/specrew-governance.md` + active role charter (detected from session-state) |
| `--boundary <name>` | Same as no-args + `docs/methodology/review-instructions.md` (for review-signoff) + Per-Boundary Checklist Matrix entry from [Proposal 140](140-reviewer-instruction-surface.md) |
| `--role <name>` | Same as no-args + named role charter + any directives the role references |
| `--shape-catalog` | `docs/methodology/lifecycle-discipline.md` Shape Catalog section only |
| `--everything` | All of the above + `docs/methodology/proposal-discipline.md` |

### Coordinator-governance integration

Coordinator governance gains an advisory rule: at each boundary transition (especially review-signoff, retro, iteration-closeout), the Coordinator MAY suggest the active agent invoke `/specrew.refocus --boundary <next-boundary>` if methodology fidelity is in doubt. Advisory only where Pillar B has no hook surface; on hook-capable hosts the boundary trigger is mechanical (see Pillar B below) and the advisory becomes the fallback, not the primary.

### Pillar B — Event-driven auto-refocus via host hooks (Amendment 2026-06-06)

Maintainer-directed scope extension: the refocus payload must ALSO fire automatically from host lifecycle events, in the places where drift is actually created. A slash command alone still depends on a human (or the drifted model itself) noticing the drift — the same discretionary loop that Proposal 165 showed cannot be fixed from inside the model's context.

**Trigger catalog (Claude Code hook names; per-host adapters map equivalents):**

| Trigger | Host event | Refocus scope injected | Rationale |
| ------- | ---------- | ---------------------- | --------- |
| B1 post-compaction | `SessionStart` with `source: compact` | active role charter + current boundary scope (equivalent of `--role <active> --boundary <current>`) | compaction is the empirically dominant drift event (drops Squad role definitions, F-049 iter-1; Shape 3c class F-024/F-046/F-048) |
| B2 launch/resume | `SessionStart` with `source: startup \| resume \| clear` | lightweight pointer set (constitution + coordinator-governance pointers + current lifecycle position) | cold starts and `claude`-in-directory launches that bypass `specrew start` (composes with Proposal 130 Pillar 4b SessionStart injection + Proposal 143 orientation) |
| B3 boundary transition | `PostToolUse` matcher on boundary-sync invocations (`sync-boundary-state.ps1`) | `--boundary <next-boundary>` scope | makes the v1 coordinator advisory mechanical; the gate crossing is exactly when the next phase's discipline must be fresh |
| B4 pre-compaction capture (research-gated) | `PreCompact` | instruct the compactor to preserve lifecycle position, active role, and boundary state in the summary | reduces what B1 must re-build; ships only if the host honors compaction-prompt augmentation |

**Per-host applicability matrix (mirrors Proposal 105 research):**

| Host | Surface | Pillar B shape |
| ---- | ------- | -------------- |
| Claude Code | full documented hook surface (`SessionStart` / `PostToolUse` / `PreCompact`) | B1 + B2 + B3 (B4 research-gated) — V1 target |
| Antigravity | hook surface per Proposal 105 (PreToolUse / SubagentStart / Stop) | subset mapped at spec time; B3-equivalent where PostToolUse exists |
| Codex CLI | hook surface undocumented | deferred (same posture as Proposal 105) |
| Copilot CLI | no hook surface | Pillar A only; coordinator advisory remains primary |
| Cursor | `.cursor/rules/*.mdc` always-attached, no invocable hooks | always-attached rule (effectively Proposal 133 primer); no event trigger |

**Guardrails (hard requirements, not options):**

- **Token budget:** hook injections use scoped pointers + excerpts, never `--everything`; each injection states its scope + sourced files in a one-line banner.
- **Idempotence / loop safety:** per-session dedupe — a trigger that fired within the current context does not re-fire on the next event unless context was lost (compaction/restart); hook handlers must be re-entrant and never block the session on failure (fail-open with a visible one-line warning).
- **Deployment:** hooks are deployed/refreshed by the same per-host deploy loop as the skill surface (Proposal 105 adapter pattern; `specrew init` + `specrew update`), never hand-edited per project.
- **Truth source:** handlers read canonical files at event time (no embedded content) — same currency rule as Pillar A.

## Architecture (deliverable shape)

- **Skill manifest:** `extensions/specrew-speckit/squad-templates/skills/specrew-refocus/SKILL.md`
- **Helper script:** `scripts/internal/refocus.ps1` — arg parsing + canonical file reads + aggregated markdown output. **Single payload engine for BOTH pillars**: the slash command and every hook handler call the same helper with the same scope flags, so payload behavior cannot drift between manual and automatic invocation.
- **Per-host deployment:** via **Proposal 058** SDK patterns — `.claude/skills/specrew-refocus/`, `.github/skills/specrew-refocus/`, `.agents/skills/specrew-refocus/`, etc. (follow F-021 / F-044 deploy-loop pattern in `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`)
- **Hook handlers (Pillar B):** per-host hook configuration + thin handler scripts that map the host event to a `refocus.ps1` scope invocation and inject its output (Claude: `.claude/settings.json` hooks block + handler under `.claude/hooks/` or equivalent — exact deployment shape decided at design-analysis with Proposal 105's adapter pattern)
- **Coordinator hook:** Add advisory entry to `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` at the boundary-transition rule (numbered rule TBD at spec time) — fallback surface for hosts without Pillar B
- **Output format:** agent-injectable markdown (preserves headings, fenced code, link refs) — wrapper banner explicitly names which scope was loaded + which canonical files were sourced + which trigger fired (manual / compact / startup / boundary)

## Composition map

- [[133]] (Specrew Primer) — passive sibling; THIS proposal is the reactive + automatic complement; ship both
- [[105](105-host-native-hook-deployment.md)] (Host-Native Hook Deployment) — Pillar B's deployment machinery and per-host hook-surface research; 146-B supplies the refocus payload, 105 supplies the adapter pattern
- [[130](130-specrew-switch-to-host-handover.md)] (Pillar 4 SessionStart/SessionEnd hooks) — B2 shares the SessionStart injection point with 130 Pillar 4b context-bridge; implementations must compose (one SessionStart handler dispatching both payloads), not duplicate
- [[168](168-claude-boundary-packet-stop-hook.md)] (Claude Boundary Packet Stop Hook) — sibling hook-family proposal; shares the hooks deployment + `stop_hook_active`-style loop-safety idioms
- [[165](165-pretooluse-render-gate-hook.md)] (PreToolUse Render-Gate Hook) — sibling; establishes the "only a trigger outside the model's context is non-discretionary" governing model that Pillar B applies to drift remediation
- [[140](140-reviewer-instruction-surface.md)] (Reviewer Instruction Surface) — supplies the Per-Boundary Checklist Matrix content loaded under `--boundary`
- [[145](145-structured-multi-phase-reviewer.md)] (Structured Multi-Phase Reviewer) — Phase 0 IS context-load; 146 is essentially "trigger Phase 0 standalone outside a review"
- **Proposal 058** (Plugin-Based Distribution candidate) — per-host deployment pattern
- [[067](067-small-fix-slice-type.md)] (Small-Fix Slice Type) — natural slice shape for 146
- [[143](143-session-start-welcome-orientation-reset-surface.md)] (Welcome Orientation + Reset Surface) — Welcome Orientation should hint at `/specrew.refocus` for discoverability
- [[132](132-mirror-parity-validator-enforcement.md)] (Mirror Parity Validator) — protects against host-specific skill drift
- [[project-specrew-primer-persistent-host-instructions-2026-05-26]] — drift empirical evidence
- [[project-cross-reviewer-3rd-empirical-instance-2026-05-28]] — cross-reviewer drift evidence
- [[project-antigravity-review-boundary-hallucination-2026-05-27]] — Antigravity drift incident

## Sizing + sequencing

**Size: ~10-15 SP (Pillar A ~5-8 + Pillar B ~5-7); 1-2 iterations** — Pillar A first (the payload engine + manual surface), Pillar B second (the hook triggers reusing the same engine). Claude-first for Pillar B; other hosts per the applicability matrix.

| Work | SP estimate |
| ---- | ----------- |
| Helper script + arg parsing (shared payload engine) | ~2 SP |
| Skill manifest + per-host deployment | ~2 SP |
| Coordinator advisory hook (fallback surface) | ~1-2 SP |
| Pillar A tests (5 invocation modes + graceful degradation on missing files) + docs | ~1-2 SP |
| Pillar B Claude hook handlers (B1 post-compaction + B2 launch/resume + B3 boundary transition) + settings deployment | ~3-4 SP |
| Pillar B loop-safety/dedupe + fail-open behavior + tests (simulated hook payloads) + docs | ~2-3 SP |

**Sequencing options:**

- **Ship-first as small-fix slice (RECOMMENDED):** Land 146 ahead of F-053 (Proposal 145 structured reviewer). Drift-remediation ROI is immediate and cross-feature; helper is available for F-053 to compose with. Small-fix slice type per Proposal 067.
- **Bundle with F-053:** Fold 146 into F-053 as Phase 0 standalone trigger. Tighter conceptual coupling but delays drift-remediation ROI.

Recommend ship-first. F-053 still composes — the slash command surface becomes one of the ways to invoke the structured reviewer's Phase 0 context-load standalone.

## Open questions

- **Auto-trigger:** RESOLVED by the 2026-06-06 amendment — on hook-capable hosts the boundary trigger is mechanical (Pillar B3); the coordinator advisory remains the fallback on hosts without a hook surface.
- **B3 matcher shape (research at design-analysis):** what does the `PostToolUse` matcher key on to detect a boundary-sync invocation reliably (command substring vs a marker file written by `sync-boundary-state.ps1`)? Marker-driven detection is likely more robust than transcript/command parsing — same crux as Proposal 165.
- **B1/B2 payload size:** what fits in a SessionStart injection without taxing every session start? Needs an empirical token measurement during implementation; the budget cap is a hard guardrail.
- **B4 viability:** does PreCompact compaction-prompt augmentation actually influence the summary on current Claude Code? Ship B4 only with empirical confirmation.
- **Hook config ownership:** Claude reads hooks from settings files that downstream users may also edit — the deploy loop must merge, not clobber (same managed-vs-user-edited discipline as F-161's marker guard).
- **Output framing:** does the loaded content go into agent context as a system message, user message, or assistant prelude? Per-host implementation detail.
- **Caching:** per-invocation file reads vs in-session memoization? Recommendation: no caching for v1 simplicity; cache later if measured.
- **Host-specific surface:** does Antigravity / Cursor / Copilot CLI surface slash commands differently? Per-host adapter shape TBD at spec time. Cursor specifically uses `.cursor/rules/*.mdc` not slash commands (per F-050) — Cursor would surface 146 as an always-attached rule, not an invocable slash, OR be deferred to a future iteration.
- **Versioning:** when methodology files change (post `specrew update`), does the skill auto-pick-up or need re-deploy? Recommendation: skill reads canonical files at invocation time (no embedded content), so `specrew update` automatically picks up new methodology without re-deploying the skill.
- **Failure mode:** what if a canonical file is missing (project not updated to latest)? Recommendation: graceful degradation with a clear message naming the missing file + suggesting `specrew update`.

## Risks

- **Context bloat:** `--everything` could blow context budget. Mitigate via per-flag scoping; document recommended invocations; expose token-cost estimate in the helper output.
- **Discoverability:** users may not know when to invoke. Mitigate via:
  - Welcome Orientation (Proposal 143) hint at session start
  - Coordinator-suggested invocation at boundary transitions
  - `specrew help` surface entry
  - Documentation in `README.md` Quick Reference
- **Skill drift across hosts:** same risk as any per-host skill deployment. Mitigate via [Proposal 132](132-mirror-parity-validator-enforcement.md) mirror-parity validator.
- **Stale content surface:** if methodology files lag the actual discipline (e.g., a new Shape added to a memory but not yet to `lifecycle-discipline.md`), 146 surfaces stale guidance. Mitigate via methodology-file currency check at boundary transitions; broader scope is Proposal 140 + documentation discipline.
- **Cursor host limitation:** Cursor's `.cursor/rules/*.mdc` surface is always-attached, not invocable as slash command. 146 may degrade to an always-attached rule on Cursor (effectively duplicating Proposal 133 primer) OR be Cursor-deferred. Decide at spec time.
- **Hook injection loops (Pillar B):** a hook that fires on events its own injection can cause would loop. Mitigate via per-session dedupe + re-entrant handlers + the `stop_hook_active`-style guard idiom from Proposal 168.
- **Session-start latency/cost (Pillar B):** B2 fires on every launch; an oversized payload taxes every session. Mitigate via the pointer-set scope (not full corpus) + the token-budget guardrail.
- **Hook config clobbering (Pillar B):** deploying hooks into user-editable settings files risks overwriting user hooks. Mitigate via merge-aware deployment (F-161 managed-marker discipline applied to hook config).
- **Silent hook failure (Pillar B):** a broken handler must never block the session. Fail-open with a visible one-line warning; covered by simulated-payload tests.
