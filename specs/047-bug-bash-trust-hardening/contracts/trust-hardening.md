# Contract: F-047 Trust-Hardening Public Surface

**Feature**: `047-bug-bash-trust-hardening`
**Stability**: pre-1.0

## Test-SpecrewHandoffBlockPresent (new helper, shared-governance.ps1)

Detects whether a `=== SPECREW HANDOFF ===` block precedes a boundary commit window.

### Exported API
| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Test-SpecrewHandoffBlockPresent` | `(-CommitMessage <string> [-SessionMetadata <hashtable>]) : bool` | True if a handoff block is present in the inspected window | never throws; returns `$false` on absent/unparseable input |

### Invariants
- Pure detection; emits no findings itself (the validator maps the bool to a WARN).
- Mirrored byte-identical into `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1`.

## validate-governance.ps1 — new WARN findings

| Finding code (indicative) | Trigger | Severity |
| --- | --- | --- |
| `handoff-block-missing` | boundary/iteration commit with no preceding handoff block | WARN |
| `dashboard-missing-diagnosis` | `dashboard.md` absent — classified as non-Specrew-managed vs. auto-render regression | WARN |
| `artifact-wrong-location` | canonical artifact under an ephemeral host-scratch path | WARN |
| `review-diagrams-no-mermaid` | `review-diagrams.md` exists, no ` ```mermaid ` block | WARN (soft) |
| `internal-reference-in-prose` | `\bF-\d{3,}\b` / `\bProposal \d{3,}\b` / `\bFeature \d{3,}\b` in handoff prose | WARN |

### Invariants
- All five are WARN; none escalate to FAIL (FR-016) — existing repos do not start failing on update.

## Get-SpecrewSkillCatalogState (contract change, skill-catalog-state.ps1)

### Behavior change
| Symbol | Before | After |
| --- | --- | --- |
| `Get-SpecrewSkillCatalogState` → `HasMissingRoots` | `true` only when a root directory is absent | `true` when a root is absent OR present-but-zero-`SKILL.md` (content-based) |

### Invariants
- An empty skill root now triggers auto-repair; no contradictory residual "missing skill files" WARN.

## tasks-progress.yml regeneration (contract change, specrew-start.ps1)

### Behavior change
| Input | Before | After |
| --- | --- | --- |
| `tasks.md` with `[x]` + `state.md` complete | all tasks written `planned` | per-task status derived from `tasks.md` (authoritative) + `state.md` |

### Invariants
- `tasks.md` is the single source of truth; `tasks.md`↔`state.md` divergence is surfaced, not silently resolved.

## Coordinator-prompt feature-closeout HANDOFF template (contract addition)

### Invariant
- Every per-host template's feature-closeout HANDOFF block contains the PR-at-feature-close SDLC action items (push → open PR → address automated PR review → merge), independent of agent memory.
