# Forge-Neutralization Migration Inventory (Iteration 3 / FR-019)

**Feature**: 182-work-kind-branch-governance · **Iteration**: 003 · **Date**: 2026-06-12
**Source of truth**: [Iteration-1 forge-coupling inventory](../001/forge-coupling-inventory.md) (T012), augmented
by a planning-time sweep across ALL surface types the maintainer named (lifecycle prompts, skills,
extension scripts, charters, lens content, CI templates, downstream-governing docs).

## Scope guardrail (binding)

Iteration 3 is the **downstream-governance neutralization slice ONLY** — NOT a general GitHub cleanup.
A surface is in scope to **change** ONLY if it is a Specrew-*deployed*, downstream-*governing* surface
that prescribes Specrew's own GitHub-dev habits (`gh pr create`, Copilot-as-mandate,
`Find-Module/Install-Module Specrew`) as the downstream flow. Three things are explicitly OUT of scope:

- **Specrew's own dev infra** (`.github/`, `publish-module.yml`, Specrew's own repo URL, the
  `specrew-version` skill, `deploy-speckit-extension.ps1`) — the maintainer's rule: do not change
  Specrew's own GitHub usage.
- **The GitHub host adapter** (`templates/github/**`) — host-specific by design; a non-GitHub host does
  not deploy it.
- **False positives** — code comments, host-instruction file references, agent seed-histories.

## Disposition legend

- **change** — a confirmed downstream-governing coupling to neutralize this iteration.
- **no-change** — inspected; either out-of-scope (own-infra / host-specific) or already forge-neutral.
- **inspect-only** — re-verify at implementation before deciding; carries an open question for the
  before-implement gate.

## A. CHANGE — confirmed downstream-governing coupling (G1–G5 from the Iter-1 inventory)

| ID | Surface | Kind | Coupling | Neutralization |
| --- | --- | --- | --- | --- |
| G1 | `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md` (feature-closeout steps) | methodology-wording | `gh pr create` + `Find-Module/Install-Module Specrew` as the downstream closeout SDLC | Make project-agnostic + forge-neutral: PR/MR "via your forge (the adapter describes how)"; "publish/tag per the project's own release mechanism"; address the project's `review_gate`. |
| G2 | `extensions/specrew-speckit/prompts/coordinator-response.md` (release-SDLC steps) | methodology-wording | Same closeout SDLC prose as G1 | Same as G1. |
| G3 | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (Steps 5–14) | methodology-wording | Same closeout SDLC prose as G1 | Same as G1. |
| G4 | The lifecycle-prompt Rule 46/47 feature-closeout `AGENT NEXT ACTION` block (generated from G1–G3) | methodology-wording (regenerate, not hand-edit) | Generated "Step 6 `gh pr create`", "check Copilot's PR review" mandate | Regenerate from the neutralized G1–G3; verify the deployed block carries no GitHub-only mandate; Copilot becomes opt-in `review_gate.automated_review`. |
| G5 | `extensions/specrew-speckit/scripts/shared-governance.ps1` PR-review-integration (`Resolve-*Reviewer` → `copilot-pull-request-reviewer`) | runtime/script | GitHub-specific automated-reviewer detection assumed present | Route reviewer detection through the adapter's capability model; Copilot is a GitHub-adapter opt-in suggestion, not a baked-in reviewer. |

## B. DELTA — coupling the Iter-1 sweep MISSED (new finding; recorded, not silently folded in)

| ID | Surface | Kind | Coupling | Disposition |
| --- | --- | --- | --- | --- |
| D1 | `docs/methodology/lifecycle-discipline.md` (lines ~143–148, the release-SDLC table) | methodology-wording (doc) | Same `gh pr create` + "Read Copilot's automated PR review" + `Install-Module Specrew -AllowPrerelease` closeout SDLC as G1–G3, in a downstream-referenced methodology doc (a refocus deep-source) | **inspect-only → human ruling at before-implement.** The table sits beside a Specrew-own "Project Coordinates" section (`https://github.com/alonf/specrew`). Question: is the SDLC table downstream-governing (label/neutralize as a non-mandatory example) OR a Specrew-own dev-doc section (exclude per the own-infra rule)? Recommendation: label it a non-mandatory GitHub example (the doc is downstream-referenced), keeping the general methodology forge-neutral — but the maintainer decides. |

## C. NO-CHANGE — own-infra / host-specific (inspected, out of scope)

| Surface | Why excluded |
| --- | --- |
| `extensions/specrew-speckit/squad-templates/skills/specrew-version/SKILL.md` (`Update-Module Specrew`) | Specrew's OWN version-check skill — its own publish/update mechanism, not a downstream mandate. |
| `extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1:398` (`Install-Module Specrew -Force` repair hint) | Specrew's OWN installer/repair message. |
| `templates/github/agents/squad.agent.md` (`gh pr`, `@copilot`) | The GitHub host adapter's deployed agent — host-specific by design. |
| `templates/github/workflows/specrew-ci.yml`, `specrew-confidence-lane.yml` (`git+https://github.com/github/spec-kit.git`) | GitHub host-adapter CI templates + the spec-kit dependency genuinely lives on GitHub. |
| `docs/release-discipline.md`, `README.md`, `docs/**` (Specrew's own release/usage docs), `.github/workflows/**`, `publish-module.yml` | Specrew's OWN release/CI infra (maintainer's exclusion rule). |
| `templates/squad/agents/*/history.md`, `picard/alignment-review-validator-fix.md` | Star-Trek-named agent seed-histories / examples — false positives. |

## D. NO-CHANGE — already forge-neutral (iter-1 work; re-verify in the SC-008 sweep)

| Surface | Current state |
| --- | --- |
| `extensions/specrew-speckit/knowledge/design-lenses/devops-operations.md:109` | Already opt-in: "suggest Copilot the way Specrew uses it — the user decides in the workshop". Neutral. |
| `templates/work-kind/repository-governance.yml:34` | Already opt-in: `provider_suggestion: copilot  # GitHub only; the adapter MAY suggest it`. Neutral. |
| `docs/methodology/work-kinds.md:47` | Already opt-in: "on GitHub the adapter may *suggest* Copilot; the user decides". Neutral. |
| `extensions/specrew-speckit/squad-templates/agents/{reviewer,spec-steward,planner,implementer,retro-facilitator}/charter.md` | Swept — NO coupling matches. Clean. |
| `extensions/specrew-speckit/squad-templates/skills/design-workshop.md` | "Copilot" refers to the Copilot **host** (menu-rendering behavior), not GitHub PR review. False positive. |
| `docs/methodology/review-instructions.md` | "GitHub Spec Kit" = product description; `.github/copilot-instructions.md` = host-instructions file; host list. No downstream forge-mandate. |

## E. Open decisions for the before-implement gate

- **DP-1 (GitHub-specifics relocation):** where do the concrete GitHub + beta-publish steps go once the
  prose is genericized? **Option (a)** relocate to a new GitHub-adapter surface (richer, but risks the
  "general cleanup" scope-creep the guardrail forbids); **Option (b, recommended)** genericize the
  closeout *shape* and keep GitHub + PSGallery as a clearly-labeled **non-mandatory example** that a
  project's `provider: github` + its release config instantiate. Either way, **verification MUST prove
  Specrew's own GitHub + beta-publish closeout still works** (Specrew dogfoods these same surfaces).
- **DP-2 (D1 disposition):** rule `lifecycle-discipline.md`'s release-SDLC table as downstream-governing
  (T303 neutralizes/labels it) or Specrew-own (T303 records the exclusion).

## Magnitude

**5 confirmed coupling items (G1–G5)** + **1 delta (D1, pending disposition)**, concentrated in the
shared closeout-SDLC prose (4 surfaces generating one Rule 46/47 block) + one script (G5). The migration
is bounded; the split-to-sibling escape hatch is not expected to be needed.
