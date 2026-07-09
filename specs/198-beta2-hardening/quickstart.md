# Quickstart: 0.40.0-beta2 Hardening Bundle (Iteration 001 slice)

**Feature**: 198-beta2-hardening
**Last verified**: 2026-07-10 (plan-time; re-verified at review with run
evidence)

## Run it

```powershell
# the firewall lane, exactly as CI runs it
pwsh -NoProfile -File scripts/internal/lint-self-leak.ps1 -ProjectRoot .

# the paired fixtures for the lane + toolchain
Invoke-Pester -Path tests/unit -TagFilter 'self-leak'
Invoke-Pester -Path tests/integration -TagFilter 'toolchain-0129'
```

## Try the canonical scenario

1. Open any deployed template under `templates/` and add a line containing
   a deny-listed self-fact (e.g. a dev-repo path).
2. Run the lint command above — expected: exit 1, red output naming the
   file, the matched term, its class, the `specrew-self-ok: <reason>`
   escape syntax, and the parameterization-rule doc.
3. Add the annotation on the line above with a real reason; re-run —
   expected: exit 0, the hit reported as annotated with its reason.
4. Revert the template; re-run — expected: exit 0, clean.

## Verify the edge cases

- Annotation WITHOUT a reason (`specrew-self-ok:`) → still red (treated as
  unannotated).
- `specify init` fixture on Spec-Kit 0.12.9 completes with
  `--integration <key>` and no `--ai` anywhere
  (`tests/integration` toolchain suite; probe evidence at
  `specs/198-beta2-hardening/iterations/001/quality/toolchain-probe-evidence.md`).
- Pin surfaces agree: `pwsh -NoProfile -File scripts/internal/validate-versions.ps1`
  reports 0.12.9 / 0.11.0 everywhere it checks.
