# Retro Facilitator History

Project-specific learnings and patterns discovered during work.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->

**Pattern:** Effort estimation remains accurate when task boundaries are clear and Phase-N clarity work is complete before iteration starts. **Context:** Iteration 002 delivered all 7 tasks at estimated effort (zero variance) because Phase 1 scope was well-defined from prior planning, and no discovery surprises emerged during implementation. When starting a new phase or feature, front-load clarification work so subsequent iteration estimation benefits from stable scope.

**Pattern:** Fail-closed governance enforcement prevents silent compliance gaps but requires upfront configuration of test-command harness. **Context:** Iteration 002 implemented required-gate enforcement successfully, but coverage verification defaulted to `not_executed` because reviewer config did not declare test commands. This pre-existing gap should be resolved before Phase 2 iterations begin, to prevent discovery of missing validation infrastructure at the wrong phase boundary.

**Pattern:** Infrastructure scaffolding scales cleanly when coupled to existing artifact flows rather than creating parallel mechanisms. **Context:** Adding `quality-evidence.md` and `mechanical-findings.json` to the iteration artifact surface worked because the publish flow was integrated into existing reviewer and scaffold paths. No coupling rework was needed.

## Learnings

**Lesson:** Approval scope must be tethered to the active iteration slice, not inherited from prior decisions. Reusing approval evidence across iteration boundaries creates false confidence. Always refresh approval scope when a plan is resliced or deferred. **(Feature 008 Iteration 002)**

**Lesson:** Human-direction hold messages must bridge governance language and human action. The original message was too governance-internal. The fix: use a three-section rule — (1) why-we-stopped, (2) what-you-can-do, (3) who-to-escalate-to. Embed this in coordinator guidance and reviewer charters. **(Feature 008 Iteration 002)**

**Lesson:** Startup-loaded configuration files (.github/agents/squad.agent.md, .specify extension templates) are not re-read mid-session. Changes to these files require an explicit iteration-boundary commit and session restart via specrew-start.ps1. Document this boundary for future iterations that touch startup-loaded surfaces. **(Feature 008 Iteration 002)**

**Lesson:** User-facing handoff paths require execution-time testing of the full scaffolded replay surface, not just runtime state artifacts. When implementing handoff features, ensure the complete pipeline (scaffold → digest → parse) is exercised in automated tests before marking complete. Coverage of runtime config/ledger/state alone is insufficient. **(Feature 008 Iteration 003, G-001)**

**Lesson:** Duplicate function definitions create silent maintenance risk even when syntax is correct. Add post-implementation validation that searches for duplicate definitions in PowerShell scripts. S-001 (duplicate Get-IterationReference in manage-reviewer-regression.ps1) was not caught until review. **(Feature 008 Iteration 003, S-001)**

**Lesson:** Reviewer-regression event detection is working correctly when zero events fire during Squad review cycles. G-001 was a first-pass finding against never-approved work, not a regression against a prior approval. Continue tracking reviewer-regression events in each iteration closeout; zero events does not indicate broken detection logic, it confirms stable Squad review quality. **(Feature 008 Iteration 003)**

**Lesson:** When a prior iteration surfaces a lesson tied to a specific mandate, embedding that mandate into the next iteration plan ensures proactive discipline rather than reactive discovery. Iteration 003 required rework to close the G-001 replay-path visibility gap. Iteration 004 plan explicitly mandated scaffolded replay-path coverage for T020–T026 handoff tasks. The team honored this mandate in test design from the outset, resulting in zero replay-path visibility gaps at review and first-pass acceptance. Reactive fixes become working discipline when the lesson is named, mandated, and carried forward explicitly. **(Feature 008 Iteration 004)**

**Lesson:** Richer pre-sign-off hardening-gate schemas (Overall Verdict + explicit pending-metadata fields) are superior to blocked-only conventions. Iteration 005 used this schema to signal planning readiness while showing which governance fields remained pending. At sign-off, fields updated atomically rather than blocking the entire gate. This convention prevents approval-inheritance drift and tethers scope to the active iteration. Embed as Spec 005 Phase 2 enforcement baseline across the feature portfolio. **(Feature 008 Iteration 005)**

**Lesson:** Approval-recording boundaries require honest independent repair after review catches stale status and paraphrased evidence. Iteration 004 review identified approval-recording gaps (scope inheritance from prior cycles). Iteration 005 hardening-gate refreshed approval explicitly, with Alon Fliess signing off on 2026-05-11 scoped to the Polish slice. The Approval Ref now traces to active governance decisions, not prior cycles. Formalize this repair as a known trap: scan every hardening gate Approval Ref against the active .squad/decisions.md ledger; trace must point to recorded explicit approval for the active iteration, not inferred from prior messages. **(Feature 008 Iteration 005)**