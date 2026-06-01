# Proposal 145 Structured Review — Spec Kit 0.9.0 Spike Closeout

**Feature**: 090-speckit-090-compatibility · **Branch**: `spike-speckit-090` · **Spike commit**: `662a6512` (amended in this closeout) · **Date**: 2026-06-02
**Reviewer**: Specrew Crew coordinator (claude host) applying the Proposal 145 7-phase structured review.
**Scope reviewed**: the single spike commit (max_tested bump + format-aware `Ensure-ExtensionRegistration` + tests + report/evidence) and the working-tree state before push/PR.

## Per-phase synthesis

### Phase 0 — Context load → `pass`

Loaded: `proposals/145-structured-multi-phase-reviewer.md`, the spike commit diff (12 files), `compatibility-report.md` + `evidence/`, source vs deployed `deploy-speckit-extension.ps1`, `scripts/internal/supported-versions.yml`, `Specrew.psd1` FileList, and the two regression tests.

### Phase 1 — Branch hygiene → `pass` (with classifications + decision D1)

- **Push status**: `spike-speckit-090` is local-only **by design** — this review gates the push. Not a Shape-4 "never-pushed" failure; the APPROVE verdict below authorizes push as the explicit next step.
- **Shape-5 audit (cited evidence is committed)**: every artifact the report/commit cites is committed in the spike commit — `compatibility-report.md`, all 6 `evidence/*` files, both test files, and the 3 source files (`supported-versions.yml`, `deploy-speckit-extension.ps1`, `CHANGELOG.md`). No working-tree-only cited evidence.
- **Boundary-commit cadence**: one focused chore commit — appropriate for a chore-grade declaration+fix slice; mirrors precedent `ee320e79`.
- **Working tree**: every dirty file classified as pre-existing / out-of-spike-scope (table). The spike commit cleanly excludes all of them; none are reverted (they are pre-existing user/runtime state the spike must not destroy).
- **Upstream parity**: tracked `.specify/extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1` deployed copy is **not** synced to the fix → decision **D1** (leave stale, documented).

Dirty-file classification:

| Path | Δ | Classification | Action |
| --- | --- | --- | --- |
| `.claude/agents/reviewer.md` | +11 | Crew agent runtime (present at session start) | exclude; do not revert |
| `.github/agents/squad.agent.md` | +62 | Crew coordinator prompt regen (pre-existing) | exclude |
| `.squad/config.json` | +25 | Squad runtime config (pre-existing) | exclude |
| `.squad/decisions.md` | +89 | delegated-routing ledger (pre-existing) | exclude |
| `specs/051-multi-session-foundation/iterations/003/tasks-progress.yml` | +1 | F-051 iteration state (other feature) | exclude |
| `.cursor/` | untracked | Cursor host artifacts (runtime) | exclude (untracked) |
| `.specrew/version-check-cache.json` | untracked | per-session version cache (refreshed by this spike's `--info` runs) | exclude; flag as `.gitignore` candidate (separate hygiene chore — not broadened into this spike) |

### Phase 2 — Functional correctness → `pass`

Fix traced + runtime-verified on the real corruption path: string-format → single bare-string entry + idempotent 2nd run; missing-string → added as bare string; object-format → updated in place (no string dup). The bump is data-driven (four-state) and verified `current` at 0.9.0. No auto-pass on test-green alone — the corruption was reproduced (smoke #10) then shown fixed.

### Phase 3 — Non-functional → `pass`

No auth/secret/PII surface. The fix adds no new throw points (clean early-return), is StrictMode-safe, and emits auditable `preserved-registration` / `updated-registration` actions. Encoding: the `specify check` cp1252 banner crash is pre-existing (not 0.9.0) and mitigated by `PYTHONIOENCODING=utf-8`; documented.

### Phase 4 — Code quality → `pass`

`markdownlint` clean on CHANGELOG + report. The fix matches surrounding style (4-space indent, helper conventions, `Add-DeploymentAction`/`Write-Utf8` patterns); a comment states the *why* (0.9.0 `installed:` format change). No dead code, no magic numbers, no commented-out blocks.

### Phase 5 — Test coverage + integrity → `pass`

- **Coverage**: fix has direct regression tests (3 cases); bump has four-state-at-0.9.0 assertions.
- **Gate-completeness (Shape 8)**: tests assert both the positive behavior *and* the corruption-prevention (no object insertion, exactly one entry, idempotent) — the inverse direction, not just "a function ran".
- **Fixture realism (Shape 6)**: tests invoke the **real** `deploy-speckit-extension.ps1` against temp projects, not a synthetic stand-in.
- **Producer/consumer**: the registration producer has a consumer-side runtime demo (`specrew update --specrew` on the 0.9.0 fresh project).
- **Tests-actually-run-at-review**: all three rerun `exit 0` + markdownlint `exit 0` in this review (not asserted from memory). `deploy-extension-missing-source-tolerance` unaffected.

### Phase 6 — System safety + ops → `pass`

Backward compatibility explicitly preserved + tested (≤0.8.x object format, Case C). Deprecation discipline: the Spec Kit 0.12.0 removal of the agent-context compat fallback is documented (report + `supported-versions.yml` notes + memory) as the next-spike trigger. Rollback: chore commit is revertable; the 0.9.0 install is reversible via the documented `uv tool install ...@v0.8.18`. No new multi-dev collision surface (a deploy helper, not shared session state).

### Phase 7 — Synthesis

```yaml
verdict:
  per_phase: { phase_0: pass, phase_1: pass, phase_2: pass, phase_3: pass, phase_4: pass, phase_5: pass, phase_6: pass }
  overall: APPROVE for push/PR
```

## Decision D1 — `.specify` deployed-copy drift: LEAVE STALE (documented)

The tracked deployed copy `/.specify/extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1` retains the old object-only registration logic (verified: it lacks the format-aware branch). **It is intentionally left unsynced for this spike**, on this evidence:

1. **Not release-relevant.** `.specify/` is **not** in `Specrew.psd1` FileList (verified — zero `.specify` matches). The module ships and releases the **source** `extensions/specrew-speckit/` tree, which *is* fixed.
2. **Not on any executed path.** `specrew init` / `specrew update` invoke the deploy helper via the **module** path (`<repoRoot>/extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1`), never the project's `.specify/` copy. `deploy-speckit-extension.ps1` is an init/update helper, not a lifecycle-execution script, so the deployed copy is never run. No test executes it (the regression + missing-source tests both invoke the source).
3. **No parity gate.** There is no current test enforcing deployed-copy↔source parity; the mirror-parity validator is a **future** proposal (Proposal 132, cited in 145's own risks). The deployed copy has tolerated registration-metadata drift historically with green CI.
4. **Self-heals via the generator.** The canonical refresh is `specrew update --specrew` (which re-copies the whole `.specify/extensions/specrew-speckit/` tree from the fixed source). Hand-patching a single file would be an ad-hoc partial regeneration of a generated artifact and would add unrelated churn to a focused chore commit.

**Reversal**: run `specrew update --specrew -ProjectPath .` on this repo to refresh the deployed copy from the fixed source whenever desired.

## Validation results (this review, runtime — not asserted)

| Check | Result |
| --- | --- |
| `tests\integration\extension-registration-format.tests.ps1` | exit 0 |
| `tests\integration\version-info-states.tests.ps1` | exit 0 |
| `tests\integration\deploy-extension-missing-source-tolerance.tests.ps1` | exit 0 |
| `npx markdownlint-cli CHANGELOG.md compatibility-report.md` | exit 0 |
| `git show --check HEAD` | clean (after EOF-blank-line fix on evidence/01,04,05) |
| `git status --short --branch` | only the classified out-of-scope files remain |

## Verdict: **APPROVE for push/PR**

All seven phases pass; the four required cleanup items are resolved (dirty files classified, `.specify` drift decided + documented per D1, whitespace fixed, validations rerun green). Push of `spike-speckit-090` and PR creation are the explicit next human steps.

## PR review response (#1626 — 2026-06-02)

PR [#1626](https://github.com/alonf/specrew/pull/1626) opened against `main`; all 6 CI checks green (Contract lane, Deterministic gate, Lint, Ubuntu, macOS, `test`). Two automated reviewers each raised one valid finding on the new string-format branch of `Ensure-ExtensionRegistration`; both addressed before merge:

1. **Codex (P2) — indentation.** Inserting `- specrew-speckit` at column 0 would break an *indented* `installed:` sequence (0.9.0 emits column-0, but indented sequences are valid YAML). Fixed: capture the matched item's indentation and reuse it on insert. New regression Case D (indented list → entry reuses sibling indent) + Case E (indented + already present → preserved).
2. **Copilot — hard-coded id.** The branch hard-coded `specrew-speckit` instead of the `$ExtensionName` parameter. Fixed: use `$ExtensionName` for both the presence check and the inserted entry.

Re-validated after the fix: `extension-registration-format.tests.ps1` (6 cases A–E), `version-info-states.tests.ps1`, and `deploy-extension-missing-source-tolerance.tests.ps1` all green. Verdict unchanged: **APPROVE for merge** (pending maintainer go-ahead).
