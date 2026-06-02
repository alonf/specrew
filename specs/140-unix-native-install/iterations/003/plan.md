# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 19/20 story_points
**Started**: 2026-06-02

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose.
  - Task Status MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 3 completes the feature on **macOS** and ships the **beta-before-stable release gate**. It turns
the Darwin fail-closed stub in `install.sh` into a real Homebrew PowerShell auto-install, adds the
`--prerelease` install path, extends the existing `validate-macos` CI job with the wrapper runtime suite,
records the macOS manual proof CI cannot produce, writes the native-first docs (leading with `install.sh`,
demoting manual `Install-Module`), completes the parity cascade's docs arm, and runs the greenfield +
brownfield release validation against a published beta (covering bundled Spec Kit 0.9.0).

Two carve-outs keep this iteration honest and within the 20 SP cap:

- **FR-018 / FR-019 (Node/`nvm` + Spec Kit `specrew init` diagnostics) are NOT implemented here.** They are
  delivered by a separate `specrew init` dependency-diagnostics slice (maintainer decision 2026-06-02, see
  `spec.md` Out of Scope). Iteration 3 only **documents** these prerequisites (T022, troubleshooting) and
  **surfaces** them in the macOS manual smoke (T021).
- **Remaining MS-supported distros (RHEL/Fedora via the MS dnf repo) are deferred** to a follow-up
  iteration. The maintainer's request and this iteration's proof surface are macOS; adding dnf would
  overflow the cap. `install.sh` keeps failing closed for those platforms (FR-007/FR-016 fail-closed path,
  already CI-proven in Iteration 2). See Deferrals.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-007 (macOS) | Replace the Darwin fail-closed stub with Homebrew `pwsh` auto-install (`brew install --cask powershell`), install-only-if-absent, fail-closed if Homebrew absent. | US2 |
| FR-016 (macOS) | macOS supply-chain/safety: Homebrew is the vendor-recommended source; `brew` runs as the user (never `sudo brew`); install-only-if-absent; idempotent; fail closed + manual-docs on absent Homebrew. | US2 |
| FR-017 | `install.sh --prerelease`: `-AllowPrerelease` install; `--help` + output state stable vs prerelease; installed-module-lacks-`specrew`-surface mismatch → fail closed. Proven at the release gate (T024). | US2 |
| FR-014 | Native-first docs: `install.sh`/`curl`-to-`sh` first; manual `Install-Module` demoted (PSGallery default-`N` note); pwsh internal-only; troubleshooting documents the macOS Node/`nvm` + Spec Kit prerequisites. | US4 |
| FR-012 (macOS) | Extend the `validate-macos` CI job with the wrapper runtime suite. | US1 |
| FR-002/003/004/008 (macOS) | macOS wrapper runtime: forwarding (spaces/quotes/`--`/empty), symlink resolution, pwsh-missing negative, unknown-option passthrough. | US1 |
| FR-011 (docs arm) | Complete the parity cascade's docs-example arm (registry → … → docs); name the full cascade on failure. | US3 |
| FR-015 | Greenfield + brownfield release-gate validation on a real macOS host via the prerelease flow; covers bundled Spec Kit 0.9.0; no publish without explicit maintainer authorization. | US2 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T018 | macOS Homebrew `pwsh` auto-install: replace the `install.sh` Darwin fail-closed stub with the Homebrew flow — detect `brew`; `brew install --cask powershell`; **install-only-if-absent** (prefer an existing working `pwsh`); **`brew` runs as the invoking user, never `sudo brew`**; idempotent re-run; **Homebrew absent → fail closed + manual-dependency-docs link**. Derive the exact macOS command from Microsoft's CURRENT PowerShell-on-macOS install docs (D11 discipline), not memory. | FR-007, FR-016 | US2 | 3 | Implementer | `install.sh`, `tests/**` | done | claude | | |
| T019 | `install.sh --prerelease` flag: parse `--prerelease` (and `sh -s -- --prerelease`); route the module install to `-AllowPrerelease` (PSResourceGet `-Prerelease` equivalent); `--help` documents it; installer output states **stable vs prerelease**; if the installed module lacks the native `specrew` wrapper command surface (version/source mismatch) → **fail closed** non-zero with an incompatibility message. Built here; exercised for real at T024. | FR-017 | US2 | 2 | Implementer | `install.sh`, `tests/**` | done | claude | | |
| T020 | Extend the existing `validate-macos` CI job (`cross-platform-validation.yml`) with the **wrapper runtime suite on macOS**: arg forwarding (spaces/quotes/`--`/empty), symlink resolution, pwsh-missing-at-wrapper negative, unknown-option passthrough; `install-shell-wrappers` → PATH → `specrew version` / `start --help`. (Clean no-`pwsh` auto-install is NOT CI-reachable on macOS runners → manual, T021.) | FR-012, FR-002, FR-003, FR-004, FR-008, SC-001, SC-003 | US1 | 3 | Reviewer | `.github/workflows/**`, `tests/integration/**` | done | claude | | |
| T021 | macOS **manual-proof** evidence on a real macOS host (the part CI cannot reach): `install.sh` primary path incl. Homebrew `pwsh` auto-install (surfaced, install-if-absent, idempotent re-run), then `specrew version`/`init`/`start`; record the run and capture the prerequisite conditions observed (Node/`nvm` shadowing; `node -v` verified inside `pwsh`; old Spec Kit remediation). Extends `macos-smoke-evidence.md`. | FR-007, FR-016, SC-007 | US2 | 3 | Reviewer | `iterations/003/quality/**`, `macos-smoke-evidence.md` | blocked | | | |
| T022 | Native-first docs (`README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `docs/troubleshooting.md`): lead with `install.sh` / `curl`-to-`sh` from zsh/bash; demote manual `Install-Module` to a labelled fallback with the **PSGallery default-`N`** note; pwsh as internal dependency only; **troubleshooting documents** the macOS Node/`nvm`-shadows-Homebrew prerequisite (verify `node -v` inside `pwsh`) and the Spec Kit old-version remediation (`uv tool install … @v<baseline> --force`, `<baseline>` = `supported-versions.yml` `speckit.min`). | FR-014, SC-005 | US4 | 3 | Spec Steward | `README.md`, `docs/**` | done | claude | | |
| T023 | Complete the parity cascade **docs arm**: extend the parity CI to check doc command examples against the canonical registry (or allowlist with rationale); failure output names the FULL cascade (registry → wrappers → installer → FileList → docs). Finishes the cascade started in Iteration 2 (docs arm was deferred). | FR-011, FR-009 | US3 | 2 | Reviewer | `.github/workflows/**`, `tests/**` | done | claude | | |
| T024 | **Release gate (beta-before-stable):** with explicit maintainer authorization, publish the beta, then install the **published** beta on a real macOS host via `curl`-to-`sh` with `-s -- --prerelease`; run BOTH a **greenfield** and a **brownfield** project (`specrew version`/`init`/`start`), validating the bundled **Spec Kit 0.9.0** support; record evidence. This is where FR-017's prerelease install + version/source-mismatch check are proven against a real published beta. **No beta/stable publish without explicit maintainer authorization.** | FR-015, FR-017, SC-006, SC-008 | US2 | 3 | Reviewer | `iterations/003/quality/**`, `CHANGELOG.md` | blocked | | | |

## Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Closeout Status |
| --- | --- | --- | --- |
| `dead-field` | mechanical | `iterations/003/quality/mechanical-findings.json` | pending |
| `anti-pattern` | mechanical | `iterations/003/quality/mechanical-findings.json` | pending |
| `test-integrity` | mechanical | `iterations/003/quality/mechanical-findings.json` | pending |
| `stack-tooling-evidence` | tooling | `iterations/003/quality/quality-evidence.md` | pending |
| `quality-lens-review` | manual-evidence | `iterations/003/quality/quality-evidence.md` | pending |

## Phase 2 Hardening

Pre-implementation hardening is planned in `iterations/003/quality/hardening-gate.md`. Iteration 3 opens
**new** load-bearing surfaces that Iteration 2's Ubuntu proof did not cover — the macOS/Homebrew
supply-chain, the `--prerelease` provenance + version/source-mismatch check, and the release-gate publish —
so per the Iteration-2 closeout commitment the `security-surface`, `error-handling-expectations`, and
`test-integrity-targets` concerns are **re-raised as `Blocking: true`** for those macOS/prerelease surfaces
and close only with recorded evidence (CI where reachable, **manual proof** where not). Required lenses
under `iterations/003/quality/lenses/`: `security-baseline@v1.0.0`, `robustness-baseline@v1.0.0`,
`test-integrity@v1.0.0`. Focus areas: **macOS supply-chain/provenance** (Homebrew as the vendor-recommended
source; `brew` as the user, never `sudo brew`; install-only-if-absent; idempotent); **prerelease
provenance** (`-AllowPrerelease` fetches the published beta; the installed-module-lacks-`specrew`-surface
mismatch fails closed); **failure semantics** (Homebrew absent → fail closed + manual docs; no partial
install reported as success); and **test-integrity** — which MUST enumerate, per path, what is **CI-proven
vs manual** (macOS wrapper runtime: CI-proven via `validate-macos`; macOS clean `install.sh` auto-install +
interactive elevation + the release-gate beta install: **manual**, since macOS runners cannot give a clean
no-`pwsh` env). Git-Bash on Windows is a proxy, never the runtime verdict.

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
- Dependency graph: **T018 → T019** are serial (both edit `install.sh`; single Implementer, no
  same-specialty split). **T024 (release gate) depends on T018 + T019** (macOS install + `--prerelease`)
  AND on a maintainer-authorized published beta. **T021 (manual proof) depends on T018/T019**. **T020
  (macOS CI)** tests the wrappers and does not need the `install.sh` macOS path, so it can run in parallel
  with the `install.sh` chain. **T022 (docs)** is independent and parallelizable; **T023 (docs-parity arm)
  depends on T022** (docs must exist to check) and the Iteration-2 cascade.
- Shared-surface risk: T018/T019 both edit `install.sh` — keep serial. T020/T023 both touch
  `.github/workflows/**` — coordinate the two CI changes in one pass to avoid workflow-file collision.
- Recommendation: single serial Implementer on the `install.sh` chain (T018→T019); Reviewer on CI/parity +
  the manual macOS proof + the release gate; Spec Steward on docs. No parallel same-specialty expansion at
  this size.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Plan + hardening gate + macOS-smoke evidence at this boundary |
| Discovery/Spikes | 0 | macOS install command derived from MS docs within T018 (no separate spike) |
| Implementation | 8 | T018 (macOS install) + T019 (`--prerelease`) + T022 (docs) |
| Review | 8 | T020 (macOS CI) + T021 (manual proof) + T023 (docs-parity) + T024 (release gate) |
| Rework | buffer | within the 1 SP headroom (19/20) |

## Traceability Summary

- Requirement scope (Iteration 3): FR-007 (macOS), FR-016 (macOS), FR-017, FR-014, FR-012 (macOS),
  FR-002/003/004/008 (macOS halves), FR-011 (docs arm), FR-015.
- Success criteria: SC-005, SC-006, SC-007 (macOS), SC-008, and the macOS halves of SC-001/SC-003.
- Carved-out (separate `specrew init` slice, NOT this iteration): FR-018, FR-019 — Iteration 3 only
  documents (T022) + surfaces (T021) the conditions.
- Deferred (follow-up iteration): remaining MS-supported distros (RHEL/Fedora via the MS dnf repo) for
  FR-007/FR-016; `install.sh` keeps failing closed for them (Iteration-2-proven path).
- Every Iteration-3 task maps to ≥1 in-scope FR/SC; every in-scope FR/SC maps to ≥1 task.

## Deferrals

| Deferred item | Requirement | Rationale | Next action |
| --- | --- | --- | --- |
| Remaining MS-supported distros (RHEL/Fedora via MS dnf repo) | FR-007, FR-016 (non-macOS, non-Ubuntu) | Maintainer's request + this iteration's proof surface are macOS; adding dnf overflows the 20 SP cap (split, don't raise). `install.sh` already fails closed for these (Iteration-2-proven). | A follow-up iteration adds the dnf path + its proof surface. |
| `specrew init` Node/`nvm` + Spec Kit diagnostics (implementation) | FR-018, FR-019 | Carved to a separate `specrew init` dependency-diagnostics slice (maintainer decision 2026-06-02) to keep feature 140 focused on wrappers/`install.sh`/docs. | Stand up the separate slice; Iteration 3 documents (T022) + surfaces (T021) the conditions in the meantime. |

## Notes

- Capacity 19/20 leaves 1 SP rework headroom. macOS auto-install + interactive elevation + the release-gate
  beta install are **manual proofs** (no clean no-`pwsh` macOS runner); the macOS wrapper runtime is
  CI-proven via the extended `validate-macos` job. The hardening gate's `test-integrity` concern enumerates
  the CI-vs-manual split so closeout cannot overstate coverage.
- FR-017 (`--prerelease`) is built in T019 and **proven** in T024 — a published beta exists at the
  release-gate moment, so the prerelease install + the version/source-mismatch fail-closed are exercised for
  real (not build-now/prove-later).
- The beta-before-stable mandate applies: T024 publishes a beta first and validates the installed prerelease
  before any stable promotion; **no beta/stable publication without explicit maintainer authorization.**
- T010's ratified `curl|sh` + `sudo`/no-tty rules (research D11a) carry forward; on macOS, Homebrew runs as
  the user (no `sudo`), so the elevation path is simpler, but the surfaced-never-silent rule still holds for
  any privileged step.
