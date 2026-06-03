# Proposal 145 Structured Review — Unix-Native Install, Iteration 001

**Feature**: 140-unix-native-install · **Iteration**: 001 · **Branch**: `140-unix-native-install`
**Date**: 2026-06-02 · **Reviewer**: Crew Reviewer (+ explicit security lens per maintainer instruction)
**Method**: Proposal 145 7-phase structured review, run before review-signoff.
**Scope reviewed**: Iteration 1 implementation (T001-T009) across commits `f7f18325`, `2484d9a0`, `bdef01b4`, `b94ae290` + the review boundary.

## Per-phase synthesis

### Phase 0 — Context load → `pass`

Loaded: `spec.md`, feature `plan.md` + `research.md`, `tasks.md`, iteration `plan.md`, `hardening-gate.md` (ready), the 3 lenses, `mechanical-findings.json` (0), and the implementation diff (groups A-D).

### Phase 1 — Branch hygiene → `pass`

- **Working tree**: only `M .specrew/last-validator-summary.json` — a validator-run cache, out-of-scope, not committed (classified). All feature work committed.
- **Boundary cadence**: 10 boundary commits (specify → clarify → plan → tasks → before-implement → 4 implement groups → review) — clean, per-coherent-group as instructed.
- **Shape-5 audit (cited evidence committed)**: every artifact `review.md` cites is committed — the 4 implement groups (`f7f18325`/`2484d9a0`/`bdef01b4`/`b94ae290`) + the review boundary. No working-tree-only evidence.
- **Push status**: branch is local-only (`origin/main..HEAD` = 10 commits) — by design, pending the maintainer's push decision.
- **Wrapper "upstream parity"**: the generate-then-commit `-Check` drift guard is green (committed `bin/` byte-in-sync with the generator).

### Phase 2 — Functional correctness → `pass`

Generator (deterministic/idempotent, `-Check` drift), wrappers (thin; pwsh check; symlink-resolution loop; alias→subcommand dispatch), installer (decision matrix incl. `skip-needs-force`; idempotent; bin-dir confinement; Windows no-op), and dispatch wiring — all traced and unit-tested (22 checks). A real bug (`$home`/`$IsWindows` read-only-automatic assignment) was caught by tests and fixed. Unix runtime is deferred scope (Phase 5).

### Phase 3 — NFR / security → `pass`

Explicit security lens covers all 5 maintainer-flagged surfaces (bin-dir confinement, `curl|sh` trust, argument forwarding, symlink resolution, `pwsh`/`ExecutionPolicy`). `Bypass` is scoped to the trusted module entrypoint; `-NoProfile`; no secrets; no out-of-dir or shell-profile mutation; failure semantics explicit (robustness lens). Encoding: wrappers are LF-pinned (`.gitattributes`).

### Phase 4 — Code quality → `pass`

Thin forwarders; reviewable generator + installer (pure dot-sourceable decision functions); matches repo conventions (param blocks, helper functions, dispatch shape). `markdownlint` clean. `PSScriptAnalyzer`: only `PSAvoidUsingWriteHost` warnings — the repo's deliberate CLI-output convention (`specrew.ps1` carries 44 pre-existing; the new scripts are consistent), **not** a defect; no other rule findings. No dead code.

### Phase 5 — Test coverage / integrity → `pass` (with classified deferral)

- 22 assertion-driven checks across 4 files, all green; mechanical-findings 0.
- **Gate-completeness**: parity is bidirectional (registry↔wrapper AND FileList↔disk); `-Check` covers all 4 drift modes (in-sync/tampered/missing/extra).
- **Fixture realism**: tests run the REAL scripts, not synthetic stand-ins.
- **Producer/consumer**: the generator (producer) has a consumer-side parity test.
- **Tests-actually-run-at-review**: re-run green at the review boundary.
- **Unix-runtime deferral** — see the explicit classification below.

### Phase 6 — System safety / ops → `pass`

Backward compatibility: Windows behavior unchanged; no new exported alias (so the existing wrapper-set/registry is unchanged for current projects); FileList additions are additive. Rollback: all commits revertable; nothing published. Multi-dev: the generator + `bin/` + FileList are additive shared surfaces (low collision). No-publish gate held (release gate is Iteration 2).

## Phase 7 — Synthesis

```yaml
verdict:
  per_phase: { phase_0: pass, phase_1: pass, phase_2: pass, phase_3: pass, phase_4: pass, phase_5: pass, phase_6: pass }
  overall: APPROVE WITH DEFERRED RUNTIME PROOF
```

## Unix-runtime deferral — explicit classification: ACCEPTED DEFERRED SCOPE (not a missed test gap)

The Unix **runtime** (symlink install, live PATH membership, quoting/spaces argument forwarding, the `pwsh`-missing path) is **accepted, deferred scope**, not a missing test:

1. **Approved decision**: the 2-iteration split (iter-1 = platform-agnostic core; iter-2 = `install.sh` + Ubuntu/macOS CI + docs + release gate) was the maintainer-approved verdict at the `plan → tasks` boundary.
2. **The core IS proven**: the platform-agnostic logic (generator, registry parsing, installer decision matrix, FileList parity, dispatch, Windows no-op) is fully unit-tested on Windows (22 checks). Iteration 1 makes **no** claim of Unix-runtime proof.
3. **Documented everywhere**: the deferral is recorded in `spec.md` (FR-012/SC-001/SC-003 → Iteration 2), `tasks.md` (T011), the hardening gate, and the test-integrity lens — consistent, not hidden.
4. **Platform-not-proxy honored**: Git Bash was used only for `bash -n` syntax checking, never as a substitute for the Ubuntu/macOS runtime verdict.

## Verdict: **APPROVE WITH DEFERRED RUNTIME PROOF**

All seven phases pass. Iteration 1's platform-agnostic deliverable (wrappers + generator + parity + installer + FileList) is accepted; the Unix-runtime proof is owed by Iteration 2's Ubuntu/macOS CI lane (T011) and the greenfield/brownfield release gate (FR-015). No beta/stable publish without explicit maintainer authorization. The maintainer's review-signoff is the boundary approval.
