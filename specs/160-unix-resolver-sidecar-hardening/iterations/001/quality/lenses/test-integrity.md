# Lens Evidence: test-integrity@v1.0.0 — Iteration 001

**Verdict**: pass
**Recorded**: 2026-06-03

## Concern under review

The feature's core value is proof-before-fix: tests must reproduce the suspected
failure BEFORE any fix; after-the-fact tests that only prove the final
implementation violate the repro-first contract (FR-001/SC-002).

## Evidence

- **Repro-first ordering is in git history**: commit `645f3f2a`
  (`boundary(implement): repro-first evidence`) contains both test files FAILING
  against the live source (resolver: 4 source-regression assertions; sidecar:
  Case A generic + slash). The fix commit `b460f2d5` follows it. The evidence
  ordering is auditable, not asserted.
- **Tests fail for the right reason**: pre-fix failures were exactly the
  bug-demonstrating assertions (source embeds backslash ChildPaths; canonical
  content + no marker classified user-edited) — not incidental breakage.
- **Negative paths covered**: preserve-on-user-edited (Case D), legacy-signature
  fallback still recognized (Case C), marker-present (Case B), Windows-latent
  behavior documented (resolver Section 2 Windows branch).
- **Fixture realism**: the sidecar fixture AST-extracts the LIVE classifier from
  the source script and uses REAL definitions from the real template root — not a
  reimplementation; the resolver test creates real files and exercises real
  `Join-Path`/`Test-Path` semantics.
- **Honest coverage boundaries recorded**: marker CREATION in the active deploy
  loop is verified by code inspection (L591-600 always writes SKILL.md + marker)
  and by exercising `Get-ManagedSkillMarkerContent`; the full deploy loop itself
  is not executed by the fixture (direct deploy-logic fixtures sufficed; the
  plan's escalation clause was not triggered). The resolver source-regression
  assertion covers the two known literal shapes, not all conceivable future
  backslash literals — the general guard is the recommended follow-up CI lint.
- **Tests wired into CI**: both tests added to `specrew-ci.yml` deterministic-gate
  (ubuntu-latest), closing the F-140 "tests existed but never ran in CI" lesson
  and giving the resolver POSIX branch a real Unix execution.
