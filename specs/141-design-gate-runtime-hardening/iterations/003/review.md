# Review: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted

## Summary

Iteration 003 of feature 141-design-gate-runtime-hardening delivered the greenfield/downstream
hygiene bundle — FR-012 (suppress the spurious multi-developer warning a single-dev bootstrap
triggered) and FR-013 (fresh-greenfield baseline-commit handling). Reproduce-first established that
FR-012 was a genuine false positive and that FR-013's baseline logic is already correct once a commit
exists, so FR-013 resolved to **verify-clean + a conservative guidance nudge (C+nudge)** per the
maintainer decision — no auto-commit. All five tasks (T001-T005) are `done`, `origin/main` (0.31.0
stable + Feature 140) is merged cleanly, the governance validator reports **all 4 iterations PASS**
(incl. 141/003), and the targeted suites are green. Verdict: **accepted** for review-signoff.

Reviewed against the maintainer-requested Proposal 145 dimensions (state truth, branch hygiene,
functional correctness, test integrity, evidence integrity) plus a dirty/stash classification.

## Review Dimensions (Proposal 145 framing)

### State truth

- The iteration ledger is internally consistent and reconciled: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/003/state.md (Last Completed Task `T005`; Tasks Remaining none; In Progress none), file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/003/tasks-progress.yml (T001-T005 all `done`), and the file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/003/plan.md Status column (T001-T005 `done`) all agree. plan.md carries a **Task Ledger Authority** note naming `tasks-progress.yml` authoritative and recording the prove-first reframe (the original T003/T002 task descriptions are superseded by the as-built outcome).
- `Current Phase` was **intentionally held** at `before-implement` / `Iteration Status: executing` until this review.md existed — claiming `review-signoff` without review.md FAILs the required-artifact check (the iteration-002 lesson).
- `boundary_enforcement.verdict_history` carries the `tasks -> before-implement` authorization recorded at the start of implementation; the `before-implement -> review-signoff` authorization is recorded with this review.

### Branch hygiene

- Branch `141-design-gate-runtime-hardening`. Iteration-003 commit range: **`592b21c0..4c8c0f67`** (8 commits: T001 reproduce/classify, T002 FR-012, T003 prove-first + C+nudge, T003/T004 guidance+SC-009, T005 gap ledger, SC-009 promotion, the origin/main merge, the send-back reconciliation).
- **`origin/main` merged cleanly at `8609760c`** (0.31.0 stable + Feature 140 Unix-native install, 59 commits) via the `ort` strategy with **no conflicts**. 140's surfaces (`bin/`, `scripts/specrew.ps1`, `install.sh`, design-lenses) are disjoint from the 141 files, so nothing collided; the FR-012/FR-013 changes survived intact and were re-verified green post-merge.
- **HEAD `4c8c0f67`**. **No push / no PR** while the feature remains in progress.
- Each commit is a focused, boundary-disciplined slice; no unrelated refactors landed on the 141 files.

### Functional correctness

- **FR-012 (spurious multi-developer warning):** in file:///C:/Dev/Specrew-design-analysis/scripts/auto-detection.ps1, close-together shared-state writes (`$writeSignals`) **no longer trigger the multi-developer recommendation on their own** — they only corroborate a genuine distinct-actor signal (>=2 git authors, >=2 active-session machines, or >=3 numbered-branch fanout). A single-developer fresh greenfield (whose bootstrap writes `start-context.json` + `last-start-prompt.md` + `decisions.md` within ~1s) no longer surfaces "Multiple developers detected"; **genuine multi-developer activity still surfaces** (verified: a 2-author repo still produces the recommendation, with the write count shown as corroborating detail).
- **FR-013 (fresh-greenfield baseline, C+nudge):** prove-first showed the baseline already resolves to a real HEAD and refreshes consistently once a commit exists (the Feature-029 contract). The **zero-commit fail-safe is preserved** — file:///C:/Dev/Specrew-design-analysis/scripts/specrew-start.ps1 does **not** stamp a baseline and creates **no commit** on the user's behalf when no HEAD resolves; instead it emits a **guidance nudge** to make an initial commit. Once a commit exists, the boundary-refresh path resolves `baseline_commit_hash == HEAD` and stays consistent with what the reader returns. Auto-committing was explicitly declined (it would contradict the tested Feature-029 contract).
- The US6-AC1-vs-Feature-029 tension is recorded as **resolved-by-clarification** (drift-log + gap ledger), not an auto-commit behavior change.

### Test integrity

- Reproduce-first was followed: the FR-012 false positive FAILED on pre-fix code (single-dev bootstrap set `has_multi_developer_signal=true`) and passes after; FR-013 prove-first proved the baseline resolves once a commit exists before any change.
- Exact local results (all `exit=0`, re-run post-merge):
  - **SC-008** — file:///C:/Dev/Specrew-design-analysis/tests/unit/feature-051-iteration2b.tests.ps1: **21 pass / 0 fail** (single-dev bootstrap → no signal/recommendation; 2-author repo → recommendation still fires with write-signal corroboration).
  - **SC-009** — file:///C:/Dev/Specrew-design-analysis/tests/integration/design-gate-runtime-hardening-greenfield-baseline.tests.ps1: **6 pass / 0 fail** (zero-commit → guidance + no stamp + no commit created; post-commit → resolves to HEAD + consistent).
  - feature-141 unit — file:///C:/Dev/Specrew-design-analysis/tests/unit/design-gate-runtime-hardening.tests.ps1: **17 pass / 0 fail** (no regression from the FR-013 `specrew-start.ps1` change).
  - iteration-2 FR-011/FR-014 — file:///C:/Dev/Specrew-design-analysis/tests/integration/multi-host-launch-path.tests.ps1: **24 pass / 0 fail** (no regression). Note: its fixtures are committed, so it does NOT exercise the new no-commit branch — the committed SC-009 carries that coverage.
- **Validator:** `validate-governance.ps1 -NoCacheRead` → **all 4 scoped iterations PASS** (incl. 141/003), re-run post-merge + post-reconciliation, exit 0.

### Evidence integrity

- **No CI evidence is claimed for the co-located baseline-hygiene SC-009.** The full file:///C:/Dev/Specrew-design-analysis/tests/integration/baseline-hygiene.tests.ps1 suite halts locally at its PRE-EXISTING repeated-tasks idempotency sub-check (installed-module F-033 markdownlint gate) — confirmed pre-existing by stashing the iteration-003 changes and re-running at HEAD (identical halt). Its CI execution is **not** verified here and is not relied on as evidence.
- **Primary SC-009 evidence is the locally-green** file:///C:/Dev/Specrew-design-analysis/tests/integration/design-gate-runtime-hardening-greenfield-baseline.tests.ps1 (6/0, watched pass against repo code) — it dot-sources the same repo functions the boundary sync uses and invokes the repo `specrew-start.ps1` directly.
- Runtime-vs-form: FR-012 verified by calling `Get-SpecrewMultiDeveloperSignals` against a real fresh greenfield (`has_multi_developer_signal=False`); FR-013 verified by running the real `specrew start` (guidance emitted, no stamp) + the real boundary-refresh functions. Not file-presence checks.
- No new dependencies (pure PowerShell) — see file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/003/dependency-report.md. Full TG-006 gap ledger in file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/003/coverage-evidence.md.

### Dirty / stash classification

- **`stash@{0}` is NOT part of Feature 141** and is **not restored into this branch.** It holds pre-existing non-141 working-tree changes (CI workflows *reverted* to node 20 + 138-line deletion that main has, a `.gitignore` session-rule addition, an `iteration-config.yml` agent-state flip, and `.squad/*` runtime churn). The merge took main's authoritative versions; the stash stays **parked** — to be dropped only after asking Alon separately (the `.gitignore` session-rules may be worth re-adding on their own).
- All remaining untracked files are **runtime/session artifacts only**: `.specrew/active-sessions.yml`, `.specrew/last-validator-summary.json`, `.specrew/version-check-cache.json`, `.specrew/lenses/`, `.specrew/presets/`, `.specify/feature.json`, `.cursor/`, and other features' scaffolded ledgers (`specs/140-design-analysis-gate/iterations/001/tasks-progress.yml`). None were committed.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-012, FR-013, FR-015 | pass | Reproduced + classified both defects in drift-log before any fix; suspected self-host-only classes excluded. |
| T002 | FR-012 | pass | `$writeSignals` corroborates-only; single-dev bootstrap no longer triggers; genuine multi-dev preserved. |
| T003 | FR-013 | pass | Prove-first verify-clean + C+nudge: zero-commit fail-safe preserved, no auto-commit, guidance nudge added. |
| T004 | SC-008, SC-009 | pass | Reproduce-first tests folded into T002/T003; SC-009 promoted to a committed locally-green suite. |
| T005 | TG-006 | pass | quickstart Iteration-3 section + TG-006 gap ledger (implemented/enforced/observable/documented). |

## Gap Ledger

- No requirement (FR/SC) gaps: FR-012, FR-013, SC-008, SC-009, TG-006 all verified.

## Follow-ups (not iteration-003 requirement gaps)

- **FR-012 self-host-only signals** (version-mismatch-vs-`0.0.0` placeholder; author/branch-fanout) fire only under Specrew SOURCE/dev-repo conditions, not a fresh greenfield/downstream. Not reproduced as leaks → follow-ups, not changed here.
- **`recorded_at` datetime coercion** — deferred follow-up (FR-013 is `Write-Warning`-only and does not touch that serialization path, so the deferral holds).
- **stash@{0} disposition** — park; ask Alon before dropping; the `.gitignore` session-rules may warrant a separate re-add.

## Notes

- Reproduction/classification + the prove-first discriminator are recorded in file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/003/drift-log.md.
- Reviewer artifacts: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/003/reviewer-index.md, code-map.md, coverage-evidence.md, dependency-report.md, review-diagrams.md, dashboard.md.
