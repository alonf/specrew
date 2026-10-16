# Implementation Plan: beta4.1 UX stabilization

**Feature**: 202-beta4-1-ux-stabilization
**Iterations**: 001 = Tier 1 (this plan's work breakdown); 002 = Tier 2, planned only after the maintainer accepts Tier 1 at the iteration-001 closeout
**Date**: 2026-10-13
**Branch**: `202-beta4-1-ux-stabilization` (from `24e5701a`; sync base `origin/201-first-run-experience`, not main)
**Inputs**:

- spec.md, approved for specify (out-of-band entry `auth-83b0f0c2...`, B4F-109) and clarify (hook-captured);
- iterations/001/design-analysis.md, with its Co-Design Record agreed 2026-10-13 (DA-1 to DA-5);
- implementation-rules.yml (the 199 manifest inherited, with the 202 amendments);
- the resolved quality profile, corrected below.

## Summary

Tier 1 removes the stops, repaints and silent failures that cost the maintainer turns without carrying a decision, and makes Codex workshop capture work as Claude's and Copilot's does. The work follows the governing UX principle and the quality priority: integrity, then parity, diagnosability, friction, latency. Every fix lands once in the shared path. Hosts stay declarative bindings (DA-1). Every fix is proven RED-first through the shipped entry point: the real launcher and dispatcher, fed recorded real payloads.

## Technical Context

- **Language/Version**: PowerShell 7.x (Windows, macOS, Linux); Markdown, YAML and JSON artifacts.
- **Primary Dependencies**: none new (dependency stance `use-existing-no-new-dependency`): .NET file APIs and Pester.
- **Storage**: append-only JSONL journals under `.specrew/runtime/`, plus `.specrew/start-context.json`. No database.
- **Testing**: Pester. The cross-host acceptance suite goes through the real launcher and dispatcher with recorded payloads (FR-024). Fault-injection cases a-e run with (e) on the Windows, macOS and Linux CI matrix (FR-025).
- **Target Platform**: the Specrew module and its host hooks for Claude, Codex and Copilot (validated tier); Cursor and Antigravity are experimental.
- **Performance Goals**: latency is recorded, not a driver. The journal retry is bounded to at most 5 attempts within 250 ms.
- **Constraints**:
  - no logic in host bindings beyond declared data and a named registry transform;
  - the hook never blocks over formatting;
  - integrity stores hold hashes only;
  - payload capture happens in scratch directories only;
  - the ledger is append-only.
- **Scale/Scope**: 11 Tier 1 findings and 24 FRs in iteration 001 (FR-001 to FR-021 and FR-024 to FR-026). Tier 2's FR-022 and FR-023 are excluded.

## Architecture

Bound by the design gate: the existing layered hooks (host bindings, launcher, dispatcher, providers, stores, readers), with no new layer. The agreed component map and flows are in iterations/001/design-analysis.md (Co-Design Record). Component-to-file anchors:

| Component | Files (source of truth; `.specify` mirrors and the `scripts/internal` / `extensions` twin copies sync in the same commit) |
| --- | --- |
| Host bindings: field maps, origin rules, named transform | `hosts/{claude,codex,copilot,cursor,antigravity}/host.psd1` (`RefocusHookBindings`) |
| Standard turn record + transform registry | `specrew-hook-dispatcher.ps1` (input block ~1148-1203) replacing `scripts/internal/bootstrap/HostEventAdapter.ps1` `ConvertFrom-SpecrewHostHookEvent` |
| Hook-output journal, retry, outage buffer, health journal | `specrew-hook-dispatcher.ps1` `Write-DispatcherHookOutputAuthorityRecord` (88-125) |
| Integrity check + receipt writer | `extensions/specrew-speckit/scripts/workshop-authority-store.ps1` (409-539, 541) |
| Receipt caller + disclosures | `scripts/internal/bootstrap/HandoverStore.ps1` `Update-SpecrewRollingHandover` (~1126-1234) |
| Stop decisions: presented memory, substance-only, meaning lines, system fill | `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` (774-818, 1196-1263, 1426, 1456-1526, 1866, 1970, 2106-2151, 2259-2272) |
| Turn-end store, draft intake, meaning-line check | `extensions/specrew-speckit/scripts/turn-end-store.ps1` (459-600), `declare-turn-end.ps1` (128-195) |
| Orientation + dials | `specrew-bootstrap-provider.ps1` (186-282), `scripts/internal/user-profile.ps1` (586-648) |
| Feature resolver, pointer, cycle reset, coverage line | `extensions/specrew-speckit/scripts/shared-governance.ps1` (1117-1167, 3983-4060, 7521-7697, 7995), `scripts/internal/sync-boundary-state.ps1` (604-717, 1041, 1983), `create-governed-feature.ps1` |
| Status / where | `scripts/specrew-where.ps1` (~482), `scripts/internal/dashboard-renderer.ps1` (399, 699, 1604-1646) |
| Resume narrative | `HandoverStore.ps1` `Get-SpecrewRollingHandover` (438), bootstrap provider (236-282), `coordinator-resume.ps1` (181) |
| Gate refusal names producer | `scripts/internal/design-analysis-gate.ps1` (637-645, 767-801) |
| Skills naming the draft path | the three turn-end skills (design workshop, gate stop, refocus surfaces), born-clean |

## Work breakdown, effort, and FR-to-test mapping (iteration 001)

**25.5 SP is planned against the 20 SP convention, an overcommit of 5.5 SP that is visible and not hidden.** The iteration is scope-bounded: the maintainer fixed Tier 1 as iteration 001, so the plan does not defer anything on its own (plan-boundary prompt 1). Review effort is governed by the codex round allowance, not by SP, per the 199 retro ruling. Every work item lands RED-first: the fixture reproduces the defect through the shipped entry point, then the fix turns it green.

| # | Work item | FRs | SP | RED fixture (through the shipped path) |
| --- | --- | --- | --- | --- |
| W1 | Capture real hook payloads (Claude, Codex, Copilot; Cursor/Antigravity only as a by-product) in scratch directories. Measure per host whether a session id is present (DA-4) and which hook output is shown directly to the user (DA-3) | FR-024 | 1.5 | Fixture files under `tests/fixtures/hook-payloads/<host>/`, with a provenance note (host version, date, scratch path). No governed worktree touched |
| W2 | `ConvertTo-SpecrewTurnRecord` + per-host field maps, origin rules (data) and the shared transform registry (Copilot replay / skipped question); both old normalizers removed; twin-copy parity test | FR-006 | 2.5 | `turn-record-contract.Tests.ps1`: every recorded payload through the real launcher and dispatcher yields the declared record; a Copilot replayed directive yields `host-injected`; the parity test fails on a one-byte twin drift |
| W3 | Journal: share mode allowing concurrent appends, bounded retry (5 attempts in 250 ms), per-process outage buffer read before the prompt decision and flushed then removed, health journal, legacy `.unhealthy` treated as degraded | FR-001..005, FR-008 | 3.0 | `hook-output-journal.Tests.ps1`: reproduces the latch (a held lock writes a permanent marker today); the fix clears on the next append; buffer read and flush; hashes-only assertion |
| W4 | B4F-108 disclosure: same-turn disclosure with consumed status; status/where health line; orientation line; the "selection channel" inference removed; the recovery question in project terms ("Nothing is deleted"); the approving receipt recorded | FR-007, FR-009, FR-010 | 2.0 | `receipt-disclosure.Tests.ps1`: degraded reply leads to a disclosure naming the cause and consumed status, never "selection channel"; message-content tests and the banned-noun check |
| W5 | Cross-host acceptance + fault injection: product-domain, agenda, one lens on each validated host through the real path (3 receipts, 1 reply per checkpoint); cases a-e, with (e) two real processes on the 3-OS CI matrix | FR-024, FR-025 | 2.5 | `cross-host-workshop.Tests.ps1`, `journal-fault-injection.Tests.ps1`; (e) runs as two `pwsh` processes |
| W6 | Presented-crossing memory per (session, crossing), cleared only by a context gap (crossing id or reviewed artifacts changed, SessionStart new/resume/compact, 8-hour gap; HEAD alone is NOT a gap); one-line mention; no `Stop hook error` | FR-011 | 2.0 | `crossing-presentation.Tests.ps1`: the three B4F-104 triggers lead to 0 repaints; an agent bookkeeping commit leads to no repaint; a compact leads to one repaint |
| W7 | Substance-only Stop: the declared meaning-line set (headings, review links, question, approval line, verdict options, marker) replaces the whole-draft comparison; deterministic lines are system-filled, marked and journaled | FR-012, FR-013, FR-015 | 2.0 | `presented-check.Tests.ps1`: a reworded draft keeping every meaning line passes; a dropped verdict option is named; a missing dials line is filled with 0 cycles |
| W8 | Orientation first: finished orientation supplied as system output on the first prompt; no duplicate on hosts that show hook output directly; session-scoped "bootstrap delivered" check | FR-014 | 1.5 | `orientation-order.Tests.ps1`: first-prompt payload carries the orientation; a host flagged direct-display yields no agent-rendered duplicate |
| W9 | One shared prose dials sentence; numeric renderer removed; adapter supplies only the correction-command reference | FR-016 | 1.0 | `dials-parity.Tests.ps1`: byte-identical across the three validated bindings (SC-005); no `=\d` keys |
| W10 | One feature resolver (DA-5 precedence with disclosure); pointer records its branch; `create-governed-feature.ps1` writes the pointer; status/where use the resolver; writer test | FR-017, FR-018 | 2.0 | `feature-resolver.Tests.ps1`: the 199-on-201 case, a stale pointer, Shipped vs in-flight, two competing in-flight features; every writer updates the pointer |
| W11 | Shared cycle-reset function (`feature-closeout -> specify` for a different feature) used by crossing calc + authorization writer; `feature_ref` on new entries/crossings; coverage line filtered by feature; legacy entries untouched | FR-026 | 2.0 | `new-feature-reset.Tests.ps1`: reproduces 202's no-crossing specify; after fix a crossing opens and the verdict captures with 0 out-of-band; coverage line never names 199's campaign (SC-009) |
| W12 | Resume from disk: pending crossing, `from_commit..HEAD`, progress; narrative as aged context, flagged when stale or naming another feature | FR-019 | 1.0 | `resume-from-disk.Tests.ps1`: reproduces the B4F-089 4a22ba8f shape |
| W13 | Gate refusal names the producing step (design-analysis) | FR-020 | 0.5 | `design-analysis-gate.Tests.ps1`: refusal text names the producer |
| W14 | Draft intake on stdin with explicit UTF-8 on every OS, stored at the per-session path; three skills name it | FR-021 | 1.0 | `turn-draft-intake.Tests.ps1`: Hebrew and other non-ASCII round-trip byte-exact on 3 OS (B4F-065 class); two sessions do not collide |
| W15 | Acceptance evidence: before/after friction table (null, not zero), validator run vs the known baseline, live-walk script for the three validated hosts (Codex on a healthy worktree) | SC-001, SC-003, SC-008 | 1.0 | Evidence artifacts under `iterations/001/`; the live walk is the maintainer's at closeout |

## Test strategy

- Deterministic Pester through shipped entry points. The cross-host suite drives the real launcher and dispatcher with each deployed binding, never the shared path directly.
- Paired honesty tests for every authority invariant: hook output never mints, and a typed reply mints exactly once.
- Message-content assertions for every disclosure and refusal; the banned-noun and gloss checks inherited from 199.
- Fault injection with real processes, and case (e) on three operating systems.
- Mirror parity, twin-copy parity and SelfLeakLintLane ride every commit. FileList order is not enforced yet; that is B4F-111, beta5.

## Quality plan (resolved profile, corrected)

The resolver returned a bounded custom composition (`quality-profile.custom-composition.v1`) and marked three dimensions not-applicable. **That reading is wrong for 202, and is overridden here with rationale:**

| Dimension | Resolver said | 202 plan | Why |
| --- | --- | --- | --- |
| concurrency-correctness | not-applicable | **required** | B4F-108's trigger is two hook processes appending at once; FR-001 and case (e) |
| resiliency | not-applicable | **required** | degraded state, self-recovery and outage buffer (FR-002..004) |
| retry-idempotency-and-recovery | not-applicable | **required** | bounded retry, buffer flush idempotence, recovery with an approving receipt (FR-002, FR-004, FR-009) |

The required lenses are `security-baseline`, `robustness-baseline` and `test-integrity`, routed to the strongest available reviewer (codex, human-authorized).

- **Security:** the integrity boundary (FR-005/006) is the sensitive surface, and the evidence is the paired never-mint fixtures.
- **Robustness:** W3/W4/W6.
- **Test integrity:** RED-first ordering, and instance-pinned fixtures.

`iterations/001/quality/hardening-gate.md` is completed before implement, at the before-implement boundary.

## Constitution Check

| Principle | Status |
| --- | --- |
| I Spec authoritative / VIII reconciliation | Pass. FR-018 reconciled at design-analysis with DRIFT-001; no silent divergence |
| II/XXVII Layered system | Pass. Fixes classified as Spec Kit extension (hooks, providers, stores); no Squad-layer change |
| III Supported extension surfaces | Pass. Host hook surfaces only; no host internals patched |
| IV Compatibility | Pass. Legacy marker migration, legacy ledger entries untouched, experimental hosts kept working |
| XV Human oversight | Pass. Recovery asks one decision; verdicts stay typed; the ledger is append-only |
| XVI Capacity-aware | Flagged. 25.5 SP against 20, overcommit visible (prompt 1) |
| XXI/XXIII-XXV Verification | Pass. RED-first, real-path cross-host suite, live walk at closeout |

## Risks and watch items

- **Twin copies.** The dispatcher and providers exist in two byte-identical copies. W2 adds a parity test, so a one-sided fix fails CI.
- **Host-visible hook output** (DA-3) and **session-id presence** (DA-4) are unknown until W1 measures them. W8 and W14 branch on those facts, and any host that cannot meet the design is reported at the before-implement boundary.
- **Origin `unknown` parity:** a host whose typed prompts and replays look identical must not have every reply blocked. The journal match is the defense, and W5 proves it.
- **Codex as reviewer:** the file-delivery quirk (empty stdout, findings in `.review/findings.jsonl`, possible "partial" label) is not a review failure.
- **This session dogfoods the defects.** B4F-104 and B4F-100 repaints may recur at this feature's own boundaries until W6/W7 land, and they are recorded as acceptance evidence.

## Iteration 002 (Tier 2)

Not planned here. It starts only after the maintainer's explicit Tier 1 acceptance at the iteration-001 closeout. Its design-analysis sets the exact review-ordering slices (FR-022) and the package-comparison scope (FR-023).

**First item (maintainer ruling, 2026-10-16): B4F-125**, approval intake, ahead of the review-ordering slice. (a) A phrase that leads its own line in the human's own message, with no pasted-transcript structure, is an approval; the B4F-065 guard tells a pasted transcript from a typed line instead of rejecting by position, and a refusal says why a recognized phrase did not count. (b) An allowance reset requested in order to run a round authorizes that round. (c) No approval request offers the human a command to run as the approval; the typed reply is the path. Each part gets a failing test built from `iterations/001/b4f-125-live-messages.json`.

**Proposed order (maintainer, 2026-10-16; decided at iteration 002's plan stop, not before):**

1. **B4F-127 first (critical):** bind every unbound approval (review round, allowance reset, partial sign-off override, stop-here decision, workshop receipts) to one human message by its transcript identity, not its text, and make the second recording path a no-op for a message already recorded. Failing test: one typed approval, then N turns with no human message, gives exactly one recorded approval.
2. **B4F-125** (approval intake, above), with **B4F-128** beside it: a reworded discussion question counts as present when its meaning matches, as headings already do.
3. **B4F-055:** demotion on form; a summary never says "nothing needs your attention" over real major findings.
4. **One simplification item** drawn from the runtime-store inventory in the iteration-001 retro.

Size: 15 SP or less. Review rounds are placed after the tasks that touch approval handling.

**Release gate (maintainer ruling at review sign-off, 2026-10-16):** closing iteration 001 is not a release. Beta4.1 does not ship (no merge to main, no published module) until B4F-127 is fixed in iteration 002.
