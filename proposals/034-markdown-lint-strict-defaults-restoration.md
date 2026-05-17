---
proposal: 034
title: Markdown Lint Cleanup and Strict-Defaults Restoration
status: draft
phase: phase-2
estimated-sp: 12
discussion: tbd
---

# Markdown Lint Cleanup and Strict-Defaults Restoration

## Why

Specrew's CI (`Specrew CI` + `Test` workflows) was red on every push to main for at least 3 days (2026-05-13 onward), accumulating 1,274 markdown lint violations across the repo. Detection came only via failure-email notification noise on 2026-05-16.

Pragmatic chore commits added a `.markdownlint.json` config that disables high-volume rule classes mismatched with Specrew's writing style. That reduced violations from 1,274 to 291 — **config-only, no content changes**, deliberately avoiding merge-conflict risk with Feature 019 Distribution Module Iteration 1 currently in flight.

The 291 remaining violations are **genuine cleanup work**, not style mismatches:

- MD047 missing-trailing-newline (86 files)
- MD007 ul-indent inconsistency (68)
- MD012 multiple-blanks (50)
- MD009 trailing-spaces (47)
- MD029 ol-prefix mismatches (14)
- MD052 broken reference-links (12)
- Plus smaller categories totalling ~14 sites

Beyond those 291: the original 1,274 violations are MASKED by the relaxed config. They include some legitimate Specrew style choices but also many genuinely-fixable issues (blank lines around lists, language specifiers on fence blocks, etc.). The pragmatic config is a band-aid; the methodologically-clean solution is to **fix the content AND restore strict markdownlint defaults**.

This proposal does both.

## What

A scoped one-iteration feature that:

1. **Sweeps the repo** to fix all current markdown lint violations (both the 291 genuine ones and the ~1,274 currently-masked)
2. **Removes or empties `.markdownlint.json`** so strict defaults apply going forward
3. **Updates CI workflows** to surface lint failures as PR annotations
4. **Educates Squad coordinator** on markdown-strict-defaults invariant for generated artifacts
5. **Adds validator integration** so future markdown drift is caught at validate-governance time

### Five pillars

1. **Content cleanup sweep** — Mechanical edits across ~200-300 markdown files. Use `markdownlint --fix` for auto-fixable rules (MD047, MD009, MD012); manual fixes for the rest. Includes trailing newlines, indent normalization, blank-line spacing, ordered-list renumbering, broken-reference repair, table-style consistency.
2. **Config cleanup** — Delete `.markdownlint.json` OR keep it with NO `MD*: false` rule disables. End state: strict markdownlint defaults are the repo contract.
3. **CI workflow hardening** — Update `Specrew CI` + `Test` to emit markdownlint findings as GitHub Actions PR diff annotations grouped by rule. Composes with branch protection on main (separate small chore).
4. **Squad coordinator guidance** — New coordinator-template invariant: any markdown Squad generates (specs, plans, tasks, retros, decisions, handoffs) MUST conform to strict markdownlint defaults. Composes with the file-url-compliance coordinator-prompt update.
5. **Validator integration** — Add soft `markdown-lint-violation` WARN rule in `validate-governance.ps1` that runs markdownlint against the repo and reports findings. Severity WARN initially; can graduate to FAIL once a known-clean baseline is established.

### Concrete deliverables

- ~200-300 markdown files edited to conform to strict defaults
- `.markdownlint.json` deleted (or emptied of `MD*: false` rules)
- CI emits markdownlint findings as PR annotations
- New coordinator invariant in `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (+ deployed mirrors)
- New validator rule `markdown-lint-violation` with synthetic violating + compliant fixtures
- New `docs/contributor-markdown-style.md` documenting the strict-defaults contract for contributors

## Effort

- **Iteration 1**: ~10-15 SP, single iteration
- Mostly mechanical edits with tooling-assisted auto-fix where possible
- One-day focused work; longer if cross-platform CI integration adds complexity

## Phase placement

**Phase 2 — sequenced AFTER Feature 019 Distribution Module (both iterations) closes**.

Rationale:
- F-019 Iter 1 currently in flight; touches many markdown surfaces (templates, docs, retros, decisions ledger)
- F-019 Iter 2 (Cross-Platform Hardening) will further sweep markdown via `Join-Path` work
- Running this markdown sweep on main now would create massive merge conflicts when F-019 PRs land
- Sequencing AFTER F-019 means the cleanup runs against a stable base; F-019's markdown surfaces also get cleaned in the same sweep

Pre-condition: F-019 Iter 1 + Iter 2 closed; main stable.

## Concurrent-friendly check

**HIGH-traffic for markdown but LOW-traffic for code.** The markdown sweep touches hundreds of files — guaranteed conflict surface with ANY other feature that edits markdown. This is the OPPOSITE of concurrent-friendly: it should ship in serial isolation between other feature lifecycles.

Practical recommendation: pick a quiet window between features; do the sweep; ship; then unblock other features. Could be a "stop-the-world" small feature that ships in a single day with no concurrent work.

## Open questions

1. Auto-fix tooling: rely on `markdownlint --fix` for the mechanical portion, or do all edits manually?
2. Config end-state: delete `.markdownlint.json` entirely, or keep an empty-disables file for documentation?
3. CI gating: lint-blocks-PR immediately, or grace period?
4. PR-annotation format: per-rule grouping, or per-file?
5. Squad coordinator invariant: WARN-level or strict (FAIL on violation in handoff content)?
6. Validator rule severity: WARN initially, FAIL after baseline establishes?
7. Test fixture pattern: synthetic violating + compliant pair (per Validator Hardening pattern)?
8. Cross-platform: PowerShell-native check or shell out to `markdownlint` binary?
9. Backwards-compat: should `.specify/`, `.squad/` excludes continue, or also conform?
10. Documentation: contributor-style guide covering the strict-defaults contract?

## Risks

- **Massive diff surface**: ~200-300 files edited; PR review burden is high. Mitigation: separate commits by rule class (one commit per MD-rule cleanup), enables review by rule + by file at reviewer's preference.
- **Auto-fix tool quality**: `markdownlint --fix` may not perfectly fix everything. Mitigation: manual review + spot-check after auto-fix pass.
- **Cross-platform line-ending issues**: Windows CRLF vs Linux LF could trigger MD-rule false positives. Mitigation: enforce `.gitattributes` line-ending convention before sweep.
- **Future drift**: without coordinator + validator discipline, the cleanup degrades over time. Pillar 4 + 5 are load-bearing for sustained CI green.

## Cross-references

- Proposal 008 NFR Governance — strict-defaults pattern aligns with Tier 1 universal baselines
- Proposal 030 Quality Hardening Bundle — Validator Hardening expansion picks up Pillar 5 validator rule
- Proposal 033 Specrew Governance CLI — composes; `specrew validate markdown` could be a subcommand
- Feature 019 Distribution Module — must close before this feature opens (merge-conflict avoidance)
- Feature 019 Iter 2 Cross-Platform Hardening — sequenced before; cross-platform CI matrix exists when this lint sweep runs

## Status history

- 2026-05-16: candidate captured + immediately promoted to draft after 3-day CI red incident exposed the gap; user direction "Add a proposal to fix ALL lint issues and clear the .markdownlint.json settings to have a clean solution" anchors the strict-defaults end state.
