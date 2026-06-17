# Iteration State: 002

**Schema**: v1
**Current Phase**: plan
**Iteration Status**: specify-approved
**Last Completed Task**: specify boundary approved
**Tasks Remaining**: (not planned yet)
**In Progress**: (none)
**Baseline Ref**: abf18b99
**Updated**: 2026-06-17T14:39:12Z

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

Specify is approved content-wise and must be committed as a focused
`boundary(specify)` commit before planning advances. The next boundary is plan
for the iteration 002 scope; do not implement, open feature-closeout, or start
release work without the next explicit human verdict.

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
- Artifact-local checks passed for lens JSON shape/provenance, stale delegated
  workshop records, old single-file/deploy-path wording, and whitespace diff.
  Scoped governance validation is not green yet because iteration 002 has no
  `plan.md`; that is expected until the next plan boundary materializes it.

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
- **Last Completed Task**: specify boundary approved
- **Next Suggested Task**: plan boundary
- **Next Recovery Action**: (none)
- **In-Progress Tasks**: (none)
- **Remaining Tasks**: (not planned yet)
- **Repair Escalation**: inactive
- **Blockers**: (none)
- **Salvageable Tasks**: n/a
<!-- <<< specrew-managed resume-report <<< -->
