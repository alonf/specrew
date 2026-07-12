# Drift Log: Iteration 003

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

**Total drift events**: 4
**Resolution rate**: 75% (3/4 resolved in place; DRIFT-198-I003-002 is a recorded
requirement bound to T019/T030–T032, realized there)
**Specification drift**: One implementation-vs-data-model divergence
(DRIFT-198-I003-001) in iteration-002's shipped FR-020 code, surfaced by
iteration-003 co-review and fixed in place with paired abuse tests. One
process/governance defect (DRIFT-198-I003-002): lifecycle verdict packets
were rendered during pending/blocking co-reviews — recorded as FR-045 and
bound to T019 + T030–T032. One docs-vs-shipped-design drift
(DRIFT-198-I003-003): T015's design surfaces bound "REQUIRED bounded
verification" after the option-1 decision (2026-07-11) had made it opt-in —
the authoritative docs are now aligned to the shipped design. One
implementation defect in the shipped T016 detector (DRIFT-198-I003-004): the
containment sampler tokenized the reviewer HOST's own prompt arg, so a codex
review whose prompt merely NAMED the origin path false-flagged as origin
access — caught by dogfooding the detector on its own increment, fixed in
place with a host-prompt-arg exemption + a regression test.

## Events

### DRIFT-198-I003-004 — T016 containment sampler tokenized the reviewer HOST's own prompt arg, false-flagging a real codex review as origin access (resolved: host-prompt-arg exemption + regression test)

- **Requirement citation**: FR-011 / SC-003 (the T016 containment-violation
  DETECTOR: cwd/command-line sampling, loud origin-side `containment-violated`);
  NFR-001 (no false result). The maintainer's T016 constraints (2026-07-12,
  bounded/redacted records; never mid-flight kill) are unaffected — this is a
  precision defect, not a hygiene or safety one.
- **Divergence (implementation defect, shipped this iteration)**: the reviewer
  HOST is launched as `codex exec "<prompt>"` — the review PROMPT is a positional
  command-line arg, and that prompt LEGITIMATELY names origin paths (the
  changed-file list, design-context refs, the project root itself). The sampler
  `Get-ContinuousCoReviewContainmentSamples` tokenized the host's ENTIRE command
  line, so an origin path MENTIONED in the prompt was recorded as origin ACCESS.
  The orchestrator's fail-loud path then failed a clean review with
  `failure_reason=containment-violated` and discarded its findings.
- **Detection (dogfood — the detector caught its own bug)**: the first serialized
  codex review OF the T016 increment (run `20260712T181010372-fpvalidate`) fired
  the new detector on `pid=… image=codex.exe source=arg path=C:\Dev\…` — the
  reviewer's own prompt-arg, not access. A true positive of a false-positive class.
- **Resolution (implementation-corrected, in place)**: arg-sampling is now SKIPPED
  for the reviewer HOST — the ROOT pid and any same-image worker — because the
  prompt lives in the host's args; `exe`-source is still sampled for the host (a
  host exe UNDER origin is still caught), and a NON-host descendant (git/rg/node)
  invoked with an origin path IS still arg-sampled (a real operation-target signal).
  The fail-CLOSED default keeps the ROOT pid arg-exempt even if its image can't be
  resolved (CIM/proc race). Added a paired sampler regression test
  (`worktree-containment.Tests.ps1`, HOST PROMPT-ARG EXEMPTION): host prompt-arg
  skipped, host exe kept, descendant git arg kept → exactly one violation (the
  descendant), never the host prompt.
- **Residual limitation (documented, accepted under MONITORED confinement)**: a
  host that reaches origin via a path in its OWN args is now caught only by
  exe/cwd; on Windows (no cheap cwd) that means exe-only for the host. The
  STRUCTURAL guarantee is unchanged — T013 materializes the reviewer worktree
  OUTSIDE origin (fail-closed), and T016 remains a best-effort monitor, not
  OS-enforced isolation.
- **Scope note**: no new requirement and no scope change — this REALIZES FR-011 at
  its intended precision (origin ACCESS, not origin MENTION); found and fixed in
  003 as field evidence of the value of dogfooding the detector on its own tree.

### DRIFT-198-I003-003 — T015 confinement contract: design surfaces bound "REQUIRED bounded verification" after the option-1 decision made it opt-in (resolved: docs aligned to the shipped design)

- **Requirement citation**: FR-010 (confinement contract), FR-013 (reviewer
  teaching); the 203-W3/W6 doctrine; NFR-001 (no false-green). The shipped
  `reviewer-spawn-contract.md` + the simplified orchestrator are the
  authoritative CODE surfaces.
- **Divergence (docs vs shipped design)**: T015's design bindings
  (design-analysis.md ConfinementContract component map + the code-implementation
  lens + the container diagram + the retro-lens reference) stated the confinement
  contract "REQUIRES the bounded in-worktree verification step", but the
  maintainer's option-1 decision (2026-07-11, state.md) REMOVED automatic
  per-review verification from the orchestrator (it could not be confined
  in-process - findings 4b124d0e / c9abe16d / bfc7b5c5) and kept the
  bounded-verification helper as an EXPLICIT opt-in API only. The design surfaces
  were not updated to match, and no drift event recorded the change.
- **Detection**: iteration-003 continuous co-review (run
  `20260712T171055717-fpvalidate`, ADVISORY process-design-drift) + maintainer
  instruction 2026-07-12.
- **Resolution (docs aligned to the shipped design, in place)**: every
  authoritative surface now states the approved design —

  1. automatic per-review verification was REMOVED;
  2. T018 owns the one-time runner-observed verification evidence;
  3. the bounded-verification helper is EXPLICIT opt-in only;
  4. reviewer confinement is MONITORED, not OS-enforced;
  5. reviewer-invocation integrity remains MANDATORY.

  Updated: design-analysis.md (ConfinementContract component map,
  code-implementation lens, container diagram, retro-lens reference), tasks.md
  T015, and `reviewer-spawn-contract.md` (already aligned). T015 is treated as
  complete only now that these records agree.
- **Scope note**: no new requirement and no scope change - this ALIGNS the design
  docs to a decision already shipped in code; the code was correct, the docs
  lagged.

### DRIFT-198-I003-002 — stop-ordering: verdict/decision packets rendered during a pending/blocking co-review (recorded → FR-045, bound to T019 + T030–T032)

- **Requirement citation**: NEW FR-045 (GOV-002, stop-ordering); relates to
  the never-false-green class of FR-041–FR-044 (capture integrity) and the
  reviewed-tree-digest binding of FR-016/FR-017 (T019). NFR-002 (a
  pre-verdict/blocked state must not remain authoritative).
- **Divergence (process, this iteration)**: during iteration-003 continuous
  co-review the assistant rendered user-facing decision/verdict-shaped
  packets (six-section re-entry packet + numbered approval-style options)
  while a required co-review was still pending/in-flight/BLOCKING, and
  before the review's reviewed-tree digest was accepted against the exact
  current tree (e.g. the T034b strict-resolution decision, surfaced with
  numbered options across several stops while the co-review of that
  increment kept returning blocking findings and concurrent navigator runs
  were still firing). A blocked or superseded packet could then be captured
  as authorization for a boundary whose increment was never cleanly
  reviewed — one layer up from the FR-041 fabricated-authorization class.
- **Detection**: maintainer instruction, 2026-07-12 (field evidence
  `research/stop-ordering-defect.md`).
- **Additional field evidence (2026-07-12, autonomous/manual review collision)**:
  during the T015/file-primary remediation the AUTONOMOUS continuous-co-review
  (Stop-hook navigator) and the MANUAL serialized reviews collided repeatedly -
  the navigator fired on transient working-tree digests WITHOUT matching recorded
  implementer-evidence, producing STALE blocking packets (e.g. runs
  `20260712T094204795`, `20260712T115340210`, `20260712T140622099`) whose findings
  were already fixed or superseded on the current digest. This is exactly the
  class FR-045 + T019 exist to handle (in-flight dedup + an exact-current-digest
  acceptance gate, so a blocked/superseded packet can never become authorization).
  Recorded as T019/FR-045 field evidence rather than changing review scheduling now
  (maintainer instruction 2026-07-12); detail in `research/stop-ordering-defect.md`.
- **Resolution (recorded + bound, realized in T019/T030–T032)**: FR-045
  states the rule — no verdict/boundary packet (options + marker) while a
  required co-review is pending or before the exact-current-digest review
  is clean or human-dispositioned; a blocked attempt yields no options and
  no marker; a mid-review human question is a narrow non-boundary decision;
  bound to T019 (reviewed-tree-digest acceptance gate + in-flight dedup) and
  T030–T032 (capture rejects blocked/superseded packets; fixtures reproduce
  the stop-ordering sequence). Not resolved-in-place here (this iteration
  did not build the enforcement); recorded as durable field evidence +
  requirement + task binding so the enforcement lands where those tasks do.
- **Scope note**: NEW requirement (FR-045), maintainer-instructed — added
  to the capture-integrity requirement family, not a silent scope creep.

### DRIFT-198-I003-001 — FR-020 tracker honesty check diverged from its TrackerClaims data model (resolved: implementation-corrected)

- **Requirement citation**: FR-020 (fail-closed tracker honesty check);
  data-model.md Entity `TrackerClaims` — `task_statuses` MUST use canonical
  enums only, "parse failure of any claim → fail-closed"; NFR-001 (no
  false-green path); the module's own header states the I3 fail-direction
  ("any parse ambiguity, any unknown file shape, any claim the check cannot
  map → NOT honest").
- **Divergence (shipped in iteration 002, T010)**:
  `Get-ContinuousCoReviewStateClaims` extracted only `Iteration Status` and
  `Last Completed Task` and IGNORED all other content, accepting any
  `[a-z-]+` status and any free-text last-task value; the `tasks-progress.yml`
  parser accepted any `[a-z-]+` status rather than the canonical enum set.
  A tracker-only edit could therefore inject an unmapped/foreign claim
  (a capacity or test-count line into state.md) or use a non-canonical
  status form and be treated as honest — retaining stale review evidence.
  A fail-OPEN door in the exact fail-closed machinery the feature promises.
- **Detection**: iteration-003 continuous co-review, run
  `20260711T163540953-1446b84c` (blocking). Verified against disk and the
  data model before acting — the finding was correct, not a stale replay.
- **Resolution (implementation-corrected, in place)**: canonical
  iteration-status and task-status enums are now required (non-canonical →
  fail-closed); `Last Completed Task` must be a `Tnnn` id or a `(none...)`
  sentinel (other free text → fail-closed); an injected capacity/test-count
  claim in a tracker file (their real homes are the non-tracker plan.md /
  coverage-evidence.md) declines the bypass. Five paired tests added to
  `tests/unit/tracker-honesty-check.tests.ps1` (Tests 7-11): four abuse
  paths prove decline, one paired legitimate case proves the fix did not
  over-close; the full suite is green and the signoff-gate wiring
  (degraded-evidence-gate 9/9) still accepts a legitimate tracker-only
  reconcile.
- **Scope note**: not a scope expansion — this REALIZES FR-020 per its own
  recorded data model; no new requirement. Recorded here (found/fixed in
  003) rather than reopening the closed 002 record.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration

### Notes

- DRIFT-198-I003-001 used implementation-correction (the code was brought to
  its data model), the honest direction for a fail-open in fail-closed
  machinery.
