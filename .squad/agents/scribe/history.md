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
