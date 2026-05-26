# Requirements Checklist: F-048 Beta-Before-Stable SDLC Discipline

**Feature**: `048-beta-before-stable-sdlc`

## Functional Requirements Checks

- [ ] **FR-001**: Feature-closeout handoff includes `AGENT NEXT ACTION:`.
- [ ] **FR-002**: Feature-closeout handoff includes `HUMAN ACTION NEEDED:`.
- [ ] **FR-003**: Handoff enumerates Steps 5-14 in order with required actions.
- [ ] **FR-004**: Step 12 fail loop supports repeated beta attempts.
- [ ] **FR-005**: `docs/release-discipline.md` documents the release policy.
- [ ] **FR-006**: Stable publication is blocked until explicit human PASS.
- [ ] **FR-007**: Release audit record includes required structured evidence.
- [ ] **FR-008**: Release audit includes a human-readable per-feature narrative.
- [ ] **FR-009**: Default audit path supports a trailing one-file PR.
- [ ] **FR-010**: `release_audit_direct_to_main: true` opt-in is supported.
- [ ] **FR-011**: Direct-main shortcut is disabled unless explicitly enabled.
- [ ] **FR-012**: Missing release evidence prevents completed audit status.
- [ ] **FR-013**: Focused tests cover handoff/docs/audit/config behavior.
- [ ] **FR-014**: Mirrored extension files remain byte-identical.
- [ ] **FR-015**: Proposal/index metadata is updated where applicable.
- [ ] **FR-016**: Tag/publish/direct-main success cannot be inferred from
  missing credentials, workflow result, PR state, or human PASS evidence.

## Success Criteria Checks

- [ ] **SC-001**: Template checks find both ownership rows and Steps 5-14.
- [ ] **SC-002**: Synthetic FAIL loops to beta and blocks stable.
- [ ] **SC-003**: Release discipline docs cover the required policy surface.
- [ ] **SC-004**: Synthetic release creates one complete audit artifact.
- [ ] **SC-005**: Default vs direct-main audit behavior is tested.
- [ ] **SC-006**: Missing evidence keeps audits incomplete or failed.
- [ ] **SC-007**: Mirror parity passes for modified extension mirrors.
- [ ] **SC-008**: Focused tests and governance validation pass.
