---
proposal: 092
title: Specrew Dashboard Web App (Observability, Insights, and Multi-Developer SDLC View)
status: candidate
phase: phase-4
estimated-sp: 80-120 across 4-5 iterations
discussion: tbd
---

# Specrew Dashboard Web App (Observability, Insights, and Multi-Developer SDLC View)

## Why

Specrew today exposes its state through two narrow surfaces: the CLI (`specrew where`, `specrew start`, `specrew validate-governance`) and direct file reading (`.specrew/`, `specs/`, `proposals/`, retros, dashboards). Both are powerful but each carries cognitive load: the user has to know what to look for, where it lives, and how to interpret it. The CLI surface is single-snapshot; reading files is laborious; correlating across multiple features, multiple iterations, multiple developers, or multiple agents is effectively impossible without manual aggregation.

As Specrew matures and adoption grows, the gap widens:

- **Multi-developer scenarios** (Proposal 010) imply multiple parallel timelines; tracking even two is hard at the CLI/file level.
- **Multi-agent scenarios** (Proposals 024, 058, 069) mean a single developer might have Copilot, Claude Code, and Codex working concurrently — possibly multiple instances of each — on the same project. There is currently no way to *see* this.
- **Cloud-agent scenarios** (future remote-execution proposals) extend this further: agents running on infrastructure the developer doesn't directly observe.
- **Methodology insight** — the data to answer "is our process actually working?" exists across `.specrew/`, retros, validator summaries, cost records, and git history, but there is no analytic surface that joins them.
- **Onboarding** — new developers (or returning developers after a gap) face a steep climb to understand "where is this project? what's active? what's planned? what hurts?" — the answer requires reading dozens of files.
- **External stakeholders** (product managers, security reviewers, executives) have no read-only surface they can be pointed at.

User-stated motivation (2026-05-22):

> "A complementary dashboard web app that … shows all that happened in the process. We may also use this as a place to manage the process — but we need to analyze what can be and should be done from a central app … the purpose is to provide the perfect understanding and insights into Specrew SDLC."

This is a strategic capability: the difference between Specrew-as-a-CLI-methodology and Specrew-as-a-product. It also enables future commercial models (hosted observability for teams) without changing the methodology itself.

### Why now is hard, why later is harder

The data model decisions made by this proposal affect **all** future telemetry-emitting work: cost tracking (Proposal 070), boundary commit discipline (Proposal 082), build-time history (Proposal 091 pillar 2e), PR-review integration (Proposal 089), and any future multi-host/cloud-agent feature. If we defer the dashboard until after those ship without coordinating, we will have to retrofit a uniform event schema across half the codebase. Drafting the data model **now** (even if the web app itself ships in phase 4) lets every downstream feature emit dashboard-compatible events from day one.

## What

### Scope summary

A web-based observability and insight surface for Specrew projects. Local-first by default, with an opt-in cloud-collector mode for multi-developer/multi-agent/cloud-agent visibility. Read-only at MVP; carefully-scoped write actions (annotations, schedule decisions, approvals) deferred to later iterations.

### Profile-state dual-mode rendering

The dashboard works for **both** projects that have activated the `proposal-driven-design` profile (Proposal 096) and those that have not. Per-view-family behavior:

- **Profile-neutral views** (work in both modes): product overview (#1), SDLC process explainer (#5), active features (#6), boundary timeline (#7), live activity feed (#8), live agent monitor (#9), cloud agent monitor (#10), approval audit log (#11), tests + coverage (#12), quality-gate trends (#13), agent + model performance (#14), cost dashboard (#15), spec-fidelity tracker (#16), bugs + defects (#17), tech debt (#18), build-time + SDLC perf (#19), developer switcher (#20), human↔AI interaction explorer (#21), problematic-files (#22), codebase activity heatmap (#23), retrospective explorer (#24), onboarding view (#25), process compliance scorecard (#26), replay mode (#27), multi-project portfolio (#28), search (#29), notifications (#30), external integrations (#31). These render from profile-neutral data sources: `.specrew/`, `specs/`, retros, git log, the unified event stream, etc.
- **Profile-conditional views**: roadmap view (#2), architecture + design (#3), decision/ADR ledger (#4). When the profile is active, these views overlay `proposals/` content on top of profile-neutral data (`roadmap.yml`, `constitution.md`, `.specrew/decisions/`). When the profile is inactive, the same views render from profile-neutral sources only — the proposals layer is simply absent. No view *fails* due to profile state; some views are richer when proposals exist.

Dashboard detects profile state from `.specrew/config.yml`'s `profiles:` array at startup; rendering adapts accordingly. Search (#29) results scope to whichever data sources are present.

### Information surfaces (16 view-families)

The dashboard organizes information into 16 view-families. Each can ship independently; the MVP carves out a small initial subset.

#### Product + planning

1. **Product overview** — name, mission, current version, supported channels, active branches, "what is this project?" elevator pitch (rendered from `.specrew/start-summary.md`, README, `roadmap.yml`).
2. **Roadmap view** — visual roadmap from `roadmap.yml` + `proposals/INDEX.md`. Done / in-flight / planned / candidate. Filterable by phase, tier, audience. Composes with Proposal 028 (lifecycle hardening) when it ships.
3. **Architecture + design view** — solution architecture, technology choices, design decisions. Sourced from constitution.md, ADR ledger (proposed below), spec.md/plan.md files. Composes with Proposal 011 (Architecture Intent Checkpoint) and Proposal 012 (Visual Artifact Extension — diagrams).
4. **Decision/ADR ledger** — every design decision captured during planning, with who/when/why/alternatives-considered. Either lives in spec/plan files (current state) or in a dedicated `.specrew/decisions/` directory (proposed). Searchable + linkable.

#### Process state + activity

5. **SDLC process explainer** — interactive view of Specrew's lifecycle (boundary sequence, slice types, agent roles). Pedagogical surface for new users + reference for experienced ones. Composes with Proposal 013 (Methodology Site).
6. **Active features view** — every feature currently in-flight across all developers (when multi-dev), with current boundary, last activity, owner. Boundary-timeline visualization for each.
7. **Boundary timeline viewer** — per-feature, visualize the lifecycle as a horizontal timeline with timestamps. Click a boundary to inspect the handoff that authorized it. Color-coded by status (approved / rejected / autopilot-skipped / pending).
8. **Live activity feed** — chronological stream of significant events across all developers + agents: boundaries crossed, commits, PRs opened, validator runs, retros completed. Filterable by dev/agent/feature.
9. **Live agent monitor** — for each known developer machine, list of installed agents (Copilot, Claude Code, Codex), their current activity, current feature/iteration, current boundary. Multiple instances per agent type supported (e.g., dev has two Claude Code sessions, one on feature A iter 2, one on feature B iter 1).
10. **Cloud agent monitor** — when Specrew supports cloud-hosted agent execution, the same live view but for remote agents. Stub at MVP; populated when remote-execution ships.
11. **Approval audit log** — every human approval decision + every autopilot-skipped approval across the project's history. Critical for governance compliance + post-incident replay.

#### Quality + insight

12. **Tests + coverage view** — test counts per feature, coverage trends, flaky test surface, broken test history. Composes with whatever test-coverage telemetry ships.
13. **Quality-gate trends** — validator pass/fail history, lint violations over time, PR-CI duration, deterministic-gate outcomes. Composes with Proposal 086's telemetry stream.
14. **Agent + model performance** — per-agent and per-model metrics: errors per iteration, reviewer findings count, time-to-boundary, % autopilot overrides. Sortable + comparable. Composes with Proposal 068 (cost-aware routing) catalog and Proposal 070 (token economy).
15. **Cost dashboard** — per-feature, per-iteration, per-agent, per-model cost. Trend over time. Burn rate vs configured budget. Composes with Proposal 070.
16. **Spec-fidelity tracker** — for each shipped feature, how closely did delivered code/tests match the source spec? Drift incidents catalog. Composes with Proposal 018 (Source-Spec Fidelity Contract).
17. **Bugs + defects view** — found bugs (from retros, PR reviews, post-ship slices), categorized by type/severity/root cause. Cross-linked to features that introduced them.
18. **Tech debt view** — debt ledger from Proposal 091 rendered with trend, top-aged, top-priority, recent closures, repayment pathways. Net change per iteration.
19. **Build-time + SDLC performance** — graphs of validator duration, lint duration, test duration, total iteration wall-clock, time-spent-per-boundary. Composes with Proposal 091 pillar 2e telemetry stream.

#### Multi-actor + interaction

20. **Developer switcher** — for multi-developer teams, switch perspective: "show me as if I were developer X". Useful for code review, mentoring, retros.
21. **Human ↔ AI interaction explorer** — for any past or active iteration, view the sequence of human prompts + agent responses + tool calls + boundary decisions. Reveals *how* the developer drove the AI. Useful for methodology improvement + training.
22. **Problematic-files view** — files opened/touched by multiple agents and developers; conflict surface. The dashboard explains for each: is concurrent access **a must** (e.g., shared utility module), or **tech debt** (file should be split / extracted / refactored)? Heuristic-based classification with manual override; composes with Proposal 091 (file-churn auto-detector).
23. **Codebase activity heatmap** — which modules/files are getting most attention; which are stagnant; correlation with bugs (hot files with high defect density are red flags).

#### Cross-cutting + onboarding

24. **Retrospective explorer** — searchable archive of all retros across all features. Topic clustering ("what do we keep complaining about?"). Trend analysis. Cross-link to debt entries that originated from retro observations.
25. **Onboarding view** — "I just joined / I just came back — what's active, what's planned, what hurts, where should I start?" Pulls from product overview, active-features, debt, recent retros. Tailored welcome for new developers.
26. **Process compliance scorecard** — per-feature, did methodology run clean? Skipped boundaries (with reason), autopilot overrides count, retro completeness, time-spent-per-boundary distribution. Useful for self-improvement + external review.
27. **Replay mode** — for any past feature, replay the boundary sequence with timing as a "movie". Retro + training value; also useful when debugging "how did we end up here?"
28. **Multi-project portfolio view** — for devs managing several Specrew projects, a single index across projects with active features, debt totals, recent shipped work.
29. **Search across everything** — specs / plans / tasks / retros / decisions / debt / proposals / commits / handoffs. One search box.
30. **Notifications + alerts** — configurable triggers: debt growth ≥ N SP, build-time regression > X%, stuck boundary > N hours, expired session-state, failed CI on active feature. Web push, email, optional Slack.
31. **External integration view** — GitHub PR status, CI runs, deployment status alongside Specrew state. Composes with Proposal 089 (PR-review integration).

(Not all 31 ship at once — see MVP carve-out below.)

### Two cross-cutting subsystems

#### A. Data model + event schema

The dashboard requires a uniform event schema that all Specrew-emitting work writes into. Proposed location: `.specrew/.events/<YYYY>/<MM>/<DD>.jsonl` (append-only, gitignored or partially-tracked depending on profile). Event shape:

```json
{
  "schema": "specrew-event-v1",
  "id": "evt-<uuid>",
  "ts": "2026-05-22T09:30:00Z",
  "type": "boundary-crossed | commit | pr-opened | validator-ran | retro-completed | debt-added | debt-closed | …",
  "actor": { "kind": "human|agent|automated", "name": "alon|copilot-#1|claude-#2|…" },
  "project": "<project-id>",
  "feature": "F-035",
  "iteration": "001",
  "boundary": "iteration-closeout",
  "payload": { …event-type-specific fields… }
}
```

Every existing emitter (validator, boundary-state-sync, retro template, debt ledger, etc.) gets a small hook that appends an event. Existing artifacts (retros, dashboards, validator-summary.json) remain authoritative; events are a *parallel telemetry stream* derived from them. No double-source-of-truth.

#### B. Telemetry agent (the per-machine collector)

For multi-developer and multi-agent visibility, each developer machine runs a small Specrew daemon (`specrew-agent`) that:

- Watches `.specrew/` and `specs/` of all known Specrew projects (configured at install)
- Tails the `.events/` JSONL streams
- Detects running agent instances (Copilot, Claude Code, Codex) by process inspection or known marker files
- Ships events to a configurable destination: local-only (no shipping), git-sync (commits events to a side-branch periodically), or cloud-collector (HTTPS POST to a hosted endpoint)

The dashboard frontend reads from the chosen destination. Local-only mode requires no daemon (frontend reads files directly).

### Privacy + data sovereignty

The dashboard must support three deployment modes, each preserving a different privacy stance:

1. **Local-only** (default, MVP) — frontend runs on `localhost` (`specrew dashboard` opens browser), reads from local filesystem. No telemetry leaves the machine. Single-developer single-project visibility only.
2. **Git-synced multi-dev** — events are committed to a side-branch (`specrew-events/<dev-name>`) per dev; the dashboard reads aggregated history from git. No external service required. Works for small teams using GitHub/GitLab.
3. **Cloud-collector** (opt-in) — events ship to a hosted collector; the dashboard is a web app served from the same service. Required for cloud-agent monitoring and large multi-dev/multi-project scenarios. Auth + tenant isolation required.

The schema is identical across all three modes; the difference is transport.

### Read vs read-write

MVP is **strictly read-only**. The dashboard reads existing state, presents it richly, but does not modify it. Specrew governance flows continue to run through the CLI.

Carefully-scoped write actions are considered for later iterations:

- **Annotate** any item (free-text notes attached to features/iterations/debt entries/decisions)
- **Schedule** debt entries (sets `scheduled-for` field)
- **Promote** debt to proposal (triggers Proposal 091's `specrew debt promote` flow)
- **Approve a boundary from the web UI** (carefully — must trigger the same validator/commit flow as CLI approval, with full audit-log entry)
- **Trigger a re-validate** of a feature

Riskier actions stay CLI-only forever: editing specs, launching iterations, force-merging.

## MVP definition (Iteration 1, ~25-35 SP)

**Scope**: Single-project, single-developer, local-only, read-only.

**Includes**:

- `specrew dashboard` CLI command that opens browser to `localhost:<port>`
- Frontend skeleton (chosen tech stack — see open questions) with routing, layout, navigation
- 6 view-families:
  - **Product overview** (#1)
  - **Roadmap** (#2)
  - **Active features** (#6) + per-feature **boundary timeline** (#7) — for the single dev's current project only
  - **Tech debt** (#18) — if Proposal 091 has shipped; otherwise a stub
  - **Onboarding view** (#25)
  - **Search across everything** (#29) — basic full-text against local files
- Live updates via filesystem watcher (no daemon required at MVP)
- Event schema defined and emitted by validator + boundary-state-sync + retro completion (foundation for later iterations) — even if MVP UI only consumes a subset

**Explicitly excludes from MVP**:

- Multi-developer view (deferred — requires git-sync or cloud-collector)
- Multi-agent monitoring (deferred — requires telemetry agent)
- Cloud agents (deferred — requires remote-execution proposal first)
- Write actions of any kind
- Cost dashboard (deferred until Proposal 070 ships)
- Spec-fidelity tracker (deferred until Proposal 018 drafted)
- Replay mode (deferred — needs full event stream maturity)
- Notifications (deferred)
- Multi-project portfolio (deferred)

**Rationale**: MVP must prove that "rich local view of one Specrew project" works smoothly + that the data model is solid. Multi-dev/multi-agent layers on top once the foundation is proven.

## Roadmap beyond MVP

- **Iteration 2 (~20-25 SP)** — Quality + insight layer: tests/coverage (#12), quality-gate trends (#13), build-time + SDLC perf (#19), bugs + defects (#17), retrospective explorer (#24), process compliance scorecard (#26). Adds the "is our process healthy?" surface.
- **Iteration 3 (~30-40 SP)** — Multi-developer + telemetry agent: deploy `specrew-agent` daemon, git-sync mode, multi-dev active-features view (#6), developer switcher (#20), human↔AI interaction explorer (#21), live activity feed (#8), live agent monitor (#9). This iteration is when "multiple agents per dev" becomes visible.
- **Iteration 4 (~20-25 SP)** — Cloud-collector mode + cloud-agent monitor (#10) + multi-project portfolio (#28) + notifications (#30) + external integration view (#31).
- **Iteration 5 (~15-20 SP)** — Advanced views: replay mode (#27), problematic-files (#22), codebase heatmap (#23), agent/model performance (#14), cost dashboard (#15), spec-fidelity (#16), ADR ledger (#4), approval audit log (#11), SDLC process explainer (#5), architecture view (#3). Plus optional carefully-scoped write actions if user wants them.

**Total**: ~80-120 SP across 4-5 iterations.

The proposal is best viewed as a roadmap; each iteration ships value independently. Splitting into separate proposals (one per iteration) is a viable alternative — see open questions.

## Functional Requirements (high-level for candidate phase)

- **FR-001**: `specrew dashboard` CLI command (cross-platform) that starts the local server + opens browser
- **FR-002**: Frontend web app with routing, layout, navigation across all enabled view-families
- **FR-003**: Local-filesystem data adapter (reads `.specrew/`, `specs/`, `proposals/`, retros, git log)
- **FR-004**: Unified event schema (`.specrew/.events/*.jsonl`) emitted by validator + boundary-state-sync + retro completion + debt operations + cost recording
- **FR-005**: Per-view-family rendering (each view-family is independently implementable)
- **FR-006**: Live filesystem watcher for active-features view (no daemon required at MVP)
- **FR-007**: Search across local artifacts (specs/plans/tasks/retros/decisions/debt/proposals)
- **FR-008**: `specrew-agent` daemon for multi-dev/multi-agent telemetry collection (iteration 3+)
- **FR-009**: Git-sync transport mode (commits events to side-branch per dev)
- **FR-010**: Cloud-collector transport mode + auth + tenant isolation (iteration 4+)
- **FR-011**: Cloud-agent monitor view + remote-execution adapter (iteration 4+, depends on cloud-execution proposal)
- **FR-012**: Optional read-write actions with full audit-log + governance compliance (iteration 5+, opt-in per profile)
- **FR-013**: Notification surface + configurable triggers (iteration 4+)
- **FR-014**: Privacy modes documented + tested; user can verify what leaves the machine
- **FR-015**: Self-applied: dashboard is dogfooded on the Specrew repo itself from MVP

## Out of scope

- Replacing the CLI — dashboard is *complementary*, not a substitute. Power-user + automation flows stay CLI.
- Replacing GitHub / GitLab / Linear / Jira — Specrew dashboard surfaces Specrew SDLC state; external tools remain authoritative for code review, issue tracking, etc. Integration views (#31) surface them but don't host them.
- A general-purpose project management tool — scope is bounded to Specrew SDLC observability.
- Custom dashboard editing by end-users — initial views are curated; user-configurable dashboards is a far-future capability.
- Mobile apps — desktop browser only at MVP.
- Offline-first persistence — local-only mode is already offline; cloud-collector requires connectivity.
- Real-time collaborative editing of artifacts — not a Google-Docs-like surface; viewing only at MVP.

## Effort

- **MVP / Iteration 1**: ~25-35 SP — single-project local-only read-only, 6 view-families, event schema foundation
- **Iteration 2**: ~20-25 SP — quality + insight layer
- **Iteration 3**: ~30-40 SP — multi-dev + telemetry agent
- **Iteration 4**: ~20-25 SP — cloud-collector + cloud-agent monitor + portfolio + notifications + integrations
- **Iteration 5**: ~15-20 SP — advanced views + optional write actions
- **Total**: ~110-145 SP if all iterations ship. Realistic range with re-scoping: **~80-120 SP**.

## Phase placement

**Phase 4 (scale)**. Specrew methodology must stabilize first; the dashboard amplifies an already-solid system rather than fixing one. However, **the event schema (Pillar A) should land earlier** — ideally as a phase-2 chore so downstream telemetry-emitting features (Proposal 070 cost, 086 perf, 089 PR-review, 091 tech debt) write into the unified schema from day one. This avoids retrofit cost when the dashboard catches up.

Suggested sequencing:

1. **Phase 2 (now-ish)** — draft + land the event schema as a small chore (~5 SP). Existing emitters get a thin event-emit hook. No UI yet.
2. **Phase 3 (mid-2026)** — MVP of the dashboard (iterations 1+2). Local-only single-dev. Establishes the visual + interaction patterns.
3. **Phase 4 (late 2026 / 2027)** — multi-dev + cloud + advanced views as adoption pressure materializes. Iterations 3-5.

## Open questions

1. **Tech stack** — Frontend: React / Vue / SolidJS / Svelte / vanilla? Backend: Node.js / .NET / Go / Rust / Python? Should match Specrew's existing PowerShell-centric stack as little as possible (frontend tech is decoupled). Recommendation: TBD at clarify — but bias toward Node.js + React for ecosystem maturity, cross-platform, and reasonable developer pool.
2. **Bundling / distribution** — npm package? Standalone binary (single-file via deno-compile / pkg / dotnet AOT)? PSGallery module like `specrew` itself? Trade-off: single-binary is simplest for users; npm/node is simplest for the dashboard developer.
3. **Storage backend for cloud-collector mode** — Postgres / SQLite / DynamoDB / managed Mongo? Self-hosted vs hosted-by-Specrew-org? Decision deferred to iteration 4.
4. **Should this be one proposal or split into 5 (one per iteration)?** Arguments for one: shared data model + unified vision. Arguments for split: each iteration is independently shippable, easier to deprioritize/skip individual iterations. Recommendation: **one proposal as roadmap-document**, with explicit "ship-by-iteration" framing, and each iteration treated as a discrete feature when scheduled. Similar to how Proposal 086 (validation performance bundle) bundles 6 pillars that ship as separate features.
5. **Event schema — append-only JSONL, or SQLite, or both?** JSONL is git-friendly + simple; SQLite is queryable but harder to diff. Recommendation: JSONL as canonical store; SQLite as derived cache built on demand.
6. **Privacy default for the telemetry agent** — opt-in to ship anywhere, or default to local-only with explicit opt-in for git-sync/cloud? Recommendation: default local-only; cloud-collector is explicit opt-in with clear documentation of what ships.
7. **Multi-agent detection on a single dev machine** — how does the agent know Copilot CLI vs Claude Code vs Codex are running? Process inspection? Marker files (`~/.specrew/agents/<instance-id>.lock`)? Recommendation: marker files written by each agent host at session start (composes with Proposal 069 multi-host launch path); process inspection as fallback.
8. **Cloud-agent monitoring depends on remote-execution proposal** — does that proposal exist yet? If not, draft it as a sibling so this proposal has the adapter shape to integrate against. (Memory mentions "concurrent multi-host execution" as future Proposal 076 — not yet drafted.)
9. **Write actions — should *any* land at MVP, or strictly read-only until iteration 5?** Strict read-only is safer; allowing one or two innocuous writes (e.g., annotate) at MVP may build user habit. Recommendation: **strict read-only at MVP**; revisit in iteration 2.
10. **How does this compose with the methodology site (Proposal 013)?** The methodology site is a documentation/marketing surface for people who haven't installed Specrew yet. The dashboard is for users *with* an installed Specrew project. Different audiences, different content. They could share branding + design system but should remain separate apps.
11. **Multi-project portfolio storage** — where does the dashboard know about "all my Specrew projects"? Config file in `~/.specrew/projects.yml`? Auto-discovery via filesystem scan? Recommendation: explicit config; auto-discover with user confirmation.
12. **Should the dashboard surface in-flight failures** (e.g., a Crew currently stuck in a repair loop, a long-running validator)? This is closer to alerting than observability. Recommendation: yes, as a "system health" widget on the main page, surfaced via the event stream.
13. **Onboarding view tone** — terse / friendly / pedagogical? Should it adapt based on detected expertise (composes with Proposal 015 Expertise-Aware Adaptive Interaction)?
14. **External-stakeholder mode** — read-only public link to a curated subset of the dashboard for non-developers (PMs, security review, executives)? Useful but adds auth/export complexity. Recommendation: defer past iteration 5.

## Risks

1. **Scope sprawl** — 31 view-families is a lot. Without strict MVP discipline + iteration gating, this becomes a multi-year project that ships nothing usable. *Mitigation*: MVP is 6 view-families; each iteration has a tight scope; no view ships without being valuable on its own.
2. **Maintenance burden of a parallel frontend stack** — Specrew is currently PowerShell + markdown. Adding a Node/React surface means a second build, second test suite, second deploy. *Mitigation*: keep the frontend stack minimal; consider single-binary distribution to hide complexity from users; separate frontend release cadence from Specrew core.
3. **Data model lock-in** — the event schema, once emitted by half a dozen features, is expensive to change. *Mitigation*: schema versioning baked in from day one (`"schema": "specrew-event-v1"`); rich payload-typing is opt-in; aggressively keep v1 minimal.
4. **Telemetry trust** — users may distrust a daemon that reads their entire `.specrew/`. *Mitigation*: open-source agent; clear documentation of what's read + where it's shipped; local-only as default; never any auto-upgrade-to-cloud.
5. **Multi-agent detection fragility** — process inspection differs across OSes; marker-file convention only works if every host adopts it. *Mitigation*: composes tightly with Proposal 069 (multi-host launch path) which already needs per-host launch standardization.
6. **Cloud-collector hosting cost + ops** — running a multi-tenant SaaS is non-trivial. *Mitigation*: cloud-collector is a far-future opt-in; local-only + git-sync cover most users for the foreseeable future.
7. **Privacy regulation exposure** — if cloud-collector touches enterprise customer data, GDPR/SOC2 implications follow. *Mitigation*: defer cloud-collector commercial offering until a deliberate business decision; document data-flow precisely.
8. **Replicates GitHub/Jira/Linear features** — risk of users saying "I already have this in <X>". *Mitigation*: focus on what is *Specrew-native* (boundaries, retros, debt, agent monitoring, cost-per-iteration) that other tools cannot surface; integrate (#31) rather than re-implement.
9. **Write-action governance bypass** — if web UI can approve boundaries, it must produce identical audit + commit trail as CLI; otherwise it's a backdoor. *Mitigation*: write actions are deferred to iteration 5+ and must route through the same validator/commit/audit code paths as CLI; no parallel approval mechanism.
10. **Onboarding view becomes wrong** — "where should I start?" recommendation is a heuristic; if wrong, it actively misleads new devs. *Mitigation*: present as suggestions, not commands; always link to underlying data.
11. **Heatmap / activity views can be weaponized** — "developer X did less than developer Y" surveillance dynamics. *Mitigation*: design choice — no per-developer leaderboards; activity views are about *code surface* and *process compliance*, not individual ranking. Document this stance explicitly.

## Cross-references

- **Composes with** (proposals this dashboard surfaces / depends on):
  - [008 NFR Governance](008-nfr-governance.md) — NFR status surfaced in quality view
  - [009 Velocity Dashboard "Where Am I?"](009-velocity-dashboard.md) — the CLI predecessor; dashboard is the rich evolution
  - [010 Multi-Developer Reconciliation](010-multi-developer-reconciliation.md) — primary consumer of multi-dev view
  - [011 Architecture Intent Checkpoint](011-architecture-intent-checkpoint.md) — feeds architecture view
  - [012 Visual Artifact Extension](012-visual-artifact-extension.md) — feeds architecture view with diagrams
  - [013 Methodology Site](013-methodology-site.md) — sibling marketing surface; SDLC explainer (#5) may share content
  - [015 Expertise-Aware Adaptive Interaction](015-expertise-aware-adaptive-interaction.md) — onboarding view personalization
  - [017 Learning Loop Closure](017-learning-loop-closure.md) — feeds retro explorer + compliance scorecard
  - [018 Source-Spec Fidelity Contract](018-source-spec-fidelity.md) — feeds spec-fidelity tracker
  - [024 Multi-Host Runtime Abstraction](024-multi-host-runtime-abstraction.md) — multi-agent telemetry depends on host abstraction
  - [028 Lifecycle Hardening](028-lifecycle-hardening.md) / [033 Specrew Governance CLI](033-specrew-governance-cli.md) — feeds roadmap view + decision ledger
  - [047 Project Governance Profile](047-project-governance-profile.md) — profile selects which views/detectors/write-actions are enabled
  - [058 Plugin-Based Host Distribution](058-plugin-based-host-distribution.md) — multi-agent detection via plugin marker files
  - [068 Cost-Aware Model Routing](068-cost-aware-model-routing.md) / [070 Token Economy MVP](070-token-economy-mvp.md) — feed cost dashboard + agent/model performance
  - [069 Multi-Host Launch Path](069-multi-host-launch-path.md) — multi-instance/multi-host marker-file convention
  - [086 Validation Pipeline Performance Bundle](086-validation-pipeline-performance-bundle.md) — feeds quality-gate trends + build-time graphs
  - [089 PR Review Integration](089-pr-review-integration-address-pr-review-gate.md) — feeds bugs/defects + external integration view
  - [091 Technology Debt Control](091-tech-debt-control.md) — feeds tech debt view + problematic-files view
  - [096 Proposal-Driven Design Profile](096-proposal-driven-design-profile.md) — dashboard reads profile state from `.specrew/config.yml` and adapts roadmap/architecture/decision views per dual-mode rendering described above
- **Possibly subsumes / partially overlaps with**:
  - [044 Process Insights / Coaching](044-process-insights-coaching.md) — if it exists; the compliance scorecard + retro explorer overlap with coaching insights. Coordinate at clarify time.
  - [046 / 048 Dashboard Renderer + Velocity Refinement](046-dashboard-renderer.md) — those are CLI-side enhancements to `specrew where`; this proposal is the web surface. They compose: web pulls richer data, CLI stays terse.
- **Sibling proposal needed**:
  - **Remote-execution / cloud-agent proposal** (currently undrafted; memory references future Proposal 076 "concurrent multi-host execution") — cloud-agent monitor (#10) depends on it. Recommend drafting alongside this proposal so adapter shape is co-designed.

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to user direction on a Specrew dashboard web app for SDLC observability + insight. 31 view-families catalogued; MVP carved out as 6 view-families in iteration 1; ~110-145 SP total across 5 iterations (realistic 80-120 with scoping). Awaiting clarify-time decisions on tech stack, single-vs-split proposal shape, write-action policy, and cloud-collector business model.
