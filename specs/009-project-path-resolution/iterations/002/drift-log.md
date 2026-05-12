# Drift Log: Iteration 002 Planning Decisions

**Iteration**: 009-project-path-resolution / 002  
**Planner**: Planner  
**Date Created**: 2026-05-09  

---

## Scope Boundary Decisions

### Decision 1: Three-File Scope is Exhaustive for FR-003 Audit Gap

**Context**: User (Alon Fliess) identified three specific files as "remaining audit-gap items for FR-003." The feature 009 Phase 1 plan included audits of:
- Five user entry-point scripts (specrew-*.ps1)
- 11 internal governance scripts in extensions/ and .specify/extensions/ mirrors

Phase 1 implementation completed all 16+ audited files. Three additional test/evaluation files were not in the original Phase 1 task list.

**Decision**: Plan this iteration to address exactly these three named files and no others. Do not expand to broader test-suite or evaluation-script scanning.

**Rationale**:
- User explicitly named the three files, implying these are the only known gaps
- Phase 1 research was comprehensive for governance scripts; test/evaluation files were out of scope  
- Keeping the slice small ensures rapid review and deployment before feature 008 work resumes
- Any additional audit gaps not named by user should be deferred to a future iteration or raised as a new feature request

**Impact**: Iteration scope is 3–4 story points instead of 8+. This keeps capacity predictable and avoids scope creep.

---

### Decision 2: process-scorer.ps1 is an Exemption Candidate, Not a Mandatory Migration

**Context**: The user's scope constraint states: "migrate only if the parameter is truly a user-supplied relative path; otherwise plan/document a justified exemption."

Audit findings for `evaluation/scorers/process-scorer.ps1`:
- Parameter: `[string]$ProjectPath = (Get-Location).Path` (has a safe default; user can override)
- Main path resolution: Line 265 uses `(Resolve-Path -Path $ProjectPath).Path`, not `GetFullPath`
- GetFullPath calls exist but on computed paths (line 92, 96, 99), not on raw user input like `$ProjectPath`
- The `$ReportPath` parameter (optional) does use `GetFullPath` internally but is a report output path, not a project/spec/iteration path

**Decision**: Record process-scorer as an exemption. Explain why it does not meet the "user-supplied relative path using raw GetFullPath" criteria.

**Rationale**:
- The defect model for feature 009 is: user supplies relative path → script uses `[System.IO.Path]::GetFullPath` → resolves against .NET CurrentDirectory (wrong) instead of PowerShell cwd (correct)
- process-scorer does NOT follow this pattern; it uses `Resolve-Path` which resolves against PowerShell cwd correctly
- The GetFullPath calls in process-scorer are on paths that have already been joined/computed, not on raw user input
- Documenting the exemption with clear criteria protects against future objections and helps other auditors understand why this file was skipped

**Impact**: Reduces task count from 9 to 8 tasks. Updates known-traps.md with exemption rationale to close the audit.

---

### Decision 3: Static-Scan Target Extension Includes All Three Files

**Context**: The regression test in `tests/integration/project-path-resolution-regression.ps1` contains a `$scanTargets` array listing files that should be scanned for the anti-pattern `[System.IO.Path]::GetFullPath($ProjectPath|...)`.

The current scan targets include:
- 5 user entry-point scripts (scripts/*.ps1)
- 10 extension governance scripts (extensions/ and .specify/ mirrors)
- No test/evaluation scripts

**Decision**: Add all three files to `$scanTargets`, even though process-scorer is an exemption:
- `tests/manual/copilot-squad-smoke.ps1`
- `tests/manual/copilot-squad-confidence-lane.ps1`
- `evaluation/scorers/process-scorer.ps1`

**Rationale**:
- The static scan is a safety check to prevent reintroduction of the pattern. Even if process-scorer is exempt now, scanning it ensures the pattern does not drift back in
- Smoke and confidence-lane must be scanned to verify T001-T002 migrations are complete
- The scan is deterministic and finds zero findings if the pattern does not exist, so adding files increases coverage at no cost

**Impact**: Extends regression test by three files. Increases regression test coverage without complexity or false-positive risk.

---

### Decision 4: Iteration 002 Does Not Reopen Known-Traps Corpus or Phase 5 Closure

**Context**: Feature 009 Phase 5 created `.specrew/quality/known-traps.md` and seeded the `path-resolution` trap entry with:
- Pattern description
- Detection method (static scan)
- Remediation (use Resolve-ProjectPath)
- Discovery date (2026-05-09)

**Decision**: Iteration 002 will ADD exemption rationale for process-scorer to the known-traps corpus but will NOT modify or re-run the trap reapplication evidence already recorded in feature 009.

**Rationale**:
- Feature 009 Phase 5 closed with trap reapplication evidence recorded in `specs/009-project-path-resolution/quality/trap-reapplication.md`
- Iteration 002 is a follow-on slice, not a re-implementation of Phase 5
- Recording exemption rationale alongside the trap entry is a lightweight bookkeeping update, not a re-run of the full reapplication process
- Any future trap reapplication will be triggered by a separate review cycle, not by this iteration

**Impact**: Iteration 002 produces a clean exemption record without reopening closed Phase 5 work. Known-traps corpus remains fit-for-purpose for future feature audits.

---

### Decision 5: Effort Estimate Is 3–4 Story Points

**Context**: Phase 1 closure required ~20 story points across six phases (setup, US-1/entry-points, US-2/internal, US-3/regression, trap seeding, validation).

Iteration 002 scope is:
- Two script migrations (T001-T002): Similar to Phase 2 migration tasks (US-1) but smaller scripts; ~1 SP each = 2 SP
- One audit with exemption record (T004-T006): Lighter than migration; ~0.5 SP
- Static-scan extension and regression test (T007-T008): ~0.5 SP
- Total: 3–3.5 story points

**Decision**: Estimate iteration 002 at 3–4 story points. Single implementer, expected 2–3 day duration.

**Rationale**:
- Scripts are smaller than governance entry points; shorter change surface
- No new regression test creation (only extending existing $scanTargets list)
- Exemption record is documentation, not code
- Review overhead is light because scope is bounded and traceability is clear

**Impact**: Helps capacity planner assess if iteration can start before feature 008 work. If capacity is constrained, this iteration could be deferred without blocking feature 008 resumption.

---

### Decision 6: Review Approval Gate Is Explicit For Exemption Rationale

**Context**: The decision to skip process-scorer is justified but is a design choice that affects audit completeness. Future reviewers or maintainers might question why an evaluation scorer was excluded from path-resolution migration.

**Decision**: Require explicit reviewer approval of the exemption rationale before the iteration is marked complete. The review.md artifact will record the reviewer's sign-off on why process-scorer meets the exemption criteria.

**Rationale**:
- Exemptions are design decisions that benefit from human review, not just automation
- Recording the reviewer's confirmation in review.md creates an auditable record
- This prevents silent reintroduction of the same file in a future audit round where the exemption rationale is forgotten

**Impact**: Adds a manual review step in the approval path. Ensures exemption rationale is vetted before closure.

---

## Schedule and Capacity Notes

- **Iteration 002 is BLOCKED** until human (user/Alon Fliess) confirms these are the only three remaining audit gaps
- **Parallel execution**: T001 and T002 can run in parallel; T004 can also run in parallel if capacity permits
- **Critical path**: T007 and T008 must wait for T001-T002 to complete so regression test can verify zero findings
- **Estimated wall-clock time**: 2–3 days at normal capacity
- **Dependency on other work**: None blocking. Feature 008 can resume independently while Iteration 002 executes.

---

## Deferred Decisions (Recorded for Future Iterations)

1. **Broader test-suite scanning** (e.g., tests/integration/*.ps1, tests/unit/*.ps1) — deferred until a future audit gap is explicitly identified
2. **Feature 005 mechanical-lens catalog mapping** — remains deferred per feature 009 plan; no iteration 002 scope expansion
3. **Repository-wide GetFullPath cleanup** — out of scope for this defect model; future architectural work only
4. **Cross-platform ergonomics** — deferred per feature 009 phase 2 plan; beyond shared helper scope

---

**Drift Log Complete**: 2026-05-09 | **Next Step**: Await human approval to enter executing status
