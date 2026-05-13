---
name: "multi-artifact-governance-principle-embedding"
description: "Embed critical governance principles into multiple artifacts for durability across document updates and session boundaries"
domain: "governance"
confidence: "high"
source: "earned"
tools:
  - name: "edit"
    description: "Update multiple related documents to ensure consistent principle embedding"
    when: "When codifying a governance principle that spans coordinator guidance, checklists, validators, and documentation"
  - name: "grep"
    description: "Search for principle expressions across artifacts to verify durability coverage"
    when: "When validating that a principle is present in all intended locations"
---

## Context

When embedding a critical governance principle (like plain-language-first or jargon-early detection), do not rely on a single artifact or checklist. Instead, embed the principle into multiple complementary artifacts so that even if one gets skipped, outdated, or misunderstood, the principle survives in the others.

Iteration 001 (feature 007) discovered this pattern when codifying the governance-acronym detection rule (three-or-more governance acronyms in lead without plain-language paraphrase). The rule was embedded in:
1. **Coordinator prompt** (T001): Plain-language guardrail + examples showing how to lead with human terms
2. **Handoff template** (T002): Concrete copy-paste patterns demonstrating plain-language-first structure
3. **Governance checklist** (T005): Soft-warning check operationalizing the detection rule
4. **Soft-validator design** (T006): Pseudo-code and algorithmic definition of the detection logic

This four-artifact redundancy ensures that:
- Agents reading only the prompt get the guardrail and examples
- Reviewers reading only the template see validated patterns
- Governance reviewers reading only the checklist get the detection rule
- Implementers reading only the validator design get the algorithmic definition

No single document path leads to the principle being skipped.

## Patterns

- **Map the principle to its owners.** Identify which roles (agents, reviewers, implementers, governance) interact with the principle. Embed guidance in artifacts those roles naturally read.
- **Separate implementation guidance from detection rules.** Agents need to understand "how to do it" (prompt + template). Governance tools need to understand "how to detect violations" (checklist + validator). Both groups benefit from the same principle but consume different artifact forms.
- **Use redundancy strategically.** Don't duplicate word-for-word. Instead, express the principle at different levels of abstraction:
  - **Prompt**: Plain human guidance with examples ("Do not open with three or more acronyms without first explaining them")
  - **Template**: Concrete copy-paste patterns showing compliant and non-compliant forms
  - **Checklist**: Operationalized check ("Count governance acronyms in lead. If ≥3 and no paraphrase, flag as soft warning")
  - **Validator design**: Algorithmic definition with pseudo-code and edge cases
- **Verify coverage before governance publication.** Before closing an iteration, search for the principle across all artifacts. Verify it appears in at least 2-3 independent artifact types. Single-artifact principles are fragile.
- **Document the multi-artifact strategy in the feature spec or plan.** Make explicit that "this principle is embedded in X, Y, Z artifacts" so future maintainers know which documents to update if the principle needs refinement.

## Examples

- **Iteration 001 (feature 007, plain-language-first principle)**:
  - Prompt (`coordinator-response.md`, line 32): "Do not open with three or more governance acronyms, schema-field names, or lifecycle labels without first paraphrasing them in human terms."
  - Template (`coordinator-handoff-template.md`): Examples show "What I just did [plain-language summary of work]" before diving into governance details
  - Checklist (`coordinator-handoff-governance.md`, check #1): "Plain-language-first lead: Is the first sentence of the response in human terms, not governance vocabulary?"
  - Validator design (`soft-validator-handoff-governance.md`, Rule 3): Pseudo-code counts governance terms and flags responses with 3+ acronyms in lead without paraphrase
  - **Result**: Zero ambiguity across agent prompts, reviewer checklists, and governance tooling about what plain-language-first means.

## Anti-Patterns

- **Single-artifact embedding**: Putting a governance principle only in the checklist (and nowhere else) risks agents not knowing the principle exists because they don't read checklists.
- **Duplicate exact wording across artifacts**: This creates maintenance debt. If the principle needs refinement, 10 copies must be updated in perfect synchrony.
- **Embedding guidance where the role doesn't read it**: Putting governance rules only in the coordinator prompt (where agents read) and nowhere in the validator or checklist (where governance tools live) means validation tools can't operationalize the rule.
- **Assuming session context preserves principle awareness**: Principles embedded only in post-review artifacts or session-specific prompts may not survive session boundaries. Embed in git-tracked, reviewable documents for durability.

## How to Apply

1. **Identify the principle**: Name the governance rule or behavior you want to codify (e.g., "plain-language-first", "jargon-detection", "three-section format").
2. **Identify the artifacts that already exist or will be created** for implementation, review, governance, and documentation.
3. **Assign principle expressions to each artifact type**:
   - **Implementation guidance** (prompts, templates): Plain-language guardrails and copy-paste examples
   - **Review guidance** (checklists, decision trees): Operational checks and risk indicators
   - **Governance tooling** (validators, detection rules): Algorithmic definitions and pseudo-code
   - **Documentation** (design docs, spec sections): Formal definition and rationale
4. **Verify coverage**: Use grep or manual search to confirm the principle appears in at least 2-3 independent artifacts.
5. **Document the multi-artifact strategy** in planning or design artifacts so maintainers know where to look and update.

## Governance Reference

- **Source**: Iteration 001 retrospective (feature 007, 2026-05-11). Plain-language-first principle embedded in T001 (prompt), T002 (template), T005 (checklist), T006 (validator design).
- **Known trap reference**: `.specrew/quality/known-traps.md` row 12 (`human-handoff` — three-or-more governance acronyms in lead without paraphrase)
