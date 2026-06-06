# Contract: Retire Top-Level Evaluation Surface — Public Surface

**Feature**: 170-retire-evaluation-surface
**Stability**: internal test support (pre-1.0; no public product contract)

## tests/support/process-quality-scorer.ps1

Pure parameterized PowerShell script computing lifecycle artifact and
phase-adherence scores for a Specrew project. **Not** a public evaluation
harness: its supported consumers are the two integration-test entry points
below; any other use is unsupported.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| (script invocation) | `-ProjectPath <string> [-IterationPath <string[]>] [-AsJson] [-PassThru] [-WriteReport] [-ReportPath <string>]` | Score a project's iterations; emit JSON (default) or object (`-PassThru`); optionally write a markdown report | `Set-StrictMode -Version Latest`; throws on unresolvable paths |
| `Resolve-ReportPath` (internal) | `(projectPath, requestedPath): string` | Default report target `<project>/test-results/process-quality-report.md`; rooted paths honored | never returns a tracked top-level path by default |

### Supported entry points (the actual contract surface)

| Entry point | Purpose |
| --- | --- |
| `tests/integration/process-quality-scorer.ps1` | Scoring semantics regression (PASS/FAIL, exit code) |
| `tests/integration/process-quality-report.ps1` | Report generation + placement regression |

### Invariants

- No tracked path in the repository begins with `evaluation/` (FR-001).
- The default generated report resolves outside every tracked top-level
  surface (FR-004).
- The scorer file parses on Linux with forward-slash path assertions intact
  (FR-005; asserted by `tests/integration/multi-host-lifecycle-smoke.tests.ps1`).
- Iteration statuses accepted by the scorer are exactly the canonical set:
  `planning, executing, reviewing, retro, complete, abandoned`.
- CI job names and test semantics are unchanged by the move (proposal
  out-of-scope guarantee).
