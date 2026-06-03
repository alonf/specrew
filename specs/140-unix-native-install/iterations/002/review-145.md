# Proposal 145 Structured Review — Unix-Native Install, Iteration 002

**Feature**: 140-unix-native-install · **Iteration**: 002 · **Branch**: `140-unix-native-install`
**Date**: 2026-06-02 · **Reviewer**: Crew Reviewer (+ explicit auto-install/supply-chain security lens)
**Method**: Proposal 145 7-phase structured review, run before review-signoff.
**Scope reviewed**: Iteration 2 (T010–T017) across commits `f1c41874`, `b36fdbcd`, `aa33fbee`, **proven on
Ubuntu CI run `26812981387`** (all five jobs green).

## Per-phase synthesis

### Phase 0 — Context load → `pass`

Loaded: `spec.md` (FR-007/016 auto-install), feature `plan.md` + `research.md` (D11 + D11a ratified
elevation), `tasks.md`, iteration `plan.md` (19/20), `hardening-gate.md` (re-raised Blocking concerns),
the 3 lenses, and the CI run `26812981387` job logs.

### Phase 1 — Branch hygiene → `pass`

- **Working tree**: feature work committed in 3 coherent groups (`f1c41874` before-implement+T010;
  `b36fdbcd` install.sh; `aa33fbee` proof+lens); only the validator-cache + this review boundary remain.
- **Shape-5 audit (cited evidence committed AND proven)**: every artifact `review.md` cites is committed
  **and** exercised by the green CI run — not working-tree-only, not proxy-only.
- **Push status**: branch pushed; CI run `26812981387` green (the runtime verdict is remote + reproducible).

### Phase 2 — Functional correctness → `pass`

`install.sh` detection (os-release → Ubuntu/Debian; unsupported → fail-closed), the Ubuntu/Debian pwsh
auto-install code path (MS apt repo; install-if-absent; idempotent repo-add; PMC 404 → fail-closed),
ratified tty/elevation (`run_privileged`), module install-if-absent, and wrapper install — all traced and
**proven end-to-end on a clean no-pwsh Ubuntu container** (CI log: pwsh genuinely absent → 7.6.2 installed
from MS repo → branch module → 8 wrappers → `specrew version`). Not a no-op green. **Debian** shares that
identical apt/PMC code path and is **detection-proven** (`--check` routes it to apt), but its PMC install
was not executed this iteration — only Ubuntu runtime proof was required.

### Phase 3 — NFR / security → `pass`

The load-bearing auto-install surface was reviewed against all maintainer-flagged controls: vendor-source
provenance (MS repo + signed packages; no untrusted `curl|bash` beyond the trusted bootstrap), **surfaced
(never silent) elevation**, **fail-closed** on unsupported/failed, install-if-absent (no clobber),
idempotent repo-add. The root path + the fail-closed path are CI-recorded; the interactive-sudo-password
path is honestly labeled manual.

### Phase 4 — Code quality → `pass`

`install.sh` is POSIX `sh`, **shellcheck-clean in CI**, with a thin `run_privileged` indirection that
unifies the root-container and real-user paths; no bashisms; matches the repo's shell-wrapper idiom. Tests
are POSIX sh with a small pass/fail harness. `markdownlint` clean on artifacts.

### Phase 5 — Test coverage / integrity → `pass`

- **CI-vs-manual enumerated** (no blanket "CI-validated"): Ubuntu apt auto-install = container-proven;
  detection/fail-closed = fixture-proven (5/5); wrapper runtime FR-002/003/004/008 = proven on real Ubuntu
  (`4 passed, 0 failed` — incl. the symlink + pwsh-missing paths Git-Bash could not prove); parity-cascade
  green. `Install-Module` from PSGallery = explicitly Iteration-3 release-gate (un-provable pre-publish);
  interactive sudo = manual.
- **Fixture realism**: tests run the REAL `install.sh` + the committed wrapper (stub module-root only
  echoes args); the only seams are an os-release path override + the documented local-module pre-seed.
- **platform-not-proxy honored**: Git-Bash was a forwarding/syntax smoke only; Ubuntu CI is the verdict.

### Phase 6 — System safety / ops → `pass`

Windows behavior unchanged (thin wrappers + installer no-op as before; FR-004 wrapper still never installs
pwsh). install-if-absent never clobbers an existing pwsh; idempotent repo-add; no shell-profile mutation;
no out-of-bin-dir writes. Rollback: all commits revertable; **nothing published**. The `1*-*` CI trigger
fix is additive.

## Phase 7 — Synthesis

```yaml
verdict:
  per_phase: { phase_0: pass, phase_1: pass, phase_2: pass, phase_3: pass, phase_4: pass, phase_5: pass, phase_6: pass }
  overall: APPROVE
```

## Runtime-proof classification: PROVEN (Ubuntu) — not deferred

Unlike Iteration 1 (which legitimately deferred Unix runtime), **Iteration 2's Unix runtime is proven in
this iteration** on the authoritative Ubuntu CI surface (run `26812981387` on `aa33fbee`; re-proved green
on the tip `d70b2ec5` as run `26813561040`): the auto-install, detection, fail-closed, and wrapper runtime
all executed and passed. The Iteration-1 deferral on the Ubuntu paths is thereby **discharged**.
macOS/Homebrew + non-Ubuntu/Debian distros + native-first docs + the greenfield/brownfield release gate
(incl. Spec Kit 0.9.0) + `Install-Module`-from-PSGallery + any publish are **accepted Iteration-3 scope**
(the maintainer-approved 2→3 split), classified explicitly — not a missed test gap. (Debian's apt/PMC path
is Iteration-2 code, detection-proven + sharing the Ubuntu-proven code path; an explicit Debian-container
runtime proof is an optional cheap add if desired.) **FR-012 is half-met**: the green macOS CI job proves
only that the module imports on macOS, not macOS auto-install/wrapper runtime (Iteration 3).

## Verdict: **APPROVE**

All seven phases pass; the headline auto-install is empirically proven on Ubuntu CI (not faked, not
proxy, not deferred). Iteration 2's platform-agnostic-plus-Ubuntu deliverable is accepted. No beta/stable
publish without explicit maintainer authorization (release gate is Iteration 3). The maintainer's
review-signoff is the boundary approval.
