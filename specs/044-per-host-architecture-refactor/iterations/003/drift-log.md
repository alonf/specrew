# Iteration 003 Drift Log

**Feature**: F-044 | **Iteration**: 003

Drift = anything that diverged from the iter-003 manual-test-driven scope during implementation. Documenting drift honestly is required by Specrew's review-gate discipline (Proposal 073 Review Evidence Integrity).

## Drift #1 — Bug 7a turned out to be a stale-install false positive

- **Original assumption**: Bug 7a (Codex CLI rejecting `--full-auto` flag) was a real bug in `hosts/codex/handlers.ps1` flag-translation logic, requiring a code fix.
- **Investigation finding**: Read `hosts/codex/handlers.ps1:101` on the integration branch — the current code returns `--dangerously-bypass-approvals-and-sandbox` (correct flag), NOT `--full-auto`. The user's test output showed `--full-auto` because PowerShell loaded the user's stale `0.24.1` PSGallery install simultaneously with the Dev tree (dual-module-load visible in their `Get-Module Specrew` output).
- **Resolution**: No code change. Bug 7a marked as no-op in iter-003 scope. Captured the dual-install detection gap as a follow-up (queue against Proposal 060 small-fix slice).
- **Schema impact**: None.
- **User impact**: User must remove the stale `0.24.1` PSGallery install before iter-004 testing — otherwise the dual-load will continue to mask which version actually ran. Pre-test step documented in `review.md` § "Recommended user pre-test step".
- **Reviewer disposition**: Verified before fixing — saved a wasted commit on already-correct code.

## Deferred to standing proposals (not drift but recorded for traceability)

- **Bug 1** (interactive `--host` menu): UX improvement, not a Specrew tooling regression. → Small-fix slice OR fold into Proposal 063 (Substantive Intake Questioning).
- **Bug 3** (Codex stops in fewer places, no clarify questions): Host autopilot bypasses prose-based handoffs — requires tool-protocol layer fix. → Proposal 063 + Proposal 065 (Launch-Mode Boundary Enforcement).
- **Bug 4** (Claude finishes without closeout/iteration-approval menu): Same root cause as Bug 3. → Proposal 063 + Proposal 065.
- **Bug 6** (Only Squad shows concurrent per-mission agent dispatch; Claude/Codex run everything in one context): Per-host coordinator-overlay translation. → Proposal 024 Category D (already documented as out-of-scope in F-044 [spec.md](../../spec.md)).
- **Bug 7e** (Copilot "Failed to load 3 skills" — only `iteration-resume` was named): Needs reproduction against latest Copilot CLI. → Investigation slice.
- **Bug 8** (Copilot very slow / weekly quota exhausted): External — aligns with Proposal 068 (Cost-Aware Model Routing).
- **Dual-module-load detection** (0.24.1 + 0.26.0 simultaneously in `Get-Module Specrew`): `specrew update` UX should detect + warn. → Small-fix slice OR fold into Proposal 060 (Prerelease Channel + Module Hygiene).

## Cross-feature note

iter-003's scope is closing manual-test bugs. None of these bugs are F-043-attributable (F-043 closed cleanly modulo A-1 which was fixed in iter-002).
