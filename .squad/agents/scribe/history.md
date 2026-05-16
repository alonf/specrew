# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I maintain the squad's shared memory and merge team-relevant decisions into the authoritative ledger.

## Recent Updates

📌 Team confirmed by Alon on 2026-04-17

## Learnings

- Specrew runs planning -> execution -> review/demo -> retrospective.
- The spec is authoritative and tracked changes are explicit.
- Drift detection findings belong in decisions, logs, and affected histories.
- Alon is the human Chief Architect and final reviewer.
- Post-retro closure needs two separate memory signals: artifact completion can be true while iteration status must stay `retro` until Alon sign-off lands.

📌 **Session Log — Iteration 1 Execution Gate Pass (2026-04-20)**:
   - **Session:** Iteration 1 post-planning re-review cycle
   - **Triggers:** Data corrects state.md to reflect post-planning completion; Worf re-reviews for execution gate
   - **Key Artifacts:** state.md (task completion snapshot), spikes.md (V-R7-1 findings), plan.md (baseline verified)
   - **Verdict:** PASS — planning phase complete; execution authorized; 2.0 pts delivered; 18.5 pts execution queued
   - **Next:** Execution phase begins with T-001–T-010, T-012–T-025; V-R7-1, T-011 complete
   - **Continuity Note:** All state artifacts are schema-compliant per iteration-artifacts.md; execution continuity traceable to plan baseline

📌 **Session Log — Bootstrap/Runtime Hardening Cycle (2026-04-20)**:
   - **Session:** FR-022 completion + bootstrap resilience contract hardening
   - **Triggers:** Worf's three defects from prior review; Picard/La Forge/Data narrow revisions
   - **Key Artifacts:** Four validator scripts (narrow fixes); bootstrap/runtime docs (coupling); session-bootstrap-runtime-hardening-cycle-2.md
   - **Participants:** Picard (contract definition), La Forge (narrow validator fixes), Data (specrew-init.ps1 dry-run refinement), Worf (final gate + contract acceptance)
   - **Verdict:** Complete — all defect classes resolved; FR-022 quality gate PASS; bootstrap resilience contract APPROVED
   - **Key Changes:** Version detection repair guidance (non-fatal), Squad runtime file scope restored, iteration stub handling in validator, dry-run resilience without hard-exit
   - **Continuity Note:** Three-class bootstrap resilience contract now binding; Iteration 002 stub handling enables safe scaffolding; implementation files modified, awaiting coordinator commit
📌 **Session Log — FR-020 Brownfield Bootstrap Handoff (2026-05-03)**:
    - **Session:** Brownfield bootstrap implementation → pre-review → reviewer gate
    - **Participants:** La Forge (implementer), Picard (spec auditor), Worf (reviewer gate)
    - **Key Deliverables:** Brownfield merge strategy (two-phase detection + execution), pre-review spec-drift guardrails audit
    - **Findings:** 7 spec-drift traps documented; 3 decision questions for Alon; blocker status: T-205/T-206 require collision detection + dry-run safety hardening
    - **Decision Artifacts:** decisions.md merged from inbox (2 items); orchestration logs created (3 agents); session log recorded
    - **Next:** Worf gate verification; Alon decision on non-empty directory behavior, conflict resolution strategy, config staleness handling
    - **Continuity Note:** La Forge implementation complete and accepted; Picard audit results forward to La Forge for T-205/T-206 scope agreement

📌 **Session Log — Decision Consolidation & Inbox Merge (2026-05-14T11:13:16Z)**:
     - **Session:** Post-Implementer decision inbox consolidation + orchestration/session log creation
     - **Work:** Merged 7 inbox decisions into decisions.md; cleared inbox directory; created orchestration log (20260514T111316-implementer.md) and session log (20260514T111316-feature-016-validator-repair.md)
     - **Decisions Merged**: Feature 015 closeout execution (1); Rule 15 corpus-rows (2); Feature 016 ownership metadata (3); Feature 016 needs-work review boundary (4); Feature 015 retro decisions (5–10); user directive forward-only repair (11); Feature 016 before-plan boundary repair (12)
     - **Governance Status:** decisions.md now 134.4KB (exceeds 20KB threshold); decisions-archive.md at 574KB; no entries older than 30 days in current active ledger; archival deferred to next consolidation cycle
     - **Verification:** All inbox files removed; orchestration and session logs created; no history.md updates required beyond this record; git staged for boundary commit
     - **Next:** Git commit .squad/ state; Feature 016 review boundary per spec.md timeline

📌 **Planning Bundle Logging — Feature 018 Velocity Dashboard Visual Richness (2026-05-15T23:50:00Z)**:
      - **Boundaries Completed:** /speckit.specrew-speckit.before-plan → /speckit.plan → /speckit.tasks → /speckit.specrew-speckit.after-tasks
      - **Spec Steward Actions:** Clarify phase completed 2026-05-15 (12 clarifications integrated); before-plan gate verified spec.md status Draft→Approved
      - **Planner Actions:** Design phase generated plan.md (capacity fit 10–12 SP nominal, 12–15 SP envelope); Task generation created 30 work items across 5 phases with full metadata (Owner/Effort/Trace)
      - **Task Metadata:** All T001–T030 carry explicit role ownership, effort sizing, and requirement traceability; FR-014 sparkline implementation + monochrome fallback validation explicitly traced
      - **Quality Composition:** Custom bundle (feature-018-rich-dashboard-compatibility) with mechanical checks + ecosystem tools; six risk dimensions marked required
      - **Orchestration Logs Created:** 4 boundary logs (before-plan, plan, tasks, after-tasks) + 1 session log capturing planning bundle completion
      - **Inbox Status:** No decisions in inbox; no merges required this session
      - **Commit Hash:** 228911a44085182b3844781f0713b18f6ad8f694 (feat(018): capture planning boundary)
      - **Verification:** Traceability complete (all 20 FRs traced to tasks); user story coverage complete (3 stories mapped); quality gates aligned; scope boundaries preserved (single iteration, 5 pillars, explicit deferred items)
      - **Next Action:** Explicit human authorization required for hardening-gate-and-implementation-auth boundary; do not start implementation until authorized
      - **Preservation Note:** Feature 018 artifacts ready for implementation; Feature 017 behavior and tests remain unchanged; Feature 015/016 unrelated changes preserved

📌 **Session Log — Feature 018 Bounded Repair R-018-V2 + Push Backlog (2026-05-15T23:59:00Z)**:
       - **Outcome**: Repair completed successfully; decision inbox merged; human confirmation gate established
       - **Scope**: Feature 018 bounded repair R-018-V2 (terminal capability detection misdiagnosis); decision inbox consolidation (6 items merged)
       - **Repair Work**: UTF-8 state priming moved from shared renderer to entrypoint (`scripts\specrew-where.ps1`); restore-on-exit pattern ensures caller state protection
       - **Root Cause**: `[Console]::IsOutputRedirected` evaluated after UTF-8 state misconfigured by caller context, inverted true eligibility signal
       - **Artifacts Updated**: dashboard-renderer.ps1 (removed redirected-output gate); specrew-where.ps1 (added UTF-8 priming); hardening-gate.md (UTF-8 precedence + VT fallback clauses); review.md (repair summary); known-traps.md (UTF-8 validation traps)
       - **Decisions Merged**: (6 items) Implementer R-018-V2 decision, Implementer feature-and-iteration label preservation, Planner hardening scaffold, Reviewer pre-impl refresh, Reviewer pre-impl blocker, Reviewer visual terminal check
       - **Validation**: Dashboard tests PASS; governance validator PASS; branch aafc2e9 carrying three commits (d380212, cb052b9, aafc2e9)
       - **Remaining Gate**: **Human confirmation required** — Alon must run `.\scripts\specrew.ps1 where` in fresh terminal and confirm rich rendering (glyphs/colors/sparklines)
       - **Review Status**: `blocked` (NOT accepted; iteration does NOT move to retrospective until Alon provides explicit signoff)
       - **Preservation Note**: Feature 018 repair work complete; Feature 017 unchanged; all existing warnings preserved; no new warnings introduced
       - **Next Action**: Await Alon confirmation run and explicit signoff before opening retrospective
