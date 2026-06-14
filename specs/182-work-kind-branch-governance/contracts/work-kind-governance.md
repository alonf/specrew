# Contract: Work Kind and Branch Governance Public Surface

**Feature**: 182-work-kind-branch-governance
**Stability**: pre-1.0 (additive + fail-open; stable IDs, deprecate-not-delete)

## WorkKindCatalog (`work-kinds.yml`) + CatalogSchema

The shipped, data-driven taxonomy. Validated by `work-kinds.schema.json`.

### Invariants

- Exactly the four ids `software-feature | bug-bash | docs-only | devops` in v1; ids are stable and
  never renumbered (deprecate-not-delete).
- Each entry has `lifecycle_weight`, a non-empty `required_evidence`, and an `allowed_scope`.
- Adding/tuning a kind is a **data edit** to the catalog; the lens, templates, validator, and docs
  read it, so they cannot drift.

## WorkKindDeclaration (`.specrew/work-kind.yml`)

The authoritative, forge-neutral per-work-item declaration.

### Invariants

- Exactly one `work_kind`, which MUST exist in the catalog.
- Authoritative over any branch-prefix hint or (GitHub) label mirror.
- Absent/malformed → advisory WARN + branch-prefix inference, never a hard block.

## RepositoryGovernance (`.specrew/repository-governance.yml`)

Project-level governance capture (`branch_model` + `review_gate` + `multi_repo`). See data-model.md.

### Invariants

- `branch_model` branch **names are the user's**; `main` is only a default name, never assumed.
- `provider`/plan/visibility are captured BEFORE any enforcement mechanism is promised.
- `enforcement_mode` reflects the **achievable** mechanism (honest), degrading to `ci-only`/`manual`.

## WorkKindValidator (provider-neutral)

```text
work-kind-validator.ps1 -ProjectPath <path> -BaseRef <ref> [-Mode advisory|blocking] [-Adapter <id>]
```

### Exported behavior

| Check | Pass condition | Failure message |
| --- | --- | --- |
| one-kind | exactly one `work_kind` declared | names the missing/ambiguous declaration |
| in-catalog | `work_kind` exists in the catalog | names the unknown kind (WARN + skip) |
| changed-file-scope | changed files within `allowed_scope` (allow-list exempts global/generated) | names the offending file + the allowed scope + the fix |
| closeout-evidence | required evidence present; no open lifecycle boundary (software-feature/bug-bash) | names the missing evidence / open boundary |

### Invariants

- Reads changed files via `adapter.read_pr_context` OR a `git diff <base>..<head>` fallback — runs
  with **no adapter**.
- Defaults to `advisory` (exit 0 + WARN); `blocking` is opt-in. Fail-open on malformed input.
- Output names the EXACT gap + the allowed scope + the fix, and carries the advisory/blocking label.

## ProviderAdapter (the only forge seam)

```text
detect_capability(ctx)          -> ProviderCapability         # read-only, always safe
describe_protection(governance) -> human-readable plan        # read-only, always safe
apply_protection(governance)    -> result                     # GUARDED: human-approved; synthesized adapters omit/stub
read_pr_context()               -> { changed_files[], target_branch, source_branch, merge_state }
```

### Invariants

- The methodology + declaration + validator **core** import no forge assumption.
- `apply_protection` is the only privileged mutation: human-approved, never auto-applied, never from
  an unverified synthesized adapter; uses the user's own forge token (Specrew stores no secret).
- Implementations: `github` (reference), `generic/unknown` (always-present fallback → `ci-only`/
  `manual` + git-diff), `synthesized` (on the fly, **read-only by default** until human-verified).

## CapabilityDetector

```text
capability-detector.ps1 -ProjectPath <path> [-Adapter <id>]
```

Returns the achievable `mechanism` + honest `constraints`; never promises unavailable protection;
offers synthesis for an unknown forge.

## Emergency bypass

A bypass is an authorized escape hatch that writes a durable audit artifact (who/why/when/what) —
committed or logged, never a silent skip.
