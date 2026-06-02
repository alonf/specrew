# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 18/20 story_points
**Started**: 2026-06-02
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose.
  - Task Status MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Note — proposed 2→3 iteration split (maintainer decision requested at plan → tasks)

The 2026-06-02 scope correction (spec commit `5d2167c4`) turned `install.sh` from "verify pwsh +
tell the user" into **auto-install PowerShell Core as a dependency** (FR-007/FR-016). That adds
platform/package-manager detection, per-platform install, a `curl | sh` elevation path, and a
load-bearing supply-chain security review. The originally-planned Iteration 2 (~14 SP: install.sh +
Ubuntu/macOS CI + docs + release gate) plus this expansion estimates **~26–30 SP — over the 20 SP
cap**. Per the project's "split, don't raise the cap" stance, this is proposed as a **3-iteration
feature**:

- **Iteration 2 (this plan, ~18 SP)** — `install.sh` orchestration + platform-detection framework +
  **Ubuntu/Debian auto-install proven on Ubuntu CI** + the security lens. Auto-install is intrinsically
  runtime code, so this iteration **builds AND proves** the primary platform end-to-end (no
  build-now/prove-later deferral — that would repeat the form-without-runtime trap on the highest-risk
  surface). Ubuntu-first because a clean no-pwsh container is the cheapest honest proof.
- **Iteration 3 (sketch only; not scaffolded)** — macOS/Homebrew + remaining MS-supported distros, each
  proven on its surface; native-first docs (FR-014); greenfield + brownfield release gate (FR-015) incl.
  bundled Spec Kit 0.9.0. macOS runners can't give a clean no-pwsh env, so the brew path + interactive
  `sudo` ride the iteration where **manual proof** is budgeted.

This split is a feature-shape change and is the **maintainer's call** — it is surfaced here and in the
handoff, not executed silently. The task table below is the Ubuntu-first Iteration 2; Iteration 3 is
sketched in the feature `tasks.md` only.

## Scope Summary

Iteration 2 delivers the **user-facing shell-native install on the primary platform, proven**:
`install.sh` (auto-installs pwsh on Ubuntu/Debian, then installs Specrew + wrappers), the
platform-detection framework with fail-closed behavior for unsupported platforms, the Ubuntu CI runtime
proof (which also discharges the Iteration-1-deferred Unix wrapper runtime on Ubuntu), the parity-cascade
CI guard, and the auto-install security lens.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-007 | `install.sh` user-facing entrypoint: auto-install pwsh on Ubuntu/Debian → `Install-Module Specrew` → `install-shell-wrappers`; fail-closed + manual-docs on unsupported/failed. (macOS/other distros → Iter 3.) | US2 |
| FR-016 | Auto-install safety/transparency: detect platform first; vendor-recommended source only (MS apt repo + verified key); surface (never hide) `sudo`; install-only-if-absent; idempotent repo-add; fail closed. | US2 |
| FR-002 | Exact argument forwarding — **proven on Ubuntu CI** (spaces/quotes/`--`/empty). | US1 |
| FR-003 | Module-root resolution via symlink — **proven on Ubuntu CI**. | US1 |
| FR-004 | Wrapper pwsh-missing-at-runtime error (the wrapper never installs pwsh) — **proven on Ubuntu CI**. | US1 |
| FR-008 | Thin-forwarder unknown-option passthrough — **proven on Ubuntu CI**. | US1 |
| FR-009 | Generate-then-commit drift guard as a CI regenerate-+-`git diff` job. | US3 |
| FR-011 | Parity cascade in CI (registry → wrappers → FileList arm; docs arm → Iter 3) with cascade-named failure. | US3 |
| FR-012 | **Ubuntu** half of the authoritative CI validation surface (macOS half → Iter 3). | US1 |

**Deferred to Iteration 3**: FR-007/FR-016 macOS (Homebrew) + remaining MS-supported distros; FR-012
macOS lane; FR-014 native-first docs; FR-015 greenfield/brownfield release gate (+ Spec Kit 0.9.0);
SC-005/SC-006 and the macOS halves of SC-001/SC-003/SC-007.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T010 | `install.sh` orchestration: shebang + `set -eu`, shell lint clean (`sh -n`/shellcheck), happy path (detect → ensure pwsh → `Install-Module Specrew` → `install-shell-wrappers`), fail-closed structure, arg surface (`--bin-dir` passthrough, `--help`), non-interactive/CI mode flag | FR-007 | US2 | 2 | Implementer | `install.sh` | planned | | | |
| T011 | Platform + package-manager detection framework: parse `/etc/os-release` (ID/VERSION_ID), detect apt/dnf/brew/snap, map to a support decision; **unsupported platform/manager → fail closed + manual-dependency-docs link**; table-driven os-release fixtures + tests | FR-007, FR-016 | US2 | 3 | Implementer | `install.sh`, `tests/**` | planned | | | |
| T012 | Ubuntu/Debian pwsh auto-install: add Microsoft apt repo (key import via the verified MS key, source list) + `apt-get install -y powershell`; **install-only-if-absent** (prefer an existing working pwsh, never clobber/upgrade silently); **idempotent repo-add**; non-interactive flags for CI | FR-007, FR-016 | US2 | 3 | Implementer | `install.sh` | planned | | | |
| T013 | `curl \| sh` tty / elevation handling: detect non-tty stdin; resolve interactive `sudo` (re-exec against `/dev/tty`, or detect-and-instruct download-then-run); surface the exact privileged command; never silently elevate | FR-007, FR-016 | US2 | 2 | Implementer | `install.sh` | planned | | | |
| T014 | **Ubuntu CI runtime proof** (extend `cross-platform-validation.yml`): clean container WITHOUT pwsh → run `install.sh` → auto-install pwsh → `Install-Module` → `install-shell-wrappers` → PATH → `specrew version` / `start --help`; PLUS the wrapper runtime suite on Ubuntu (arg forwarding spaces/quotes/`--`/empty, symlink resolution, pwsh-missing-at-wrapper negative, unknown-option passthrough); shellcheck gate in CI | FR-012, FR-002, FR-003, FR-004, FR-008, FR-007, SC-001, SC-003, SC-007 | US1 | 4 | Reviewer | `.github/workflows/**`, `tests/integration/**` | planned | | | |
| T015 | Parity-cascade CI job: regenerate wrappers + `git diff --exit-code`; registry ↔ `bin/` ↔ `FileList` arm; name the cascade on failure (registry → wrappers → installer → FileList → docs). Docs arm deferred to Iter 3 with the docs | FR-011, FR-009 | US3 | 2 | Reviewer | `.github/workflows/**` | planned | | | |
| T016 | Security lens evidence for the auto-install surface: supply-chain provenance (MS repo + verified key trust), elevation surfaced via the normal prompt, fail-closed on unsupported/failed, install-only-if-absent, idempotent repo-add, **no untrusted `curl \| bash` beyond the trusted Specrew bootstrap itself** | FR-016 | US2 | 2 | Reviewer | `iterations/002/quality/**` | planned | | | |

## Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `dead-field` | mechanical | `iterations/002/quality/mechanical-findings.json` | planned |
| `anti-pattern` | mechanical | `iterations/002/quality/mechanical-findings.json` | planned |
| `test-integrity` | mechanical | `iterations/002/quality/mechanical-findings.json` | planned |
| `stack-tooling-evidence` | tooling | `iterations/002/quality/quality-evidence.md` | planned |
| `quality-lens-review` | manual-evidence | `iterations/002/quality/quality-evidence.md` | planned |

## Phase 2 Hardening

Pre-implementation hardening is planned in `iterations/002/quality/hardening-gate.md`. Auto-install is the
load-bearing security surface this iteration, so `security-surface`, `error-handling-expectations`, and
`test-integrity-targets` are **re-raised as `Blocking: true`** (honoring the Iteration-1 closeout
commitment) and closeable only with recorded runtime evidence. Required lenses under
`iterations/002/quality/lenses/`: `security-baseline@v1.0.0`, `robustness-baseline@v1.0.0`,
`test-integrity@v1.0.0`. Focus areas: **supply-chain/provenance** (MS apt repo + verified key, no
untrusted `curl|bash`, install-only-if-absent, idempotent repo-add), **privilege/elevation** (surface
`sudo` via the normal prompt, never silent; the `curl | sh` non-tty path), **failure semantics**
(unsupported platform/manager → fail closed + manual docs; no partial install reported as success), and
**test-integrity** — which MUST enumerate, per path, what is **CI-proven vs manual** (Ubuntu apt:
CI/container-proven this iteration; macOS brew + interactive `sudo`: Iteration 3 / manual). Git-Bash on
Windows is a proxy, never the runtime verdict.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives may suggest future capacity adjustments. |

## Concurrency Rationale

- Roster: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Dependency graph: `install.sh` chain T010 → T011 → T012 is serial; T013 (tty/elevation) follows T010; T014 (Ubuntu CI) depends on T010–T013; T015 (parity-cascade) is independent of auto-install (depends on the Iteration-1 generator) and can run in parallel; T016 (security lens) reviews T011–T013.
- Shared-surface risk: T010–T013 all edit `install.sh` — keep serial (single Implementer), no same-specialty split. T014/T015 touch `.github/workflows/**` — keep the two CI jobs in one coordinated change to avoid workflow-file collision.
- Recommendation: single serial Implementer on the `install.sh` chain + a Reviewer on CI/parity/security; no parallel same-specialty expansion at this size.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Plan + hardening gate + D11 research (platform matrix) at this boundary |
| Discovery/Spikes | 1 | D11: derive the MS-supported install matrix from Microsoft's current install docs (within T011) |
| Implementation | 10 | T010–T013 (orchestration + detection + Ubuntu install + tty) + T015 (parity-cascade) |
| Review | 6 | T014 (Ubuntu CI runtime proof) + T016 (security lens) |
| Rework | buffer | within the 2 SP headroom (18/20) |

## Traceability Summary

- Requirement scope (Iteration 2): FR-002, FR-003, FR-004, FR-007, FR-008, FR-009, FR-011, FR-012, FR-016 (FR-002/003/004/008/012 are the Ubuntu-runtime proof half; macOS half is Iteration 3).
- Deferred to Iteration 3: FR-007/FR-016 macOS + remaining distros, FR-012 macOS, FR-014, FR-015.
- User stories: US1 (Ubuntu wrapper runtime), US2 (install + auto-install), US3 (parity cascade); US4 (docs) is Iteration 3.
- Success criteria: SC-001/SC-003/SC-007 (Ubuntu halves) this iteration; SC-002 already met in Iteration 1; SC-005/SC-006 + macOS halves are Iteration 3.
- Every task maps to ≥1 in-scope FR; every in-scope FR maps to ≥1 task.

## Notes

- Capacity 18/20 leaves 2 SP rework headroom. Auto-install is built **and** proven on Ubuntu in this iteration — no runtime deferral on the new high-risk surface.
- Status stays `planning` until the plan + split are approved at plan → tasks; flips to `executing` at implementation start.
- No beta/stable publish; the release gate (FR-015) is Iteration 3 and requires explicit maintainer authorization.
- Iteration 3 is intentionally **not** scaffolded and its task table is **not** written (sketch only in the feature `tasks.md`), pending maintainer approval of the split.
