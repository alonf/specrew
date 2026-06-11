# Component-Design — Feature 177 (code-implementation / software-development-rules lens)

**Depth**: full · **Confirmation**: human-confirmed / lens-question (2026-06-10)

## Component map

```text
  CATALOG  (ships with Specrew — the stable core; everything depends inward on it)
  ┌────────────────────────────────────────────────────────────────────┐
  │  code-rules.yml ............ 49 rules + per-stack defaults, each with │
  │                              id · group · applies · default · stack   │
  │  code-implementation.md .... the lens md (decision spine + per-stack  │
  │                              dilemmas + run-cadence + conduct)        │
  │  implementation-rules.schema.json ... schema for the per-feature manifest │
  │  registration ............. index.yml row · applicability-map.json ·  │
  │                              specrew-design-workshop lens map · $lensIds │
  └────────▲──────────────────────────────────────────────▲─────────────┘
           │ reads / presents                              │ resolves rule text by ID
   DESIGN TIME                                       IMPLEMENT TIME
  ┌──────────────────────────┐                     ┌──────────────────────────┐
  │ specrew-design-workshop   │   writes            │ specrew-code-rules        │
  │ skill  (+ code lens turn) │──────────┐          │ skill   (NEW, static)     │
  └──────────────────────────┘          │          │ generic reader            │
                                         ▼          └────────────▲─────────────┘
                          ┌───────────────────────────┐         │ reads (known location)
                          │ PER-FEATURE ARTIFACTS      │         │
                          │  implementation-rules.yml  │─────────┘
                          │  workshop/code-impl.md     │────► plan.md constraints
                          └───────────────────────────┘       Implementer charter pointer
```

## Named components

**Catalog (ships with Specrew — stable, data-driven):**

- `code-rules.yml` — canonical rule catalog: 49 rules + per-stack defaults, each `id` / `group`
  (baseline-default · decision-prompt · applicability-filtered · enforcement-mode) / applicability /
  default / stack. Single source of truth.
- `code-implementation.md` — the lens md: decision spine, per-stack dilemmas, run-cadence, conduct;
  references the catalog, does not re-prose all 49 rules.
- `implementation-rules.schema.json` — schema for the per-feature manifest (mirrors `product-domain.schema.json`).
- registration — `index.yml` row, `applicability-map.json` entry, `specrew-design-workshop` lens map, `$lensIds`.

**Producer (design-time):** `specrew-design-workshop` skill (updated) — runs the code lens turn; writes the manifest.

**Per-feature artifacts (written to ONE location):** `implementation-rules.yml` (selected rule IDs +
per-rule decision/enforcement + resolved stack + `context_scope`) + `workshop/code-implementation.md`.

**Consumer (implement-time — NEW):** `specrew-code-rules` skill — STATIC generic reader.

**Wiring:** `plan.md` converts selected rules → implement constraints; Implementer charter/coordinator
carries a thin pointer to the skill.

**Tests:** registration · catalog integrity (unique/stable IDs, schema-valid) · manifest schema ·
guidance-skill multi-host parity · workshop-writes-manifest · baseline+overlay composition.

## Static-vs-per-feature write split (resolves the multi-location concern)

```text
WRITTEN ONCE, ON INIT/UPDATE  (deploy engine → every host skill dir)   ── generic, NEVER per-feature
  .claude/skills/specrew-code-rules/SKILL.md   ─┐
  .github/skills/specrew-code-rules/SKILL.md    ├─ identical generic reader skill
  .agents/skills/specrew-code-rules/SKILL.md   ─┘
  code-rules.yml (49 rules + per-stack)         ── changes only on a Specrew release

WRITTEN ONCE PER FEATURE  (design-workshop → ONE place)               ── the per-feature payload
  specs/<feature>/implementation-rules.yml      ── selected rule IDs + decisions + resolved stack
  specs/<feature>/workshop/code-implementation.md

AT IMPLEMENT TIME
  specrew-code-rules (static) → resolves active feature → reads specs/<feature>/implementation-rules.yml
                              → resolves rule text from code-rules.yml → guides the agent
```

## Decisions (human-confirmed)

1. **Static generic reader skill** — installed once on init to every host dir, byte-identical, never
   rewritten per feature. It resolves the active feature at runtime, reads the **known manifest
   location**, and composes **baseline** (catalog `baseline-default` rules, always-on even with no
   manifest) **+ overlay** (the feature's selected `decision-prompt` / `applicability-filtered` rules +
   decisions).
2. **Reference-by-ID manifest** — lean manifest of selected rule IDs + decisions; the skill resolves
   rule text from the catalog (one source of truth; stable IDs for future 156/145). NOT embed-full-text.
3. **Reuse the deploy engine** (`deploy-squad-runtime.ps1`) — the skill is added as a managed skill
   *definition* (data + host-scope frontmatter); the existing data-driven fan-out deploys it to all
   hosts with the managed marker + parity guard. Zero per-feature deployment code.

## Follow-up (decision #3 — tracked, not in F-177 scope)

- **FILE a sibling chore/proposal**: extract a named reusable `Deploy-SpecrewSkill` /
  `Sync-SpecrewSkills` function from the `deploy-squad-runtime.ps1` script body, so multi-host skill
  fan-out is a cleanly callable component (maintainer's separate-component instinct). Not required for
  F-177; reuse-as-is is sufficient.
