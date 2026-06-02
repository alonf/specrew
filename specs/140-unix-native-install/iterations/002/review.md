# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-02
**Reviewed By**: Crew Reviewer (auto-install/supply-chain security lens per maintainer instruction)
**Overall Verdict**: accepted
**Provenance**: all reviewed code + tests are committed on branch `140-unix-native-install`
(`f1c41874` T010, `b36fdbcd` install.sh T011-T014, `aa33fbee` proof+lens T015-T017) and **proven on
Ubuntu CI run 26812981387** (all five jobs green). No working-tree-only evidence; no faked/proxy proof.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T010 | FR-007, FR-016 | pass | Ratified piped-`curl`-to-`sh` + `sudo`/no-tty hybrid recorded in research D11a (binding rules). `f1c41874`. |
| T011 | FR-007 | pass | `install.sh` orchestration (happy path, fail-closed structure, `--bin-dir`/`--help`/`--check`); proven end-to-end by the clean-container CI job. `b36fdbcd`. |
| T012 | FR-007, FR-016 | pass | os-release detection (Ubuntu/Debian); matrix **derived from Microsoft's current install docs**; unsupported→fail-closed. Detection test `5 passed, 0 failed` (CI). `b36fdbcd`. |
| T013 | FR-007, FR-016 | pass | Ubuntu/Debian pwsh auto-install via the MS apt repo; **CI log: `pwsh not found → Installing from the Microsoft package repository → PowerShell Core installed (7.6.2)`**; install-only-if-absent, idempotent repo-add, PMC `.deb` 404 = fail-closed. `b36fdbcd` / CI `26812981387`. |
| T014 | FR-007, FR-016 | pass | Ratified tty/elevation via `run_privileged` (root path unifies container + real-user; surfaced sudo; no-tty fail-closed; never silent, never consumes stdin). Root path + fail-closed CI-proven; interactive-`sudo`-password is manual (acknowledged). `b36fdbcd`. |
| T015 | FR-012, FR-002, FR-003, FR-004, FR-008, FR-007, SC-001, SC-003, SC-007 | pass | **Ubuntu CI runtime proof**: clean no-`pwsh` `ubuntu:24.04` container end-to-end (branch module) → `specrew version`; wrapper runtime `4 passed, 0 failed` (forwarding/symlink/pwsh-missing-127/passthrough); shellcheck clean. CI `26812981387`. `aa33fbee`. |
| T016 | FR-011, FR-009 | pass | Parity-cascade CI: generator `-Check` + `git diff --exit-code` + registry/FileList parity tests — green. `aa33fbee`. |
| T017 | FR-016 | pass | Security/robustness/test-integrity lens evidence (supply-chain provenance, surfaced elevation, fail-closed); CI-vs-manual enumerated; runtime-recorded against CI `26812981387`. `aa33fbee`. |

## Gap Ledger

- No in-scope (Ubuntu/Debian) FR/SC gaps: FR-002/003/004/007/008/009/011/012/016 + SC-001/003/007 (Ubuntu halves) verified at runtime: fixed-now. (Iteration 3 scope is recorded under Notes → "Out-of-iteration scope", which is the maintainer-approved split boundary, not gaps in this iteration.)

## Notes

- **Empirical proof (platform-not-proxy honored)**: the Unix runtime is verified on the authoritative Ubuntu CI surface (run `26812981387`), not on Git-Bash. Git Bash on Windows was used only as a forwarding/syntax smoke (it cannot prove symlink/pwsh-missing/`env -i` — Ubuntu CI did: FR-003 + FR-004 pass on real Ubuntu).
- **The headline (auto-install) is real, not a no-op green**: the CI log shows pwsh was genuinely absent, installed 7.6.2 from the Microsoft repo as root, the branch module skipped the gallery (install-if-absent), 8 wrappers installed, and `specrew version` ran.
- **Security**: all five maintainer-flagged surfaces reviewed (supply-chain source provenance, surfaced sudo, fail-closed, install-if-absent, idempotent repo-add); no untrusted `curl|bash` beyond the trusted Specrew bootstrap.
- **Out-of-iteration scope** (Iteration 3, the maintainer-approved 2→3 split — **not gaps** in this iteration's delivery): macOS/Homebrew + other distros (FR-007/016/012 macOS halves, SC-001/003/007 macOS), native-first docs (FR-014/SC-005), the greenfield+brownfield release gate (FR-015/SC-006) incl. bundled Spec Kit 0.9.0, and `Install-Module Specrew` resolving the *published* PSGallery artifact (intrinsically un-provable pre-publish). All were kept OUT of Iteration 2 per the maintainer instruction; no beta/stable publish.
- **No publish**: beta/stable remains gated on explicit maintainer authorization (the release gate is Iteration 3).
- **Verdict semantics**: "accepted" is the Reviewer recommendation; the maintainer's **review-signoff** is the boundary approval.
- A Proposal 145 7-phase structured pass accompanies this review (`review-145.md`).
