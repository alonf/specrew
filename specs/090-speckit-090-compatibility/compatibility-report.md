# Spec Kit 0.9.0 Compatibility Spike — Report

**Feature**: 090-speckit-090-compatibility
**Branch**: `spike-speckit-090`
**Date**: 2026-06-02
**Author**: Specrew Crew coordinator (claude host, non-Squad runtime)
**Spike question**: Can Specrew (0.30.0) safely raise `speckit.max_tested` from `0.8.18` to `0.9.0`, and what changes/tests are required?

**Environment under test**: `uv 0.8.17`, `pwsh 7.6.1`, `squad 0.9.4`. Spec Kit moved `0.8.18` → `0.9.0` (`git+https://github.com/github/spec-kit.git@v0.9.0`, commit `b40ec416`) for the duration of the spike.

---

## Verdict: COMPATIBLE WITH ONE SMALL CODE FIX

Specrew 0.30.0 is compatible with Spec Kit 0.9.0 for **all read paths, the `--info`/`--spec-kit` surfaces, and all existing (≤0.8.x-initialized) projects**. But **`specrew update` requires one small code fix before 0.9.0 support ships.**

0.9.0 changed the `.specify/extensions.yml` `installed:` list from objects to **bare strings**. Specrew's extension-registration helper (`Ensure-ExtensionRegistration` in `extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1`) still searches for and writes the **legacy object format**. On a 0.9.0-initialized project it fails to match the bare-string entry and **inserts a duplicate object entry**, leaving `specrew-speckit` registered twice in a malformed mixed-type list — **silently (exit 0)**. This is the **primary `specrew update` path** (it calls the manual deploy helper directly; it never uses `specify extension add`), and it is reproduced at runtime (smoke #10). 0.9.0 currently tolerates the malformed file (smoke #11), so it is silent corruption, not a crash — which makes it more dangerous, not less.

Required changes for clean 0.9.0 support:

1. **`max_tested` bump** (`0.8.18` → `0.9.0`) + notes in `scripts/internal/supported-versions.yml`.
2. **Make `Ensure-ExtensionRegistration` format-aware** — detect a bare-string `installed:` list (0.9.0) and register/idempotently no-op as a bare string; keep object-format handling for ≤0.8.x projects. Small, safe, backward-compatible.
3. **Regression tests** for both (four-state status at the new ceiling; registration idempotency on a string-format `installed:` list).

`specrew update --info` (status display) and `specrew update --spec-kit` (the `uv tool install ...@<ver>` upgrade action) need **no** change — both are data-driven/version-agnostic and proven (smoke #1, #6, #2).

This maps to the task's middle option ("compatible with small changes") — and here the "small change" includes a **real, scoped code fix**, surfaced only because the smoke test exercised the mutating `specrew update` path at runtime rather than trusting the fresh-init (CLI) success.

---

## Framing: the impact is asymmetric

The risk profile splits cleanly on one axis. The report and the smoke matrix are organized around it.

- **Existing Specrew projects (the common case) — near-zero impact.** They never re-run `specify init`, so 0.9.0's bundled `agent-context` extension is never auto-installed; their committed `speckit.plan` command + the original `.specify/scripts/powershell/update-agent-context.ps1` keep working; Specrew never calls the deprecated Python `upsert_context_section()` path, so the 0.12.0 deprecation warning never fires for them. `specrew update` / `specrew start` do not re-init. Proven tolerant: 0.9.0 reads their legacy object-format `extensions.yml` and stale `init-options.json` without error.
- **Fresh `specrew init` on a box with 0.9.0 installed — this is where all the risk lived.** This is the path that exercises the new extension system. It passed: `specify extension add` merges Specrew's governance hooks correctly alongside the new `agent-context` extension.

---

## What Spec Kit 0.9.0 actually changed

0.9.0's headline change (PR #2546, "Extract agent context updates into bundled agent-context extension") refactors how upstream `specify` manages the agent-context file (the `<!-- SPECKIT START -->` / `<!-- SPECKIT END -->` block in `CLAUDE.md` / `.github/copilot-instructions.md` / `AGENTS.md`):

1. New **bundled `agent-context` extension** (`extensions/agent-context/`) with `after_specify` + `after_plan` hooks, a `speckit.agent-context.update` command, and bash + PowerShell `update-agent-context` scripts driven by `.specify/extensions/agent-context/agent-context-config.yml` (`context_file` + `context_markers`).
2. `specify init` now **auto-installs** the bundled `agent-context` extension and writes its config.
3. The legacy Python `upsert_context_section()` path is **deprecated** (short-circuits when the extension is disabled; emits a deprecation warning) and **scheduled for removal in 0.12.0**. Backward-compat is preserved via class-constant marker defaults.

Two **material on-disk deltas** observed in a fresh 0.9.0 init that downstream tooling could care about:

- **`update-agent-context` relocated.** Old: `.specify/scripts/powershell/update-agent-context.ps1`. New: `.specify/extensions/agent-context/scripts/powershell/update-agent-context.ps1`. The old path is **absent** in a fresh 0.9.0 init.
- **`extensions.yml` `installed:` schema changed** from a list of **objects** (`- name: …` / `version:` / `path:`) to a list of **bare strings** (`- agent-context` / `- git` / `- specrew-speckit`). A new `.specify/extensions/.registry` JSON sidecar now holds per-extension metadata + compiled command lists.

**Why neither delta breaks Specrew:** Specrew does **not** vendor the `speckit.plan` command or `update-agent-context` — both come from `specify init`. A grep of the whole repo confirms **no Specrew script, validator, governance helper, host module, or bootstrap check references the old `update-agent-context.ps1` path**; the only references are the Spec-Kit-authored `speckit.plan` command and frozen test fixtures (`tests/unit/fixtures/015-public-readiness-pass/`). Specrew's own lifecycle updates context via the deployed `/speckit.plan` command (0.9.0 ships its own, hook-driven) — and Specrew's governance scaffolding never touches the agent-context file at all.

---

## Smoke test matrix (11 checks — #10 surfaced the defect, now fixed; all others green)

Checks #1–#9 pass; **#10 FAILED and surfaced the `specrew update` corruption defect** (since fixed + regression-tested); #11 is the severity check confirming the corruption was tolerated, not fatal. Raw logs + captured artifacts under `file:///C:/Dev/Specrew-speckit-090-spike/specs/090-speckit-090-compatibility/evidence/`.

| # | Test | Expectation | Result |
|---|---|---|---|
| 1 | `specrew update --info`, Spec Kit 0.8.18 installed (baseline) | Spec Kit `current`, 0.9.0 advisory | **PASS** — Current 0.8.18 / LatestSupported 0.8.18 / UpstreamLatest 0.9.0 / `current` + advisory. `evidence/01-before-info-0818.txt` |
| 2 | Install Spec Kit 0.9.0 via `uv tool install --force` | `specify 0.9.0` | **PASS** — `specify-cli==0.9.0` (commit `b40ec416`) |
| 3 | **Fresh `specrew init` on 0.9.0** (throwaway dir) | end-to-end bootstrap succeeds | **PASS** — exit 0; `specify-init: initialized .specify`, full governance + squad + slash-surface deploy |
| 4 | **Hook coexistence** (verdict discriminator) | agent-context + git + specrew-speckit hooks coexist | **PASS** — fresh `extensions.yml` registers all three; Specrew's 3 hooks (`before_plan` → before-plan, `after_tasks` → after-tasks, `before_implement` → before-implement) present and correct. `evidence/freshinit-extensions.yml` |
| 5 | **CLI extension-add took (not the manual fallback)** | `specify extension add --dev` path used | **PASS** — `.specify/extensions/.registry` registers all 3 extensions with compiled command lists; 11 `speckit.specrew-speckit.*.prompt.md` compiled into `.github/prompts/` — artifacts the object-format manual fallback cannot produce. `evidence/freshinit-extensions-registry.json` |
| 6 | Existing-project `specrew update --info`, 0.9.0 installed, `max_tested` still 0.8.18 | `ahead-of-supported` + advisory | **PASS** — Current 0.9.0 / LatestSupported 0.8.18 / `ahead-of-supported` + advisory. `evidence/04-existing-info-090.txt` |
| 7 | Legacy object-format `extensions.yml` + stale `0.7.3.dev0` `init-options.json` tolerance | 0.9.0 reads them without error | **PASS** — `specify extension list` in this repo (legacy format + stale metadata) exit 0, lists git + specrew-speckit correctly |
| 8 | `specrew start --no-launch` on the 0.9.0-bootstrapped project | handoff regenerated, no launch | **PASS** — exit 0; `last-start-prompt.md` / `start-context.json` / `start-summary.md` regenerated; host resolved. `evidence/05-start-nolaunch.txt` |
| 9 | **Agent-context runtime step** (not file-presence) | 0.9.0 marker upsert runs in a Specrew-bootstrapped project | **PASS** — `agent-context: updated .github/copilot-instructions.md` exit 0; `<!-- SPECKIT START/END -->` block written from a synthesized `plan.md` |
| 10 | **`specrew update --specrew` on a 0.9.0-initialized project** | registration stays clean + idempotent | **FAIL — defect found** — `Ensure-ExtensionRegistration` did not match 0.9.0's bare-string entry and **inserted a duplicate object-format `specrew-speckit` entry** into the `installed:` list (mixed-type, double registration), **silently (exit 0)**. `evidence/update-corrupted-extensions.yml` vs `evidence/freshinit-extensions.yml`. Log: `evidence/06-update-on-090-project.txt` |
| 11 | 0.9.0 `specify extension list` on the corrupted file | severity check | **TOLERATED (not a crash)** — exit 0; all 3 extensions listed once (0.9.0 dedupes/ignores the stray object entry). Confirms the corruption is silent, not fatal — but Specrew still must not produce it. |

---

## Stale `.specify/init-options.json` / `integration.json` — the task's "special attention"

The honest answer is **mostly moot — confirm and document, do not fix**. Three cases:

1. **Does Specrew read `speckit_version` from these files?** No. Specrew resolves versions from `.specrew/config.yml` and by probing `specify --version` / `uv tool list` (`scripts/internal/version-check.ps1`, `extensions/specrew-speckit/scripts/validate-versions.ps1`). The `.specify/*.json` files are Spec-Kit-owned artifacts; Specrew leaves them untouched after init by design.
2. **Does Spec Kit 0.9.0 break on a stale `0.7.3.dev0` value?** No. 0.9.0 `specify extension list` ran cleanly in this repo, whose `.specify/init-options.json` is pinned at `0.7.3.dev0` (test #7). 0.9.0 only re-reads `init-options.json` on a `specify init` re-run, which Specrew never triggers on `update`/`start`.
3. **Fresh inits regenerate them.** A fresh 0.9.0 init writes `speckit_version: 0.9.0` (and drops the old `preset: null` field) — cosmetic schema drift Specrew does not consume.

Net: the stale metadata is a property of long-lived bootstrapped repos, not of the Specrew↔0.9.0 integration. No action required.

---

## Required changes for clean 0.9.0 support

### (1) Declaration bump

Single edit to `file:///C:/Dev/Specrew-speckit-090-spike/scripts/internal/supported-versions.yml` — the `speckit` block:

```yaml
speckit:
  min: "0.8.4"
  max_tested: "0.9.0"
  notes: "0.9.0 extracted agent-context updates into a bundled agent-context extension (after_specify/after_plan hooks); validated 2026-06-02 (spike-speckit-090): Specrew's before-plan/after-tasks/before-implement hooks coexist via `specify extension add`, legacy object-format extensions.yml + stale init-options.json tolerated, agent-context marker upsert runs. Upstream compatibility fallback deprecated (removal in 0.12.0) does NOT affect Specrew — Specrew never invokes the upstream context-update path. 0.8.14-0.8.18 all additive."
```

This mirrors the prior bump precedent (`ee320e79` — `chore(speckit): bump max_tested 0.8.13 -> 0.8.18`). After this edit, `specrew update --info` flips the Spec Kit row from `ahead-of-supported` to `current` when 0.9.0 is installed.

### (2) Format-aware extension registration (the code fix)

In `file:///C:/Dev/Specrew-speckit-090-spike/extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1`, `Ensure-ExtensionRegistration` must detect the format of the existing `installed:` list:

- **Bare-string list (0.9.0)** — `- agent-context` / `- specrew-speckit`: if `specrew-speckit` is already present as a string, no-op (idempotent); if missing, add the bare string `- specrew-speckit`. Do **not** insert an object entry.
- **Object list (≤0.8.x)** — `- name: specrew-speckit` …: keep the current update-in-place behavior (existing projects unaffected).
- **Create-from-empty**: continue to emit the format Spec Kit expects (object remains acceptable when no `.specify/extensions.yml` exists; in practice `specify init` has already created it, so the format-detection branch governs).

This keeps both `specrew update` and the `specrew init` manual fallback correct on 0.9.0-initialized projects while preserving ≤0.8.x behavior. Small and self-contained.

### (3) Tests

- **Four-state declaration** (mirrors `file:///C:/Dev/Specrew-speckit-090-spike/tests/integration/version-info-states.tests.ps1`): with `max_tested: "0.9.0"`, installed `0.9.0` → `current`; `0.8.x` → `update-available-supported`.
- **Registration idempotency**: feed `Ensure-ExtensionRegistration` a bare-string `installed:` list and assert it leaves a single `- specrew-speckit` string entry (no duplicate, no object insertion, no mixed-type list), and that a second run is a no-op. A companion case asserts ≤0.8.x object-format input is still handled in place.

### (4) Release notes

A one-line CHANGELOG entry recording validated support for Spec Kit 0.9.0 + the agent-context-extension coexistence note.

---

## Forward-looking, non-blocking observations

1. **Hook block on the manual path — CONFIRMED preserved.** `Ensure-ExtensionRegistration` writes `hooks: {}` only on create and never emits Specrew's governance hook block — it relies on `specify extension add` to merge hooks. The concern was whether the format-aware fix's early-return path disturbs the existing hook block on a `specrew update` manual-path refresh. **Verified post-fix**: after two `specrew update --specrew` runs on the string-format fresh project, all three governance hooks survive (`before_plan` → before-plan, `after_tasks` → after-tasks, `before_implement` → before-implement) and the `agent-context` `after_plan` hook still coexists. No further action.
2. **0.12.0 deprecation horizon.** The upstream compatibility fallback (`upsert_context_section`) is removed in Spec Kit 0.12.0. Specrew is unaffected (it never calls the upstream context path), but the next compatibility spike (≥0.12.0) should confirm the bundled `agent-context` extension is always auto-present and that no Specrew flow assumes the legacy inline path.
3. **`specify check` + Windows cp1252 (cosmetic).** `specify check` crashed with `UnicodeEncodeError` rendering its banner in a non-UTF-8 console — a pre-existing `rich`/Windows issue, **not** 0.9.0-specific. Specrew's own version probe already sets `PYTHONIOENCODING=utf-8` to avoid it. No action.

---

## Environment state after the spike

Spec Kit **0.9.0 is currently installed machine-wide** (`uv tool`), replacing 0.8.18. Because `uv tool` is global, this affects every Specrew worktree/project on this machine, several of which assume the validated version.

- **If the bump is approved**, 0.9.0 becomes the validated version — keep it installed (no revert).
- **If deferred/rejected**, revert with: `uv tool install --force specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.18`

Throwaway smoke project at `C:\Temp\specrew-090-smoke\freshinit` can be deleted.
