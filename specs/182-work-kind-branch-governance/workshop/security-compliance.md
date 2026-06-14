# Security & Compliance Workshop Record: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Depth**: medium
**Confirmation**: human-confirmed (lens-question)

## Trust boundaries + attack surface

```text
        ┌──────────────────────── Specrew (holds NO secrets) ─────────────────────────┐
        │  WorkKindValidator   — read-only: repo files + git diff; fail-open; no token │
        │  CapabilityDetector  — read scope ───────────────┐                           │
        │  apply_protection    — admin scope ─ HUMAN-APPROVED gate ──┐                 │
        └───────────────────────────────────────────────────┼───────┼─────────────────┘
                                  token from CI (GITHUB_TOKEN) or user `gh auth`
                                                             ▼       ▼
                                                     ┌───────────────────────┐
        Synthesized adapter (AI-generated):          │  FORGE (the enforcer) │ ◀ trust boundary
          read-only by default · checked into repo   │  protected branch     │
          (reviewable) · provenance · apply ONLY      │  required reviews     │
          after a human verifies it                   │  bypass_actors = []   │
                                                     └───────────┬───────────┘
        Emergency bypass ──▶ durable AUDIT artifact (who/why/when/what), never a silent skip ◀┘
```

## Decisions

- **DP-S1 — Authz model**: Specrew **captures** the branch-governance policy; the **forge
  enforces** it (protected branch + required reviews + bypass list). Specrew implements no
  authz of its own. Secure-by-default: `apply_to_admins: true`, `bypass_actors: []`,
  force-push/delete off.
- **DP-S2 — Privileged-action safety**: `apply_protection` is the only privileged mutation —
  **human-approved, never auto-applied**, never from an unverified synthesized adapter; uses
  the user's own forge token (CI token or `gh auth`); **Specrew stores no secret**.
- **DP-S3 — Synthesized-adapter trust**: AI-generated adapters are **read-only by default**
  (`detect`/`describe` only), **checked into the downstream repo** (reviewable), provenance
  recorded; `apply_protection` is unlocked only after a human verifies the adapter.
- **DP-S4 — Emergency bypass audit (FR-011)**: a bypass is an authorized escape hatch that
  writes a **durable audit artifact** (who/why/when/what) — committed or logged, never a
  silent skip.
- **DP-S5 — Secrets / least-privilege**: detection needs **read** scope, apply needs **admin**
  scope; missing/insufficient token → degrade to `ci-only`/`manual` with an honest message
  (never fail-closed-blocking).
- **DP-S6 — Validator confinement**: the CI validator reads repo files + git diff only, **no
  secret access**, **fail-open** (never spuriously blocks merge); denial-path tests required
  (too-broad bypass, missing-token path).
