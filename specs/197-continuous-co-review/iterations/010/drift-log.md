# Drift Log: Iteration 010

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 2 (1 governance-tooling; 1 implementation-vs-requirement), plus 1 carried-finding closure (D-197-I009-003 refuted-with-evidence)
**Resolution rate**: 100% (2/2 resolved; 1/1 carried finding closed)
**Specification drift**: None detected (D-002 was implementation drift against the standing host-neutrality requirement)

## Events

### D-197-I010-001 — Boundary-cursor null-history mis-captured the plan-boundary verdict (recurrence of the 142/193 defect)

**Status**: RESOLVED (locally reconciled 2026-07-01); durable fix remains deferred to Proposals 142/193.
**Detected by**: the design-analysis → plan boundary sync (2026-07-01). `boundary_enforcement.verdict_history` in `.specrew/start-context.json` was empty and `last_authorized_boundary` was `null` — the feature ran iterations 001–009 + a 0.39.0-beta1 release without the boundary cursor ever being maintained. The sync therefore computed `Multi-boundary gap: true` and asked to authorize the earliest uncrossed boundary (`intake -> specify`); the Stop-hook verdict-capture then recorded the maintainer's "confirm" as `approved for specify` (misattribution) and advanced the cursor one bogus step.

**Impact**: the machinery would otherwise walk one bogus re-approval per boundary (`specify -> clarify -> plan -> ...`) for a feature whose boundaries were long since traversed — governance theater, and a misattribution of the human's intent (the "confirm" meant "reconcile and proceed to plan", not "approve specify").

**Resolution (maintainer-confirmed "reconcile and proceed", 2026-07-01)**: reconciled `.specrew/start-context.json` (gitignored runtime state) to the true position — `last_authorized_boundary: plan`, `pending_next_boundary: tasks`, and a corrected `verdict_history` entry recording the real `approved for plan with Option A` verdict (auth commit `ab1b516b`, the iter-010 design-analysis Human Decision). Removed the stale `intake -> specify` `pending-verdict-stop.md`. This is the same defect class as D-197-I009-008; the durable, multi-machine cursor fix stays deferred to **Proposals 142/193** (a separate feature after F-197).

**Trace**: governance state-truth (boundary cursor); D-197-I009-008; Proposals 142/193. Not a spec/implementation drift.

### D-197-I010-002 — Reviewer-host names hardcoded in the CCR core (host-neutrality violation)

**Status**: RESOLVED (fixed 2026-07-08, same-day as detection).
**Detected by**: the maintainer's code review during iter-010 execution (2026-07-08): "the worktree reviewer is not host-agnostic — harness specifics (claude, codex, copilot, …) must come from the host-specific code; the core stays AI-host-free."

**Finding (against FR-016/SC-022 host-neutrality; `reviewer-host-catalog.ps1` is the ONLY sanctioned host-data seam)**:

- `reviewer-selection-policy.ps1` hardcoded a `claude↔codex` independence-preference pairing in core policy.
- `worktree-reviewer.ps1` `Get-ContinuousCoReviewAgentCommand` silently fell back to a hardcoded `claude -p --permission-mode bypassPermissions` invocation when the catalog could not load — a wrong-host run instead of a loud failure.
- `worktree-reviewer.ps1` core invocation functions defaulted `-HostName 'claude'`.
- `co-review-service.ps1` ask-path defaulted to `'claude'` when no reviewer host resolved.
- `continuous-co-review-navigator.ps1` core-emitted guidance prose hardcoded `--host codex … (or claude/copilot)`.

**Resolution (implementation-reverted-to-requirement)**: the independence preference is now catalog-derived (strongest eligible candidate on a DIFFERENT harness than the code-writer — any host, including future ones); the catalog-unreachable fallback THROWS (surfaced as a failed run, never a silent wrong-host review); `-HostName` is mandatory at the core invocation seams; the ask-path fails soft with `no-authorized-reviewer-host`; guidance prose is host-neutral. A host-neutrality guard test (`tests/continuous-co-review/governance/host-neutral-core.Tests.ps1`) scans the CCR core for lowercase harness-name literals outside the catalog so the class cannot regress.

**Trace**: FR-016, SC-022, SEC-004 (independence policy); maintainer directive 2026-07-08.

### D-197-I009-003 closure — conformance flush/read race REFUTED with evidence (T109)

**Status**: CLOSED (refuted-with-evidence, 2026-07-08; per the design N7 either/or and the maintainer-approved default).
**Evidence**: the forensic on the REAL self-host corpus — 21 journal records (8 stop-blocks, 2026-06-29 → 2026-07-08, dx instrumentation live throughout): zero stale/unreadable reads; every `packet-absent` block read a genuinely packet-less message; the only packet-present blocks are marker-mismatch enforcement under the separately-tracked D-197-I010-001 cursor defect; the 2026-07-08 event is first-party witnessed end-to-end (legit block → packet rendered → next stop passed). Full analysis: `specs/197-continuous-co-review/iterations/010/quality/flush-race-forensic.md`. The permanent analyzer (`tests/continuous-co-review/unit/flush-race-forensic.Tests.ps1`) fails-and-reopens if the signature ever appears; no mitigation re-added (the T099 material-turn gate bounds the parse cost regardless).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
