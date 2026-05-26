---
proposal: 132
title: Mirror-Parity Validator Enforcement (F-047 FR-014 Mechanical Backfill)
status: candidate
phase: phase-2
estimated-sp: 2-4
priority-tier: 1
discussion: F-047 FR-014 ("Any change to `extensions/specrew-speckit/scripts/*` MUST be mirrored byte-identical in `.specify/extensions/specrew-speckit/scripts/`") is a prose rule with no mechanical enforcement. 2026-05-26 mirror-parity audit found 4 drifted files (1 extension.yml + 3 scripts) traced to commit `18bfaeab` (F-044 iter-003) which predated FR-014. Fixed in chores `6299fb99` + `948ab40c`. The fix proves the prose-rule layer alone does not catch drift; mechanical SHA256 check is the durable enforcement. Small-fix slice ~2-4 SP; bundle candidate with Proposal 067 small-fix-slice or Proposal 030 Quality Hardening Bundle.
---

# Mirror-Parity Validator Enforcement (F-047 FR-014 Mechanical Backfill)

## Why

F-047 FR-014 (specs/047-bug-bash-trust-hardening/spec.md) mandates:

> "Any change to `extensions/specrew-speckit/scripts/*` MUST be mirrored byte-identical in `.specify/extensions/specrew-speckit/scripts/`."

This rule exists in prose only — Crew agents are told to maintain parity via the implementer charter and the Reviewer verifies via SHA256 spot-checks. **No automated validator rule enforces it.** Reliance on prose discipline is exactly the form-vs-meaning gap that motivated Proposal 030 in the first place — if a commit lands in `extensions/` without mirroring to `.specify/`, no automated layer catches it.

### Empirical motivation (2026-05-26)

A routine version-pin audit during a v0.27.4-beta validation cycle surfaced four drifted files in the `.specify/` mirror:

1. **`.specify/extensions/specrew-speckit/extension.yml`** — pinned at `0.27.3`; source at `0.27.4`. Drift introduced 2026-05-26 in v0.27.4-beta.2 (commit `db5e80d6`) when "bump remaining version manifests" missed the mirror.
2. **`.specify/extensions/specrew-speckit/scripts/run-hardening-gate.ps1`** — missing StrictMode-defensive `[string[]]` coercion at lines 574-582; mirror could fail under StrictMode where source succeeds.
3. **`.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`** — missing 18-line block handling numeric-only feature IDs ("001" → prefix-match `specs/001-*`); functionality the mirror lacked entirely.
4. **`.specify/extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1`** — missing `$null -ne $RequirementScope` strict-null check + `FR-PLACEHOLDER` degradation logic + warning emission.

The 3 scripts trace to commit `18bfaeab` (F-044 iter-003 manual-test repair, 2026-05-22) which touched ONLY `extensions/...` paths without mirror update. **F-047 was authored AFTER this commit and added FR-014 to prevent FUTURE drift — but did not include a backfill mechanism and did not add a mechanical check.** The drift persisted undetected for 4 days until the routine audit found it.

Both fixes shipped as chore commits:

- `6299fb99` — `extension.yml` version bump (single-line)
- `948ab40c` — 3-script byte-identical sync (33 insertions, 7 deletions)

### Why prose-rule-only is insufficient

The pattern is identical to many other "form correct, meaning wrong" gaps Specrew has documented:

- F-013/F-016 boundary discipline was prose-only until Proposal 065 added launch-mode enforcement
- Handoff-block emission was prose-only until Proposal 120 added validator enforcement
- Coordinator-prompt SDLC ownership was prose-only until Proposal 131 was drafted

Mirror parity belongs to the same class. The prose rule exists; the validator does not. Without mechanical enforcement, the rule degrades on:

- Hosts that don't reliably honor coordinator-prompt rules (multi-host expansion territory)
- Sub-agents (Scribe, hot-fix sessions) that bypass the implementer-charter awareness
- Pre-rule commits (the 18bfaeab case — three months elapsed before detection)
- Compaction-degraded sessions where adjacent-discipline awareness drops

### Real-world blast radius

Today's drift was zero-impact for end users — `specrew init` copies `extensions/` → `.specify/extensions/` in downstream projects, so external users always run the source path. But:

- **Dev-tree workflows** that read `.specify/extensions/scripts/...` directly (some validator flows, some test fixtures) get the buggy older code
- **Mirror drift compounds** — once a mirror exists with one stale file, future "rebase from source to mirror" attempts have to reason about whether each diff is intentional, slowing every future fix
- **The next FR-014 violation could be worse** — a fix in `extensions/` for a real bug, missing from `.specify/`, lets the bug recur via the mirror path

The point of mechanical enforcement is to never have to relitigate "is this drift intentional or a missed mirror?"

## What

Single validator rule + one shared helper. Small-fix-slice-sized.

### Pillar 1: SHA256 parity check rule (~1-2 SP)

New validator rule in `extensions/specrew-speckit/scripts/validate-governance.ps1`:

```powershell
function Test-MirrorParity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot
    )

    $sourceScripts = Get-ChildItem -Path (Join-Path $RepoRoot 'extensions/specrew-speckit/scripts') `
        -Filter '*.ps1' -File -ErrorAction SilentlyContinue
    $violations = @()

    foreach ($src in $sourceScripts) {
        $relPath = $src.Name
        $mirrorPath = Join-Path $RepoRoot ".specify/extensions/specrew-speckit/scripts/$relPath"

        if (-not (Test-Path -LiteralPath $mirrorPath -PathType Leaf)) {
            $violations += [pscustomobject]@{
                Kind     = 'missing-mirror'
                Source   = $src.FullName
                Mirror   = $mirrorPath
                Severity = 'FAIL'
            }
            continue
        }

        $srcHash    = (Get-FileHash -LiteralPath $src.FullName -Algorithm SHA256).Hash
        $mirrorHash = (Get-FileHash -LiteralPath $mirrorPath  -Algorithm SHA256).Hash
        if ($srcHash -ne $mirrorHash) {
            $violations += [pscustomobject]@{
                Kind       = 'drift'
                Source     = $src.FullName
                Mirror     = $mirrorPath
                SourceHash = $srcHash.Substring(0,12)
                MirrorHash = $mirrorHash.Substring(0,12)
                Severity   = 'FAIL'
            }
        }
    }

    return $violations
}
```

Emit rule output:

```text
FAIL [mirror-parity] drift: extensions/specrew-speckit/scripts/<name>.ps1 (src=abc123def456) does not match .specify/extensions/specrew-speckit/scripts/<name>.ps1 (mirror=789abc012345). Per F-047 FR-014, mirror MUST be byte-identical. Fix: cp extensions/specrew-speckit/scripts/<name>.ps1 .specify/extensions/specrew-speckit/scripts/<name>.ps1
```

### Pillar 2: Phased severity rollout (~0.5 SP)

Two-phase rollout to avoid disrupting in-flight work:

1. **Phase 1 (ship immediately as WARN)**: emit WARN-only on detected drift. Lands with the small-fix slice; gives any in-flight feature branches one feature-cycle to catch up.
2. **Phase 2 (promote to FAIL after one feature-cycle)**: after the rule has been WARN for one feature ship (≈1 week), promote to FAIL severity. Drift then blocks boundary-sync until repaired.

The phased rollout pattern matches F-047 Item 1 (handoff-block presence) which shipped as WARN to avoid breaking in-flight work.

### Pillar 3: Bidirectional check + intentional-divergence whitelist (~0.5-1 SP, optional)

Some content lives in `.specify/extensions/...` but NOT in `extensions/...` (e.g., spec-kit installation artifacts that don't come from the source). The check must be source-anchored (every source script has a corresponding mirror) but should NOT fail on mirror-only files unless they shadow a source script.

Optional whitelist file `.specrew/mirror-parity-whitelist.yml`:

```yaml
# Files intentionally in mirror only (no source counterpart expected)
mirror_only:
  - extensions/specrew-speckit/scripts/spec-kit-runtime-stub.ps1
# Files intentionally in source only (dev-only, not mirrored)
source_only:
  - extensions/specrew-speckit/checklists/
  - extensions/specrew-speckit/design/
  - extensions/specrew-speckit/governance/
  - extensions/specrew-speckit/prompts/
```

If Pillar 3 is deferred, the validator covers the FR-014 scope (`scripts/*` only) and source-anchored direction is sufficient.

### Pillar 4: Scope expansion (optional, ~1 SP)

F-047 FR-014 scopes the rule to `scripts/*` only. The 2026-05-26 audit revealed `extension.yml` also drifted (version pin) — same root cause, different file. Optional expansion to cover:

- `extensions/specrew-speckit/extension.yml`
- `extensions/specrew-speckit/scripts/*` (FR-014 scope)
- `extensions/specrew-speckit/squad-templates/**/*.md` (currently shows 3 drifted templates per 2026-05-26 audit)

Each expansion broadens the failure surface; pair with a whitelist if false-positive risk is non-trivial. Recommended: ship Pillar 1+2 for `scripts/*` first; expand later if more drift incidents accumulate.

## How (small-fix-slice plan)

- Single iteration on feature branch from `main`
- ~2-4 SP total (Pillar 1+2 only); ~3-5 SP with Pillar 3+4
- Files touched:
  - `extensions/specrew-speckit/scripts/validate-governance.ps1` — add rule invocation
  - `extensions/specrew-speckit/scripts/shared-governance.ps1` — add `Test-MirrorParity` helper
  - `tests/integration/mirror-parity.tests.ps1` (new) — drift fixture + no-drift fixture
  - `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` (mirror)
  - `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` (mirror)
  - `CHANGELOG.md` entry
- Phase 1 (WARN) ships in the small-fix slice
- Phase 2 (FAIL promotion) ships ~1 week later as a follow-up commit (or bundled into next runtime-touching feature)

## Acceptance signals

- **AC1**: `validate-governance.ps1` emits WARN (Phase 1) / FAIL (Phase 2) when any `extensions/specrew-speckit/scripts/*.ps1` differs by SHA256 from its `.specify/extensions/specrew-speckit/scripts/*.ps1` counterpart
- **AC2**: `validate-governance.ps1` emits the same severity when a source script has no mirror counterpart
- **AC3**: Test fixture verifies positive case (synthetic drift → expected violation) and negative case (clean parity → no violation)
- **AC4**: `Test-MirrorParity` helper is exported from `shared-governance.ps1` for reuse by other validators (e.g., Reviewer skill could call it directly)
- **AC5**: Phase 1 → Phase 2 transition documented in CHANGELOG (transition is a separate one-line edit, not a re-release)
- **AC6 (Pillar 3, if shipped)**: Whitelist file at `.specrew/mirror-parity-whitelist.yml` honored — explicitly-listed source-only or mirror-only files do not trigger violations
- **AC7 (Pillar 4, if shipped)**: Scope extension to `extension.yml` + `squad-templates/**/*.md` verified on the same 2026-05-26 backfill fixture

## Out of scope

- Auto-fixing detected drift (validator reports; human or future hook decides whether source or mirror is canonical). Auto-sync would be a separate proposal — composes with Proposal 088 markdown-lint-pre-boundary auto-fix pattern but at a different surface
- Hook-based pre-commit enforcement (Proposal 105 territory)
- Cross-host mirror parity (e.g., `hosts/<kind>/...` adapter symmetry) — separate concern, separate proposal if it surfaces

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **F-047 (Trust-Hardening Bug-Bash, shipped 2026-05-26)** | This proposal mechanically enforces FR-014 (the prose rule F-047 added). Same family as F-047's other validator additions (handoff-block presence, Mermaid template, downstream-language audit) — runtime-checked discipline, not prose-discipline |
| **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning)** | Directly addresses the form-vs-meaning gap: F-047 added FR-014's FORM (the prose rule); this proposal adds the MEANING check (mechanical SHA256 verification). Could be bundled INTO 030 as a sub-component when 030 is implemented |
| **Proposal 067 (Small-Fix Slice Type)** | Natural shape for this work — single rule + helper + test, ~2-4 SP, no architectural change. Validates the small-fix-slice methodology in another bug-class |
| **Proposal 086 (Validation Pipeline Performance Bundle) Pillar 5 (Repetition Detector)** | Pillar 5 detects "validator is repeating the same failure" — composes with this proposal's WARN-then-FAIL pattern. If the mirror-parity WARN fires repeatedly across boundaries, Pillar 5 surfaces it as "you have a persistent drift" instead of just emitting the WARN each run |
| **Proposal 088 (Markdown-Lint Pre-Boundary Auto-Fix)** | Adjacent pattern — validator detects + auto-corrects. Mirror-parity could eventually adopt an auto-correct mode (copy source → mirror as part of boundary-sync), but Phase 1 explicitly excludes auto-fix to keep human in the loop |
| **Proposal 105 (Host-Native Hook Deployment)** | Runtime-hook layer where `PreToolUse` on `Edit` of `extensions/specrew-speckit/scripts/*.ps1` could trigger immediate mirror update (instead of waiting for validator detection at boundary-sync time). Phase-3 enhancement after this proposal lands |
| **Proposal 120 (Handoff-Block Validator Enforcement)** | Sibling proposal — both mechanize a prose rule that F-047 added. Same shared-helper pattern: `Test-SpecrewHandoffBlockPresent` in 120, `Test-MirrorParity` in this proposal |
| **Proposal 087 (Push-to-Main Scoping)** | Push-to-main validator runs full-repo lint as truth-check; this proposal's `Test-MirrorParity` would naturally land there for the full-repo nightly check, and in PR-CI scoped check for changed files |

## Status history

- 2026-05-26: candidate proposal drafted after 2026-05-26 mirror-parity audit surfaced 4-file drift (extension.yml + 3 scripts) and backfilled in chores `6299fb99` + `948ab40c`. The drift traced to commit `18bfaeab` (F-044 iter-003) which predated F-047 FR-014 by 4 days, demonstrating that the prose rule alone does not backfill pre-existing drift and does not catch out-of-band commits. Mechanical SHA256 check is the durable layer.

## Cross-references

- **Empirical motivation**: 2026-05-26 mirror-parity audit + 4-file backfill in chores `6299fb99` (extension.yml) + `948ab40c` (3 scripts)
- F-047 spec: file:///C:/Dev/Specrew/specs/047-bug-bash-trust-hardening/spec.md (FR-014)
- Source script being mirrored: file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/
- Mirror destination: file:///C:/Dev/Specrew/.specify/extensions/specrew-speckit/scripts/
- Proposal 030 (Quality Hardening Bundle): file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- Proposal 067 (Small-Fix Slice Type): file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md
- Proposal 086 (Validation Pipeline Performance Bundle): file:///C:/Dev/Specrew/proposals/086-validation-pipeline-performance-bundle.md
- Proposal 088 (Markdown-Lint Pre-Boundary Auto-Fix): file:///C:/Dev/Specrew/proposals/088-markdown-lint-pre-boundary-auto-fix-discipline.md
- Proposal 105 (Host-Native Hook Deployment): file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md
- Proposal 120 (Handoff-Block Validator Enforcement): file:///C:/Dev/Specrew/proposals/120-handoff-block-validator-enforcement.md
- Proposal 131 (Coordinator-Prompt SDLC Ownership Clarification): file:///C:/Dev/Specrew/proposals/131-coordinator-prompt-sdlc-ownership-clarification.md
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
