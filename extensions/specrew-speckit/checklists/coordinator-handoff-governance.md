# Coordinator Handoff Governance Checklist

## Purpose

This checklist is a **soft-warning** surface for final coordinator responses. Findings from this checklist should guide rewrites and review focus, but they do **not** hard-block response delivery on their own.

## Source Rule

Reference: `.specrew/quality/known-traps.md` row 12 (`human-handoff`)

The core user-facing risk is jargon-first handoff wording that hides the actual action a human needs to take.

## Soft-Warning Checks

| Check | Pass Condition | Soft Warning Trigger | Notes |
|---|---|---|---|
| Plain-language-first lead | The lead sentence starts in human-readable language | The lead starts with three or more governance acronyms, lifecycle labels, or schema-field names without paraphrase | Warn, suggest rewrite |
| Current progress status present | The response clearly states what is complete, changed, verified, open, or blocked | No explicit progress statement is present | Warn, do not hard-fail |
| Recommended next step present | The response names one immediate next action | No explicit next step is present | Warn, do not hard-fail |
| Readable identifier references | When authored prose contains three or more feature, iteration, task, requirement, corpus, or commit references, each one has inline descriptive scope or a valid shared scope statement | Three or more authored references appear without readable descriptive scope | Warn, do not hard-fail |
| Shared-scope grouping clarity | A grouped list or range uses one shared explanation only when the grouping is unmistakable | A grouped list relies on one explanation but the covered identifiers are ambiguous | Warn, request rewrite |
| Excluded verbatim surfaces stay excluded | Numeric references that appear only in quoted material, code blocks, raw tool output, or Copilot-rendered tool-call result blocks are ignored | The review counts excluded verbatim content toward the descriptive-reference warning | Warn, request rewrite |
| Review file reference format | If the next step is local file review in this Windows workflow, the response includes a `file:///` URI using the absolute Windows path | The response points the reviewer at a local file with only a plain path or no navigation-ready URI | Warn, request rewrite |
| Blocker / risk disclosure | If blockers, skipped checks, failed checks, or known risks exist, the response states them plainly | The response hides or omits a known blocker or risk | Warn, request clarification |

## Review Method

### 1. Plain-Language-First Check

- Inspect the lead sentence of each handoff section.
- If the lead opens with governance-heavy wording, rewrite it in plain English first.
- Formal references may appear later in the section.

### 2. Current Progress Status Check

Confirm the response answers:

- What happened?
- What changed or was reviewed?
- What is complete, open, or blocked?

### 3. Recommended Next Step Check

Confirm the response answers:

- What is the single best immediate action?
- Who owns it when ownership matters?

### 4. Blocker / Risk Disclosure Check

If any of these exist, they must be visible:

- blocker
- deferred decision
- skipped or failed validation
- known risk

### 5. Readable Identifier Reference Check

When the authored prose contains three or more identifiers:

- confirm feature, iteration, task, requirement, corpus-row, and commit references are readable on first pass
- allow one shared scope statement only when the whole grouped list is clearly labeled
- confirm commit references include a why-it-matters phrase

### 6. Excluded-Surface Check

When identifiers appear only inside excluded verbatim content:

- do not count them toward the descriptive-reference warning
- ignore quoted material, fenced code blocks, raw tool output, and Copilot-rendered tool-call result blocks
- only authored prose should affect the soft warning

### 7. Review File Reference Check

When the next step is to review a local repository file in this Windows environment:

- confirm the response includes a `file:///` URI
- confirm the URI uses the absolute Windows path
- allow additional fallbacks, but do not accept plain paths as the only review reference

## Executable Heuristics

- Missing progress status = `soft-warning.missing-progress-status`
- Missing next step = `soft-warning.missing-next-step`
- Three-or-more opaque authored references = `soft-warning.opaque-numeric-references`
- Missing `file:///` review URI for local file review = `soft-warning.review-file-reference-format`
- Three-or-more governance labels in the lead without paraphrase = `soft-warning.jargon-first-lead`
- Hidden blocker or verification gap = `soft-warning.hidden-blocker-or-risk`

## Reviewer Notes

- This checklist is intentionally human-reviewable and soft-validator-friendly.
- It supports compact handoffs as long as both semantic fields remain explicit.
- The descriptive-reference rule is additive and remains non-blocking.
- Use it to improve clarity, not to replace reviewer judgment.
