---
proposal: 131
title: Coordinator-Prompt SDLC Ownership Clarification (Agent-Driven With Human Approval, Steps 5-14)
status: candidate
phase: phase-2
estimated-sp: 3-5 (standalone) or 5-7 (bundled with Proposal 060)
priority-tier: 1
discussion: empirically motivated by 2026-05-26 F-047 Codex regression where F-047 Item 6's coordinator-prompt template embedded the PR-at-feature-close SDLC sequence as "HUMAN ACTION NEEDED" — visibility goal achieved but ownership semantics regressed; F-045 Codex (pre-Item-6) correctly drove the full SDLC end-to-end; F-047 Codex (post-Item-6) pushed via Scribe then stopped before opening the PR; absorbed memory `[[codex-pr-creation-regression-2026-05-26]]`. **EXTENDED 2026-05-26 to include Steps 9-14** (beta-tag → publish → manual-test → promote-stable) per [[feedback-beta-publish-before-stable-2026-05-26]] universal mandate; bundle candidate with Proposal 060 since both modify the same template surface. F-048 iteration 001 implemented the coordinator prompt/governance/test slice on the active feature branch; runtime enforcement and release-audit automation remain out of this proposal's shipped slice.
---

# Coordinator-Prompt SDLC Ownership Clarification (Agent-Driven With Human Approval)

## Why

F-047 Item 6 (FR-011 in specs/047-bug-bash-trust-hardening/spec.md) embedded the PR-at-feature-close SDLC sequence (push → open PR → address automated PR review → merge) in the coordinator-prompt feature-closeout HANDOFF template **as `HUMAN ACTION NEEDED` items**. The intent was to make the SDLC sequence visible to every host regardless of host-memory awareness — but the wording shifted perceived ownership from "agent drives, human approves each step" to "human does all SDLC steps."

The very fix shipped in F-047 v0.27.3 became a regression on the agent-drives-PR behavior we wanted to preserve from F-045 Codex.

### Cross-host empirical evidence (same Codex host, three sessions)

| Host / Feature | PR creation behavior | SDLC awareness at closeout |
|---|---|---|
| Codex (F-045 v0.27.1) — pre-Item-6 | Agent drove push + `gh pr create` + Copilot review monitoring + merge | Full SDLC; correctly identified push/PR/review/merge as agent responsibilities |
| Antigravity (F-046 v0.27.2) | Bypassed entirely (autopilot blew through closeout without push or PR) | Zero SDLC awareness — separate Proposal 105 territory |
| Codex (F-047 v0.27.3) — post-Item-6 | Pushed via Scribe; stopped before `gh pr create`; emitted HANDOFF asking human to open the PR | Partial — knew push was needed but stopped at PR creation step |

**F-045 → F-046 → F-047 is not a monotonic improvement.** F-047 Codex regressed from F-045 Codex on this specific axis, even though F-047 itself shipped fixes intended to harden closeout SDLC awareness across hosts.

### Empirical evidence of the regression

- F-047 PR #985 was NOT created by Codex. Created manually from a Claude session via `gh pr create --body-file .scratch/f047-pr-body.md` after Codex's "open a PR for me" handoff. Merge: `19a0c5e40d01f0ffc5edc2d32fd5f89a8653ddc0` on 2026-05-26T12:49:28Z.
- F-045 PR #883 WAS created by Codex end-to-end (merge `973af287` on 2026-05-25T19:27:18Z) — same Codex host, different session.
- F-047 Codex emitted: "open a PR from 047-bug-bash-trust-hardening to main, then continue from that review/merge handoff."

### Standing rule this regression violates

The PR-at-feature-close SDLC pattern (memory `[[feedback-pr-at-feature-close-sdlc]]`, adopted 2026-05-12) explicitly states:

> "Squad drives PR creation as part of feature-closeout; branches from main per feature, merge-commit only (not squash); feature-start template includes branch-from-main + upstream push; feature-closeout template includes Steps 5–9 for push/PR/self-review/merge"

Squad/Codex/Antigravity/any other Crew runtime drives the PR cycle. Human approval at each substantive step, not human execution.

## What

Single-pillar small-fix slice that clarifies SDLC ownership semantics in the coordinator-prompt feature-closeout HANDOFF template across all hosts.

**F-048 iteration 001 branch status (2026-05-26)**: the coordinator prompt/governance template slice has been implemented with focused regression coverage in `tests/integration/beta-before-stable-sdlc.tests.ps1`. This does not claim F-048 iteration 002 release-audit automation or Proposal 105 runtime enforcement.

### Pillar 1: AGENT TO EXECUTE alongside HUMAN ACTION NEEDED (~1-2 SP)

The coordinator-prompt feature-closeout HANDOFF template needs a one-line clarification: SDLC steps are **agent-driven with human approval at each step**, not human-driven.

**Bad current wording (post-F-047 Item 6)**:

```text
HUMAN ACTION NEEDED:
  1. push the branch
  2. open a PR
  3. address automated PR review
  4. merge after approval
```

**Better wording — Option B (split into ownership rows, EXTENDED 2026-05-26 with Proposal 060 beta-publish sequence)**:

```text
AGENT NEXT ACTION:
  Execute the feature-closeout SDLC steps, pausing for human verdict at
  each substantive step:
    Step 5: push the branch
    Step 6: gh pr create
    Step 7: self-review PR (reference per-iteration review.md + retro.md)
    Step 8: gh pr merge --merge (preserves per-feature history)
    Step 9: tag merge commit v<next-version>-beta.1 + push tag
    Step 10: verify .github/workflows/publish-module.yml published the
             prerelease via Find-Module Specrew -AllowPrerelease
             -RequiredVersion <ver>
    Step 11: PAUSE for human manual test verdict — emit instructions:
             "Install via `Install-Module Specrew -RequiredVersion
             <ver> -AllowPrerelease -Force` in a clean shell. Exercise
             feature-specific surface + smoke `specrew start` and
             `specrew where`. Report PASS or FAIL with evidence."
    Step 12: if FAIL → fix on main → tag v<ver>-beta.2 → repeat from
             Step 9 (loop until PASS)
    Step 13: if PASS → tag the PASS-validated commit v<next-version>
             stable + push tag; verify workflow publishes stable to PSGallery
    Step 14: stop before any new feature work

HUMAN ACTION NEEDED:
  Approve each agent action as the agent pauses for verdict.
  At Step 11 specifically: install the prerelease package, exercise it,
  and report PASS / FAIL with evidence.
```

**Why split rows + extended sequence**: makes the agent-drives-with-approval pattern explicit while encoding the full PR-at-feature-close SDLC including Steps 9-13 (beta tag → publish → manual test → promote stable) per the [[feedback-beta-publish-before-stable-2026-05-26]] universal mandate. Backward compatible for downstream tooling that scans for `HUMAN ACTION NEEDED:`.

Recommended: **Option B with Steps 5-14 extension** — bundles with Proposal 060 since both modify the same template surface; one slice ships both changes.

**Alternative Option A (replace ownership label only, no Steps 9-13)** is now obsolete — the extended SDLC is part of the standing rule, so any rewrite must include Steps 9-14, not just the original Steps 5-8.

### Pillar 2: Test coverage for HANDOFF emission shape (~1 SP)

Add an integration test verifying the feature-closeout HANDOFF emits BOTH rows AND covers Steps 5-14:

- `AGENT NEXT ACTION:` row enumerates all 10 steps (5-14) with execute-verbs (push, `gh pr create`, monitor Copilot review, merge, tag `-beta.N`, verify prerelease publish, wait-for-human-test-verdict, fix-loop, tag stable, stop)
- `HUMAN ACTION NEEDED:` row covers both approvals AND the explicit Step 11 manual-test verdict ("Install + exercise + report PASS / FAIL")

Composes with `tests/integration/handoff-format.tests.ps1` (F-014 test coverage).

### Pillar 3: Charter sync across all Crew agents (~0.5-1 SP)

The same clarification propagates to:

- `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` — feature-closeout boundary rules
- `extensions/specrew-speckit/squad-templates/agents/scribe.md` — Scribe charter (Scribe currently pushes; charter should clarify Scribe also opens PR and monitors review unless human pre-empts)
- `.specrew/team/agents/scribe.md` (canonical source per F-044)
- Each per-host `hosts/<kind>/coordinator-rules.psd1` if host-specific wording exists

Mirror parity discipline: every change to `extensions/specrew-speckit/squad-templates/` MUST be byte-identical with `.specify/extensions/specrew-speckit/squad-templates/`.

## How (small-fix-slice plan, bundle candidate with Proposal 060)

- Single iteration on feature branch from `main` — or bundled with Proposal 060 as a 2-iteration feature since both touch the same template surface
- ~3-5 SP standalone (was 2-4 — raised for Steps 9-14 extension); ~5-7 SP bundled with Proposal 060 polish (workflow primitives already shipped F-023)
- Files touched:
  - `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (Pillar 1)
  - `extensions/specrew-speckit/squad-templates/agents/scribe.md` (Pillar 3)
  - `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (mirror parity)
  - `.specify/extensions/specrew-speckit/squad-templates/agents/scribe.md` (mirror parity)
  - `tests/integration/handoff-format.tests.ps1` (Pillar 2)
- CHANGELOG entry
- INDEX update at feature-closeout (candidate → shipped)
- Bundle candidate: ship as part of F-048 bug-bash if F-048 is queued; otherwise as standalone small-fix slice per Proposal 067

## Acceptance signals

- **AC1**: Feature-closeout HANDOFF template emits both `AGENT NEXT ACTION:` and `HUMAN ACTION NEEDED:` rows with all 10 Steps (5-14) enumerated
- **AC2**: Integration test in `tests/integration/handoff-format.tests.ps1` verifies the two-row shape AND the Steps 5-14 sequence on a synthetic feature-closeout commit
- **AC3**: Post-merge regression test: replay F-047 Codex's exact handoff context against the updated template — expect the agent to drive `gh pr create` AND the subsequent beta-tag → publish → wait-for-test → promote sequence rather than handing PR creation off
- **AC4**: Mirror parity preserved across `extensions/specrew-speckit/squad-templates/` and `.specify/extensions/specrew-speckit/squad-templates/`
- **AC5**: F-045 baseline behavior preserved at Steps 5-8 — the template change does not regress the F-045 end-to-end agent-driven PR cycle
- **AC6 (NEW)**: Steps 9-14 work end-to-end on a synthetic dry-run feature: agent tags `-beta.1`, workflow publishes, agent emits Step 11 HANDOFF for human verdict, agent waits, agent tags stable after PASS verdict
- **AC7 (NEW)**: Step 12 fix-loop verified: synthetic FAIL verdict at Step 11 triggers correct loop back to Step 9 with incremented `-beta.2` tag

## Out of scope

- Runtime enforcement that the agent actually executes the steps (that is Proposal 105 territory — hooks would intercept on missing `gh pr create` after merge commit)
- Slash-command surface for manual PR creation (that is part of Proposal 130 / 089 territory)
- Backfill of historical incorrect HANDOFF emissions (one-time fix; future emissions follow the new template)

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 078 (Handoff Conversation Quality)** | This proposal's Pillar 1 wording change is a specific case of 078's Pillar 1 (three-section format at feature-closeout normal path). 078 says "the section must be present"; this proposal says "the section must use agent-drives ownership language". Composes naturally — 078 enforces shape, 131 enforces semantics |
| **Proposal 089 (PR Review Integration — Address-PR-Review Gate)** | 089 covers the post-PR-creation portion (monitor Copilot review, address findings, merge). This proposal covers the pre-PR-creation transition (agent owns `gh pr create`) AND the post-merge beta-publish sequence (Steps 9-14). 089 + 131 + 060 together complete the SDLC cycle |
| **Proposal 060 (PSGallery Prerelease Channel + Universal Beta-Before-Stable Mandate)** | **BUNDLE CANDIDATE.** 060's Iteration 1 scope (coordinator-prompt template extension Steps 9-13 + `docs/release-discipline.md` + integration test) overlaps 100% with this proposal's Pillar 1 + Pillar 2. Ship as a single 2-iteration feature: Iter-1 = template change + tests + docs; Iter-2 = `--allow-prerelease` flag on `specrew update --self` + prerelease-banner integration. Combined SP ~5-7 |
| **Proposal 105 (Host-Native Hook Deployment)** | Runtime enforcement layer that would catch agent-skipping-PR-creation behaviorally (e.g., Stop hook checks "if last commit is feature-closeout and no PR exists, emit reminder"). Prose-level fix (131) is the immediate remediation; runtime enforcement (105) is the durable backstop |
| **Proposal 120 (Handoff-Block Validator Enforcement)** | Pillar 1's `Test-SpecrewHandoffBlockPresent` helper composes — extend it to grade the AGENT NEXT ACTION / HUMAN ACTION NEEDED two-row shape at feature-closeout commits |
| **Proposal 067 (Small-Fix Slice Type)** | This proposal is itself a small-fix slice — single coordinator-prompt template wording change with test coverage. Natural fit for the small-fix-slice methodology |
| **F-047 Item 6 retro lesson** | The retro lesson here is "make the SDLC sequence visible to every host" achieved the visibility goal but introduced an ownership-ambiguity regression. Visibility alone is not enough; ownership semantics must be encoded too. The bug-bash slice type (Proposal 055) intrinsically iterates — incremental small improvements with retro-driven feedback — and that is acceptable as long as each retro captures the new gap |

## Drafting trigger

Draft when F-048 bug-bash is queued (likely after another empirical incident accumulates 2-3 related findings per the [[default-bug-handling-pattern-interim-2026-05-24]] interim catalog). Or ship as standalone small-fix slice per Proposal 067 if no bug-bash is queued by 2026-06-15.

## Cross-references

- Standing rule: `[[feedback-pr-at-feature-close-sdlc]]` — the rule this regression violates
- F-047 spec: file:///C:/Dev/Specrew/specs/047-bug-bash-trust-hardening/spec.md (FR-011 — the change that caused the regression)
- F-047 retro: file:///C:/Dev/Specrew/specs/047-bug-bash-trust-hardening/iterations/001/retro.md (did not catch this gap because PR was not opened by Codex during the iteration)
- Proposal 078: file:///C:/Dev/Specrew/proposals/078-handoff-conversation-quality.md (Pillar 1 feature-closeout normal path)
- Proposal 089: file:///C:/Dev/Specrew/proposals/089-pr-review-integration-address-pr-review-gate.md (post-PR-creation lifecycle gate)
- Proposal 105: file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md (runtime enforcement layer)
- Proposal 120: file:///C:/Dev/Specrew/proposals/120-handoff-block-validator-enforcement.md (handoff-block presence + shape grading)
- Proposal 067: file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md (small-fix-slice methodology)
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md

## Status history

- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep absorbing `[[codex-pr-creation-regression-2026-05-26]]`. ~2-4 SP small-fix slice. Bundle candidate for F-048 bug-bash; standalone-ready as fallback.
- 2026-05-26 (later, same day): **extended Pillar 1 + Pillar 2 to cover Steps 9-14** (beta-tag → publish → manual-test → promote-stable) per the new [[feedback-beta-publish-before-stable-2026-05-26]] universal mandate. SP raised 2-4 → 3-5 standalone; bundle-with-060 recommended ~5-7 SP combined since both proposals modify the same template surface. AC6 + AC7 added covering Steps 9-14 dry-run + fail-loop behavior.
- 2026-05-26 (F-048 iteration 001): active feature-branch implementation landed the coordinator ownership split across the generated start handoff, coordinator response guidance, coordinator decision guidance, and source/deployed coordinator governance templates. Focused test coverage checks `AGENT NEXT ACTION:` + `HUMAN ACTION NEEDED:`, ordered Steps 5-14, the explicit Step 11 PASS/FAIL gate, and the beta fail-loop. Remaining related work is outside this proposal's implemented slice: F-048 iteration 002 release-audit automation and Proposal 105 runtime enforcement.
