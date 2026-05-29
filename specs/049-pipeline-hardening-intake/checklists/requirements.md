# Requirements Checklist: F-049 Release Pipeline Hardening + Substantive Intake Slice

**Feature**: `049-pipeline-hardening-intake`

## Functional Requirements Checks

- [ ] **FR-001**: Docker-based test runner uses a Linux-based PowerShell LTS container (`mcr.microsoft.com/powershell:lts-ubuntu-22.04`).
- [ ] **FR-002**: The harness downloads and installs the previous stable version (v0.27.6) as the E2E verification baseline.
- [ ] **FR-003**: The harness verifies that every single item listed in the candidate's `Specrew.psd1` FileList unpacked correctly on disk.
- [ ] **FR-004**: The harness executes `specrew update` and verifies that updates succeed and mirror parity remains intact.
- [ ] **FR-005**: The Docker harness is wired into `.github/workflows/publish-module.yml` as a blocking pre-publish gate.
- [ ] **FR-006**: A comprehensive `docs/troubleshooting.md` guide is authored addressing standard install/update, caching gotchas, deployscript exceptions, and clean-reinstalls.
- [ ] **FR-007**: `docs/troubleshooting.md` is registered in `Specrew.psd1` FileList in the same commit.
- [ ] **FR-008**: `/speckit.specify` supports Product Manager, UX/UI, Architect, and AI Researcher / Project Manager personas.
- [ ] **FR-009**: The specify interface presents the 12-category intake catalog representing comprehensive parameters.
- [ ] **FR-010**: Intake dynamically branches into Mode A (Confirmation), Mode B (Targeted Clarifications), or Mode C (Interactive Interview).
- [ ] **FR-011**: Intake supports "Other" and "I don't know, you decide" options with proactive AI research capabilities.
- [ ] **FR-012**: The Docker harness includes a version pin drift assertion to detect mismatching version configurations (Prop 134 Pillar 1).

## Success Criteria Checks

- [ ] **SC-001**: Missing or corrupt layout candidates are blocked from publication (0% escaped omissions).
- [ ] **SC-002**: `docs/troubleshooting.md` exists, is registered in FileList, and is cross-referenced in other docs.
- [ ] **SC-003**: Persona-driven specify generates specs matching user intent with extremely low subsequent clarify cycles.
