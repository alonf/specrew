---
name: "specrew-code-rules"
description: "Guide the coding agent with this feature's chosen implementation-craft rules WHILE it writes code. Use during implement: before and while writing source, and RE-INVOKE per task / file type. It resolves the active feature, reads the per-feature implementation-rules.yml manifest + the canonical code-rules.yml catalog (+ any code-rules.local.yml overlay), and composes a BASELINE (always-on craft defaults) + the feature's OVERLAY (selected decision-prompt rules + decisions + custom rules + dependency policy), surfaced task-scoped (service / client / concurrency / API) so the code reflects the agreed posture. Triggers: implement, writing code, code rules, code quality, DI, naming, error handling, dependency, add a package, refactor, concurrency, API design, before I write the implementation."
domain: "lifecycle-implementation"
confidence: "high"
source: "Specrew Feature 177 (Code & Implementation Lens, Proposal 163) — the implement-time half: read the design-time manifest and actively guide the coding agent. No 145 mechanical gate; guidance, not a gate."
---

# specrew-code-rules

**Type**: Implement-time Guidance Skill
**Schema**: v1
**Status**: Active implementation conduct

## Purpose

The code-implementation design lens captured this feature's implementation-craft rules at design time (the
`implementation-rules.yml` manifest). This skill is the **implement-time half**: while you write code, it
surfaces the chosen rules so the code reflects the agreed posture (DI, naming, size, error handling,
security-context, copy semantics, dependency stance, …) without the maintainer re-pasting rules. It is
**guidance, not a gate** — there is no mechanical conformance check; the value is that you actually follow
the rules as you write.

## The Big Picture (read this first, every time)

You are a **static reader**. You carry NO per-feature content yourself — you resolve it at read time:

1. **Resolve the active feature.** Read `.specrew/start-context.json` (`session_state.feature_ref` /
   `feature_path`) to find the active feature's `specs/<feature>/` directory.
2. **Read the per-feature manifest** `specs/<feature>/implementation-rules.yml` — the selected rule ids
   (checked/unchecked), per-rule decisions, the resolved stack, custom rules, and the `dependency_policy`.
3. **Read the canonical catalog** `extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml`
   (deployed under the project's design-lens catalog) to resolve each selected rule id to its text, and the
   optional **project overlay** `code-rules.local.yml` (additive + per-rule override; never drops a shipped
   rule) for the ingested company guideline / reusable custom rules.
4. **Compose BASELINE + OVERLAY** (below) and surface it **task-scoped** for the current work.

## Compose: baseline + overlay

- **BASELINE** — the catalog's `baseline-default` group ALWAYS applies (intent-revealing names, short
  methods, low nesting, DI as a principle, no magic numbers, guard object invariants, don't leak mutable
  internals, SOLID, idiomatic errors, …). Apply it even when there is **no manifest** (baseline-only mode).
- **OVERLAY** — when a manifest exists, layer the feature's choices on top: the selected `decision-prompt`
  rules + the human's per-rule `decision`, the applicable `applicability-filtered` rules, any `custom_rules`,
  and the `dependency_policy`. An **unchecked** baseline rule is a recorded exception — honor the exception.

## Surface it task-scoped (never a flat dump)

Pull only the group relevant to the current task/file, keyed by the manifest's selected groups + the
resolved stack:

- **writing a service** -> DI · DTO boundaries · idiomatic error handling + bounded retries ·
  authz / security-context flow · robustness/state boundaries.
- **writing a client / UI** -> render purity · never-block-the-event-loop · validation placement ·
  input controls that prevent invalid input.
- **writing concurrency** -> prefer concurrency over locks · explicit ordering/idempotency · normalize state.
- **writing an API / contract** -> protocol by shape · versioning · pagination/delivery · idempotency ·
  error envelope · public-API/reusable-code design posture.
- **repeated conditionals / polymorphism** -> Strategy/State over repeated branching; choose the
  polymorphism mechanism (functional vs inheritance/interfaces) deliberately.
- **per-stack** -> the `language:<stack>` rules for the resolved stack (e.g. C# nullable/file-scoped +
  analyzers; Go small interfaces + gofmt; Python typing + ruff/mypy; C/C++ ownership + clang-tidy/safety).

State the rules that bind THIS task, then write the code following them. Re-invoke for the next task/file.

## Dependency policy (FR-013)

Honor the manifest's `dependency_policy`:

- Default stance is **use existing project tools / no new dependency** — do NOT silently add a package.
- If the policy lists an approved dependency, follow its captured constraints (version, license posture,
  coupling/replaceability notes). If you believe a NEW dependency is needed and it is not in the policy,
  **surface that to the human** (it is a dependency-selection decision), do not just add it.

## Fail-open (never block, never crash)

- **No manifest** -> baseline-only mode (the catalog `baseline-default` rules). Say so briefly.
- **Unknown rule id** in the manifest (catalog changed) -> note it and skip that id; keep going.
- **Malformed manifest / overlay** -> warn and fall back to the shipped catalog baseline; never crash.

## When to Use

- At **implement** time — before and while writing source files. Re-invoke per task / file type so the
  surfaced rules match what you are writing.
- It is a reader: it never edits the manifest, the catalog, or itself. The workshop (design-time) writes the
  manifest; this skill only reads it.

## Review note

This skill is doing its job when, in a dogfood: the generated code visibly reflects the manifest's chosen
rules (DI posture, naming, size, the decided forks), the human did not have to re-paste rules, and a new
dependency was never added without surfacing the decision. That dogfood (on the deployed module) is the
acceptance gate (SC-004 / SC-007 / SC-008) — not unit-green.
