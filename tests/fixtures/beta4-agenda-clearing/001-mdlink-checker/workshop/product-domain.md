# Product-Domain Workshop Record — 001-mdlink-checker

**Depth**: Light
**Why Light**: tiny, fully understood personal CLI utility; risk is nil, so competitive
analysis, stakeholder mapping, and adoption planning are not warranted.
**Confirmation**: human-confirmed (lens-question) — the human supplied every answer up front
and confirmed the rendered record with "move on".

## User / stakeholder

A solo developer maintaining Markdown documentation folders (the requester themself). User and
stakeholder are the same person; no separate buyer/operator role.

## Pain / job / current workaround

Relative links and in-document `#anchor`s break silently when Markdown files move or get
renamed. Today this is caught only by clicking through links by hand, or not caught at all.

## MVP

A command-line tool that:

- takes a directory,
- scans every `.md` file beneath it,
- checks every relative file link and every `#anchor` against the actual files and headings on
  disk,
- prints each broken link as `path, line, target`,
- exits 1 if any broken links were found.

## Out of scope

HTTP/HTTPS links, auto-fixing broken links, CI integration, any UI.

## Key constraints

PowerShell 7. Single script. No external dependencies. Zero false positives on a clean folder.

## Skipped areas (Light depth)

- **Alternatives / competitors** — no competitive landscape for a personal utility; the current
  workaround (manual click-through, or nothing) is already captured under pain/job.
- **Adoption / rollout** — single-user tool; no rollout, training, or change-management surface.

## Evidence

Every statement above is tagged `known` — self-reported by the person who owns and will use this
workflow directly.
