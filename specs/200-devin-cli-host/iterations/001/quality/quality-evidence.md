# Quality Evidence: Iteration 001

**Profile Ref**: `quality-profile.custom-composition.v1`
**Preset Refs**: `powershell-psd1-yaml-json-github-actions`
**Findings Ref**: `specs/200-devin-cli-host/iterations/001/quality/mechanical-findings.json`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-24T09:31:18Z

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| `registry-input-validation` | FR-001, FR-004 | `host-registry.tests.ps1` exercised registered, differently-cased, and unknown input at all three production boundaries. | `pass` | `—` |
| `host-filelist-generation` | FR-002 | The production generator passed generate/check, stale, duplicate, escaping-link, missing-file, folder/Kind, folder-only fixture, LF, and CRLF cases on Windows and Linux. | `pass` | `—` |
| `host-purity-firewall` | FR-003, FR-004 | The production scanner passed the real tree, detected both runtime-planted reserved tokens, passed registry-driven content, and reported an allow-list reduction from 11 to 8. | `pass` | `—` |
| `test-integrity` | FR-001, FR-002, FR-003, FR-012 | Tests invoked the production validator, generator, purity scanner, publish harness, and unchanged conversation capture path. | `pass` | `—` |
| `prepublish-package` | FR-002, FR-019 | The production publish harness package-only path validated 314 FileList entries, 15 generated host files, five manifests, and version parity. | `pass` | `—` |

## Runtime Evidence

- `tests/integration/host-registry.tests.ps1`: all assertions passed.
- `tests/integration/host-package-filelist.tests.ps1`: eight package-generation
  assertions passed on Windows and Linux.
- `tests/integration/host-coupling-firewall.tests.ps1`: all assertions passed;
  the committed enum allow-list is 8, below the pre-feature baseline of 11.
- `tests/integration/filelist-completeness.tests.ps1`: 314 manifest entries are
  complete across deployable roots.
- `tests/integration/multi-host-launch-path.tests.ps1`: all assertions passed on
  Windows and Linux.
- `tests/integration/publish-module-harness.tests.ps1`: the production
  package-only harness path and all workflow-wiring assertions passed.
- `tests/bootstrap/ConversationCapture.Tests.ps1`: all existing host shapes,
  Tier-3 fallback, degradation, and budget assertions passed with the accessor
  unchanged.

## Windows and Unix Proof

- Windows: the focused lane passed directly in this worktree.
- Linux: the same generator, package, registry, launch, and firewall lane passed
  in `mcr.microsoft.com/powershell:lts-ubuntu-22.04` on a copied Linux
  filesystem.
- The first Linux run exposed CRLF-to-LF check drift. The generator now
  preserves the existing manifest line ending, with an explicit LF fixture.
- The next Linux run exposed a Windows-only fake path in the launch test. The
  fixture now uses the platform temporary root and separator-normalized
  assertions. The final Linux lane passed completely.

## Full-Repository Validator Carry

The user-mandated uncached validator was run with:

`validate-governance.ps1 -ProjectPath . -NoParallel -NoCacheRead`

1. The first run completed in 25.86 seconds and failed on missing canonical
   `Current Phase` and `Iteration Status` metadata in this iteration's
   `state.md`.
2. The second run completed in 11.65 seconds and rejected `implement` because
   persisted boundary metadata uses the canonical `before-implement` value
   until review-signoff.
3. After both real failures were corrected, the full run completed in 26.29
   seconds with exit code 0. Remaining dashboard and historical handoff
   findings were warnings, not hidden failures or timeouts.
4. The final artifact tree was rerun uncached and passed in 26.99 seconds.

## Traceability and Drift

- Iteration scope contains 13 authoritative FR/SC references.
- T001-T006 cover all 13; no task is orphaned and no scoped requirement is
  uncovered.
- Drift verdict: `PASS`. The review-time newline and fixture-path repairs remain
  within FR-002 and FR-019; no unauthorized capability or later-iteration task
  entered the diff.

## Diff Classification

- Registry validation, FileList generation, purity enforcement, delegated-agent
  discovery, publish validation, and CI changes are generic shared cleanup.
- No host package was added; T007 and later tasks remain untouched.
- No new firewall exception was added, and all three Slice A exceptions are
  absent.
- `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` has no diff.
- Generated `Specrew.psd1` output is reproducible and contains only the generic
  generator helper addition outside existing host-package rows.

## Non-Gating Observation

An exploratory run of the broad `start-command.ps1` suite exceeded 186 seconds
inside a nested no-launch start operation and was terminated. It produced no
failure result and is not used as evidence. The required full-repository
validator did not time out, and the focused start/launch production paths
passed on both operating systems.
