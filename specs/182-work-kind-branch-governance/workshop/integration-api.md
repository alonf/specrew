# Integration & API Workshop Record: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Depth**: full
**Confirmation**: human-confirmed (lens-question)

## ProviderAdapter contract (the only forge-specific seam)

```text
ProviderAdapter:
  detect_capability(ctx)          -> { mechanism: branch-protection|rulesets|ci-only|manual, constraints }
  describe_protection(governance) -> human-readable plan (read-only, always safe)
  apply_protection(governance)    -> result      # GUARDED: human-approved; synthesized adapters omit/stub
  read_pr_context()               -> { changed_files[], target_branch, source_branch, merge_state }
  # provider-NEUTRAL fallback for read_pr_context: `git diff <base>..<head>` for changed_files;
  #   branch_model supplies target/promotion semantics — the validator runs with NO adapter at all
```

## CI work-kind validator data-flow (provider-neutral script)

```text
  inputs:  .specrew/work-kind.yml (declaration)  +  work-kinds.yml (catalog)
           +  changed_files (adapter.read_pr_context OR git-diff fallback)
           +  closeout evidence (specs/<feature>/…)  +  branch_model (repository-governance.yml)
  checks:  exactly one work_kind?  ·  kind in catalog?  ·  changed files within the kind's allowed
           scope (allow-list exempts global/generated files)?  ·  required closeout evidence present?
           ·  software-feature/bug-bash: no open lifecycle boundary?
  output:  advisory (warn) | blocking verdict that NAMES THE EXACT GAP (SC-005)
```

## Decisions

- **DP-I1 — Declaration mechanism (FR-009 resolved)**: `.specrew/work-kind.yml` is the
  **authoritative**, forge-neutral, versioned, reviewable declaration; an **optional
  branch-prefix convention** (`docs/`, `devops/`, `fix/`, `feature/`) supplies a default the
  file confirms/overrides. PR/MR labels are **rejected as the source of truth** (forge-
  specific — they would reintroduce the coupling the architecture removed); on GitHub an
  **opt-in label mirror** may be surfaced by the adapter but is never authoritative.
- **DP-I2 — ProviderAdapter contract**: `detect_capability` / `describe_protection` (read-
  only, always safe) / `apply_protection` (guarded, human-approved; synthesized adapters
  omit/stub) / `read_pr_context`. The validator works with **no adapter** via the
  `git diff <base>..<head>` + `branch_model` fallback — forge independence by construction.
- **DP-I3 — Contracts + versioning**: `work-kinds.yml` catalog + `.specrew/work-kind.yml`
  declaration + `.specrew/repository-governance.yml` + per-feature closeout evidence; each
  carries `schema_version`; **fail-open + WARN** on unknown/malformed (Feature-177 pattern);
  stable work-kind IDs (deprecate-not-delete).
- **DP-I4 — Fail-open edges**: no declaration → infer from branch prefix if configured, else
  WARN "declare your work kind" (advisory); unknown `work_kind` → WARN + skip scope/evidence
  checks; malformed catalog/declaration → WARN + neutral (never hard-block); adapter
  unavailable / generic forge → `read_pr_context` falls back to git diff, capability →
  `ci-only`/`manual`.
- **DP-I5 — Seams**: the validator resolves the active feature → reads the known manifest
  paths; the specify/closeout gates read existing artifacts; the work-kind manifest is NOT a
  new hard gate in v1 (advisory), consistent with the phased posture (DP-A5).
