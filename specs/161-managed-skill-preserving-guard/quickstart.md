# Quickstart: Managed-Skill "Stuck Preserving" Guard

**Feature**: 161-managed-skill-preserving-guard
**Last verified**: 2026-06-06 (planning-time; re-verify at review)

## Run it

```powershell
# The new deploy-level repro harness (created in this feature):
pwsh -File tests/integration/managed-skill-stuck-preserving.tests.ps1

# The existing F-160 classifier fixture (regression guard, must stay green):
pwsh -File tests/integration/managed-runtime-sidecar.tests.ps1
```

## Try the canonical scenario

1. Run the new harness. It creates a scratch project under the system temp
   directory with a `.squad` directory, seeded `.copilot/skills/specrew-*`
   fixtures (marker-present, user-authored, current-canonical-no-marker,
   stale-canonical-no-marker), then executes the real
   `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` against it.
2. Expected: PASS lines for S1 (marker-present removed), S2 (user-authored
   preserved), S3 (current-canonical removed — F-160 guard), S6 (active roots
   carry `SKILL.md` + `.specrew-managed`), S5 (second run idempotent), and an
   explicit recorded outcome for S4 (stale-canonical probe) feeding the
   verdict.
3. Run it a second time: outcomes must be identical (determinism, SC-001).

## Verify the edge cases

- **User-authored preservation (data-loss guard)**: in the harness output, the
  S2 directory must be reported `preserved-legacy-unmanaged-skill` and still
  exist with byte-identical content afterwards — in every state, pre- or
  post-fix.
- **Idempotency**: the S5 second deploy run must report preserved/no-change
  for managed active-root surfaces (no churn).
- **Verdict presence**: after implementation, the iteration quality evidence
  (`specs/161-managed-skill-preserving-guard/iterations/001/quality/`) must
  contain the CONFIRMED/REFUTED verdict with the exact code-path citation.
