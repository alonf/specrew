# Quickstart: Beta-Before-Stable SDLC Discipline

**Feature**: `048-beta-before-stable-sdlc`  
**Last verified**: 2026-05-26

## Run it

After implementation, run the focused verification commands:

```powershell
pwsh -NoProfile -File .\tests\integration\beta-before-stable-sdlc.tests.ps1
pwsh -NoProfile -File .\tests\integration\release-audit.tests.ps1
pwsh -NoProfile -File .\.specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

## Try the canonical scenario

1. Reach feature-closeout on a synthetic feature.
   Expected result: the handoff contains `AGENT NEXT ACTION:` and
   `HUMAN ACTION NEEDED:` rows.
2. Confirm the agent-owned row lists Steps 5-14 in order.
   Expected result: push, PR, self-review, merge, beta tag, prerelease verify,
   human PASS/FAIL pause, beta fail-loop, stable tag, stable verify, stop.
3. Capture release audit evidence for the synthetic completed release.
   Expected result: `docs/releases/<feature-ref>.md` is created with structured
   front matter and a readable narrative.
4. Run audit validation.
   Expected result: validation passes only when beta verification, explicit
   human PASS, stable tag, and stable verification are present.

## Verify the edge cases

- Record a beta `FAIL` verdict.
  Expected result: stable publication remains blocked and the next action loops
  to a new beta attempt.
- Omit `release_audit_direct_to_main: true`.
  Expected result: audit capture selects the trailing one-file PR mode.
- Set `release_audit_direct_to_main: true`.
  Expected result: audit capture selects direct-main mode but still requires the
  same release evidence.
