# Workshop Record: code-implementation (light, auto-on)

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Confirmation**: human-confirmed ("Inherit as presented")

## Source of code-rules truth

The product-level baseline: F-197's `implementation-rules.yml` (44 catalog
rules resolved for `powershell-markdown-yaml-json`) + repo doctrine. No
external guideline or example-project ingestion. F-198 introduces no new
language, stack, or dependency — the Spec-Kit 0.12.9 / Squad 0.11.0 bumps are
version updates of existing dependencies (decided at integration-api I2).

## Inheritance decision

Inherit the full checked baseline with decision texts re-anchored to F-198's
surfaces; exceptions unchanged and still true (`evidence-driven-performance`,
`collection-query-semantics`, `pagination-delivery`,
`messaging-event-processing`, `cache-boundaries`).

F-197's feature-scoped custom rules retire; F-198 binds six custom rules:

1. **provider-mirror-parity** — every extension script change syncs its
   `.specify` mirror in the same commit.
2. **psd1-filelist** — every new shipped file joins Specrew.psd1 FileList in
   the commit that creates it.
3. **born-clean** — every touched template/prompt/skill/refocus surface
   passes SelfLeakLintLane from its first commit (205-W1 lands first).
4. **scratch-probes-only** — agentic/init CLI probes in scratch dirs only,
   never a governed cwd.
5. **remote-main-sync** — merge/rebase latest remote main before each
   iteration's implement phase.
6. **paired-honesty-tests** — the NFR paired-test rule is a code-review
   enforcement item.

Dependency stance: `use-existing-no-new-dependency`.

Manifest: `specs/198-beta2-hardening/implementation-rules.yml` (validated
shape against the F-197 precedent).

## Iteration 005 rearchitecture reassessment — 2026-07-16

The maintainer retained this repository and manifest as the sole code-rules source and kept the resolved `powershell-markdown-yaml-json` stack with no new dependency. The full reassessment record is in the iteration workshop.

The existing baseline remains checked, with decisions re-anchored to the controlled external review architecture: pure state-machine policy; repository-only immutable `FileMode.CreateNew` authority facts; unique claim generations rather than generic locks/CAS; closed versioned request/result contracts; explicit target, harness, runtime, store, and clock adapters; no hidden provider retries; post-termination timeout-result publication; three-OS runtime fixtures; and one bounded live smoke for each supported harness.

The former `evidence-driven-performance` exception is removed. Performance is P1 below stability/integrity and now requires phase timing, preflight-before-spend, shared-object worktrees, bounded prompts, delta-assisted full-snapshot re-review, duplicate warnings, low-cost heartbeats, minimal hashing, and safe optional usage metrics.

The maintainer selected `claude` as the independent reviewer while Codex is the code-writer. The canonical authorization command succeeded with reference `workshop-198-beta2-hardening`; no model or effort is pinned.
