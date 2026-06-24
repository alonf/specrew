# Quality Evidence: Iteration 001

**Profile Ref**: `quality-profile.pending`
**Preset Refs**: (pending preset selection)
**Findings Ref**: `specs/200-devin-cli-host/iterations/001/quality/mechanical-findings.json`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-24T10:33:27Z

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| `registry-input-validation` | FR-001, FR-004 | `host-registry.tests.ps1` exercised registered, differently-cased, and unknown input at all three production boundaries.` | `pass` | `—` |
| `host-filelist-generation` | FR-002 | `The production generator passed generate/check, stale, duplicate, escaping-link, missing-file, folder/Kind, folder-only fixture, LF, and CRLF cases on Windows and Linux.` | `pass` | `—` |
| `host-purity-firewall` | FR-003, FR-004 | `The production scanner passed the real tree, detected both runtime-planted reserved tokens, passed registry-driven content, and reported an allow-list reduction from 11 to 8.` | `pass` | `—` |
| `test-integrity` | FR-001, FR-002, FR-003, FR-012 | `specs/200-devin-cli-host/iterations/001/quality/quality-evidence.md` | `passed` | `—` |
| `prepublish-package` | FR-002, FR-019 | `specs/200-devin-cli-host/iterations/001/coverage-evidence.md` | `passed` | `—` |
