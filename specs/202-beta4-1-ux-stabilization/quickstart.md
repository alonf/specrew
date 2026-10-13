# Quickstart: verifying 202 Tier 1

1. **Unit and contract suites** (each work item's RED fixture):
   `pwsh -NoProfile -File tests/full-powershell-test-sweep.ps1`, or run a single file with `Invoke-Pester tests/unit/<name>.tests.ps1`.
2. **Cross-host workshop acceptance** (SC-001, through the real launcher and dispatcher with the recorded payloads in `tests/fixtures/hook-payloads/<host>/`):
   `Invoke-Pester tests/unit/cross-host-workshop.tests.ps1`
3. **Fault injection, cases a-e** (SC-002). Case (e) needs two real `pwsh` processes and runs on the Windows, macOS and Linux CI matrix:
   `Invoke-Pester tests/unit/journal-fault-injection.tests.ps1`
4. **Validator compared with the known baseline** (SC-008):
   `pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .`. The output is compared with the baseline (review-evidence, defer-provenance, 198/011 needs-rework).
5. **Live walk at the iteration-1 closeout** (the maintainer). On Claude, Codex (healthy worktree) and Copilot: product-domain, then agenda, then one lens. Each host should produce 3 receipts with 1 reply per checkpoint. The friction table records real decisions, corrective exchanges and extra stops, with null where a value was not captured.
