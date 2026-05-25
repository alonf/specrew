# Iteration State: 009

**Schema**: v1
**Last Completed Task**: T004 (markdownlint + validator + commit + push)
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: 7773aa12
**Updated**: 2026-05-25T00:00:00Z
**Current Phase**: iteration-closeout
**Iteration Status**: complete

**Feature**: F-044 Per-Host Architecture Refactor
**Branch**: `multi-host-integration-refactor`
**Iteration**: 009 — Bare file:/// URI Enforcement (Smoke-Test Regression Fix) (LIVE-TRACKED)
**Started**: 2026-05-25
**Closed**: 2026-05-25

## Summary

User-flagged regression during pre-smoke-test prep: across all 4 hosts (Copilot, Claude, Codex, Antigravity), boundary handoffs emit file references in markdown-link form `[plan.md](file:///C:/foo/plan.md)` instead of bare `file:///C:/foo/plan.md` URIs. PowerShell terminals (Windows Terminal, VS Code integrated terminal) auto-detect bare `file:///` URIs and make them clickable via Ctrl+Click — but they do NOT render markdown, so the URL is hidden inside `()` and the user can't click through to the artifact. This is the third methodology-UX regression in F-044's arc (iter-008 closed two; iter-009 closes the third).

Root cause: iter-008's three-section format directive said "use `file:///` URIs" but didn't explicitly forbid markdown-link wrapping. An agent reading "use file:/// URIs" can legitimately emit `[name](file:///...)` — that IS a file:/// URI, just wrapped. iter-009 tightens the wording to mandate **bare** form explicitly.

## What Shipped (post-implement)

- `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` 14A — added "BARE `file:///` URIs, NOT markdown-link form" bullet inside the three-section template + welcoming-tone block; also updated 2 supporting bullets to require bare form
- `.specify/.../specrew-governance.md` — mirror
- All 5 canonical agent charters — added bold "Bare URI, not markdown link form" paragraph + updated the existing What I just did bullet to say BARE; mirrored to .specify/ deployed copies
- `docs/user-guide.md` "What you'll see at every boundary" — added explicit bare-URI explanation + how to re-prompt when the Crew emits markdown-link form

## Verification

```text
=== iter-009 verification ===
PASS Markdownlint: 0 violations across all 13 touched files
PASS Validator (governance): iter-009 directory passes canonical-schema lens
```

## Empirical motivation

User exact phrasing (2026-05-25, pre-smoke-test prep): "I do not get the links to the md files (spec, plan, ...) as clickable file urls. I do not know if PowerShell support the markdown links `[](url)`, but it does support `file:///` urls and it was part of the instructions."

Investigation confirmed the regression spans all 4 hosts because the canonical template wording was silent on bare-vs-wrapped form. Per memory rule "use file:/// URL format for all file path references" — that rule applies to BARE URIs, not markdown-link-wrapped URIs (which break Ctrl+Click discovery in PowerShell).

## Outstanding (deferred)

- **Validator hardening**: promoting bare-URI enforcement from text-rule to validator-enforced rule (parse handoff content + reject markdown-link-wrapped file:/// URIs) is a separate methodology-evolution candidate. Captured in retro Improvement Actions; not iter-009 scope.
- **Three-section format adherence at runtime**: covered in iter-008; iter-009 is purely the bare-URI sub-regression.
