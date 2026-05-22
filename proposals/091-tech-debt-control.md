---
proposal: 091
title: Technology Debt Control (Ledger, Aging, Repayment Pathways, Awareness)
status: candidate
phase: phase-2
estimated-sp: 17-22
discussion: tbd
---

# Technology Debt Control (Ledger, Aging, Repayment Pathways, Awareness)

## Why

Technology debt accumulates continuously across every project: refactor opportunities surfaced mid-feature, dependency versions that drift behind, logging and observability gaps spotted in incidents, external documentation that goes stale, SDLC friction that costs minutes per cycle, build-time regressions that compound silently. Specrew currently has **no first-class mechanism** to capture, age, prioritize, or systematically repay this debt. The consequences observed so far:

- Debt items mentioned in retros (e.g., "we should rename Squad → Crew everywhere", "mirror parity is painful", "validator is slow") are not durably tracked. They surface in conversation, then evaporate until they re-surface as the same retro item iterations later.
- Build-time has grown — F-034 brought a ~127× speedup *because* the regression had been silently accumulating since validator-introduction. No telemetry caught it; user pain caught it.
- PR-review findings that flag debt-class issues (Copilot says "this should be extracted", "this dependency is outdated") are addressed if relevant to the PR, otherwise lost.
- Documentation drift is invisible: README, methodology site, and inline charters age at a different rate than the code, and no signal flags the divergence.
- No agent or user has line-of-sight on "how much debt do we owe right now, and is it growing?" — the question is unanswerable today.

User-stated motivation (2026-05-22):

> "Technology Debt is something that happens all the time and we need to keep it low. It is refactoring, updating packages, fixing logging and traceability, external documentations, enhancing the performance of the SDLC and the build time. … I want to raise the awareness of both the agents and the human user and I want to control the debt and not to raise it."

The intent is **not** zero debt (impossible and not desirable — some debt is rational deferral). The intent is **measurable, controlled debt with explicit repayment pathways**, so debt level is a knob the team turns deliberately rather than a drift that surprises them.

## What (5 Pillars)

### Pillar 1 — Debt Ledger Schema + File

A structured `.specrew/tech-debt.md` ledger is the source of truth. Format: front-matter index + per-entry sections. Each entry has:

| Field | Purpose |
|---|---|
| `id` | Stable ID (`debt-001`, `debt-002`, …) for cross-reference |
| `title` | One-line description |
| `type` | `refactor` / `dependency` / `docs` / `observability` / `performance` / `test-coverage` / `build-tool` / `security` / `sdlc` |
| `severity` | `low` / `medium` / `high` / `critical` |
| `priority` | `p3` / `p2` / `p1` / `p0` (separate from severity — severity is "how bad if untouched", priority is "how soon to act") |
| `effort-sp` | Repayment estimate in story points |
| `files` | List of affected file paths (used by Boy-Scout integration) |
| `found-at` | ISO timestamp of first discovery |
| `found-by` | `human` / `agent-<name>` / `auto-detector-<name>` / `pr-review` / `retro-<feature>-<iter>` |
| `escalated-at` | ISO timestamp of most recent severity/priority bump (null if never) |
| `escalation-reason` | Free text on what triggered the bump |
| `status` | `open` / `scheduled` / `in-progress` / `closed` / `wont-fix` |
| `scheduled-for` | Feature ID or iteration ID if status=scheduled (e.g., `F-042-iter-001` or "next iteration") |
| `closed-at` | ISO timestamp of closure (null if open) |
| `closed-by` | Commit hash or PR ref that closed it |
| `related` | Cross-references to proposals, FRs, other debt entries |
| `notes` | Free-form context |

The file is human-readable (markdown), machine-parseable (via the structured front-matter blocks per entry), and lives next to `roadmap.yml`, `constitution.md`, and other governance files.

A validator rule (`validate-governance.ps1`) checks that:

- Every entry has all required fields
- IDs are unique and monotonically increasing
- Closed entries have non-null `closed-at` + `closed-by`
- File paths in `files` field exist (or entry status is `closed`/`wont-fix`)

### Pillar 2 — Collection Mechanisms

Debt enters the ledger through **five** channels:

**2a. Retrospective ingestion** (primary, human-led)

The retro template gains a `## Tech Debt` section. The Retro Facilitator surfaces debt-class observations from the iteration. Each observation becomes either:

- A new debt entry (Retro Facilitator drafts it with the user)
- A bump to an existing entry's severity/priority + escalation event
- A `closed` resolution if the iteration repaid debt

**2b. Manual entry** (anywhere, human or agent)

`specrew debt add --type=refactor --severity=medium --files=path/to/file.ps1 --title="…"` creates an entry. Any agent or the user can invoke this when debt is spotted mid-flow. Inline shorthand is acceptable (Spec Steward can record a TODO during planning if user agrees).

**2c. Auto-detectors** (scheduled or on-demand)

A small initial set, each lightweight + opt-in via governance profile (composes with Proposal 047):

| Detector | Signal | Records as |
|---|---|---|
| `todo-harvest` | New `TODO/FIXME/HACK` comments in committed code | `type=refactor`, `severity=low` (auto-bump on age) |
| `dep-staleness` | Outdated package versions (npm/pip/dotnet/PSGallery) | `type=dependency`, severity by CVE/major-version delta |
| `doc-staleness` | `docs/` or `README.md` mtime older than touched code mtime by >30 days | `type=docs`, `severity=low` |
| `file-churn` | File modified ≥5 times in last 3 iterations with no refactor commit | `type=refactor`, `severity=medium` |
| `build-time-regression` | Validator/test wall-time grows >20% iteration-over-iteration | `type=performance`, `severity=high` |
| `test-coverage-gap` | New code added without corresponding test file | `type=test-coverage`, `severity=medium` |

Detectors run as part of validator pipeline (composes with Proposal 086 perf bundle) and emit non-fatal warnings + auto-create debt entries (deduplicated by file + type).

**2d. PR-review surfacing** (composes with Proposal 089)

When a reviewer (Copilot, human, or future agent reviewer) leaves a comment that matches debt-class heuristics ("this should be refactored", "this dependency is outdated", "missing logging", "no test for this"), the comment is offered to the user as a candidate debt entry at PR-review-integration time. User confirms inline → entry is created with `found-by=pr-review` + PR link in `related`.

**2e. Build-time telemetry stream** (sub-pillar — user explicitly called this out)

`.specrew/.cache/build-time-history.jsonl` records per-boundary timings for validator, lint, tests, total iteration wall-clock. A small renderer (`specrew debt build-time`) shows trend over last N iterations as a sparkline. The `build-time-regression` detector consumes this stream.

### Pillar 3 — Aging, Escalation, and Closure

**Aging rules** (auto-applied at iteration-closeout):

- Entry open > 3 iterations → severity bumped one notch (low→medium, medium→high) unless `wont-fix`
- Entry cited in retro twice (across iterations) → priority bumped one notch
- Entry on a file touched ≥3 times without repayment → priority bumped one notch

Each bump writes an `escalated-at` + `escalation-reason` event so history is auditable.

**Decay rules** (prevents ledger rot):

- Entry open > 6 iterations → flagged for "still relevant?" review at retro (file may be gone or rewritten)
- Entry whose `files` paths no longer exist → auto-flagged for review (likely auto-closeable)
- Entry not surfaced in any retro for 10 iterations → moved to `dormant` sub-status (still in ledger, but excluded from active dashboard)

**Closure rules** (prevents form-without-meaning closure):

- Status transition to `closed` requires `closed-by` (commit hash or PR ref)
- Validator verifies the commit/PR exists and touches the entry's listed files
- Retro Facilitator confirms closure aligns with retro evidence

### Pillar 4 — Repayment Pathways (Three Modes)

**Mode A — Boy-Scout integration** (primary, opportunistic)

At plan-boundary, the Planner consults `.specrew/tech-debt.md` filtered by `files` intersection with the iteration plan's touched files. If matches exist, the Planner surfaces them in the plan-approval handoff:

> The iteration plan touches the following files with open debt:
>
> - `extensions/specrew-speckit/scripts/shared-governance.ps1` — debt-014 (refactor: extract path-resolution helpers, ~2 SP, medium severity)
> - `extensions/specrew-speckit/scripts/validate-governance.ps1` — debt-021 (test-coverage: rule 47 untested, ~1 SP, low severity)
>
> Extend iteration by ~3 SP to repay these? `[y/n/select]`

User selects which (if any) to absorb. Selected items become tasks in the iteration tasks.md with `[debt-014]` provenance tags. Closeout marks the debt entries `closed` with the iteration's merge commit as `closed-by`.

**Mode B — Dedicated debt-fix slice** (small/medium debt, between features)

Composes with Proposal 055 (slice-type catalog) and Proposal 067 (small-fix slice). A new `debt-fix` slice type is introduced:

- Eligibility: 1-3 debt entries, ≤5 SP combined, no architectural change
- Lifecycle: chore-shaped (no spec/plan, just tasks + closeout)
- Required artifacts: code + tests if test-coverage debt + CHANGELOG entry + ledger close-out
- Can be batched: "Repay all `low` severity docs debt" as a single slice

**Mode C — Roadmap promotion** (large debt)

Debt entry with `effort-sp ≥ 10` OR `severity=critical` is a candidate for promotion. `specrew debt promote <id>` routes per **project profile state** (see Proposal 096):

- **If `proposal-driven-design` profile is active** (Specrew's own repo + projects that opt in): drafts a candidate proposal in `proposals/` pre-filled from the entry, marks debt as `scheduled-for=<proposal-NNN>`. When the proposal ships as a feature, debt closes automatically via the proposal's `shipped-as` link.
- **If the profile is not active** (default for downstream projects): writes the entry as a planned-item row in `.specrew/roadmap.yml` with `source=debt-promotion-<id>` provenance, marks debt as `scheduled-for=<roadmap-slug>`. When the roadmap item ships as a feature, debt closes the same way.

Either way, the promotion preserves audit trail; the destination differs by profile. This composes with Proposal 033 (governance CLI surface) — `debt promote` is a sibling of `propose` (when profile-active) and `feature`.

**Budget mechanism** (soft warning, not hard gate):

- Per-iteration target: net-zero or net-negative debt SP (entries closed ≥ entries opened, weighted by SP)
- If total open debt SP grows for 3 consecutive iterations, the retro template surfaces a mandatory "Debt Growth Review" section. User decides whether next iteration must include a debt-fix slice.
- No hard gate initially — voluntary culture-first, gate can be added later if needed.

### Pillar 5 — Visibility (Dashboard, Retro, Agent Charters)

**Dashboard section** (composes with Proposal 009 velocity dashboard):

```text
TECH DEBT
Total open: 27 entries, 84 SP estimated
Trend (last 3 iters): ↗ +12 SP (growing) — review required at next retro
By type: refactor 11 | dependency 4 | docs 6 | perf 3 | test-cov 3
Top 3 by priority/age:
  ⚠ debt-007 (p0, 47 days, high) — auth-middleware refactor (Proposal 092 candidate)
  ⚠ debt-014 (p1, 32 days, medium) — extract path-resolution helpers
  ⚠ debt-021 (p1, 18 days, medium) — rule 47 test coverage gap
Recent closures (last iter): debt-003, debt-009, debt-018 (net -8 SP)
```

Dashboard tone: actionable, not alarmist. Trend arrow uses ↗ (growing) / → (stable) / ↘ (shrinking).

**Retro template addition**:

A required `## Tech Debt` section in every retro:

- **New entries added this iteration**: list with ids + SP
- **Entries closed this iteration**: list with ids + SP
- **Net change**: + or − SP
- **Trend over last 3 iterations**: growing / stable / shrinking
- **Aging concerns**: entries ≥ 5 iterations old
- **Next iteration recommendation**: continue as-is / absorb debt via Boy-Scout / schedule debt-fix slice / promote a large entry to proposal

The Retro Facilitator charter is updated to own this section.

**Agent charter integration**:

- **Spec Steward** — at clarify, consults debt entries on files referenced by the spec. If significant debt overlaps with new scope, raises it to the user.
- **Planner** — at plan, runs the Boy-Scout query (Mode A). Surfaces matches in handoff.
- **Implementer** — at execute, sees debt tags on tasks (`[debt-014]`) and includes them in commit messages for traceability.
- **Reviewer** — at review, checks whether PR introduces *new* debt (e.g., new TODOs, untested code paths) and offers candidate entries.
- **Retro Facilitator** — owns the retro debt section and the dashboard trend.

### Self-applied seeding (proposed initial entries)

When this proposal ships, the ledger is seeded with the dozen-ish debt items currently visible across the project. This eats own dog food and gives the ledger immediate value rather than starting empty. Candidate seed entries (subject to user confirmation at clarify):

| Title | Type | Estimated SP |
|---|---|---|
| Markdown lint cleanup (~1,565 violations) — Proposal 034 | refactor | 12 |
| "Squad" → "Crew" rename drift across proposals | docs | 5 |
| Mirror parity between `.specify/` and `extensions/` is manually maintained | sdlc | 8 |
| Proposal 076 reserved for "concurrent multi-host execution" — not drafted | docs | 2 |
| Validator scoping chore expanded but not yet shipped | performance | 8 |
| Slash-command path/naming mismatch (F-021 work) — Proposal 064 candidate | refactor | 7 |
| `Specrew.psd1` version-consistency validator chore — not yet shipped | sdlc | 3 |

This list is illustrative — final seeding happens at clarify time.

## Functional Requirements (high-level for candidate phase)

- **FR-001**: `.specrew/tech-debt.md` ledger file with structured per-entry format
- **FR-002**: Validator rule for ledger integrity (required fields, unique IDs, closure evidence)
- **FR-003**: `specrew debt add | list | show | close | promote | bump | reopen` CLI surface
- **FR-004**: Retro template `## Tech Debt` section (new entries, closures, net change, trend)
- **FR-005**: Dashboard `TECH DEBT` section (totals, trend, top-priority, recent closures)
- **FR-006**: Boy-Scout planner integration (debt query intersected with iteration files at plan boundary)
- **FR-007**: Aging auto-bump rules at iteration-closeout (severity/priority escalation with audit trail)
- **FR-008**: Decay rules (stale-entry flagging, missing-file detection)
- **FR-009**: Auto-detector framework with initial detectors: `todo-harvest`, `dep-staleness`, `doc-staleness`, `file-churn`, `build-time-regression`, `test-coverage-gap`
- **FR-010**: Build-time telemetry stream (`.specrew/.cache/build-time-history.jsonl`) + `specrew debt build-time` renderer
- **FR-011**: PR-review debt-class detection (composes with Proposal 089)
- **FR-012**: Debt-fix slice type (composes with Proposal 055/067)
- **FR-013**: Roadmap promotion command + auto-link on proposal ship
- **FR-014**: Soft budget mechanism (net-zero target, retro mandatory review on 3-iteration growth)
- **FR-015**: Agent charter updates (Spec Steward / Planner / Reviewer / Retro Facilitator)
- **FR-016**: Self-applied seeding at ship time

## Out of scope

- Hard gates that block iteration progress on debt level (deferred to a possible follow-up; voluntary culture first)
- Sophisticated code-smell analyzers (cyclomatic complexity, duplication detection, etc.) — initial detectors are simple/cheap; can grow later
- Cross-project debt aggregation across multiple Specrew-managed repos (single repo scope first)
- Machine-learning-based debt classification (rule-based detectors only)
- External integrations (Linear, Jira, GitHub Projects) — internal-ledger first, integrations later as adapters
- A separate UI beyond the dashboard and CLI surface

## Effort

- **Iteration 1 (~10 SP)**: Pillars 1+2+3 — ledger schema + validator rule + retro ingestion + manual CLI (`add`/`list`/`show`/`close`) + aging rules + closure evidence. Two simplest detectors only: `todo-harvest` + `doc-staleness`.
- **Iteration 2 (~7-10 SP)**: Pillars 4+5 — Boy-Scout planner integration + debt-fix slice type + dashboard section + retro template update + remaining detectors (`dep-staleness`, `file-churn`, `build-time-regression`, `test-coverage-gap`) + build-time telemetry stream + roadmap promotion (`specrew debt promote`) + agent charter updates + self-applied seeding.
- **Total**: ~17-22 SP

## Phase placement

**Phase 2 — Tier 1 methodology**. Tech debt control is core methodology, not operational tooling. It belongs in the methodology-first tier that should ship before external adoption (~late summer 2026). Sequencing: queue after the v0.24.3 performance bundle wraps (F-035/036/037/038) — composes naturally with Proposal 086's pillars 2+5 (rule-applicability cache + repetition detector are themselves debt-style mechanisms) and Proposal 089 (PR-review integration, which this proposal extends to debt surfacing). Sequencing relative to Proposal 030 (Quality Hardening Bundle) and Proposal 047 (Governance Profile) needs clarify-time decision.

## Open questions

1. **Ledger format**: pure markdown with structured sections, or YAML front-matter blocks per entry, or a separate `tech-debt.yml`? Markdown is human-friendly; YAML is machine-friendly. Recommendation: markdown with per-entry YAML front-matter (best of both, matches existing iteration/spec patterns).
2. **Auto-detector cadence**: every validator run (cheap, frequent) vs only at iteration-closeout (less noise) vs nightly truth check (composes with Proposal 087)? Recommendation: cheap detectors per validator run; heavy ones (file-churn, build-time-regression) at iteration-closeout.
3. **Severity vs priority — both or merge?** Some teams find both redundant. Recommendation: keep both, since "how bad if untouched" (severity) and "how soon to act" (priority) are legitimately different axes — but allow profile to disable one if user prefers.
4. **Boy-Scout user prompt — autopilot-safe?** If user is running `--autonomous`, does the planner auto-include matched debt or skip the prompt? Recommendation: autonomous mode skips the prompt (no debt absorbed without explicit confirmation), reports skipped opportunities in handoff.
5. **Should the validator hard-fail on ledger schema errors, or soft-warn?** Recommendation: hard-fail on missing required fields, soft-warn on aging/decay (which are heuristics, not violations).
6. **How does this compose with NFR Governance (Proposal 008)?** NFR breaches should auto-create debt entries with `type=performance` or `type=security`. Recommendation: define adapter at FR-011 once 008 is drafted concretely.
7. **Should the dashboard show debt as a *percentage* of total project SP shipped, or absolute SP?** Recommendation: both — absolute for action, percentage for trend interpretation.
8. **What about debt found in *other* projects using Specrew (downstream)?** Initial implementation is per-project; cross-project aggregation is out of scope but the schema should not preclude it.
9. **Closure-evidence verification — how strict?** Requiring the commit to touch the entry's files is mechanical; requiring meaningful resolution is form-vs-meaning territory. Recommendation: mechanical check + manual reviewer confirmation, matching the pattern in Proposal 073 (Review Evidence Integrity).
10. **Does this propose merge into a broader "Methodology Self-Improvement" bundle** alongside Proposal 017 (Learning Loop Closure)? Recommendation: keep separate — Learning Loop closes the retro→corpus→enforcement loop for *behavior*; this proposal closes the same loop for *code/system debt*. Sibling, not duplicate.

## Risks

1. **Ledger rot** — entries accumulate without being addressed; the file becomes wallpaper. *Mitigation*: aging rules + decay/dormancy + soft budget force periodic engagement; dashboard surfaces growth trend.
2. **Detector false positives** — `todo-harvest` flags legitimate notes; `doc-staleness` flags intentionally-frozen docs. *Mitigation*: every detector has an opt-out marker (`<!-- specrew:debt-ignore -->`); governance profile controls which detectors run.
3. **Over-engineering at MVP** — too many fields, too many detectors, too much CLI surface. *Mitigation*: Iteration 1 ships only essential schema + retro ingestion + manual CLI + 2 detectors; iteration 2 layers on the rest.
4. **Boy-Scout fatigue** — every iteration prompts for debt absorption, user habituates and dismisses. *Mitigation*: cap prompt to top 3 entries by priority; suppress entries the user has declined twice (unless escalation event); allow `--no-debt-prompt` per-iteration override.
5. **Debt-fix slice abuse** — every chore gets relabeled as debt-fix to skip lifecycle. *Mitigation*: debt-fix slice requires an existing ledger entry referenced in tasks.md provenance tag; can't be created post-hoc.
6. **Promotion floods proposals/** — every medium debt becomes a candidate proposal, swamping INDEX. *Mitigation*: promotion thresholds (≥10 SP or critical), and promoted debt always starts as candidate (lowest visibility).
7. **Self-applied seeding controversy** — initial seed list includes opinions about what is debt vs intentional design. *Mitigation*: seed at clarify with user confirmation per entry; no silent seeding.
8. **Build-time telemetry storage growth** — JSONL grows unbounded. *Mitigation*: rotate at 1,000 entries (~3-6 months); archive older to `.specrew/.cache/archive/`.

## Profile coupling

This proposal is **mostly profile-neutral** — the ledger, detection, aging, repayment Modes A+B, dashboard section, retro integration, and agent charter awareness all work for any Specrew project regardless of profile.

**One coupling point**: Mode C (Roadmap promotion). The `specrew debt promote <id>` destination depends on whether the `proposal-driven-design` profile (Proposal 096) is active:

- Active → debt promotes to a candidate proposal in `proposals/`
- Inactive → debt promotes to a planned-item row in `.specrew/roadmap.yml`

The promotion command itself works in both modes; only the destination differs. No other part of this proposal requires the profile.

## Cross-references

- **Composes with** (mutually reinforcing):
  - [008 NFR Governance](008-nfr-governance.md) — NFR breaches auto-record as debt entries; this proposal provides the ledger 008 writes into
  - [017 Learning Loop Closure](017-learning-loop-closure.md) — sibling for code-debt that Learning Loop is for behavior-debt; they share retro→ledger→enforcement shape
  - [028 Lifecycle Hardening](028-lifecycle-hardening.md) / [033 Specrew Governance CLI](033-specrew-governance-cli.md) — `specrew debt` is a sibling CLI surface
  - [047 Project Governance Profile](047-project-governance-profile.md) — profile selects which auto-detectors run + which severities require retro action
  - [055 Slice-Type Catalog](055-post-ship-bugfix-lifecycle.md) — adds `debt-fix` slice type
  - [067 Small-Fix Slice](067-small-fix-slice-type.md) — supplies the lightweight lifecycle pattern that debt-fix inherits
  - [086 Validation Pipeline Performance Bundle](086-validation-pipeline-performance-bundle.md) — pillars 2+5 (rule-applicability cache + repetition detector) are themselves debt-prevention mechanisms; build-time-history stream shares the telemetry shape
  - [089 PR Review Integration](089-pr-review-integration-address-pr-review-gate.md) — debt-class review comments surfaced as candidate entries
  - [030 Quality Hardening Bundle](030-quality-hardening-bundle.md) — closure-evidence verification follows the form-vs-meaning pattern from 030/073
  - [096 Proposal-Driven Design Profile](096-proposal-driven-design-profile.md) — supplies the profile-gating for Mode C's promote destination; rest of this proposal is profile-neutral
- **Related precedents**:
  - The retro→corpus→enforcement pipeline introduced by Rule 15 (Proposal 006 / F-015 Public-Readiness Pass) is the methodological precedent: debt control closes the same loop one layer down.
  - Proposal 034 (Markdown Lint Cleanup) is itself a debt-fix slice that would be ledger entry #1 if this proposal had existed.

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to user direction on technology debt control. Awaiting clarify-time decisions on open questions before promotion to `draft`.
