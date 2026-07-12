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
**Resolution rate**: DRIFT-198-I003-001 + DRIFT-198-I003-003 resolved in place;
DRIFT-198-I003-002 recorded → T019/T030–T032; DRIFT-198-I003-004 resolved via a
maintainer-decided FR-011/SC-003 AMENDMENT (T016 REOPENED, pending certification of
the amended surfaces)
**Specification drift**: One implementation-vs-data-model divergence
(DRIFT-198-I003-001) in iteration-002's shipped FR-020 code, surfaced by
iteration-003 co-review and fixed in place with paired abuse tests. One
process/governance defect (DRIFT-198-I003-002): lifecycle verdict packets
were rendered during pending/blocking co-reviews — recorded as FR-045 and
bound to T019 + T030–T032. One docs-vs-shipped-design drift
(DRIFT-198-I003-003): T015's design surfaces bound "REQUIRED bounded
verification" after the option-1 decision (2026-07-11) had made it opt-in —
the authoritative docs are now aligned to the shipped design. One
design defect in the shipped T016 detector (DRIFT-198-I003-004): an argv
containment detector built as a HARD review-failure could not be made complete.
Six successive fresh-context reviews found the reviewer's prompt mis-read as
access, then quoted / relative / option-attached path bypasses, plus periodic-
sampling and silent-failure gaps. The maintainer's review determined the
hard-failure argv DESIGN itself was the defect: FR-011 + SC-003 were AMENDED
(FR-008/T013 is the structural guarantee; cwd/exe-under-origin are the only HARD
`containment-violated` signals; argv matches are best-effort diagnostic WARNINGS
that never discard a valid review; sampler health is recorded so weak visibility
is never silent), and T016 was REOPENED against the amended contract.

## Events

### DRIFT-198-I003-004 — T016 containment sampler could not distinguish a reviewer HOST's prompt MENTION of origin from real origin ACCESS (resolved in two field-caught stages: prompt-mention subtraction restores host observability)

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
- **Stage 1 detection (dogfood — the detector caught its own bug)**: the first
  serialized codex review OF the T016 increment (run
  `20260712T181010372-fpvalidate`) fired the new detector on
  `pid=… image=codex.exe source=arg path=C:\Dev\…` — the reviewer's own
  prompt-arg, not access. A true positive of a false-positive class.
- **Stage 2 — the first fix was itself over-broad, and codex caught THAT too
  (dogfood²)**: the initial correction simply SKIPPED arg-sampling for the host
  (root + same-image workers). That removed the false positive but BLINDED the
  detector to a host that reaches origin via its OWN real arg — on Windows there
  is no cheap cwd and the host exe is never under origin, so the host had NO
  remaining access signal. The next fresh-context codex review (autonomous
  navigator run `20260712T153106402-764adb91`, CORROBORATED by the manual
  serialized review `20260712T183648073-fpvalidate`, both blocking, 1 finding)
  flagged the gap AND correctly objected that this drift record had marked the
  residual "accepted" with no human approver and no carried work item — i.e. an
  invalid self-approved deferral.
- **Stage 3 — subtraction was still too broad; codex caught THAT too (run
  `20260712T190522932`)**: the Stage-2 fix subtracted for the root pid AND any
  same-image worker. A follow-on codex review showed that is a containment FALSE
  NEGATIVE — a same-image worker (e.g. pwsh spawning pwsh) accessing a prompt-named
  origin path has its ONLY real token subtracted against the root's prompt, and the
  superset gate is trivially met when the prompt names few distinct paths. A false
  negative in a containment detector is worse than a false positive, so the reviewer
  correctly blocked.
- **Stage 4 — the ROOT CAUSE surfaces: the tokenizer itself (run
  `20260712T192442732`)**: a further codex review showed the whitespace-split tokenizer
  `Get-ContinuousCoReviewPathLikeTokens` split the command line BEFORE removing quotes,
  so a QUOTED origin operation target with spaces (e.g. `"C:\Origin Project\secret.md"`)
  fragmented into `C:\Origin` + `Project\secret.md`, neither of which resolves under
  origin — a containment-detection BYPASS (false negative). This was the ROOT CAUSE
  behind the whole arc: the same naive tokenizer both mis-read the prompt (Stage 1) and
  could be bypassed by a spaced path.
- **Resolution (root-cause fix — STRUCTURED ARGV, subtraction removed)**: the sampler
  now parses the command line into STRUCTURED argv with platform-appropriate quoting —
  `CommandLineToArgvW` on Windows (honours `\"` escapes) and NUL-split
  `/proc/<pid>/cmdline` on POSIX — then tests each whole argument for an absolute path
  (`Get-ContinuousCoReviewCommandLineArgv` + `Select-ContinuousCoReviewAbsolutePathTokens`).
  Consequences: (a) the reviewer's PROMPT — a SINGLE positional arg — is one non-path
  token, so a prompt that merely NAMES origin is never mistaken for access (the Stage-1
  false positive is now structurally impossible); (b) a QUOTED path with spaces stays one
  token and IS detected (Stage-4 bypass closed); (c) every process — root, same-image
  worker, or descendant — is sampled UNIFORMLY, so a real origin arg is always observable
  (Stages 2–3 false negatives closed). The prompt-token-subtraction workaround
  (`Get-ContinuousCoReviewOperationTargetTokens`, the `prompt_mention_tokens` telemetry,
  the ROOT-pid gating) is DELETED — it existed only to compensate for the broken
  tokenizer. Tests: a unit test (quoted-spaced path is one token; single-arg prompt yields
  no path token) + a sampler test (quoted spaced descendant path DETECTED; prompt not
  flagged; same-image worker's real arg observable → two violations, never the prompt).
- **Stage 5 — RELATIVE-traversal bypass; MAINTAINER chose to FIX, not defer (run
  `20260712T195149281`)**: the authoritative serialized review (evidence injected) found
  that `Select-ContinuousCoReviewAbsolutePathTokens` kept only ABSOLUTE tokens and silently
  dropped RELATIVE ones, so a descendant launched from the worktree could reach an origin
  sibling via `git show ..\..\<origin>\secret` with no violation. This was the DOCUMENTED
  relative-arg gap that Stage-4's resolution had framed as "inherent scope" — the SAME
  self-declared-residual pattern Stage 2 was blocked for. Escalated to the maintainer (the
  5th distinct detector finding); the maintainer explicitly chose to FIX it (a human
  decision, not a self-approval). Fix: `Resolve-ContinuousCoReviewRelativeOriginTokens`
  resolves each relative path-like argv token against the process cwd (POSIX
  `/proc/<pid>/cwd`; Windows the `-WorktreeCwd` the reviewer was launched in) and the
  normalized absolute path is checked under-origin — only a traversal that ESCAPES the
  worktree up to origin flags. Test: a real `..`-traversal abuse (dropped without a cwd,
  caught with the worktree cwd).
- **Stage 6 — the HARD-FAILURE DESIGN is the defect, not one tokenizer case (maintainer
  review, run `20260712T171701083` + full review 2026-07-12)**: a 6th review found
  option-attached path values (`--git-dir=..\<origin>\.git`, `--git-dir=C:\origin\.git`)
  evade the detector — again contradicting a self-declared "only argless-syscall residual".
  Escalated. The maintainer's full review then identified the PATTERN as the finding:
  argv/command-line matching is inherently incomplete (six parser patches, plus periodic
  5s-heartbeat sampling that misses a short-lived descendant, plus Windows assumed-cwd
  classification), so using an argv match as a HARD review-failure is the wrong design.
  Additional blocking findings: sampling exceptions degraded to SILENT inactivity (no health
  recorded, contradicting spec L907); and demoting argv from a hard signal is a binding
  behaviour change that requires an explicit REQUIREMENT AMENDMENT, not another drift-only
  correction (FR-011 required argv observations to mark `containment-violated`).
- **Resolution (Option 1 + explicit SPEC AMENDMENT; T016 REOPENED)** — the maintainer chose
  Option 1 with a spec amendment (rejected Option 2, more patches). FR-011 and SC-003 are
  AMENDED and T016 is REOPENED:
  1. **FR-008/T013** (worktree materialized OUTSIDE origin) is the STRUCTURAL containment
     guarantee.
  2. **Strong signals** — a reviewer-tree process whose **cwd** or **exe** resolves under
     origin — remain HARD `containment-violated` (fail loud, discard findings).
  3. **Argv matches** become bounded **DIAGNOSTIC WARNINGS**: recorded, never grounds to
     discard an otherwise valid review. `--name=value` is expanded as useful best-effort
     coverage, WITHOUT any completeness claim.
  4. The monitor records **SAMPLER HEALTH** — attempts, successful samples, failures,
     degraded reason, final-sample-taken — so weak visibility (fewer samples, a sampling
     error, a short-lived descendant between heartbeats) is VISIBLE, never silent
     inactivity. A FINAL best-effort sample fires after the reviewer's run loop.
  Code: the orchestrator partitions violations by source (cwd/exe → hard fail; arg →
  warning) and persists `containment_warnings` + `sampler_health`; the sampler expands
  option-values, resolves relative args against the process cwd, and returns health via a
  `-Health [ref]`. Tests added: strong-signal hard-fail, argv-only warning (review NOT
  discarded), option-attached value, sampling-failure (degraded recorded), final-sample,
  alternate-child-cwd.
- **Scope note**: this is a REQUIREMENT AMENDMENT (FR-011 + SC-003), maintainer-decided
  2026-07-12 — not a silent drift-only correction. Six successive fresh-context reviews
  demonstrated that the hard-failure argv design was the root problem; the honest resolution
  makes T013 the guarantee, cwd/exe the hard signals, and argv a best-effort monitor whose
  health is always recorded. T016 stays REOPENED until these amended surfaces are certified.

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
