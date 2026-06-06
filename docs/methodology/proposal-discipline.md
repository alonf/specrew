# Specrew Proposal Discipline

Specrew's roadmap is driven by a proposal-first design pattern. Proposals capture feature ideas, methodology improvements, and architectural changes BEFORE they become features. The discipline around creating, updating, and validating proposals is itself part of the methodology — and reviewers verify proposal artifacts the same way they verify feature artifacts.

This document applies to:

- **Implementers** creating or updating proposals (you need to follow these rules to land changes cleanly)
- **Reviewers** verifying commits that touch `proposals/*.md` (you need to check that submissions follow these rules)

For broader review discipline see [review-instructions.md](review-instructions.md). For the lifecycle/spec/traceability contract see [lifecycle-discipline.md](lifecycle-discipline.md).

## Where Proposals Live

- All proposals: `proposals/NNN-<kebab-case-slug>.md` in the Specrew repo root
- Navigation index: `proposals/INDEX.md` (human-maintained until Proposal 028 auto-generation ships)
- Numbering: sequential from 001 upward; never reuse a number, even if a proposal is withdrawn. Withdrawn proposals stay in the file tree as `status: withdrawn` for audit-trail continuity.

## Proposal File Format

Every proposal MUST have:

```markdown
---
proposal: <NNN>                            # zero-padded 3-digit number matching filename
title: <Descriptive Title>
status: candidate | draft | active | shipped | superseded | withdrawn
phase: phase-1 | phase-2 | phase-3 | phase-4 | phase-5 | phase-6 | phase-7
estimated-sp: <number or range like "5-7" or "10-15">
priority-tier: 1 | 2 | 3                    # optional but recommended for Tier 1
discussion: <one-line context note + date>  # what triggered this proposal
---

# <Title>

## Why

<Problem statement; empirical evidence motivating the proposal>

## What — N Pillars

<Concrete deliverables, usually broken into pillars or phases>

## How

<Suggested implementation slicing; iteration breakdown if multi-iter>

## Acceptance criteria

<AC1, AC2, ... — verifiable success conditions>

## Out of scope

<What's explicitly NOT covered by this proposal>

## Composition

<How this composes with other proposals; relationship table>

## Risks

<Known risks + mitigations>

## Status history

<Dated entries showing the proposal's lifecycle>

## Cross-references

<file:/// URLs to related artifacts; INDEX link>
```

Reviewers verify the format is present + populated, not stub-form.

## Proposal Mutability Classes

Proposal status controls whether body text can evolve freely or must preserve a
historical shipped baseline.

| Status | Mutability class | Edit rule |
|---|---|---|
| `candidate` | exploratory | Body text can evolve normally. Keep Status history useful when the direction changes materially. |
| `draft` | source-spec candidate | Body text can evolve normally until the proposal becomes active. Major identity changes should become a new proposal. |
| `active` | in-flight feature input | Use the active feature's normal spec/plan/tasks amendment flow. Do not use `Post-Ship Amendments` for active-proposal scope changes. |
| `shipped` | historical shipped baseline | Do not weave new normative behavior into the original body. Use `Post-Ship Amendments` or a new/superseding proposal. |
| `superseded` | historical baseline replaced by later work | Preserve the historical body. Record supersession pointers, errata, or post-ship deltas without rewriting shipped scope. |
| `withdrawn` | audit record | Preserve the withdrawal rationale and history. Only edit for typos, links, errata, or cross-reference hygiene. |

Legacy `promoted` status is treated as an older synonym for `active` during
review. Legacy `partially-shipped` status is treated as shipped for the shipped
slice and must not be used to hide new requirements inside historical body text.

For `shipped` and `superseded` proposals, allowed direct edits outside
`Post-Ship Amendments` are limited to typo fixes, broken link fixes, historical
errata, Status history, Cross-references, and metadata such as `superseded-by`.
Behavior-changing work defaults to a new proposal or clearly linked follow-up
feature rather than silent body edits.

## Post-Ship Amendments

Use this section only for proposals with `status: shipped` or
`status: superseded`. Keep implemented amendments in the original proposal for
audit continuity; do not copy them into a generated amendment index.

```markdown
## Post-Ship Amendments

### A1 - <short amendment title>

- amendment-id: A1
- date: YYYY-MM-DD
- status: proposed | accepted-unimplemented | active | implemented | rejected | superseded
- delta-summary: <what changes relative to shipped behavior>
- implementation-owner: <feature, proposal, owner, or TBD>
- preserve: <shipped behavior that must remain intact>
- tests-required: <characterization, regression, or acceptance tests required>
```

Amendment status meanings:

| Status | Meaning |
|---|---|
| `proposed` | Captured for discussion; not yet accepted into backlog. |
| `accepted-unimplemented` | Accepted as follow-up scope and visible in proposal status/index surfaces. |
| `active` | Being implemented by an active feature or clearly linked work item. |
| `implemented` | Delivered; closeout evidence names the amendment id and final disposition. |
| `rejected` | Considered and rejected; keep the rationale in the amendment body or Status history. |
| `superseded` | Replaced by another amendment or proposal; link the replacement. |

Every implementation plan that uses a post-ship amendment must include a
`Delta from shipped behavior` section naming the amendment id or superseding
proposal, the shipped behavior to preserve, and required characterization or
regression tests.

## Creating a New Proposal

Step-by-step (this sequence is enforced; deviations are reject-worthy):

1. **Identify the next available proposal number** — check `proposals/INDEX.md` + `ls proposals/` for highest existing number; pick `<highest+1>`
2. **Verify the number isn't in flight elsewhere** — `git log --all -- "proposals/<NNN>-*.md"` to confirm no in-flight branch is using it
3. **Choose status** — `candidate` for idea-form; `draft` if a full source-spec exists already
4. **Author the file** with proper frontmatter + all required sections (Why / What / How / AC / Out of scope / Composition / Risks / Status history / Cross-references)
5. **Add an entry to `INDEX.md`** under the correct section (Shipped / Draft / Candidate). Entry format: `| [NNN](NNN-slug.md) | Title — description | phase | SP |`
6. **Update the Candidate (or Draft) count** in the INDEX section header (`## Candidate (N)` → `## Candidate (N+1)`)
7. **Lint locally** — `npx markdownlint-cli proposals/NNN-*.md proposals/INDEX.md` — push-to-main lint failure cascades to skip Deterministic + Contract lanes silently, so catching lint locally matters
8. **Verify branch = main** before commit — `git branch --show-current` must return `main`. Proposals always commit to main, never to feature branches (real F-020 incident: proposals on feature branch caused closeout PR stray-disposition)
9. **Use worktree pattern if currently on feature branch** — `git worktree add C:/path/to/worktree main`; copy files there; edit + commit + push from worktree; remove worktree
10. **Commit with clear message** — pattern: `chore(proposals): draft NNN-<slug>`; include rationale + composition notes in body
11. **Push to origin/main**

## Updating an Existing Proposal

When to update vs draft a new proposal:

| Change type | Action |
|---|---|
| Refinement of scope, adding pillars, clarifying composition, fixing typos | **Amend existing proposal** — edit + commit with `chore(proposals): refine NNN-<slug>` |
| Promoting candidate → draft (full source-spec exists) | **Amend in place** — change `status: candidate` → `status: draft`; move INDEX entry from Candidate to Draft section; update counts |
| Promoting draft → shipped (feature merged) | **Amend in place** — change `status: shipped`; move INDEX entry; add "Shipped as feature-NNN" |
| Adding behavior after a proposal shipped | **Use `Post-Ship Amendments` or draft a new proposal** — do not rewrite shipped body text |
| Significant scope expansion that changes the proposal's identity | **Draft new proposal** + reference old one as ancestor; old proposal stays as audit trail |
| Pivot to fundamentally different approach | **Withdraw old + draft new** — old status → `withdrawn`; document the pivot in old proposal's Status history |
| Splitting one proposal into multiple | **Draft new proposals + amend original** to scope only to one piece + reference the split-offs |

Status transitions must be visible in the proposal's "Status history" section with date + commit hash.

## Discussing and Positioning Proposals

When discussing proposals (in design conversations, planning sessions, or reviewer feedback), reference these properties:

- **Priority tier** — Tier 1 (HIGH PRIORITY, must ship soon), Tier 2 (valuable, ship when capacity allows), Tier 3 (later phase)
- **Phase** — phase-1 through phase-7; reflects when in the Specrew roadmap this lands
- **SP estimate** — story points; informs sequencing capacity
- **Composition** — which other proposals this composes with, depends on, absorbs, supersedes, or is sibling to
- **Strategic value** — does it ship Specrew differentiation, plug a capability gap, fix a bug class, OR enable upstream contribution (Squad / Spec Kit channel via Brady Gaster)?

Bundling decisions: when ≥2 proposals naturally compose, consider bundling them into a single feature. Examples:

- Proposal 137 (Design Alternatives Gate) + Proposal 138 (Spec Kit Underutilized) bundle because 138's `/speckit.checklist` Pillar 1 hook fits cleanly at 137's new design-analysis boundary
- Proposal 011 + 121 + 135 bundle as "Design Rigor" because they form an end-to-end pipeline

Don't bundle prematurely; ship-independence is usually safer than bundling unless the composition synergy is concrete.

## Validation Consistency Rules

Reviewer (and validator) checks for any proposal-touching commit:

| Rule | Check |
|---|---|
| **File presence** | `proposals/NNN-<slug>.md` exists for every INDEX entry; every file has matching INDEX entry |
| **Number uniqueness** | No duplicate proposal numbers across `proposals/*.md` files |
| **Frontmatter completeness** | Required fields (`proposal`, `title`, `status`, `phase`, `estimated-sp`) present; values are valid enums |
| **Status-INDEX consistency** | Proposal's `status: candidate` lands in INDEX Candidate section; `status: draft` in Draft; `status: shipped` in Shipped |
| **Post-ship amendment shape** | Shipped/superseded amendments use required fields and allowed statuses; unsafe body edits warn before merge |
| **Count accuracy** | `## Candidate (N)` in INDEX matches actual row count under that section; same for Draft + Shipped |
| **Cross-reference validity** | Every `file:///` URL points to a real file; every `[[memory-name]]` link points to a real memory entry |
| **Composition link bidirectionality** | If Proposal A says "composes with B", Proposal B should also reference A (best-effort; manual maintenance) |
| **No proposals on feature branches** | `git log <feature-branch> -- proposals/` should be empty — proposals always commit to main |
| **No squashed proposal commits** | Proposal commits should be clean direct-to-main commits, not part of merge-commit branches |
| **Lint clean** | `markdownlint` passes; no trailing whitespace, broken table syntax, or unclosed code fences |
| **Slug matches title** | File name slug should reasonably match the title (kebab-case from title words) |

## Reviewer Verification for Proposal Changes

When a commit touches `proposals/*.md`, the reviewer must:

1. **Read the proposal diff** — is the change substantive or just a formatting fix?
2. **Verify INDEX consistency** — did the entry move correctly between sections if status changed?
3. **Check cross-references** — do new file:/// URLs and [[memory-name]] links resolve?
4. **Verify count headers** — does `## Candidate (N)` match the actual count after the change?
5. **Confirm branch discipline** — was the commit on main, not on a feature branch?
6. **Confirm lint discipline** — does `markdownlint` pass on the touched files?
7. **For new proposals**: verify all required sections are populated (not stub-form)
8. **For status transitions**: verify the transition is documented in Status history with date + commit hash
9. **For shipped/superseded proposals**: verify behavior-changing deltas live in `Post-Ship Amendments` or a superseding proposal, not in rewritten shipped body text

## Strategic Composition Patterns

Recurring patterns in Specrew's proposal ecosystem; useful framing during proposal discussions:

- **Engine + data architecture pivot pattern** (F-049 iter-3) — when a feature involves volatile data (intake catalogs, question banks, persona definitions), prefer to design as: discrete engine + YAML data catalogs + thin orchestrators. Future expansions land as YAML-only data additions, not engine rewrites. Captured as TG-013/TG-014/TG-015 + SC-006 (extensibility proof).
- **Provider/adapter pattern for multi-host abstractions** — Proposal 024 (Multi-Host Runtime CORE), Proposal 069 (Multi-Host Launch Path), Proposal 127 (Git-Host Adapter), Proposal 057 (Roadmap Input Adapter), Proposal 101 (External Tracker Sync Provider), Proposal 105 (Host-Native Hook Deployment), Proposal 139 (Multi-Agent Subagent Orchestration) all follow the same shape: per-host adapter contract + per-host adapter implementations + capability flags + degraded-mode fallback.
- **Empirical-evidence-first proposals** — every proposal should cite the specific dogfooding incident(s) that motivated it. "Discussion: surfaced YYYY-MM-DD during <incident>" in frontmatter; "Empirical motivation" subsection in body. Proposals without empirical motivation are speculative; reviewers should push back on them or downgrade priority.
- **Upstream-contribution candidate flagging** — when a proposal addresses a gap that Squad or Spec Kit also has (verified via repo audit), flag it as upstream-contribution candidate. Composition with Proposal 039 (Squad Upstream Reconciliation) pattern. Track via Brady Gaster channel.
- **Slice-type catalog application** (Proposal 055) — for any proposed work, identify the slice type: chore / small-fix / bug-fix / bug-bash / doc-only / enabler / new-feature / refactor / methodology-improvement. Slice type drives applicable disciplines (which boundaries are required, what artifacts are needed).

## Cross-References

- [lifecycle-discipline.md](lifecycle-discipline.md) — shared methodology (boundary discipline, spec authority, traceability, drift, committed-tree durability, lifecycle metadata, spec coverage verification, release process, Shape Catalog)
- [review-instructions.md](review-instructions.md) — reviewer-specific guidance (review method, verdict format, approval/rejection criteria, severity guidance, mindset, agent-diagnosis verification)
- [../../proposals/INDEX.md](../../proposals/INDEX.md) — proposal navigation index
- [../../proposals/028-public-proposals-surface.md](../../proposals/028-public-proposals-surface.md) — future INDEX auto-generation
- [../../proposals/039-squad-upstream-reconciliation.md](../../proposals/039-squad-upstream-reconciliation.md) — upstream-contribution pattern
- [../../proposals/055-always-in-flow-bug-fix-lifecycle.md](../../proposals/055-always-in-flow-bug-fix-lifecycle.md) — slice-type catalog
- [../../proposals/060-prerelease-channel-staging.md](../../proposals/060-prerelease-channel-staging.md) — universal beta-before-stable mandate
