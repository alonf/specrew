---
proposal: 101
title: External Tracker Sync Provider Abstraction (GitHub Projects / Azure DevOps / Jira / Linear)
status: candidate
discussion-status: ad-hoc
spec-status: none
relationship-status: clean
phase: phase-2
estimated-sp: 20-30
discussion: ad-hoc 2026-05-22 session
---

# External Tracker Sync Provider Abstraction (GitHub Projects / Azure DevOps / Jira / Linear)

## Why

Specrew currently treats `tasks.md` as the authoritative tracking surface for an iteration's work. For a solo developer or small open-source project, this is fine. For **the majority of enterprise projects** — which use Linear, GitHub Projects, Azure DevOps Boards, or Jira as the canonical work-tracking system — `tasks.md` is a parallel surface that nobody on the team reads, creating tracking blind spots.

Memory entry `project_proposals_pattern_as_opt_in_profile_2026_05_19` documents the strategic decision: external trackers are **Pattern A** — the *default* for downstream projects. Proposals (Proposal 096 `proposal-driven-design` profile) are Pattern B, opt-in. **Pattern A has been the documented default for three days and has zero implementation behind it.** That is the gap this proposal fills.

Empirical signals:

- The 2026-05-22 external research document framed `--sync-provider github|azure|jira` as a primary roadmap item; the framing is consistent with the existing Pattern A decision
- Proposal 057 (Roadmap Spine + Input Adapter Pattern) — already promoted to draft — introduces the input-adapter pattern but for the *roadmap* layer, not *task* layer. The same adapter pattern naturally extends to tasks; without this proposal, that extension stays vapor
- Proposal 091 (Tech Debt Control) Mode C promotion explicitly says debt entries promote to `roadmap.yml` planned-item rows when proposal-driven-design profile is inactive. The roadmap layer assumes there's something it routes *to*; for projects using external trackers, that "something" is the tracker
- The github-coupling-investigation memory shows current Specrew is heavily GitHub-coupled; this proposal's provider abstraction is *the* mechanism for breaking that coupling without losing the GitHub-shaped experience for GitHub-org users

User-stated motivation (2026-05-22):

> "[The external research document] mentioned `--sync-provider github|azure|jira` as a primary roadmap item; it's consistent with memory's Pattern A; we need a concrete proposal for it."

This proposal is **arguably higher-leverage for adoption than Proposal 096** (proposal-driven-design profile). 096 unlocks projects that *want* the deliberation surface. 101 unlocks every project that *uses an external tracker* — which is most production projects.

## What (7 Pillars)

### Pillar 1 — Default-on vs opt-in (default-on with off-switch)

External tracker sync should be **default-on** for new Specrew projects, **with an opt-out** for solo devs / scratch repos / local-only workflows.

Rationale: memory's Pattern A already says external tracker is the *default*. The implementation should match the strategic decision: at `specrew init`, the prompt should be:

> Will this project track work in an external system (Linear, GitHub Issues, Jira, Azure DevOps)? [Y/n]
> If yes, which one? [linear | github-issues | github-projects | jira | azure-devops | local-only]
> [If anything other than local-only:] Configure now? [Y/n] (deferred config is fine)

This is **opposite** to Proposal 096's default-off prompt for proposals. The two profiles together cover:

| What user wants | Activate |
|---|---|
| External tracker (most projects) | Sync provider (this proposal); local-only for `tasks.md` is just the deferred state |
| Proposals surface (some projects) | `proposal-driven-design` profile (Proposal 096) |
| Neither (scratch / prototype) | `--no-tracker --no-proposals`; pure Specrew core |
| Both (Specrew itself, Rust-RFC-style projects) | Both activated |

### Pillar 2 — Sync directionality + canonical-ownership map

The core design decision: **one-way (Specrew → tracker) vs bidirectional (tracker → Specrew flows back)**.

One-way is simpler; limits value (tracker updates don't reach Specrew). Bidirectional is harder; introduces conflict resolution when both sides edit independently. This proposal commits to **bidirectional with a canonical-ownership map** per field. Each task field is owned by exactly one side:

| Field | Canonical owner | Rationale |
|---|---|---|
| Identity (stable GUID) | **Specrew** | Specrew generates, tracker stores in description / custom-field |
| Title | **Specrew** | Authored at plan time; tracker mirrors |
| Description / acceptance criteria | **Specrew** | Authored at plan time; tracker mirrors |
| Status (pending / in-progress / complete / blocked) | **Tracker** | Updated by humans clicking in the tracker UI; Specrew reads |
| Owner / assignee | **Tracker** | Tracker is the team-coordination surface |
| Comments / discussion | **Tracker** | Tracker is the discussion surface |
| Effort estimate (SP) | **Specrew** | Authored at plan time |
| Iteration / sprint | **Specrew** | Specrew-lifecycle concept; tracker mirrors |
| Custom labels | **Negotiated** | Per-project profile decides |

When fields diverge, the canonical owner wins. Audit log captures the diverging-write that lost. Retro can surface frequent divergences as a methodology problem ("our team keeps editing acceptance criteria in Jira; should we make that the canonical surface?").

### Pillar 3 — Provider divergence handling (rich adapters, not lowest common denominator)

The five named providers have substantially different data models:

| Provider | Hierarchy | Statuses | Custom fields | Cycles/iterations | Auth |
|---|---|---|---|---|---|
| GitHub Issues | Flat + labels | Open/Closed | Limited (no native) | No native | `gh` CLI |
| GitHub Projects | Custom views + Items | Configurable per project | Yes | Iteration field | `gh` GraphQL |
| Linear | Issue + sub-issue | Configurable | Yes | Cycles | GraphQL + API key |
| Jira | Epic→Story→Subtask | Workflow-defined | Extensive | Sprints | REST + auth |
| Azure DevOps | Multiple work-item types | Workflow-defined | Extensive | Iterations | `az` CLI / REST |

A naive abstraction collapses to "flat tasks with open/closed status" — lowest common denominator — and loses the value of using Linear / Jira / Azure DevOps in the first place. This proposal commits to **rich per-provider adapters**:

- Each adapter implements the full `ITaskDispatcher` interface (defined in Pillar 4) plus provider-specific extensions
- Adapters expose provider-specific features through escape-hatch fields (`provider-specific.linear.cycle-id`, `provider-specific.jira.epic-key`, etc.)
- Specrew core models don't lose information when round-tripping through any adapter

The implementation cost is real: each adapter is genuinely separate code (~150-300 LoC each). The MVP ships **two adapters** (GitHub Issues + Linear, as the most-requested-by-volume pairing); iteration 2 adds Jira + Azure DevOps; iteration 3 adds GitHub Projects (which is more complex than GitHub Issues because of the Project-as-canvas data model).

### Pillar 4 — Adapter interface (`ITaskDispatcher`)

The adapter interface — drawn from the external research document's framing but sharpened for Specrew's actual data model:

```text
ITaskDispatcher (per provider)
  ├── connect(config) → session    # auth + session establishment
  ├── enumerate_existing() → [tasks_in_tracker]    # for initial sync
  ├── push_task(specrew_task) → tracker_id    # Specrew-canonical fields
  ├── update_task(tracker_id, fields) → ()    # delta sync
  ├── pull_task(tracker_id) → tracker_task    # for tracker-canonical fields
  ├── close_task(tracker_id, reason) → ()    # iteration / feature closeout
  └── reconcile(specrew_state, tracker_state) → [conflicts]    # bidirectional diff
```

Each adapter implements these against its provider. The **reconcile** method is the heart of bidirectional sync: it produces a diff of conflicts that the canonical-ownership map (Pillar 2) then resolves automatically; unresolvable conflicts surface to the user at retro or at sync time.

Composes naturally with Proposal 057's input-adapter pattern — same shape, applied to tasks instead of roadmap. Should share the abstraction infrastructure rather than fork it.

### Pillar 5 — Task identity + idempotency under refactoring

Stable GUIDs (the research document's pattern) ensure re-sync doesn't create duplicates. But what about **Specrew-side refactoring**? Three cases:

| Refactor | Naive behavior | Required behavior |
|---|---|---|
| T001 renumbered to T0NN | Create new tracker task; orphan old | Re-link via GUID; rename in tracker |
| Task split into T001-a + T001-b | Create two new tracker tasks; orphan old | Spawn child tasks linked to parent; mark parent "split" |
| Two tasks merged | Create new tracker task; orphan both | Mark one canonical; mark other as duplicate-of-canonical |
| Task removed (rejected from scope) | Tracker task lingers | Close in tracker with "removed-from-scope" reason |

GUIDs survive refactoring because they live in a hidden HTML comment in `tasks.md` (e.g., `<!-- specrew-task-guid: 7f3a... -->`), not in the visible task number. Numbering changes; GUIDs persist. Adapter reads GUIDs from the comment, maps to tracker IDs via local sidecar (`.specrew/sync-state.yml`).

### Pillar 6 — State sync (per-provider status mapping)

Tracker statuses don't map 1:1 to Specrew statuses. Per-provider mapping config required:

```yaml
# .specrew/sync-state.yml
providers:
  linear:
    status_mapping:
      specrew_pending: "Backlog"
      specrew_in_progress: "In Progress"
      specrew_complete: "Done"
      specrew_blocked: "Blocked"
  jira:
    status_mapping:
      specrew_pending: "To Do"
      specrew_in_progress: "In Progress"
      specrew_complete: "Done"
      specrew_blocked: "Blocked"
```

Mapping config is provider-specific; user-editable per project. Validator catches missing mappings.

### Pillar 7 — Per-provider authentication + tooling

Each provider has its own auth + tooling story. The proposal commits to **explicit per-provider docs** + **shared authentication abstraction** that lives in `.specrew/credentials.yml.example` (gitignored real version: `.specrew/credentials.yml`):

```yaml
# .specrew/credentials.yml (gitignored)
providers:
  github:
    auth_via: gh-cli  # delegates to gh's existing auth
  linear:
    auth_via: api_key
    api_key: ${LINEAR_API_KEY}  # env var
  jira:
    auth_via: api_token
    domain: mycompany.atlassian.net
    email: user@example.com
    api_token: ${JIRA_API_TOKEN}
  azure-devops:
    auth_via: az-cli  # delegates to az's existing auth
```

Each adapter validates credentials at session-establishment; explicit error messages when missing/wrong. No credentials in tracked files.

## Functional Requirements

- **FR-001**: `specrew init` prompt offers external tracker selection; default-on; opt-out available
- **FR-002**: `ITaskDispatcher` interface defined; reused for all providers
- **FR-003**: Iteration 1 ships adapters for GitHub Issues + Linear
- **FR-004**: Iteration 2 ships adapters for Jira + Azure DevOps
- **FR-005**: Iteration 3 ships adapter for GitHub Projects (richer data model)
- **FR-006**: Stable GUIDs in `tasks.md` (via HTML comment); persists through Specrew-side refactoring
- **FR-007**: Bidirectional sync with canonical-ownership map per field (Pillar 2)
- **FR-008**: Per-provider status mapping config in `.specrew/sync-state.yml`
- **FR-009**: Per-provider auth via `.specrew/credentials.yml` (gitignored); `.example` file tracked
- **FR-010**: `specrew sync` CLI command — explicit sync trigger; reports diff before applying
- **FR-011**: `specrew sync --dry-run` reports what would change without applying
- **FR-012**: Lifecycle integration: sync auto-triggered at task creation (push), at iteration-closeout (pull statuses); explicit user-trigger otherwise
- **FR-013**: Conflict resolution per Pillar 2 canonical-ownership; unresolvable conflicts surface to user at retro
- **FR-014**: Adapter conformance test suite — each adapter passes the same `ITaskDispatcher` contract tests
- **FR-015**: Composition with Proposal 057 — share input-adapter infrastructure with roadmap-adapter; same abstraction
- **FR-016**: Composition with Proposal 097 — each enabled provider creates a coupling-surface entry with `category: service-api`
- **FR-017**: Composition with Proposal 010 — multi-developer reconciliation uses the tracker as shared-truth substrate
- **FR-018**: Composition with Proposal 091 — debt promotion to `roadmap.yml` when proposal-driven-design profile inactive AND tracker not set; with tracker set, promote to tracker
- **FR-019**: Self-applied: Specrew itself uses GitHub Issues as the tracker (composes with proposal-driven-design profile already active)
- **FR-020**: Documentation: `docs/external-tracker-integration.md` describes setup per provider

## Out of scope

- **Real-time webhook integration** (tracker pushes notifications to Specrew) — out of scope at MVP; relies on poll-on-sync; webhooks are a future enhancement
- **GUI for tracker browsing** — composes with Proposal 092 (Dashboard); not this proposal's responsibility
- **Custom workflow definitions** (define a Jira workflow from Specrew) — out of scope; user manages workflows in the tracker
- **Migration between trackers** ("we used Jira, now we want Linear") — out of scope; manual migration with adapter-pair scripting
- **Multi-tracker sync** (single project syncs to two trackers simultaneously) — out of scope; one tracker per project
- **Tracker-side custom field provisioning** — adapter assumes user has set up necessary custom fields in tracker; doesn't create them
- **Issue templates / form-based task creation in tracker** — out of scope; tasks pushed are Specrew-shaped
- **AI-driven tracker-data analysis** — out of scope; that's downstream of Proposal 092

## Effort

- **Pillar 1 (init prompt + default-on)**: ~1 SP
- **Pillar 2 (canonical-ownership map + conflict resolution)**: ~3 SP
- **Pillar 3 (provider divergence handling architecture)**: ~2 SP — design + escape-hatch fields
- **Pillar 4 (ITaskDispatcher interface + conformance tests)**: ~3 SP
- **Pillar 5 (GUID stability through refactoring)**: ~3 SP — HTML-comment scheme + sidecar + refactor handling
- **Pillar 6 (status mapping config)**: ~1 SP
- **Pillar 7 (auth + credentials infrastructure)**: ~2 SP
- **GitHub Issues adapter (iteration 1)**: ~3-4 SP
- **Linear adapter (iteration 1)**: ~3-4 SP
- **CLI command (`specrew sync`)**: ~2 SP
- **Lifecycle integration (auto-trigger points)**: ~2 SP
- **Documentation**: ~1-2 SP
- **Total iteration 1**: ~26-30 SP
- **Iteration 2 (Jira + Azure DevOps adapters)**: ~8-10 SP
- **Iteration 3 (GitHub Projects)**: ~6-8 SP
- **Realistic total**: ~40-48 SP across 3 iterations; **MVP target**: ~20-25 SP if Linear or one of the Iteration 1 adapters defers to iteration 2.

## Phase placement

**Phase 2 — Tier 1 adoption gate (high priority)**. Unblocks Pattern A adoption (most projects). Should ship before significant external-tester onboarding.

Sequencing recommendation:

1. Proposal 057 (Roadmap Spine + Input Adapter Pattern) ships first — supplies the input-adapter pattern this proposal extends
2. 101 ships next; GitHub Issues + Linear adapters in iteration 1; Specrew itself self-applies with GitHub Issues
3. Iteration 2 adds Jira + Azure DevOps after the architecture proves out
4. Iteration 3 adds GitHub Projects after the simpler GitHub Issues adapter has shipped

Alternative ordering: 101 ships before 057 if the input-adapter pattern in 057 isn't blocking (which it might not be — task-adapter and roadmap-adapter can evolve in parallel as long as they later converge on shared infrastructure).

## Open questions

1. **Default-on for new projects — confirm vs reconsider?** Recommendation: yes, default-on; matches Pattern A documented stance. Worth re-checking at clarify time.
2. **MVP adapter selection — GitHub Issues + Linear, or different pair?** Recommendation: GitHub Issues (existing coupling; fastest to ship) + Linear (most-requested-by-enterprise-trial-volume per anecdotal signal). Could swap Linear for Jira if enterprise adoption pressure mandates.
3. **GitHub Issues vs GitHub Projects as the "GitHub" adapter** — Projects is richer; Issues is simpler. Recommendation: ship Issues first (simpler); Projects is iteration 3.
4. **Canonical-ownership map negotiability per project** — should profile let users override (e.g., "in our team, acceptance criteria is canonical in Jira")? Recommendation: yes; profile-level override; default is the table in Pillar 2.
5. **Status-mapping config — Specrew-curated defaults vs forced-explicit?** Recommendation: Specrew-curated defaults shipped; user can override; missing custom-status mappings surface as warnings.
6. **GUID format** — UUID v4? Hash of (feature-id + iteration + task-number-at-creation)? Recommendation: UUID v4 — stable, simple, no collision concerns.
7. **`tasks.md` HTML comment vs frontmatter for GUID — readability?** Recommendation: HTML comment immediately after task heading; invisible in rendered markdown; trivial for parser to extract.
8. **Webhook support timeline** — when does poll-on-sync become insufficient? Recommendation: poll is fine for MVP and most users; webhook is future when multi-dev parallel work demands real-time visibility.
9. **Auth via OAuth flow vs API keys** — better UX for OAuth but harder to ship. Recommendation: API keys at MVP; OAuth-flow is future enhancement.
10. **`specrew sync` triggered when** — fully automated at lifecycle gates, or user-triggered? Recommendation: auto on task creation + iteration closeout; user-triggered otherwise; profile can fully-automate.
11. **What if user runs `specrew sync` and the tracker doesn't exist** (deleted, renamed, etc.)? Recommendation: graceful error with recovery instructions; sync state cached locally so partial recovery possible.
12. **Multi-iteration tasks** — what if a task spans iterations? Recommendation: task linked to its iteration; if rescheduled, sync updates the iteration field.
13. **Specrew-side history for tracker-only edits** — should we keep an audit log of every tracker-side change we pulled? Recommendation: yes, in `.specrew/sync-state.yml`'s `audit:` section; bounded length.

## Risks

1. **Per-adapter implementation cost overruns** — each adapter is genuinely ~150-300 LoC plus tests. *Mitigation*: rigorous interface contract + conformance tests; share as much logic as possible; start with simpler adapter (GitHub Issues) before tackling Jira/Azure DevOps complexity.
2. **Tracker API changes break adapters silently** — providers change auth scopes, deprecate endpoints. *Mitigation*: integration tests; adapter version-locks to tracker API version; explicit deprecation warning when adapter is on aging API.
3. **Bidirectional sync conflicts cause data loss** — canonical-ownership map silently overwrites a field the user expected to be canonical elsewhere. *Mitigation*: audit log preserves every overwrite with full context; retro surfaces frequent overwrites; canonical-ownership map is profile-configurable.
4. **Tracker rate limits block sync at scale** — large team + frequent sync → API throttling. *Mitigation*: per-adapter rate-limit awareness; exponential backoff; batch sync where API supports.
5. **Credentials leakage** — `.specrew/credentials.yml` accidentally committed. *Mitigation*: gitignore + pre-commit secret-scanning (composes with Proposal 100 AT-005/AT-009); credentials.yml.example tracked instead.
6. **Specrew lifecycle gates depend on tracker availability** — tracker down → can't complete iteration closeout. *Mitigation*: tracker sync is non-fatal at boundaries; can be re-tried; degraded mode (`local-only-temporarily`) when tracker unreachable; explicit reconnect step.
7. **Provider lock-in via custom-field usage** — heavy use of Jira custom fields makes switching providers harder. *Mitigation*: portability checker reports custom-field usage; warn users when adopting provider-specific features.
8. **Canonical-ownership map disagreement at team level** — different team members have different mental models. *Mitigation*: profile-level commit to canonical-ownership; document the decision; retro for ongoing tuning.
9. **GUID-based identity confuses users** — "where did this T001-with-GUID come from?". *Mitigation*: GUIDs are in HTML comments (invisible by default); user sees task number normally; GUID surfaces only at sync time.
10. **Specrew dogfooding regresses** — Specrew itself uses GitHub Issues; bad adapter implementation breaks Specrew's own tracking. *Mitigation*: dogfood adapter in a dedicated test branch before adopting on main; canary period.

## Cross-references

- **Composes with**:
  - [010 Multi-Developer Reconciliation](010-multi-developer-reconciliation.md) — uses tracker as shared-truth substrate; mutually reinforcing
  - [047 Project Governance Profile](047-project-governance-profile.md) — profile sets default provider + canonical-ownership overrides
  - [057 Roadmap Spine + Input Adapter Pattern](057-roadmap-spine-input-adapter.md) — supplies the input-adapter abstraction this proposal extends to tasks
  - [091 Technology Debt Control](091-tech-debt-control.md) — Mode C promotion routes to tracker when tracker is configured (composes with 091's profile-aware promotion)
  - [092 Specrew Dashboard Web App](092-specrew-dashboard-web-app.md) — dashboard consumes tracker data alongside Specrew local state
  - [096 Proposal-Driven Design Profile](096-proposal-driven-design-profile.md) — sibling profile; both can be active in the same project (e.g., Specrew itself)
  - [097 Coupling Surface Catalog](097-coupling-surface-catalog.md) — each enabled provider is a coupling-surface entry (`category: service-api`)
  - [099 Cross-Model Independent Reviewer](099-cross-model-independent-reviewer.md) — reviewer findings surface in the tracker (when integration shipped)
  - [100 Agent-Class Threat Surface](100-agent-class-threat-surface.md) — credentials leakage scenarios (AT-005, AT-009) apply
- **Memory motivation**:
  - `project_proposals_pattern_as_opt_in_profile_2026_05_19` — Pattern A: external trackers default for downstream; this proposal implements it
  - `project_github_coupling_investigation_2026_05_22` — provider abstraction is the primary mechanism for reducing GitHub-specific coupling
- **External sources**:
  - External research document received 2026-05-22 (raised `--sync-provider github|azure|jira` framing; this proposal sharpens with concrete bidirectional + canonical-ownership + adapter-contract design)

## Status history

- 2026-05-22: status set to `candidate`. Drafted to implement Pattern A (external trackers as default for downstream) from existing strategic decision. Bidirectional sync with canonical-ownership map per field; rich per-provider adapters (not lowest common denominator); GitHub Issues + Linear adapters in iteration 1; Jira + Azure DevOps iteration 2; GitHub Projects iteration 3. Arguably higher-leverage for adoption than Proposal 096 (proposal-driven-design). Awaiting clarify-time decisions on default-on stance, adapter pair selection, and canonical-ownership map tuning.
