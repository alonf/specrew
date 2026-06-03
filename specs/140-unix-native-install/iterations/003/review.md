# Review: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted — *iteration acceptable with macOS manual validation (T021) WAIVED per maintainer decision 2026-06-03; see note below*

> Updated 2026-06-03 for iteration closeout. The earlier interim verdict was `needs-rework` ONLY because
> T021 (macOS manual proof) + T024 (beta-publish validation) were blocked on external execution. Both are
> now resolved: **T024 PASSED** — `0.31.0-beta4` is Linux-validated (interactive `specrew start` opens + the
> `specrew version` label fix confirmed on a real host) — and **T021 is WAIVED** (maintainer accepts a
> reactive-fix posture; macOS is CI-covered, see `quality/release-gate.md`). The implemented slice never
> needed rework (all T018-T023 pass). The verdict is `acceptable` on the **explicit condition** that the
> macOS manual surface is *waived, not validated*.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T018 | FR-007, FR-016 | pass | macOS Homebrew auto-install; install-if-absent; brew-as-user; fail-closed if brew absent; macOS-aware `--check`. Shell tests green. |
| T019 | FR-017 | pass | `--prerelease` -> `-AllowPrerelease`; stable/prerelease output; wrapper-surface mismatch fail-closed. Surface + predicate unit-tested. |
| T020 | FR-012, FR-002, FR-003, FR-004, FR-008, SC-001, SC-003 | pass | macOS wrapper-runtime lane + real `install-shell-wrappers` -> `specrew version`/`start --help` wired; YAML valid. **macOS CI GREEN** — run 26852247885 (SHA 224bbd6f): macOS Validation + Ubuntu bootstrap/detection/clean-container + parity cascade all pass. |
| T021 | FR-007, FR-016, SC-007 | pass | Acceptable for closeout **via maintainer WAIVER 2026-06-03** — the macOS manual proof was BLOCKED on a real Mac and the maintainer waived it (reactive-fix posture; macOS CI-covered: `validate-macos` + the interactive-`start` PTY TTY-survival regression). Not executed, not scheduled. `pass` = accepted-via-waiver, NOT validated. Template retained (`quality/macos-manual-proof.md`). |
| T022 | FR-014, SC-005 | pass | Native-first docs; manual `Install-Module` demoted + PSGallery default-`N` note; nvm/Spec-Kit prerequisites documented. Lint clean. |
| T023 | FR-011, FR-009 | pass | Docs-parity arm: every `specrew-*` doc token resolves to alias/skill/allowlist; cascade-named on failure; wired into CI. Test green. |
| T024 | FR-015, FR-017, SC-006, SC-008 | pass | beta-before-stable executed: `0.31.0-beta1`→`beta4` published; **`0.31.0-beta4` Linux-validated 2026-06-03** (interactive `specrew start` opens + the `specrew version` label fix). Evidence in `quality/release-gate.md`. |

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

### Runtime evidence at closeout (resolved 2026-06-03)

- **T024** release gate (SC-006, SC-008) — **DONE.** `0.31.0-beta4` published + Linux-validated: interactive
  `specrew start` opens; `specrew version` reports `0.31.0-beta4` (the label fix). See `quality/release-gate.md`.
- **T021** macOS manual proof (SC-007 macOS) — **WAIVED** (maintainer, reactive-fix; macOS CI-covered).
- **CI floor under the waiver:** the macOS lane (run 26852247885) + the interactive-`start` **PTY
  TTY-survival** regression (now green on the Ubuntu *and* macOS lanes) cover the macOS surface short of a
  live on-host run.

## Gap Ledger

- No FR/SC gaps in the implemented slice (T018-T023 — install.sh macOS + prerelease, macOS CI wiring, native-first docs, docs-parity): all covered requirements verified locally and mechanically clean: fixed-now.

## Notes

- Overall Verdict `acceptable` reflects the full iteration at closeout: T018-T023 `pass`, T024 `pass`
  (beta4 Linux-validated), T021 `waived` (macOS manual, maintainer decision). The verdict is explicitly
  conditioned on the macOS-manual waiver — macOS is CI-covered, not on-host-validated.
- A late-cycle fast-follow (post-beta3) added the `specrew version` prerelease label + a TTY-survival
  regression test; shipped in `0.31.0-beta4` and Linux-validated. Two known fast-follows remain (charter
  sidecar investigation; `version-checks.tests.ps1` dev-box-only seam) — neither blocks closeout.
- Drift: none (drift-log clean).
