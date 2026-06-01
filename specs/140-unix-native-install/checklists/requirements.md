# Requirements Quality Checklist: Unix-Native Install & Command Surface

**Feature**: 140-unix-native-install
**Date**: 2026-06-02
**Purpose**: Pre-planning requirements-quality review of `spec.md` (Proposal 153 basis).

## Clarity

- [x] Every functional requirement is testable and unambiguous, or explicitly marked `[NEEDS CLARIFICATION]`.
- [x] User stories are independently testable and prioritized (P1 wrappers, P1 install/bootstrap, P2 registry parity, P3 docs).

## Completeness

- [x] Happy path + edge cases enumerated (pwsh missing, symlink resolution, quoting/spaces, bin-dir creation, PATH, packaging/symlink metadata).
- [x] Cross-platform scope explicit (Unix runtime in scope; Windows unchanged except docs).
- [x] Verification surface stated: Ubuntu + macOS CI is authoritative; Git Bash on Windows is a proxy only.
- [x] Release gate captured (greenfield + brownfield install-validation incl. bundled Spec Kit 0.9.0; no publish without authorization — FR-015 / SC-006).

## Consistency

- [x] Functional requirements trace to user stories (TG-001).
- [x] Out-of-scope reconciles with Proposal 153 follow-ups; `install.sh` bounded to a thin bootstrap (TG-004).
- [x] Issue #1627 explicitly deferred (separate subsystem).

## Open clarifications (resolved at /speckit.clarify — Session 2026-06-02)

- [x] FR-006: missing bin dir requires `-Force`; not-on-`PATH` is warn-only (no profile mutation).
- [x] FR-007: repo-committed `install.sh` (`curl | sh`) — verify pwsh, Install-Module, then install-shell-wrappers.
- [x] FR-009: generate-then-commit — generator is source of truth, generated wrappers committed + CI drift-diff.
