# Drift Log: Iteration 002

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

**Total drift events**: 1
**Resolution rate**: 0% (0/1 resolved — awaiting human decision)
**Specification drift**: Plan-vs-tasks decomposition divergence (DR-002-001)

## Events

### DR-002-001 — Iteration-002 plan re-decomposed against a misread tasks.md

- **Type**: plan-vs-tasks divergence (governing-artifact contradiction).
- **Requirement citation**: the authoritative `specs/200-devin-cli-host/tasks.md`
  (approved at the tasks boundary) decomposes the feature into T001-T017 across
  THREE iterations. Its **Iteration 002 = T007-T011, 15/20 SP** (T007 package
  skeleton FR-005/006/010; T008 five handlers FR-007/008/016/018; T009 the single
  host-neutral hook seam FR-003/009/016/018; T010 ATIF normalizer + Stop
  enrichment + redaction FR-011/012/017; T011 pwsh Windows hook attempt +
  pinned-CLI validation + iter-002 regression FR-006/009/018/021). Iteration 003 =
  T012-T017 (coordinator migration, compat, promotion, docs).
- **What happened**: `iterations/002/plan.md` (this iteration's plan) was authored
  from a fresh planner-agent decomposition that IGNORED the authoritative tasks.md,
  inventing a conflicting numbering (T007-T015) and an unnecessary 4-iteration
  split (Slice C -> iter-002/003, Slice D -> iter-004). The canonical iter-002 is
  only 15 SP and needs NO split.
- **Root cause**: the coordinator misread tasks.md as empty of tasks — checked it
  with a markdown-table pattern (`^\| T`) that returned 0, but tasks.md uses the
  `- [ ] T###` checklist format — and instructed the planner to decompose from
  scratch.
- **Impact on built work** (code is reviewer-PASS; the issue is labels + scope):
  commits map to canonical IDs as: my "T007 skeleton" = canonical **T007** (same);
  my "T010 handlers" + "T011 surfaces" = canonical **T008**; my "T012 hook seam" =
  canonical **T009** (reviewer-confirmed substance); my "T008 normalizer" + "T009
  collision guard" = canonical **T010** (partial — Stop enrichment, `.specrew/
  runtime` atomic writes, Unicode/boundary-packet canaries, and FR-017 redaction
  are NOT yet done). Canonical **T011** (pwsh Windows attempt + pinned-CLI
  validation + iter-002 regression evidence) is NOT done — I had deferred it to
  "iter-003," which conflicts with the canonical plan.
- **Tension to resolve**: the human's before-implement instruction ("no live host
  in iter-002; defer live to iter-003") aligns with my re-plan but CONFLICTS with
  canonical T011, which places the pwsh attempt + pinned-CLI validation in
  iter-002.
- **Resolution**: `human-decision` — escalated to Alon. Options: (A) realign to
  canonical tasks.md (iter-002 = T007-T011, 15 SP, incl. the pwsh attempt; finish
  canonical T010 + T011; full promotion stays iter-003 T016), or (B) re-baseline
  tasks.md to formalize the deferral (iter-002 deterministic-only, push T011 live
  work to iter-003), updating tasks.md + capacity. Pending the decision, no
  further task commits; the verified hook-seam change stays uncommitted.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
