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
