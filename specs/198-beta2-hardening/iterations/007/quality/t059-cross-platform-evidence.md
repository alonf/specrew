# T059 Cross-Platform Deterministic Evidence

**Schema**: v1
**Task**: T059
**Status**: implementation and local Windows/Linux proof complete; hosted three-OS CI proof pending
**Evidence Date**: 2026-07-17
**Provider Spend**: zero

## Delivered Proof Surface

- `.github/workflows/cross-platform-validation.yml` contains one bounded, fail-fast-disabled matrix job for `windows-latest`, `ubuntu-latest`, and `macos-latest`.
- The job name and tests explicitly label the run as deterministic fake-provider evidence that never promotes live support.
- All five production adapter constructors build their normal process specifications; a test-only seam replaces only the executable with the unique `specrew-t059-fake-provider` command. No installed real provider executable can be selected.
- The matrix proves raw file-primary success and strict prose-wrapped rejection for Claude, Codex, Copilot, Cursor, and Antigravity with exactly one fake invocation per case.
- A seeded timeout creates a descendant, then requires verified root/descendant death before controller-owned partial timeout publication.
- The bounded CI suite list also carries strict ingress/identity, immutable authority-store concurrency, spend allowance, interruption/recovery, currentness, external-target containment/origin integrity, public routing, and the native platform runtime suite.
- Linux CI creates one delegated bounded cgroup-v2 root and requires POSIX runtime proof; absence or failure cannot become a skip. macOS uses the production process-group port. Windows uses the production Job Object port.

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

## Pending Hosted Evidence

- No macOS runner is available locally, and no repository push or external workflow dispatch was authorized in this task turn.
- T059 therefore remains `in-progress`. It may become `done` only after the committed matrix runs green on hosted Windows, Linux, and macOS, including the macOS production process-group cases.
- Source presence, Windows/Linux local results, fake adapters, and OS-unsupported simulations do not count as macOS or live-harness proof.
- T060 remains blocked on T059 completion. All five paid live harness slots remain separately human-authorized work, and T061 correction/rerun slots remain outside that floor.

## Drift Decision

The T059 comparison against FR-060, FR-061, FR-062, FR-064, SC-017 through SC-021, and NFR-007 is `PASS`: the implementation matches the planned deterministic proof surface, retains strict failure direction, and makes the missing hosted macOS evidence explicit instead of claiming completion. No Iteration 007-local drift event is required.
