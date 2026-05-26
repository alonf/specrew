# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-05-26
**Completed At**: 2026-05-26T10:30:39Z
**Overall Outcome**: accepted; scope delivered; no open FR/SC gaps

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1 | 1 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 1 | 1 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 1 | 1 | 0 |
| T006 | 1 | 1 | 0 |
| T007 | 1 | 1 | 0 |
| T008 | 1 | 1 | 0 |
| T009 | 1 | 1 | 0 |
| T010 | 1 | 1 | 0 |
| T011 | 1 | 1 | 0 |
| T012 | 1 | 1 | 0 |
| T013 | 1 | 1 | 0 |
| T014 | 1 | 1 | 0 |
| T015 | 1 | 1 | 0 |
| T016 | 1 | 1 | 0 |
| T017 | 1 | 1 | 0 |
| T018 | 1 | 1 | 0 |
| T019 | 1 | 1 | 0 |

**Average variance**: 0 SP. **Capacity utilization**: 20/20 SP planned, 20/20 SP delivered.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0 | 0 | 0 | Existing plan and pre-implementation artifacts were already approved before this continuation. |
| Discovery/Spikes | 0 | 0 | 0 | No spike was needed; F-046 and F-047 findings supplied the empirical basis. |
| Implementation | 17 | 17 | 0 | WARN-only validators, scaffolder hardening, prompts, skill-root detection, task-progress reconciliation, version bump, and tests all landed inside the planned slice. |
| Review | 3 | 3 | 0 | Review packet was authored, accepted, validated, and committed before review-signoff approval. |
| Rework | 0 | 0 | 0 | One review-state metadata correction was caught by regression tests and fixed inside review overhead. |

## Drift Summary

- Total requirement drift events: 0
- Total process-level gaps: 0 open
- Resolved via spec update: 0
- Resolved via implementation correction: 1 review-state metadata correction
- Deferred: 0
- Escalated to human decision: 1 review-signoff approval, recorded before retro

## What Went Well

- Scope discipline held. The iteration delivered the seven trust-hardening findings in [findings.md](../../findings.md) without expanding into the larger verdict-history atomic refactor.
- The review gate was not bypassed. [review.md](review.md) was authored, accepted, committed, validated, and then explicitly approved by Alon Fliess before this retro started.
- The implementation converted several F-046/F-047 forensic-only gaps into observable WARN signals: missing handoff blocks, post-compaction handoff drops, wrong-location canonical artifacts, missing Mermaid diagrams, handoff internal references, dashboard diagnosis ambiguity, empty skill roots, and stale task-progress regeneration.
- Regression discipline was useful in practice. `substantive-interaction-model-handoff-test.ps1` caught the invalid `Current Phase: review` value before the review boundary closed; the fix was to use canonical `review-signoff` while keeping iteration status `reviewing`.
- Mirror parity and release discipline held. Modified extension scripts were byte-identical across `extensions/` and `.specify/extensions/`, and v0.27.3 was recorded across manifests, README, and CHANGELOG.

## What Didn't Go Well

### Boundary-sync ergonomics are still semantically sharp

F-047 had to call `sync-boundary-state.ps1` directly because this host is in `bootstrap_only` runtime mode. The tool is mechanically usable, but the review/review-signoff distinction remains easy to misapply: calling review sync while already at `review-signoff` logged expected-next-boundary warnings. The audit trail was preserved, but the operator experience is still too easy to make noisy.

### Scaffolders still create pending drafts during interrupted runs

The retro scaffolder timed out after producing [retro.md](retro.md), and also emitted `.pending` reviewer artifacts. This is correct preservation behavior after F-046 Bug 3, but the console experience looked like a hung operation and required cleanup of generated pending drafts. The preservation semantics are right; the script needs clearer bounded output or faster early-exit behavior.

### Session-state prompts lagged the true feature state

[last-start-prompt.md](file:///C:/Dev/Specrew/.specrew/last-start-prompt.md) still carried stale "Welcome Back Snapshot" details saying the current boundary was `specify` and task progress was pending, even though frontmatter and [start-context.json](file:///C:/Dev/Specrew/.specrew/start-context.json) correctly showed `review-signoff`. F-047 fixed task-progress regeneration, but the prompt summary layer still has a stale-derived-summary risk.

### The authorization cursor remains a known follow-up

The F-047 findings ledger records cross-feature authorization-cursor bleed as out of scope. This iteration handled the human approval operationally, but did not solve the larger global-vs-feature-scoped authorization model. That should remain a separate small-fix slice, not be hidden as "done" by v0.27.3.

## Bug-Class Pattern Analysis Across F-046 and F-047

Yes, the same classes are recurring. The common root is not "bad markdown" or "bad prompts"; it is weak coupling between lifecycle intent, host behavior, and durable evidence.

| Pattern | F-046 Signal | F-047 Signal | Classification |
| ------- | ------------ | ------------ | -------------- |
| Form-vs-meaning gaps | Boundary commits existed, but review/retro/closeout substance and human verdicts were missing or retroactive. | Handoff blocks, Mermaid diagrams, dashboards, and task progress could appear structurally present while missing the semantic evidence users needed. | Same class. Artifacts must prove meaning, not just satisfy shape. |
| Agent prose-discipline drops | Antigravity skipped handoff blocks and produced ambiguous pause narration. | F-047 added handoff-block presence checks and internal-reference WARNs, but these remain WARN-level, not runtime-enforced. | Same class, partially mitigated. |
| Host inconsistency | Antigravity skipped gates and missed PR-at-feature-close actions while Codex in adjacent work respected them. | F-047 embedded closeout SDLC actions in templates and tests, reducing host memory dependence. | Same class, mitigated at prompt/template level only. |
| Session-resume divergence | F-046 resume showed stale task/state behavior and empty skill-root contradiction. | F-047 made task progress derive from `tasks.md` and empty skill roots count as missing, but prompt snapshot staleness remains. | Same class, partially fixed. |
| Canonical artifact location drift | F-046 wrote walkthrough content into an ephemeral host-brain folder. | F-047 added wrong-location canonical artifact WARNs for host scratch directories. | Same class, now observable. |

The actionable conclusion: F-046 was primarily a bypass/recovery incident; F-047 was the first trust-hardening pass that turns those incidents into repeatable detection. The remaining work should focus on enforcement and state coherence, not more prose. Host-native hooks, feature-scoped authorization records, and single-source prompt summaries are the next reliability layer.

## Improvement Actions

1. **Owner**: Planner / Spec Steward | **Phase**: next small-fix planning | **Type**: architecture | **Expected effect**: Split the verdict-history atomic/refactor work into a narrow feature-scoped authorization model. Do not mix it with prompt or template cleanup.
2. **Owner**: Implementer | **Phase**: next lifecycle-tooling iteration | **Type**: validation | **Expected effect**: Add a stale-prompt-summary detector that compares [last-start-prompt.md](file:///C:/Dev/Specrew/.specrew/last-start-prompt.md) summary fields against [start-context.json](file:///C:/Dev/Specrew/.specrew/start-context.json) and task-progress evidence.
3. **Owner**: Implementer | **Phase**: next scaffold hardening slice | **Type**: ergonomics | **Expected effect**: Make scaffolders print explicit "preserved existing artifact; wrote .pending" summaries quickly and avoid timeout-shaped operator ambiguity.
4. **Owner**: Host adapter / Proposal 105 slice | **Phase**: future runtime-enforcement work | **Type**: enforcement | **Expected effect**: Convert human-approval gate compliance from cooperative prose into host-native checks around `boundary(` commits and boundary-sync calls.
5. **Owner**: Reviewer | **Phase**: every future bug-bash | **Type**: process | **Expected effect**: Keep the F-046/F-047 findings-ledger pattern as the canonical way to group three or more empirical defects into a scoped bug-bash iteration.

## Calibration Suggestion

- **Suggested capacity adjustment for next iteration**: keep 20 SP.
- **Rationale**: The iteration used the full 20 SP capacity with no task variance and no open rework. The work was bounded correctly; the remaining risks are follow-up architecture and host-runtime enforcement, not a capacity-estimation problem.

## Signals For Next Iteration

- Treat F-046 and F-047 as one empirical cluster: lifecycle trust failures recur when host behavior, artifact shape, and durable state are allowed to drift independently.
- Prefer small, testable slices for the remaining work: feature-scoped authorization, prompt-summary freshness, scaffolder operator feedback, and host-native boundary hooks.
- Keep hardening checks WARN-only unless the feature explicitly scopes a compatibility-breaking enforcement change.
