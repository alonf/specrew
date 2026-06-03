# Proposal 145 Structured Review — Unix Resolver Sidecar Hardening, Iteration 001

**Feature**: 160-unix-resolver-sidecar-hardening · **Iteration**: 001 · **Branch**: `160-unix-resolver-sidecar-hardening`
**Date**: 2026-06-03 · **Reviewer**: Crew Reviewer (claude), single-agent sequential phase execution
**Method**: Proposal 145 7-phase structured review, run before review-signoff at the maintainer's direction.
**Scope reviewed**: Iteration 001 (T001–T018) across commits `7ab7e6e9` (before-implement), `645f3f2a`
(repro-first evidence), `b460f2d5` (fixes), `5dc50c06` (review artifacts), plus the in-review remediations
recorded below.

## Per-phase synthesis

### Phase 0 — Context load → `pass`

Loaded: `spec.md` (FR-001..010, TG-001..005, SC-001..005 + 2026-06-03 clarify), feature `plan.md`
(Phase 1 + Phase 2 quality planning), `tasks.md` (18 tasks, 19.5/20 SP), iteration `plan.md`,
`hardening-gate.md` (ready; 4 addressed + 1 not-applicable), `investigation-evidence.md`, `drift-log.md`
(D-001/D-002), Proposals 160 + 161 (the source suspicions), `review.md`, CHANGELOG diff, and the
mechanical-findings output. Gap found and closed during this phase: the plan's required quality gates
pointed at `quality/quality-evidence.md` + `quality/lenses/*` which had never been written — all four
runtime-evidence files now exist with empirical content (not placeholders).

### Phase 1 — Branch hygiene → `pass`

- **Push status**: branch intentionally NOT pushed — explicit FR-010 requirement ("MUST NOT push");
  push belongs to feature-closeout per the PR-at-feature-close SDLC. Classified, not an oversight.
- **Main divergence**: `git merge-base HEAD main` == `main` tip (`953a16da`) — branched from current main,
  no divergence, no conflict topology.
- **Working tree**: every dirty file classified — pre-existing unrelated (`.claude/agents`,
  `.codex/agents`, `.cursor/`, `specs/140-.../tasks-progress.yml`) or sync-managed lifecycle state
  (`.specrew/*`, `.squad/*`). Zero F-160 implementation files uncommitted.
- **Shape-5 audit**: every file `review.md` cites is committed (`645f3f2a`/`b460f2d5`/`5dc50c06`); no
  working-tree-only evidence.
- **Boundary commit cadence**: 8 boundary commits (specify → review) with focused messages; honored.

### Phase 2 — Functional correctness → `pass`

- **Resolver fix traced**: all five candidate constructions (Path 0/1/2 + two `.specrew/config.yml`
  probes) replaced with multi-segment `Join-Path`; precedence (0→1→2) and the stale-install guard
  untouched (Proposal 160 non-goals honored). Behavioral proof: separator-safe form resolves a real
  nested file; Windows latency of the old form demonstrated; POSIX single-segment semantics proven
  host-independently.
- **Sidecar fix traced**: ordinal exact-match inserted after the marker check and the empty-content
  check, BEFORE the front-matter bail — the only position that recovers canonical-content dirs while
  preserving the front-matter heuristic for everything else. Missing-property edge (slash definitions
  carry no `LegacyContent`) guarded via `PSObject.Properties.Name`; null/empty canonical excluded.
- **Idempotency**: both surfaces are read-only decision logic; repeated invocation yields identical
  results (see `quality/quality-evidence.md` retry/idempotency section).

### Phase 3 — NFR / security → `pass`

- **Data-loss safety is the load-bearing control**: Case D (user-edited, no marker → preserved) passes
  before and after the fix; the fix can only classify byte-identical-to-canonical content as managed,
  which by definition contains no user customization. Ordinal comparison eliminates culture/case
  false-matches.
- **No new elevation, network, secret, or write paths**; fixtures confined to GUID-named temp dirs and
  removed in `finally`; no runtime-dir writes.
- **Conservative-preserve retained** for all ambiguous content (the safe failure direction).
- Cost/perf: one string comparison per legacy dir per definition — negligible. No UI/accessibility/i18n
  surface beyond the ordinal-comparison discipline.

### Phase 4 — Code quality → `pass`

- markdownlint clean across all iteration artifacts + CHANGELOG.
- PSScriptAnalyzer (Error + Warning) on both changed scripts: **0 errors; no new findings** — every
  warning (unapproved verbs, Write-Host, BOM, ShouldProcess, plural nouns) is a pre-existing pattern on
  lines the fixes did not touch.
- Fixes match the surrounding idiom (multi-segment `Join-Path` per Proposal 160's prescribed shape;
  `[System.StringComparison]::Ordinal` consistent with the classifier's existing comparisons).
- Source ↔ `.specify` mirror parity preserved for BOTH touched scripts; the sidecar test asserts the
  mirror carries the same fix fingerprint.
- No new dependencies (dependency-report: 0 changed / 0 new).

### Phase 5 — Test coverage + integrity → `pass` (two findings found AND fixed during this review)

- **FR→test mapping**: FR-002/FR-004 → resolver test (semantic + behavioral + source-regression
  sections); FR-005/FR-006/FR-008 → sidecar fixture (Cases A/B/C/D + parity); FR-001/FR-009 →
  evidence ordering in git history; FR-003/FR-007 → source diffs gated by T009.
- **Repro-first integrity**: failing-test commit (`645f3f2a`) precedes fix commit (`b460f2d5`);
  pre-fix failures were exactly the bug-demonstrating assertions.
- **145-catch #1 — CI wiring gap (the F-140 lesson, recurring)**: both new tests existed but were wired
  into NO CI lane (this repo enumerates tests explicitly). **Fixed in-review**: both added to
  `specrew-ci.yml` deterministic-gate (ubuntu-latest), which also discharges Proposal 160 AC4's Ubuntu
  lane — the resolver test's POSIX branch now executes on real Linux. macOS lane remains follow-up scope.
- **145-catch #2 — the tests themselves carried the anti-pattern under test**: both test files built
  their own repo paths with embedded-backslash ChildPaths and would have failed on the Ubuntu lane
  exactly the way the bug under investigation does. **Fixed in-review** (multi-segment `Join-Path`);
  both tests re-run green on Windows post-fix.
- **Honest coverage boundaries** (recorded, not hidden): marker CREATION verified by inspection of the
  active deploy loop + exercising the marker-content helper (the classifier — the suspected surface —
  is what the fixture executes; the plan's full-lifecycle escalation clause was not triggered); the
  resolver source-regression assertion covers the two known literal shapes, not every conceivable future
  backslash literal (general guard = recommended follow-up CI lint).
- **Producer/consumer demonstration**: the FIXED wrapper executed a complete real boundary-sync on
  Windows (identical-boundary re-sync → `success:true`) — the consumer path is proven, not assumed.

### Phase 6 — System safety / ops → `pass`

- **Backward compatibility**: Windows resolver behavior byte-equivalent (multi-segment `Join-Path`
  produces identical strings; proven behaviorally + by live sync). The sidecar change widens removal
  eligibility ONLY for legacy dirs byte-identical to canonical content — the single intended behavior
  delta, documented in CHANGELOG `Unreleased`.
- **Rollback**: every change sits in revertable, focused commits; nothing pushed, nothing published
  (beta-before-stable mandate untouched; publish is a later explicit activity).
- **Failure modes**: resolver miss still produces the actionable three-option throw; stale-install
  guard intact; classifier ambiguity still preserves.
- **Multi-dev collision**: shared-surface signal exists repo-wide (3 authors / 23 branches), but the
  touched scripts had no concurrent in-flight edits on this branch's diff range.

## Phase 7 — Synthesis

```yaml
verdict:
  per_phase: { phase_0: pass, phase_1: pass, phase_2: pass, phase_3: pass, phase_4: pass, phase_5: pass, phase_6: pass }
  overall: APPROVE for review-signoff
```

## Runtime-proof classification — deterministic + Ubuntu-CI-wired, no live-host Unix run yet

Per the ratified clarify decision, Unix semantics are proven by deterministic host-independent
assertions (POSIX `/`-separator interpretation) rather than a live Unix host, which this workspace does
not have. The structured review upgraded that posture: the resolver test now runs on the Ubuntu
deterministic-gate lane, so the first CI run of this branch executes the POSIX branch on real Linux.
That CI run has NOT happened yet (the branch is unpushed by FR-010 design) — it will execute when the
branch is pushed at feature-closeout. This is a classified, visible deferral, not a hidden gap.

## Honesty ledger (carried from review.md, unchanged by this structured pass)

- Finding 2 is a **classifier-mechanism** confirmation; the fix covers byte-current canonical content;
  marker-less legacy dirs carrying OLD canonical content remain conservatively preserved; real-world harm
  reachability is uncertain. Keep / expand / revert stays the maintainer's decision at signoff.
- The embedded-backslash pattern is codebase-wide (~105 occurrences / 18 production scripts incl. a
  sibling resolver in `validate-governance.ps1`); F-160 fixed only the Proposal-160-scoped boundary-sync
  resolver. Follow-up proposal recommended (sweep + CI lint).

## Verdict: **APPROVE for review-signoff**

All seven phases pass. The structured review materially improved the iteration before signoff: it found
and fixed the CI-wiring gap and the tests' own path-portability defect, and completed the missing
quality-evidence/lens runtime artifacts. The maintainer's review-signoff remains the boundary authority.
