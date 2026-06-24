# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-24
**Overall Verdict**: accepted

## Summary

Iteration 001 delivers Proposal 200 **Slice A** — the clean-extensibility
plumbing that lets a host be added by a package folder rather than by editing
shared-core host literals. All six tasks are implemented, the five Slice A
deterministic suites pass (76 assertions, 0 failures), zero specification drift
was detected, and the mechanical lenses report zero findings. Verified against
the live working tree at HEAD `6b2d89b4`.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-011, FR-012, SC-008 | pass | Empirical Stop/export spike recorded under `research/`; proved outcome-2 byte-for-byte through the unchanged `ConversationCaptureAccessor.ps1` (FR-012 preserved) and selected the handover mechanism (FR-011). Pinned-build `sh.exe` prerequisite captured as a constraint, not speculatively fixed. |
| T002 | FR-001, SC-002 | pass | All three production `[ValidateSet(...)]` host callsites (`specrew-start.ps1`, `host-flag-translation.ps1`, `coordinator-prompt-surgery.ps1`) replaced with `[ValidateScript({ Test-SpecrewRegisteredHostKind -Kind $_ })]`, backed by the live package registry. `host-registry.tests.ps1` green (24 assertions), including unknown-host and case-variant rejection. |
| T003 | FR-002, SC-004 | pass | `update-host-package-filelist.ps1` generates deterministic host-package FileList membership; `Specrew.psd1` projection updated; parity gate added. `host-package-filelist.tests.ps1` green (8 assertions) covering generate/check parity, missing-file failure, and Windows/Unix path determinism. |
| T004 | FR-003, FR-004, SC-002, SC-003 | pass | Permanent host-addition purity assertion present; planted-literal negative test exercises the **production** scanner path (both planted tokens must fail; clean tree must pass). Allow-list shrunk from pre-feature baseline 11 to a Slice A ceiling of 8 with no Devin exception added. `host-coupling-firewall.tests.ps1` green (8 assertions). |
| T005 | FR-019, SC-010 | pass | Slice A registry, firewall, generation, and FileList-faithful prepublish checks wired into `specrew-ci.yml`, `cross-platform-validation.yml`, and `publish-module.yml`. `publish-module-harness.tests.ps1` green (11 assertions); `test-publish-harness.ps1` now includes every generated host-package file. |
| T006 | SC-012 | pass | Iteration review + traceability complete; drift-log T006 checkpoint compared T001-T006 against FR-001-004/011-012/019 and SC-002-004/008/010/012 with no omission, no unauthorized capability, and no contradicted deferral. T007+ correctly absent from the diff. |

## Requirement Coverage

- **FR-001 / SC-002** — registry-driven validation at three callsites: covered (T002, T004).
- **FR-002 / SC-004** — generated host-package FileList + parity: covered (T003).
- **FR-003 / SC-003** — permanent purity assertion + negative proof: covered (T004).
- **FR-004** — firewall allow-list shrink, no Devin exception: covered (T004).
- **FR-011 / FR-012 / SC-008** — handover mechanism selected; accessor untouched: covered (T001).
- **FR-019 / SC-010** — Slice A checks wired into CI/prepublish: covered (T005).
- **SC-012** — traceability/review closure: covered (T006).

## Evidence

- Deterministic suites (run at review time, exit 0):
  `host-registry` 24, `host-package-filelist` 8, `host-coupling-firewall` 8,
  `multi-host-launch-path` 25, `publish-module-harness` 11 — total 76 PASS, 0 FAIL.
- Mechanical lenses: `quality/mechanical-findings.json` — 0 findings.
- Drift: `drift-log.md` — 0 events.
- Diff scope: 17 production files, +763/-27, confined to the Slice A owner globs;
  `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` untouched (FR-012).

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now.

## Notes

- Slices C (Devin package) and D (coordinator eligibility + config migration)
  remain out of scope for this iteration per the approved Option B split; their
  absence from the diff is expected, not a gap.
- Slice B (transcript-turn-shape contract) stays deferred until Feature 197
  merges; recorded as a constraint, no accessor edits attempted.
- The 6-SP capacity reserve was not consumed and is not implicit permission to
  pull iteration 002/003 work forward.
- Per-task drift checks ran during execution (T006 checkpoint); no batch
  drift-check rerun required.
