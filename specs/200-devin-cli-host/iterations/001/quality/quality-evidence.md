# Quality Evidence: Iteration 001

**Profile Ref**: `quality-profile.custom-composition.v1`
**Preset Refs**: `powershell-psd1-yaml-json-github-actions`
**Findings Ref**: `specs/200-devin-cli-host/iterations/001/quality/mechanical-findings.json`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-06-24T08:12:13Z

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| `registry-input-validation` | FR-001, FR-004 | `Unknown/differently-cased host tests at all three production boundaries.` | `planned` | `—` |
| `host-filelist-generation` | FR-002 | `Generate/check parity, missing-file failure, deterministic Windows/Unix path tests.` | `planned` | `—` |
| `host-purity-firewall` | FR-003, FR-004 | `Clean-tree pass, planted host-specific literal failure, and committed allow-list count.` | `planned` | `—` |
| `test-integrity` | FR-001, FR-002, FR-003, FR-012 | `Negative tests exercise the same scanner/generator/validator paths used in production and verify the accessor remains untouched.` | `planned` | `—` |
| `prepublish-package` | FR-002, FR-019 | `FileList-faithful publish harness includes every generated host package file.` | `planned` | `—` |
