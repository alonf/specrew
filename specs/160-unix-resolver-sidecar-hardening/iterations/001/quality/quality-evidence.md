# Quality Evidence: Iteration 001

**Feature**: 160-unix-resolver-sidecar-hardening
**Iteration**: 001
**Recorded**: 2026-06-03

## Stack Tooling Evidence (`stack-tooling-evidence` gate)

| Tool | Target | Result |
| ---- | ------ | ------ |
| `pwsh` integration tests | `tests/integration/unix-resolver-path-semantics.tests.ps1` | exit 0 post-fix (exit 1 pre-fix — repro-first proof) |
| `pwsh` integration tests | `tests/integration/managed-runtime-sidecar.tests.ps1` | exit 0 post-fix (exit 1 pre-fix — repro-first proof) |
| `pwsh` regression batch | skill-templates, slash-command-legacy-migration, lifecycle-boundary-sync | all exit 0 (no regression) |
| markdownlint-cli | all Iteration 001 markdown artifacts + CHANGELOG | clean |
| PSScriptAnalyzer (Error+Warning) | `sync-boundary-state.ps1`, `deploy-squad-runtime.ps1` | 0 errors; all warnings pre-existing patterns (unapproved verbs, Write-Host, BOM, ShouldProcess, plural nouns) on lines NOT touched by the fixes — no new findings introduced |
| `validate-governance.ps1 -NoCacheRead` | project | 0 hard / 0 medium; soft warnings only (pre-existing trust-hardening handoff + F-048 dashboard) |
| mechanical checks (dead-field / anti-pattern / test-integrity) | iteration | `quality/mechanical-findings.json` — no findings |
| Live consumer proof | fixed boundary-sync wrapper, identical-boundary re-sync on Windows | success:true — resolution + dispatch + full sync end-to-end through the FIXED wrapper |

## Quality Lens Review (`quality-lens-review` gate)

| Lens | Verdict | Evidence |
| ---- | ------- | -------- |
| `security-baseline@v1.0.0` | pass | `lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | pass | `lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | pass | `lenses/test-integrity.md` |

## Retry / Idempotency Review (`retry-idempotency-review` gate)

- Both touched surfaces are read-only decision logic: the resolver resolves a path
  (no writes), and the classifier returns a managed/preserve decision (no writes).
  Repeating either yields the identical result for identical inputs.
- The marker-provenance fix uses a pure ordinal string comparison; re-running the
  legacy cleanup on the same tree reaches the same classification.
- The live identical-boundary re-sync (run twice through the fixed wrapper during
  this iteration: pre-lint-halt + post-fix success) demonstrated safe repeated
  boundary-sync invocation with no duplicated verdict entries (the inline verdict
  writer skips identical-boundary re-syncs by design).
