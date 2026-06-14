# Forge-Coupling Inventory (T012 / FR-019)

**Feature**: 182-work-kind-branch-governance · **Iteration**: 001 · **Date**: 2026-06-11

The audit of Specrew's **downstream-governing** surfaces (the lifecycle prompt, deployed skills,
extension scripts, charters, lens content, deployed CI templates) for Specrew's own GitHub-dev-habit
coupling. **Specrew's OWN dev infra is explicitly EXCLUDED** (its `.github/` CI, its `docs/`/README,
its release workflows stay GitHub — the maintainer's rule). The migration of the genuine items is
**Iteration 3** (T021); out-of-surface coupling is recorded here as tight follow-ups, not silently
dropped.

## Genuine downstream coupling — migrate in Iter 3 (behind the ProviderAdapter / make project-agnostic)

| # | Surface | Coupling | Iter-3 disposition |
| --- | --- | --- | --- |
| G1 | `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md` (feature-closeout steps) | Prescribes `gh pr create`, merge-commit, **and Specrew-specific `Find-Module Specrew` / `Install-Module Specrew`** as the downstream closeout flow — doubly coupled (GitHub + Specrew-publish) | Make project-agnostic + forge-neutral: "create the PR/MR via your forge (the adapter describes how)", "address the project's `review_gate`", "publish/tag per the project's own release mechanism". GitHub specifics move to the GitHub adapter. |
| G2 | `extensions/specrew-speckit/prompts/coordinator-response.md` (release-SDLC steps) | Same `gh pr create` + `Find-Module/Install-Module Specrew` closeout steps | Same as G1 (shared closeout-step source). |
| G3 | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (Step 5–14) | Same `gh pr create` + Specrew-publish closeout steps | Same as G1. |
| G4 | The **lifecycle prompt** Rule 46/47 feature-closeout `AGENT NEXT ACTION` block (generated from the coordinator-governance source above) | The "Step 6 create the PR with `gh pr create`", "Step 7 … address automated PR review", "check Copilot's PR review" mandate | The "check Copilot PR review" becomes an **opt-in `review_gate.automated_review`** (already modelled in Iter 1); the PR/merge steps become forge-neutral via the adapter. |
| G5 | `extensions/specrew-speckit/scripts/shared-governance.ps1` PR-review-integration (`Resolve-*Reviewer` → `copilot-pull-request-reviewer`) | GitHub-specific automated-reviewer detection assumed present | Route reviewer detection through the adapter's capability model; Copilot is a GitHub-adapter opt-in suggestion, not a baked-in reviewer. |

## Host-specific — NOT a forge-neutrality violation (recorded, not migrated)

| Surface | Why it's acceptable |
| --- | --- |
| `templates/github/agents/squad.agent.md` (`gh pr list/create/merge`, `@copilot`) | This is the **GitHub host adapter's** deployed agent. A non-GitHub host does not deploy it; it is host-specific by design, not a leak into the forge-neutral methodology. Leave as-is. |

## False positives (no coupling)

- `shared-governance.ps1` / `validate-governance.ps1` lines `# Per Copilot review on PR #594/#661/#695` — **code comments** crediting past Copilot PR-review findings; not runtime coupling.
- `Test-CopilotInstructionsChangeType.ps1` + `.github/copilot-instructions.md` references — about the **Copilot host's instructions file**, not GitHub PR coupling.
- `templates/squad/agents/*/history.md` — example/seed **agent histories** (Star-Trek-named).
- `coordinator-handoff-governance.md:27` — *excludes* Copilot-rendered tool-call blocks from a check; not coupling.

## Out-of-surface / Specrew's own infra — EXCLUDED (the maintainer's rule)

- `docs/release-discipline.md`, `README.md`, `docs/**` — Specrew's **own** release/usage docs.
- `.github/workflows/**`, `publish-module.yml` — Specrew's **own** CI/release.
- `Find-Module/Install-Module Specrew` *as Specrew's own publish* — stays; only its leakage into the
  **downstream-governing** closeout steps (G1–G4) is migrated.

## Magnitude

**5 genuine downstream-coupling items** (G1–G5), concentrated in the closeout-SDLC source (3 files
that generate the same Rule 46/47 block) + PR-review-integration. This matches the Iter-1 estimate
(~10–15 files was the upper bound; the real count is tighter because G1–G4 share one closeout-step
source). The Iter-3 migration is therefore bounded; the split-to-sibling escape hatch is unlikely to
be needed but remains available.
