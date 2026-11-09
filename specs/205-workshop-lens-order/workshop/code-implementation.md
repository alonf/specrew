# code-implementation: 205-workshop-lens-order

**Depth**: light. **Confirmation**: human-confirmed (lens-question). All six decision points were answered in one typed reply on 2026-11-10.
Manifest: `specs/205-workshop-lens-order/implementation-rules.yml`.

```text
design time (this lens)                         implement time
-----------------------------------             ------------------------------------
source of rules -> stack -> baseline (on)  -->  implementation-rules.yml
                 -> decision prompts              -> specrew-code-rules skill surfaces
                 -> dependencies                     the rules task by task
                 -> reviewer + authorization      -> codex co-review at review
```

## Decisions

1. **Source of the rules:** this repo's own conventions. No other guideline applies. Tests are script-style (Set-StrictMode, Assert-True/Write-Fail, exit code), and refusals use the existing New-SpecrewWorkshopAgendaRefusal.
2. **Stack:** PowerShell 7 (`resolved_stack: powershell`). All 20 baseline defaults are on, with no exceptions.
3. **Testing posture:**
   - Test-first: `tests/unit/lens-order-parity.tests.ps1` fails on today's orders before any surface changes.
   - Extend `tests/integration/workshop-agenda-confirmation.tests.ps1` with the relative-order refusal and the FR-013 resume case.
   - Run every existing workshop test locally and report the results.
   - Register as named specrew-ci.yml steps the two new/extended files plus every existing workshop test that covers a file this feature touches and passes.
   - An already-red workshop test is reported to the human as a finding with its failure. It is never fixed silently and never left out silently.
4. **Error handling:** the writer refuses with the existing helper (out-of-order lenses, index.yml order, one action) and never reorders. The parity test collects every mismatch.
5. **Dependencies:** none new. **Verified before the plan (2026-11-10):** `Read-IntakeYamlDocument -Kind lenses` parses a scratch copy of index.yml carrying `space: problem|solution|both` (bare and quoted) for all 11 lenses. It returns the `space` property and keeps list order, so list position can be the order. The parse ran on a scratch copy, and the real index.yml is unchanged.
6. **Reviewer:** codex, human-selected. `specrew review --host codex --authorization-ref workshop-205-workshop-lens-order` succeeded. It changed codex's `authorization_ref` in `.specrew/reviewer-hosts.json` from `workshop-202-beta4-1-ux-stabilization` to this feature's reference.
