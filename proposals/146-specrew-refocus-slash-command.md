---
proposal: 146
title: /specrew.refocus Slash Command (Reactive Methodology-Corpus Re-Load for Agent Drift Remediation)
status: candidate
phase: phase-2
estimated-sp: 5-8
priority-tier: 1
discussion: surfaced 2026-05-30 as the reactive sibling to Proposal 133 passive primer; addresses empirical agent drift after compaction or in long sessions; ship-first as small-fix slice ahead of F-053 (Proposal 145 structured reviewer) for immediate cross-feature drift-remediation ROI
---

# `/specrew.refocus` Slash Command (Reactive Methodology-Corpus Re-Load for Agent Drift Remediation)

## Why

Long-session and post-compaction agent drift is empirically the dominant source of methodology bypass observed across the 2026-05-26 → 2026-05-30 dogfooding window:

- **Antigravity hallucination + framework editing** — 3 sequential incorrect root-cause diagnoses + edits to Specrew's `validate-governance.ps1` + `shared-governance.ps1` inside a downstream project, all based on misdiagnosis (`powershell` 5.1 vs `pwsh` 7+)
- **Codex+Antigravity branch-push discipline gap** recurring across F-046 / F-048 / F-050 — boundary commits not pushed, branch state local-only despite explicit standing rules
- **Cross-reviewer pattern-grep ≠ verification** — across F-049 cross-review Instances 11-18, the cross-reviewer (Claude) accepted on metadata/pattern checks; Codex caught 8 substantive issues that required actual content reads
- **Compaction empirically drops Squad role definitions** — observed F-049 iter-1 closeout 2026-05-27; Copilot itself reported needing to restart for `squad.agent.md` reload
- **F-049 + F-050 review-signoff missing 8+ structural gaps** despite `accepted` verdicts (full catalog at [Proposal 145](145-structured-multi-phase-reviewer.md))

The Specrew methodology corpus has grown to span roughly 6-8 canonical files: `.specrew/constitution.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, 5 role charters under `extensions/specrew-speckit/squad-templates/agents/`, multiple `directives/` entries, and `docs/methodology/{review-instructions, lifecycle-discipline, proposal-discipline}.md`. Under compaction or long-session attention drift, agents lose fidelity on this corpus and start operating from a degraded mental model.

### Two complementary fixes (this proposal is the reactive half)

The structural answer to compaction-induced drift is two-pronged:

| Mechanism | Coverage | Cost | Failure mode |
| --------- | -------- | ---- | ------------ |
| **Passive primer** (**Proposal 133**) — auto-injection of methodology pointers into host-specific instruction files (`CLAUDE.md` / `AGENTS.md` / `.github/copilot-instructions.md`) every turn | high (every turn) | always-on token cost | none for compaction (re-injected by construction); risk of being ignored at heavy context |
| **Reactive trigger** (THIS PROPOSAL) — user-invoked or coordinator-suggested `/specrew.refocus` slash command that explicitly re-loads scoped methodology content on demand | targeted (per invocation) | only when invoked | requires user awareness OR coordinator hint |

These are NOT competing. Both should ship. Proposal 133's passive primer is the always-on baseline; `/specrew.refocus` is the explicit recovery / boundary-transition surface that loads scoped content too heavy for every-turn injection.

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

Coordinator governance gains an advisory rule: at each boundary transition (especially review-signoff, retro, iteration-closeout), the Coordinator MAY suggest the active agent invoke `/specrew.refocus --boundary <next-boundary>` if methodology fidelity is in doubt. Advisory only for v1; future iterations may upgrade to mandatory invocation at specific boundaries based on empirical drift data.

## Architecture (deliverable shape)

- **Skill manifest:** `extensions/specrew-speckit/squad-templates/skills/specrew-refocus/SKILL.md`
- **Helper script:** `scripts/internal/refocus.ps1` — arg parsing + canonical file reads + aggregated markdown output
- **Per-host deployment:** via **Proposal 058** SDK patterns — `.claude/skills/specrew-refocus/`, `.github/skills/specrew-refocus/`, `.agents/skills/specrew-refocus/`, etc. (follow F-021 / F-044 deploy-loop pattern in `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`)
- **Coordinator hook:** Add advisory entry to `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` at the boundary-transition rule (numbered rule TBD at spec time)
- **Output format:** agent-injectable markdown (preserves headings, fenced code, link refs) — wrapper banner explicitly names which scope was loaded + which canonical files were sourced

## Composition map

- [[133]] (Specrew Primer) — passive sibling; THIS proposal is the reactive complement; ship both
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

**Size: ~5-8 SP, single-iteration**

| Work | SP estimate |
| ---- | ----------- |
| Helper script + arg parsing | ~2 SP |
| Skill manifest + per-host deployment | ~2 SP |
| Coordinator advisory hook | ~1-2 SP |
| Tests (5 invocation modes + graceful degradation on missing files) + docs | ~1-2 SP |

**Sequencing options:**

- **Ship-first as small-fix slice (RECOMMENDED):** Land 146 ahead of F-053 (Proposal 145 structured reviewer). Drift-remediation ROI is immediate and cross-feature; helper is available for F-053 to compose with. Small-fix slice type per Proposal 067.
- **Bundle with F-053:** Fold 146 into F-053 as Phase 0 standalone trigger. Tighter conceptual coupling but delays drift-remediation ROI.

Recommend ship-first. F-053 still composes — the slash command surface becomes one of the ways to invoke the structured reviewer's Phase 0 context-load standalone.

## Open questions

- **Auto-trigger:** should coordinator-governance MAKE the agent run `/specrew.refocus --boundary <name>` at boundary transitions for v1, or only SUGGEST? Recommendation: suggest-only for v1; promote to mandatory after empirical adoption.
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
