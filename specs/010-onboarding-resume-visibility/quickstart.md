# Quickstart: Feature 010 — Onboarding Resume Visibility

**Feature**: `010-onboarding-resume-visibility`  
**Branch**: `010-onboarding-resume-visibility`  
**Scope**: Documentation and bootstrap banner copy only  
**Date**: 2026-05-10

---

## Human Approval

> *I am explicitly authorizing the work below; do all of it in this same session.*

---

## What This Feature Does

Adds explicit "Resuming work later" guidance to three onboarding surfaces (README.md, docs/getting-started.md, and the bootstrap completion banner in scripts/specrew-init.ps1) and reviews docs/user-guide.md for contradictions. No runtime behavior changes.

---

## Pre-Implementation: Baseline Validation Lane

Run the full six-command lane **before making any changes** and confirm all six pass (baseline green for SC-006).

```powershell
# Run from repo root: C:\Dev\Specrew
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\validation-contract-lane.ps1
pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Record: **All 6 passed at baseline** (or note any pre-existing failures to exclude from regression scope).

---

## Implementation Order

Work surfaces in this order to minimize context-switching:

1. **`docs/getting-started.md`** — largest and most detailed surface; add "Resuming work later" subsection
2. **`README.md`** — shorter; add resume note and anti-pattern warning to Recommended flow or Notes
3. **`scripts/specrew-init.ps1`** — edit `Write-PostBootstrapGuidance` banner text only
4. **`docs/user-guide.md`** — review only; record finding; apply edit only if contradiction found

---

## Step 1: Edit `docs/getting-started.md`

**Target location**: After the first-session `specrew start` step in the Greenfield Quickstart (after step 4 "Start your first feature run"), before the Brownfield section.

**Required content** (per contract GS-C1 through GS-C8):

Add a subsection with heading `### Resuming work later` that:

- Names `specrew start` as the command for every resumed session
- Lists the three transient runtime files: `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.specrew/start-summary.md`
- Explains these files do not travel with git
- Covers the cross-machine case (pull + `specrew start` rebuilds handoff from tracked state)
- Names `copilot` directly as the unsupported launch path with a one-sentence rationale
- Clarifies that resuming means a new terminal session, not re-running inside an active conversation

**Contract reference**: `contracts/onboarding-text-surface.md` → Surface 2 clauses GS-C1 to GS-C8

**After editing**: Run lane command 6 (validate-governance) to confirm governance schema still passes.

---

## Step 2: Edit `README.md`

**Target location**: Recommended flow section (add resume note after step 2) and/or Notes section.

**Required content** (per contract README-C1 through README-C3):

- State that resumed sessions also begin with `specrew start`
- Name `copilot` as the unsupported launch path
- Include a one-sentence rationale (bypasses runtime handoff regeneration)

**Contract reference**: `contracts/onboarding-text-surface.md` → Surface 1 clauses README-C1 to README-C3

**After editing**: Re-run lane command 6 to confirm no governance drift.

---

## Step 3: Edit `scripts/specrew-init.ps1` (Banner Text Only)

**Target location**: Inside `Write-PostBootstrapGuidance` function, within the `=== Next Steps ===` block. Add after the existing step 1 ("Start spec authoring") block. The existing step numbering should shift or the new resume guidance can be numbered as a follow-on to step 1.

**Required content** (per contract BANNER-C1 through BANNER-C5):

- A "Resuming work later" item or labeled block
- States every subsequent session runs through `specrew start`
- References runtime handoff regeneration before launch
- Names `copilot` directly as unsupported
- Includes one-sentence rationale

**Implementation constraint**: Only add `Write-Host` lines. No logic changes. No function signature changes. No other edits to the file.

**Width constraint**: Keep lines ≤ 100 characters for SC-005.

**Contract reference**: `contracts/onboarding-text-surface.md` → Surface 3 clauses BANNER-C1 to BANNER-C5

**After editing**: Keep lane command 5 (`project-path-resolution-regression.ps1`) in the post-edit lane to preserve TG-005 coverage; confirm banner visibility separately during manual review.

---

## Step 4: Review `docs/user-guide.md`

**Action**: Read the "Recommended Downstream Entry Point" section and any other section that references `specrew start` or Copilot launch behavior.

**Contradiction checklist** (per contract UG-R1 to UG-R3):

- [ ] Does any sentence imply `specrew start` is only for first launch? → Edit if yes
- [ ] Does any sentence imply running `copilot` directly is acceptable? → Edit if yes
- [ ] Does any sentence contradict the resume contract? → Edit if yes

**Optional alignment note**: If language is neutral (non-contradictory but non-explicit), a one-sentence alignment note confirming `specrew start` applies to both first launch and resumed sessions MAY be added.

**Recording obligation (FR-005)**: Record the finding in iteration state notes before closure.

**Contract reference**: `contracts/onboarding-text-surface.md` → Surface 4

---

## Post-Implementation: Full Validation Lane

Run the complete six-command lane after all edits are complete. All six MUST pass (SC-006).

```powershell
# Run from repo root: C:\Dev\Specrew
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\validation-contract-lane.ps1
pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

---

## Manual Review Gate (TG-004, SC-003)

The six-command lane does not verify prose content. Before closure, a human MUST:

1. Read `README.md` end-to-end and confirm the resume guidance and anti-pattern warning are visible without searching.
2. Read `docs/getting-started.md` "Resuming work later" subsection and confirm it covers all six content obligations (GS-C1 to GS-C6 at minimum).
3. Run `scripts/specrew-init.ps1 -ProjectPath <temp-dir> -DryRun` (or equivalent) and read the printed banner to confirm the resume guidance is visible within 100 columns.
4. Confirm no surface contradicts any other on the resume contract.
5. Record `docs/user-guide.md` review finding per FR-005.

---

## Closure Checklist

Before closing the feature iteration:

- [ ] FR-001: README includes resume guidance and anti-pattern warning
- [ ] FR-002: getting-started has "Resuming work later" subsection covering all required elements
- [ ] FR-003: Bootstrap banner includes resume-mode next step
- [ ] FR-004: All three primary surfaces name `copilot` as unsupported with rationale
- [ ] FR-005: user-guide review finding recorded in iteration state notes
- [ ] FR-006: No runtime behavior changed; only documentation and banner text modified
- [ ] SC-005: Banner resume guidance visible ≤ 100 columns
- [ ] SC-006: All six validation lane commands pass (post-implementation green)
- [ ] TG-004: Human has read all three primary rendered surfaces and confirmed visibility
- [ ] TG-005: Path-resolution regression coverage remains unchanged (confirmed by lane command 5 within the six-command lane)

---

## Do Not Do

- Do not modify specs 008 or 009.
- Do not add new documentation files, new commands, or new onboarding surfaces.
- Do not change runtime behavior, lifecycle rules, or governance behavior in `specrew-init.ps1` or any other script.
- Do not modify any logic, parameters, or non-banner functions in `scripts/specrew-init.ps1`.
- Do not widen scope to other scripts, governance files, or test files.
