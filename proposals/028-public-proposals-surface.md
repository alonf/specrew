---
proposal: 028
title: Public Proposals Surface
status: candidate
phase: phase-2
estimated-sp: 13
discussion: tbd
---

# Public Proposals Surface (this proposal's home)

## Why

This proposal exists because the proposals directory itself needs lifecycle-level integration. The initial promotion (this surface itself) was landed as a chore commit before public flip — fast, but bypassing the Specrew lifecycle. This proposal queues the proper feature work to harden the proposals surface into the lifecycle.

Specifically:
- The status frontmatter is currently informal — no validator enforcement
- When a feature activates (`feature.json` points at it), the corresponding proposal status should auto-transition from `draft` → `active`
- When a feature ships, status should auto-transition to `shipped`
- Discussion-thread creation is manual

## What

Three components:

1. **Soft-validator rule**: proposals must have valid status frontmatter (required fields: `proposal`, `title`, `status`, `phase`). Invalid proposals emit soft-warning.

2. **Coordinator-prompt rule for auto status transitions**: when a feature activates / closes, the corresponding proposal (matched via `shipped-as:` field) gets its status updated automatically.

3. **GitHub Discussions integration**: when a proposal reaches `draft` status, a discussion thread is auto-created in the Methodology category; the thread URL is recorded in the proposal's frontmatter.

## Effort

~12-15 SP, 1-2 iterations.

## Phase placement

Phase 2 — after the initial public-flip promotion lands as chore. This feature hardens what's already there.

## Open questions

1. Validator severity — soft-warning or hard-fail for invalid frontmatter?
2. Auto-transition triggers — what exactly fires the proposal status change?
3. Discussion-thread creation — automated via GitHub API or manual?
4. Numbering enforcement — validator catches duplicates / gaps?
5. Status-history append — manual or automatic?
6. External-proposal submissions — same validator rules apply?
7. Proposal-spec divergence — keep proposal as historical, or update to match shipped reality?

## Risks

- **Auto-transition errors**: incorrect status change can mislead about feature state. Mitigation: transitions are PRs (not direct commits), reviewable.
- **GitHub API coupling**: discussion-thread automation depends on API. Mitigation: graceful degradation if API fails; manual fallback.
- **Validator overhead**: scanning proposals on every validator run adds time. Mitigation: scan only when proposals/ changes detected.

## Cross-references

- Initial promotion lands via chore commit (pre-public-flip, OPTION A)
- This feature is OPTION B (lifecycle hardening, post-flip)
- Composes with: Proposal 013 (Methodology Site) — both are public-facing surfaces

## Status history

- 2026-05-15: candidate captured during proposal-surface design discussion
- 2026-05-15: Option A chore-commit promotion decided; Option B (this proposal) queued as follow-up
