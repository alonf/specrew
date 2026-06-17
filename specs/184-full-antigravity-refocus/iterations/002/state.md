# Iteration State: 002

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T001 discovery (host-landscape premise confirmed; no split-guard trigger)
**Tasks Remaining**: T002, T003, T004, T005, T006
**In Progress**: (none)
**Baseline Ref**: abf18b99
**Updated**: 2026-06-17T16:40:00Z

## Charter

Iteration 002 closes the remaining Antigravity parity gap found by manual
dogfood after iteration 001. The slice is persistent host instructions at
`specrew init`, the prominent anti-raw-`specify.exe workflow` guard, bootstrap
front-loading/speedup, and real-host Opus/Flash validation.

Feature-closeout is not authorized in this iteration. Release carry-forwards
remain open: beta-before-stable, `MigrateLegacyTopLevelEventMap`
legacy-upgrade validation, and reproducible or explicitly machine-local `agy`
evidence.

## Specify Boundary

**Problem:** Antigravity refocus behavior exists, but weak/raw host sessions can
still miss the durable Specrew coordinator contract. The manual dogfood showed
three gaps: `AGENTS.md` was not deployed on the hook-only path, there was no
prominent guard against running the raw `specify.exe workflow`, and the path to
the workshop was slow on Opus and ineffective on Flash.

**Scope:** Add manifest-driven persistent instruction delivery during
`specrew init`; merge a Specrew-owned section into the host-declared
`InstructionsFile` without clobbering user content; put the coordinator contract
and anti-raw-workflow guard in both the persistent file and bootstrap; front-load
the bootstrap with the immediate Specrew action; keep shared core host-neutral;
validate with real-host Antigravity Opus 4.6 and Gemini Flash.

**Out of scope:** feature-closeout, release, beta/stable promotion, a general
host instruction overhaul beyond the manifest-driven path, and any full
Antigravity parity claim before iteration 002 evidence lands.

## Workshop Provenance

The iteration 002 product-domain and technical lens records are captured under
`iterations/002/workshop/`. The maintainer corrected the product pain and then
confirmed each selected lens one at a time: architecture-core,
component-design, integration-api, devops-operations, requirements-nfr, and
code-implementation. The records therefore use `human-confirmed` /
`lens-question` provenance.

## Next Action

Implementation authorized (`tasks -> before-implement` approved with
instructions, 2026-06-17). T001 discovery complete: the host-landscape premise
HOLDS for all hosts (no split-guard trigger; see `discovery-host-landscape.md`).
Next: T002 (packaged coordinator fragment + delimited managed-section merge
helper), then T003-T005; T006 (real-host Opus/Flash) is human-owned. Honor the
live split guard (stop for split/defer if a host diverges), the 20/20 zero-slack
cap, the host-neutral firewall, and single-source guard text (FR-018). Next human
stop: review-signoff.

## Carry Into Plan

- Size the cross-host instruction-delivery slice honestly against the restored
  20 SP cap: supported hosts x init/update/start refresh + FileList/template +
  guard + front-load + dual-model validation. Split instead of silently
  overrunning if this exceeds the cap.
- Enforce SC-014 with the host-coupling firewall. Add a negative test proving
  instruction-delivery code reads `InstructionsFile` from manifests and does not
  branch on host names.
- Put the anti-raw-Spec-Kit guard in both surfaces: the persistent instruction
  file and the front-loaded bootstrap, because a weak model may attend to only
  one.

## Notes

- Keep iteration 002 within the restored 20 SP cap; split instead of raising if
  the slice grows beyond the Antigravity-parity scope.
- Preserve user-owned instruction-file content; only the Specrew-owned section
  may be replaced.
- Keep the host-coupling firewall green.
- Planning scaffold helper was attempted but failed before writing `plan.md` on
  an existing StrictMode `.Count` issue; the plan artifact was authored directly
  and records this as a non-blocking planning note.
- Artifact-local checks passed for lens JSON shape/provenance, stale delegated
  workshop records, old single-file/deploy-path wording, and whitespace diff.
  Plan-boundary checks now pass for capacity arithmetic, traceability, host
  coupling firewall baseline, scoped governance validation, whitespace diff, and
  placeholder scan.
- Tasks boundary: `tasks.md` decomposed (T001-T006); bidirectional traceability
  PASS (every task -> >=1 FR/SC/TG and every FR-011..018 / SC-011..020 / TG-005
  -> >=1 task). Cursor reconciled to {iter-002, plan->tasks} and the `plan ->
  tasks` authorization recorded (verdict_history). The session-start integrity
  event (closed iter-001 re-scaffold from a stale cursor) is remediated and
  filed as GitHub issue #2784 (alonf/specrew); see drift-log.

<!-- >>> specrew-managed escalation-state >>> -->
## Repair Escalation

- **Status**: inactive
- **Artifact**: (none)
- **Gate**: (none)
- **Failure Count**: 0
- **Current Tier**: efficiency
- **Current Owner**: (none)
- **Locked Out Agents**: (none)
- **Last Escalated**: (none)
- **Resolved At**: (none)
- **Notes**: (none)
<!-- <<< specrew-managed escalation-state <<< -->

<!-- >>> specrew-managed resume-report >>> -->
## Resume Report

- **Timestamp**: 2026-06-17T14:39:12Z
- **Mode**: continue
- **Status**: ready
- **Last Completed Task**: specify boundary committed at 2d65f3ed
- **Next Suggested Task**: plan boundary
- **Next Recovery Action**: (none)
- **In-Progress Tasks**: (none)
- **Remaining Tasks**: T001, T002, T003, T004, T005, T006
- **Repair Escalation**: inactive
- **Blockers**: (none)
- **Salvageable Tasks**: n/a
<!-- <<< specrew-managed resume-report <<< -->
