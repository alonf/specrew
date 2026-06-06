# Process Quality Scoring

## Purpose

Turn iteration lifecycle artifacts into a lightweight, reviewable process-quality score without waiting for the full end-to-end harness.

## Reusable Pattern

1. Resolve iteration directories from `specs/*/iterations/*`.
2. Read `plan.md` first and treat `**Status**:` as the phase source of truth.
3. Build an expected-artifact matrix from the lifecycle contract:
   - planning → `plan.md`
   - executing → `plan.md`, `state.md`, `drift-log.md`
   - reviewing → add `review.md`
   - retro / complete → add `retro.md`
4. Score **artifact adherence** by checking required artifact presence.
5. Score **phase adherence** by flagging status/artifact contradictions (for example `review.md` during `planning`, or `complete` without `retro.md`).
6. Return structured output first; layer human-readable report formatting later.
7. When adding a Markdown report before the full harness exists, render the current process metrics plainly and mark outcome or later-slice criteria as **Deferred** instead of inventing placeholder scores.
8. Treat `test-results\process-quality-report.md` as an on-demand generated artifact unless the contract explicitly requires another report path; review the writer path by invoking `tests\support\process-quality-scorer.ps1 -WriteReport` and then inspect the rendered Markdown for the required sections.
9. For closeout reviews, run the scorer after creating `review.md` or `retro.md`; it will catch stale iteration status/artifact combinations (for example `retro.md` existing while `plan.md` still says `executing`) even when other validators stay green.

## When To Reuse

- Iteration governance audits
- Early process-quality scoring slices
- CI-friendly lifecycle scoring before report generation exists
- Process-slice report generation where the full FR-015 outcome scorer is still deferred
