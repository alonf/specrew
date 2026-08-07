# T059 Cross-Platform Deterministic Evidence

**Schema**: v1
**Task**: T059
**Status**: complete — corrected hosted Windows/Linux/macOS run and check suite succeeded
**Evidence Date**: 2026-07-17
**Provider Spend**: zero

## Delivered Proof Surface

- `.github/workflows/cross-platform-validation.yml` contains one bounded, fail-fast-disabled matrix job for `windows-latest`, `ubuntu-latest`, and `macos-latest`.
- The job name and tests explicitly label the run as deterministic fake-provider evidence that never promotes live support.
- All five production adapter constructors build their normal process specifications; a test-only seam replaces only the executable with the unique `specrew-t059-fake-provider` command. No installed real provider executable can be selected.
- The matrix proves raw file-primary success and strict prose-wrapped rejection for Claude, Codex, Copilot, Cursor, and Antigravity with exactly one fake invocation per case.
- A seeded timeout creates a descendant, then requires verified root/descendant death before controller-owned partial timeout publication.
- The bounded CI suite list also carries strict ingress/identity, immutable authority-store concurrency, spend allowance, interruption/recovery, currentness, external-target containment/origin integrity, public routing, and the native platform runtime suite.
- Linux CI creates one bounded cgroup-v2 root and runs the fake-process proof in a privileged lane because hosted child-cgroup control files remain root-owned; absence or failure cannot become a skip. macOS uses the production process-group port. Windows uses the production Job Object port.

## Local Windows Evidence

- Deterministic all-adapter matrix: 13 passed, 0 failed, 0 skipped.
- Exact Windows CI suite list before the final SC-017 additions: 113 passed, 0 failed, 0 skipped across adapter contracts, orchestration, ingress, target currentness, public routing, containment, and Job Object runtime.
- Added SC-017 authority-store and spend suites: 9 passed and 13 passed respectively; the updated 13-case matrix/CI-contract suite also passed.
- Worktree containment: 18 passed, including basename-only redaction and the two process-sampling cases.
- Packaged-artifact deploy: 2 passed.
- Explicit F198 registry: all 54 suites green in 520.4 seconds. The only changes after that aggregate were the two additional CI suite-list entries, their matching assertion strings, and evidence/status documentation; their focused suites are green above.

## Local Linux Evidence

- Privileged WSL using a real delegated cgroup-v2 subtree: deterministic all-adapter matrix 13 passed, 0 failed, 0 skipped.
- Production POSIX runtime: 6 passed, proving process-group behavior plus real Linux cgroup clean-exit reap, timeout tree kill, stream closure, candidate ingress, and cleanup.
- Worktree containment: 11 passed, 0 failed, 7 explicitly Windows-only skips. The prior cross-host basename and unsupported `WindowStyle` failures are corrected.
- Added SC-017 authority-store and spend suites: 9 passed and 13 passed respectively.
- The first WSL command attempt failed in launcher quoting before cgroup creation or Pester discovery. The corrected encoded-payload invocation then produced the green results above; no provider command was reachable in either attempt.

## Hosted Run History

- GitHub Actions run `29536313910` executed commit `662dfc4d310795aaddec587d94e6505bed1376e6` on all three hosted runners. The ordinary macOS validation job passed, confirming that `macos-latest` is available.
- The deterministic Windows matrix job passed.
- The deterministic Ubuntu job failed before fake-provider launch because the hosted kernel creates child `cgroup.procs` files as root even when the parent directory is chowned. The lane now installs pinned Pester for all users and runs only the deterministic test process under `sudo`, with an explicit root Git safe-directory entry.
- The macOS all-adapter fake-provider matrix passed 13/13 and all preceding shared suites passed. The job later exposed two worktree-containment portability defects: physical `/var` resolves to `/private/var`, and the legacy sampler incorrectly assumed Linux `/proc` on macOS.
- The correction compares physical paths with `realpath` on POSIX and adds a read-only macOS sampler using `Get-Process` executable metadata plus BSD `ps` command-line data. It does not add mutation or authority.
- The 1-second timeout fixture also proved unstable under virtualized WSL cold starts because containment could fire before the fake provider wrote its descendant PID. Only the fixture timeout is now 5 seconds. The descendant-death case then passed three consecutive privileged-WSL runs and one Windows run.
- Hosted run 1 remains immutable failed evidence and promotes no support.
- GitHub Actions run `29537492190` executed exact correction commit `27015b9e060e9f9696132ff3ed58631d9c538e38`. The enclosing run and GitHub Actions check suite `79984185680` completed `success`.
- Ubuntu job `87752152915` completed `success`; it ran the fake-provider suite under the bounded privileged cgroup-v2 lane and cleaned its delegated root.
- macOS job `87752152937` completed `success`; it reached and passed the full bounded suite, including physical-path containment, read-only sampling, and the production process-group cases. This is real `macos-latest` hosted-runner evidence.
- Windows job `87752152924` completed `success`; it passed the bounded deterministic suite, post-checkout cleanup, and the production Job Object cases.

## Acceptance and Next Boundary

- No macOS runner is available locally. Hosted run 2 supplies the required real macOS proof, including the production process-group cases.
- T059 is `done`: the committed correction has green hosted deterministic evidence on Windows, Ubuntu, and macOS, with the enclosing workflow/check suite terminal-success.
- Source presence, Windows/Linux local results, fake adapters, and OS-unsupported simulations do not count as macOS or live-harness proof.
- T060 is no longer dependency-blocked, but no paid live harness invocation is authorized by T059. All five base slots remain separately human-authorized work, and T061 correction/rerun slots remain outside that floor.

## Drift Decision

The T059 comparison against FR-060, FR-061, FR-062, FR-064, SC-017 through SC-021, and NFR-007 is `PASS`: the implementation matches the planned deterministic proof surface, retains strict failure direction, preserves the failed first run, and binds completion to the corrected hosted three-OS evidence. No Iteration 007-local drift event is required.
