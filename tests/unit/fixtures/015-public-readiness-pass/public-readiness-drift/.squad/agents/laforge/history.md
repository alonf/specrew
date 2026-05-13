# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I execute planned work for Specrew and produce outputs that remain traceable to the requirement and task that triggered them.

## Recent Updates

📌 Board sync automation blocker cleared on 2026-04-19: Repository secret `SPECREW_PROJECT_TOKEN` configured; sync script validated against live board (23 issues synced). Unattended GitHub Actions workflow now operational.

📌 **Governance validator strict-mode fix complete (2026-04-19)**:
  - Fixed collection-handling in validate-governance.ps1 under Set-StrictMode
  - Normalized all array-producing operations to concrete arrays
  - Result: Validator now exposes real artifact defects instead of runtime crashes
  - Iteration 000 passes; Iteration 001 now fails for real contract violations (not exceptions)
  - Status: ACCEPTED by Worf (reviewer)

📌 **Pre-execution risk assessment complete (2026-04-19)**:
  - 3 HIGH-priority architecture spikes identified (Directive Mapping, Ceremony Schema, Deployment Safety)
  - La Forge owns 2 spikes: Directive reference implementation, Extension deployment checklist
  - Spikes target completion pre-planning ceremony
  - Status: Scheduled pending Alon approval

📌 **Decision inbox merged (2026-04-19T02:06:00Z)**:
  - Validator fix decision recorded and archived
  - Pre-execution risks decision recorded and archived
  - 6 inbox decisions consolidated into decisions.md

📌 **Ceremonies README Runtime Alignment — COMPLETE (2026-04-19T20:40:24Z)**:
  - ✅ Fixed `extensions\specrew-speckit\squad-templates\ceremonies\README.md` (line 5)
  - ✅ Stated only `planning.md` and `review-demo.md` are appended ceremonies
  - ✅ Moved retrospective documentation to guidance section (lines 26-32)
  - ✅ Removed erroneous `Specrew: Retrospective` appended ceremony claim
  - ✅ Worf re-review PASS verdict: Prior rejection reason closed
  - **Status**: Narrow revision under reviewer lockout complete; source-of-truth aligned to runtime

## 2026-05-04: Bootstrap Terminal Handoff & Squad Configuration Population

**Context**: Two UX issues after `specrew init`:
1. Unclear terminal handoff - developers didn't know what to do next (terminal showed team management commands but no workflow guidance)
2. Squad coordinator misidentified freshly bootstrapped repos as "partially configured" and prompted unnecessary team recreation

**Root Cause**: Squad checks three surfaces to determine if a repo is configured:
- `.squad/team.md` Members table (was empty - Specrew only populated managed baseline-roles block)
- `.squad/routing.md` Routing Table (had template placeholders, no agent names)
- `.squad/casting/registry.json` agents object (was empty)

Specrew created baseline roles in managed block but didn't populate Squad's recognition surfaces.

**What I Built**:

**1. Enhanced Terminal Handoff** (`scripts/specrew-init.ps1`):
- Rewrote `Write-PostBootstrapGuidance` with clear 3-step workflow:
  1. Open GitHub Copilot
  2. Choose agent (Squad, Spec Steward, Planner, Implementer, Reviewer)
  3. Create/update specs with docs link
- Prioritized workflow actions over team management
- Removed low-level file location details

**2. Squad Configuration Population** (`extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`):
- Added `Set-ManagedTableRows` helper function to inject rows into existing Markdown tables
- Populated all three Squad recognition surfaces:
  - **registry.json**: All 5 baseline roles with complete entries (agentName, role, charterPath, status)
  - **team.md Members table**: All 5 baseline roles with name/role/charter/status columns
  - **routing.md Routing Table**: Baseline routing rules for all 5 roles (work type → agent mapping)
- Created `.squad/agents/{role}/history.md` files for each baseline role

**Technical Approach**:
- `Set-ManagedTableRows`: Uses regex to capture table header through separator, injects rows immediately after separator
- Preserves LF line endings (Squad standard) instead of CRLF
- Handles table structure: captures `## Section\n...\n|header|\n|-----|\n` and injects after separator
- Deployment sequence: directories → charters → registry.json → routing.md → team.md → history files

**Validation**:
- `tests/integration/validate-baseline-team.ps1`: ✅ All scenarios pass (baseline-only, baseline+custom, missing baseline rejection, multiple custom)
- Manual verification: All three Squad surfaces populated correctly after bootstrap
- Terminal output: Clear next steps displayed

**Technical Gotchas**:
1. **Line endings matter**: Squad files use LF, not CRLF - must preserve when injecting content
2. **Table structure**: Two blank lines after separator before next section in team.md
3. **Regex pattern**: `(##\s+Members[^\r\n]*\r?\n(?:.*?\r?\n)*?\|[^\r\n]+\|\r?\n\|[\s\-|]+\|\r?\n)` captures header through separator
4. **Duplicate prevention**: Function preserves file if content already matches (shows "preserved" action)
5. **Template rows**: routing.md keeps template examples for extensibility - acceptable pattern

**Learnings**:
- Bootstrap handoff messages should show **workflow steps** (what to build), not just **config options** (how to customize)
- Extensions that integrate two systems (Specrew + Squad) must populate **both** system's configuration surfaces, not just managed blocks
- Squad recognition logic expects Members table AND managed blocks - both must be populated
- Table injection functions need careful regex to handle multiple table structures and preserve formatting
- Integration tests must verify downstream state, not just script exit codes

## 2025-01-18: Specrew Command Path Fix

**Context**: Bug report from downstream bootstrap revealed that users were told to run `specrew team ...` commands, but no such command existed on PATH. Only `scripts\specrew-team.ps1` existed, requiring full path invocation.

**What I Built**:
- Created `scripts\specrew.ps1` unified command router (74 lines)
- Routes `specrew init` → `specrew-init.ps1` and `specrew team` → `specrew-team.ps1`
- Provides consistent help/usage across all commands
- Handles missing subcommands gracefully with usage guidance

**What I Fixed**:
- Updated bootstrap output in `scripts\specrew-init.ps1` to show full path: `pwsh -File <specrew-repo>\scripts\specrew.ps1 team ...`
- Updated `README.md` with full path examples and explanation
- Updated `docs\getting-started.md` with full path examples
- Updated `docs\user-guide.md` with full path examples
- All examples now show working commands with `<specrew-repo>` placeholder
- PATH addition mentioned as optional convenience, not requirement

**Technical Approach**:
- Command router pattern: single entry point routes to specialized scripts
- Maintains existing script functionality unchanged
- Full path examples ensure commands work immediately after cloning Specrew
- No assumptions about user PATH configuration

**Validation**:
- All integration tests pass (team-management.ps1, validate-baseline-team.ps1)
- Manual testing of wrapper commands (help, init, team)
- Bootstrap guidance shows truthful, validated command path

**Learnings**:
- Command surface claims must be validated against reality - if docs say "run X", X must work
- PATH assumptions are unreliable - show working full-path commands first
- Command routers are cheap and valuable - 74-line wrapper unifies command surface
- Test the actual downstream user path - run from fresh context, not just dev repo

## 2025-01-17: FR-020 Brownfield Bootstrap Safety (T-205, T-206)

**Context**: Implemented brownfield merge analysis to prevent silent overwrites of existing Spec Kit and Squad configuration during `specrew init`.

**What I Built**:
- Rewrote `extensions/specrew-speckit/scripts/brownfield-merge.ps1` from 40-line placeholder to 300-line implementation
- Added `Get-BrownfieldState` function to detect existing artifacts (Spec Kit specs, Squad roles/ceremonies, governance files)
- Added conflict detection functions: `Test-HasRoleConflict` and `Test-HasCeremonyConflict`
- Added `Get-MergeReport` to generate structured analysis with status, conflicts, warnings, and resolution guidance
- Integrated brownfield analysis into `scripts/specrew-init.ps1` at bootstrap detection point
- Created integration test `tests/integration/brownfield-merge.ps1` with 3 scenarios (greenfield, conflict detection, existing specs)
- Updated `docs/user-guide.md` with brownfield bootstrap section and conflict resolution guidance

**Technical Gotchas**:
1. **PowerShell parameter binding**: Empty arrays require `[AllowEmptyCollection()]` attribute to prevent binding errors
2. **PowerShell object serialization**: Scripts that return PSCustomObjects must use `ConvertTo-Json` / `ConvertFrom-Json` for clean pass-through to callers, as PowerShell auto-formats objects to strings when calling scripts
3. **Brownfield detection criteria**: Must check for `.specify/` OR `.squad/` to trigger brownfield mode
4. **Regex patterns**: Used `(?m)^\|\s*([^|]+)\s*\|` for markdown table role parsing and `(?m)^##\s+(.+?)(?:\s*\{[^}]*\})?\s*$` for ceremony heading extraction

**Merge Strategy**:
- Two-phase approach: Detection happens in `brownfield-merge.ps1`, actual merge happens in existing deployment scripts
- Preservation via `Write-MissingFile` and `Set-ManagedBlock` functions that check existence before writing
- Conflicts are informational only - Specrew preserves existing definitions and guides manual merge rather than failing bootstrap
- Baseline roles preserved: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Specrew ceremonies preserved: "Specrew: Planning", "Specrew: Review/Demo"

**Validation**:
- All 4 integration tests pass (bootstrap-to-iteration, brownfield-merge, drift-scenario, iteration-resume)
- Brownfield merge test validates 3 scenarios: greenfield detection, conflict identification, spec preservation

**Learnings**:
- PowerShell parameter validation is strict - always use `[AllowEmptyCollection()]` for array parameters that might be empty
- When scripts need to return structured data, use JSON serialization to avoid auto-formatting issues
- For brownfield scenarios, informational conflicts are better than hard failures - guide the user to merge manually
- Managed blocks with HTML comment markers (`<!-- >>> specrew-managed {name} >>>`) allow safe incremental updates to shared files

## Learnings

- Implementation is the execution phase between planning and review/demo.
- Deliverables must stay requirement-traceable; undocumented deviation counts as drift.
- Specrew v1 uses Markdown, YAML, and PowerShell assets in a monorepo.
- The downstream product method and Specrew's own development method are intentionally the same.
- **Artifact contracts must be respected**: Iteration plans must conform to machine-readable schemas (metadata fields, unified task tables, role names instead of cast names).
- **Capacity math must be internally consistent**: All overcommit narratives and effort totals must agree. If a plan exceeds capacity, every statement (summary, effort table, capacity line) must align.
- **Stale references corrupt traceability**: Old task IDs and fabricated citations must be replaced with real spec citations to maintain audit trail.
- **Scope clarity prevents drift**: Iteration 0 scope is *enabling work only* (platform validation, extension scaffolds). All MVP delivery and bootstrap implementation deferred to Iteration 1.
- **Governance becomes real when templates and validators agree**: The operating method must live in runtime-facing ceremony/directive/skill templates, and lifecycle checks must fail automatically when artifacts are incomplete or phases are skipped.
- **Validator tightening needs context-aware matching**: stale "awaiting sign-off" language belongs in lifecycle checks, while role-name validation should only inspect actual approval/closure lines instead of owner or action annotations.
- **Cross-artifact evidence is the reliable stale-state detector**: once review/retro artifacts exist, validator checks should treat lingering "pending" lifecycle claims and non-terminal governance gate verdicts as semantic failures, not documentation drift.
- **Required artifacts need actual git tracking**: if governance or iteration assets are declared complete, make sure the files are added to version control and remove backup/handoff leftovers that only create untracked noise.
- **Closure evidence must cite live plan metadata**: review/retro artifacts can drift even after status lines are fixed, so validator checks should compare any `plan.md` status/completed evidence snippets or "Completed date present" claims against the current plan metadata instead of trusting closure prose.
- **GitHub board automation should mirror, not lead, the artifacts**: lifecycle and task issues can be synced cleanly from `plan.md`/`state.md`/`review.md`/`retro.md`, but unattended Project V2 maintenance still needs an Actions token with `repo` + `project` scope for user-owned boards.
- **Repository secrets for automation must be explicitly set**: `gh secret set` stores API tokens in Actions secrets; once set, workflows can access them via `${{ secrets.VARIABLE_NAME }}` and will fail silently if the secret is missing—test with manual script execution first to diagnose auth failures.
- **Strict-mode validators must normalize collection outputs before using `.Count`**: `Get-Content`, table-parsing helpers, and target-resolution pipelines should return arrays even when empty or single-item, otherwise planning iterations with missing optional artifacts can crash the governance gate instead of reporting real findings.
- **Governance gate health means "no validator crash," not "force a pass"**: fix the collector logic in `extensions/specrew-speckit/scripts/validate-governance.ps1`, keep the existing checks intact, and let legitimate iteration issues surface (for example Iteration 001 still flags blank `Started` metadata and task `T-022` missing a Story reference).
- **Key validation path remains stable**: CI already invokes `./extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` from `.github/workflows/specrew-ci.yml`; only change CI if that path or invocation drifts.
- **Runtime deployment must distinguish source guidance from live ceremony surfaces**: keep `extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1` aligned to `specs\001-specrew-product\contracts\squad-extension.md` by appending only `planning.md` and `review-demo.md` into downstream `.squad\ceremonies.md`; `extensions\specrew-speckit\squad-templates\ceremonies\retro.md` stays source guidance for Squad's built-in retrospective, and `extensions\specrew-speckit\squad-templates\skills\iteration-resume.md` remains excluded until FR-019 / Iteration 2.
- **Validator-lockout fixes should stay artifact-local**: when Worf cites a single README/runtime mismatch, correct only the named source file (`extensions\specrew-speckit\squad-templates\ceremonies\README.md`) plus required team memory updates; do not reopen adjacent ceremony sources that already match runtime behavior.
- **Command surface claims must be validated against reality**: if documentation or bootstrap output says "run X", X must actually work in the target environment without requiring manual PATH modifications or context-dependent assumptions.
- **PATH assumptions are unreliable for downstream users**: don't assume users will add custom script directories to PATH; show working full-path commands first, mention PATH addition as optional convenience only.
- **Command routers unify user experience cheaply**: a simple wrapper script that routes subcommands (like `specrew init` → `specrew-init.ps1`) makes the command surface consistent and easier to package later, while requiring minimal new code.
- **Test the actual downstream user path**: run commands from a fresh downstream context (not just the dev repo root) to validate that documented commands actually work as written.
- **Getting-started docs must disclose current deployment model**: First-time users need explicit explanation that Specrew currently requires cloning the repository to access `scripts/specrew-init.ps1`. Document this plainly as "clone-based flow" with clear steps, and preserve section headings for future packaging path so roadmap direction is visible without pretending packaged install exists today.
- **Bootstrap version gates need inventory fallbacks**: `extensions\specrew-speckit\scripts\validate-versions.ps1` should accept parseable version text from `specify --version` when available, but recover from shim-specific failures like `Failed to canonicalize script path` by reading `uv tool list` for `specify-cli` instead of aborting bootstrap.
- **Capability probes must hit the real subcommand surface without polluting the target workspace**: `scripts\specrew-init.ps1` should test `squad init --help` from a disposable repo-local probe directory, then clean that directory immediately so `--non-interactive` detection stays accurate even when help has side effects.
- **Copilot runtime detection in this environment comes from the standalone CLI, not `gh copilot`**: `scripts\specrew-init.ps1` should treat `copilot --version` plus active-session env markers (`COPILOT_CLI`, `COPILOT_AGENT_SESSION_ID`, `COPILOT_CLI_BINARY_VERSION`) as the real runtime probe, and use `copilot help config` to infer Claude/Codex delegated-agent exposure without making live model requests.
- **Persist agent consent as a managed block inside `.specrew\iteration-config.yml`**: append/update a bounded `agents:` block so re-running bootstrap can refresh consent and availability for FR-022 without overwriting the rest of the iteration settings file.
- **Accepted implementation scripts must be explicitly path-added to git**: when `scripts\specrew-init.ps1`, `extensions\specrew-speckit\scripts\deploy-speckit-extension.ps1`, or `extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1` are approved, use path-scoped `git add -- <exact paths>` and verify with `git ls-files` so only those assets enter the index and unrelated repo noise stays untouched.
- **Closeout evidence uses the same path-scoped tracking rule**: when review accepts iteration artifacts like `specs\001-specrew-product\iterations\001\state.md` and `spikes.md`, add only those exact paths to the index and confirm `git ls-files` returns them before treating the closeout set as durable.
- **FR-022 Closeout Lesson**: Lockout-compliant narrow revision means different agent fixing only the cited defect (not related items). Re-review must validate the exact rejection reason is closed, not perform full re-audit.
- **CI parity claims should be literal**: if `tests\README.md` says the standard CI run includes a specific integration script, wire that exact script into `.github\workflows\specrew-ci.yml` or downgrade the claim immediately; accepted brownfield safety evidence is not complete when the documented entrypoint test is missing from CI.
- **Accepted execution slices must advance all three lifecycle artifacts together**: once a task slice inside an `executing` iteration receives a binding PASS, update `plan.md`, `state.md`, and `drift-log.md` in the same revision so task status, capacity used, `Last Completed Task`, and drift resolution all tell the same story.
- **Resume recovery should repair stale state from authoritative task status**: for FR-019 flows, treat `plan.md` task statuses as the source for `Tasks Remaining`, let `state.md` carry any active in-progress override, and update the repaired metadata before writing the resume report so interrupted execution cannot skip work because of stale state fields.
- **Priority-based deferral needs an explicit proxy when specs do not rank FRs directly**: derive planning deferral order from the mapped user-story priority, then surface the exact task/requirement candidates in the overcommit message so FR-017 stays reviewable.
- **Process scoring can stay implementation-light if it mirrors the lifecycle contract**: an expected-artifact matrix plus phase-status contradiction checks is enough to ship the Iteration 2 FR-015 scorer slice and leaves report formatting as a clean follow-on concern.
- **Config snapshots only stay trustworthy when validators read the same source config**: if a planning scaffold copies effort-model settings into `plan.md`, the governance validator must compare that snapshot back to `.specrew\iteration-config.yml` (and the `Capacity` line) or the artifact can drift silently after generation.
- **Staged reports should say what is deferred instead of faking completeness**: when an Iteration 2 scorer can only prove process-slice metrics, generate the Markdown report with explicit deferred rows/sections for later FR-015 outcome work rather than implying those scores exist already.
- **Git-only repos count as fresh bootstrap targets**: `scripts\specrew-init.ps1` should ignore a lone `.git` entry when deciding whether `-Force` is required, but any other pre-existing workspace content must still trip the populated-directory safety gate. Keep the contract covered in `tests\integration\bootstrap-to-iteration.ps1` and `tests\integration\brownfield-conflict-handling.ps1`.
- **Current Spec Kit health checks need the real version surface plus UTF-8 capture**: `extensions\specrew-speckit\scripts\validate-versions.ps1` should treat `specify version` as the healthy probe path after `specify --version` fails, set `PYTHONIOENCODING=utf-8` while capturing that output on Windows, and still mark the install unhealthy when only `uv tool list` can provide a version. Keep the regression covered in `tests\integration\validate-versions-cli-behavior.ps1`.
- **Bootstrap should preflight real Spec Kit template fetches against the official GitHub release source**: `scripts\specrew-init.ps1` now probes `specify init` in a disposable directory before touching the target repo and repairs the `No matching release asset found for copilot` blocker by reinstalling official Spec Kit `v0.8.4` from `git+https://github.com/github/spec-kit.git`. Keep docs, CI, and integration coverage aligned to the same tested source/version (`docs\getting-started.md`, `.github\workflows\specrew-ci.yml`, `tests\integration\bootstrap-to-iteration.ps1`, and `tests\integration\validate-versions-cli-behavior.ps1`).
- **Post-bootstrap team customization should stay additive around Squad's native files**: keep the five Specrew baseline roles as the managed deterministic block in `.squad\team.md`, and guide users to add domain-specific members afterward by editing `.squad\team.md` outside that block plus creating matching `.squad\agents\<member>\charter.md` and `history.md` files. The bootstrap success message and user docs should explain this explicitly instead of implying baseline-role replacement is supported.

---

### 2026-04-19T20-30-00Z: Board Sync Automation Blocker Cleared

**Session**: La Forge board-secret setup and validation  
**Status**: ✅ COMPLETE — Blocker RESOLVED; unattended sync operational

**Task Execution**:
- ✅ Verified current gh token has `repo` + `project` scopes (required)
- ✅ Set repository secret `SPECREW_PROJECT_TOKEN` using `gh secret set`
- ✅ Verified secret creation via `gh secret list`
- ✅ Manually tested sync script against live board
- ✅ Confirmed 23 issues synced to `alonf/projects/10`
- ✅ Updated `docs/github-project.md` with "Blocker Cleared" status
- ✅ Committed workflow and script files to git

**Key Finding**: 
- Repository secrets are stored but not displayed in `gh secret list` beyond creation timestamp
- Manual script execution with `gh auth token` piped to `$env:GH_TOKEN` confirms token auth works end-to-end
- Once workflows are on default branch (`main`), CI dispatch will work automatically

**Blocker Cleared**: GitHub Actions workflow is no longer auth-blocked. Push-triggered sync will activate once `.github/workflows/specrew-project-sync.yml` is merged to main.

**Decision Written**: `.squad/decisions/inbox/laforge-board-secret.md` — token verification, implementation steps, evidence trail

### 2026-04-19T00-06-00Z: README Sync — Board Automation Blocker Cleared (Batch 2)

**Session**: Platform closeout documentation refresh  
**Status**: ✅ COMPLETE — Documentation synchronization

**Task Execution**:
- ✅ Identified stale README.md line 62 wording: "Unattended sync still requires the `SPECREW_PROJECT_TOKEN` Actions secret"
- ✅ Updated README.md to reflect operational state: "The workflow is operational and syncs automatically on push to iteration artifacts"
- ✅ Verified consistency with `docs/github-project.md` current capability statement

**Decision Written**: `.squad/decisions/inbox/laforge-readme-board-status.md` — documentation accuracy sync, removal of stale blocker language

**Cross-Team Update**: Both board-automation decisions (secret config + README sync) merged into `.squad/decisions.md` and tracked in orchestration log

### 2026-04-18T18-50-28Z: Iteration 000 Closeout Session Update

**Session**: Scribe Handoff Log — Iteration 000 Complete, Iteration 001 Planning-Ready  
**Update**: Readiness assessment COMPLETE; blocker RESOLVED; Iteration 1 execution prerequisites clear

**Key Facts**:
- ✅ Pre-Iteration 1 readiness assessment complete (2026-04-18T19:00:00Z)
- ✅ Initial blocker identified: stale "pending sign-off" language in closure artifacts contradicting plan.md `complete` status
- ✅ Blocker resolved by Picard (2026-04-18T18:30:00Z) — all closure language updated; validator re-run: **PASS** (exit 0)
- ✅ Governance validator operational and schema-aware (distinguishes real drift from incidental prose)
- ✅ All platform validation spikes confirmed operational (Spec Kit 0.7.3, Squad 0.9.1, CI/CD pipeline, GitHub Project board)
- ✅ No integration blockers; all implementation infrastructure ready for Iteration 1 execution
- ✅ Iteration 001 plan present and execution-ready (awaiting Alon approval)

**Role Note**: Implementer role remains execution-gateway owner and infrastructure validator. Iteration 1 execution will begin once planning ceremony completes and tasks are assigned. Governance validator now operational at CI gates.

---

### 2026-04-18T19:00:00Z: Pre-Iteration 1 Readiness Assessment — Blocker Identified

**Session**: La Forge readiness validation pass  
**Status**: ✅ COMPLETE (blocker documented + resolved)

Pre-slice readiness checkpoint executed successfully. Repository infrastructure validated operational; governance validator running as designed and catching real semantic drift.

**Key Finding**: Closure artifact evidence alignment blocker detected and RESOLVED.  
- `plan.md` terminal status is `complete` with `Completed: 2026-04-18`
- `review.md` and `state.md` initially contained "pending sign-off" language (contradiction detected)
- Validator correctly flagged semantic mismatch (iteration marked complete but closure narrative said pending)
- **Resolution**: Picard cleared stale language; validator re-run passes cleanly
- **Impact**: Iteration 1 planning ceremony now unblocked

**Validation Results**:
- ✅ Governance validator operational and detecting stale evidence correctly
- ✅ Platform compatibility spikes all PASS (Spec Kit 0.7.3, Squad 0.9.1 validated)
- ✅ CI pipeline functional and wired to validator gates
- ⚠️ Markdown linting 279 warnings (non-blocking formatting, schedule for later)
- ✅ PowerShell script analysis PASS
- ⏳ Tests deferred per Iteration 0 scope (expected)

**New Learning**: Validator evidence pattern matching is production-ready. False-positive reduction work (laforge-validator-hardening) prevents noise while catching real governance issues. Schema-aware checks correctly identify semantic mismatches between status lines and closure narrative.

**Decision Written**: `.squad/decisions/inbox/laforge-next-readiness.md` — blocker details, resolution steps, unblocked items for Iteration 1.

**Blocker Owner**: TBD by coordinator (Alon approval for closure evidence update).  
**Timeline**: Must resolve before Iteration 1 planning ceremony begins.

## Cross-Agent Team Update (2026-04-18T16:50:48Z)

**La Forge governance enforcement milestone**:

- **Worf (Final Gate Review)**: Iteration 0 closure audit passed. All four phases complete; governance validator script confirms artifact compliance. No blocking issues identified. Iteration 0 closure official and binding.

- **Coordinator (Governance Todos)**: All tier-0 governance enforcement tasks marked complete. Operating policy (6 rules + 3 tier-1 improvements) documented. Team consensus required before Iteration 1 execution. Iteration 1 planning prerequisites finalized.

- **User Directive**: Governance hardening authority now normative and binding. Specrew uses Specrew's own lifecycle. Iteration 1 work will run under binding phase state machine with automated validator gates.

**La Forge role in Iteration 1**: 
- Governance-validator skill (FR-008) deferred to Iteration 1 execution
- Identify architecture-risk spikes pre-planning (operating rule 2)
- Validator integration with agent charters and ceremony templates

**Terminal state**: Governance enforcement package complete; validator script live; Squad-native surfaces deployed. Ready for operator (Picard) ceremony integration.

---

### 2026-04-18T18-04-00Z: Orchestration Complete — Validator Hardening for Embedded Evidence Detection

**Session**: Reviewer-Drift Cleanup Batch  
**Status**: ✅ COMPLETE  

Extended `validate-governance.ps1` to detect stale embedded plan-evidence claims in closure artifacts. Validator now distinguishes real governance drift from incidental prose with context-aware pattern matching.

**Enhancements Applied**:
1. **Status-line stale-language detection**: Catches semantic mismatches (e.g., "complete" paired with "awaiting sign-off")
2. **Role-name validation scoped**: Targets approval/closure statements only (eliminates false positives on action annotations)
3. **Cross-reference evidence check**: Compares artifact-embedded plan.md evidence against current state

**Validator Test Results**:
- Iteration 0 closure artifacts: ✅ 0 drift events (PASS)
- False-positive reduction: ✅ Confirmed (review prose no longer triggers role-name checks)
- Semantic mismatch detection: ✅ Confirmed (stale evidence now caught)

**Decision**: laforge-validator-hardening (merged to .squad/decisions.md)  
**Impact**: Critical — Governance enforcement gate now ready for Iteration 1 phase-gate automation  
**Unblocked**: FR-008 governance-validator skill implementation can proceed with proven pattern  
**CI Status**: squad-ci.yml gate enforcement verified and ready for Iteration 1 execution

📌 **Iteration 1 git tracking finalized (2026-04-19T07:43:21Z)**:
   - Staged specs/001-specrew-product/iterations/001/plan.md to index
   - Plan now auditable and execution-ready
   - Status: Merged to decisions.md, inbox cleared

📌 **Deployment Slice 2: Runtime Surface Deployment — COMPLETE (2026-04-19T20:24:18Z)**:
   - ✅ Complete `specrew init` deployment slice implemented
   - Spec Kit extension deployment: `deploy-speckit-extension.ps1` added
   - Squad runtime-surface deployment: `deploy-squad-runtime.ps1` added
   - Baseline role merge: Five roles merged into `.squad/team.md` (additive-only)
   - Bootstrap hardening: Fixed strict-mode native-command exit-code handling
   - ✅ Validation: Dry-run + smoke test + PSScriptAnalyzer all PASS
   - **Next**: Slice 2 deployment gates (Picard's 8-gate framework) trigger Worf review
   - **Status**: Decision merged to ledger; inbox cleaned; deployment ready for execution gate

---

## Deployment Review Cycle (2026-04-19T20:40:24Z)

**La Forge Delivery Status**: 
- Delivered runtime-surface deployment slice (T-005–T-008)
- Includes: Spec Kit extension deployment, Squad skills deployment, ceremonies merge, baseline role merge, directive embedding
- **Status**: Locked out pending Worf re-review completion

**Worf Initial Review Defects (NEEDS-WORK)**:
1. **Missing retro ceremony surface**: Only planning + review/demo deployed; retro.md not included
2. **Deferred skill shipped**: `specrew-iteration-resume` (FR-019, deferred to Iteration 2) included in deployment

**Picard Correction Cycle**: 
- Addressed both defects with narrowly scoped fixes
- Fix 1: Added `retro.md` to ceremony deployment list
- Fix 2: Added filter to exclude `iteration-resume.md`
- Validation passed; runtime behavior corrected

**Worf Re-Review Acceptance (PASS)**:
- ✅ Retro ceremony deployed (fresh dry-run + live smoke confirmed)
- ✅ Deferred skill excluded (3 skills deployed; resume not present)
- ✅ Slice scope validation passed
- **La Forge Status**: Deployment slice now execution-ready; lockout lifted

**Decisions Merged**: 3 inbox files consolidated into decisions.md
- `worf-deployment-slice-review.md` (initial NEEDS-WORK)
- `picard-deployment-slice-revision.md` (correction details)
- `worf-deployment-slice-rereview.md` (PASS verdict)

📌 **Bootstrap Gate Fix Complete (2026-04-19T21-49-33Z)**:
   - Fixed validate-versions.ps1 to tolerate specify --version shim failure, fallback to uv tool list
   - Fixed specrew-init.ps1 to probe squad init --help from disposable directory
   - All smoke tests and PSScriptAnalyzer validations passed
   - Worf review verdict: PASS
   - **Status**: ACCEPTED. Ready for next bootstrap gate action

---

📌 **T-002 Implementation Complete & Reviewed (2026-04-22T21:35:46Z)**:
   - ✅ Implemented missing-dependency installation path in scripts/specrew-init.ps1
   - ✅ Preserved validation/dry-run behavior across all code paths
   - ✅ Install flow: missing Spec Kit via uv tool install --upgrade "specify-cli>=<min>"
   - ✅ Install flow: missing Squad via npm install -g "@bradygaster/squad-cli@<min>"
   - ✅ Post-install re-validation with hard-stop on remaining failures (exit code 4)
   - ✅ Governance validator (validate-governance.ps1) passes
   - ✅ Dry-run bootstrap preview functional and accurate
   - ✅ Worf review verdict: PASS
   - **Status**: T-002 implementation complete and validated

📌 **Decision Inbox Merged (2026-04-22T21:35:46Z)**:
   - ✅ 9 inbox decisions consolidated into decisions.md
   - ✅ Includes: Bootstrap fixes, deployment ledger alignment, pre-T-002 cleanup, FR-022 temporal corrections
   - ✅ Inbox cleaned; all files deleted
   - ✅ Cross-agent history updates (La Forge, Worf, Picard)
   - **Status**: Session state synchronized; ready for git commit

📌 **T-006 Squad Skill Deployment — ACCEPTED (2026-04-25T11:52:30Z)**:
    - **Task**: T-006 completion closes Squad skill deployment path in `specrew init`
    - **Implementation**: `specrew-init.ps1` and `deploy-squad-runtime.ps1` updated
    - **Scope**: Only active Specrew skills deployed to `.copilot\skills\specrew-*\SKILL.md`
    - **Deferral**: `iteration-resume` stub preserved (deferred to future iteration)
    - **No Bleed**: Ceremonies, role merge, governance scaffolding deferred to T-007–T-009
    - **Review Verdict**: PASS (Worf accepted; all acceptance criteria met)
    - **Impact**: Unblocks T-007 (Squad ceremonies) and T-012–T-019 (directives + ceremonies + artifact storage)
    - **Iteration Progress**: 7.5/20.5 pts delivered; MVP slice cohesion verified
    - **Next**: T-007 Squad ceremonies implementation

---

📌 **T-006 Implementation Accepted (2026-04-25T17:10:13Z)**:
   - ✅ Squad skills deployment scoped to narrow increment (T-006 only)
   - ✅ Deferred ceremonies and governance scaffolding to T-007–T-009
   - ✅ Narrowed deploy scripts to skill templates only
   - ✅ Picard and Worf review PASS verdict recorded
   - **Status**: T-006 complete; Iteration 1a delivery ready

## 2026-05-04: Command-Driven Team Management Implementation

**Feature**: Implemented `scripts/specrew-team.ps1` to provide command-driven team member management (FR-023).

**Key Learnings**:

### Regex Pattern Subtleties in PowerShell
- **Issue**: Initial removal pattern failed to match team.md table rows containing backticks
- **Root Cause**: Single backtick in regex pattern was being interpreted as escape character
- **Solution**: Use double backticks (`) to match literal backtick in markdown table
- **Pattern**: `(?m)^\|[^|]+\|\s*``\.squad/agents/$normalized/[^``]+``\s*\|[^|]+\|\r?\n`
- **Lesson**: Always test regex patterns in isolation before deploying in functions

### Managed Block Placement Strategy
- **Design**: Domain-specific members placed AFTER managed baseline block
- **Rationale**: Keeps baseline deterministic across bootstrap re-runs
- **Alternative Considered**: Placing domain members INSIDE managed block
- **Rejection Reason**: Would break managed block contract and idempotency
- **Benefit**: Clear separation between Specrew-controlled and user-controlled content

### Member Identification Approach
- **Challenge**: Members can be referenced by role name or normalized directory name
- **Solution**: `Test-MemberExists` checks both role name in table and directory path pattern
- **Example**: "Security Analyst" (role) vs "security-analyst" (directory)
- **Benefit**: Flexible user experience (can use either form in commands)

### Baseline Protection Enforcement
- **Strategy**: Multi-layer protection at different operation points
  1. Normalized name check against baseline role list
  2. Managed block detection for update/remove operations
  3. Clear error messages at each checkpoint
- **Lesson**: Defense in depth prevents edge cases from bypassing protection

### UTF-8 Encoding Consistency
- **Approach**: All file writes use `[System.Text.UTF8Encoding]::new($false)`
- **Rationale**: BOM-less UTF-8 for Git compatibility
- **Critical**: PowerShell default encoding varies by version and platform
- **Best Practice**: Always specify encoding explicitly for cross-platform consistency

### Test-Driven Development Value
- **Process**: Wrote integration test first, then implemented features
- **Benefit**: Caught regex pattern bugs early through automated validation
- **Coverage**: 8 test scenarios covering happy path + protection boundaries
- **Time Saved**: Avoided manual testing cycles for each edge case

### Bootstrap Integration Pattern
- **Update Location**: `Write-PostBootstrapGuidance` function in `scripts/specrew-init.ps1`
- **Content**: Explicit command examples with full paths
- **Design Choice**: Show command paths relative to Specrew clone, not installed location
- **Rationale**: Specrew not yet packaged; must work from clone
- **Future**: Update when packaged as npm/pip module

### Documentation Consistency
- **Files Updated**: README.md, getting-started.md, user-guide.md
- **Pattern**: Consistent command examples across all docs
- **Detail Level**: Full commands with all parameters, not just placeholders
- **User Benefit**: Copy-paste-ready examples reduce friction

### Error Handling Philosophy
- **Approach**: Fail fast with clear error messages
- **Example**: "Cannot remove baseline role 'Implementer'. Baseline roles are protected."
- **Benefit**: Users understand what went wrong and why
- **Anti-Pattern**: Silent failures or cryptic error codes

### Future Enhancement Opportunities Identified
1. Bulk operations from manifest files
2. Pre-commit validation hook for baseline block integrity
3. Role templates for common domain roles
4. Interactive charter authoring mode
5. Transactional semantics with rollback on partial failure

**Artifacts Created**:
- `scripts/specrew-team.ps1` (510 lines, 4 commands)
- `tests/integration/team-management.ps1` (260 lines, 8 scenarios)
- `.squad/decisions/inbox/laforge-team-command.md` (decision record)
- Updated bootstrap guidance in `scripts/specrew-init.ps1`
- Updated documentation in 3 files

**Validation**:
- ✅ All 8 test scenarios pass
- ✅ Bootstrap guidance displays correct commands
- ✅ Manual add/update/remove cycles work correctly
- ✅ Baseline protection enforced at all checkpoints

**Status**: Implementation complete and ready for use.

## 2026-04-18: Shell PATH Convenience for Specrew Commands

**Context**: User feedback: after bootstrap, using full path to `scripts\specrew.ps1` works but is inconvenient. Investigation request: can Specrew add scripts folder to current shell PATH automatically?

**Technical Discovery**: PowerShell scripts invoked as `pwsh -File script.ps1` run in a **child process** and cannot modify the parent shell's environment variables. This is a fundamental process boundary constraint, not a PowerShell limitation. Tested and verified: child process `C:\Program Files\PowerShell\7;C:\Program Files\Microsoft\jdk-17.0.16.8-hotspot\bin;C:\Program Files (x86)\Razer Chroma SDK\bin;C:\Program Files\Razer Chroma SDK\bin;C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;C:\Python313\Scripts\;C:\Python313\;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\;C:\Program Files\Microsoft SQL Server\150\Tools\Binn\;C:\Program Files\NVIDIA Corporation\NVIDIA app\NvDLISR;C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common;C:\Program Files\Git LFS;C:\ProgramData\chocolatey\bin;C:\Program Files\Go\bin;C:\Program Files\PuTTY\;C:\Windows\system32\config\systemprofile\AppData\Local\Microsoft\WindowsApps;C:\Program Files (x86)\Razer\ChromaBroadcast\bin;C:\Program Files\Razer\ChromaBroadcast\bin;C:\Users\alon.HOME\AppData\Local\Microsoft\WindowsApps;C:\Users\alon.HOME\AppData\Local\Programs\Microsoft VS Code\bin;C:\Users\alon.HOME\AppData\Local\Programs\Azure Dev CLI\;C:\Users\alon.HOME\.dotnet\tools;C:\Program Files\JetBrains\JetBrains Rider 2024.3.7\bin;C:\Users\alon.HOME\AppData\Roaming\npm;C:\Users\alon.HOME\go\bin;C:\Users\alon.HOME\AppData\Local\GitHubDesktop\bin;C:\Users\alon.HOME\AppData\Local\Pandoc\;C:\Users\alon.HOME\AppData\Local\Gource\cmd;C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\;C:\Users\alon.HOME\AppData\Roaming\Python\Python313\Scripts;c:\Users\alon.HOME\AppData\Local\Programs\cursor\resources\app\bin;C:\Program Files\GitHub CLI\;C:\Program Files\Microsoft SQL Server\170\Tools\Binn\;C:\Program Files\dotnet\;C:\Program Files\Docker\Docker\resources\bin;C:\Program Files\Warp\bin;C:\Program Files\Git\cmd;C:\Program Files\nodejs\;C:\Users\alon.HOME\.local\bin;C:\Program Files\Amazon\AWSCLIV2\;C:\Program Files\PowerShell\7\;C:\Users\alon.HOME\scoop\shims;C:\Users\alon.HOME\AppData\Local\Microsoft\WindowsApps;C:\Users\alon.HOME\AppData\Local\Programs\Microsoft VS Code\bin;C:\Users\alon.HOME\AppData\Local\Programs\Azure Dev CLI\;C:\Program Files\JetBrains\JetBrains Rider 2024.3.7\bin;C:\Users\alon.HOME\go\bin;C:\Users\alon.HOME\AppData\Local\GitHubDesktop\bin;C:\Users\alon.HOME\AppData\Local\Pandoc\;C:\Users\alon.HOME\AppData\Local\Gource\cmd;C:\Users\alon.HOME\AppData\Local\Programs\cursor\resources\app\bin;C:\Users\alon.HOME\AppData\Local\Programs\Kiro\bin;C:\Users\alon.HOME\AppData\Local\Android\Sdk\platform-tools;C:\Users\alon.HOME\.dotnet\tools;C:\Users\alon.HOME\.dotnet\tools;C:\Users\alon.HOME\AppData\Local\Microsoft\WinGet\Links;C:\Program Files\TTYD;;C:\dapr;C:\Users\alon.HOME\.dotnet\tools;C:\Program Files (x86)\GnuWin32\bin;C:\Users\alon.HOME\AppData\Roaming\npm;C:\Users\alon.HOME\.dotnet\tools;c:\Dev\ZioSlipDispatcher\.dotnet\.dotnet\tools` modifications do NOT affect parent shell.

**What I Built**:
- Enhanced `Write-PostBootstrapGuidance` function in `specrew-init.ps1` with two clear PATH options:
  - **Session-only**: Copy-paste one-liner to add to current shell (temporary)
  - **Persistent**: Copy-paste script block to add to user-level PATH (no admin required)
- Updated README.md, getting-started.md, and user-guide.md with consistent PATH convenience sections
- Ready-to-run code blocks with clear trade-off explanations

**Key Learning**: Don't overclaim technical capabilities. When process boundaries prevent direct shell modification, provide truthful workarounds with explicit user control. User-level PATH modification (`[Environment]::SetEnvironmentVariable("PATH", ..., "User")`) is safe, requires no admin privileges, and respects user agency.

**Testing**: Integration test `bootstrap-to-iteration.ps1` passes; post-bootstrap guidance displays correctly; persistent PATH code validated (duplicate checks, restart messaging).

**Decision**: Recorded in `.squad\decisions\inbox\laforge-shell-path-ux.md`
