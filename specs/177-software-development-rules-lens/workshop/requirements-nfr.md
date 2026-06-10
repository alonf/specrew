# Requirements & NFR — Feature 177 (code-implementation / software-development-rules lens)

**Depth**: medium · **Confirmation**: human-confirmed / lens-question (2026-06-10)

## Functional requirements (in scope)

- **FR-001** — registered `code-implementation` lens md (index.yml, applicability-map.json, design-workshop lens map, `$lensIds`): decision spine + per-stack dilemmas + run-cadence + conduct.
- **FR-002** — data-driven `code-rules.yml` catalog: 49 rules + per-stack defaults, each with stable `id` / `group` / applicability / default / stack.
- **FR-003** — lens resolves the feature's stack and presents rules via the grouping model (baseline as defaults+exceptions; decision-prompts surfaced; applicability-filtered only when context applies); captures selections.
- **FR-004** — workshop writes schema-valid reference-by-ID `implementation-rules.yml` + `workshop/code-implementation.md` + the `lens-applicability.json` record.
- **FR-005** — new `specrew-code-rules` skill deployed to every host surface via the existing engine; static generic reader; resolves active feature; composes baseline + overlay.
- **FR-006** — plan.md converts selected rules → implement constraints (Planner directive); Implementer charter/coordinator carries a thin pointer to the skill.
- **FR-007** — manifest carries forward-compat `context_scope` hooks (V1 writes `feature_standalone`, no 162 behavior); conduct records the cadence (re-open per-stack only on new tech/language).
- **FR-008** — baseline-only mode: with no manifest, the skill still surfaces the catalog `baseline-default` rules.

## Deferred / out of scope (recorded honestly)

- 156 `workshop-decisions.yml` emission — **deferred** (forward-compatible shape only; no 156 on disk).
- 145 conformance verification — **out of scope by ruling** (no mechanical gate / no parallel engine).
- 162 product-level inheritance behavior — **deferred** (hooks only).
- Analyzer-config "enforced mode" — **out of scope** (future).

## Success criteria

- **SC-001** lens registered + selectable (registration tests).
- **SC-002** running it yields a schema-valid manifest + md + lens record with confirmation provenance.
- **SC-003** skill present + identical in every host dir after init/update (parity).
- **SC-004** at implement time the skill surfaces the selected rules and generated code reflects them — **dogfood, not file-presence**.
- **SC-005** catalog: unique/stable IDs, schema-valid, 49 rules + per-stack present + grouped.
- **SC-006** no-manifest → baseline rules still surface.
- **SC-007** rule-volume UX holds — no wall; only material rules surfaced — **validated by the dogfood human experience**.

## Quality-attribute priorities (design drivers)

```text
Quality attribute            Pri   Driver?  Threshold / evidence
──────────────────────────   ───   ───────  ───────────────────────────────────────────
Usability (rule-volume)       1     DRIVER   human sees only material choices, no wall
                                             → validated by DOGFOOD human experience
Maintainability / fwd-compat  2     DRIVER   one source of truth (catalog, stable IDs);
                                             add/change a rule = edit the catalog only
Multi-host parity             3     DRIVER   skill + lens identical across host roots → parity test
Testability                   4     DRIVER   each FR/SC has a BEHAVIOR test (not file-presence)
Performance                   —     no       markdown/yaml; no runtime perf surface
Security                      —     no       feature itself has no auth/secrets/PII surface
```

**Verification posture**: SC-004 + SC-007 are validated by the dogfood human/agent experience (the
agent actually guided; the human not facing a wall), never by "the files exist."
