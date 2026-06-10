# UI/UX — Feature 177 (code-implementation / software-development-rules lens)

**Depth**: medium · **Confirmation**: human-confirmed / lens-question (2026-06-10)

Source of UX truth = text/console (no Figma). Accessibility/locale/RTL n/a (maintainer + agent,
English, terminal). Two interaction surfaces.

## Surface 1 — human-facing (design time), GUIDELINE-FIRST

```text
code-implementation lens turn (human-facing)

  Step 0  SOURCE OF CODE-RULES TRUTH   (FIRST — the Figma-equivalent question)
            "Do you have an existing coding guideline / standards doc — OR one or more example projects
             to emulate (GitHub repo, local path, or other) for code style, language constructs, and
             patterns? Paste / point me at a doc or project, or say 'no'."
              ├─ HAVE ONE → INGEST it (assisted mapping): map onto our catalog (auto-check matches,
              │             flag conflicts for the human) + extract rules NOT in our catalog as new
              │             custom items + (company/org-level) save to PROJECT OVERLAY
              │             code-rules.local.yml → inherited per feature (product-baseline tier)
              └─ NONE      → Specrew defaults (pre-checked) + offer free-text custom rules

  Step 1  Resolve stack ......... loads only that stack's slice
  Step 2  GROUPED CHECKLIST  (pre-checked by BOTH our defaults AND the ingested guideline)
            ▾ cross-language baseline    [x] ...  (combined, reused across stacks)
            ▾ language-specific          [x] ...
            ▾ framework                  [x] ...
            ＋ custom rules  (from the guideline + your own free-text / pasted additions)
  Step 3  Decisions you must make   (paced)
  Step 4  Applicability-filtered    (context-gated)
  Step 5  Capture → implementation-rules.yml  (+ overlay for company-level rules)
```

Checklist mockup (set/unset via checkmarks; pre-checked at defaults):

```text
Stack: C#/.NET          [change]

▾ Cross-language baseline    (18 rules, ON by default — review, don't author)
   [x] names carry intent           [x] short methods            [x] low nesting
   [x] DI as a principle            [x] no magic numbers         [x] guard invariants
   [x] don't leak mutable internals [x] idiomatic errors    ...  [expand to toggle any OFF]
▾ C#/.NET specific           (7 rules, ON by default)
   [x] nullable reference types     [x] file-scoped namespaces   [x] .editorconfig + analyzers
   [ ] allow preview/latest C#      ...                          [expand to toggle]
▾ Framework: ASP.NET         (shown — web API in scope)
   [x] declarative authz attrs      [x] model validation         [ ] minimal APIs
▸ Decisions you must make     (5 — need your call, paced)
▸ Applicable only-if          (React render-purity: client? · ...)
＋ Add your own rule           (free text OR pasted doc → this feature; optionally project overlay)
```

- **Set/unset**: every rule is a checkbox, pre-checked at defaults (review not author); unchecking
  records an exception. Checkmarks rendered per group via the multi-select picker (honest: the picker,
  not a persistent GUI widget — but real checkboxes).
- **No wall**: defaults pre-checked + the guideline pre-marks the list + grouping by scope (common
  rules combined) + only material rules need attention.

## Surface 2 — agent-facing (implement time)

```text
specrew-code-rules skill — implement-time (agent-facing)

  ALWAYS IN VIEW  (compact baseline checklist — small, never a dump)
  ON-DEMAND, TASK-SCOPED  (pull only the group for the current work)
    service → DI · DTO · error/retry · authz/security-context
    client  → render purity · event-loop · validation · input controls
    concurrency → concurrency-over-locks · ordering · idempotency
    API     → protocol · versioning · pagination · idempotency · error envelope
  PER-FEATURE OVERLAY  (from implementation-rules.yml) — the feature's binding decisions
```

## Decisions (human-confirmed) + new FRs

- **FR-009** — user can set/unset rules and add custom rules.
- **FR-010** — guideline-first source-of-code-rules-truth question opens the lens (Figma-equivalent).
- **FR-011** — assisted ingestion: map a provided guideline onto the catalog with provenance + extract
  new rules; human confirms. No deterministic guideline parser.
- **FR-012** — custom rules via free-text OR pasted document → manifest + optional project overlay.
- Catalog gains a **`scope`** tag (`cross-language` / `language:<x>` / `framework:<y>`); cross-language
  rules combined.
- **Project-level overlay (`code-rules.local.yml`) IS in V1**, driven by the company-guideline use
  case (product-baseline tier, inherited per feature); feature-specific custom rules stay in the manifest.
- Agent guidance shape = always-on baseline + task-scoped lookup + per-feature overlay (not all-up-front).
