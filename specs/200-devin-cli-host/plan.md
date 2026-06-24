# Implementation Plan: Devin CLI Host — Clean-Extensibility Proof

**Feature**: 200-devin-cli-host
**Design-analysis verdict**: `approved for plan with Option B`
**Branch**: `200-devin-cli-host`
**Date**: 2026-06-24
**Spec**: file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/spec.md

## Summary

Implement Proposal 200 Slices A, C, and D by preserving the existing
host-package registry and adding focused generic adapters at its remaining
coupling seams. The delivered host is a package under `hosts/devin/`; shared
production edits contain no hand-authored Devin/Windsurf routing literal and
remove all five in-scope firewall exceptions.

The real-host spike selected full handover outcome 2. Devin `2026.7.23
(3bd47f77)` exports ATIF before Stop; a package-private Devin adapter will
normalize it to the existing Claude-like JSONL shape and pass that path to the
unchanged handover pipeline. The edit in commit
`bbd218ea49cd183d41e463be62edf8221e2b32b7` narrows FR-011 to this proven
mechanism; it does not weaken the handover requirement.

The implementation follows Option B from
file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/iterations/001/design-analysis.md.
It adds no second host catalog, no sixth registry handler, no transcript parser
shape, and no new runtime dependency.

## Estimate Reconciliation

The approved plan is 45 story points across three iterations, compared with the
proposal's preliminary 18–26 SP estimate for Slices A/C/D. The increase is
evidence-driven, not scope growth:

- the production-ready host package includes launch, permissions, runtime
  detection, Crew deployment, hooks, instructions, skills, metadata, and tests;
- the Stop spike proved an ATIF normalizer and event-path adapter are required;
- registry validation and generated package membership need reusable helpers,
  parity enforcement, negative tests, and CI/prepublish integration;
- coordinator eligibility requires a one-run, ownership-safe managed YAML
  migration rather than a new-host append;
- promotion requires cross-platform deterministic checks plus a complete
  pinned-build real-host run;
- documentation and Proposal 194 must describe the actual fragile surfaces and
  registry-derived monitoring model.

The full five-entry allow-list shrink, including both coordinator files, remains
Feature 200 proof scope.

## Technical Context

- **Language/runtime**: PowerShell 7+, PSD1 manifests, YAML/JSON configuration,
  Markdown governance artifacts, GitHub Actions.
- **Primary dependencies**: existing Specrew module/runtime and PowerShell
  standard library only.
- **Storage**: host manifests; generated `Specrew.psd1` FileList projection;
  managed `.specrew/iteration-config.yml` block; local bounded ATIF/JSONL runtime
  files; bounded compatibility evidence.
- **Testing**: repository PowerShell unit/integration/bootstrap scripts,
  FileList-faithful publish harness, Windows and Unix GitHub runners, manual
  pinned-build Devin canary.
- **Target platforms**: Windows plus at least one Unix platform for generic
  path/argument behavior. Devin remains experimental where real-host evidence
  has not passed.
- **Constraints**:
  - do not modify
    `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`;
  - do not implement deferred Slice B;
  - do not run `specrew update` or `specrew init` in this worktree;
  - no hand-authored Devin/Windsurf production literal outside `hosts/devin/`;
  - no automatic host CLI upgrades or scheduled compatibility monitor;
  - every iteration is capped at 20 SP.

## Architecture

Option B keeps the current modular monolith and one registry. New behavior is
introduced only at existing ownership seams.

| Component | Responsibility | Planned location |
| --- | --- | --- |
| Host registry validation | Discover canonical host kinds and provide reusable actionable validation. | `hosts/_registry.ps1` |
| Host package projection | Derive deterministic FileList host entries and rewrite the generated segment. | `scripts/internal/` plus `Specrew.psd1` |
| Host purity firewall | Reject host-specific shared routing, prove the failure path, and prevent allow-list growth. | `tests/integration/host-coupling-firewall.tests.ps1` |
| Devin package | Own manifest, five handlers, coordinator rules, hook adapter, and ATIF normalizer. | `hosts/devin/` |
| Generic hook adapter seam | Let a manifest name a package-local event adapter before the shared dispatcher. | host contract and hook launcher/deployer |
| Coordinator catalog | Return manifest-declared coordinator-capable host descriptors. | `hosts/_registry.ps1` |
| Managed-agent projection | Merge registry-derived coordinator entries into the Specrew-owned YAML block only. | existing init/update owners plus focused helper |
| Compatibility evidence | Record tested build, OS, event, mechanism, result, and bounded reason code. | feature evidence artifacts and manifest metadata |

### Manifest additions

The host manifest schema receives additive, safe-default fields; no chained
project upgrade or breaking manifest-version transition is required:

- `CanCoordinate` defaults to `$false`;
- `CoordinatorDefaults` is required when `CanCoordinate=$true` and supplies
  `Enabled`, `AccessPath`, and `StrengthRank`;
- `SupportedVersions.TestedBuilds` records exact tested-build identifiers;
- `CompatibilityMonitoring.FragileSurfaces` records launch, hook, payload, and
  transcript/export dependencies;
- `TranscriptExport` describes the package-owned export format, runtime paths,
  normalizer, and existing normalized shape;
- `RefocusHookBindings.EventPayloadAdapter` optionally names a module-relative
  package adapter that receives the raw event before the shared dispatcher.

Missing coordinator fields mean “not coordinator-capable”; missing event
adapter means the current direct-dispatch behavior. Existing packages therefore
remain loadable while their manifests are migrated explicitly.

### Devin handover flow

1. `New-DevinLaunchInvocation` launches interactive `devin` with the bootstrap
   prompt as positional input and a controlled `--export` path under
   `.specrew/runtime/`.
2. Devin writes ATIF before Stop, as proven by the spike.
3. The Devin package hook adapter reads the Stop payload, normalizes ATIF
   `steps[]` to the existing Claude-like JSONL turn shape, and enriches the
   event with `transcript_path`.
4. The adapter invokes the existing shared dispatcher and preserves its stdout,
   stderr, and exit semantics.
5. The unchanged handover provider and parser capture the conversation and
   boundary packet.
6. Runtime files stay local, use fixed bounded paths rather than accumulating
   session archives, and are excluded from logs, CI artifacts, and commits.

### Windows hook-runner attempt

Iteration 002 includes an empirical host-neutral attempt to render a direct
`pwsh` executable/argument hook entry so Windows does not require Git Bash.
The attempt may add a generic handler/command shape only if the Devin
Claude-compatible hook schema accepts it. If the pinned CLI still routes all
commands through `sh.exe`, the implementation records that result, keeps the
Git Bash prerequisite visible, and leaves Devin experimental. It must not add a
Devin-specific shared-core branch or claim parity that was not observed.

## Project Data Migration

`specrew update` performs one registry-derived migration of only the marked
managed `agents:` block:

- absent block: create all coordinator-capable entries;
- legacy three-host block: preserve mutable values by host key and add new
  eligible entries;
- partial block: preserve known entries, fill missing eligible entries, and
  remove only managed entries no longer eligible;
- current block: remain byte-idempotent after canonical regeneration.

Unrelated YAML, comments outside the managed block, and user-owned values remain
untouched. One current `specrew update` run is sufficient for these Feature 200
shapes; arbitrary historical-version convergence is a separate proposal/PR and
is recorded at closeout, not implemented here.

## Iteration and Capacity Plan

Capacity is 20 story points per iteration. No iteration may exceed the cap
without a new human split/defer decision.

| Iteration | Scope | Effort |
| --- | --- | ---: |
| 001 | Proven handover spike plus Slice A registry validation, generated host FileList, purity firewall, and focused CI | 14 |
| 002 | Devin package, launch/runtime/Crew, direct event-map hooks, ATIF handover adapter, and Windows direct-pwsh attempt | 15 |
| 003 | Coordinator eligibility and one-run migration, full compatibility/CI/prepublish evidence, docs, Proposal 194, and real-host promotion gate | 16 |
| **Total** |  | **45** |

### Iteration 001 — 14 SP

| Work item | Requirement refs | SP |
| --- | --- | ---: |
| Empirical Stop/export/normalization spike and evidence | FR-011, FR-012, SC-008 | 3 |
| Registry-driven validation at the three callsites | FR-001, SC-002 | 2 |
| Deterministic host-package FileList generator and parity | FR-002, SC-004 | 3 |
| Purity assertion, planted-literal test, and three-entry allow-list shrink | FR-003, FR-004, SC-002, SC-003 | 3 |
| Slice A CI/prepublish wiring | FR-019, SC-010 | 2 |
| Review/rework reserve | SC-012 | 1 |

### Iteration 002 — 15 SP

| Work item | Requirement refs | SP |
| --- | --- | ---: |
| Manifest, five handlers, coordinator rules, and package validation | FR-005, FR-006, FR-010 | 3 |
| Interactive launch, permission flags, runtime signals, instructions, skills, and Crew deployment | FR-007, FR-008 | 4 |
| Generic direct event-map/event-adapter seam and safe merge/remove/status behavior | FR-009, FR-016, SC-009 | 3 |
| Devin ATIF normalizer and unchanged-parser handover integration | FR-011, FR-012, FR-017, SC-007, SC-008 | 3 |
| Direct-pwsh Windows attempt, deterministic tests, and review reserve | FR-009, FR-018 | 2 |

### Iteration 003 — 16 SP

| Work item | Requirement refs | SP |
| --- | --- | ---: |
| Manifest coordinator eligibility/catalog and final two-entry allow-list shrink | FR-013, FR-004, SC-002 | 3 |
| Four-shape managed-agent migration, update/init/start-heal integration, and idempotency | FR-014–FR-016, SC-006 | 4 |
| Existing-host compatibility, generated package, prepublish, and cross-platform CI | FR-018, FR-019, SC-005, SC-010 | 3 |
| README/host/add-host/test/release docs and Proposal 194 amendment | FR-020, FR-022, SC-011 | 2 |
| Full pinned-build real-host prerelease evidence and promotion decision | FR-021, SC-001, SC-007 | 3 |
| Final diff classification, follow-up record, and review reserve | SC-012 | 1 |

## Requirements-to-Evidence Map

| Requirement group | Planned evidence |
| --- | --- |
| FR-001–FR-004 | Registry validator tests, FileList generate/check tests, firewall positive/negative tests, committed allow-list count. |
| FR-005–FR-010 | Devin manifest/handler contract tests, launch argv matrix, Crew fixture, hook merge/remove/status tests, Spec Kit metadata assertion. |
| FR-011–FR-012 | Spike report, normalizer fixtures, byte-validated unchanged-parser canary, forbidden accessor diff check. |
| FR-013–FR-016 | Coordinator descriptor tests and absent/legacy/partial/current YAML migration fixtures with second-run no-diff. |
| FR-017–FR-019 | Redaction checks, existing-host suites, FileList-faithful publish harness, Windows/Unix CI jobs. |
| FR-020–FR-022 | Documentation consistency review, Proposal 194 registry-driven inventory amendment, closeout follow-up record. |
| SC-001, SC-007 | Actual pinned-build interactive prerelease session evidence. |
| SC-002–SC-006, SC-008–SC-010 | Deterministic automated gates and fixtures. |
| SC-011–SC-012 | Documentation review and final production-diff classification. |

## Phase 1 Quality Planning

**Quality profile**: bounded custom composition
`powershell-psd1-yaml-json-github-actions`.

The repository-level package signal is not the implementation stack for this
feature. Required dimensions are separation of concerns, security, robustness,
test integrity, compatibility, deterministic generation/migration, and
real-host evidence.

| Gate | Category | Evidence |
| --- | --- | --- |
| Registry/manifest contract | mechanical | all manifests load; safe defaults and conditional fields validate |
| FileList generation/parity | mechanical | generate-then-check and FileList-faithful package validation |
| Purity firewall | mechanical | clean tree pass plus planted-literal failure |
| User-file preservation | security | malformed/unreadable hook file refusal and user-entry preservation |
| Transcript privacy | security | synthetic fixtures only; no prompt/transcript/credential content in logs or CI artifacts |
| Managed YAML ownership | robustness | four migration shapes, unrelated-content preservation, second-run no diff |
| Existing-host compatibility | regression | registry, launch, hooks, instructions, Crew, coordinator, package, transcript goldens |
| Real Devin behavior | runtime evidence | pinned-build launch/events/Stop/handover/permissions/hook merge evidence |

Retry is limited to one explicitly recorded transient real-host canary retry.
Deterministic generation, migration, and merge operations do not retry; they
fail safely and preserve source/user files.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: Iteration 001 registry validation, generated package
membership, purity enforcement, and CI/prepublish wiring; later iteration
controls remain explicit but do not authorize their implementation.

**Hardening Gate Artifact**:
`specs/200-devin-cli-host/iterations/001/quality/hardening-gate.md`

**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`

**Trap Reapplication Artifact**:
`specs/200-devin-cli-host/iterations/001/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters | Planned Evidence | Status |
| --- | --- | --- | --- |
| Security surface analysis | Registry inputs, manifests, generated paths, hook configuration, and transcript files cross trust/ownership boundaries. | Hardening gate plus focused malformed-input and path-containment tests. | required |
| Error handling and failure semantics | Unknown hosts, invalid packages, unreadable user files, failed normalization, and unavailable hook runners must fail safely and visibly. | Hardening gate plus negative-path tests and bounded reason codes. | required |
| Retry and idempotency | Generation/migration/merge must be deterministic; real-host canaries permit only one recorded transient retry. | Generate-check parity, second-run no-diff, hook redeploy tests, evidence record. | required |
| Test integrity | The folder-only claim needs planted violations, no-adapter regression proof, FileList-faithful packaging, and real-host evidence. | Firewall negative tests, compatibility suite, prepublish harness, prerelease evidence. | required |

### Lens Activation Plan

| Lens | Activation | Rationale | Planned Evidence |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | required | User files, executable hooks, and transcript data require explicit ownership and redaction controls. | `iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | Registry, generation, adapters, migration, and degraded host behavior require fail-safe semantics. | `iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | Architectural proof depends on tests that exercise failure paths rather than inspect file presence only. | `iterations/001/quality/lenses/test-integrity.md` |

### Routing Policy

Required hardening lenses request the strongest available review class. Any
downgrade requires explicit human approval and a recorded rationale. Effective
execution class is recorded when review runs.

### Explicit Later Deferrals

- Runtime proof remains pending until the owning implementation/review
  iteration; planning-time controls do not claim execution.
- Known-traps corpus additions require separate review and are not created
  automatically.
- Quality-drift and reference-implementation comparison are out of scope.
- The hook-adapter seam cannot implement until its Iteration 002 hardening gate
  repeats the host-neutrality, planted-literal, and no-adapter compatibility
  conditions defined in the task backlog.

## Constitution Check

- **Spec authority**: PASS. Scope maps to approved FR-001–FR-022 and
  SC-001–SC-012.
- **Layering**: PASS. Host behavior is package-owned; shared edits are generic
  registry, projection, migration, hook-adapter, or test infrastructure.
- **Traceability**: PASS. Every planned work item names requirement/evidence
  references; task-level traceability is completed before implementation.
- **Ownership**: PASS. Spec Steward owns scope/drift, Implementer owns code and
  fixtures, Reviewer owns firewall/compatibility/security evidence, and the
  human owns promotion verdicts.
- **Capacity**: PASS. 14/20, 15/20, and 16/20; 45 SP total.
- **Drift/reconciliation**: PASS. Drift signals are recorded in the iteration
  drift log and block review when they cross the explicit guards below.
- **Verification**: PASS. Deterministic tests are paired with a real-host
  prerelease gate.

## Project Structure

```text
hosts/
├── _contract.md
├── _registry.ps1
└── devin/
    ├── host.psd1
    ├── handlers.ps1
    ├── coordinator-rules.psd1
    └── hook-adapter.ps1

scripts/
├── specrew-start.ps1
├── specrew-init.ps1
├── init/agent-detection.ps1
└── internal/
    ├── coordinator-prompt-surgery.ps1
    ├── deploy-refocus-hooks.ps1
    ├── host-flag-translation.ps1
    └── [focused generic FileList/coordinator projection helpers]

tests/
├── bootstrap/
├── integration/
├── unit/
└── manual/

specs/200-devin-cli-host/
├── plan.md
├── data-model.md
├── quickstart.md
├── review-diagrams.md
├── contracts/devin-cli-host.md
└── iterations/
```

## Scope and Drift Guards

The following conditions stop implementation/review and require reconciliation:

- any diff to
  `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`;
- any hand-authored Devin/Windsurf production literal outside `hosts/devin/`;
- any new firewall exception or failure to remove all five in-scope entries;
- a second runtime host catalog or a sixth transcript-shape handler;
- hand-authored per-host FileList membership as source of truth;
- whole-file overwrite of user hook/instruction/config content;
- a claim that arbitrary historical update chains are supported;
- a scheduled live compatibility monitor or automatic CLI upgrade;
- a supported-status promotion without complete pinned-build evidence;
- any iteration above 20 SP without a new human decision.

## Plan Outputs

- Data model:
  file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/data-model.md
- Quickstart:
  file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/quickstart.md
- Public contract:
  file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/contracts/devin-cli-host.md
- Review diagrams:
  file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/review-diagrams.md
- Spike evidence:
  file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/iterations/001/research/devin-stop-payload-spike.md
