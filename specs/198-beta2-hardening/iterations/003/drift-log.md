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

**Total drift events**: 8
**Resolution rate**: DRIFT-198-I003-001 + DRIFT-198-I003-003 + DRIFT-198-I003-008 resolved
in place; DRIFT-198-I003-002 recorded → T019/T030–T032; DRIFT-198-I003-004 resolved via a
maintainer-decided FR-011/SC-003 AMENDMENT (T016 REOPENED, pending certification of
the amended surfaces); DRIFT-198-I003-007 resolved via a proposal-205 AMENDMENT
(W10 realized in T018/FR-015 here; W7–W9 carried to Iteration 004 T028 as FR-046/FR-047,
no T004–T006 reopen); DRIFT-198-I003-008 consolidated 5+ divergent trunk-resolution copies
into ONE shared resolver with strict 6-level precedence (never mutates a branch)
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
is never silent), and T016 was REOPENED against the amended contract. One
design-time technology-assumption leak (DRIFT-198-I003-007): the T018 evidence
wrapper was first designed around Pester as the universal test contract, and the
same review found unconditional stack/release teaching that names no Specrew
identifier. Proposal 205 was AMENDED (W7–W10); W10 (generic contract before
adapters) is realized here by T018/FR-015, and W7–W9 (applicability provenance,
`stack-assumption`/`delivery-assumption` taxonomy, heterogeneous fixtures) are
carried to Iteration 004 under T028 (FR-046/FR-047), composing with T021–T023 and
T027, with no reopen of the shipped firewall (T004–T006).

## Events

### DRIFT-198-I003-008 — trunk resolution was DUPLICATED across 5+ co-review sites with divergent, incomplete precedence (a latent bug class); consolidated into ONE shared resolver (resolved in place, maintainer-directed 2026-07-13)

- **Requirement citation**: FR-025 (the signoff coverage anchor = merge-base with trunk) and the
  continuous co-review fire/lease path (FR-045 lineage identity). The trunk is the shared input both the
  signoff gate and the fire baseline depend on; a wrong trunk silently breaks coverage proof and dedup.
- **Divergence (latent defect, found during beta2 hardening)**: FIVE+ independent copies of "which branch
  is trunk" had drifted apart — `Get-ContinuousCoReviewMergeBaseAnchor` (bare/`origin/<t>` + origin/HEAD
  detection), the orchestrator's `Resolve-ContinuousCoReviewTrunkName` (origin/HEAD → `origin/main`,
  `origin/dev`, `main`, `dev`, `master`), the lineage resolver's own 7-candidate loop, the signoff gate's
  `Get-ContinuousCoReviewTrunkName` (config → hardcoded **`main`**), and hardcoded `-TrunkName = 'main'`
  defaults in the CLI, navigator (×2), and worktree-navigator. They had **different candidate sets and
  order**, so past fixes patched only ONE copy each: the iter-007 `dev`-trunk dogfood fix (origin/HEAD
  detection) and the F5 fresh-checkout `origin/<t>` fix never propagated to the other copies. NONE
  implemented a configured **branch upstream**, a **local-only single pre-feature branch**, or a
  **fail-loud on ambiguity** — an ambiguous repo silently reviewed everything (or picked an arbitrary
  first-match) instead of asking the human to configure the trunk.
- **Detection**: F-198 beta2 hardening, 2026-07-13 (maintainer directive to make trunk resolution a shared
  repository capability with strict precedence).
- **Resolution (consolidated in place, maintainer-directed 2026-07-13)**: ONE shared resolver
  `co-review-trunk-resolver.ps1` (`Resolve-ContinuousCoReviewTrunkRef`) with strict precedence — (1)
  explicit `co_review_trunk` (a `-Trunk` override, else config), (2) `refs/remotes/origin/HEAD`, (3) the
  current branch's tracking REMOTE's default branch (`branch.<name>.remote` → `refs/remotes/<remote>/HEAD`,
  never the `@{upstream}` ref itself), (4) conventional refs `main`/`master`/`develop`/`dev` (local or
  `origin/`, priority order), (5) a local-only repo with exactly ONE pre-feature branch, (6) else FAIL with
  a config instruction. It **never creates, renames, or moves a branch** (read-only; proven by test). A
  greenfield repo (only the feature branch) resolves to `greenfield` → the empty-tree baseline (legitimate,
  not an ambiguity). The merge-base anchor, signoff gate + wiring, worktree baseline resolver, lineage
  resolver, CLI, navigator, and worktree-navigator now all consume it; the duplicated loops and every
  `'main'` default are removed.
- **Amendment (maintainer 2026-07-13, same day)**: (a) precedence level 3 must NEVER treat `@{upstream}`
  itself as trunk — a branch that tracks `origin/<self>` (e.g. `feature → origin/feature`) would otherwise
  merge-base with itself and hide the entire feature diff. Level 3 now takes the branch's tracking REMOTE and
  resolves THAT remote's symbolic default (`refs/remotes/<remote>/HEAD`), generalizing level 2's hardcoded
  origin to e.g. an `upstream` fork remote; a local-tracking (`.`) or missing upstream falls through to
  conventional/local-only resolution. (b) The worktree baseline consumer now fails LOUDLY on EVERY resolver
  `ok=false` (ambiguous, explicit-unresolvable, **and no-commit**) and reserves the empty-tree baseline for
  the explicit successful `greenfield` result ONLY — a resolved trunk that shares no history with HEAD
  (unrelated histories) also fails loudly rather than silently reviewing everything.
- **Evidence**: `tests/continuous-co-review/unit/trunk-resolver.Tests.ps1` (16 tests). Resolver Describe (12):
  local-only master, local-only main, origin/HEAD→develop precedence, the **origin/feature tracking
  regression** (resolves main/origin-main, never origin/feature), the **non-origin tracking-remote-head**
  positive, explicit override + `-Trunk` wins, unresolvable-explicit fails, ambiguous fails, single
  pre-feature branch, no-commit fails, greenfield ok-null, never-mutates. Consumer Describe (4): origin/feature
  tracking → NON-EMPTY baseline (merge-base with main, not HEAD, not empty-tree); greenfield → empty-tree;
  ambiguous `ok=false` → throws; no-commit `ok=false` → throws. Registered as F-198 regression suite #25; full
  25-suite registry green.
- **Scope note**: a HARDENING consolidation of existing behavior (found + fixed in 003), not a new
  requirement and not a scope expansion — it realizes the FR-025 anchor's intent uniformly. Recorded here
  rather than reopening a closed record.

### DRIFT-198-I003-007 — T018 design review surfaced a TECHNOLOGY/DELIVERY-ASSUMPTION leak class (Pester-specific evidence contract); proposal 205 AMENDED — W10 realized here in T018, W7–W9 carried to Iteration 004 T028 (recorded → FR-046/FR-047; NOT a T004–T006 reopen)

- **Requirement citation**: FR-014/FR-015 (the recorded-run evidence contract) and the self-leak
  firewall family (FR-033..FR-037, proposal 205). The maintainer's 2026-07-13 ruling
  (language/framework-NEUTRAL runner) + proposal 205 amendment (merged to main `1210d4e7`).
- **Divergence (design defect, caught BEFORE implementation)**: the T018 recorded-run evidence
  wrapper was initially designed around Pester `-PassThru` as the universal test contract — exporting
  Specrew's OWN test framework as the downstream evidence shape. The same design review surfaced the
  broader class the identity-only deny-list could miss: downstream-FACING statements (unconditional
  Windows/PowerShell implementation teaching; "software feature produces a release" language; absolute
  `C:/Dev/Specrew` examples) that present ONE stack/forge/framework/delivery model as universal WITHOUT
  naming Specrew — so the original deny-list would pass them while still leaking Specrew's
  implementation stack + delivery model as methodology.
- **Detection**: F-198/T018 design review, 2026-07-13 (maintainer); recorded in proposal 205's
  amendment log the same day.
- **Resolution (proposal 205 AMENDED + strict F-198 scope separation, maintainer-directed 2026-07-13)**:

  1. **W10 (generic contract before adapters) is realized HERE in iteration 003 by T018/FR-015**: the
     universal runner records framework-NEUTRAL execution facts and accepts an OPTIONAL, schema-valid,
     project-PRODUCED `SpecrewTestResult`; NO built-in Pester/pytest/Jest/TRX/JUnit parser; exit 0 =
     `command_succeeded`, never "all tests passed"; counts only from the produced contract. Pester is a
     DEMONSTRATION producer (recorded-run test 10), never the core contract.
  2. **W7–W9 are carried to Iteration 004 under T028** (spec FR-046/FR-047), composing with the
     provider-gated consumer CI (T021–T023) and the release-model resolver (T027): applicability
     provenance (every downstream tech/delivery statement is `project-detected` / `profile-selected` /
     `provider-gated` / `example-only`), the extended `stack-assumption` + `delivery-assumption`
     deny-list classes, and the heterogeneous fixture matrix (Python/non-Pester, non-GitHub, no-release).
     Technology names are NOT globally banned — explicitly selected presets + provider-gated templates
     stay valid.
  3. **T004–T006 are NOT reopened**: the shipped firewall (deny-list data, repo lint lane,
     parameterization doc) is untouched; the extension lands as NEW requirements owned by T028.

  Updated: spec.md (FR-046/FR-047 amendment block + section header + US5 trace), tasks.md (T028 scope +
  trace + honest SP growth 0.5→2.0; T018 refocus duty line), plus the T018 generic-runner artifacts
  (FR-014/FR-015, data-model RecordedRunEvidence + SpecrewTestResult contract, evidence schema,
  design-analysis UniversalRunner). NO Iteration 004 implementation begun.
- **Scope note**: a PROPOSAL amendment (205) absorbed into F-198 as new Iteration 004 ownership + one
  iteration-003 realization (T018) — maintainer-decided, strict scope separation; no T004–T006 reopen,
  no Iteration 004 implementation started.

### DRIFT-198-I003-006 — ADJACENT hardening found during T016/T020 confirmation: over-broad host-churn exemption + over-claiming coverage evidence (resolved in place; NOT absorbed into FR-011/FR-019)

- **Scope note (maintainer instruction 2026-07-12)**: these two defects were surfaced by
  the co-review WHILE confirming the T016/T020 amendments, but they are ADJACENT hardening
  — recorded here as their own drift event, deliberately NOT folded into FR-011 or FR-019.
- **Finding A — integrity-gate host-churn exemption too broad**:
  - *Requirement citation*: the reviewer-invocation integrity contract (FR-010 family) +
    `reviewer-spawn-contract.md` ("the ONLY permitted write is `.review/findings.jsonl`").
  - *Divergence*: `Test-ContinuousCoReviewIsHostChurnPath` exempted ANY new file whose
    top-level dir was a volatile host dir (`.codex`, `.claude`, …). A reviewer could add
    persistent content (`.codex/config.toml`, `.claude/settings.json`) or an arbitrary file
    and still receive a valid result — contradicting the spawn contract.
  - *Detection*: co-review autonomous navigator run `20260712T182526592-abc8997e` (blocking).
  - *Resolution (in place)*: the exemption is now a CHARACTERIZED ephemeral allowlist — a
    recognized ephemeral subdir segment (`sessions`, `projects`, `todos`, `logs`, `cache`,
    `tmp`, …) or file pattern (`*.jsonl`, `*.log`, `*.lock`, `*.tmp`, `session*.json`, …),
    with an explicit DENY for config/persistent patterns (`config.*`, `settings.*`, `*.toml`,
    `*.yaml`, …). An unknown/config/persistent new file under a host dir now FAILS integrity.
    Paired tests: recognized ephemeral passes; a config file (`.codex/config.toml`) and an
    unrecognized file FAIL (unit predicate + a negative integration test). `reviewer-spawn-contract.md`
    updated to describe the narrowed allowlist.
- **Finding B — coverage evidence over-claimed universal injection**:
  - *Requirement citation*: the test-evidence-honesty rule (co-review f1, 2026-07-12) — a
    count has standing only with digest-matched runner-observed evidence.
  - *Divergence*: `coverage-evidence.md` claimed EVERY listed suite was injected as
    `.review/implementer-evidence.json` with runner-observed standing, but a given review's
    injected record contains only the suites recorded for THAT exact digest (the navigator's
    run held 3 of the listed suites). So several rows (incl. T020) claimed standing they did
    not have for that tree.
  - *Detection*: same navigator run `20260712T182526592-abc8997e` (blocking).
  - *Resolution (in place)*: `coverage-evidence.md` rewritten to state that a row has
    digest-bound runner-observed standing ONLY for suites present in the digest-matched record
    for the tree under review — NO universal-injection claim, NO reliance on historical runs;
    the recorder must be re-run against the exact reviewed digest to cover every listed suite.
  - *Follow-up (bounded truth-alignment, maintainer-directed 2026-07-12; the authoritative review
    `20260712T215431762` at the recorded digest was NON-blocking)*: the initial fix narrowed only the
    intro; the meta-run/dispatcher bullet, the F-198 table row (18/0), and `state.md` L342-345 were
    ALSO narrowed to exact-digest facts. The machine record proves which suites ran for its recorded
    digest; a reviewer gives them standing only when that exact record is injected for the exact
    reviewed digest. The autonomous navigator's partial injection is recorded as
    **DRIFT-198-I003-002 behavior, NOT proof the recorded runs did not occur**.
- **Follow-up to DRIFT-198-I003-005 (advisory f1, same authoritative review)**: the `allowance-reset`
  `-NewMaxRounds` ceiling-EXTENSION was removed. The runtime ceiling reads only `.specrew/config.yml`,
  so a round-state `max_rounds` override was a DEAD, misleading audit claim; `allowance-reset` now does
  only the ENFORCED `round=0` replenish with its approver/time/reason audit.
- **Scope note**: implementation/honesty corrections, maintainer-directed as adjacent hardening (one
  authorized confirmation round + two bounded truth-alignment edits). Not new requirements; not folded
  into T016/T020.

### DRIFT-198-I003-005 — resolved-against-disk unintentionally REPLENISHED the review-spend allowance (resolved: split into resolve vs allowance-reset, maintainer ruling 2026-07-12)

- **Requirement citation**: FR-019 (the round ceiling is an AI-usage SPEND
  allowance — EVERY round counts; only a human-approved reset replenishes) and the
  maintainer-typed Q&A at spec.md ("the ceiling is an AI-usage spend allowance…
  therefore EVERY round counts").
- **Divergence (shipped in T020)**: `Set-ContinuousCoReviewFindingResolvedAgainstDisk`
  reset the round-state `round` to **0** when clearing a resolved finding. That
  IMPLICITLY replenished the spend allowance: after resolving a finding, a fresh full
  allowance was available, so already-spent rounds were effectively reused —
  contradicting FR-019's "every round counts."
- **Detection**: iteration-003 continuous co-review (autonomous navigator run
  `20260712T175244928-3e8a4ce0`, blocking). The finding also noted this iteration's
  own remediation history: the ~10 `resolved-against-disk` calls used to clear the
  latch during the DRIFT-004 arc each reset `round=0`, i.e. unintentionally
  replenished the allowance.
- **Resolution (maintainer ruling 2026-07-12 — SPLIT the concerns, implemented in
  place)**: two distinct actions —
  1. **`resolved-against-disk`** verifies the fix-evidence commit, clears the blocking
     finding + its lineage, and now **PRESERVES the spent-round count** — it never
     implicitly replenishes the allowance.
  2. **`allowance-reset`** (NEW, `Set-ContinuousCoReviewAllowanceReset`) is the
     separate, explicit human-approved action that resets/extends the round allowance;
     it records the authorizer, timestamp, and previous/new allowance, and leaves the
     resolved-finding evidence intact. Wired as a `--remediate allowance-reset` choice
     that requires `--ack-reason`.
  Updated: FR-019 (+ the assumption), `worktree-review-orchestrator.ps1`
  (resolved-against-disk preserves `round`; new allowance-reset function + choice),
  `specrew-review.ps1` (help + applied-immediately), and paired tests in
  `review-spend-allowance.Tests.ps1` (resolve PRESERVES round; allowance-reset
  replenishes + records + leaves evidence; the choice API requires `--ack-reason`).
- **Scope note**: a REQUIREMENT AMENDMENT (FR-019) + implementation correction,
  maintainer-decided. The prior in-session remediations that replenished allowance are
  recorded here as the field evidence that motivated the split.

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
- **Exact-digest evidence-injection carry (2026-07-12 maintainer directive)**: a further
  facet of the same collision — evidence recorded for digest A was PARTIALLY injected into a
  review of digest B (the autonomous navigator's working-tree digest ≠ the recorder's digest),
  so a review saw a SUBSET of the recorded suites and read it as an honesty mismatch (see
  DRIFT-198-I003-006). CARRIED TO T019 (which owns digest identity + in-flight dedup +
  exact-digest result handling): acceptance coverage MUST prove digest-A evidence cannot be
  fully OR partially injected into a digest-B review, and a partial/mismatched injection is
  surfaced honestly (never clean, never "the A-runs did not occur"). T018 stays scoped to
  producing honest runner-observed evidence for its EXACT digest only — NOT review scheduling
  or collision resolution.
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

## DRIFT-198-I003-008 — Stop-packet material misclassification (spec-updated: FR-055) + a stale committed test

- **Divergence (observed live, 2026-07-14)**: the conformance Stop-provider classified a READ-ONLY status
  turn as material because the rolling-handover signal keys on the ABSOLUTE dirty-tree surface — files an
  earlier session left dirty (plus Specrew-managed-count drift inside the hashed surface) read as this turn's
  work, forcing a duplicate five-heading packet after a complete answer. Maintainer directive (2026-07-14,
  instruction-bearing verdict) authorized the redesign; recorded as **FR-055**.
- **Resolution (spec-updated + implemented)**: SessionStart/discharged-stop session BASELINE + turn-delta
  gate; volatile managed-count clause stripped from the surface key; deterministic LONG-TURN lane (fixture d);
  PostToolUse one-per-obligation-window pre-arrangement nudge; boundary contract untouched; six regression
  fixtures (a)–(f) in `tests/integration/conformance-detection.tests.ps1` (cases PH-a…PH-f).
- **Adjacent pre-existing defect (reconciled, flagged for maintainer visibility)**: suite Case 5 (idle
  conversational intake question → #1 nudge) was **already RED at HEAD** (verified in a detached worktree at
  `de9cf834`): the T099/FR-040 design-N3 perf change deliberately stopped paying the transcript parse on idle
  stops (committed code cites "an idle intake drift is caught by the bootstrap orientation surface instead"),
  but the committed test still asserted the retired trigger, and the suite is not in the f198 registry so the
  red was invisible. Case 5 is reconciled to the ratified T099 contract (idle stop → no conformance output)
  and a new Case 5b proves the intake nudge still fires on a stop that warranted the parse. Test-only change;
  no behavior change beyond FR-055.

## DRIFT-198-I003-009 — state-narrative destruction root cause (implementation-corrected)

- **Divergence (recurring; root cause identified 2026-07-14)**: `Update-IterationStateFromTaskProgress`
  (`scripts/internal/task-progress.ps1`) replaced the ENTIRE `## Execution Summary` section — everything up to
  the next `## ` heading — with its three generated digest bullets on EVERY task-progress sync. Any hook- or
  command-driven sync therefore silently destroyed the hand-authored execution narrative in a committed
  state.md. Two observed hits: the iteration-003 "reset" repaired in commit `47106751` (previous session; root
  cause then unidentified) and the 2026-07-14T15:29Z truncation of this iteration's state.md (642 lines →
  29). The damage violates honest-state (Rule 7) and destroys the durable execution record the lifecycle
  depends on.
- **Resolution (implementation-corrected)**: the generated digest now refreshes a marker-bounded MANAGED
  block (`<!-- specrew:task-progress-summary:begin/end -->`); user narrative in the section is preserved;
  machinery-owned legacy shapes (the generated digest, the scaffold placeholder) migrate wholesale. Paired
  regression: `tests/unit/task-progress-managed-summary.tests.ps1` (4 cases, registered in the F-198
  registry) + a narrative-preservation case appended to `tests/integration/task-progress-tracking.tests.ps1`
  (that harness needs Spec Kit >= 0.12.9 to bootstrap and is environmentally unrunnable on this machine —
  pre-existing). The damaged `iterations/003/state.md` was REPAIRED from the committed rich record (canonical
  header + managed digest merged in; the long header narratives moved into the Execution Summary), and a live
  sync against the repaired file proved 700 → 700 lines with the narrative intact.
- **Scope note**: maintainer prompt-2 default from the previous session was "file as a follow-up issue" —
  superseded by the root cause being identified DURING this directive's work and the repair being futile
  without the writer fix (the next sync would re-destroy the restored record). Flagged for the maintainer's
  confirmation; send-back reverts cleanly (the fix is one function + tests).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration

### Notes

- DRIFT-198-I003-001 used implementation-correction (the code was brought to
  its data model), the honest direction for a fail-open in fail-closed
  machinery.
