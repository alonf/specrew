# Contract: Quality Governance Artifacts

## Quality profile

- **Profile**: `quality-profile.custom-composition.v1`
- **Resolution mode**: `bounded-custom-composition`
- **Required lenses**:
  - `security-baseline@v1.0.0`
  - `robustness-baseline@v1.0.0`
  - `test-integrity@v1.0.0`

## Required risk dimensions

- `code-quality`
- `design-quality-and-separation-of-concerns`
- `verification-confidence`
- `maintainability`
- `security`
- `robustness`

## Not applicable

- `concurrency-correctness`
- `resiliency`
- `retry-idempotency-and-recovery`

## Required quality gates

| Gate | Evidence contract |
| --- | --- |
| `dead-field` | Planned in `iterations/001/quality/mechanical-findings.json` |
| `anti-pattern` | Planned in `iterations/001/quality/mechanical-findings.json` |
| `test-integrity` | Planned in `iterations/001/quality/mechanical-findings.json` |
| `stack-tooling-evidence` | Planned in `iterations/001/quality/quality-evidence.md` and must cite markdownlint plus the repository's discovery/routing/lifecycle/contract validation lanes |
| `quality-lens-review` | Planned in `iterations/001/quality/quality-evidence.md` with lens-by-lens review notes |

## Stack-specific evidence decision

1. The active stack-specific lint/analyzer command for this feature is:

   ```powershell
   npx --yes markdownlint-cli README.md docs/user-guide.md .github/agents/*.md .github/prompts/*.md specs/054-activate-spec-surfaces/*.md
   ```

2. Additional stack-tooling evidence is required beyond mechanical gates and checklist references:
   - `pwsh -NoProfile -File tests/integration/slash-command-discovery.tests.ps1`
   - `pwsh -NoProfile -File tests/integration/slash-command-routing.tests.ps1`
   - `pwsh -NoProfile -File tests/integration/slash-command-coexistence.tests.ps1`
   - `pwsh -NoProfile -File tests/integration/lifecycle-boundary-sync.tests.ps1`
   - `pwsh -NoProfile -File tests/integration/validation-contract-lane.ps1`

3. No additional YAML-specific evidence source is required by current repo standards for this slice.

## Phase-2 scaffold references

- `specs/054-activate-spec-surfaces/iterations/001/quality/hardening-gate.md`
- `specs/054-activate-spec-surfaces/iterations/001/quality/trap-reapplication.md`

These paths are reserved by the plan, but hardening-only work remains deferred until a later approved boundary.
