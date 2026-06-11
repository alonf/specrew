# Integration & API — Feature 177 (code-implementation / software-development-rules lens)

**Depth**: medium · **Confirmation**: human-confirmed / lens-question (2026-06-10)

The "API" is internal — the contracts + seams between the catalog, manifest, skill, plan, and future 156.

```text
Integration seams (producers → contracts → consumers)

  REGISTRATION  (one-time, ships with Specrew)
    index.yml · applicability-map.json · design-workshop lens map · $lensIds · lens-schema

  CONTRACT 1 — catalog (data)
    code-rules.yml        (producer: Specrew release) ──┐ merge: additive + per-rule override,
    code-rules.local.yml  (producer: user overlay)     ┘ NEVER silently drop shipped rules
        └──► consumers: lens (presents) · specrew-code-rules skill (resolves rule text)

  CONTRACT 2 — per-feature manifest   implementation-rules.yml   (schema_version, fail-open WARN)
    producer: design-workshop
    shape: selected rule IDs + checked/unchecked + per-rule decision/enforcement
           + scope/stack + context_scope + custom rules + provenance (from guideline?)
    consumers: specrew-code-rules skill · plan.md (→ implement constraints)
               · (future) 156 workshop-decisions.yml      [join key = STABLE rule IDs]

  SEAM — skill ↔ feature:  skill resolves the active feature → reads the known manifest path
  SEAM — gate:  specify gate reads lens-applicability.json (existing SC-021/026); manifest NOT gated

  EDGE / COMPAT  (all fail-open, surfaced — never crash):
    no manifest → baseline only · unknown rule ID → warn + skip · bad overlay → warn + use shipped
    stable rule IDs never renumbered (deprecate-not-delete)
```

## Decisions (human-confirmed)

- **Manifest contract** — reference-by-ID + checked/unchecked + per-rule decision/enforcement +
  scope/stack + `context_scope` + custom rules + provenance + `schema_version`.
- **Overlay merge** — `code-rules.local.yml` layers on the shipped catalog: additive (new rules) +
  per-rule override (toggle/text), never silently drops a shipped rule (mirrors `.local.md`).
- **Forward-compat join key = stable rule IDs** — what a future 156 adapter keys on; deprecate-not-delete.
- **Fail-open everywhere** — missing manifest → baseline; unknown ID → warn+skip; malformed overlay →
  warn+use shipped. No hard errors (matches the advisory/no-gate posture).
- **Applicability** — the lens is **always-applicable-for-code-features** (auto-on) with an explicit skip
  for doc-only/config-only slices; people do not opt into code quality.

## Amendment 2026-06-10 (pre-plan, human-directed)

- **Manifest `dependency_policy` contract (FR-013)** — the per-feature manifest gains a `dependency_policy`
  block capturing the selected tooling/dependency fields (version, license, source org, canonical URL,
  maintenance signal, security/advisory status, compatibility, cost/quota, coupling weight, replaceability,
  test implications). This is a **design-time** contract surfaced by the guidance skill; registry-query /
  CVE / coupling-inventory automation is a separate future contract (Proposals 097 / 122 / planned 178),
  out of scope here.
