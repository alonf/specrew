# Plan: F-048 Beta-Before-Stable SDLC Discipline

**Feature**: `048-beta-before-stable-sdlc`  
**Date**: 2026-05-26  
**Status**: Draft  
**Input**: User-approved F-048 scope: codify beta-before-stable SDLC,
release-discipline documentation, and post-merge release audit trail.

---

## 1. Summary & Goals

Deliver the beta-before-stable release discipline as first-class Specrew
governance. F-048 makes the coordinator feature-closeout handoff agent-owned
instead of human-owned, documents the release rule in
`docs/release-discipline.md`, and adds a post-merge audit trail so every
runtime-affecting feature can prove beta publication, human PASS, stable
publication, and final audit capture.

The feature is intentionally split into two iterations:

- **Iteration 001**: coordinator handoff template, documentation, tests, and
  proposal/index metadata. This makes the SDLC rule visible before new audit
  automation ships.
- **Iteration 002**: release audit CLI/helper, schema/file format,
  direct-main config flag, trailing one-file PR behavior, and tests.

---

## 2. Clarify Outcome

No human clarification is pending. The originating request fixed the three
product decisions, and `spec.md` records the only reconciliation choice:
the default post-merge audit artifact will be one per-feature Markdown file
with structured front matter plus a human-readable narrative. This satisfies
both the structured-record requirement and the trailing one-file PR
requirement.

---

## 3. Substantive Decisions

### Decision 1: One audit file per feature

Use `docs/releases/<feature-ref>.md` as the release audit artifact. It contains
YAML front matter with `schema: specrew.release-audit.v1` and the required
structured fields, followed by a readable narrative timeline. This keeps
locked-main repositories compatible with a trailing one-file PR per feature.

### Decision 2: Direct-main shortcut is explicit and project-local

Add `release_audit_direct_to_main: true` as an opt-in project configuration
flag. Missing or false means the audit helper uses the trailing one-file PR
path. This repository may set the flag true because it is unlocked, but tests
must prove the default remains protected-main friendly.

### Decision 3: CLI surface

Add a top-level CLI route:

```text
specrew release-audit capture --feature <ref> --pr <number> --merge-sha <sha> \
  --version <semver> --beta-tag <tag> --beta-verification <text> \
  --human-verdict PASS|FAIL --stable-tag <tag> --stable-verification <text>

specrew release-audit validate --feature <ref>
```

`capture` writes or updates the per-feature audit artifact. `validate` reads
the artifact and rejects incomplete or contradictory release evidence. The
implementation may expose extra flags such as `--project-path`, `--mode`,
`--dry-run`, or `--open-pr`, but the contract above is the minimum public
surface.

### Decision 4: Stable promotion requires explicit PASS

Neither docs nor audit tooling may infer success from tag existence, workflow
existence, credentials, or missing evidence. A stable release is complete only
when beta publication was verified, the human verdict is explicit `PASS`, and
stable publication was verified.

### Decision 5: Mirror parity remains mandatory

Any change under `extensions/specrew-speckit/` that has a mirror under
`.specify/extensions/specrew-speckit/` must be byte-identical. F-048 is likely
to touch coordinator/squad templates, so mirror checks are part of every review.

### Decision 6: No supplemental Crew member yet

The baseline Specrew roles are sufficient for planning. The security-sensitive
parts are release credentials, stable-publish gating, and direct-main behavior;
they are covered by the Reviewer with the security and robustness hardening
lenses. If implementation exposes a credential-handling gap, add a Security
Specialist before continuing that slice.

---

## 4. Planning Artifacts

- **Data Model**: [data-model.md](file:///C:/Dev/Specrew/specs/048-beta-before-stable-sdlc/data-model.md)
- **Quickstart**: [quickstart.md](file:///C:/Dev/Specrew/specs/048-beta-before-stable-sdlc/quickstart.md)
- **Contract**: [contracts/beta-before-stable-sdlc.md](file:///C:/Dev/Specrew/specs/048-beta-before-stable-sdlc/contracts/beta-before-stable-sdlc.md)
- **Review Diagrams**: [review-diagrams.md](file:///C:/Dev/Specrew/specs/048-beta-before-stable-sdlc/review-diagrams.md)

---

## 5. Implementation Slices

### Iteration 001: SDLC Prompt + Documentation

**Slice 1: Handoff ownership template (FR-001/002/003/004)**

- **Files**: `scripts/specrew-start.ps1`,
  `extensions/specrew-speckit/prompts/coordinator-response.md`,
  `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`,
  `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`,
  and `.specify/` mirrors where present.
- **Approach**: Replace the feature-closeout handoff row that places
  push/PR/merge under `HUMAN ACTION NEEDED` with split ownership rows:
  `AGENT NEXT ACTION:` executes Steps 5-14; `HUMAN ACTION NEEDED:` approves
  agent actions and provides the Step 11 PASS/FAIL verdict.
- **Tests**: Extend the existing handoff/governance test surface or add
  `tests/integration/beta-before-stable-sdlc.tests.ps1` with template content
  assertions.

**Slice 2: Release discipline docs (FR-005/006)**

- **Files**: `docs/release-discipline.md`.
- **Approach**: Codify `[[feedback-beta-publish-before-stable-2026-05-26]]`,
  including proposal-only exemptions, PSGallery beta validation commands, PASS
  gate, fail-loop, stable promotion, audit capture, and stop-before-new-feature
  behavior.
- **Tests**: Documentation coverage assertions for Steps 5-14, explicit PASS,
  proposal-only exemption, locked-main audit PR, and direct-main opt-in.

**Slice 3: Proposal/index metadata (FR-015)**

- **Files**: `proposals/060-prerelease-channel-staging.md`,
  `proposals/131-coordinator-prompt-sdlc-ownership-clarification.md`,
  `proposals/INDEX.md`.
- **Approach**: Mark the shipped or in-progress scope accurately when the
  implementation lands; avoid claiming Iteration 002 audit automation shipped
  until it has.

### Iteration 002: Post-Merge Release Audit Trail

**Slice 4: Release audit helper + CLI (FR-007/008/009/010/011/012/016)**

- **Files**: `scripts/internal/release-audit.ps1`,
  `scripts/specrew-release-audit.ps1`, `scripts/specrew.ps1`,
  `.specrew/config.yml`, and relevant packaged file lists if needed.
- **Approach**: Implement the `specrew release-audit capture|validate` surface.
  `capture` writes `docs/releases/<feature-ref>.md` with structured front
  matter and narrative body. Default mode prepares a trailing one-file PR; the
  explicit config flag permits direct-main capture. `validate` refuses complete
  status without required release evidence and explicit human PASS.
- **Tests**: `tests/integration/release-audit.tests.ps1` covering successful
  capture, missing evidence, explicit FAIL, default trailing-PR selection, and
  direct-main selection.

**Slice 5: Package and governance integration (FR-013/014)**

- **Files**: packaging manifests and extension mirrors as required by the
  touched implementation files.
- **Approach**: Keep FileList/manifest packaging current if a new script is
  shipped; verify mirror parity; run focused tests plus governance validation.

---

## 6. FR to Test Mapping

| FR | Verified by |
| --- | --- |
| FR-001 | Handoff template assertion finds `AGENT NEXT ACTION:` |
| FR-002 | Handoff template assertion finds `HUMAN ACTION NEEDED:` |
| FR-003 | Template assertion validates Steps 5-14 in order |
| FR-004 | Synthetic FAIL validates Step 12 beta loop semantics |
| FR-005 | Documentation coverage test for `docs/release-discipline.md` |
| FR-006 | Documentation and audit tests block stable without PASS |
| FR-007 | Release audit capture test validates structured fields |
| FR-008 | Release audit capture test validates readable narrative body |
| FR-009 | Default config test selects trailing one-file PR behavior |
| FR-010 | Config true test selects direct-main behavior |
| FR-011 | Missing/false config test rejects direct-main shortcut |
| FR-012 | Missing evidence and non-PASS tests keep audit incomplete |
| FR-013 | Focused integration suites for handoff/docs/audit/config |
| FR-014 | SHA256 or `diff -q` mirror-parity check |
| FR-015 | Proposal/index content assertions or reviewer checklist |
| FR-016 | Negative tests for missing credentials/workflow/verdict evidence |

---

## 7. Quality Planning

Resolved profile: `quality-profile.custom-composition.v1`.

Required risk dimensions:

| Risk Dimension | Status | F-048 Application |
| --- | --- | --- |
| `code-quality` | required | Keep parser/helper code small, deterministic, and testable. |
| `design-quality-and-separation-of-concerns` | required | Separate template wording, release docs, audit record generation, and CLI dispatch. |
| `verification-confidence` | required | Use negative-path tests for FAIL verdicts, missing evidence, and config defaults. |
| `maintainability` | required | Use one schema version and one per-feature artifact convention. |
| `security` | required | Do not infer publish success or direct-main permission from missing evidence. |
| `robustness` | required | Audit capture must handle partial releases without claiming completion. |

Not-applicable dimensions: concurrency correctness, resiliency-specific retry
workflows, and runtime retry/idempotency machinery. The feature contains a
manual beta retry loop, but not a concurrent service or automatic retry system.

Required gates:

- `dead-field`, `anti-pattern`, and `test-integrity` mechanical checks.
- Repo-standard PowerShell syntax/test validation.
- Manual evidence in iteration `quality/quality-evidence.md`.
- Pre-implementation hardening-gate rationale for release credentials,
  direct-main behavior, and PASS-gated stable publication.

---

## 8. Risks & Mitigations

- **Ownership regression**: The template could again imply human execution.
  Mitigation: tests assert both ownership rows and action verbs.
- **Ceremonial audit records**: A record could exist without proving release
  safety. Mitigation: required fields and validation reject incomplete status.
- **Protected-main bypass**: Direct-main capture could become default.
  Mitigation: default false/missing config selects trailing one-file PR.
- **Credential leakage**: Publish/API evidence could include secrets.
  Mitigation: audit fields record commands/outcomes, never secret values.
- **Mirror drift**: Template changes can diverge between source and deployed
  extension trees. Mitigation: mirror parity verification at review.
- **Scope creep into publish workflow rewrite**: Existing beta/stable workflow
  primitives are assumed present. Mitigation: only fix missing primitives if
  planning evidence shows a requirement cannot otherwise be met.
