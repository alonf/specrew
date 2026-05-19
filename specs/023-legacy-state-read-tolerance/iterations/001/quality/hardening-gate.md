# Hardening Gate: Legacy-State Read-Tolerance (Feature 023, Iteration 1)

**Feature**: 023 - Legacy-State Read-Tolerance + Schema Migration Discipline  
**Iteration**: 001 (Schema Markers + Reader Migrations + Fixture Corpus)  
**Phase Scope**: Phase 2 Hardening Gate Planning (US-2)  
**Date**: 2026-05-19  
**Spec Reference**: file:///C:/Dev/Specrew-023/specs/023-legacy-state-read-tolerance/spec.md

---

## Pre-Implementation Hardening Review Summary

This hardening gate records **planning-time analysis, expected controls, rationale, and explicit non-applicable reasoning** for Feature 023 Iteration 1 before implementation begins. Runtime-only final proof remains deferred until later closure.

---

## 1. Security Surface Analysis

**Why It Matters**: The hardening gate must capture planning-time security analysis, expected controls, and any explicit non-applicable reasoning before coding begins. Local state file handling, no network boundaries or credential management in scope.

### Threat Model
- **State File Access**: Reader functions parse local JSON/YAML state files (`.specrew/`, `.specify/`, `.squad/`, `tasks-progress.yml`)
- **No Network Boundaries**: All state is local filesystem; no remote fetch, cache invalidation, or distributed consensus concerns
- **No Credentials in Scope**: Feature does not add credential management, encryption, or key storage
- **Existing File Permissions**: Rely on OS filesystem ACLs; no new permission model introduced

### Expected Controls (Planning-Time)
1. **Hashtable-based parsing prevents field injection**: Use `ConvertFrom-Json -AsHashtable` and manual YAML parsing; never use `PSCustomObject` from untrusted JSON
2. **Schema version dispatch is explicit**: All `v0` vs `v1` branching includes inline comments explaining behavior difference
3. **Missing fields are tolerated by default**: Hashtables silently omit missing fields; no `$null` reference errors thrown
4. **File existence checks precede reads**: All reader functions test `-Path` before attempting read

### Explicit Non-Applicable Reasoning
- **Encryption/Key Rotation**: Not in scope; feature assumes state files are protected by OS file permissions
- **Audit Logging**: Not in scope; feature does not add state-change hooks or compliance logging
- **Access Control Beyond OS ACLs**: Not in scope; feature assumes deployer controls filesystem permissions

### Approval Sign-Off (Deferred)
- **Planning-Time Analysis**: ✅ Complete — controls and non-applicable rationale recorded above
- **Implementation Approval**: ⏳ Deferred — Human Steward will approve dispatch logic after T032 (schema-version comments in place)
- **Runtime Evidence**: ⏳ Deferred — Reader tests against legacy fixtures will provide security-in-practice proof during Iteration 1 testing

---

## 2. Error Handling and Failure Semantics

**Why It Matters**: Silent failure paths, expected controls, and fallback expectations must be made explicit in the hardening gate so implementation does not invent them later or bypass runtime follow-through. Parse errors, missing files, unsupported schema versions covered explicitly in spec edge cases.

### Error Classes (Planned Behavior)

| Error Class | Trigger | Expected Behavior | Rationale | Implementation Task |
| --- | --- | --- | --- | --- |
| **Missing State File** | Reader invoked but state file does not exist on disk | Return empty/default state (e.g., empty hashtable, falsy value) | State files are optional (e.g., first run, `.specify/extensions/` may not exist yet); readers must not crash | T002, T004-T008 |
| **Parse Error (JSON)** | `ConvertFrom-Json -AsHashtable` fails due to malformed JSON | Log warning; return fallback (empty hashtable or null); continue execution | Malformed files should not block CLI operation; human can fix file manually and retry | T004-T008 (use `-ErrorAction Continue` with fallback) |
| **Parse Error (YAML)** | Manual YAML parsing (regex/split) fails | Log warning; return fallback state; continue execution | Manual parsing is more forgiving than strict parsers; invalid YAML is unlikely given manual format | T004-T008 (test harness covers edge cases) |
| **Unknown Schema Version** | Reader encounters `schema: v2` or higher (future proofing) | Log warning; treat as `v0` (backward-compatible default) or skip field entirely | Unknown versions should not crash; feature adds version tolerance as defensive measure | T006, T032 (inline schema dispatch logic) |
| **StrictMode Violation** | Missing property/variable in strict mode (e.g., `$hashtable.undefined_key`) | Fail explicitly with clear error message | StrictMode is a feature of PowerShell 7.0+; readers must be compatible; test errors are better than silent nulls | T004-T008 (validate StrictMode compatibility) |

### Fallback Expectations (Implementation Contracts)
1. **Readers never throw unhandled exceptions**: All parse/file errors caught and logged; caller receives fallback/empty state
2. **Silent failures are acceptable only for missing files**: Other errors (parse, StrictMode) should log warnings before falling back
3. **Version dispatch is explicit**: All `schema` field checks documented inline; future versions can extend behavior without code archaeology
4. **Hashtable `ContainsKey()` used for optional fields**: Never access missing keys directly; use `.Contains()` check first

### Approval Sign-Off (Deferred)
- **Planning-Time Analysis**: ✅ Complete — error classes, expected behavior, and rationale recorded above
- **Implementation Approval**: ⏳ Deferred — Human Steward will audit error handling code during reader migration (T004-T008 review)
- **Runtime Evidence**: ⏳ Deferred — Legacy fixture test suite (T023) will exercise parse errors, missing files, and schema version handling

---

## 3. Retry and Idempotency Expectations

**Why It Matters**: The hardening gate still records why retry and idempotency do not materially apply in this slice so omissions stay reviewable before implementation begins.

### Explicit Non-Applicable Reasoning

**Retry**: ❌ Not Required
- State file reads are synchronous local I/O; no network latency, timeout, or transient failure patterns
- Readers are pure functions; no side effects that need reversal
- If a read fails, the error is permanent (malformed file, permissions, missing field) and not recoverable via retry

**Idempotency**: ✅ Already Guaranteed
- State file reads are idempotent by nature: calling `Read-TaskProgress` 100 times returns the same result
- Readers do not modify state files; read-only operations are inherently idempotent
- Schema dispatch (v0 vs v1) is deterministic; same version always takes same code path

### Approval Sign-Off
- **Planning-Time Analysis**: ✅ Complete — retry and idempotency analysis recorded above
- **Implementation/Runtime Evidence**: Not required (non-applicable dimensions)

---

## 4. Test-Integrity Targets

**Why It Matters**: The hardening gate must name the planned validation evidence and expected controls for this slice so implementation readiness does not rely on smoke-only success while runtime/test proof remains visibly pending until later closure.

### Planned Validation Evidence

| Test Category | Target Coverage | Planned Evidence | Approval Gate |
| --- | --- | --- | --- |
| **Legacy Fixture Regression** | 100% of readers (T004-T008, T032, T034) against legacy versions 0.18.0-0.23.0 | Fixture corpus at `tests/fixtures/legacy-versions/` + Pester suite (T023) | T020 human review of fixture completeness; T023 CI execution |
| **Error Handling** | Parse errors, missing files, schema version mismatches | Fixture suite includes malformed JSON, missing-file scenarios, v1 with extra fields | T023 test execution; covered by fixture corpus |
| **Cross-Platform** | Windows + Linux (StrictMode compatibility) | Windows CI (existing), Linux CI lane (T024) | T024 CI integration + PR gate |
| **StrictMode Compliance** | All readers pass with `-Version Latest` mode | Unit tests run with `Set-StrictMode -Version Latest` | T021-T023 test execution |
| **Schema Dispatch Correctness** | Readers correctly branch on `schema: v0` vs `v1` | Fixture corpus includes both schema versions; inline dispatch comments audited by T034 | T034 human review of dispatch logic |

### Control Expectations (Pre-Implementation)
1. **Test suite covers both happy-path and edge cases**: Passing fixture tests prove defensive parsing works
2. **Legacy corpus represents real versions**: Fixtures drawn from actual Specrew versions 0.18.0-0.23.0 (not mock data)
3. **CI gates are binary**: Feature cannot merge until all tests pass on both Windows + Linux
4. **Human approval gates are human-readable**: Comments in code and fixture documentation make intent clear

### Approval Sign-Off (Deferred Until Test Execution)
- **Planning-Time Targets**: ✅ Complete — test coverage, evidence sources, and approval gates recorded above
- **Test Execution & Evidence**: ⏳ Deferred — T021-T023 will generate Pester test results; T024 will activate Linux CI
- **Final Sign-Off**: ⏳ Deferred — Human Steward approves fixture corpus (T020) and Linux CI activation (T024) before Iteration 1 closure

---

## 5. Quality Lenses (Pre-Activation Status)

| Lens | Activation Class | Pre-Implementation Status | Planned Artifact | Notes |
| --- | --- | --- | --- | --- |
| `security-baseline@v1.0.0` | `required` | Planning-time analysis complete (Section 1 above) | `specs/023-legacy-state-read-tolerance/iterations/001/quality/lenses/security-baseline.md` | TBD: Defer full line-by-line evidence until execution; planning analysis covers threat model, controls, non-applicable reasoning |
| `robustness-baseline@v1.0.0` | `required` | Planning-time analysis complete (Section 2 above) | `specs/023-legacy-state-read-tolerance/iterations/001/quality/lenses/robustness-baseline.md` | TBD: Defer full line-by-line evidence until execution; planning analysis covers error classes, fallbacks, dispatch logic |
| `test-integrity@v1.0.0` | `required` | Planning-time targets defined (Section 4 above) | `specs/023-legacy-state-read-tolerance/iterations/001/quality/lenses/test-integrity.md` | TBD: Defer execution evidence until Iteration 1 testing; planning phase names target coverage and evidence sources |
| `bug-hunter` (strongest-available) | `strongest-available` | Deferred to execution | Not applicable at planning | Will activate during implementation/review iteration (Phase 2+) |
| `quality-drift` | Not activated | Deferred to Phase 2+ | Not applicable | Deferred to dedicated quality-drift iteration (not in Phase 1 scope) |

---

## 6. Iteration 1 Implementation Readiness Checklist

- [ ] **Spec Authority**: Iteration 1 scope (FR-001 through FR-009, FR-014) maps to approved spec and plan ✅
- [ ] **Security Planning**: Threat model, controls, and non-applicable reasoning recorded (Section 1) ✅
- [ ] **Error Handling Planning**: Error classes, expected behavior, and fallbacks defined (Section 2) ✅
- [ ] **Test-Integrity Targets**: Coverage goals, evidence sources, and approval gates named (Section 4) ✅
- [ ] **Quality Lens Activation**: Pre-implementation lenses identified; full execution deferred to implementation phase ✅
- [ ] **Human Oversight Gates Ready**: T020 (fixture corpus), T028 (validator audit), T030 (docs), T034 (dispatch logic) defined in tasks.md ✅
- [ ] **Bootstrap Principle**: Iteration 1 implementation will serve as reference implementation of patterns ✅
- [ ] **Two-Iteration Split**: Iteration 1 (schema + readers + fixtures) and Iteration 2 (validator + docs) scoped correctly ✅
- [ ] **Linux Validation**: Linux CI lane (T024) planned for cross-platform evidence ✅
- [ ] **Always-in-Flow Evidence**: Reader migrations depend on test infrastructure; fixtures depend on inventory; validator depends on readers ✅

---

## Approvals and Deferrals

### Pre-Implementation Sign-Off (This Gate)
- ✅ **Planning-time analysis complete**: Security, error handling, test-integrity targets recorded
- ✅ **Explicit non-applicable reasoning**: Retry, idempotency, credential management captured
- ✅ **Quality lenses identified**: security-baseline, robustness-baseline, test-integrity marked as required
- ⏳ **Human approval pending**: Feature 023 implementation authorized per approved planning; this gate confirms governance readiness

### Known Deferrals (Explicitly Approved Deferred Until Later)
1. **Full lens line-by-line execution evidence**: Deferred until implementation phase (T001-T024)
2. **Bug-hunter review (strongest-available routing)**: Deferred to Phase 2+ (not in Iteration 1 scope)
3. **Quality-drift comparison and reference-implementation checks**: Deferred to Phase 2+ (not in Iteration 1 scope)
4. **Known-traps corpus seeding**: Deferred to dedicated known-traps iteration (not in Phase 1 scope)
5. **Runtime-only final proof** (after all tests complete): Deferred until Iteration 1 test execution completes

### Implementation Authorization
**Authorized to proceed with Iteration 1 implementation upon this gate approval**, pending:
- Human Steward approval of dispatch logic (T034)
- Human Steward approval of fixture corpus (T020)
- CI evidence from Iteration 1 test execution (T021-T024)

---

## Iteration 1 Closure Criteria

Feature 023 Iteration 1 is complete and ready for Iteration 2 when:
1. All reader migrations complete (T004-T008, T032)
2. Human Steward approves dispatch logic (T034 sign-off)
3. Legacy fixture corpus complete and human-approved (T020 sign-off)
4. All fixture tests pass on Windows (T023)
5. Linux CI lane active and tests pass on Linux (T024)
6. Bootstrap reference implementation established and reviewable

---

## Sign-Off Record

**Gate Status**: ⏳ **PLANNING-READY** (planning-time analysis complete; runtime evidence pending)

**Prepared By**: Spec Kit Planning Extension  
**For Feature**: 023 - Legacy-State Read-Tolerance  
**Iteration**: 001 (Schema Markers + Reader Migrations + Fixture Corpus)  
**Authorization Date**: 2026-05-19  
**Authorization Commit**: e9e283d7291e1d52fc4fe86aa893cc5c4769f176  

**Human Approval Pending**:
- [ ] Alon Fliess (Human Steward) — Approve planning-time hardening analysis and authorize Iteration 1 implementation

---

**End of Hardening Gate Document**
