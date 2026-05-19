---
proposal: 059
title: Legacy-State Read-Tolerance + Schema Migration Discipline
status: candidate
phase: phase-2
estimated-sp: 15
discussion: tbd
---

# Legacy-State Read-Tolerance + Schema Migration Discipline

## Why

Specrew persists state across many on-disk files that evolve over time: `.specrew/config.yml`, `.specrew/start-context.json`, `.specrew/roadmap.yml` (per Proposal 057), `.specify/feature.json`, `.specify/extensions/specrew-speckit/extension.yml`, `tasks-progress.yml`, `version-check-cache.json`, the `.squad/identity/now.md` frontmatter, and several validator-summary files. As features ship, these schemas grow. But the *readers* don't always grow defensively.

**Empirical motivation — 2026-05-19 WSL trial:**

Moment20 was initialized at Specrew 0.19.0 (pre-F-020). After upgrading the project to 0.22.0 via `specrew update`, `specrew start` crashed:

```
Get-SpecrewStartContextSessionState: scripts/specrew-start.ps1:396
| The property 'session_state' cannot be found on this object.
```

Root cause: `Get-SpecrewStartContextSessionState` reads `.specrew/start-context.json` and accesses `$context.session_state` via PSCustomObject property dereferencing. Under `Set-StrictMode -Version Latest`, accessing a property that doesn't exist on the object **throws** before the `if ($null -eq …)` guard can short-circuit. The file is structurally valid JSON; it just doesn't have a field that didn't exist in 0.19.0. Hotfix `b97a74b` switched to `ConvertFrom-Json -AsHashtable` + indexer syntax so missing keys return `$null` instead of throwing.

This bug class is broader than one function. The same pattern lurks anywhere Specrew reads JSON or YAML written by an older Specrew. **Every schema field that exists today was added at some point; if older state files in the wild don't have it, the reader needs to tolerate that.**

Related historical incidents from this session:
- **F-022 closeout-helper schema mismatch** (commit `94b44d7`): `Set-FeatureCloseoutIdentityNow` wrote human-readable frontmatter without the `session_state_*` machine fields the stale-state validator required. Same class — readers and writers diverged on schema.
- **Specrew version write-back regression** (also `94b44d7`): `specrew update --spec-kit`/`--squad` was downgrading `specrew_version` from a stale extension.yml pin. Same class — a reader took authority from a file it shouldn't have.

## What

Three coupled disciplines: **(A)** schema versioning on every persisted file, **(B)** a reader-tolerance principle enforced by convention + validator, **(C)** a legacy-state fixture corpus exercised on every PR.

### A. Schema versioning on every persisted file

Add `schema: vN` (or equivalent) as a required first-class field on every Specrew-managed persisted file. Current inventory:

| File | Schema marker today? | Notes |
|---|---|---|
| `.specrew/config.yml` | No | Add `schema: v1` |
| `.specrew/start-context.json` | Implicit via F-020 contract | Promote to explicit `schema` field |
| `.specrew/roadmap.yml` | TBD per Proposal 057 | Design with schema from day 1 |
| `.specify/feature.json` | No | Add `schema: v1` |
| `.specify/extensions/specrew-speckit/extension.yml` | Has `version:` but ambiguous | Distinguish content version from schema version |
| `tasks-progress.yml` | Yes (F-020 added it) | Already a v1 contract; reaffirm |
| `version-check-cache.json` | Yes (`schema: 'v1'`) | Already conforms |
| `.squad/identity/now.md` frontmatter | No | Add `schema: v1` |
| `.specrew/last-validator-summary.json` | No | Add `schema: v1` |

Migration writer: when a reader observes a missing schema field on an old file, it logs `schema-implied-v0` and treats the file as v0 for compatibility-mode reads. Writers always emit the latest version.

### B. Reader-tolerance principle

Codify three rules that govern *every* reader of persisted state:

1. **Hashtable, not PSCustomObject, for parsed state.** Use `ConvertFrom-Json -AsHashtable` and YAML parsers that return hashtables. PSCustomObject property access throws under StrictMode for missing properties; hashtable indexer returns `$null`.

2. **Never throw on missing optional fields.** Required fields are explicitly enumerated per schema-version; everything else is optional and defaults to `$null` / `''` / `@()` as appropriate. The "required" set can grow only with a schema-version bump.

3. **Schema-aware dispatch when behaviors differ across versions.** A reader that needs to handle v0 differently from v1 does so explicitly, with a comment naming the version it's matching.

### C. Legacy-state fixture corpus

Materialize a corpus under `tests/fixtures/legacy-versions/{0.18.0,0.19.0,0.20.0,0.21.0,0.22.0,…}/` that snapshots the on-disk state of a project at each shipped version. Each fixture contains the minimum file set a reader might encounter:

```
tests/fixtures/legacy-versions/0.19.0/
  .specrew/
    config.yml
    start-context.json
    last-validator-summary.json
  .specify/
    feature.json
    extensions/specrew-speckit/extension.yml
  .squad/
    identity/now.md
  tasks-progress.yml   # may or may not exist depending on version
```

Every Specrew reader (`Get-SpecrewStartContextSessionState`, `Get-FeatureJson`, `Get-ConfigMap`, `Get-SpecrewIdentitySessionState`, etc.) is invoked against every fixture in CI. Pass criteria: no throws, no `$null`-reference crashes, return values structurally consistent with the function's declared output contract.

When a new feature bumps a schema:
1. The feature adds a new fixture at the new version (e.g., `0.23.0/`).
2. The feature's spec must include "reader-tolerance audit" as a closeout requirement.
3. CI runs all readers against all fixtures; any regression blocks merge.

### Validator rule

Add a validator rule (gap #11 after Proposal 004's nine gaps closed): every PowerShell function whose name begins with `Get-Specrew*SessionState` or `Get-Specrew*State` or reads from `.specrew/*` / `.specify/*` / `.squad/*` and includes `ConvertFrom-Json` must use the `-AsHashtable` parameter. The exact rule shape is TBD; the principle is "no PSCustomObject-from-JSON in state readers."

## Effort

- **Iteration 1 (~10 SP)**: schema markers on all currently-persisted files; reader audit + hashtable migration of identified PSCustomObject readers; fixture corpus for shipped versions 0.19.0 → 0.22.0.
- **Iteration 2 (~5 SP)**: validator rule for reader patterns; closeout-template update so future features add their fixture; documentation in `docs/data-contracts.md` (new file).

**Total: ~15 SP, two iterations.**

## Phase placement

**Phase 2, HIGH-PRIORITY post-F-022.** Belongs in the same batch as Proposals 030 (Quality Hardening Bundle), 054 (Pre-Merge Lifecycle Gate), 055 (Always-In-Flow Bug-Fix Lifecycle) — all are bug-class-prevention work.

Reasonable sequencing:
- **After** Proposal 035 (Session-State Durability) ships — it defined the most volatile schema. Already shipped as F-020 + F-022.
- **Before** Proposal 057 (Roadmap Spine) — `roadmap.yml` should ship with schema versioning from day 1, not retrofit later.
- **Before** Proposal 010 (Multi-Developer Reconciliation) — multi-developer is where schema-version skew gets worst (different devs on different Specrew versions writing the same files).

## Open questions

1. **YAML schema markers**: `.specrew/config.yml` is YAML. Add a top-level `schema: v1` key? Or piggyback on existing keys? Top-level cleanest.
2. **Migration writer policy**: when a reader observes a v0 file, does it (a) read in compat mode and never write, (b) read in compat mode and silently upgrade on next write, or (c) read in compat mode and emit a one-time "upgrade your state" UX hint? Recommend (b) for opaque caches, (c) for user-visible config files.
3. **Validator rule strictness**: should the rule reject ALL `ConvertFrom-Json` without `-AsHashtable` in scripts under `scripts/`, or only those in state readers? Narrow is safer; broad catches more. Start narrow; widen on Phase 2 retrospective.
4. **Fixture freshness**: when Specrew bumps to 0.23.0, do we *generate* the 0.23.0 fixture by running `specrew init` + a recorded lifecycle, or hand-curate? Generated is more accurate; hand-curated is more deterministic. Recommend generated for releases, hand-curated for edge cases (corrupted files, partial state).
5. **Cross-platform fixture variance**: Linux ext4 vs Windows NTFS produce slightly different file content (line endings, file ordering). Fixtures should normalize before committing — Git's `core.autocrlf` already does this for text, but binary state files would need explicit normalization. Most Specrew state is text; defer this until proven necessary.
6. **Performance**: running every reader against every fixture in CI scales linearly. At ~10 readers × 5 fixtures × 3 OS lanes that's 150 tests. Probably fine; reassess at 20+ fixtures.

## Risks

- **Retrofit churn**: existing readers may have subtle behavioral changes when migrated from PSCustomObject to Hashtable (PSCustomObject treats single-element arrays as scalars in some pipelines; Hashtable doesn't). Audit each migration carefully.
- **False security**: passing the fixture corpus doesn't prove all readers are tolerant — only that they're tolerant against the specific fixtures committed. Composes with Proposal 030 (form-vs-meaning) by tightening what "passes" means.
- **Maintenance overhead**: each release adds a fixture. ~5 minutes per release; trivial.
- **`-AsHashtable` parameter not available in older PowerShell**: requires PS 6+. Specrew already requires PS 7+ (per `Specrew.psd1` `PowerShellVersion = '7.0'`). Not a concern.

## Cross-references

- Composes with [030](030-quality-hardening-bundle.md) (Quality Hardening Bundle, form-vs-meaning) — distinct discipline (schema vs. test integrity) but same goal class.
- Composes with [035](035-session-state-durability.md) (Session-State Durability) — the F-020 work that introduced the schema this proposal generalizes.
- Composes with [042](042-specrew-integration-test-suite.md) (Specrew Integration Test Suite) — the fixture corpus integrates with the headless E2E lifecycle; same CI infrastructure.
- Composes with [054](054-pre-merge-lifecycle-verification-gate.md) (Pre-Merge Lifecycle Verification Gate) — both bug-class-prevention; lifecycle gate catches schema-write divergence, this proposal catches schema-read intolerance.
- Composes with [057](057-roadmap-spine-input-adapter-pattern.md) (Roadmap Spine) — `roadmap.yml` should adopt schema versioning from day 1.
- Composes with [010](010-multi-developer-reconciliation.md) (Multi-Developer Reconciliation) — multi-developer needs schema-version skew handling; this proposal is a precursor.
- Composes with [004](004-validator-hardening.md) (Validator Hardening, shipped F-013) — extends validator-rules surface with reader-tolerance gap #11.
- Sibling of [055](055-always-in-flow-bug-fix-lifecycle.md) (Always-In-Flow + Bug-Fix Lifecycle) — bug-fix-repair slice type would route schema-migration repairs here.

## Status history

- 2026-05-19: candidate captured after WSL trial surfaced legacy-state crash class. Hotfix `b97a74b` addressed the immediate `start-context.json` crash; this proposal generalizes the discipline.
