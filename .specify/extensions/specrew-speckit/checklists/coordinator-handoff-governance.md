# Coordinator Handoff Governance Checklist

## Purpose

This checklist is a **soft-warning** surface for coordinator top-level responses. Findings from this checklist should guide rewrites and review focus, but they do **not** hard-block response delivery on their own.

## Source Rule

Reference: `.specrew/quality/known-traps.md` row 12 (`human-handoff`)

The core user-facing risk is jargon-first handoff wording that hides the actual action a human needs to take.

## Soft-Warning Checks

| Check | Pass Condition | Soft Warning Trigger | Notes |
|---|---|---|---|
| Response-type selector | Real human blockers and long-work stops use the five-part context packet; in-flight work uses a single-line progress update | The response uses the context-packet format even though no immediate human action or handoff-worthy pause exists | Warn, suggest rewrite |
| Mixed transition handling | A mixed transition + true blocker response still uses the stop-message format because the human action wins | The response treats a real blocker as mere progress, or treats pure progress as a stop | Warn, suggest rewrite |
| In-flight progress shape | Progress-only updates stay as concise single-line prose with no user-action section | An in-flight update reuses the five-part context packet or invents a new structured format | Warn, suggest rewrite |
| Substantive stop action | A final stop message names one substantive immediate human action | The `What I need from you` section is empty or uses placeholder wording such as `Nothing yet` or `No action needed` | Warn with `soft-warning.empty-user-action-section` |
| Transitional stop reason | A final stop message's `Why I stopped` describes a real human blocker | `Why I stopped` is really just wait-state or transition narration | Warn with `soft-warning.transitional-stop-claim` |
| Plain-language-first lead | The lead sentence starts in human-readable language | The lead starts with three or more governance acronyms, lifecycle labels, or schema-field names without paraphrase | Warn, suggest rewrite |
| Current progress status present | The response clearly states what is complete, changed, verified, open, or blocked | No explicit progress statement is present | Warn, do not hard-fail |
| Recommended next step present | The response names one immediate next action | No explicit next step is present | Warn, do not hard-fail |
| Five-part stop context complete | Long-work and real-blocker final stop messages include `What I just did`, `Why I stopped`, `What needs your review`, `What happens next`, and `What I need from you` | One or more five-part context sections are missing | Warn with `soft-warning.incomplete-five-part-stop-context` |
| Readable identifier references | When authored prose contains three or more feature, iteration, task, requirement, corpus, or commit references, each one has inline descriptive scope or a valid shared scope statement | Three or more authored references appear without readable descriptive scope | Warn, do not hard-fail |
| Shared-scope grouping clarity | A grouped list or range uses one shared explanation only when the grouping is unmistakable | A grouped list relies on one explanation but the covered identifiers are ambiguous | Warn, request rewrite |
| Excluded verbatim surfaces stay excluded | Numeric references that appear only in quoted material, code blocks, raw tool output, or Copilot-rendered tool-call result blocks are ignored | The review counts excluded verbatim content toward the descriptive-reference warning | Warn, request rewrite |
| Review file reference format | If the next step is local file review, the response includes a `file:///` URI resolved from the current project's absolute path | The response points the reviewer at a local file with only a plain path or no navigation-ready URI | Warn, request rewrite |
| Thin "What I just did" | Planning / implementation / review / retro handoffs include at least 3 identifiers and at least 50 words; iteration-closeout / feature-closeout include at least one of those thresholds | The section is too thin for the active boundary | Warn with `soft-warning.thin-what-i-just-did` |
| Specific stop boundary | `Why I stopped` names the exact boundary that is being entered and matches the active iteration state | The boundary is generic, missing, or contradicts the active iteration state | Warn with `soft-warning.unspecific-stop-boundary` |
| Actionable boundary request | `What I need from you` names the boundary, includes `file:///` inspection targets, and requests a verdict | One or more of `boundary-name`, `inspection-target`, or `verdict-required` is missing | Warn once with `soft-warning.unactionable-user-request` |
| Click-through file references | Artifact references in authored narration and stop messages use `file:///` outside exempt contexts, and cited files exist | Bare paths appear outside exemptions or a `file:///` target is broken | Warn with `soft-warning.bare-path-in-*` / `soft-warning.broken-file-url-reference` |
| Post-commit verification truth | Boundary handoffs that claim implementation-ready or review-ready state disclose commit-reference sync, exact-tree reruns, and stale-reference scan status | The handoff implies post-commit verification happened but omits whether the ledger was synchronized, the exact-tree rerun happened, or the stale-reference scan was clean | Warn, request explicit post-commit verification status |
| Blocker / risk disclosure | If blockers, skipped checks, failed checks, or known risks exist, the response states them plainly | The response hides or omits a known blocker or risk | Warn, request clarification |

## Review Method

### 1. Response-Type Selector Check

- Ask whether a real immediate human action is required now.
- If yes, require the five-part context packet.
- If no, require a concise single-line progress update instead.

### 2. Mixed-Case Check

- If a response includes both transition narration and a real human blocker, treat it as a stop message.
- If the response only describes internal waiting or background work, treat it as an in-flight progress update.

### 3. Plain-Language-First Check

- Inspect the lead sentence of each handoff section.
- If the lead opens with governance-heavy wording, rewrite it in plain English first.
- Formal references may appear later in the section.

### 4. Current Progress Status Check

Confirm the response answers:

- What happened?
- What changed or was reviewed?
- What is complete, open, or blocked?

### 5. Recommended Next Step Check

Confirm the response answers:

- What is the single best immediate action?
- Who owns it when ownership matters?

For in-flight progress updates, the forward-motion clause can satisfy this check when it clearly states what Squad will continue doing next.

### 6. Blocker / Risk Disclosure Check

If any of these exist, they must be visible:

- blocker
- deferred decision
- skipped or failed validation
- known risk

### 7. Readable Identifier Reference Check

When the authored prose contains three or more identifiers:

- confirm feature, iteration, task, requirement, corpus-row, and commit references are readable on first pass
- allow one shared scope statement only when the whole grouped list is clearly labeled
- confirm commit references include a why-it-matters phrase

### 8. Excluded-Surface Check

When identifiers appear only inside excluded verbatim content:

- do not count them toward the descriptive-reference warning
- ignore quoted material, fenced code blocks, raw tool output, and Copilot-rendered tool-call result blocks
- only authored prose should affect the soft warning

### 9. Review File Reference Check

When the next step is to review a local repository file in this Windows environment:

- confirm the response includes a `file:///` URI
- confirm the URI resolves from the current project's absolute path
- allow additional fallbacks, but do not accept plain paths as the only review reference

## Executable Heuristics

- Missing progress status = `soft-warning.missing-progress-status`
- Missing next step = `soft-warning.missing-next-step`
- Missing five-part stop context section = `soft-warning.incomplete-five-part-stop-context`
- Empty or placeholder stop-message action = `soft-warning.empty-user-action-section`
- Transitional waiting narrated as a stop = `soft-warning.transitional-stop-claim`
- Three-or-more opaque authored references = `soft-warning.opaque-numeric-references`
- Missing `file:///` review URI for local file review = `soft-warning.review-file-reference-format`
- Three-or-more governance labels in the lead without paraphrase = `soft-warning.jargon-first-lead`
- Hidden blocker or verification gap = `soft-warning.hidden-blocker-or-risk`
- Thin boundary summary = `soft-warning.thin-what-i-just-did`
- Missing or mismatched stop boundary = `soft-warning.unspecific-stop-boundary`
- Missing boundary-name / inspection-target / verdict-required = `soft-warning.unactionable-user-request`
- Bare path or broken `file:///` reference = `soft-warning.bare-path-in-*` / `soft-warning.broken-file-url-reference`
- Hidden post-commit verification status = `soft-warning.hidden-post-commit-verification`

## Reviewer Notes

- This checklist is intentionally human-reviewable and soft-validator-friendly.
- It supports compact handoffs as long as the five context fields remain explicit: progress, stop reason, review context, resume path, and immediate action.
- The descriptive-reference rule is additive and remains non-blocking.
- Use it to improve clarity, not to replace reviewer judgment.
