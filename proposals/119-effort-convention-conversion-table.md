---
proposal: 119
title: Effort Convention Conversion Table + Helper (Methodology-Level Unification of T-Shirt Sizing and Story Points)
status: candidate
priority: high
phase: phase-2
estimated-sp: 8-12
discussion: 2026-05-25 F-045 iter-001 blocked by validator FAIL "summed task effort '0'" — root-cause traced to dual effort conventions coexisting without a forcing function (Spec-Kit `/speckit.tasks` emits S/M letters; Specrew iteration plan declares `story_points`; validator enforces numeric-only via `[double]::TryParse`). User direction "Yes, draft this proposal, give it high priority" — methodology gap recurs on every new iteration in every project until closed.
depends-on:
  - 067  # Small-Fix Slice Type — Slice 1 below ships as a small-fix slice
composes-with:
  - 009  # Velocity Dashboard — requires numeric SP; consumes the helper this proposal ships
  - 030  # Quality Hardening Bundle (Form-vs-Meaning Verification) — this is a textbook form-vs-meaning bug class
  - 047  # Project Governance Profile — per-project effort-convention override is a profile concern
  - 052  # Specrew Profile System — composes with the override mechanism
blocks: []
---

# Effort Convention Conversion Table + Helper (Methodology-Level Unification of T-Shirt Sizing and Story Points)

## Why

**HIGH PRIORITY — recurring methodology gap blocking active feature work.**

Specrew's toolchain runs **two competing effort vocabularies side-by-side** with no documented conversion bridge that any of the consumer code reads. The mismatch produces a textbook form-vs-meaning bug class: the form (validator parse) catches the mismatch correctly but the meaning (what effort the iteration actually contains) is silently lost. Every new iteration plan today hits this gap; every downstream project that adopts Specrew will hit it on their first patch slice; the cost compounds.

### Empirical motivation — F-045 iter-001 (2026-05-25)

Running F-045 (v0.27.1 bug-fix bundle):

1. Spec-Kit's `/speckit.tasks` generated `specs/045-v0271-bugfix-bundle/tasks.md` with the canonical Spec-Kit convention: `[effort: S]`, `[effort: M]` annotations on each task.
2. Squad's Planner populated `specs/045-v0271-bugfix-bundle/iterations/001/plan.md` task-table Effort column by **copying S/M letters verbatim** from the source tasks document.
3. The iteration plan's Effort Model section (line 74 of the template) declares the unit as `story_points` — implying numeric. The conversion `S=1, M=2` is documented as a prose note (line 101 of the template) but only readable by humans.
4. `validate-governance.ps1` lines 3155-3160 (and mirror at `.specify/extensions/specrew-speckit/scripts/`) parses Effort with `[double]::TryParse([string]$task.Effort, ...)` — numeric only. Lines 3188-3205 repeat the same assumption in overcommit logic. Neither code path reads the prose note.
5. Every S/M parse returned 0 (`TryParse` fails on letters → fallback to 0). Summed effort: 0. Validator FAIL: `Capacity used value '20' does not match summed task effort '0' for planning status`.

The block was diagnosed only because the user (Alon) traced the validator code directly; the agent's initial hypothesis ("non-consecutive task ID parsing quirk") was wrong because the symptom "0 sum" doesn't match the hypothesis "partial sum from sequential parser stopping at a gap." Squad proposed two mitigations (add deferred T002 placeholder, OR renumber to T001-T014) that **both addressed the wrong root cause** — both left S/M in the Effort column.

The minimal unblock for F-045 iter-001 is mechanical: change S/M cells to 1/2 numeric in that single iteration's plan. That's a workaround. The recurring methodology gap remains. This proposal closes it.

### Layered failure analysis

| Layer | Convention | Reads conversion table? | Failure mode |
|---|---|---|---|
| Spec-Kit `/speckit.tasks` (upstream) | t-shirt sizing (S/M/L letters in tasks.md) | n/a (it emits the convention) | Specrew can't influence upstream output |
| Squad Planner (populating iter plan) | preserves source label verbatim | no — charter doesn't document the conversion responsibility | passes S/M to iter plan unchanged |
| Iteration plan template (Effort Model) | declares unit as `story_points` (numeric) | no — declaration is decorative | unit mismatch with copied content |
| Validator capacity summation | numeric-only via `TryParse` | no — no S/M mapping in that code path | every letter parses as 0 → sum = 0 |
| Validator overcommit logic | numeric-only (same code) | no | same |
| Velocity dashboard renderer | reads numeric SP from iteration history | n/a (downstream of validator) | propagates whatever the validator stored |
| Closeout-dashboard generator | numeric SP variance | n/a (downstream) | same |
| Retro variance calculation | numeric SP delta | n/a (downstream) | same |

**Eight consumer surfaces; zero shared conversion source.** The convention exists only in a prose note in one template.

### Why "high priority"

1. **Active block**: F-045 iter-001 hit this 2026-05-25; workaround applied but the gap recurs in iter-002 unless fixed.
2. **Recurring pattern**: Specrew tested empirically across several projects (memory: WSL trial, gym-test, calc-v2, tip-calc-v2 dogfooding) — every project that runs `/speckit.tasks` followed by `validate-governance.ps1` is exposed.
3. **Methodology-not-mechanical fix**: This isn't a one-off validator bug — it's an architectural gap between toolchain layers. The validator-only patch (the small-fix slice motivated by F-045) treats the symptom; this proposal closes the methodology gap so velocity math, dashboard rendering, and capacity discipline all share one effort source-of-truth.
4. **Downstream public adoption window approaches** (~Sept 2026 per memory's methodology-first prioritization). Every external tester running their first patch slice will hit this; resolving it before adoption removes a sharp first-touch friction.

### User direction (2026-05-25)

> "The plan had to be in Story Point to calculate velocity. We can have a conversion table and the code that calculate story point can use it."

And:

> "Yes, draft this proposal, give it high priority"

## What

Three independently shippable slices delivering a complete methodology-level unification.

### Slice 1 — Conversion data + helper + validator integration (small-fix-slice-shaped, ~4-5 SP)

**Composes with [Proposal 067 — Small-Fix Slice Type](file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md)**. The validator fix the user identified as the immediate F-045 unblock follow-up IS this slice. Lands first; unblocks F-045 iter-002 and all future iterations.

**New file** — `extensions/specrew-speckit/data/effort-convention.yml`:

```yaml
# Specrew effort-convention conversion table.
# Canonical unit is `story_points` (numeric). T-shirt-sizing letters are an
# accepted input form that gets normalized to numeric at parse time.
# Projects may override this file via .specrew/effort-convention.yml.

schema_version: v1

# Default mapping. Adjust per-project if your team uses different bucketing
# (e.g., Fibonacci variants: { XS: 1, S: 2, M: 3, L: 5, XL: 8 }).
mapping:
  XS: 0.5
  S: 1
  M: 2
  L: 3
  XL: 5

# Numeric input is accepted directly (e.g., 1.5 SP for fractional work).
# Anything not in the mapping AND not a parseable number is a hard error.
allow_numeric_passthrough: true

# When the validator encounters an unrecognized symbol, fail-loud (true)
# or skip-with-warning (false). Fail-loud is the safe default.
strict_unknown_symbol: true
```

**New helper** — `scripts/internal/effort-convention.ps1`:

```powershell
function Get-EffortConventionTable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )
    # Resolution order:
    #   1. .specrew/effort-convention.yml (project override)
    #   2. <module-root>/extensions/specrew-speckit/data/effort-convention.yml (default)
    # Returns parsed hashtable with .mapping, .allow_numeric_passthrough, .strict_unknown_symbol
}

function ConvertTo-NumericStoryPoints {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EffortValue,

        [Parameter(Mandatory = $true)]
        [hashtable]$ConventionTable
    )
    # Returns numeric SP (decimal) on success.
    # Behavior:
    #   - If $EffortValue is numeric (`TryParse` succeeds) AND allow_numeric_passthrough: return numeric value.
    #   - If $EffortValue matches a key in $ConventionTable.mapping: return the mapped value.
    #   - Otherwise: throw if strict_unknown_symbol, else return 0 with a Write-Warning.
}
```

**Validator integration** — modify `validate-governance.ps1` capacity summation (lines 3155-3160) AND overcommit logic (lines 3188-3205) to call `ConvertTo-NumericStoryPoints` instead of `[double]::TryParse` inline. Mirror the same change to `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`.

**Tests** — `tests/integration/effort-convention.tests.ps1`:

- Numeric input passthrough (1, 2, 1.5)
- S/M/L mapping
- Custom mapping via project override
- Unknown symbol with strict mode → throw
- Unknown symbol with lenient mode → 0 + warning
- Mirror parity (both copies of validate-governance.ps1 produce identical sums for the same fixture)

### Slice 2 — Planner charter + iteration template + Spec-Kit task-handoff convention (~3-4 SP)

The fix in Slice 1 makes the validator tolerant. Slice 2 makes the **upstream layers** explicit about which form to use where.

**Planner charter update** — `extensions/specrew-speckit/squad-templates/agents/planner/charter.md` (and mirror at `.specify/extensions/specrew-speckit/squad-templates/agents/planner/charter.md`):

Add a section "Effort-convention handoff discipline":

> When populating the iteration plan's Tasks table from Spec-Kit's tasks.md source:
>
> - The iteration plan's Effort Model section declares the canonical unit (typically `story_points`).
> - Spec-Kit's tasks.md may use t-shirt-sizing letters (S/M/L) as input shorthand.
> - The Planner MUST honor the iteration plan's declared unit. Either:
>   - Translate t-shirt-sizing to the declared unit at population time using the project's effort-convention table (`extensions/specrew-speckit/data/effort-convention.yml`, optionally overridden by `.specrew/effort-convention.yml`), OR
>   - Pass t-shirt-sizing through untranslated AND rely on the validator's conversion (acceptable but produces less-readable iteration ledgers).
> - The iteration plan's Tasks table is the canonical capacity ledger; downstream consumers (velocity dashboard, closeout-dashboard, retro variance) all key off it.

**Iteration plan template update** — `extensions/specrew-speckit/squad-templates/iterations/plan.md` (and mirror):

Replace the bare prose note "Effort conversion for capacity math: S=1 story point, M=2 story points" with an inline reference to the canonical table:

```markdown
## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Canonical unit. The Tasks table Effort column MUST contain values resolvable via `effort-convention.yml` — numeric or t-shirt letters (S/M/L/XL). |
| Conversion Source | [effort-convention.yml](file:///<project>/.specrew/effort-convention.yml) (or extension default) | Versioned table. Override per-project via `.specrew/effort-convention.yml`. |
| ... |
```

**Documentation** — new `docs/how-to/effort-conventions.md`:

- Explains the canonical-unit + accepted-input-forms model
- Shows the default mapping table
- Shows how to override per-project (`.specrew/effort-convention.yml`)
- Documents fail-loud-vs-lenient mode
- FAQ: "Why can't I use story-point '3.5' in t-shirt mode?" — explains the strict_unknown_symbol behavior

**README + getting-started touchups** — single-line callouts pointing at `docs/how-to/effort-conventions.md`.

### Slice 3 — Downstream consumer alignment (~2-3 SP)

Once Slice 1's helper exists, every other place that sums or averages effort should also call it (instead of re-implementing the parse). One-pass refactor:

- `scripts/specrew-where.ps1` velocity-section renderer — call `ConvertTo-NumericStoryPoints` for any historical iteration plan that uses t-shirt sizing (back-compat with older plans).
- `scripts/internal/sync-boundary-state.ps1` closeout-dashboard generator (per Proposal 046 / F-040 fix-bundle) — same.
- `extensions/specrew-speckit/squad-templates/skills/specrew-capacity-planning/SKILL.md` — update the skill's prompt content to reference the convention table.
- `extensions/specrew-speckit/squad-templates/skills/specrew-traceability-check/SKILL.md` — same if it references effort.
- Retro variance calculation (wherever it lives — `extensions/specrew-speckit/scripts/run-retro-variance.ps1` or similar) — same.

**Why not Slice 3 inside Slice 1?** Slice 1 unblocks the immediate validator FAIL with minimum risk. Slice 3 is opportunistic alignment that doesn't block correctness — it just makes the codebase consistent. Split keeps the small-fix-shaped slice truly small.

## Architecture

### Resolution order (single source of truth)

```text
1. .specrew/effort-convention.yml                              (project override; optional)
2. <module-root>/extensions/specrew-speckit/data/effort-convention.yml  (shipped default)
```

Cached at module-load time per project; invalidated when either file's mtime changes (same pattern Proposal 086 uses for validator-result memoization).

### Consumer pattern

Every consumer of effort values follows the same shape:

```powershell
$conventionTable = Get-EffortConventionTable -ProjectPath $ProjectPath
foreach ($task in $iterationTasks) {
    $sp = ConvertTo-NumericStoryPoints -EffortValue $task.Effort -ConventionTable $conventionTable
    $totalEffort += $sp
}
```

No consumer parses Effort values directly. The helper is the only code path that touches the mapping table; the table is the only data file that declares the mapping.

### Schema versioning

`schema_version: v1` in the YAML lets the helper detect format drift on future schema changes. v1 → v2 migration would land via a separate small-fix slice; consumers see the new schema transparently because they only call the helper.

## Implementation slices summary

| # | Slice | Type | Files touched | SP | Risk |
|---|---|---|---|---|---|
| 1 | Conversion data + helper + validator + mirror + tests | small-fix slice (Proposal 067) | new YAML, new PS1 helper, validate-governance.ps1 ×2, new test file | 4-5 | Med — touches validator; mirror parity critical |
| 2 | Planner charter + iteration template + docs | small-fix slice | planner charter ×2, iteration plan template ×2, new how-to doc, README/getting-started touch | 3-4 | Low — documentation + prompt content; no runtime change |
| 3 | Downstream consumer alignment (velocity / closeout-dashboard / retro variance / skills) | small-fix slice | ~5-8 files across scripts and skills | 2-3 | Low — opportunistic refactor; helper already verified by Slice 1 tests |

**Total**: 9-12 SP across 3 slices, each independently shippable, no cross-slice blocking after Slice 1 lands.

### Sequencing

1. **Slice 1 ships first** — closes the F-045 gap and unblocks iter-002 + all future iterations.
2. **Slice 2 ships next** — within 1-2 weeks of Slice 1 — establishes the Planner-charter discipline so the convention is visible to humans authoring iteration plans.
3. **Slice 3 ships opportunistically** — when those consumers are touched for other reasons, OR as a single batch refactor if maintainer wants the alignment in one PR.

## Risks

| Risk | Mitigation |
|---|---|
| Existing iteration plans use inconsistent forms (some numeric, some letter, some mixed) | Helper accepts both via `allow_numeric_passthrough: true`. Migration is automatic — nothing breaks. |
| Per-project override (`.specrew/effort-convention.yml`) drifts from team's actual usage | Validator surfaces the resolved table at FAIL time so the message names which mapping it tried |
| Spec-Kit upstream changes the `/speckit.tasks` Effort format | Mapping table is versioned; if upstream introduces a new symbol (e.g., `XXL`), add to the table — no code change |
| Mirror copies (`extensions/` ↔ `.specify/extensions/`) drift after this proposal lands | Existing host-coupling-firewall test (per F-044 work) should catch divergence; add an assertion that both validators import the same helper |
| Helper signature changes after Slice 3 finds an unexpected consumer requirement | `ConvertTo-NumericStoryPoints` is internal — bump the file's schema_version comment if signature changes; no external API contract |
| Fail-loud strict mode breaks an existing project that uses a non-default symbol | Default `strict_unknown_symbol: true` matches "fail fast" Specrew philosophy. Project can opt to `false` via override. CHANGELOG calls out migration path. |
| `0.5` SP fractional values produce weird dashboard averages | Velocity dashboard rounds to one decimal place; documented behavior |
| Memoization (Proposal 086 P1) cache invalidation when `effort-convention.yml` changes | Add the convention file's mtime to the validator's cache-key inputs |

## Composition

- **[067 Small-Fix Slice Type](file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md)** — Slice 1 ships as a small-fix slice per 067's contract (code + tests + CHANGELOG + proposal + INDEX). Slices 2 and 3 are also small-fix-shaped.
- **[009 Velocity Dashboard](file:///C:/Dev/Specrew/proposals/009-velocity-dashboard.md) (shipped as F-017)** — depends on numeric SP for velocity math. Slice 3 makes the velocity renderer consume the helper so back-compat with t-shirt-sizing iteration plans works correctly.
- **[030 Quality Hardening Bundle](file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md)** — this proposal is empirical motivation for 030's form-vs-meaning verification component. Adding 119 to 030's "case studies" appendix is recommended.
- **[047 Project Governance Profile](file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md)** — per-project `.specrew/effort-convention.yml` override is naturally a profile concern; 047's profile system can include effort-convention as a profile attribute.
- **[052 Specrew Profile System](file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md)** — same composition; profile-level effort-convention defaults.
- **[063 Substantive Intake Questioning](file:///C:/Dev/Specrew/proposals/063-substantive-intake-questioning.md)** — F-025 intake interview is a good place to ask "what's your team's effort convention?" once and write the override file.
- **[086 Validation Pipeline Performance Bundle Pillar 1 (Memoization)](file:///C:/Dev/Specrew/proposals/086-validation-pipeline-performance-bundle.md) (shipped as F-034)** — the validator's memoization cache must invalidate when `effort-convention.yml` changes; add the file's mtime to the cache-key inputs in Slice 1.
- **[110 Specrew Update Experience](file:///C:/Dev/Specrew/proposals/110-specrew-update-experience.md)** — when `effort-convention.yml` is migrated to a new schema in the future, Proposal 110's CHANGELOG-driven "what's new" surface naturally announces the migration to users.

## Open questions

1. **Default mapping values**: ship `{XS: 0.5, S: 1, M: 2, L: 3, XL: 5}` as proposed, or use Fibonacci `{S: 2, M: 3, L: 5, XL: 8}` (matches some Agile teams' habit)? Recommendation: ship linear `{S=1, M=2, L=3}` matching the existing prose-note convention in the iteration plan template; let projects override to Fibonacci via `.specrew/effort-convention.yml` if they prefer.
2. **Should `0` be a valid effort?**: zero-effort tasks (documentation, automated checks) are edge cases. Recommendation: accept `0` via numeric passthrough; surface a Write-Warning if a task has 0 effort to nudge planners to confirm intent.
3. **Fractional SP (e.g., 1.5)**: useful for fine-grained work; consistent with the proposed `XS: 0.5`. Recommendation: support throughout (helper, validator, dashboard). Documented as "fractional values round to one decimal place at dashboard render time."
4. **Where should Slice 3's refactor happen — in this proposal, or as part of Proposal 086 Pillar 4 (batched state writes) when those files are touched anyway?**: Recommendation: keep in this proposal as Slice 3 (already-bounded scope). 086 P4's batched-state-writes work is orthogonal and shouldn't bundle.
5. **Should Spec-Kit upstream be nudged to support numeric Effort?**: Per Proposal 058 spirit, Specrew should compose with whatever Spec-Kit emits. The conversion table is Specrew's responsibility. Recommendation: do NOT push for upstream changes; the conversion bridge is the right abstraction.
6. **Migration check for existing iteration plans**: should `specrew where` or a chore validator surface "you have N iteration plans using letter-form Effort; the new helper handles them transparently but consider migrating for consistency"? Recommendation: optional follow-up small-fix; not blocking.

## Out of scope

- **Estimating effort itself** — this proposal handles representation + parsing, NOT the act of choosing an effort value. The Planner / human still picks the number; this proposal just ensures the picked value is honored end-to-end.
- **Multi-unit support** (e.g., hours vs SP vs ideal-days) — iteration plans declare ONE unit; mixing is out of scope. A future proposal can add unit-conversion (`time` ↔ `story_points`) if needed but it's a separate concern.
- **Spec-Kit upstream changes** — see Open Question 5.
- **Retroactive normalization of existing iteration plans** — see Open Question 6. Helper handles them transparently; mass-migration is a separate optional chore.
- **Velocity calculation algorithm changes** — Proposal 009's velocity math is downstream; this proposal only ensures the INPUTS are correctly summed.
- **Per-agent effort overrides** (e.g., "junior implementer's S = senior's M") — interesting future direction but bigger methodology surface; defer.

## Success criteria

- F-045 iter-002 (and all future iterations across all projects) can use either numeric SP, t-shirt letters, or a mix in the Effort column without validator FAIL.
- `validate-governance.ps1` reads `effort-convention.yml` via the new helper; mirror parity preserved.
- Planner charter explicitly documents the convention-handoff discipline.
- Iteration plan template surfaces the conversion-source reference inline (not buried as a prose note).
- `docs/how-to/effort-conventions.md` explains the model + override pattern.
- Project override (`.specrew/effort-convention.yml`) works end-to-end and is honored by every consumer (validator, velocity renderer, closeout-dashboard, retro variance).
- Memoization cache (Proposal 086 P1) invalidates correctly when the convention file changes.
- New integration tests cover: numeric passthrough, letter mapping, custom mapping override, unknown-symbol strict/lenient modes, mirror parity.
- F-045's temporary numeric-in-iter-001 workaround can be reverted to t-shirt letters at iter-001 closeout (or before iter-002 starts) and validate-governance still passes.
