# Iteration State: 012

**Schema**: v1
**Last Completed Task**: T005 (artifacts + lint + validate + commit + push)
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: 0b1c1810
**Updated**: 2026-05-25T00:00:00Z
**Current Phase**: iteration-closeout
**Iteration Status**: complete

**Feature**: F-044 Per-Host Architecture Refactor
**Branch**: `multi-host-integration-refactor`
**Iteration**: 012 — v0.27.0 Release-Readiness Slice (LIVE-TRACKED)
**Started**: 2026-05-25
**Closed**: 2026-05-25

## Summary

User-flagged: v0.27.0 ready for PSGallery publish pending release-readiness audit. Dispatched 8-area Explore audit which found 4 blockers + polish items. Plus inspection revealed proposal-110 collision (concurrent Claude session pushed proposal 110 specrew-update-experience to main; my proposal 110 quality-tier-routing landed second with same number; my entry was in INDEX, theirs was not). iter-012 closes all of these in a single docs-only slice.

## What Shipped (post-implement)

- Merged `origin/main` (5 commits) into feature branch — auto-resolved INDEX.md showing 104/108 as shipped, 109/110(other)/111 as candidates
- Renamed `proposals/110-quality-tier-routing-runtime-verification-bundle.md` → `proposals/112-...` ; updated frontmatter `proposal: 110` → `proposal: 112`
- Updated INDEX.md: registered other Claude's proposal 110 (specrew-update-experience) in candidate section; bumped candidate count 68 → 69; my entry moved to 112
- Authored `docs/release-notes-v0.27.0.md` — comprehensive multi-host first-release notes with TL;DR, motivation, F-043+F-044 detail, Known Limitations including Antigravity caveats, migration notes, verification summary
- Added 4th `--host antigravity` line to getting-started.md quickstart (parity with hero narrative)
- Added 2 Known Limitations entries to getting-started.md: Antigravity-cooperative-gate-weakness caveat + per-host coordinator-overlay note

## Verification

```text
=== iter-012 verification ===
PASS Markdownlint: 0 violations across all touched docs (release-notes-v0.27.0.md, getting-started.md, INDEX.md, 112-*.md)
PASS Validator (governance): iter-012 directory passes canonical-schema lens
PASS Iteration plan + state + scope + drift-log + code-map + review + retro all present
```

## Outstanding (none in iter-012)

- iter-010 PR cleanup (7 Copilot review findings) — still deferred per pre-iter-008 decision; ships as separate small-fix slice OR v0.27.1 patch
- Release tagging + PSGallery publish — explicitly held per user direction ("wait for all green before #7")
- 9 dashboard.md missing-artifact warnings across closed iterations — pre-existing across multiple features (Proposal 046+048 scope); not iter-012
