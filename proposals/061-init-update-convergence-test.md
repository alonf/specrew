---
proposal: 061
title: Init/Update Convergence Test (Frozen-Snapshot Replay)
status: candidate
phase: phase-2
estimated-sp: 13
discussion: tbd
---

# Init/Update Convergence Test (Frozen-Snapshot Replay)

## Why

Specrew offers two paths to reach the latest deployed state in a project: `specrew init` from scratch, and `specrew update` from an older version. **There is no test that these paths converge to the same end state.** They diverge in practice — and silently — until a user hits the gap.

**Empirical motivation — 2026-05-19 WSL trial cluster:**

The session surfaced *four* distinct cases where `specrew init` produces a different on-disk state than `specrew update` from an older version:

1. **`squad.agent.md` managed block** — fresh init at 0.22.0 produced `updated` with current managed-block content; update from 0.19.0 reported `preserved` because the source content was unchanged at the file level (only the *managed block within it* needed refresh, which `Set-ManagedBlock` should have done but the test reported "preserved" anyway). Reported as bug "I am trying the slash commands, but they are not there".

2. **`.copilot/skills/` skill set** — fresh init at 0.22.0 deploys ~19 skill directories (8 generic Squad + 11 specrew-*); update from 0.19.0 to 0.22.0 ended up with only the 11 specrew-* skills because the generic Squad skills are written by `squad init` (which `specrew update` doesn't re-run). Reported as "it is an update bug" by the maintainer.

3. **Path-target drift** (foreshadowed): the post-F-023 path-relocation chore (`.copilot/skills/` → `.github/skills/`) will likely produce additional init/update divergence unless the update path explicitly cleans up the old location.

4. **Schema marker propagation** (F-023 territory): without a convergence test, future schema markers may write at init but never retrofit on update.

A convergence test catches these by *construction*: if init produces state S₁ and update produces state S₂, the test asserts S₁ == S₂ (modulo intentional user-customization preserves), and fails CI on every divergence.

**Strategic value beyond bug-class prevention**: a convergence test is documented evidence to potential users that Specrew's update path is trustworthy. For a methodology product whose entire value depends on users running the lifecycle, "the update doesn't drift" is a load-bearing claim that should be mechanically verified.

## What

Three coupled components: **(A)** frozen init-snapshot corpus per shipped version, **(B)** update-loop replay runner, **(C)** diff classifier with documented preserve-rules.

### A. Frozen init-snapshot corpus

For every Specrew version that has shipped, capture the on-disk output of `specrew init` against a fresh empty project, normalized for cross-platform reproducibility:

```
tests/fixtures/init-snapshots/
  0.19.0/
    .copilot/...           # exact state at v0.19.0 init
    .specify/...
    .specrew/...
    .squad/...
    .github/...
  0.20.0/
    ...
  0.21.0/
    ...
  0.22.0/
    ...
  0.23.0/                  # current; produced by capturing fresh init at release time
    ...
```

Capture discipline (codified in the release process):

1. On every version-bump PR, the bumping change also captures a new init-snapshot under the new version's directory.
2. Capture is automated: `tools/capture-init-snapshot.ps1 -Version <N.N.N>` runs `specrew init` against a temp dir, normalizes (strip GUIDs, timestamps, machine-specific paths), and writes to the fixture corpus.
3. The corpus is git-tracked. Changes to it require explicit PR review.

### B. Update-loop replay runner

A test (`tests/integration/Test-InitUpdateConvergence.Tests.ps1`) that, for every shipped version V_old and the current version V_current:

1. Copy `tests/fixtures/init-snapshots/<V_old>/` to a temp directory
2. Run `specrew update` against the temp dir
3. Compare resulting state to `tests/fixtures/init-snapshots/<V_current>/`
4. Classify each diff per the rules in component C
5. Pass if all diffs are in the "allowed" classification; fail with a full report otherwise

Cross-platform: runs on Windows + Ubuntu + macOS lanes. Composes with [042](042-specrew-integration-test-suite.md).

### C. Diff classifier with documented preserve-rules

Not every file should be identical after update vs fresh-init. Some are intentionally user-customizable:

- `.squad/team.md` — users add custom team members; `specrew init` writes the baseline, `specrew update` should preserve the user's edits
- `.specrew/config.yml` — partially preserves (some fields user-set, some managed)
- `specs/*` — user lifecycle artifacts; never refreshed by update

The classifier codifies the rules:

| Classification | Behavior | Examples |
|---|---|---|
| **must-converge** | `specrew update` MUST produce byte-identical output to fresh init | All `extensions/specrew-speckit/scripts/*.ps1` deployed to `.specify/`; SKILL.md files; managed blocks in squad.agent.md; coordinator templates |
| **managed-block-converge** | The managed block within a file must match; surrounding text may differ (user edits outside the block) | `.github/agents/squad.agent.md` (Set-ManagedBlock content); `.squad/ceremonies.md` |
| **schema-converge** | Schema markers + structural fields must match; user-added fields tolerated | `.specrew/config.yml`; `.specify/feature.json` |
| **preserve** | Update MUST NOT modify; user-owned | `.squad/team.md` (after first init); `specs/*`; `.squad/decisions.md` |
| **absent-at-old** | File didn't exist at V_old; update must create it from V_current's template | New skills, new managed sections, new contracts |

Each classification rule lives in a manifest (`tests/fixtures/init-snapshots/convergence-rules.yml`) committed to git. Rules are referenced by glob pattern + classification. New patterns must be added in the same PR as the file's introduction.

### Reporting

On failure, the test emits a per-version, per-file diff report:

```
[FAIL] Update from 0.19.0 → 0.23.0 divergence

  File: .github/agents/squad.agent.md
  Classification: managed-block-converge
  Block: specrew-governance
  Diff:
    fresh-init contains Rule 22 (lines 132-148)
    updated     does not contain Rule 22
  Likely cause: Set-ManagedBlock not invoked on update path

  File: .copilot/skills/specrew-help/SKILL.md
  Classification: must-converge
  Status: missing in updated; present in fresh-init
  Likely cause: deploy-squad-runtime.ps1 update path skips this file

  ...

Summary: 7 must-converge failures, 1 managed-block-converge failure
```

Failures block CI merge. Each failure carries a remediation hint pointing to the relevant deployment script.

## Effort

- **Iteration 1 (~8 SP)**: snapshot capture tool + corpus for shipped versions (0.19.0 → current) + update-loop runner + diff classifier with v1 ruleset
- **Iteration 2 (~5 SP)**: CI integration (Windows + Linux + macOS lanes); release-process discipline (snapshot-on-version-bump); rules-manifest expansion for edge cases; convergence-failure remediation playbook in `docs/data-contracts.md`

**Total: ~13 SP across two iterations.**

## Phase placement

**Phase 2, Tier 1.** Sits *inside* the bug-prevention triad (059 → 060 → 042) as a fourth layer. Two reasonable sequencing options:

- **Option A (after F-024 / Proposal 060 prerelease channel, before F-025 / 042 Iter 1)**: prerelease channel landed gives convergence-test a natural firing surface (every prerelease tag triggers the convergence matrix). 042 Iter 1 then adds command-lifecycle E2E as a separate layer.
- **Option B (folded into 042 Iter 2 or Iter 3)**: convergence test is a *kind of* E2E test; could ride 042's CI infrastructure. Less proposal count growth, but conflates two distinct bug classes (command failures vs init/update drift).

**Recommended: Option A.** The init/update convergence bug class is distinct enough from command-failure bugs that it deserves its own proposal + tests, and the test infrastructure overlap with 042 is modest (mostly the CI matrix setup, which 060's prerelease workflow already provides).

Triad-with-061 revised sequencing:

1. F-023 = Proposal 059 (Legacy-State Read-Tolerance) — in progress
2. Post-F-023 chore: F-021 slash-command path fix (~3 SP, captured in memory)
3. F-024 = Proposal 060 (Prerelease Channel) — ~10 SP
4. **F-025 = Proposal 061 (Init/Update Convergence Test) — ~13 SP**
5. F-026 = Proposal 042 Iter 1 (Linux Command-Lifecycle E2E) — ~8-10 SP

Total bug-prevention layer cost: ~50 SP across 4 features. Justified by the 6-bug cluster from one WSL trial session.

## Open questions

1. **Snapshot normalization rules**: GUIDs in `.squad/casting/*.json`, ISO-8601 timestamps in `now.md`, machine-specific paths — all need normalization at capture time. What's the canonical normalizer? Recommend: dedicated `Normalize-InitSnapshot` function that runs at capture AND at compare time, applied symmetrically.
2. **Capture-on-tag automation**: should the snapshot be captured by the publish-module workflow (extends Proposal 060 scope) or by a separate manual step? Automation lower-effort over time; manual gives the maintainer review window. Recommend automation with maintainer-approval gate.
3. **Historical snapshot reconstruction**: 0.18.0 / 0.19.0 / 0.20.0 / 0.21.0 init-snapshots don't exist today. Reconstruct by running `specrew init` from those git tags against the current `init` source, or accept "first version covered is X" where X is the version this proposal ships under? Reconstruct is achievable but tedious; accepting "convergence test starts at version X" is pragmatic. Recommend pragmatic.
4. **User-customization rules**: who decides which files are `preserve` vs `must-converge`? The classification manifest needs a maintainer-blessed v1 list; subsequent additions go through normal PR review. Recommend: maintainer writes v1, contributors propose additions.
5. **Cross-platform reproducibility**: line endings, path separators, file ordering in archives — all platform-dependent. Normalize at capture *and* compare. May need a small abstraction layer (`Compare-NormalizedTree`).
6. **Cost vs frequency**: at 5 historical versions × 3 OS lanes × ~15 min per update-loop, ~225 minutes of CI per run. Acceptable on tag pushes / weekly cron; expensive on every commit. Recommend: triggered on tag, on `main` merges, and via manual workflow dispatch — not on every PR.
7. **Failure forensics**: when a convergence test fails, what's the lowest-effort path to find the root cause? Recommend: the failure report includes the deployment-script line that wrote the divergent file (or didn't write it), per `deploy-*.ps1` action-log integration.

## Risks

- **Snapshot drift**: a refactor that changes innocuous internal layout (e.g., `.squad/.first-run` filename) breaks every historical comparison until corpus is regenerated. Mitigation: classification rules treat path-aliases as equivalent; corpus regeneration is a documented quarterly maintenance step.
- **False sense of security**: passing convergence doesn't prove the *behavior* of the resulting state — it proves *file content* matches. A reader that crashes on the converged state still crashes. Mitigation: convergence is one layer; 042 Iter 1 command-lifecycle E2E and 059 reader-tolerance fixtures cover the behavior layer.
- **Test latency**: 225 minutes of CI per matrix run is non-trivial. Mitigation: parallelize per (V_old, OS) tuple; cache the unchanged init-snapshot fixtures across runs.
- **Rule manifest sprawl**: as Specrew evolves, the classification rules grow. Mitigation: classify by glob, not by individual file; review rule additions for over-specification.
- **Capture environment skew**: capturing init-snapshots on Windows produces different file content than capturing on Linux (path separators in some files, line endings). Mitigation: capture on a canonical CI environment (Ubuntu) and normalize aggressively; document the choice.

## Cross-references

- Composes with [042](042-specrew-integration-test-suite.md) (Integration Test Suite) — shares CI infrastructure but tests a distinct bug class (init/update drift vs command-lifecycle failures).
- Composes with [059](059-legacy-state-read-tolerance.md) (Legacy-State Read-Tolerance) — sibling discipline; 059 tests *readers* against legacy state, this tests *writers* (init/update) for convergence to canonical state. Both use the `tests/fixtures/` infrastructure.
- Composes with [060](060-prerelease-channel-staging.md) (PSGallery Prerelease Channel) — prerelease tags are the natural firing surface for this test.
- Composes with [054](054-pre-merge-lifecycle-verification-gate.md) (Pre-Merge Lifecycle Verification Gate) — both bug-class-prevention; lifecycle gate validates command flow, convergence test validates state drift.
- Builds on [031](031-specrew-distribution-module.md) / F-019 (Specrew Distribution Module) — uses the bundled-templates path established by F-019's deployment work.
- Sibling of post-F-023 chore (slash-command path fix, in memory): the chore moves `.copilot/skills/` → `.github/skills/`; this test would detect any incomplete migration on the update path.

## Status history

- 2026-05-19: candidate captured during F-023 human-review session, motivated by four empirical init/update divergence cases from the WSL trial (`squad.agent.md` managed-block, `.copilot/skills/` skill-set, foreshadowed path-relocation drift, schema-marker propagation). Maintainer surfaced the gap directly: "We need to think about an Update test... keep a copy of specrew files after init as a frozen set and in CI/CD do a loop of updates."
