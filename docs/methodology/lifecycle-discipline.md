# Specrew Lifecycle Discipline

This document is the shared methodology contract for everyone working on Specrew — implementers and reviewers both. It defines the lifecycle boundaries, traceability expectations, release process discipline, and the empirically-observed failure patterns (Form-Without-Runtime-Compliance Shape Catalog) that govern Specrew development.

If you are reviewing work, read this document alongside [review-instructions.md](review-instructions.md). If you are implementing work, this is the contract you must honor.

## Purpose

Specrew is a governed agentic SDLC layer over GitHub Spec Kit. It keeps a human in control at explicit lifecycle boundaries while AI agents do the implementation work between those boundaries. Specrew can run through multiple AI hosts, including Codex, Claude Code, GitHub Copilot CLI, and Antigravity, but the durable source of truth is the repository artifact trail, not any one host's memory.

This repository is dogfooding Specrew: Specrew is being built using Specrew. That means every change is not only a normal code change. It is also a methodology exercise. Implementers and reviewers must verify that the feature obeys Specrew's own lifecycle, traceability, audit, and boundary rules.

## Boundary Discipline

Specrew has explicit lifecycle boundaries:

`specify -> clarify -> before-plan -> plan -> tasks -> before-implement -> implement -> review-signoff -> retro -> iteration-closeout -> feature-closeout`

`before-plan` and `before-implement` are Specrew-added readiness gates that hook into Spec Kit's extension points. They are mandatory but lightweight; their job is to verify the prior boundary's output is durable + the next boundary can start.

After `feature-closeout`, the post-merge release SDLC runs Steps 5-14: push → PR → review → merge → tag `-beta1` → publish prerelease → manual install validation (PAUSE here for human) → tag stable → publish stable → stop. This is mandated for every feature touching runtime artifacts, even small fixes; see Proposal 060 (universal beta-before-stable mandate). Detailed Release Process Discipline section below.

One human authorization advances at most one boundary unless the human explicitly gives a valid compound verdict. Agent prose cannot simulate approval.

Reviewers check for:

- Claimed boundary state matching actual artifacts.
- No implementation before plan/tasks approval.
- No review-signoff claim before review evidence is complete.
- No iteration-closeout claim without `retro.md`, `dashboard.md`, and lifecycle sync artifacts.
- No feature-closeout claim without the feature closeout dashboard and roadmap/state updates.

**Commit-label discipline at commit time**: every commit during a boundary's life must declare the ACTIVE boundary in the commit message (`boundary(review)`, `boundary(implement)`, `boundary(closeout)`, etc.). A commit labeled with the wrong boundary is lifecycle-state-lying in commit metadata — auditors looking at `git log --oneline` weeks later will misread the iteration's history. The active-boundary label is the boundary the iteration is currently IN at commit time, not the boundary the commit's author wishes were active. Empirical incident: an agent committed 4 changes during a review boundary all labeled `boundary(implement)`, baking false history into git. Reviewer technique: `git log --oneline <iteration-start>..HEAD` and verify each commit's `boundary(<X>)` prefix matches the boundary the iteration was actually in at that commit timestamp.

## Spec Authority

The spec is the contract. If implementation and spec disagree, the implementation is wrong unless there is a recorded human-approved spec amendment.

Review for:

- Field names, schema shapes, command names, output formats, and file paths matching the spec exactly.
- Optional fields remaining optional and required fields being present.
- Edge cases explicitly named in the spec being exercised in production paths.
- No silent substitution of a weaker behavior for a required behavior.

## Traceability

Every task should have a clear path back to requirements. Every in-scope requirement should be covered by tasks and evidence.

Review for:

- Task rows in `plan.md` with FR/SC links.
- `tasks-progress.yml` matching the plan task IDs.
- Evidence rows covering all measurable success criteria.
- Tests named or structured so a future reviewer can connect them to requirements.

## Drift

Drift is any mismatch between spec, plan, tasks, implementation, tests, or evidence.

Review for:

- Implementation that satisfies tests but not the spec.
- Evidence that claims success for a requirement it does not actually measure.
- Plan status saying `planning` while task progress says all tasks are complete.
- Files generated in one host surface but not mirrored to required host surfaces.
- Decisions described in prose but missing from `.squad/decisions.md`.

## Committed-Tree Durability

A green local run is not enough. Specrew review must verify that the evidence exists in the committed tree at the reviewed commit.

**Multi-altitude verification**: when reviewing a fix that addressed a specific defect, verify the fix at EVERY altitude where the defect could have produced state. A single defect can produce artifacts at session-state, lifecycle-metadata, production-code, test-fixture, feature-level-dashboard, and framework-deployment altitudes. A repair that addresses one altitude may silently leave related artifacts unfixed at other altitudes. See Shape 8 in the Shape Catalog for the empirical pattern. Practical technique: when the diff shows a one-line fix (e.g., `Save(stream)` → `Save(stream, new DwgOptions())`), grep the entire repo for the same pattern at adjacent altitudes (test fixtures, helper scripts, demo code) before approving. When the diff shows a state-metadata repair (e.g., `verdict_history` entry removed), enumerate other state-files the same automation could have written to (dashboards, summaries, host-history caches).

Review for:

- Tests and quality evidence committed at HEAD.
- No references to missing files.
- No reliance on generated artifacts that were not committed when the lifecycle requires durable evidence.
- Handoff claims that match `git log`, not just the agent's summary.
- For repair-class commits, multi-altitude verification applied — fix confirmed at every altitude where the defect could have produced state, not just the most-visible altitude.

## Lifecycle Metadata Integrity

Lifecycle metadata is part of the product when dogfooding Specrew.

Review for:

- Plausible `started_at`, `completed_at`, and `updated_at` values.
- No copied placeholder dates.
- `plan.md` status consistent with current lifecycle phase.
- Per-task statuses in `plan.md` consistent with `tasks-progress.yml`.
- `Completed` populated only when the lifecycle phase actually warrants it.
- Closeout artifacts present only when closeout actually happened.

## Spec Coverage Verification (Tests Pass ≠ Spec Delivered)

Tests passing does not prove coverage of the spec. This is the most consequential review gap in Specrew dogfooding so far — see the Form-Without-Runtime-Compliance Shape Catalog below for the empirical pattern (Shape 7).

A reviewer who only runs the tests and checks they pass will MISS gaps that an independent reviewer reading the code paths will catch. **The mode of verification matters**: running tests proves the implemented contract works; reading code proves the contract matches the spec. You need both.

Specific verification techniques (apply on every iteration that lands new behavior):

- **Schema diff**: open the spec's schema definition and the implementation's actual write. Compare field names character-for-character. Renamed fields, missing required fields, and changed nesting are all common implementation drift.
- **Type-contract trace**: for every parameter the spec allows multiple types for (e.g., `"1-10 or 'auto'"`), trace the value from the entry point (user input or persistence layer) through every function call to the final consumer. PowerShell `[ValidateRange()]` + `[int]` on a parameter that the spec says accepts `"auto"` will crash at runtime; tests with hardcoded integer overrides won't catch it.
- **Escape-hatch end-to-end check**: if the spec lists an escape hatch (`"Other"`, `"I don't know"`, `"auto"`, `--force`, default fallback), find or run a test that exercises it through the production entry point — not just a helper unit test. If no such test exists, that escape hatch is unverified.
- **SC-clause-by-clause evidence audit**: for every success criterion with multiple measurable clauses (e.g., SC-005's three metrics), confirm `quality-evidence.md` has an explicit measurement row for each clause. Partial evidence is a blocker, not a minor.
- **Production-path-vs-test-path comparison**: locate the production orchestrator (the thing the user invokes, e.g., `Invoke-SpecifyIntake.ps1`) and trace what arguments it passes to helpers. Compare to what arguments the tests pass to the same helpers. If they differ, tests don't cover production paths.

Review for:

- Tests exercising real command/orchestrator paths, not only helper functions.
- Edge cases from the spec, especially explicit escape hatches and fallback behavior.
- Negative tests for unsupported or malformed input where required.
- Tests that fail for the right reason if the required behavior is removed.
- Evidence for every clause of a multi-part success criterion.
- Implementation field names match spec field names character-for-character.
- Every escape hatch from the spec exercised through the production entry point.

## Release Process Discipline (Repository, CI, PSGallery, Beta-vs-Stable)

Specrew ships as a published PowerShell module. The lifecycle does NOT end at feature-closeout — the post-merge SDLC (Steps 5-14, codified in F-048) carries the work through PR review, CI gates, beta release, manual install validation, and finally stable promotion. Reviewers of feature-closeout boundaries + downstream boundaries (PR, beta publish, stable promote) must verify each step.

Iteration-level review can skip this entire section. Full-feature review and post-merge release review must work through it.

### Repository Conventions

> **Forge-neutrality note (FR-019 / SC-013).** The conventions and the Post-Merge SDLC in this section
> are **Specrew's OWN** repository setup — provider `github` + the PowerShell Gallery — shown as a
> concrete **example**, NOT a downstream mandate. A project governed by Specrew substitutes its own
> forge, branch model, `review_gate`, and release/publish mechanism per its
> `.specrew/repository-governance.yml`; the GitHub-specific commands below (`gh pr create`,
> `Find-Module`/`Install-Module Specrew`, PSGallery `workflow_dispatch`) are Specrew-specific and apply
> only when a project's provider/workflow instantiates that path.

- **Repository**: <https://github.com/alonf/specrew>
- **Default branch**: `main`
- **Feature branches**: named `<NNN>-<feature-slug>` (e.g., `049-pipeline-hardening-intake`); branched from `main`; one feature per branch.
- **Merge strategy**: **merge-commit only** (NOT squash). The merge commit preserves the lifecycle's boundary-by-boundary atomic commit cadence which validators + audit trail depend on. A squash would collapse the boundary commits into one and destroy lifecycle traceability.
- **Proposals and documentation**: `main` is protected — it requires pull requests (see [Proposal 182](../../proposals/182-work-kind-branch-governance.md)), so proposal and docs changes land through a PR-backed **docs-only** work item (a short-lived `docs/...` or `chore/proposals-...` branch → PR → merge), never a direct push to `main`. They must still never be mixed into a software-feature branch (empirical incident: F-020 closeout PR stray-disposition when proposals landed on a feature branch). Until Proposal 182 formalizes the work-kind / branch-governance model, treat proposal and documentation edits as docs-only PRs.
- **Local lint before push**: run `npx markdownlint-cli` on touched markdown + the scoped governance validator. Push-to-main lint failure cascades to skip the Deterministic + Contract lanes (silent truth-check disable), so catching lint locally matters.
- **Worktree pattern**: when working on main while a feature branch is checked out, use `git worktree add` for an isolated copy. Don't disturb the feature-branch working tree.

### Post-Merge SDLC — Specrew's own example (F-048 Steps 5-14)

The sequence below is **Specrew's own** post-merge SDLC (provider `github` + PowerShell Gallery), an
example of the closeout shape — not a downstream mandate. For Specrew itself every feature touching
runtime artifacts follows it (universal mandate per Proposal 060); a downstream project runs the same
*shape* via its own forge + release mechanism per its `.specrew/repository-governance.yml`:

| Step | Owner | Action |
|---|---|---|
| 5 | Agent | Push feature branch to origin |
| 6 | Agent | Create PR via `gh pr create` with proper title + body |
| 7 | Human + Agent | Read Copilot's automated PR review (`gh pr view <#> --json reviews && gh api repos/<owner>/<repo>/pulls/<#>/comments`); address every finding before merge |
| 8 | Human | Approve merge (merge-commit strategy; not squash) |
| 9 | Agent | Tag `v<X.Y.Z>-beta1` on the merge commit (`-beta2`, … on a FAIL loop) |
| 10 | Agent | Publish prerelease to PSGallery via `workflow_dispatch` |
| 11 | **Human PAUSE** | Manual install validation: `Install-Module Specrew -AllowPrerelease` on a clean machine; exercise the new feature end-to-end; verify no regression; verify FileList complete; verify mirror parity intact post-install |
| 12 | Agent | If validation PASSED: tag `v<X.Y.Z>` (stable) at the SAME commit as the beta tag |
| 13 | Agent | Promote to PSGallery stable channel via `workflow_dispatch promote-prerelease` |
| 14 | Agent | Stop |

Step 11 is the most consequential PAUSE — it has caught real bugs during dogfooding (e.g., FileList omissions broke v0.27.3 install on Mac; v0.27.4-beta.1 caught a `docs/release-discipline.md` omission between beta.1 → beta.2). NEVER skip step 11, even for trivial fixes.

If step 11 FAILS: fix the issue, bump to the next beta (`-beta2`, then `-beta3`, …), re-validate, repeat until PASS, then promote stable. The stable promotion must come from a beta that PASSED — never directly from main without going through beta.

### CI Lanes

PR-CI runs multiple lanes; reviewers must verify all are green before merge:

| Lane | Checks |
|---|---|
| **Lint** | `markdownlint` on markdown + `PSScriptAnalyzer` on PowerShell touched files |
| **Validator** | `validate-governance.ps1` on the feature's spec/plan/tasks artifacts; FR/SC coverage; mirror parity; capacity arithmetic |
| **Deterministic** | Verifies cross-platform reproducibility — output should be identical across Windows/Linux runs |
| **Contract** | Verifies extension contracts (Spec Kit hooks via `.specify/extensions.yml`; Squad coordinator definitions; slash-command machinery) |
| **Test matrix** | Pester integration tests across Windows + Linux + macOS |
| **Docker pre-publish harness** (F-049 iter-1) | Runs against the packaged module candidate to catch FileList omissions BEFORE PSGallery upload. Blocks publish if any FileList entry is missing on install. |

Push-to-main also runs Lint + Validator + a nightly truth-check. If Push-to-main Lint fails (e.g., a proposals commit with lint violations), the Deterministic + Contract lanes are SKIPPED silently — a real "truth-check disabled by lint failure" incident has happened. Always lint locally before pushing to main.

### PSGallery Publishing

Specrew publishes to <https://www.powershellgallery.com/packages/Specrew> as the `Specrew` PowerShell module. Users install via `Install-Module Specrew` (stable) or `Install-Module Specrew -AllowPrerelease` (beta).

Before any beta or stable publish, reviewers must verify:

- **Manifest version pin consistency** — these 5 surfaces must all declare the same version:
  - `Specrew.psd1` `ModuleVersion`
  - `.specrew/config.yml` `specrew_version`
  - `extensions/specrew-speckit/extension.yml` `version`
  - `.specify/extensions/specrew-speckit/extension.yml` `version` (Spec-Kit-side mirror)
  - `README.md` version references
- **`Specrew.psd1 FileList` completeness** — every new file added during the feature MUST be listed in `FileList`. Missing files break install on Mac/Linux (only files in FileList are extracted from the .nupkg). Recurring bug class — v0.25.0 broke `hooks/`, v0.27.3 broke `docs/`, v0.27.4-beta.1 broke `docs/release-discipline.md` (caught only because of beta-validation step).
- **Mirror parity** — `extensions/specrew-speckit/scripts/*` byte-identical with `.specify/extensions/specrew-speckit/scripts/*` per F-047 FR-014.
- **Pin drift detection** — Specrew's own `Get-SpecrewVersionInfo` cmdlet (or `specrew update --info`) must report consistent versions across all 5 manifest surfaces. Drift here is a silent bug class.
- **`specrew update` deploys cleanly** — recurring bug class: `specrew update` has appended duplicate role rows + failed to bump downstream project's `specrew_version`. Test on a sample downstream project before stable promotion.

### Beta-Before-Stable Universal Mandate (Proposal 060)

Every release ships `-beta1` first, manually validated, then promoted to stable. NO exceptions, including:

- Hot fixes
- Production-fire emergencies
- Trivial documentation changes that touch runtime artifacts
- Validator-only releases
- Test-only releases that don't change code paths

Proposal-only changes (no runtime artifacts) are exempt — they don't trigger the release pipeline. They still land as a docs-only PR against protected `main` (see [Proposal 182](../../proposals/182-work-kind-branch-governance.md)), not a direct push.

Reviewers approving stable promotion must verify:

- A corresponding `-beta<N>` tag exists at the same merge commit
- PSGallery shows the prerelease version published successfully
- Maintainer recorded manual install validation PASS (in `.squad/decisions.md` or commit message of the stable tag)
- NO new commits between beta tag and stable tag (otherwise the validated artifact is different from what gets promoted; this is a real risk class)

Standard release cycle: `v<X.Y.Z>-beta1` → manual validation → if PASS: `v<X.Y.Z>` stable; if FAIL: fix + `-beta2` → re-validate → eventually stable.

### Reviewer Checklist by Boundary

**Iteration-level review (review-signoff, retro, iteration-closeout)**:

- All lifecycle artifacts present + internally consistent (see Lifecycle Metadata Integrity above)
- Spec coverage verified (see Spec Coverage Verification + Shape 7 in catalog)
- No release-process concerns yet (iteration is intra-feature)

**Feature-closeout review (before push to origin)**:

- All iterations within the feature are closed (each has `retro.md`, `dashboard.md`, complete `tasks-progress.yml`)
- `closeout-dashboard.md` present at feature level
- `.squad/decisions.md` has feature-closeout boundary entry citing the closeout commit hash
- Manifest version pins applied to all 5 surfaces (consistent across `Specrew.psd1`, `.specrew/config.yml`, both `extension.yml` mirrors, `README.md`)
- `Specrew.psd1 FileList` updated to include every new file the feature created
- Mirror parity intact between `extensions/specrew-speckit/scripts/*` and `.specify/extensions/specrew-speckit/scripts/*`
- README updated if any user-facing behavior changed

**PR review (Step 7, between push and merge)**:

- PR title concise (< 70 chars); body covers feature scope + test plan
- All CI lanes green (Lint, Validator, Deterministic, Contract, Test matrix, Docker pre-publish harness)
- Copilot's automated PR review surfaced + every finding addressed (`gh pr view <#> --json reviews && gh api repos/<owner>/<repo>/pulls/<#>/comments`)
- No surprise file changes outside the feature's planned scope
- Merge strategy = merge-commit (NOT squash) — verify the merge button is set correctly

**Beta publish review (Steps 9-10, after merge)**:

- `v<X.Y.Z>-beta<N>` tag created on the merge commit (not on a feature-branch commit)
- PSGallery prerelease published successfully — check <https://www.powershellgallery.com/packages/Specrew>
- Module installable via `Install-Module Specrew -AllowPrerelease`

**Manual install validation (Step 11 PAUSE — the most consequential review)**:

- Fresh `Install-Module Specrew -AllowPrerelease` on a clean machine succeeds without errors
- New feature exercised end-to-end through real entry points (not test fixtures)
- No regression in existing features (smoke-test prior critical paths)
- FileList completeness verified — every file the feature added is present on the installed module path
- Mirror parity intact post-install — `Specrew.psd1` paths match `.specify/extensions/` paths byte-for-byte
- Decision recorded in `.squad/decisions.md` or commit message: PASS or FAIL with concrete reasons
- If FAIL: do not promote stable; fix + bump beta + re-validate

**Stable promotion review (Steps 12-14)**:

- Manual validation PASS explicitly recorded
- `v<X.Y.Z>` stable tag created at the SAME commit as the validated `-beta<N>` tag
- NO commits exist between the beta tag and the stable tag (if there are, the stable promotion is invalid — the validated artifact is different from what's being promoted)
- PSGallery stable promoted successfully via `workflow_dispatch promote-prerelease`
- Module installable via default `Install-Module Specrew` (stable channel)
- Update Specrew's own `.specrew/config.yml specrew_version` if needed (downstream-project version bump is a separate concern but often slips here)

## The Form-Without-Runtime-Compliance Shape Catalog

Empirical patterns observed during Specrew dogfooding where an artifact LOOKS correct in form but FAILS to deliver substance. Use as a checklist during review. Implementers should also know these patterns — they describe failure modes to avoid.

| Shape | Pattern | Detection method |
|---|---|---|
| **Shape 1: Trigger-bypass** | Non-Specrew session writes artifacts that look like normal lifecycle outputs but skipped the trigger hooks. Boundary-state metadata is missing or incomplete. | Validator: check for trigger-driven artifacts (`dashboard.md`, sync state files) at expected closeouts. |
| **Shape 2: Wrong-location** | Canonical artifacts written into ephemeral host session-scratch locations (e.g., `~/.copilot/session-state/<id>/files/...`) instead of `specs/<feature>/...`. | Validator: scan host session-scratch paths for files matching Specrew artifact patterns. |
| **Shape 3: Handoff-block-dropped** | Boundary stop happens without the agent emitting the `=== SPECREW HANDOFF ===` block. Next session has no structured pickup point. | Validator: at boundary commits, verify handoff block was emitted; reviewer charter: cite handoff block presence in `review.md`. |
| **Shape 4: State-advance-without-verdict** | Boundary state advances in recorded artifacts (`boundary-state.json`, `.squad/identity/now.md`) without matching human verdict history. | Validator: cross-check verdict history against state advances. |
| **Shape 5: Reviewer-approves-working-tree-only-state** | Reviewer accepts work + cites committed-hash provenance, but cited production files are not in the committed tree (only working tree). Code can vanish via `git reset` / fresh clone. | `git ls-tree -r <cited-hash>` against every file cited as evidence. Absorbed into Proposal 120 as Pillar 5. |
| **Shape 6: Missing prompt-relevance check** | Crew acts on user prompt that's topically unrelated to the bound project (cross-project bleed); no defense against multi-shell wrong-paste mistakes. | Reviewer charter: confirm coordinator surfaces project context + topical-relevance check; validator: detect commits outside active project root. |
| **Shape 7: Tests pass but don't cover spec** | Files committed AND tests pass (Pillar 5 form satisfied), but tests don't exercise spec-required paths. Production users hitting unexercised paths get runtime failures. | Read code paths + trace type contracts; compare implementation field names + types against spec; confirm every escape hatch is exercised through production entry point (not just helper unit tests). |
| **Shape 8: Multi-altitude defect with single-altitude repair** | A defect produces state at multiple altitudes (e.g., session-state + feature-level dashboard; or production code + test fixtures using the same pattern; or verdict history + adjacent automation artifacts). The repair correctly addresses one altitude but misses the others. Approval looks safe because the most-visible altitude is clean; the unfixed altitudes silently retain the bug pattern until a downstream check or fresh-start detector catches them. | When reviewing a fix, enumerate ALL altitudes where the defect could have produced state, then verify each independently. Specifically: if production code was fixed with a one-line change (`Save(stream)` → `Save(stream, options)`), grep the entire repo for the same pattern at adjacent altitudes (test fixtures, helper scripts, demo code). If lifecycle metadata was repaired (verdict_history entry removed), enumerate other state files the same automation could have written. |

Each shape has been observed empirically during F-049 / PlanningPoC / WSL trial / Gym test dogfooding cycles. When reviewing, ask: "is any of these 8 shapes present here?" When implementing, ask: "is my work avoiding all 8 shapes?"

## Cross-References

- [review-instructions.md](review-instructions.md) — reviewer-specific guidance (review method, verdict format, approval/rejection criteria, severity guidance, mindset)
- [proposal-discipline.md](proposal-discipline.md) — proposal management discipline (create/update/validate proposals)
- [../../proposals/INDEX.md](../../proposals/INDEX.md) — proposal navigation index
- [../../proposals/060-prerelease-channel-staging.md](../../proposals/060-prerelease-channel-staging.md) — universal beta-before-stable mandate
- [../../proposals/120-handoff-block-validator-enforcement.md](../../proposals/120-handoff-block-validator-enforcement.md) — Pillar 5 absorbed Shape 5
- [../../proposals/055-always-in-flow-bug-fix-lifecycle.md](../../proposals/055-always-in-flow-bug-fix-lifecycle.md) — slice-type catalog
