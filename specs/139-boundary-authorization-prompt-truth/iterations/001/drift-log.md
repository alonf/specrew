# Drift Log: Iteration 001

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 6
**Resolution rate**: 100% (6/6 resolved)
**Specification drift**: Resolved by human-approved spec/task reconciliation before implementation

## Events

### D-001 — Post-tasks gate-format refinements required traceability update

- **Detected At**: 2026-06-01T10:05:44Z
- **Type**: human-decision
- **Status**: resolved
- **Source**: Human approval for `tasks -> before-implement` added final generated gate-format refinements after the tasks boundary.
- **Impact**: The original spec/tasks covered the six-section packet but did not explicitly cover no legacy `=== SPECREW HANDOFF ===` duplication, grouped discussion prompts with "approve with defaults", `discuss prompt #N`, high-impact/release-blocking review callouts, or renewed approval after a prompt-specific discussion loop.
- **Resolution**: Updated [spec.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/spec.md), [tasks.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/tasks.md), [plan.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/plan.md), and [boundary-authorization-prompt-truth.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/contracts/boundary-authorization-prompt-truth.md) before implementation.
- **Follow-up**: Implementation must execute T017-T021 and review must verify SC-012 through SC-015.

### D-002 — Implementation preflight classification and test discovery

- **Detected At**: 2026-06-01T10:25:00Z
- **Type**: implementation-preflight
- **Status**: resolved
- **Source**: Human approval for `before-implement -> implement` required T001-T003 before editing implementation files.
- **Impact**: Implementation must keep the beta2 smoke failure, Feature 016 one-boundary re-entry intent, Proposal 145 review lens, and the clarified six-section packet in scope while excluding unrelated dirty runtime/session files.
- **Resolution**: Loaded Proposal 154, the beta2 smoke failure, the Feature 016 three-section handoff contract, the clarified six-section Feature 139 packet, and Proposal 145 as a review lens. No implementation-context gaps were found; Proposal 154's embedded five-section packet is superseded by the human-approved six-section contract in the Feature 139 spec.
- **Dirty State Classification**: Existing dirty files under `.codex/`, `.github/agents/squad.agent.md`, `.specrew/last-validator-summary.json`, `.squad/`, `specs/051-multi-session-foundation/iterations/003/tasks-progress.yml`, `.cursor/`, `.specrew/version-check-cache.json`, and `.squad/events/` are classified as pre-existing session/runtime or unrelated feature state. They remain excluded from Feature 139 staging unless explicitly reclassified before editing.
- **Focused Test Discovery**: Selected `tests/integration/start-command.ps1` for generated start prompt/start-context coverage, `tests/integration/launch-mode-boundary-enforcement.tests.ps1` for policy-state behavior, `tests/unit/validate-governance.interaction-model.tests.ps1` and new Feature 139 fixtures for handoff compliance, plus validator coverage in `extensions/specrew-speckit/scripts/validate-governance.ps1` and its `.specify` mirror for the narrow `Status: Approved` contradiction check.
- **Follow-up**: Implementation must update only required Feature 139 source/tests and must keep full Proposal 150, hook enforcement, broad Proposal 151 migration, and lifecycle redesign out of scope.

### D-003 — Adjacent Feature 016 docs/test truth defect blocked implementation review

- **Detected At**: 2026-06-01T10:58:00Z
- **Type**: adjacent-defect
- **Status**: resolved
- **Source**: Human send-back after implementation noted that `tests\unit\validate-governance.interaction-model.tests.ps1` was still failing.
- **Exact Assertion**: `Assert-True -Condition ($readmeText -match 'Post-Commit Verification Protocol') -Message 'Docs/template truth scenario is missing the README post-commit verification protocol.'`
- **Classification**: Feature 139 exposed an existing Feature 016 documentation defect; it did not cause the failure. The Feature 139 implementation did not modify `README.md`, and the failure asserts an existing docs/template-truth contract from Feature 016 Iteration 002.
- **Impact**: Implementation review could not proceed with a known failing required test.
- **Resolution**: Added the missing `Post-Commit Verification Protocol` section to [README.md](file:///C:/tmp/Specrew-main-boundary-auth/README.md), preserving the Feature 016 exact-tree, stale-reference scan, commit-reference synchronization, and explicit-defer contract.
- **Follow-up**: Rerun the full required test set before stopping again at `implement -> review`.

### D-004 — Packet-wide clickable artifact reference enforcement gap

- **Detected At**: 2026-06-01T12:15:00Z
- **Type**: regression-enforcement-gap
- **Status**: resolved
- **Source**: Human send-back after retro noted that the live gate packet still allowed bare repository artifact references outside the primary review-target sentence.
- **Requirement Citation**: FR-012 requires targeted `file:///` review surfaces, FR-024 requires bare `file:///` links in primary packet review targets, and Feature 016 / Proposal 007 require artifact references in boundary handoffs to be navigation-ready instead of bare repository paths.
- **Impact**: The implemented prompt guidance and validator coverage protected review targets but did not make the rule explicit for every packet section, and the validator evidence path did not hard-fail stored emitted packet text when a boundary sync supplied handoff evidence.
- **Classification**: Feature 139 regression and enforcement gap. This is in-scope because Feature 139 owns the new human re-entry packet contract and its prompt/validator enforcement.
- **Resolution**: Updated [specrew-start.ps1](file:///C:/tmp/Specrew-main-boundary-auth/scripts/specrew-start.ps1), [coordinator governance template](file:///C:/tmp/Specrew-main-boundary-auth/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md), the mirrored [coordinator governance template](file:///C:/tmp/Specrew-main-boundary-auth/.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md), [handoff-governance-validator.ps1](file:///C:/tmp/Specrew-main-boundary-auth/extensions/specrew-speckit/validators/handoff-governance-validator.ps1), the mirrored [handoff-governance-validator.ps1](file:///C:/tmp/Specrew-main-boundary-auth/.specify/extensions/specrew-speckit/validators/handoff-governance-validator.ps1), [validate-governance.ps1](file:///C:/tmp/Specrew-main-boundary-auth/extensions/specrew-speckit/scripts/validate-governance.ps1), and the mirrored [validate-governance.ps1](file:///C:/tmp/Specrew-main-boundary-auth/.specify/extensions/specrew-speckit/scripts/validate-governance.ps1). The packet rule now applies to every packet section; bare `specs/...`, `.specrew/...`, `.squad/...`, `tests/...`, and `README.md` references fail outside command/code exemptions; stored `.specrew/handoff-evidence.json` packet text is validated.
- **Verification**: [validate-governance.interaction-model.tests.ps1](file:///C:/tmp/Specrew-main-boundary-auth/tests/unit/validate-governance.interaction-model.tests.ps1) and [boundary-authorization-prompt-truth.tests.ps1](file:///C:/tmp/Specrew-main-boundary-auth/tests/unit/boundary-authorization-prompt-truth.tests.ps1) pass after the repair.
- **Follow-up**: Re-emit the `retro -> iteration-closeout` packet using only `file:///` artifact references and record that packet as boundary evidence.

### D-005 — Visible packet and stored packet evidence diverged

- **Detected At**: 2026-06-01T13:20:00Z
- **Type**: emitted-packet-evidence-parity-gap
- **Status**: resolved
- **Source**: Human send-back after iteration-closeout noted that the visible `What needs your review` section still presented bare repository artifact references for the iteration dashboard, hardening gate, drift log, and quality evidence.
- **Requirement Citation**: D-004 and Feature 139 closeout acceptance require every artifact, file, or directory reference in every human re-entry packet section to use `file:///` URL form, and require stored boundary packet evidence validation to check the actual emitted packet text.
- **Impact**: The handoff validator catches the exact bare primary-review-section case when supplied as packet text, but the human-visible response can still diverge if an agent validates one packet through boundary sync and then rewrites or summarizes the final approval packet outside that stored evidence path.
- **Classification**: Feature 139 enforcement/evidence discipline gap. The validator did not miss the exact case; the failure was that the final visible packet was not treated as the same text that had been stored and validated.
- **Resolution**: Strengthened [specrew-start.ps1](file:///C:/tmp/Specrew-main-boundary-auth/scripts/specrew-start.ps1), [coordinator governance template](file:///C:/tmp/Specrew-main-boundary-auth/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md), and the mirrored [coordinator governance template](file:///C:/tmp/Specrew-main-boundary-auth/.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md) so the packet text recorded as boundary evidence must be the exact human-visible packet emitted for approval, with no post-validation summary or artifact-reference rewrite.
- **Verification**: [boundary-authorization-prompt-truth.tests.ps1](file:///C:/tmp/Specrew-main-boundary-auth/tests/unit/boundary-authorization-prompt-truth.tests.ps1) now includes the exact primary `What needs your review` bare-path case reported in this send-back and asserts all four bare repository paths hard-fail.
- **Follow-up**: Re-emit the `iteration-closeout -> feature-closeout` packet with visible `file:///` review targets in the primary six-section packet and record that exact packet as boundary evidence.

### D-006 — Markdown-link packet references bypassed visible URI enforcement

- **Detected At**: 2026-06-01T14:10:00Z
- **Type**: common-enforcement-path-regression
- **Status**: resolved
- **Source**: Human send-back after feature-closeout noted that the primary six-section packet still surfaced non-clickable artifact references even though the legacy `=== SPECREW HANDOFF ===` block used `file:///` links.
- **Requirement Citation**: D-004 requires every artifact, file, or directory reference in every human re-entry packet section to use visible `file:///` URL form. D-005 requires the stored boundary packet evidence to be the exact human-visible approval packet and rejects any approval packet that was not stored and validated as that visible packet.
- **Impact**: The common validator stripped markdown file links such as `[dashboard.md](file:///...)` before bare-path scanning, so a packet could pass validation while the terminal-visible primary packet hid the clickable `file:///` target behind markdown syntax. The sync path also recorded handoff evidence after boundary state advancement and only warned on recording failure, so invalid packet evidence was not a pre-advance hard gate.
- **Classification**: Feature 139 enforcement-path regression. This is in-scope because Feature 139 owns the human re-entry packet contract, stored packet evidence parity, and packet-wide clickable-reference enforcement.
- **Resolution**: Updated [handoff-governance-validator.ps1](file:///C:/tmp/Specrew-main-boundary-auth/extensions/specrew-speckit/validators/handoff-governance-validator.ps1) and the mirrored [handoff-governance-validator.ps1](file:///C:/tmp/Specrew-main-boundary-auth/.specify/extensions/specrew-speckit/validators/handoff-governance-validator.ps1) so markdown file links in boundary handoffs hard-fail with `validation-fail.markdown-file-url-in-boundary-handoff`. Updated [sync-boundary-state.ps1](file:///C:/tmp/Specrew-main-boundary-auth/scripts/internal/sync-boundary-state.ps1) so supplied handoff text is validated before boundary state advancement. Updated [specrew-start.ps1](file:///C:/tmp/Specrew-main-boundary-auth/scripts/specrew-start.ps1) to remove the contradictory markdown-link guidance and require visible bare `file:///` URLs in generated lifecycle instructions.
- **Verification**: [boundary-authorization-prompt-truth.tests.ps1](file:///C:/tmp/Specrew-main-boundary-auth/tests/unit/boundary-authorization-prompt-truth.tests.ps1) now covers the exact failure where the primary six-section packet has bare `specs/...` paths while the legacy handoff block is compliant, the related markdown-link escape where the primary packet uses `[name](file:///...)`, stored packet evidence validation for both cases, and boundary-sync rejection before state advancement.
- **Follow-up**: Re-emit the `feature-closeout -> release-closeout` packet using visible bare `file:///` URLs in the primary six-section packet, store that exact visible packet as boundary evidence, and stop for explicit release-closeout approval.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
