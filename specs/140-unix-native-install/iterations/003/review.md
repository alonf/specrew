# Review: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: needs-rework

> Interim review of the **implemented slice (T018-T023)** per maintainer request ("review the implemented
> slice now"). This is NOT iteration closeout. Overall Verdict is `needs-rework` **only** because T021 +
> T024 are blocked on external execution — the implemented slice itself needs no rework (all T018-T023 pass).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T018 | FR-007, FR-016 | pass | macOS Homebrew auto-install; install-if-absent; brew-as-user; fail-closed if brew absent; macOS-aware `--check`. Shell tests green. |
| T019 | FR-017 | pass | `--prerelease` -> `-AllowPrerelease`; stable/prerelease output; wrapper-surface mismatch fail-closed. Surface + predicate unit-tested. |
| T020 | FR-012, FR-002, FR-003, FR-004, FR-008, SC-001, SC-003 | pass | macOS wrapper-runtime lane + real `install-shell-wrappers` -> `specrew version`/`start --help` wired; YAML valid. macOS CI run pending branch push (see Findings). |
| T021 | FR-007, FR-016, SC-007 | needs-work | BLOCKED: needs a real macOS host. Procedure + evidence template filed (`quality/macos-manual-proof.md`, PENDING). |
| T022 | FR-014, SC-005 | pass | Native-first docs; manual `Install-Module` demoted + PSGallery default-`N` note; nvm/Spec-Kit prerequisites documented. Lint clean. |
| T023 | FR-011, FR-009 | pass | Docs-parity arm: every `specrew-*` doc token resolves to alias/skill/allowlist; cascade-named on failure; wired into CI. Test green. |
| T024 | FR-015, FR-017, SC-006, SC-008 | needs-work | BLOCKED: needs maintainer beta-publish authorization. Procedure + evidence template filed (`quality/release-gate.md`, BLOCKED). |

## Findings

### Correctness — PASS

- **Wrapper module-resolution verified (the load-bearing risk).** `install-shell-wrappers` installs
  **symlinks** back into the module's `bin/` (`New-Item -ItemType SymbolicLink`), and `bin/specrew` resolves
  its module root via a POSIX symlink-following loop (no GNU `readlink -f`). A wrapper placed in
  `~/.local/bin` therefore resolves to the installed module on macOS too (BSD-safe). This is the same
  mechanism Ubuntu CI (T015) already proves green; T020 extends it to a macOS runner. A *copy* would break
  resolution — confirmed it is a symlink, so no bug.
- **T018 macOS path.** Darwin detection without `/etc/os-release`; `brew install --cask powershell` as the
  user (no `sudo`); install-only-if-absent (guarded by `have pwsh`); fail-closed if Homebrew absent; the
  apt elevation path was correctly moved into the Linux branch (macOS needs none).
- **T019 prerelease.** Routes to `-AllowPrerelease`; output states stable vs prerelease;
  `verify_specrew_wrapper_surface` fails closed when the installed module lacks `bin/specrew`. It runs only
  after a *fresh* gallery install (pre-seeded CI skips it), so Iteration-2 Ubuntu CI is unaffected.

### NFR — PASS

- **Supply-chain (FR-016):** vendor-recommended sources only (MS apt repo / Homebrew); the only trusted
  `curl|sh` is the Specrew bootstrap itself. Security-surface lens evidence recorded.
- **Idempotency:** `have pwsh` guard + re-runnable brew/Install-Module/install-shell-wrappers; the full
  macOS re-run proof is T021 (manual).
- **Fail-closed:** unsupported platform / absent Homebrew / prerelease mismatch all fail closed with a
  manual-docs link; no partial install reported as success.

### Test integrity — PASS (CI-vs-manual honestly split)

- **CI-proven:** detection (7 host-independent cases incl. the macOS branch via `SPECREW_UNAME_OVERRIDE`),
  wrapper runtime (Ubuntu T015 + macOS T020), docs-parity (T023), the `--prerelease` surface + mismatch
  predicate (T019 unit, via the `SPECREW_NO_MAIN` library seam).
- **Manual / release-gate (NOT CI):** clean macOS auto-install + interactive elevation (T021); prerelease
  install against a published beta + greenfield/brownfield (T024). Enumerated in the hardening gate; not
  overstated as CI coverage.
- **Mechanical lenses** (dead-field / anti-pattern / test-integrity): clean — `findings: []`.

### Minor observations (non-blocking)

- `SPECREW_UNAME_OVERRIDE` is a test seam in production `install.sh` (mirrors the existing
  `SPECREW_OS_RELEASE_FILE` seam); undocumented in `--help` (correctly not user-facing). Low risk — it only
  selects a detection branch and cannot change install sources or escalate. Acceptable.
- `verify_specrew_wrapper_surface`'s `Sort-Object Version -Descending` ignores prerelease tags on the base
  `Version`; benign on the clean release-gate host (only the beta present). Flag for the T024 run.

### Pending runtime evidence before closeout (blocked tasks; tracked in plan.md / state.md)

- **T021** macOS manual proof (SC-007 macOS) — needs a real Mac.
- **T024** release gate (SC-006, SC-008) — needs maintainer beta-publish authorization.
- **T020** macOS CI lane is wired + YAML-valid but has **not yet run** on a macOS runner (branch not
  pushed). Pushing the branch / opening the PR triggers it; its green result is required for review-signoff.

## Gap Ledger

- No FR/SC gaps in the implemented slice (T018-T023 — install.sh macOS + prerelease, macOS CI wiring, native-first docs, docs-parity): all covered requirements verified locally and mechanically clean: fixed-now.

## Notes

- Overall Verdict `needs-rework` reflects that the **iteration** is not acceptable yet (T021/T024 blocked;
  macOS CI not yet run), NOT that the implemented slice needs changes — every T018-T023 verdict is `pass`.
- review-signoff for the full iteration is pending three things: (1) the macOS CI lane green on push,
  (2) T021 evidence filed from a real Mac, (3) T024 release-gate executed under explicit maintainer
  authorization.
- Drift: none introduced this slice (drift-log clean).
