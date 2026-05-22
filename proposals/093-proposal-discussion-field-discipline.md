---
proposal: 093
title: Proposal Discussion-Field Discipline (Methodology Category, README Honesty, Validator Rule, CLI Assist)
status: candidate
phase: phase-2
estimated-sp: 2-3
discussion: ad-hoc 2026-05-22 session
---

# Proposal Discussion-Field Discipline (Methodology Category, README Honesty, Validator Rule, CLI Assist)

> **Profile scope**: This proposal is a **component of the `proposal-driven-design` profile** (Proposal 096). It applies only to projects that have activated the profile (Specrew itself, plus any downstream project that opts in). For non-activated projects, no `proposals/` directory exists, the `discussion:` field has no meaning, and the CLI command described in Part 3 is not registered.

## Why

`proposals/README.md` (line 46-54) describes per-proposal discussion threads in a "Methodology" GitHub Discussions category, created on-demand when a proposal reaches `draft` status. The reality as of 2026-05-22 diverges from this in three ways:

1. **The "Methodology" category does not exist.** The repo currently has only the GitHub default categories (Announcements, General, Ideas, Polls, Q&A, Show and tell). The README references a category that was never created. (This was flagged as pending in the 2026-05-19 public-flip session and never closed.)
2. **Zero per-proposal discussion threads have been created.** Of 36 proposals on disk, 30 carry `discussion: tbd` and 6 (066-072) carry `discussion: ad-hoc <date> session` — a more honest notation for "design conversation happened in a CLI session, not on a public thread." Not a single proposal has a real GitHub Discussions URL.
3. **The `tbd` → real-URL transition has no enforcement.** Proposals advance through `candidate` → `draft` → `active` → `shipped` without anyone ever looking at the `discussion:` field. It's silently always `tbd`.

User-stated concern (2026-05-22):

> "I saw in the proposal readme that we open discussion for each proposal? I didn't see discussion. Should this be a GitHub automation or is it the responsibility of the user that suggests the proposal?"

The README is aspirational; the practice is non-existent. This proposal closes the gap honestly: **author responsibility, with CLI assist, with a validator rule that enforces the field's truthfulness at status-transition time.** Full GitHub Actions automation is over-engineering at current scale (single maintainer, ~36 proposals, small adoption); it can be added later if proposal volume justifies it.

## What

Three small, independently-shippable parts.

### Part 1 — Create the "Methodology" Discussions category (ops chore, one-time)

Either via GitHub web UI (Settings → Discussions → Categories → New category) or via GraphQL:

```text
gh api graphql -f query='mutation {
  createDiscussionCategory(input: {
    repositoryId: "<repo-id>",
    name: "Methodology",
    description: "Per-proposal discussion threads for Specrew design proposals (see /proposals/)",
    emoji: ":scroll:"
  }) { discussionCategory { id slug } }
}'
```

Records the category ID for future automation. Recurring effort: zero.

### Part 2 — Update `proposals/README.md` and `_template.md` to document three valid `discussion:` values

The current README implies a single shape (GitHub URL). Reality has shown three:

| Value | When valid | Meaning |
|---|---|---|
| `tbd` | `status: candidate` only | No discussion yet; proposal is too early |
| `ad-hoc <date> session` | Any status | Design conversation happened in an interactive session (CLI agent, in-person, etc.); no public thread. This is honest documentation of where the design discussion lived. |
| `<github-discussions-url>` | Any status | Public thread on the Methodology category exists. Open for community input. |

The README is updated to document these three values, why each exists, and when each is appropriate. The `_template.md` frontmatter comment is updated to list the three options.

### Part 3 — Validator rule + `specrew proposal discuss <NNN>` CLI command

**Validator rule** (added to `validate-governance.ps1`):

- For any proposal with `status: candidate`: `discussion:` may be `tbd`, an ad-hoc notation, or a URL — anything is valid.
- For any proposal with `status: draft | active | shipped`: `discussion:` must be either `ad-hoc <date> session` notation OR a `https://github.com/.../discussions/<n>` URL. `tbd` is no longer acceptable.
- Severity: medium warning (not hard fail) initially, so existing `tbd` entries on draft+ proposals (currently zero, but possible in future) get flagged for backfill without blocking work.

**CLI command** (folded into Proposal 033 if/when it ships; standalone otherwise):

`specrew proposal discuss <NNN>` — opens a GitHub Discussion in the Methodology category for proposal NNN, pre-populated with the proposal's title + Why section as the opening post. Returns the URL and writes it back into the proposal's `discussion:` frontmatter field. Wraps:

```text
gh api graphql -f query='mutation { createDiscussion(input: {
  repositoryId: "<id>",
  categoryId: "<methodology-id>",
  title: "<proposal-title>",
  body: "<opening-post>"
}) { discussion { url } } }'
```

This makes opening a discussion a one-shot command instead of a manual GitHub UI navigation, removing the friction that has kept the practice from happening.

## Functional Requirements

- **FR-001**: "Methodology" discussion category exists on the repo with stable category ID recorded somewhere reusable (e.g., `.github/discussion-categories.yml`)
- **FR-002**: `proposals/README.md` documents the three valid `discussion:` field values and when each is appropriate
- **FR-003**: `proposals/_template.md` frontmatter lists the three valid values as inline comment guidance
- **FR-004**: Validator rule warns (medium severity) when a `status: draft|active|shipped` proposal has `discussion: tbd`
- **FR-005**: `specrew proposal discuss <NNN>` CLI command creates a Discussion + writes the URL back to frontmatter (or, if Proposal 033 hasn't shipped, a standalone PowerShell script under `scripts/internal/` provides the same)
- **FR-006**: The CLI command's opening post is human-friendly: title + Why + What summary + link to the proposal file

## Out of scope

- Full GitHub Actions automation on status transition — deferred until proposal volume justifies it (or until external contributors start submitting via PR)
- Two-way sync (discussion comments reflected back into proposal file) — that's a different proposal entirely
- Migration of existing `ad-hoc` proposals to real Discussions threads — explicit decision to leave them as-is; the notation is honest
- Cross-proposal threading or labelling — the Methodology category alone is sufficient

## Effort

- **Part 1 (Methodology category)**: ~0.25 SP — one ops command + record category ID
- **Part 2 (README + template update)**: ~0.5 SP — straightforward docs edits
- **Part 3 (validator rule + CLI command)**: ~1.5-2 SP — small validator rule, ~30 lines of PowerShell + frontmatter write-back; doubles to 2 SP if delivered as a standalone command rather than folded into Proposal 033
- **Total**: ~2-3 SP (small-fix slice eligible — composes with Proposal 067)

## Phase placement

Phase 2, **small-fix slice**. Composes with Proposal 067 (small-fix slice type) — eligible because: ≤3 SP, few files (README, template, validator script, one optional CLI script), no architectural change, trivially revertible.

Can ship immediately, independently of Proposal 033 (governance CLI). If 033 ships first, Part 3 folds into 033's scope. If this proposal ships first, the CLI command lives in a small standalone script under `scripts/internal/` and is later moved into 033's CLI surface when that proposal ships.

## Open questions

1. **Severity of the validator rule** — medium warning or hard fail? Recommendation: medium warning for the first iteration after ship, then promote to hard fail once existing proposals are confirmed compliant.
2. **Should `ad-hoc <date> session` notation require a date?** Currently a free-text field. Recommendation: yes, ISO date — gives forward-pointer for traceability. Validator can regex-match `^ad-hoc \d{4}-\d{2}-\d{2}( session.*)?$`.
3. **Should the CLI command also support `--close` / `--lock` to lock a discussion when proposal ships?** Recommendation: out of scope for this proposal; can be added trivially later.
4. **Where does the Methodology category ID live?** Recommendation: `.github/discussion-categories.yml` so it's source-controlled and the CLI command can read it.
5. **Auto-opening behavior on proposal creation** — should `specrew proposal new <slug>` (when it exists per Proposal 033) auto-open a Discussion, or always require explicit `specrew proposal discuss`? Recommendation: explicit, never auto — matches the "author timing matters" principle.

## Risks

1. **Methodology category created but ignored** — if the validator rule is too soft, nothing changes. *Mitigation*: medium-warning surfacing in the validator summary is visible at every governance run; aging-bump style escalation to hard-fail after N iterations of being ignored.
2. **CLI command friction still too high** — if `gh discussion create` requires extra auth setup or fails on first invocation, users abandon. *Mitigation*: integration test verifies the path works end-to-end on a fresh machine; documentation includes auth setup as a precondition.
3. **Stale discussions accumulating** — once threads exist, they may go stale as proposals evolve. *Mitigation*: out of scope for this proposal; this is what `ad-hoc <date> session` notation already implicitly accepts — design conversation moves where it's productive.

## Cross-references

- **Component of**:
  - [096 Proposal-Driven Design Profile](096-proposal-driven-design-profile.md) — this proposal is one of the components bundled under the `proposal-driven-design` profile umbrella; not applicable to projects that have not activated the profile
- **Composes with**:
  - [028 Public Proposals Surface](028-public-proposals-surface.md) — this proposal operationalizes a piece of 028's intent that has been silently missing
  - [033 Specrew Governance CLI](033-specrew-governance-cli.md) — `specrew proposal discuss` is a natural fit for 033's CLI surface; Part 3 folds into 033 when 033 ships
  - [067 Small-Fix Slice Type](067-small-fix-slice-type.md) — this proposal is itself a small-fix slice candidate
- **Composes with self** — this proposal's `discussion:` field is `ad-hoc 2026-05-22 session`, dogfooding the very pattern it documents.

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to user observation that the README aspires to per-proposal discussions but no proposal actually has one. Honesty-first approach: document the three patterns that exist, enforce the field at status-transition, add CLI assist to remove friction.
