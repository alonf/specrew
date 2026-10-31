# Implementation Plan: beta5 stabilization

**Feature**: 203-beta5-stabilization
**Iterations**: 001 = authority core (US1, US2, US3, plus FR-046), this plan's work breakdown; 002 = stops, CI
rider, claim release, journal (US4 to US7), planned in detail at its own design analysis
**Date**: 2026-10-31
**Branch**: `203-beta5-stabilization` (from main at `df1141a8`; sync base main)
**Inputs**:

- spec.md, approved for specify and for clarify (both hook-captured typed verdicts);
- iterations/001/design-analysis.md, with its Co-Design Record agreed 2026-10-31 (Option B; DA-2, DA-7 and
  DA-8 amended by the maintainer), decision commit `130e88c7`;
- research.md (the per-host facts behind DA-2 to DA-4 and DA-7);
- implementation-rules.yml (202's manifest inherited, with the 203 changes);
- the resolved quality profile, corrected below.

## Summary

Iteration 001 makes measure (b) hold by construction and removes the per-round approval. One pure classifier
(`Resolve-SpecrewTypedAct`) reads each typed turn once and returns one act; every recovery path writes only
through `Write-SpecrewTypedAct`, which re-reads the cited turn and re-derives the act. The plan's review budget is
snapshotted into a single grant at the before-implement verdict; the orchestrator reserves each round before
invoking the reviewer and stops the human only on the four pause facts. Every unrecorded approval-shaped turn is
reported in the same turn. All of it is built behind a live-engine pin outside the worktree, so no unreviewed
capture code judges the maintainer's approvals.

## Technical Context

- **Language/Version**: PowerShell 7.x (Windows, macOS, Linux); Markdown, YAML, JSON; GitHub Actions YAML.
- **Primary Dependencies**: none new (`use-existing-no-new-dependency`): .NET file APIs, git, Pester.
- **Storage**: the existing append-only JSONL journals and review campaign fact store; no database.
- **Testing**: Pester, RED-first through shipped entry points; cross-host replay with recorded real payloads
  (`tests/fixtures/hook-payloads/<host>/`); fault fixtures for every mint path.
- **Target Platform**: the Specrew module and its hooks on Claude, Codex and Copilot (validated tier).
- **Performance Goals**: none new; a scoped round must receive only its listed files (DA-7, token cost).
- **Constraints**: authority rules live once (DA-1); stores keep ids and hashes; no script or `!` approval path;
  no checkout inside the worktree (DA-8); the live engine advances only after an iteration's review.
- **Scale/Scope**: iteration 001 covers FR-001 to FR-027, FR-041 (correlation), FR-042, FR-043, FR-045, FR-046.

## Architecture

Bound by the design gate: the existing layered hooks plus the campaign fact store, with the agreed component map
in iterations/001/design-analysis.md (Co-Design Record). Component-to-file anchors (source of truth; the
`.specify` mirrors and the `scripts/internal` / `extensions` twin copies change only at a deployment point, see
"When 203's changes reach the live hooks"):

| Component | Files |
| --- | --- |
| Host bindings (identity field, output shapes) | `hosts/{claude,codex,copilot}/host.psd1` |
| Dispatcher, turn record | `extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1` and its `scripts/internal` twin (`ConvertTo-SpecrewTurnRecord`) |
| Classifier (new) and writer (new) | `scripts/internal/bootstrap/HumanAuthorityStore.ps1` (`Resolve-SpecrewApprovalForm` folded into `Resolve-SpecrewTypedAct`; `Write-SpecrewTypedAct`) |
| User-prompt router, turn-end recovery, backstop | `scripts/internal/bootstrap/HandoverStore.ps1` (`Invoke-SpecrewTypedAuthority`, `Update-SpecrewRollingHandover`), `ConversationCaptureAccessor.ps1` |
| Not-recorded reporter | `HumanAuthorityStore.ps1` (`Write-SpecrewAuthorityNotRecordedReport`) |
| Budget snapshot, ceiling | `scripts/internal/sync-boundary-state.ps1` (plan validation), the verdict capture path, `review-campaign-orchestrator.ps1` (`Get-ReviewCampaignRoundBudgetTotal` becomes the ceiling) |
| Orchestrator loop, reservation, infra cap | `scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1` (grant 1725-1745, budget state 675, check 1671) |
| Navigator, review stops | `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`, `worktree-navigator.ps1`, `review-signoff-evidence-gate.ps1` |
| Scoped round | `worktree-review-orchestrator.ps1`, `worktree-reviewer.ps1`, `review-target-port.ps1` |
| Token usage | `review-claude-harness-port.ps1`, `review-codex-harness-port.ps1`, `review-copilot-harness-port.ps1`, `review-progress-projection.ps1` |
| Stop check (FR-046) | `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`, `turn-end-store.ps1` |
| Live engine pin | the providers' engine resolution (`specrew-handover-provider.ps1:82-87`, `specrew-co-review-navigator-provider.ps1:60`, `specrew-bootstrap-provider.ps1`, dispatcher 955-965); a pin script under `scripts/internal/` |

## Review budget

```yaml
iteration-001:
  model: per-round approvals (today's engine; the budget engine is not live until this iteration's deployment)
  rounds: 4            # today's co_review_max_rounds default, with allowance resets as today
  host_order: [codex, copilot, claude]
iteration-002:
  rounds: 4
  host_order: [codex, copilot, claude]
  infra_failure_cap: 2
```

**Reasoning.**

- Iteration 001 cannot use the budget model: the live-engine pin keeps it out of the live hooks until this
  iteration's review signs off (DA-8). Its review runs on today's engine, with a per-round approval each round
  and today's default cap of 4 per allowance. The before-implement snapshot does not apply to it.
- Iteration 002 is the first review on the budget model. 202's iterations ran 6, 10 and 8 review rounds under
  per-round approvals, most of them re-reviews of fixes. Under 203 a late fix costs a scoped round (DA-7), which
  is small. A budget of 4 keeps the plan inside the configured ceiling (`co_review_max_rounds`, default 4, in
  `.specrew/config.yml`, not set there today), so no ceiling change is needed; one expected top-up gives
  measure (f) a cost of 2 authorizations for the boundary against the baseline of 6.
- `infra_failure_cap: 2`: two consecutive infrastructure failures on a host move to the next host in the order.
  Codex's file-delivery quirk (empty stdout, findings in `.review/findings.jsonl`) is not an infrastructure
  failure, so it does not count toward the cap.

## When 203's changes reach the live hooks

The maintainer's clarify instruction: 203 changes the capture and Stop checks that govern this feature's own
boundaries, and they reach the live hooks only after an iteration's review, so a half-built capture never judges
the maintainer's approvals. The research found that in this self-host repo the live providers load engine code
from the project working tree first, so an uncommitted edit would go live at once. The plan:

1. **W1 (first, deployed alone).** The providers' engine resolution changes so the self-host tree yields to an
   explicitly set `SPECREW_MODULE_PATH`. A pin is created outside the worktree,
   `%USERPROFILE%\.specrew\live-engine\203-beta5-stabilization`, as a detached `git worktree` at W1's reviewed
   commit, and this worktree's hook launcher is pointed at it (`-ModulePath`). W1 gets its own review round on
   today's engine; after sign-off the `.specify` mirror is synced from the same commit and the pin is created.
   From then on, engine edits in this worktree are inert.
2. **During the iteration.** Source changes land in `extensions/` and `scripts/internal/` only. The `.specify`
   mirror and the pin stay at the last deployed commit. The mirror-parity check is enforced at deployment
   points and at the pull request, not on every branch commit; a deploy-pending record
   (`specs/203-beta5-stabilization/iterations/001/deploy-pending.md`) lists what is waiting.
3. **Deployment point.** After the iteration's review sign-off, and before the Claude-only capture check
   (FR-045): the pin advances to the signed-off commit and the `.specify` mirror is synced from it, in one
   commit. The capture check then exercises the deployed engine.
4. **Iteration 002** repeats the same cycle; its review is the first to run on the budget model.

This changes the inherited `provider-mirror-parity` rule ("syncs its `.specify` mirror in the same commit") for
203: the manifest records the scoped exception.

## Work breakdown, effort, and FR-to-test mapping (iteration 001)

**32 SP is planned against the 20 SP convention, an overcommit of 12 SP that is visible and not hidden.** The
maintainer fixed iteration 001's scope (US1 to US3 plus FR-046). Review effort is governed by the review budget,
not by SP. Every work item lands RED-first: the fixture reproduces the defect through the shipped entry point,
then the fix turns it green.

| # | Work item | FRs | SP | RED fixture (through the shipped path) |
| --- | --- | --- | --- | --- |
| W0 | Host facts in scratch directories only: both Copilot firings for one prompt (native and Claude-hook), asserting one stand-in identity; a paste on Copilot and on Codex; Claude `systemMessage` visibility (the maintainer observes it); a Claude compaction entry as a fixture | FR-016, FR-017, FR-029 (DA-4) | 2.0 | Fixtures under `tests/fixtures/hook-payloads/<host>/` with provenance; `typed-turn-identity.Tests.ps1` asserts one identity for the two Copilot firings |
| W1 | Live engine pin: resolution yields to `SPECREW_MODULE_PATH`; pin script (create, advance, show); launcher wiring; twin-copy parity; deployed alone after its own review | clarify instruction | 2.0 | `live-engine-resolution.Tests.ps1`: with the variable set, a deliberately broken worktree engine file is not loaded |
| W2 | `Resolve-SpecrewTypedAct`: act DTO, identity per binding (DA-2, Copilot normalization), standalone rule (DA-3), pending-state routing to one act | FR-014, FR-015, FR-018, FR-020, FR-023 | 4.0 | `typed-act-classifier.Tests.ps1`: quoted, backticked and pasted phrases yield none; a compaction summary yields none; one turn yields one act |
| W3 | `Write-SpecrewTypedAct` with re-derivation; rewire the router, turn-end recovery, backstop and writer CLIs; remove per-path rules and `--approve-round`; supersession fact | FR-010, FR-014, FR-021, FR-022, FR-025 | 4.0 | `typed-act-writer.Tests.ps1`: an agent citing a real `confirm` turn mints no verdict; a re-typed approval supersedes, never reuses |
| W4 | Verdict pairing against the pending-crossing record across a compaction; mismatched boundary reported, nothing recorded | FR-019, FR-020 | 1.5 | `verdict-pairing.Tests.ps1`: packet, compaction, verdict records once; `approved for tasks` while plan waits records nothing |
| W5 | Not-recorded reporter: every branch with its own reason (incl. stage evidence absent), store checked when speaking, Claude visible line, justified stop elsewhere | FR-026, FR-027, FR-032 (touched refusals) | 2.0 | `not-recorded-report.Tests.ps1`: each branch reports; a recorded approval never reports |
| W6 | Budget declaration and snapshot: `## Review budget` parser, ceiling validation at plan sync and snapshot (refusal names the ceiling and `.specrew/config.yml`), grant fact citing the verdict; zero rounds when absent | FR-001, FR-002, FR-003, FR-008 | 2.5 | `review-budget-snapshot.Tests.ps1`: a plan edit after the verdict does not change the grant; above-ceiling refused at both points |
| W7 | Orchestrator loop: single grant, reservation before invocation, top-up starts the next round, infra-failure cap and host advance, pause facts (a)-(d), navigator reads pause facts only, stop layout and phrases | FR-004 to FR-007, FR-009, FR-011 | 5.0 | `review-budget-loop.Tests.ps1`: no reviewer invoked past `budget_total` (the July shape); 2 infra failures advance codex to copilot; exhausted order pauses (d) |
| W8 | Scoped late-fix round: sparse materialization of the listed paths, `scoped` label, coverage rule | FR-013 | 2.0 | `scoped-round.Tests.ps1`: the reviewer worktree contains only the listed paths; coverage complete only when every changed file is covered |
| W9 | Token usage: parse host-reported usage (Claude, Codex from its delivery file, Copilot if reported), round result and sign-off total | FR-012 | 1.5 | `review-usage.Tests.ps1`: recorded reviewer outputs yield tokens or "not reported by <host>" |
| W10 | FR-046: the Stop check verifies the reply's decision parts; the word-for-word declared-vs-reply comparison goes | FR-046 | 1.5 | `presented-check.Tests.ps1`: a reworded content line passes; a missing marker or option blocks |
| W11 | Audit and correlation: record-to-typed-turn join audit; reservations cite grant and reset; turn identity and campaign id on records | FR-024, FR-041 (part) | 1.5 | `authority-audit.Tests.ps1`: a record with no joined typed turn fails the audit |
| W12 | Test evidence suite: no-human-turn fixtures for every mint path, non-approval phrase fixtures, cross-host replay incl. compaction, budget economics fixtures | FR-042, FR-043 | 1.5 | the suites above, collected and run in the census and a PR lane |
| W13 | Deployment and the Claude-only capture check: pin advance plus `.specify` sync after sign-off; the maintainer's check (verdict after a compaction, quoted phrase, pasted phrase) with records | FR-045 | 1.0 | `iterations/001/capture-check.md` with the three results |

## Test strategy

- Deterministic Pester through shipped entry points; the cross-host suite drives the real dispatcher with each
  binding and recorded payloads, never the classifier alone.
- Paired honesty tests for every authority invariant (legitimate path works, abuse path fails), with
  message-content assertions.
- RED-first, instance-pinned fixtures for every budget economics invariant (FR-043).
- Agent CLI probes in scratch directories only, never this worktree.
- New suites are census-selected by name (`*.Tests.ps1`).

## Quality plan (resolved profile, corrected)

The resolver returned a bounded custom composition and read the stack as Node and a browser SPA, and marked
three dimensions not-applicable. **That reading is wrong for 203 and is overridden here with rationale:**

| Dimension | Resolver said | 203 plan | Why |
| --- | --- | --- | --- |
| stack surfaces | Node.js API, TypeScript SPA | PowerShell module, host hooks, GitHub Actions | the repository's product is a PowerShell module |
| concurrency-correctness | not-applicable | **required** | Copilot fires two hooks for one turn (DA-2); reservation before invocation under concurrent hook processes |
| resiliency | not-applicable | **required** | infrastructure-failure cap and host advance (FR-009); the pin keeps a broken engine out of the live hooks |
| retry-idempotency-and-recovery | not-applicable | **required** | re-derivation writes only if unrecorded (FR-022); top-up idempotence; recovery paths |

The required lenses are `security-baseline`, `robustness-baseline` and `test-integrity`, routed to the reviewer
order codex, copilot, claude (human-authorized). `iterations/001/quality/hardening-gate.md` is completed before
implement, at the before-implement boundary.

## Constitution Check

| Principle | Status |
| --- | --- |
| I Spec authoritative / VIII reconciliation | Pass. The co-design amendments are recorded in design-analysis.md; no spec divergence |
| II/XXVII Layered system | Pass. Spec Kit extension surfaces (hooks, providers, stores, engines); no Squad-layer change |
| III Supported extension surfaces | Pass. Host hook surfaces only |
| IV Compatibility | Pass. Plans without a budget get zero rounds and a top-up (FR-008); legacy ledger entries untouched |
| XV Human oversight | Pass. The typed reply stays the only approval; the budget is approved inside an existing verdict |
| XVI Capacity-aware | Flagged. 32 SP against 20, overcommit visible (plan-boundary prompt 1) |
| XXI/XXIII-XXV Verification | Pass. RED-first, real-path cross-host replay, the Claude capture check at the iteration end |

## Risks and watch items

- **W1 before everything.** Until the pin is deployed, edits in this worktree's `scripts/internal` are live. W1
  is the only engine edit before its own deployment.
- **Iteration 001 reviews on today's engine.** Expect per-round approvals and the declared-vs-reply blocks until
  the deployment point; they are recorded as baseline evidence, not as defects of 203.
- **Copilot identity.** If W0 shows the two firings do not share an instant, the identity replacement comes to
  the before-implement boundary.
- **Twin copies.** The dispatcher and providers exist in two copies; the parity test keeps them aligned.
- **Codex as reviewer.** The file-delivery quirk is not a review failure.
