# Requirements & NFR Workshop Record: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Depth**: medium
**Confirmation**: human-confirmed (lens-question)

## NFR priority order (design drivers)

```text
RANK  QUALITY ATTRIBUTE             DRIVER?    HOW IT'S PROVEN (not file-presence)
 1    Forge-neutrality / portability  ★ top    methodology + core validator run on a NON-GitHub / no-adapter repo
 2    Honesty / no-over-claim         ★ high    review finds NO over-claim; partial enforcement labeled phased/deferred
 3    Safety (security)               ★ high    denial-path tests: apply_protection human-gate, read-only adapters, no secrets
 4    Maintainability                 ★ high    data-driven catalog = one source of truth; add a kind = data edit; docs↔enforcement sync
 5    Brownfield-compat / fail-open   ★ med     adapt to existing CI/CD; validator never spuriously blocks; advisory default
 6    Multi-host parity               ★ med     surfaces deploy across all hosts (parity test)
      Performance                       no      governance tooling; runs once per PR — explicitly a NON-driver
```

## FR set (consolidated)

Original FR-001…FR-013 stand (FR-003 generalized to `branch_model`; FR-009 resolved to
`.specrew/work-kind.yml` authoritative + branch-prefix hint). Workshop additions:

- **FR-014** — provider-neutral core: methodology + declaration + core validator import no
  forge assumption; `ProviderAdapter` is the only forge seam.
- **FR-015** — ship the `ProviderAdapter` contract + a GitHub reference adapter + a
  generic/unknown fallback (`ci-only`/`manual` via git-diff).
- **FR-016** — on-the-fly adapter synthesis: generate a forge adapter when the downstream
  dev names their forge; read-only by default; provenance recorded.
- **FR-017** — `review_gate`: human approvals + comment-resolution always-available;
  automated review opt-in (Copilot suggested on GitHub via the adapter); user decides in
  the workshop.
- **FR-018** — project-level `.specrew/repository-governance.yml` capture (`branch_model` +
  `review_gate` + `multi_repo`), decided once + inherited per feature.
- **FR-019** — forge-neutralization: audit + decouple ALL downstream-governing surfaces from
  Specrew's own GitHub dev habits (producing an inventory), without changing Specrew's own
  GitHub usage.
- **FR-020** — `apply_protection` is human-approved, never auto-applied / never from an
  unverified synthesized adapter; Specrew holds no secret.
- **FR-021** — brownfield-aware governance: detect existing CI/CD + branch protection +
  review setup; offer to **adapt** the work-kind check into it OR **change** to the
  recommended posture; never silently overwrite. The capture records the existing posture +
  the chosen action.

## SC additions

- **SC-010** — methodology + core validator run on a non-GitHub / no-adapter repo with the
  full lifecycle.
- **SC-011** — a non-`main` integration-branch config (e.g. `master` + `dev`) is honored by
  the validator + lifecycle (feature-closeout at target merge; promotion = release-validation).
- **SC-012** — on-the-fly synthesis produces a forge adapter that is read-only until a human
  verifies it.
- **SC-013** — the forge-neutralization audit inventory exists; migrated downstream-governing
  surfaces carry no GitHub-only mandate (closeout "check Copilot" → opt-in); Specrew's own
  infra unchanged.
- **SC-014** — applying the updated DevOps lens to Specrew's own repo surfaces no conflict
  (or it is reconciled); Specrew's `.specrew/repository-governance.yml` matches its actual
  posture (main protected, PR-required, applies-to-admins, no force-push/delete, its CI lanes
  as required checks, its review gate) — also proves the neutralized closeout still works for
  a GitHub project.

## FR/SC → iteration map

```text
Iter 1 (methodology + seam contract + audit + brownfield discovery):
   FR-001..006, 008, 009, 010, 014, 015(contract+fallback), 016(doc), 017, 018, 019(inventory),
   021(lens content + discovery)                                   → SC-001..004, 011
Iter 2 (runtime):
   FR-007, 011, 012, 015(GH detect), 016(exercised), 020, 021(detector runtime)
                                                                    → SC-005, 006, 007, 009, 010, 012, 014
Iter 3 (decouple):
   FR-019(migration)                                                → SC-008, 013
```
