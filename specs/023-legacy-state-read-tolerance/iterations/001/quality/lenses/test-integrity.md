# Test-Integrity Lens: Legacy-State Read-Tolerance (Feature 023, Iteration 1)

**Lens**: `test-integrity@v1.0.0`  
**Iteration**: 001  
**Status**: Planning-time targets defined; full execution deferred to implementation phase  

## Planning-Time Coverage Targets

This document records the planning-time test-integrity targets for Feature 023 Iteration 1. Full test execution evidence will be generated during implementation.

### Target Coverage Map

| Component | Target Coverage | Planned Evidence | Approval Gate |
| --- | --- | --- | --- |
| **Reader Functions** | 100% of migrated readers (T004-T008, T032, T034) | Legacy fixture corpus against versions 0.18.0-0.23.0 | T023 test execution + T020 human approval |
| **Parse Errors** | Missing files, malformed JSON, malformed YAML, unknown schema | Fixture suite with error scenarios | T023 test execution |
| **Schema Dispatch** | Both v0 and v1 paths, mismatches, future proofing | Fixtures include v0, v1, and edge cases | T023 test execution + T034 dispatch audit |
| **StrictMode** | All readers pass with `-Version Latest` | Unit tests run with strict mode enabled | T021-T023 test suite |
| **Cross-Platform** | Windows and Linux | Windows CI (existing) + Linux CI lane (T024) | T024 CI integration + PR gate |

### Test Integrity Expectations
- **No smoke testing**: Fixture tests must exercise error paths, not just happy-path success
- **Real legacy data**: Fixture corpus drawn from actual Specrew versions 0.18.0-0.23.0
- **Explicit assertions**: Tests verify correct fallback behavior, not just "no crash"
- **CI gates**: Feature cannot merge until all tests pass on both Windows and Linux
- **Regression coverage**: Each schema migration is tested against legacy fixtures

### Test Structure (Planned)

```powershell
# Pester test suite covering:
Describe "Legacy State Reader - Robustness" {
  Context "Happy path - current schema" { }
  Context "Legacy files - schema v0" { }
  Context "Missing files" { }
  Context "Malformed JSON" { }
  Context "Unknown schema versions" { }
  Context "StrictMode compliance" { }
  Context "Cross-platform line endings" { }
}
```

### Test Fixtures Required
- `legacy-versions/0.18.0/`: Real state files from 0.18.0
- `legacy-versions/0.19.0/`: Real state files from 0.19.0
- ... (through 0.23.0)
- Error scenarios: malformed JSON, missing files, etc.

### Approval Status
- **Planning**: ✅ Complete — hardening-gate.md Section 4 contains full test-integrity targets and approval gates
- **Test Execution**: ⏳ Deferred — T021-T023 will create and run Pester suite
- **Coverage Verification**: ⏳ Deferred — T020 human review of fixture corpus completeness
- **Full Lens Execution**: ⏳ Deferred — Full test evidence generated during T021-T024

## Placeholder for Implementation Evidence

When implementation phase begins, this section will be populated with:
- Pester test suite code and results
- Legacy fixture corpus with evidence of coverage
- Cross-platform CI execution logs (Windows + Linux)
- T020 human review of fixture completeness
- T024 Linux CI integration confirmation

---

**Status**: ✅ Planning-time targets recorded; ready for implementation phase
