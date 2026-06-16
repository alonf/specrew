# Mirror Parity Evidence

**Schema**: v1
**Feature**: 183-stability-quality-bundle
**Iteration**: 001
**Task**: T007
**Recorded At**: 2026-06-16T10:10:16Z
**Result**: PASS

## Scope

T007 verifies that every touched source extension/runtime file under
`extensions/specrew-speckit/**` is byte-aligned with its deployed project mirror
under `.specify/extensions/specrew-speckit/**`.

## Evidence

- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/ProviderMirrorParity.Tests.ps1` passed.
- A direct SHA-256 comparison across all touched extension/deployed mirror pairs passed.
- `git diff --check` passed after the T006/T007 artifact updates.

## Touched Mirror Pairs

| Source | Deployed Mirror | Status |
| --- | --- | --- |
| `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` | `.specify/extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` | aligned |
| `extensions/specrew-speckit/design/soft-validator-handoff-governance.md` | `.specify/extensions/specrew-speckit/design/soft-validator-handoff-governance.md` | aligned |
| `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md` | `.specify/extensions/specrew-speckit/prompts/coordinator-decision-guidance.md` | aligned |
| `extensions/specrew-speckit/prompts/coordinator-response.md` | `.specify/extensions/specrew-speckit/prompts/coordinator-response.md` | aligned |
| `extensions/specrew-speckit/refocus-scopes.json` | `.specify/extensions/specrew-speckit/refocus-scopes.json` | aligned |
| `extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1` | `.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1` | aligned |
| `extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1` | `.specify/extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1` | aligned |
| `extensions/specrew-speckit/scripts/specrew-handover-provider.ps1` | `.specify/extensions/specrew-speckit/scripts/specrew-handover-provider.ps1` | aligned |
| `extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1` | `.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1` | aligned |
| `extensions/specrew-speckit/squad-templates/agents/implementer/charter.md` | `.specify/extensions/specrew-speckit/squad-templates/agents/implementer/charter.md` | aligned |
| `extensions/specrew-speckit/squad-templates/agents/planner/charter.md` | `.specify/extensions/specrew-speckit/squad-templates/agents/planner/charter.md` | aligned |
| `extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md` | `.specify/extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md` | aligned |
| `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | aligned |
| `extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md` | `.specify/extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md` | aligned |
| `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | aligned |
| `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | `.specify/extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | aligned |

## Provider Full-Copy Parity

The provider parity test also asserted module/source/.specify byte identity for
the full-copy provider set:

- `deploy-refocus-hooks.ps1`
- `refocus.ps1`
- `specrew-bootstrap-provider.ps1`
- `specrew-handover-provider.ps1`
- `specrew-hook-dispatcher.ps1`

No mirror mismatch remains open for T007.
