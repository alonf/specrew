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

## Open clarifications (resolve at /speckit.clarify before planning)

- [ ] FR-006: default behavior when bin directory is missing (auto-create vs `-Force`); PATH-not-on-PATH (warn vs guided fix).
- [ ] FR-007: `install.sh` delivery model + chicken-and-egg sequencing (curl-pipe vs repo file vs module-shipped).
- [ ] FR-009: wrapper generation vs parity-validation for v1 — the load-bearing architecture choice (routed to the clarify → plan boundary).
