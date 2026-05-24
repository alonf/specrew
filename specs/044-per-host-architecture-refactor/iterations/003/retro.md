# Iteration 003 Retro

**Feature**: F-044 | **Iteration**: 003 | **Date**: 2026-05-24

## What went well

- **Manual dogfood caught 5 real bugs the 4-agent automated deep review missed**. The deep review at iter-001 close found 22 issues but none of these 5. That's because the 4 agents had read access only — they couldn't actually RUN `specrew init` and watch the skills load, or read the bootstrap message, or scaffold a hardening gate from an empty file. **Manual run is a strictly stronger review boundary than agent-read review.** Worth formalizing in the methodology (and is exactly what Proposal 042 Specrew Integration Test Suite is trying to formalize).
- **Root causes traceable to single files for each bug.** No hidden coupling, no fix-here-breaks-there. iter-003 closes in one commit because the bugs were genuinely independent.
- **Bug 7a turned out to be a stale-install false positive.** Verifying first (reading the actual code on branch) before "fixing" saved a wasted commit.
- **The dual-iteration-fix-slice methodology pattern is now established.** iter-001 architectural ship + iter-002 deep-review cleanup + iter-003 manual-test cleanup. Each demonstrates a different review boundary working as intended.

## What went poorly

- **The user wasted significant time + tokens on a stale install** (dual-module-load: 0.24.1 PSGallery + 0.26.0 Dev tree). The `specrew update` UX needs to fix this — auto-detect stale installs and prompt/upgrade. Captured as a candidate follow-up.
- **Copilot ran the user out of weekly quota during testing.** This isn't a Specrew bug per se, but the methodology trial cost real money. Proposal 068 (Cost-Aware Model Routing) becomes more urgent every test cycle that burns tokens without measurable progress.
- **Three of the methodology gaps (Bugs 3, 4, 6) are NOT something iter-003 can fix.** They're standing proposals (063, 065, 024 Category D). The user encountered them as bugs, not as deferred-work; need to make sure they understand these are tracked and not forgotten.
- **No automated tests added for the 5 fixes.** Each fix has a reproduction scenario but the scenarios live in `scope.md` + `review.md`, not in CI. If iter-004's manual test passes, queue an iter-005 (or post-feature-close small-fix slice) to add automated tests.
- **The "scaffold-iteration-plan.ps1 emits Phase Baseline / agent-written plans don't" gap is a contract drift.** iter-003 fixed the retro side (graceful tolerance) but the deeper fix is a single canonical iteration-plan template that agents are mandated to use. That's Proposal 035 (Session-State Durability) adjacent.

## Lessons + queued action items

1. **Manual dogfood IS a review boundary**, not a "user smoke check". The methodology should encode this — at minimum after substantial architectural work like F-044 — by requiring at least one manual end-to-end before feature-closeout. Captures empirically what we've seen across F-043/044 + F-019/F-024 incidents.
2. **Stale-install detection in `specrew update`**: the dual-module-load symptom is too subtle for users to notice in test output. The CLI should refuse to run silently against a stale install OR loudly print which version is actually executing.
3. **Bug 7e (Copilot 3 skills failed) remains under-investigated.** Queue follow-up to reproduce against the latest Copilot CLI version and identify the other 2 skills.
4. **Tier B (interactive `specrew start` menu) and Tier C (methodology depth) are queued correctly** but the user should see them surface in `proposals/INDEX.md` so they don't disappear.
5. **Bug 5 (Squad-hardcoded message) was a clear F-044 closeout gap.** The work shipped 4 host runtimes but left the bootstrap message Copilot-default. Capture in the F-044 deferred-work pattern: "every refactor that adds a new host needs a sweep of user-facing strings."

## Action items queued

| Item | Vehicle | When |
|---|---|---|
| Automated tests for 5 iter-003 fixes (especially bootstrap output content + hardening-gate first-run + retro Phase Baseline absent) | Small-fix slice OR iter-005 | After iter-004 manual verification passes |
| `specrew update` dual-install detection | Small-fix slice; OR fold into Proposal 060 (Prerelease Channel + Module Hygiene) | Post-F-044 closeout |
| Copilot 3-skill-failure investigation (Bug 7e) | Small-fix slice when Copilot quota refills | Post-F-044 closeout |
| Bug 1 interactive `--host` menu | Small-fix slice OR Proposal 063 | When user revisits |
| Surface Tier B/C deferrals in `proposals/INDEX.md` | On-main chore commit | Post-PR-to-main |

## Honest framing for the reader

iter-003 closes 5 of 6 Tier A bugs caught by the first real multi-host dogfood. The 6th was a stale-install false positive. The bigger lesson is that **the manual dogfood is the gold standard for Specrew's review boundary** — it caught things the 4-agent deep review couldn't see. Worth formalizing in the methodology.
