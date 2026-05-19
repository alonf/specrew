---
proposal: 006
title: Public-Readiness Pass
status: shipped
phase: phase-1
estimated-sp: 19
shipped-as: feature-015
discussion: tbd
---

# Public-Readiness Pass

## Why

Specrew was on a path to public-open but had four prerequisite gaps that would have made the public flip functionally non-open-source:

1. **No LICENSE file**: default copyright reserved all rights, preventing legitimate use
2. **No NOTICE / upstream attribution**: MIT-licensed Spec Kit and Squad require copyright-notice preservation for substantial copies
3. **Stale README and product-spec status**: README missed key sections; product spec at `specs/001-specrew-product/spec.md` still showed `Status: Draft` despite 13 features shipping
4. **No versioning discipline**: `.specrew/config.yml` showed `specrew_version: "0.1.0-dev"` set at bootstrap, never moved; no CHANGELOG, no git tags, no release process

These four gaps were tightly coupled and bundled into one small feature to avoid spreading close-out work across four separate features.

## What

A two-iteration bundle:

**Iteration 1 (~10 SP)**: Licensing + README

- Added MIT LICENSE file at repo root
- Added NOTICE.md crediting Squad and Spec Kit upstream projects
- Rewrote README with Current State, What's working, What's NOT working yet, Roadmap, License, Contributing sections
- Reconciled product-spec status from `Draft` to `Active 0.14.0`

**Iteration 2 (~9 SP)**: Versioning + closeout template integration

- Bumped `.specrew/config.yml` `specrew_version` from `0.1.0-dev` to `0.14.0`
- Created `CHANGELOG.md` with retroactive entries for features 001 through 014
- Tagged release commits as `v0.13.0` and `v0.14.0`
- Extended feature-closeout authorization template with **Rule 15** that mandates version-bump + CHANGELOG + tag at every feature-closeout
- Reconciled stale `Status: Draft` fields on shipped feature specs (007, 009, 011, 012)
- Documented versioning schema in `docs/versioning.md`

See `specs/015-public-readiness-pass/spec.md` for full detail.

## Effort

~19 SP across 2 iterations.

## Phase placement

Phase 1 — HARD PREREQUISITE for public-open. Without licensing, public-open would have been functionally non-open-source.

## Notable outcomes

Rule 15 (version management at feature-closeout) was tested in production on Feature 015's own feature-closeout boundary. The rule fired correctly on load-bearing actions (version bump, CHANGELOG entry, README update, git tag) WITHOUT explicit enumeration in the authorization prompt — empirically validating the codification approach.

This was the first real-world test of Specrew's "codify lifecycle discipline into coordinator prompts to remove manual prompting" pattern. The result strongly supported the approach. Three corpus-row candidates surfaced from the test:

- `auto-correct-cosmetic-vs-pause-and-ask`
- `template-substitution-failure-on-closeout`
- `stale-example-wording-on-version-bump`

## Cross-references

- Specification: `specs/015-public-readiness-pass/spec.md`
- Codified: Rule 15 in `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
- Foundation for: public flip (which is gated on this proposal having shipped)

## Status history

- 2026-05-12: candidate captured following gap analysis
- 2026-05-13: status → draft
- 2026-05-13: Iteration 001 → active → shipped
- 2026-05-14: Iteration 002 → active → shipped (Rule 15 dogfooded successfully)
