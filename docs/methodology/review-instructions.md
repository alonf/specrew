# Specrew Review Instructions

This document is for reviewers (human + AI) asked to review Specrew work. It complements [lifecycle-discipline.md](lifecycle-discipline.md) (the shared methodology contract) and [proposal-discipline.md](proposal-discipline.md) (proposal management).

## Purpose

Specrew is a governed agentic SDLC layer over GitHub Spec Kit. It keeps a human in control at explicit lifecycle boundaries while AI agents do the implementation work between those boundaries. Specrew can run through multiple AI hosts, including Codex, Claude Code, GitHub Copilot CLI, and Antigravity, but the durable source of truth is the repository artifact trail, not any one host's memory.

This repository is dogfooding Specrew: Specrew is being built using Specrew. That means the review is not only a normal code review. It is also a methodology review. The reviewer must verify that the feature obeys Specrew's own lifecycle, traceability, audit, and boundary rules — see [lifecycle-discipline.md](lifecycle-discipline.md) for the full contract.

## Who This Is For

This document serves multiple reviewer audiences. Use this map to find the sections relevant to your role:

| Reader role | Sections to read |
|---|---|
| **Iteration reviewer** (review-signoff, retro, iteration-closeout) | All of this document + [lifecycle-discipline.md](lifecycle-discipline.md) Boundary Discipline / Spec Authority / Traceability / Drift / Committed-Tree Durability / Lifecycle Metadata Integrity / Spec Coverage Verification / Shape Catalog |
| **Feature-closeout / PR / Release reviewer** | All of the iteration-reviewer reading + [lifecycle-discipline.md](lifecycle-discipline.md) Release Process Discipline section (repository / SDLC Steps 5-14 / CI / PSGallery / beta-vs-stable / per-boundary checklist) |
| **Proposal reviewer** (any commit touching `proposals/*.md`) | This document Bootstrap + Source of Truth + Review Method + [proposal-discipline.md](proposal-discipline.md) end-to-end |
| **AI agent acting in any reviewer role** | Read everything. Bootstrap section explicitly addresses cold-start orientation for AI sessions. |

When the AI reviewer issues a `rejected for <boundary>` verdict, the reject message MAY cite specific sections of this file by name for the implementer to consult. This is the intended use; the file is a shared methodology contract, not a hidden review rubric.

## Bootstrap Context for Fresh Reviewer Sessions

If you are starting a review session cold (especially as an AI agent — your context may not include prior conversation history):

1. **Read this file first** plus [lifecycle-discipline.md](lifecycle-discipline.md). They are the methodology contract for Specrew reviews.
2. **Identify which iteration is under review.** The user will name a feature ID + iteration number (e.g., `F-049 / Iteration 003`) and a commit HEAD (e.g., `8641c738`). All your verification must be against that specific committed state, not the working tree.
3. **Bootstrap project state**:

   ```powershell
   git rev-parse HEAD
   git branch --show-current
   git log --oneline -10
   git status --short
   ```

4. **Locate the iteration's authoritative artifacts**:

   ```text
   specs/<feature>/spec.md                                  # the contract
   specs/<feature>/plan.md                                  # feature-level roadmap
   specs/<feature>/iterations/<NNN>/plan.md                 # iteration scope
   specs/<feature>/iterations/<NNN>/tasks-progress.yml      # task ledger
   specs/<feature>/iterations/<NNN>/quality/quality-evidence.md  # acceptance evidence
   ```

5. **Understand the active boundary**: the user's verdict request will name a target boundary (e.g., `review-signoff`). Your verdict must address that specific boundary, no other.

6. **Confirm host context if relevant**: Specrew runs through multiple AI hosts. The active host's session-scratch may contain ephemeral state that should NOT be cited as evidence (Shape 2: wrong-location pattern). Stay anchored to the repository artifact trail.

If memory or persistent-instruction files (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`) are available in the project root, read them — they may contain project-specific reviewer guidance that supplements this document.

## Core Review Stance

Default to a read-only review unless the human explicitly asks you to modify files.

Lead with findings. Prioritize bugs, requirement drift, behavioral regressions, missing evidence, missing tests, and lifecycle/audit inconsistencies. Summaries are secondary.

Do not approve because tests are green. Tests are one evidence source. The delivered behavior, spec conformance, committed artifacts, and lifecycle state must also match.

Do not reject for style or preference unless it creates a real maintainability, correctness, governance, or user-facing risk.

## Source Of Truth Order

When artifacts disagree, use this order:

1. Human-approved spec requirements in `specs/<feature>/spec.md`.
2. Human-approved iteration scope in `specs/<feature>/iterations/<NNN>/plan.md`.
3. Task progress and lifecycle metadata in `tasks-progress.yml`, `review.md`, `retro.md`, `dashboard.md`, and closeout artifacts.
4. Implementation files and tests.
5. Handoff prose from the previous AI host.

Handoff prose is useful but not authoritative. Verify it against committed files.

## What To Inspect First

Start every review with repository state:

```powershell
git status --short --branch
git rev-parse HEAD
git branch -vv
git log --oneline -10
```

Confirm:

- The branch and HEAD match the claimed handoff.
- The worktree is clean, or any dirt is explained and unrelated.
- Claimed commits exist and subjects match the claim.
- The upstream branch, if relevant, points to the same commit.

Then inspect the feature package:

- `specs/<feature>/spec.md`
- `specs/<feature>/iterations/<NNN>/plan.md`
- `specs/<feature>/iterations/<NNN>/tasks-progress.yml`
- `specs/<feature>/iterations/<NNN>/quality/`
- `specs/<feature>/iterations/<NNN>/review.md`, if present
- `specs/<feature>/iterations/<NNN>/retro.md`, if present
- `specs/<feature>/iterations/<NNN>/dashboard.md`, if closeout was claimed
- `.squad/decisions.md` and relevant decision inbox/archive files
- Relevant implementation and test files

## Review Method

1. Reconstruct the claimed scope.
   Read the FRs, SCs, task table, and any explicit human decisions. Identify exactly what the iteration promised to deliver.

2. Trace tasks to requirements.
   Every task should map to at least one FR, SC, or approved technical governance item. Every in-scope FR/SC should have at least one implementing or evidence task.

3. Verify behavior against the spec.
   Inspect the actual code path that production commands use. Do not rely only on helper-level tests if the real orchestrator uses the helper differently. Specifically:
   - **Trace type contracts**: when the spec allows multiple types for a value (e.g., `1-10 or "auto"`), trace the value from entry point through every function call. PowerShell `[ValidateRange()]` + strict typing will crash at runtime if a string reaches an integer parameter.
   - **Read schema definitions**: open the spec's schema section and the implementation's actual write/serialization. Compare field names character-for-character. Renames, missing required fields, and changed nesting are common drift.
   - **Audit escape hatches end-to-end**: every escape hatch the spec lists (`"Other"`, `"I don't know"`, `"auto"`, `--force`, `default fallback`) must be exercised by a test that goes through the production entry point, not just a helper unit test.

4. Verify evidence against the committed tree.
   Evidence files must cite files that exist in the committed tree. If a test or artifact only existed in the working tree, it is not durable evidence. See [lifecycle-discipline.md](lifecycle-discipline.md) Committed-Tree Durability for multi-altitude verification technique.

5. Run or verify tests.
   Prefer the scoped tests named by the handoff. If a validator writes cache or summary files, run it in an isolated clone unless the human authorized modifying the main checkout.

6. Check lifecycle consistency.
   `plan.md`, `tasks-progress.yml`, `review.md`, `retro.md`, dashboards, closed-iteration index, and decisions ledger should tell the same lifecycle story.

7. Check audit timestamps and commit history.
   Timestamps should be historically plausible and compatible with the commits that introduced the work. Fabricated or impossible timestamps are an audit-trail defect.

8. Separate blockers from retro lessons.
   Blockers prevent approval. Retro lessons are useful process findings that should be captured, but they do not block unless they caused an actual delivery or governance gap.

## Post-Ship Proposal Amendment Reviews

When implementation or review evidence references a shipped or superseded
proposal, review the work as a delta from shipped behavior, not as a fresh
implementation of the whole historical proposal.

Required checks:

- Identify the `amendment-id` or superseding proposal reference.
- Compare delivered behavior against the amendment delta, not the full shipped proposal body.
- Verify the preserve list: shipped behavior that must remain intact is characterized by tests, protected by regression coverage, or explicitly changed by the approved delta.
- Verify `tests-required` was satisfied or explicitly deferred by the human.
- Check the diff for unrelated shipped-scope reimplementation.
- Confirm closeout evidence names the final amendment disposition, such as `implemented` or `superseded`.

Evidence that merely says "matches Proposal NNN" is over-strong for post-ship
work unless it also names the active delta and the shipped behavior preserved.
For these reviews, FR-006 and FR-015 are release-blocking: missing delta evidence
or any rewrite of real shipped proposal bodies blocks signoff unless the human
records a narrower deferral or explicit exception.

## Common Specrew Review Failure Modes

Use these as prompts during review:

- Green tests but untested spec behavior is broken (Shape 7 in [lifecycle-discipline.md](lifecycle-discipline.md) Shape Catalog).
- Helper works, orchestrator fails because types or data shapes differ (Shape 7 variant).
- Schema written by implementation does not match the schema in the spec (Shape 7 variant).
- Evidence claims an SC passes but measures only part of it.
- Handoff says branch is clean or pushed, but local HEAD/upstream says otherwise.
- Commit subjects or hashes are swapped in the handoff.
- Plan and task-progress artifacts disagree on lifecycle state.
- Timestamps are impossible or copied from a template.
- Governance validator passes but does not check a functional requirement.
- A large fix-time helper appears because a design dependency was missed during planning.
- Boundary cadence promised in the plan is not reflected in actual commits.
- "Repaired the gaps the prior runs left behind" language in handoff implies broken-as-initially-committed state somewhere in the commit chain — audit those commits.

## Running Validation

Run scoped tests that are relevant to the feature. Example:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\<test-file>.ps1
```

Run governance validation when relevant. If it writes cache or summary artifacts, prefer an isolated clone:

```powershell
git clone --no-hardlinks C:\Dev\Specrew C:\tmp\specrew-review-<feature>-<sha>
cd C:\tmp\specrew-review-<feature>-<sha>
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\<feature>\iterations\<NNN> -NoCacheRead
```

After running commands in the main checkout, re-check:

```powershell
git status --short
```

The review should not leave unexplained modifications.

## Approval Criteria

Approve review-signoff only when all are true:

- The implementation satisfies every in-scope FR and SC, or explicit deferrals are human-approved and recorded.
- Required tests and evidence pass against the committed tree.
- The real production paths are covered for the important behaviors.
- Lifecycle artifacts are internally consistent.
- Audit metadata is plausible and traceable.
- Known gaps are either fixed or formally deferred by the human.
- The worktree and branch state match the handoff claim.

## Rejection Criteria

Reject or require rework when any are true:

- A required FR/SC is not implemented.
- A required edge path is broken.
- Evidence claims more than it proves.
- Tests pass but do not cover a required behavior that is likely to fail.
- Lifecycle state is contradictory.
- Audit trail is fabricated, impossible, or materially incomplete.
- Required files are missing from the committed tree.
- The implementation changed scope without a recorded decision.

## When To Recommend Independent Cross-Reviewer Verification

Single-reviewer review is empirically insufficient for high-stakes Specrew work. The F-049 iter-3 review demonstrated this concretely: a single-reviewer Pillar 5 form check (tests pass + files committed) approved an iteration that an independent reviewer correctly rejected after finding 4 substantive gaps (schema mismatch, broken escape hatch, incomplete SC evidence, lifecycle artifact inconsistency).

Recommend (or perform yourself, if asked) a cross-reviewer pass when:

- The iteration ships architectural foundation work that future iterations depend on.
- The iteration introduces a new validator rule, lifecycle boundary, or governance contract.
- The iteration claims a multi-clause success criterion (e.g., "≥30% reduction AND ≥40% reduction AND no regression").
- The iteration's tests rely on parameter overrides that bypass the production codepath.
- The handoff includes language like "repaired the gaps the prior runs left behind" — signals incomplete prior work that may have left subtle defects.
- The iteration involves cross-platform behavior (Windows + Mac/Linux), mirror parity, or multi-host deployment.

When acting as the second reviewer, do not start from the first reviewer's conclusions. Read the spec + code + tests independently. Cross-check schema field names. Read parameter types. Trace escape hatches end-to-end. Then compare your findings to the first reviewer's; gaps between you reveal the value of cross-verification.

Proposal 102 (Cross-Model Independent Reviewer) is the planned long-term automation for this; until it ships, recommend manual cross-reviewer for high-stakes iterations.

## Verdict Format

Use concise, direct verdicts. Findings first. **Name the EXACT target boundary** in the verdict — ambiguity here has caused real lifecycle confusion in past Specrew dogfooding (e.g., "approve for review-boundary progression" was rejected because the boundary wasn't named precisely). Acceptable verdict shapes:

- `approved for plan boundary`
- `approved for before-implement`
- `approved for review-signoff`
- `accepted for review-signoff` (verdict shape varies by lifecycle phase)
- `rejected for review-signoff` (with named gaps)
- `blocked pending clarification`

Never use ambiguous phrasing like "approve for next boundary" or "looks good" without naming what is approved.

Recommended structure:

```markdown
Recommendation: reject review-signoff / approve review-signoff / blocked pending clarification.

Findings:

1. [Severity] Requirement or artifact affected.
   Evidence: file path and line, command result, or observed behavior.
   Impact: why this blocks or matters.
   Required fix: concrete next action.

2. ...

Verified true:

- Branch/head state.
- Tests that passed.
- Validator result.
- Evidence that is valid.

Not blocking / retro capture:

- Process lessons.
- Commit cadence concerns.
- Design-analysis lessons.

Final recommendation:

- What must change before approval.
```

## Severity Guidance

Use `blocking` for issues that prevent lifecycle approval:

- Spec non-conformance.
- Broken required behavior.
- Missing required evidence.
- Contradictory lifecycle state.
- Invalid audit trail.

Use `major` for serious risks that may not block the current boundary if explicitly deferred:

- Weak coverage around a non-critical path.
- Maintainability risk from rushed design.
- Cross-host parity risk with partial evidence.

Use `minor` for cleanup that should not affect approval:

- Wording clarity.
- Non-substantive formatting.
- Optional artifact polish.

Use `retro` for process lessons:

- Commit cadence drift.
- Late discovery of design alternatives.
- Handoff wording errors.
- Evidence that points to a future validator improvement.

## Reviewer Mindset

Be skeptical of summaries and generous with facts. Verify before judging. Separate what is proven from what is claimed. Specrew's value is that the human can trust the artifact trail after the host changes; the AI reviewer protects that trust by making drift visible before approval.

When the AI host (Codex, Claude Code, GitHub Copilot CLI, Antigravity, others) has produced a "ready" handoff, the reviewer's job is NOT to trust it. The reviewer's job is to ask: *what would I observe if it were not ready?* If those observations would be visible only by reading code paths or comparing schemas, you must do that reading. If they would be visible only by running tests against the committed tree, you must run those tests in an isolated clone. The handoff is data; verification is the verdict.

## Verifying Agent Diagnoses

When an AI agent (the host being reviewed, OR the reviewer agent itself, OR any subagent in the chain) proposes a root-cause diagnosis for a defect, the reviewer must require an EMPIRICAL CONFIRMATION step before treating the diagnosis as accepted.

Empirical confirmation means: open the actual file, check the actual bytes, run the actual command, observe the actual behavior, query the actual API. Pattern-matching against similar past bugs is not empirical confirmation. Plausible-sounding technical explanations are not empirical confirmation. Citing documentation is not empirical confirmation if the documentation could be wrong about this specific case or version.

Empirical evidence from Specrew dogfooding: in one session, a host agent proposed three distinct hallucinated root causes in sequence for a single failure (a UTF-8 Hebrew filename theory; a CORS-plus-locked-binary theory; a library-trial-mode-corrupts-output theory). Each was confidently presented with technical detail. Each was wrong. Each proposed "fix" was a patch that didn't address the actual problem. The actual root cause turned out to be a missing parameter on a `Save()` call — discoverable in 30 seconds by reading the production-code call site, not knowable by reasoning from symptoms.

Common signs an agent diagnosis needs empirical confirmation before acceptance:

- The diagnosis explains the visible symptom plausibly but doesn't cite a specific commit / file / line / byte / test result that proves it.
- The proposed fix targets framework files, validators, or governance scaffolding (often the wrong altitude — the bug is usually in caller code, not in the called framework).
- The agent dismisses alternative diagnoses without empirical reason ("it's not X because it would look different" — without showing what X would actually look like).
- The diagnosis is presented as "definitive" after only documentation search or theoretical reasoning, with no observation step.
- The proposed fix is materially more complex than the failure mode warrants (entire library swap for a symptom that could be a one-parameter change).
- The agent loops on a single hypothesis class after the human pushes back, generating variants instead of broadening the hypothesis space.

When you see these signs, ask: *what specific empirical observation would distinguish this diagnosis from alternative diagnoses?* — then make that observation (or require the agent to make it) before approving the diagnosis OR any fix predicated on it. If the diagnosis cannot be falsified by any cheap observation, treat it as speculation, not diagnosis.

## Empirical Provenance

The rules in this document were not designed in the abstract. Each came from a specific Specrew dogfooding incident:

- **Shape 5** discovered during PlanningPoC iter-004 review (2026-05-27): Reviewer accepted work citing a commit hash; cited production files were never committed; user caught the bypass by accident via `git status`. Documented in [lifecycle-discipline.md](lifecycle-discipline.md) Shape Catalog.
- **Shape 6** discovered 2026-05-28: cross-project prompt-pasting incident; Crew has no topical-relevance check against bound project.
- **Shape 7** discovered F-049 iter-3 review (2026-05-28): single-reviewer Pillar 5 form check approved an iteration with 4 substantive gaps including a broken escape hatch; independent reviewer caught the gaps by reading code paths.
- **Shape 8** discovered during PlanningPoC iter-005 → iter-007 cycle (2026-05-27 → 2026-05-28): `bba6d53` lint-plus-sync-feature-closeout interaction injected stray state at TWO altitudes — a phantom verdict-history entry (session-state altitude) AND an orphan `closeout-dashboard.md` file (feature-state altitude). The repair commit caught the verdict-history entry only; the orphan dashboard survived three iterations until detected by `specrew start --host codex` stale-state detection on fresh host invocation. Same session: iter-007 production-code fix to `Save(stream, new DwgOptions())` was empirically validated, but two test-fixture files (`SyntheticDwgFixture.cs`, `UploadRunFlowTests.cs`) retained the original `Save(stream)` no-options pattern at the test-fixture altitude — caught only by the Reviewer's byte-level inspection of the synthetic fixture stream.
- **Agent-diagnosis hallucination chain** observed 2026-05-27 during PlanningPoC iter-006 review boundary: host agent produced three sequential confidently-stated root-cause diagnoses (UTF-8 Hebrew filename, CORS plus locked binary, library trial-mode corruption), all hallucinated, all leading to patches that didn't address the actual one-parameter-missing root cause. Motivates the "Verifying Agent Diagnoses" section above.
- **Commit-label-at-commit-time discipline gap** observed same session: agent committed four changes during a review boundary all labeled `boundary(implement)`. Baked false lifecycle history into git. Motivates the commit-label clause in [lifecycle-discipline.md](lifecycle-discipline.md) Boundary Discipline.
- **Schema-mismatch and broken-escape-hatch patterns** are the empirical core of Shape 7's spec coverage verification techniques.
- **Lifecycle artifact inconsistency** (plan.md says `planning`/`planned` while tasks-progress.yml says `completed`) is an artifact-drift class that surfaces when reviewers cross-check artifacts rather than trusting one source.
- **Boundary commit cadence violations** + **fabricated timestamps** are audit-trail-integrity defects observed in F-049 iter-3 implementation.
- **Commit subject hash-swap in handoff messages** is an administrative accuracy gap observed multiple times — always cross-check `git log` against the handoff.
- **Iteration-closeout audit-trail integrity** (F-049 iter-3 iteration-closeout cycle 2026-05-28): cross-reviewer (Codex) caught 3 audit-trail gaps that single-reviewer (Claude) had approved. Gaps were: (a) `review.md` line 7 still said "retro remains unopened pending fresh human authorization" while state.md/retro.md/now.md all said retro was complete (form-without-runtime-compliance variant at the artifact-text layer); (b) `state.md` cited the wrong commit (`b34de704` was the review-signoff state repair commit, not the retro-establishing commit `2eba2a91`) — **false lifecycle transition provenance** baked into git-readable history; (c) `.specrew/start-context.json` `last_authorized_boundary: retro` but `verdict_history` array was missing the `review-signoff → retro` approval entry — internally inconsistent metadata claiming authorization without supporting durable trail. All three gaps were metadata-only fixes; substantive code was correct. Empirical motivation for: (1) validator rule cross-checking `last_authorized_boundary` vs latest `verdict_history` entry; (2) reviewer charter discipline mandating cross-artifact text-consistency check; (3) **3rd documented empirical instance of cross-reviewer (Codex/Claude pairing) catching what single-reviewer missed in F-049** — promotes Proposal 102 + 140 priority further. Captured in memory `[[cross-reviewer-3rd-empirical-instance-2026-05-28]]`.

When a future incident reveals a new shape or pattern, this document should be updated. It exists to harden empirical lessons into reusable reviewer discipline.

## Cross-References

- [lifecycle-discipline.md](lifecycle-discipline.md) — shared methodology (boundary discipline, spec authority, traceability, drift, committed-tree durability, lifecycle metadata, spec coverage verification, release process, Shape Catalog)
- [proposal-discipline.md](proposal-discipline.md) — proposal management (create/update/validate proposals)
- [../../proposals/INDEX.md](../../proposals/INDEX.md) — proposal navigation index
- [../../proposals/102-cross-model-independent-reviewer.md](../../proposals/102-cross-model-independent-reviewer.md) — long-term automation for cross-reviewer pattern
- [../../proposals/120-handoff-block-validator-enforcement.md](../../proposals/120-handoff-block-validator-enforcement.md) — Pillar 5 absorbed Shape 5
