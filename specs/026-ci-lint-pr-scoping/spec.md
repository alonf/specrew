# PR Lint Scoping — Governance Efficiency

## Problem

The CI lint job in `.github/workflows/specrew-ci.yml` runs full-repository checks on every pull request, scanning all Markdown and PowerShell files regardless of what the PR modifies. For large repos with many specs, configs, and governance artifacts, this creates unnecessary latency (F-024 PR #306 took ~80 minutes across 5+ CI cycles; typical lint job runs ~15 minutes -> optimized target <1 minute). Push-to-main linting remains comprehensive to ensure the default branch is conformant end-to-end.

## Fixed Design

Scope pull-request linting in `.github/workflows/specrew-ci.yml` to changed files only:

- **markdownlint:** on PR events, check only changed `*.md` files (via `git diff --name-only --diff-filter=d base..head -- '*.md'`)
- **PSScriptAnalyzer:** on PR events, check only changed `*.ps1` files (via `git diff --name-only --diff-filter=d base..head -- '*.ps1'`)
- **validate-governance.ps1:** on PR events, check only changed iteration directories under `specs/*/iterations/` plus the always-checked global state surface (`.specrew/`, `.squad/identity/`, `.specify/feature.json`); skip full `specs/` tree scan.
- **Defensive fallback:** if `git diff` cannot resolve the base (e.g., on orphaned branches), fall back to full validation.
- **Push events:** unchanged; `git push` to `main` or `001-specrew-product` continues full-repository lint for conformance gate.

## Scope Boundaries

- **Applies to:** Pull requests only via `on: pull_request` event handler in `.github/workflows/specrew-ci.yml`.
- **Target file:** `.github/workflows/specrew-ci.yml` lint job and `Validate iteration governance` step.
- **Validator target:** `extensions/specrew-speckit/scripts/validate-governance.ps1` receives scoped iteration paths on PR; runs full path on push.
- **Out of scope:** YAML/JSON linting and generic `specs/*` patterns (only specific `specs/*/iterations/` dirs on PR).
- **Push-to-main behavior:** full-repository lint unchanged (all `.md`, all `.ps1`, full governance validation).

## Acceptance Criteria

- **AC1:** On PR events, markdownlint receives only changed `*.md` files; scan time <1 minute for typical PRs.
- **AC2:** On PR events, PSScriptAnalyzer receives only changed `*.ps1` files; scan time <1 minute for typical PRs.
- **AC3:** On PR events, `validate-governance.ps1` scopes to directories matching `specs/*/iterations/<N>/` that have changed files, unless `.specrew/`, `.squad/identity/`, or `.specify/feature.json` changes force the unscoped fallback; it skips the full `specs/` tree walk when scoped.
- **AC4:** On PR events, if diff base cannot be resolved, all three tools fall back to full validation (non-blocking informational log).
- **AC5:** On push events, all three tools run full-repository scans unchanged (no diff-scoping applied).

## Empirical Motivation

F-024 PR #306 measured ~80 minutes cumulative CI runtime across 5+ lint cycles on a typical feature iteration with governance additions. Primary bottleneck: full-repository markdownlint (docs/spec trees) + full PSScriptAnalyzer (scripts/ + extensions/ trees) + full governance validation (44+ closed iterations). Typical lint job runs ~15 minutes; optimized PR scoping target <1 minute, unblocking faster developer feedback cycles.
