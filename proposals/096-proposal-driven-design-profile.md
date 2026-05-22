---
proposal: 096
title: Proposal-Driven Design Profile (Umbrella for Opt-In Pre-Spec Deliberation Pattern)
status: candidate
phase: phase-3
estimated-sp: 8-12 (umbrella scope; component proposals carry their own SP separately)
discussion: ad-hoc 2026-05-22 session
---

# Proposal-Driven Design Profile (Umbrella for Opt-In Pre-Spec Deliberation Pattern)

## Why

Specrew core methodology is lifecycle + boundaries + validators + retros + substantive-interaction — that's what every Specrew project gets. The **proposal → spec → feature** pattern that Specrew itself uses (the `proposals/` directory, INDEX, status frontmatter, discussion threads, promotion pathways) is a *specific* deliberation pattern that suits some projects but not others. Per the existing strategic decision documented in memory (`project_proposals_pattern_as_opt_in_profile_2026_05_19`):

- Most downstream projects use external issue trackers (Pattern A) — Linear, GitHub Issues, Jira — for pre-spec ideation
- Forcing the `proposals/` ceremony on every Specrew project adds heavy overhead that small/early-stage projects don't need
- Specrew's own proposals/ surface exists because *Specrew itself* needs that depth of design deliberation — that's a project-specific need, not a methodology universal

The Proposal 052 profile-system architecture is the right home for "powerful patterns that not every project wants." This proposal **defines the `proposal-driven-design` profile** as one of Specrew's anchor profiles, bundling all the pieces that currently exist or are being drafted around the `proposals/` surface.

The profile is the architectural anchor several recent proposals are implicitly assuming:

- **Proposal 028** (Public Proposals Surface) — validator + auto-transition + discussion integration; explicitly proposal-coupled
- **Proposal 062** (Reciprocal Dependency Metadata) — only meaningful when proposals reference each other
- **Proposal 091** (Tech Debt Control) — mostly profile-neutral, but `debt promote <id> → proposal-NNN` pathway is profile-coupled
- **Proposal 093** (Discussion-Field Discipline) — entirely proposal-specific
- **Proposal 095** (Lifecycle State Richness) — entirely proposal-specific
- **Proposal 092** (Dashboard) — roadmap view #2 and decision view #4 layer proposals on top of profile-neutral data sources

Without this umbrella, those proposals are forward-pointing dangling references. With it, they have a clear "component of profile X" home, and `specrew proposal *` commands have a clear gating story.

User direction (2026-05-22) — paraphrased:

> Proposals are opt-in for downstream projects. Are you sure we want a `specrew proposal` command? Or do we want to make proposals mandatory for all projects?

This proposal preserves the opt-in stance (recommended for adoption reasons documented in memory) and **operationalizes** it: the CLI surface, validator rules, INDEX rendering, and discussion machinery are all profile-gated, not core.

## What

### Profile definition (1-line summary)

`proposal-driven-design` is an opt-in Specrew profile that adds a public deliberation surface (`proposals/` directory + INDEX + status frontmatter + discussion-thread integration + CLI commands) for projects that want long-form design deliberation before specs are written.

### Activation

Activated at `specrew init` or via post-init config:

```yaml
# .specrew/config.yml
profiles:
  - proposal-driven-design
```

When activated:

- `proposals/` directory is created with `README.md`, `INDEX.md`, `_template.md` scaffold
- `specrew proposal *` commands light up (registered with the CLI dispatcher)
- Validator runs proposal-frontmatter rules (composes with Proposal 028)
- Boundary-state-sync triggers auto-transitions when features ship (composes with Proposal 028)
- Discussion-thread integration available (composes with Proposal 093)
- Tech-debt `promote` pathway (Proposal 091) routes to candidate-proposal creation; otherwise routes to `roadmap.yml` planned-entry

When NOT activated:

- No `proposals/` directory created
- `specrew proposal *` commands behave per the **Unactivated-command UX** (next section) — recommend-but-don't-enroll
- Validator skips proposal-frontmatter rules
- Tech-debt `promote` falls back to `roadmap.yml` planned-entry (or an external-tracker adapter; see Out of Scope)
- Dashboard (Proposal 092) renders roadmap view from `roadmap.yml` only; proposals layer absent

### Unactivated-command UX (recommend, don't enroll)

When `specrew proposal <anything>` is invoked in a project that has not activated the profile, the command exits with code 2 and prints an informative message. **The command is recognized — it does not error as "unknown" — but it does not silently activate the profile either.** The user is directed to make an explicit choice.

Output template:

```text
specrew: 'proposal' commands belong to the 'proposal-driven-design' profile,
         which this project has not activated.

What this profile does:
  Adds a public design-deliberation surface (proposals/, INDEX,
  status frontmatter, discussion threads). Suitable for methodology
  projects, language/framework designs, and projects with significant
  cross-stakeholder design decisions before specs are written.

Most projects don't need this. The common alternative is an external
issue tracker (Linear / GitHub Issues / Jira) for pre-spec ideation.
See: docs/proposals.md

To activate:
  specrew profile add proposal-driven-design

To see all available profiles:
  specrew profile list

Exiting without changes.
```

Design rationale — three options considered, third chosen:

- **(rejected) Hard reject** — register the command nowhere, produce "unknown command" error. User has no path forward; bad UX.
- **(rejected) Auto-enroll on first use** — interactively prompt "activate now? [y/N]" and scaffold on yes. Activating the profile creates `proposals/`, alters validator behavior, and adds discoverable surface to the project. That's a methodology commitment, not a one-command convenience. It should be a deliberate decision at `init` time or via explicit `specrew profile add`, not a side effect of typing the wrong command.
- **(chosen) Recommend, don't enroll** — informative exit with activation guidance + explicit acknowledgement of the alternative (external trackers). Gives the user enough information to choose deliberately. Validates "don't activate" as a legitimate answer rather than implying "you forgot to turn this on."

The same UX pattern is the reference implementation for **every** profile-gated command surface across Specrew (not just `specrew proposal`). When other profiles add their own commands in the future, they follow the same recommend-but-don't-enroll template.

### Bundle composition

The profile bundles these components (each ships as its own feature/proposal; the profile is the meta-grouping):

| Component | Source | Always-required for profile | Optional opt-in within profile |
|---|---|---|---|
| `proposals/` directory + README + template | Profile init scaffold | ✓ | |
| Frontmatter schema + validator rules | Proposal 028 | ✓ | |
| Status auto-transition on feature ship | Proposal 028 | ✓ | |
| Reciprocal dependency metadata | Proposal 062 | ✓ | |
| Discussion-field discipline + CLI command | Proposal 093 | ✓ | |
| Lifecycle state richness (partial/frozen/per-component) | Proposal 095 | ✓ | |
| INDEX.md auto-rendering | Proposal 028 + 095 | ✓ | |
| `specrew proposal status / list / discuss / promote / components` CLI | Composed across 028/033/091/093/095 | ✓ | |
| Tech-debt `promote` adapter (debt → candidate proposal) | Proposal 091 | | ✓ |
| Public GitHub Discussions integration | Proposal 028 + 093 | | ✓ (depends on hosting on GitHub) |

The "always-required" components define what the profile *is*; the "optional" components are within-profile feature flags.

### Specrew's own configuration

This Specrew repo will declare the profile activated in its own `.specrew/config.yml` (composing with the existing config) so the proposal surface continues to work exactly as it does today. The migration is mechanical:

```yaml
# .specrew/config.yml after this proposal ships
profiles:
  - proposal-driven-design
```

No existing proposals/ content changes. No INDEX restructuring. No proposal-status changes. The profile just makes the *implicit* "Specrew uses this pattern" *explicit* via config.

### Anchor-profile question

Proposal 052 (Specrew Profile System) mentions "Specrew core authors 1-2 anchor profiles to prove the system works." There are two plausible homes for `proposal-driven-design`:

- **(A)** As an independent proposal that ships *after* 052 lands the profile-gating mechanism
- **(B)** As part of 052's anchor-profile bundle, shipping together with the profile system itself

This proposal is drafted as **(A)** for clarity (it has enough scope-specific decisions to deserve its own proposal), but if 052 is being scoped at clarify-time, the answer to "do we bundle anchors with the system or separately" should consider this proposal as one of the candidate anchors. Cross-reference both ways.

### Specifically what `specrew proposal` does (the CLI surface)

Composed from the component proposals; lives under the profile:

| Command | Source proposal | Purpose |
|---|---|---|
| `specrew proposal new <slug>` | 028 / 033 | Scaffold a new proposal from `_template.md` |
| `specrew proposal status <NNN>` | 095 | Show full lifecycle picture for a proposal |
| `specrew proposal list [--status=… --has-spec --no-discussion --frozen --conflicts …]` | 095 | Query proposals across all dimensions |
| `specrew proposal components <NNN>` | 095 | Show per-pillar breakdown for multi-component proposals |
| `specrew proposal discuss <NNN>` | 093 | Open GitHub Discussion + write URL back to frontmatter |
| `specrew proposal promote <id>` | 091 | Promote a tech-debt entry into a candidate proposal |
| `specrew proposal transition <NNN> <new-status>` | 028 / 095 | Explicit status change with audit-log entry |
| `specrew proposal index` | 028 / 095 | Regenerate INDEX.md from frontmatter |

When the profile is not activated, none of these commands are registered.

## Functional Requirements

- **FR-001**: Profile activation via `.specrew/config.yml` `profiles:` array; supports composition with other profiles
- **FR-002**: At `specrew init`, prompt user whether to activate `proposal-driven-design` (default: off, with brief explanation of trade-offs)
- **FR-003**: Profile-init scaffold creates `proposals/` directory with README, INDEX, `_template.md`
- **FR-004**: CLI dispatcher conditionally executes `specrew proposal *` commands based on profile activation. When activated: full command behavior. When not activated: recommend-but-don't-enroll UX per the "Unactivated-command UX" section — informative message, exit code 2, no scaffolding side effects
- **FR-005**: Validator rule set (proposal-frontmatter checks, auto-transition, INDEX rendering) runs only when profile activated
- **FR-006**: Tech-debt `promote` adapter (Proposal 091) routes correctly per profile state (to candidate proposal if activated; to `roadmap.yml` planned-entry otherwise)
- **FR-007**: Dashboard (Proposal 092) detects profile state and renders proposals-layer conditionally; profile-neutral data sources (roadmap.yml, decisions/, etc.) work either way
- **FR-008**: `specrew profile list` shows activated profiles + brief description of each (composes with Proposal 052)
- **FR-009**: Specrew's own `.specrew/config.yml` declares `profiles: [proposal-driven-design]` at this proposal's ship; verifies no behavior regression
- **FR-010**: Documentation: `docs/getting-started.md` describes the profile in the init flow; `docs/proposals.md` (new, profile-specific) describes the pattern in detail; only loaded into help-system when profile activated
- **FR-011**: Profile deactivation is non-destructive: removing the profile from config doesn't delete `proposals/` content; user can re-activate at any time

## Out of scope

- **External-tracker adapters** (Linear / GitHub Issues / Jira as alternative to proposals/) — out of scope for this proposal; a separate `external-tracker` profile could be drafted to provide the Pattern A integration documented in memory
- **Migrating an existing project's external-tracker issues into `proposals/`** — manual process if user wants to switch
- **Multi-profile conflict resolution** (what if two activated profiles claim conflicting capabilities) — handled by Proposal 052's profile-system core, not here
- **Community / external authors of proposal-pattern variants** — out of scope; this is Specrew's first-party anchor profile
- **Auto-detection** of "this project probably wants proposals" — explicit user choice at init; no heuristics
- **Visual UI for proposal browsing** — covered by Proposal 092 (Dashboard); this proposal just ensures the dashboard's data sources adapt

## Effort

This proposal's *direct* SP cost is small — most weight is in the component proposals it bundles:

- **Profile definition + activation/deactivation mechanics**: ~3 SP — config-flag parsing, CLI-dispatcher conditional registration, scaffold-on-activate logic
- **Specrew self-migration to declare profile**: ~0.5 SP — one config-file edit + regression test
- **CLI-dispatcher integration + error message for non-activated state**: ~1.5 SP
- **`docs/proposals.md` + getting-started conditional section**: ~1.5 SP
- **Init-time prompt**: ~1 SP
- **Profile-list integration with Proposal 052's `specrew profile`**: ~0.5 SP (depends on 052 shipping; trivial composition once it does)
- **Total this proposal**: ~8-12 SP

Component proposals (028, 062, 091, 093, 095) carry their own SP independently. The full profile bundle's total cost is the sum of those plus this umbrella — but each ships independently.

## Phase placement

**Phase 3 (extensibility tier)**. The profile system architecture is Phase 3 work; anchor-profile definitions follow naturally.

Sequencing recommendation:

1. Proposal 052 (profile system core) ships first OR ships alongside this proposal
2. This proposal ships immediately after, declaring `proposal-driven-design` as the first anchor profile
3. Components (028, 062, 091, 093, 095) ship under the profile umbrella; can ship in any order since each is independent
4. Specrew self-migrates its `.specrew/config.yml` to declare the profile at this proposal's ship

If 052 is delayed, this proposal could ship with a **minimal profile-gating mechanism** (just a config flag + CLI-dispatcher branch), explicitly scoped to "until 052 lands the full profile system." That fallback is ~3 SP cheaper than the full integration.

## Open questions

1. **Should this proposal ship as part of 052's anchor-profile bundle**, or separately? Argument for bundling: tighter design coupling, single umbrella commit. Argument for separately: each anchor profile has enough scope-specific design decisions to deserve its own proposal. Recommendation: separately (as drafted), with explicit `composes-with: 052` cross-reference.
2. **Default at init: on or off?** If "off", new Specrew projects don't get proposals by default — which is correct for adoption-friendliness but means Specrew dogfooding requires explicit on-flip. If "on", every new project gets the heavy ceremony. Recommendation: **off** by default; init prompt explains the choice; Specrew's own repo explicitly opts in.
3. **What about projects that want a *lighter* proposal pattern** (just a `proposals/` directory with no INDEX automation, no discussion threads, no CLI)? Sub-profile? Recommendation: out of scope; the lighter pattern is "no profile, just informal docs". Don't fragment.
4. **Should the init-time prompt offer external-tracker as an alternative**? Recommendation: yes when the external-tracker profile exists; for now (only this anchor), the prompt is "proposal-driven-design: yes / no / decide later (off, can be activated later)".
5. **How does this profile interact with Proposal 047 (Project Governance Profile)?** 047 is about project-level governance settings (init-time preference capture); this proposal is about a specific feature-pattern profile. Recommendation: composes — governance profile can recommend or default-activate `proposal-driven-design` depending on project type ("methodology authoring projects → activate" vs "standard product → leave off").
6. **Deactivation semantics in the wild** — a project activates the profile, generates 30 proposals, then deactivates. What happens to `proposals/`? Recommendation: non-destructive — files remain on disk; CLI commands disappear; validator skips; user can re-activate or move/delete manually. Document explicitly.
7. **Does CLI-dispatcher conditional registration apply at install time or at runtime?** Recommendation: runtime — checked on each invocation; lighter to maintain than install-time generation.
8. **Naming consistency** — should it be `proposal-driven-design`, `proposals`, `pdd`, or something else? Recommendation: `proposal-driven-design` for clarity; aliases acceptable later.
9. **Self-applied dogfooding**: Specrew is the canonical first user. Open question for clarify time: do we add a regression test that confirms Specrew's behavior is unchanged after the profile-config migration? Recommendation: yes — small CI check that `proposals/` works exactly as today.

## Risks

1. **Fragmenting the methodology** — multiple optional profiles risk making "what is Specrew?" answer harder. *Mitigation*: profile system is bounded (1-2 anchors initially, per 052); each profile has clear charter and audience; `specrew profile list` makes activation state visible.
2. **Component proposals (028, 091, 093, 095) drift if they ship before this umbrella** — they may inadvertently assume mandatory-proposals semantics. *Mitigation*: this proposal ships *first* (or alongside the earliest component); other component proposals reference it; mass-edit if drift is detected.
3. **Specrew self-migration regression** — declaring the profile in Specrew's config could inadvertently change behavior. *Mitigation*: regression test; rollback plan is one config-line revert.
4. **External-tracker users feel abandoned** — projects on Linear/Jira have no profile available at this proposal's ship. *Mitigation*: explicit Out-of-Scope acknowledgement; queue an `external-tracker` profile proposal in candidate state to signal intent.
5. **CLI-dispatcher conditional logic regresses other commands** — wrong profile-detection logic could fail-closed and break non-proposal commands. *Mitigation*: conditional applies only to `specrew proposal *` subtree; core commands unaffected; integration tests cover non-profile mode.
6. **Profile activation friction** — users who *want* proposals find the init-prompt confusing. *Mitigation*: docs link from prompt explains trade-offs in 3 lines; default-off keeps new users on the simple path.
7. **Documentation drift between activated and non-activated states** — getting-started doc could go stale describing the profile incorrectly. *Mitigation*: composes with Proposal 094 (Documentation Update Discipline) — the docs gate catches this.

## Cross-references

- **Foundation**:
  - [052 Specrew Profile System](052-specrew-profile-system.md) — provides the profile-gating mechanism this proposal uses
- **Components bundled under this profile**:
  - [028 Public Proposals Surface](028-public-proposals-surface.md) — frontmatter schema, validator, auto-transition, INDEX
  - [062 Reciprocal Dependency Metadata + Impact Analysis](062-reciprocal-dependency-metadata-impact-analysis.md) — per-proposal relationship metadata
  - [091 Technology Debt Control](091-tech-debt-control.md) — only the `debt promote` adapter is profile-coupled; rest is profile-neutral
  - [093 Proposal Discussion-Field Discipline](093-proposal-discussion-field-discipline.md) — entirely profile-scoped
  - [095 Proposal Lifecycle State Richness](095-proposal-lifecycle-state-richness.md) — entirely profile-scoped
- **Consumes**:
  - [092 Specrew Dashboard Web App](092-specrew-dashboard-web-app.md) — dashboard's roadmap + decision views adapt to profile state
- **Sibling consideration**:
  - **External-tracker profile** (not yet drafted) — for Pattern A projects using Linear / GitHub Issues / Jira instead of proposals. Should be drafted as a candidate to acknowledge the alternative explicitly.
- **Composes with**:
  - [047 Project Governance Profile](047-project-governance-profile.md) — governance profile can recommend/default-activate this profile per project type

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to user observation that recent component-proposal drafts (091, 093, 095) implicitly assumed proposals are mandatory, contradicting the existing strategic decision (memory `project_proposals_pattern_as_opt_in_profile_2026_05_19`). This proposal provides the explicit umbrella that the components hang under, preserving the opt-in stance while operationalizing it through Proposal 052's profile-system architecture.
