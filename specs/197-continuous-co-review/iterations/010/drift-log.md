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

**Total drift events**: 4 (1 governance-tooling; 2 implementation-vs-requirement; 1 doc/test-vs-doctrine), plus 1 carried-finding closure (D-197-I009-003 refuted-with-evidence)
**Resolution rate**: 100% (4/4 resolved; 1/1 carried finding closed)
**Specification drift**: None detected (D-002 was implementation drift against the standing host-neutrality requirement; D-003 was documentation/test drift against decisions this iteration itself made; D-004 was implementation drift against FR-025 found by the feature's own reviewer)

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

### D-197-I010-003 — Teaching docs and integration tests lagged this iteration's own doctrine decisions (co-review verification round)

**Status**: RESOLVED (fixed 2026-07-08, same day; caught by the continuous co-review verification run `20260708T115526673` — the feature under review found the drift in its own iteration artifacts).
**Detected by**: the antigravity worktree reviewer (3 blocking + 2 advisory findings), verifying the escalation-repair fix batch.

**Findings and resolutions (all doc/test drift against decisions already made THIS iteration — D-197-I010-002 host-neutrality and the P1 baseline-anchoring doctrine):**

- `extensions/specrew-speckit/refocus/review-signoff.md` had drifted from its `.specify` mirror, and both still taught `--live --baseline-ref <committed-baseline>` — contradicting the P1 doctrine (a signoff run auto-anchors to the feature merge-base; an explicit `--baseline-ref` run is EXPLORATORY and never signoff evidence). **Resolved**: item 4 rewritten to teach `--live` with the baseline omitted, naming the three durable evidence artifacts; source and mirror re-synced; the same stale teaching swept out of 8 charter/ceremony/reviewer-agent files and the 6 deployed SKILL.md copies.
- `extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md` (and mirror) still described a hardcoded `claude↔codex` reviewer pairing; `tests/integration/review-signoff-live-wiring.tests.ps1` asserted regexes pinned to the OLD wording (pre-`Codex + ChatGPT`, explicit rank numbers). **Resolved**: the lens now states the host-neutral rule (strongest eligible reviewer on a DIFFERENT harness than the code-writer, same-host fallback fired immediately and labelled); the test regexes now assert the current doctrine wording, including the literal `DIFFERENT harness than the code-writer`.
- `tests/integration/review-command.ps1` Test 5 still drove the deleted pre-worktree-cutover fixture pipeline (`--host fixture` expecting exit 0 + the legacy artifact set). **Resolved**: rewritten to assert the CURRENT contract — an unregistered `--host` fails loudly with `requested-host-not-available` and writes no gate evidence (honour-or-surface, never substitute).
- (Advisory) `tasks-progress.yml` carried fabricated completion timestamps lying in the future of the review run's start. **Resolved**: all task `started_at`/`completed_at` values replaced with the real boundary/commit-derived times from git history; recorded here as an honesty correction — progress artifacts must carry disk/git truth, never narrative-convenient times.
- (Advisory) these drifts were initially unrecorded in this drift-log. **Resolved**: this entry.

**Trace**: P1 baseline-anchoring doctrine (iter-010 design); D-197-I010-002; T093 honour-or-surface; Rule "Honest state". Strategy: implementation-reverted-to-requirement (docs/tests corrected to the decided doctrine).

### D-197-I010-004 — Reviewed identity ≠ certified identity: worktree materialized HEAD while the gate digested the working tree (FR-025 false-allow vector)

**Status**: RESOLVED (fixed 2026-07-09, same session; maintainer fix-now decision "1" on the round-ceiling escalation).
**Detected by**: the feature's own reviewer — antigravity run `20260708T211331029` (round-5 escalation, 141s, the FIRST run consuming T111 implementer evidence): "the worktree reviewer still materializes and diffs HEAD rather than the same current-state tree identity used by the reviewed-state digest… This allows uncommitted changes to bypass review while recording the working tree's digest as reviewed."

**Finding (verified against source before fixing)**: `New-ContinuousCoReviewStrippedWorktree` archived `HEAD^{tree}` while `Get-ContinuousCoReviewReviewedStateDigest` (the gate's freshness identity) is `git write-tree` over the WORKING tree. With uncommitted changes present, the reviewer reviewed HEAD but the run recorded the working-tree digest — un-reviewed content could be certified as reviewed. Exploit requires a DIRTY tree at run time; every boundary-evidence run this iteration ran on a clean tree (HEAD == working tree), so no existing evidence was tainted.

**Resolution (implementation-reverted-to-requirement)**: the orchestrator now computes the digest FIRST and materializes the worktree FROM the digest's own tree object (`-SourceTreeId`; the digest tree is a real `git write-tree` object, so `git archive` serves it directly) — the reviewed content and the certified content are the SAME git tree by construction, and `.review/changes.diff` runs baseline→that tree. Digest failure falls back to HEAD with `reviewed_digest_error` carrying why the identities may differ. Bonus: `specrew review --live` now genuinely reviews uncommitted work. Regression tests: `worktree-source-tree-identity.Tests.ps1` (dirty-tree content present in the worktree + materialized tree id EQUALS the certified digest id; HEAD fallback preserved). Full CCR suite 254/254.

**Trace**: FR-025 (unreviewed-source false-allow — the same class the digest strip-list rules guard); SC-019/SC-020 (gate evidence integrity); escalation run `20260708T211331029`; maintainer decision DEC-197-I010-005.

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
