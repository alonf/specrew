# Code & Implementation Lens

## Lens ID

`code-implementation`

## Purpose

The other lenses cover *what the system is*; none covers *how the code is written*. This lens captures
implementation-craft decisions — language version, construct usage, DI/pattern posture, file/function
size, comment policy, packaging, per-stack dilemmas, dependency selection, and the maintainer's default
rule set — **with the human at design time**, and feeds them to a guidance skill that **actively guides
the coding agent at implement time**. It prevents the ad-hoc, inconsistent, refactor-prone code that
results when craft decisions are made implicitly during `implement`.

## When this lens runs

`code-implementation` is **always-applicable for any feature that writes code** (auto-on, with an
explicit skip for doc-only / config-only slices) — people do not opt into code quality. The rule set is
**data-driven**: the canonical catalog is `code-rules.yml` in this directory; this lens md is the
*conduct + decision spine* and references the catalog by group, never re-prosing every rule.

## Applicability Signals

- The feature writes or changes source code in any language.
- It may add or choose a library, framework, SDK, CLI, test tool, build tool, or runtime package.
- It exposes consuming-code-facing API (more than one caller), services, UI, concurrency, or messaging.
- Skip only for doc-only / config-only slices (record the skip reason).

## Design Decision Points

Surfaced via the **grouping model** (see below); the catalog holds the full rule text + ids.

- **Source of code-rules truth** — does the human have an existing coding guideline OR one or more
  example projects (GitHub / local / other) to emulate for style, constructs, and patterns? (Ingest by
  assisted mapping; otherwise use the Specrew defaults.)
- **Resolved stack** — the language/runtime baseline (drives which catalog slice + applicability-filtered
  rules apply); asked at the lens turn with repo inference as a hint.
- **Baseline craft posture** — the `baseline-default` group (intent-revealing names, short methods, low
  nesting, DI, no magic numbers, guard invariants, no leaky internals, SOLID, …) stated as defaults;
  the human toggles exceptions only.
- **Consequential forks** — the `decision-prompt` group: concurrency vs locks, copy semantics, error
  handling, protocol, pagination, cache posture, testing/TDD posture, Strategy/State over repeated
  conditionals, polymorphism mechanism (functional vs inheritance/interfaces), extension points (OCP),
  authz/security-context flow, current-LTS check, shared-code packaging, public-API design, and the
  per-stack posture for the resolved stack.
- **Applicability-filtered rules** — shown only when the context applies (render purity, event-loop
  discipline, vendor-neutral observability, UI input controls, framework validation, technology-enabler
  shortlist, CNCF maturity, rendering/hosting model).
- **Tooling / dependency selection (FR-013)** — when implementation may add/choose a dependency, present
  **"use existing project tools / no new dependency" first** plus options; for a chosen dependency capture
  version, license, source org, canonical URL, maintenance signal, security/advisory status,
  compatibility, cost/quota (if relevant), coupling weight, replaceability, and test implications.
- **Continuous co-review harness/model/effort** — for code-writing features, ask which continuous co-review harness, model,
  and optional effort setting should review the implementation (for example Codex + ChatGPT, Claude + Opus 4.8 1M context, or Copilot
  on a strong model). If the human skips the workshop or does not choose a reviewer, Specrew auto-selects:
  Codex + ChatGPT and Claude + Opus 4.8 1M context are peer top review classes; prefer Codex when Claude wrote
  the code and prefer Claude when Codex wrote it; Copilot on a strong model ranks next; then other harnesses.
  If only one harness is available, use that harness with its best authorized review model. Record the answer in
  `reviewer_preference`; dynamic model/effort discovery is future capability-adapter work, so MVP values are
  captured as explicit host-specific labels.

## Rule grouping and consumption model

The catalog classifies every rule so the human sees only material choices while plan/implement/review
receive a complete manifest:

- **baseline-default** — best-practice rules that normally apply; stated as the project baseline, asked
  only for exceptions.
- **decision-prompt** — rules whose answer changes performance / complexity / maintainability / UX /
  operations / coupling; surfaced to the human.
- **applicability-filtered** — stack / framework / domain rules irrelevant unless that context applies.
- **enforcement-mode** — informational per-rule evidence mechanism (compiler / formatter / analyzer /
  tests / review). **No 145 mechanical gate** — enforcement is the implement-time guidance skill.

The lens output is the per-feature `implementation-rules.yml` manifest (reference-by-ID), forward-compatible
with Proposal 156 `workshop-decisions.yml`; it is consumed by `plan.md` (implement constraints) and the
`specrew-code-rules` skill, and is NOT a standalone verification universe.

## Run Cadence

The code rules are mostly **product-level and stable**:

- **V1 (Proposal 162 not shipped)**: every code-writing feature gets a feature-level pass
  (`context_scope: feature_standalone`).
- **Future (Proposal 162 shipped)**: decide the rules **once at a product-level workshop**, then each
  feature **inherits** them (`context_scope: feature_delta` against `product_baseline`) and **re-opens
  only the parts a new technology or programming language changes**.
- An ingested company guideline / example-project conventions are product-level → persist to the
  reusable `code-rules.local.yml` overlay.

## Workshop Conduct

- **Diagram for this lens**: render it as **console ASCII inline** — a view of the grouped checklist
  (design-time) + the agent-guidance surface (implement-time) — so the human sees it in the conversation
  (a fenced mermaid block is source text, not a picture, on a terminal host); any mermaid/svg/html file is
  an additional artifact whose clickable `file:///` link you surface in the same message.
- **Source-of-truth first**: ask for an existing guideline OR example project(s) before presenting the
  checklist (the Figma-equivalent question). On a provided guideline/project, perform **assisted
  ingestion** (agent-reasoning, no parser): map conventions onto the catalog (auto-check matches, flag
  conflicts), extract non-catalog conventions as custom rules with provenance
  (`from-guideline` / `from-example-project` + source ref); company/org-level → the project overlay.
- **Resolve the stack**, then present the **grouped, pre-checked set/unset checklist** — baseline as a
  summary (exceptions only), decision-prompts paced (offer all-at-once or one-at-a-time on a dense set),
  applicability-filtered only when context applies. Never a flat wall.
- **Dependency selection**: default-first "use existing project tools / no new dependency"; capture the
  fields for any chosen dependency into the manifest `dependency_policy`.
- **Reviewer selection (INT-006 - present the list, do NOT ask blind)**: before closing this lens, RUN
  `specrew review --list-hosts --code-writer-host <the host you are running as>` and PRESENT its output to
  the human verbatim - the SELECTABLE hosts (recommended independent first, then their own code-writer shown
  as also-selectable, then any unavailable host shown with its reason) and the DEFAULT. Do NOT present from
  memory or from the examples above; the command reflects what is actually installed on the human's PATH.
  Then capture their pick into `reviewer_preference` as `mode=human-selected` with the chosen `host`. A human
  MAY pick their own code-writer - only they know each host's quota/token status; independence is the
  recommendation, not a rule. If they make no choice, record the DEFAULT the command marked (still
  `mode=human-selected`). Do NOT show or pin a model - Specrew uses the host's own default model (no dynamic
  model discovery exists yet).
  - **AUTHORIZE the pick (bridge to the navigator)**: capturing `reviewer_preference` alone is NOT enough - the
    async navigator selects from `.specrew/reviewer-hosts.json`, NOT from the workshop manifest. After the human
    picks, RUN `specrew review --host <chosen> --authorization-ref workshop-<feature>` to persist the
    human-provenance authorization to `reviewer-hosts.json` (the navigator reads it READ-ONLY). The HUMAN chose it,
    so this records their provenance - it is NOT agent self-authorization (the Proposal-190 hole). Do NOT hand-write
    `reviewer-hosts.json` yourself: the command writes the EXACT `hosts[]` catalog schema the navigator READS; a
    hand-authored file (e.g. an `authorizations[]` array) is INERT - the co-review silently finds no host and a
    different agent fills the vacuum with its own review that the lifecycle then accepts. If the command ERRORS,
    surface the error to the human and STOP; never fall back to writing the file by hand. WITHOUT a command-written
    authorization the auto-fired co-review has no host and stays dark.
- **Capture** the selections/decisions/custom-rules/dependency-policy into `implementation-rules.yml`
  (reference-by-ID) + the human-readable `workshop/code-implementation.md`; record the lens in
  `lens-applicability.json`.
- **Re-invoke the `specrew-design-workshop` skill** before the next lens.

## Question Bank

- Do you have a coding guideline or an example project to emulate?
- What stack/runtime baseline are we binding, and which modern constructs are in/out?
- Which baseline craft defaults should be OFF or changed for this feature?
- Concurrency: locks or lock-free/immutable/channels? Copy semantics? Error-handling style?
- Protocol / pagination / cache / messaging posture? Testing/TDD posture?
- Do repeated conditionals call for Strategy/State? Functional or inheritance polymorphism?
- Which review harness and model should review the code, or should Specrew auto-select if no choice is made?
- May this feature add a dependency — or can existing project tools do it? If new: version, license,
  source, maintenance, security advisories, compatibility, coupling, replaceability, test impact?

## Alternative Dimensions

- **Simplest**: accept the baseline defaults + the resolved-stack defaults; no custom rules.
- **Reasonable**: baseline + the consequential decision-prompts answered + applicable filtered rules +
  any dependency selection.
- **By the book**: ingest the company guideline / example project, record custom rules to the project
  overlay, and decide every consequential fork + the full per-stack posture.

## Plan Obligations

- `plan.md` converts the selected rules into implement constraints (the manifest is the source).
- The Implementer charter / coordinator carries a thin pointer to the `specrew-code-rules` skill.
- A load-bearing `dependency_policy` (a chosen new dependency) is recorded with its captured fields.

## Validation Signals

- The agent is **actively guided** by the manifest at implement time and generated code reflects the
  chosen rules (dogfood, not file-presence).
- The human faced a grouped checklist, not a wall (dogfood).
- The catalog has unique/stable ids and validates against its schema; the manifest is schema-valid.
- Review can point to the captured decision for any rule it checks (no parallel code-quality gate).

## Artifacts

- `code-rules.yml` (this directory) — the canonical catalog.
- `implementation-rules.schema.json` (this directory) — the per-feature manifest schema.
- `specs/<feature>/implementation-rules.yml` — the per-feature manifest (reference-by-ID).
- `specs/<feature>/workshop/code-implementation.md` — the human-readable lens record.
- `code-rules.local.yml` (project root, optional) — the reusable overlay (ingested guideline + custom rules).
- `reviewer_preference` in the workshop record / implementation manifest — selected reviewer harness/model/effort
  or explicit auto-selection fallback.

## Manifest shape (hand-authored example)

Author `implementation-rules.yml` **by hand** following this shape (like `product-domain`; you do NOT call
a PowerShell writer). The manifest reader is a constrained YAML subset, so the indentation is exact: list
items (`- id:`) at **2 spaces**, their properties at **4 spaces**, `dependency_policy.selected` items at
**4 spaces** with fields at **6 spaces**; strings are double-quoted, booleans are bare (`true` / `false`),
and `enforcement` is an inline list. `selections` reference `code-rules.yml` ids (an unchecked baseline id
is a recorded exception); `provenance.confirmation` pairs with `confirmation_scope`
(`human-confirmed`->`lens-question`, `human-delegated`->`explicit-delegation`,
`human-skipped`->`explicit-skip`). Validate against `implementation-rules.schema.json`.

```yaml
schema_version: "1.0"
context_scope: "feature_standalone"
resolved_stack: "csharp-dotnet"
selections:
  - id: "code-rule.dependency-injection"
    checked: true
  - id: "code-rule.idiomatic-error-handling"
    checked: true
    decision: "Result type at the service boundary; ProblemDetails at the API edge."
    enforcement: [review]
  - id: "code-rule.comments-wisely"
    checked: false
custom_rules: []
dependency_policy:
  stance: "use-existing-no-new-dependency"
reviewer_preference:
  mode: "human-selected"
  host: "codex"
  model: "chatgpt"
  effort: "max"
  source: "code-implementation-workshop"
  authorization_ref: null
  rationale: "Code author is Claude, so Codex gives an independent strong review."
provenance:
  confirmation: "human-confirmed"
  confirmation_scope: "lens-question"
```

## Source Notes

- Proposal 163 (Code & Implementation Lens) — the 49-rule maintainer baseline + the research baseline.
- Microsoft Framework Design Guidelines (cross-stack reusable-code/API questions, adapted per stack).
- Per-stack sources: C#/.NET language-version + analyzers + DI guidelines; Google C++ Style / C++ Core
  Guidelines / LLVM / CERT / MISRA; TypeScript strict + ESLint/typescript-eslint + Prettier; ruff /
  Black / mypy / PEP 8; Effective Go + gofmt/vet/golangci-lint; Checkstyle / PMD / SpotBugs /
  google-java-format. (Sources catalogued in Proposal 163; checked 2026-06-08.)
- F-177 additions (2026-06-10): SOLID baseline, Strategy/State over repeated conditionals, polymorphism
  mechanism choice, and example-project ingestion.
