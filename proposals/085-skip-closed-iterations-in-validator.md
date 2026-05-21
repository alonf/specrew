---
proposal: 085
title: Skip Closed Iterations in Validator (Status-Based Iteration Pruning)
status: candidate
phase: phase-2
estimated-sp: 3-5
discussion: tbd
---

# Skip Closed Iterations in Validator (Status-Based Iteration Pruning)

## Why

Specrew's validator (`validate-governance.ps1`) iterates over EVERY iteration directory under `specs/<feature>/iterations/<NNN>/` on every full-repo run. Today the corpus has 44+ iterations; ~85% of them are CLOSED (shipped, immutable, no longer changing). The validator re-validates them anyway.

This is wasted work that compounds as the corpus grows:

- **Today**: 44 iterations × ~30-60s per iteration validation = ~22-44 min per full-repo run
- **In 6 months at current cadence**: ~100+ iterations = ~60-100 min per full-repo run
- **In a year**: validator runtime becomes a major bottleneck for any full-repo invocation

Proposals 083 (Local Validator Speedup) and 084 (Validator Iteration Parallelization) reduce SCOPE and CONCURRENCY axes. **085 adds the IMMUTABLE-WORK axis** — don't re-validate iterations that have shipped and aren't changing.

### Empirical motivation

The Crew building Proposal 083 (2026-05-22) burned ~92+ minutes on `speckit.implement`, including ~65+ minutes across three validator integration test runs (23m 37s + 25m 2s + 16m 38s ongoing). Each test run re-validated the full 44-iteration corpus, including 39+ closed iterations. **Of the ~92 minutes, conservative estimate: 50+ minutes was re-validating closed work** that hasn't changed in months.

### Strategic motivation: external-adoption window

Per memory `[[project-velocity-tracking-post-v0-24-2-2026-05-22]]`, the September 2026 external-adoption window assumes Specrew's velocity is sustainable. Closed iterations grow linearly with corpus age; without status-based pruning, validator runtime grows linearly too. External users running Specrew on THEIR own iteration corpora (starting at 0, growing as they adopt) hit this same growth curve.

### User direction (2026-05-22)

> "I do not understand why do we validate old iterations, I hope that the fix that only looks at git diff files will change this behavior and running validation in parallel will shorten it even more. The problem now is that we add more and more files to validate in each release."

Answer: 083 + 084 address part of the problem; 085 closes the remaining gap. Together the three slices make validator runtime essentially **constant** instead of growing with corpus age.

## What (5 Pillars)

### Pillar 1: Status-based default skip

The validator reads each iteration's `state.md` (or equivalent canonical status marker). If the iteration's status is `closed` (or boundary is `feature-closeout`/`iteration-closeout` and `Iteration Status: COMPLETE`), the validator **skips** the iteration's per-rule checks by default.

```powershell
# Pseudo-code
foreach ($iteration in $allIterations) {
    $state = Get-SpecrewIterationState -Path $iteration
    if ($state.Status -in @('closed', 'complete') -and -not $IncludeClosed) {
        continue  # skip; iteration is immutable
    }

    Test-IterationGovernance -Path $iteration
}
```

### Pillar 2: `-IncludeClosed` opt-in flag

A new `-IncludeClosed` switch to `validate-governance.ps1` overrides the default skip:

- Use case 1: **Schema migration validation** — when a Specrew release adds a new validator rule that requires backfill on old artifacts, run `validate-governance.ps1 -IncludeClosed` to surface any drift.
- Use case 2: **Periodic full-repo truth check** — CI on push-to-main events can run `-IncludeClosed` to catch any drift in closed iteration artifacts (file renames, schema upgrades, etc.).
- Use case 3: **Sanity validation pre-release tag** — before tagging a release, run `-IncludeClosed` once to confirm the whole corpus is green.

### Pillar 3: CI safety check (push-to-main runs `-IncludeClosed`)

To prevent any silent drift in closed iteration artifacts, the existing push-to-main workflow extends to:

```yaml
- name: Validator full-repo truth check
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  run: pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -IncludeClosed
```

Same pattern as `ci(lint-scoping)`: PR-CI uses scoped/skip-closed mode for speed; push-to-main runs the full truth check.

### Pillar 4: `[validator-scope]` banner extension

Compose with 083's `[validator-scope]` and 084's `[validator-parallelism]` banners. The scope banner gains an explicit closed-skipped count:

```
[validator-scope] auto-scoped to origin/main...HEAD (5 active iterations validated, 39 closed iterations skipped)
[validator-parallelism] parallel mode, throttle-limit=6, iteration runspaces=5
[validator-timing] mode=scoped+skip-closed elapsed_ms=2840 iterations_validated=5 trigger_source=local
```

The scope reduction is visible without grepping logs.

### Pillar 5: Configuration via `iteration-config.yml`

Three new keys in `.specrew/iteration-config.yml`:

```yaml
validator:
  skip_closed: true   # default; skip closed iterations on every run
  closed_statuses:    # which status values count as "closed"
    - closed
    - complete
    - feature-closeout
    - iteration-closeout
  parallelism: 6      # composes with Proposal 084
```

Setting `skip_closed: false` reverts to today's behavior (validate all iterations always). The default ships as `true`; downstream projects can opt out for whatever reason.

## How (implementation plan)

This slice ships AFTER Proposal 084 lands (both touch the same iteration-loop area of `validate-governance.ps1`; sequencing avoids conflict). Combined effect with 083 + 084 makes validator runtime essentially constant with corpus age.

| Step | File | Effort |
|---|---|---|
| Add `Get-SpecrewIterationStatus` helper that reads each iteration's `state.md` and returns canonical status | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirrors) | 1 SP |
| Modify validator iteration loop to skip closed iterations by default | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirrors) | 0.5 SP |
| Add `-IncludeClosed` switch parameter | same | 0.25 SP |
| Update `[validator-scope]` banner to show skipped count | same | 0.25 SP |
| Update CI workflow yaml: push-to-main runs `-IncludeClosed` truth check | `.github/workflows/<relevant>.yml` | 0.5 SP |
| Add `validator.skip_closed` + `validator.closed_statuses` to `.specrew/iteration-config.yml` template | template file + downstream sync | 0.5 SP |
| Tests: default skips closed; `-IncludeClosed` opts in; CI workflow tested | `tests/integration/validate-governance-skip-closed.tests.ps1` (new) | 1 SP |
| Mirror parity sweep | both mirrors | 0.25 SP |
| CHANGELOG entry + INDEX update | docs | 0.25 SP |

Total: **~4-5 SP**. Small-fix slice candidate per Proposal 067.

**Ship target**: v0.25.0 alongside Proposals 084 + 078, OR v0.24.3 fast follow-up to v0.24.2 (depends on the maintainer's bundle preference).

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 083 (Local Validator Speedup)** | 083 scopes to GIT-DIFF changed iterations; 085 scopes by STATUS. Both compose: a feature touching 3 iterations validates only the 3 changed iterations AND skips closed iterations within that scope. Edge case: when 083 falls back to full-repo due to global-state changes, 085's skip-closed kicks in to maintain bounded runtime. |
| **Proposal 084 (Validator Iteration Parallelization)** | Orthogonal: 084 parallelizes the validation loop; 085 reduces the loop's input set. Together: ~6× parallelization × ~5-10× scope reduction × ~5-8× status pruning = ~150-500× speedup vs today's serial-all-iterations baseline. |
| **Proposal 030 (Quality Hardening Bundle)** | Could absorb 085 if shipped together later. 085 standalone is the cleaner ship path. |
| **Proposal 042 (Specrew Integration Test Suite)** | Tests in 042's integration suite could benefit from skip-closed default; less time spent in test setup. |
| **Proposal 040/070 (Token Economy)** | The new `validator.skip_closed` and `validator.closed_statuses` keys live in `iteration-config.yml`, composing with the broader configuration surface. |

## Acceptance signals

- **AC1**: Validator skips closed iterations by default. Verified by running on a multi-iteration repo with mix of closed + active iterations; observing `[validator-scope]` banner showing skipped count.
- **AC2**: `-IncludeClosed` flag overrides the default. Verified by running with `-IncludeClosed` and observing all iterations validated.
- **AC3**: `validator.skip_closed: false` in `iteration-config.yml` reverts to today's all-iterations behavior. Verified by config-driven test scenario.
- **AC4**: CI push-to-main workflow runs `-IncludeClosed` as truth check. Verified by workflow yaml inspection + CI run.
- **AC5**: `[validator-scope]` banner shows accurate "N active, M closed-skipped" breakdown.
- **AC6**: Empirical perf — validator on a 44-iteration corpus with 39 closed + 5 active completes in ~5-iteration time (with auto-scope + parallelization compounded: seconds, not minutes).
- **AC7**: Mirror parity across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/`.
- **AC8**: Error handling: if `state.md` is missing or malformed for an iteration, fall back to validating it (don't silently skip an iteration whose status can't be determined).

## Out of scope

- **Cross-iteration validation rules**: some validator rules check consistency ACROSS iterations (e.g., proposal-to-feature mapping). Those rules might need to inspect closed iterations even when individual-iteration validation skips them. This proposal scopes only the per-iteration loop; cross-iteration rules are unaffected.
- **Cache-based validation**: a more sophisticated approach would cache validation results per-commit-hash and only re-validate when content changes. That's a much larger change; this proposal's status-based skip is the simpler, more immediate win.
- **Time-based pruning** (e.g., "skip iterations closed more than 90 days ago"): out of scope; status is the right discriminator, not time.

## Cross-references

- **User direction**: 2026-05-22 conversation, "I do not understand why do we validate old iterations... The problem now is that we add more and more files to validate in each release."
- **Empirical evidence**: 2026-05-22 observation of Crew on 083 burning ~92+ minutes including ~65+ min on validator runs against the full 44-iteration corpus
- **Proposal 083 (Local Validator Speedup)**: file:///C:/Dev/Specrew/proposals/083-local-validator-speedup.md
- **Proposal 084 (Validator Iteration Parallelization)**: file:///C:/Dev/Specrew/proposals/084-validator-iteration-parallelization.md
- **Memory `[[project-velocity-tracking-post-v0-24-2-2026-05-22]]`**: empirical baseline; 085 extends the speedup story past the constant-time threshold
- **Memory `[[project-post-f029-sequencing-2026-05-21]]`**: current canonical queue; 085 slots alongside 084 post-v0.24.2 bundle
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
