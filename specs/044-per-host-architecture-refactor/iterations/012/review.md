# Review: Iteration 012

**Schema**: v1
**Reviewed**: 2026-05-25
**Overall Verdict**: accepted

**Feature**: F-044 Per-Host Architecture Refactor

## Outcome Summary

**APPROVED** — all 5 tasks closed. v0.27.0 release-readiness blockers from doc-readiness audit are resolved: release notes authored, getting-started.md hardened with antigravity quickstart + Known Limitations entries, proposal-110 collision resolved by renumbering. Branch ready for CI re-run → green → PR merge → v0.27.0 tag → PSGallery publish (steps 7-9 explicitly held per user direction).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-012 | pass | Merged `origin/main` (5 commits) cleanly. INDEX.md inherits 104/108 shipped + 109/110/111 candidates from main |
| T002 | FR-012 | pass | Renamed my proposal 110 → 112; registered other Claude's proposal 110 (specrew-update-experience) in INDEX candidate section; candidate count 68 → 69 |
| T003 | FR-012 | pass | Authored `docs/release-notes-v0.27.0.md` with TL;DR, motivation, F-043+F-044 detail, External-user-value section, Known Limitations (Antigravity caveats + overlay + Codex slash-command-absence + Squad-Copilot-coupling), Migration, Verification, What's next |
| T004 | FR-012 | pass | Added 4th `--host antigravity` line to getting-started.md quickstart (line 89); added 2 Known Limitations entries (Antigravity-cooperative-gate caveat + per-host overlay note) |
| T005 | FR-012 | pass | iter-012 artifacts + lint clean + validator PASS for iter-012 + commit + push |

## Gap Ledger

- No in-scope requirement (FR/SC) gaps: all user-surfaced concerns closed: fixed-now. (iter-010 PR-review cleanup + dashboard-missing-artifacts are out-of-scope items inherited from pre-iter-008 decisions — not iter-012 deferrals; captured in [scope.md](./scope.md) for traceability.)

## Verification Evidence

```text
=== iter-012 verification ===
PASS Markdownlint: 0 violations across all touched docs
PASS Validator (governance): iter-012 directory passes canonical-schema lens
PASS All 7 iter-012 artifacts present (plan, state, scope, drift-log, code-map, review, retro, pr-review-resolution)
```

## Real-world verification (deferred to user)

The canonical empirical test for iter-012 is whether the v0.27.0 PSGallery publication succeeds without external-user navigation gaps. User-driven smoke test: first external installer attempts `Install-Module Specrew -Scope CurrentUser`, follows getting-started.md, picks a host, completes a feature lifecycle. If any documentation friction surfaces, that's iter-013 scope.

## Sign-off

Approved for iteration-closeout. iter-012 is the FINAL iteration of F-044 BEFORE the v0.27.0 release tag.
