# Quality Evidence: Iteration 001

**Profile Ref**: `quality-profile.pending`
**Preset Refs**: (pending preset selection)
**Findings Ref**: `specs/205-workshop-lens-order/iterations/001/quality/mechanical-findings.json`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-11-09T23:55:59Z

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| `dead-field` | mechanical quality bar, unused-state hygiene | `specs/205-workshop-lens-order/iterations/001/quality/mechanical-findings.json` | `planned` | `—` |
| `anti-pattern` | mechanical quality bar, deterministic anti-pattern scan | `specs/205-workshop-lens-order/iterations/001/quality/mechanical-findings.json` | `planned` | `—` |
| `test-integrity` | mechanical quality bar, assertion-driven tests | `specs/205-workshop-lens-order/iterations/001/quality/mechanical-findings.json` | `planned` | `—` |
| `stack-tooling-evidence` | stack tooling evidence | `specs/205-workshop-lens-order/iterations/001/quality/quality-evidence.md` | `planned` | `—` |
| `quality-lens-review` | quality-lens review | `specs/205-workshop-lens-order/iterations/001/quality/quality-evidence.md` | `planned` | `—` |

## T003 — parity test red-first on the unchanged tree (SC-001)

**Run**: 2026-11-10, `pwsh -NoProfile -File tests/unit/lens-order-parity.tests.ps1` at `12837d26` (before any surface change), exit 1.
**Self-tests**: 22 of 22 passed (every plan.md "matches" and "does not match" example, a seeded multi-mismatch tree, stale-copy detection with the project-only fix).

```text
index.yml order: product-domain, architecture-core, requirements-nfr, data-storage, ui-ux, devops-operations, integration-api, security-compliance, observability-resilience, component-design, code-implementation
Checked: 5 full surfaces, 428 swept files (13 runs), 11 lens files, 20 deployed copies.
lens-order-parity: 72 mismatch(es):
```

All five known order definitions are reported: the skill list, the methodology catalog tables and visual-vocabulary
table, the catalog README (which lists 9 of 11 lenses) and the before-specify command list. No deployed copy is stale.
The sweep found six runs outside the named surfaces, all reported against the current (old) `index.yml` order:

- `applicability-map.json` lines 5 (always_on) and 10 (questions)
- `diagram-vocabulary.json` line 5
- `product-domain.md` line 118
- `design-workshop.md` line 261
- `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1` line 589, a comment that names an example set of lenses in a file that feature 203 changes heavily (an exemption candidate, brought to the maintainer)

| File | Mismatches |
| --- | --- |
| `.agents/skills/specrew-design-workshop/SKILL.md` | 2 |
| `.claude/skills/specrew-design-workshop/SKILL.md` | 2 |
| `.cursor/rules/specrew-design-workshop/SKILL.md` | 2 |
| `.github/skills/specrew-design-workshop/SKILL.md` | 2 |
| `.specify/extensions/specrew-speckit/squad-templates/skills/design-workshop.md` | 2 |
| `docs/methodology/design-workshop-methodology.md` | 2 |
| `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-specify.md` | 1 |
| `extensions/specrew-speckit/knowledge/design-lenses/applicability-map.json` | 2 |
| `extensions/specrew-speckit/knowledge/design-lenses/architecture-core.md` | 4 |
| `extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md` | 3 |
| `extensions/specrew-speckit/knowledge/design-lenses/component-design.md` | 3 |
| `extensions/specrew-speckit/knowledge/design-lenses/data-storage.md` | 4 |
| `extensions/specrew-speckit/knowledge/design-lenses/devops-operations.md` | 3 |
| `extensions/specrew-speckit/knowledge/design-lenses/diagram-vocabulary.json` | 1 |
| `extensions/specrew-speckit/knowledge/design-lenses/index.yml` | 11 |
| `extensions/specrew-speckit/knowledge/design-lenses/integration-api.md` | 4 |
| `extensions/specrew-speckit/knowledge/design-lenses/observability-resilience.md` | 3 |
| `extensions/specrew-speckit/knowledge/design-lenses/product-domain.md` | 4 |
| `extensions/specrew-speckit/knowledge/design-lenses/README.md` | 1 |
| `extensions/specrew-speckit/knowledge/design-lenses/requirements-nfr.md` | 4 |
| `extensions/specrew-speckit/knowledge/design-lenses/security-compliance.md` | 4 |
| `extensions/specrew-speckit/knowledge/design-lenses/ui-ux.md` | 3 |
| `extensions/specrew-speckit/squad-templates/skills/design-workshop.md` | 4 |
| `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1` | 1 |

## T017 — baseline of every existing workshop test on the unchanged tree (FR-021)

**Run**: 2026-11-10 at `854ed59d` (tests only; no product file changed), out of process, one `pwsh` per file (Pester for `Describe` files), under the existing-test safety rule.
**Screen**: 31 files matched (workshop, lens, agenda, design-analysis, product-domain, code-implementation). None writes to the home folder or global locations. Throwaway fixtures in the OS temp folder are allowed (the maintainer confirmed this reading). `workshop-material-packet-language` runs `git commit` only inside its own temp fixture repo.
**Home hook files**: 6 hashed before and after every run (`~/.specrew/specrew-hook-launch.ps1`, `~/.specrew/hook-bindings/antigravity-6ad8359f…binding`, `~/.codex/hooks.json`, `~/.cursor/hooks.json`, `~/.copilot/hooks/specrew-refocus.json`, `~/.copilot/hooks/specrew-walk-capture.json`). All were unchanged after every run.

**cross-host-workshop.tests.ps1** was screened out first because it deploys hooks, then reviewed at the maintainer's request:

- The test has one deploy call, `deploy-refocus-hooks.ps1 … -UserHomeOverride $userHome` at line 59, where `$userHome` is a temp folder.
- The deployer resolves every `~/` path and the launcher path from that override (`deploy-refocus-hooks.ps1:28, 105, 116, 261`).
- The spawned hooks run the scratch project's dispatcher. Its only write (the hook-health marker) lands in the scratch project's `.specrew/runtime`.
- All writes were covered. The 6 home files were backed up to the scratchpad, hashed, and the test was run: **PASS**, with 0 hashes changed and 0 new files in the hook folders.

**Result**: 30 PASS, 1 FAIL. The one failure is `workshop-agenda-confirmation`, which is T004's red-first state, and every one of its pre-existing assertions passes.

| Test | Result | Time | Note |
| --- | --- | --- | --- |
| `tests/bootstrap/HandoverGateWorkshop.Tests.ps1` | PASS | 1s |  |
| `tests/bootstrap/WorkshopDecisionRecap.Tests.ps1` | PASS | 1s |  |
| `tests/bootstrap/WorkshopHostDetection.Tests.ps1` | PASS | 9s |  |
| `tests/integration/agent-led-workshop-replay.tests.ps1` | PASS | 70s |  |
| `tests/integration/design-analysis-boundary.tests.ps1` | PASS | 17s |  |
| `tests/integration/design-workshop-claude-tool-safety.tests.ps1` | PASS | 5s |  |
| `tests/integration/governed-feature-workshop-controller.tests.ps1` | PASS | 3s |  |
| `tests/integration/product-domain-multihost.tests.ps1` | PASS | 0s |  |
| `tests/integration/specify-workshop-routing.tests.ps1` | PASS | 3s |  |
| `tests/integration/workshop-agenda-confirmation.tests.ps1` | FAIL | 14s | T004 red-first by design (FR-016 cases fail until T005/T007) |
| `tests/integration/workshop-agenda-vocabulary.tests.ps1` | PASS | 6s |  |
| `tests/integration/workshop-controller-initialization.tests.ps1` | PASS | 1s |  |
| `tests/integration/workshop-intake-completion-survives-agenda.tests.ps1` | PASS | 1s |  |
| `tests/integration/workshop-lens-checkpoint.tests.ps1` | PASS | 13s |  |
| `tests/integration/workshop-material-packet-language.tests.ps1` | PASS | 15s |  |
| `tests/integration/workshop-resolve-prefers-open-feature.tests.ps1` | PASS | 4s |  |
| `tests/integration/workshop-state-transition-table.tests.ps1` | PASS | 1s |  |
| `tests/integration/workshop-typed-turn-authority.tests.ps1` | PASS | 5s |  |
| `tests/unit/code-implementation-lens.tests.ps1` | PASS | 1s |  |
| `tests/unit/cross-host-workshop.tests.ps1` | run separately: PASS | — | see below |
| `tests/unit/design-analysis-gate-refusal.tests.ps1` | PASS | 1s |  |
| `tests/unit/design-analysis-gate.tests.ps1` | PASS | 1s |  |
| `tests/unit/design-gate-code-implementation-artifact.tests.ps1` | PASS | 1s |  |
| `tests/unit/lens-acknowledgment.tests.ps1` | PASS | 1s |  |
| `tests/unit/lens-applicability-selector.tests.ps1` | PASS | 1s |  |
| `tests/unit/lens-conduct-delivery.tests.ps1` | PASS | 0s |  |
| `tests/unit/product-domain-lens.tests.ps1` | PASS | 1s |  |
| `tests/unit/workshop-confirm-not-bound.tests.ps1` | PASS | 4s |  |
| `tests/unit/workshop-delegation.tests.ps1` | PASS | 50s |  |
| `tests/unit/workshop-question-tool.tests.ps1` | PASS | 1s |  |
| `tests/unit/workshop-refusal-contract.tests.ps1` | PASS | 1s |  |

## T012 — parity and agenda tests green (SC-001, SC-002, SC-003, SC-004)

**Run**: 2026-11-10, after T005 to T011 and the maintainer's exemption ruling. `worktree-reviewer.ps1` is restored to origin/main.

```text
index.yml order: product-domain, requirements-nfr, ui-ux, security-compliance, data-storage, integration-api, devops-operations, architecture-core, component-design, observability-resilience, code-implementation
Exemptions:
  extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 /\(\?:[a-z-]+\|/ - Order has no meaning in a regex alternation; the file is owned by feature 203 T011 and is not edited here.
  scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1 /workshop holds architecture-core, requirements-nfr, security-compliance, product-domain/ - A comment naming lenses a workshop holds, not an order; the file is under active change in feature 203 (T008) and is not edited here. Temporary: after feature 203 merges, reorder the comment and remove this exemption.
  scripts/internal/continuous-co-review/worktree-reviewer.ps1 /requirements/NFR, data-storage, security-compliance, integration/API/ - The reviewer's prompt text (a short-name lens list, recorded for iteration 3); feature 203's folder, where a changed file can make the review launch refuse with a runtime-drift error (203 DRIFT-051). Not edited here.
Checked: 5 full surfaces, 428 swept files (13 runs), 11 lens files, 22 deployed copies.
lens-order-parity: all checks passed
```

- **Parity**: 22 of 22 self-tests pass, and the repository check passes. It went from 72 mismatches on the unchanged tree to 0.
- **SC-002**: the extractor counts match the expected table for all 11 lenses (product-domain 0, requirements-nfr 6, ui-ux 6, security-compliance 6, data-storage 7, integration-api 7, devops-operations 7, architecture-core 4, component-design 5, observability-resilience 6, code-implementation 7). Each bullet-list lens returns exactly the points under its two sub-headings, and product-domain's 8 numbered points are proven tagged by the test's own count.
- **SC-003**: the exemption list prints with its reasons on every run. It has 3 entries, all in files feature 203 owns, and the review-signoff comment entry is temporary.
- **Agenda test** (exit 0): every assertion passes. FR-016: refused at render and at confirm, nothing written, an in-order agenda is not reordered. FR-013: the old-order confirmed agenda resumes in its own order, closes both lenses, completes, and keeps its order.
- **Tag disagreements**: none. Every lens's questions matched its FR-015 tag.
