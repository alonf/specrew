# Iteration Plan: 008

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 14/20 story_points
**Started**: 2026-06-10
**Completed**:

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity `<consumed>/<cap> <unit>`. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Scope Summary

Iteration 008 finishes the hook-driven era now that all four hooked hosts are GREEN. iter-7 achieved claude
content-parity (FR-023); its FR-024 multi-host completion LANDED this session during the cross-host dogfood —
codex entered the PARITY SET after two codex-format fixes were found and shipped (the SessionStart `hooks.json`
needed codex's `{ hooks: { <Event> } }` wrapper, and the dispatcher output needed
`hookSpecificOutput.additionalContext` instead of the flat form), alongside the mandatory orientation banner
(hoisted + expanded in `Format-BootstrapDirective`) and real `-SpecrewVersion` threading. claude, codex, and
copilot are now observed governed; antigravity stays launcher-only by design (no hook).

This iteration delivers the three maintainer asks on that green baseline:

1. **Docs (FR-008):** reposition `specrew start` as an OPTIONAL host-selector / launcher, not the entry —
   after `specrew init` the user just opens their host and the SessionStart hook drives.
2. **Intake at init (FR-025, new):** capture the user-profile dials at `specrew init` (guarded interactive),
   so hook-only users still get the expertise adaptation; retain the `specrew start` fallback + a hook nudge.
3. **Handover validation (FR-022 / SC-003 / SC-008 / SC-009):** validate the rolling handover across exit
   modes (`/exit`, double Ctrl+C, window close, process kill), document the test procedure, and fix any
   agent-authoring gap the validation surfaces.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T048 | Docs: reposition `specrew start` as an optional host-selector (README Quick Start + getting-started "Start the first feature" + host-pick note + CHANGELOG); the SessionStart hook drives after `specrew init` | FR-008, FR-001 | US-2 | 3 | Implementer | done |
| T049 | Move user-profile intake to `specrew init` (ask ONLY when profile ABSENT and session INTERACTIVE; skip silently on `-Force`/CI; retain `specrew start` fallback; bootstrap directive nudges `/specrew-user-profile` when absent) | FR-025 | US-1 | 5 | Implementer | done |
| T050 | Handover validation across exit modes + test-procedure doc (`/exit`, double Ctrl+C, window close, kill); confirm the crash-safe agent-authored body persists + resume restores; fix any authoring gap | FR-022, FR-009 | US-1 | 6 | Implementer | in-progress |

**Capacity: 14/20** (T048 3 + T049 5 + T050 6 = 14). The FR-024 codex / FR-004 banner / version fixes were
delivered as iter-7's multi-host completion (already shipped + validated) and are NOT re-counted here.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments. |

## Traceability Summary

- T048 -> FR-008 (specrew start prompts + docs updated), FR-001 (the hook is the primary trigger).
- T049 -> FR-025 (NEW this iteration: user-profile intake capturable at init, guarded interactive).
- T050 -> FR-022 (rolling-handover body agent-authored), FR-009 (handover wired through hook deployment),
  SC-003 / SC-008 / SC-009 (Stop round-trip + hard-kill crash-safety).
- Reconciled this session (iter-7 FR-024 completion, not re-counted here): codex hooks.json wrapper +
  dispatcher hookSpecificOutput output + lean-pointer delivery; mandatory banner hoist+expand (FR-004);
  real version threading.

## Notes

- All hooked hosts (claude / codex / copilot) observed governed; antigravity launcher-only (FR-024).
- Sequence: T048 docs (lowest risk) -> T049 intake -> T050 handover validation.
- T050 may surface a real agent-authoring gap (the copilot dogfood showed the body was not authored); if so,
  the fix (the directive's handover-protocol instruction / its prominence) is in scope.
- **Cleanup candidate — `.gitignore` gap:** `.specrew/runtime/` is NOT ignored (`bootstrap-journal.jsonl`,
  `handover-journal.jsonl`, `refocus-state-*.json`, `session-marker.json` show as untracked runtime noise),
  and `.specrew/last-validator-summary.json` is gitignored yet still TRACKED (committed before the ignore).
  Fix: add `.specrew/runtime/` to `.gitignore` and `git rm --cached` the stale-tracked validator summary.
- **Finding — iter-4 state corruption (reverted this session):** tooling rewrote `iterations/004/state.md`
  from `complete / iteration-closeout` to `not-started / before-implement` and created a bogus
  `iterations/004/tasks-progress.yml` (2026-06-10T09:10). A progress-tracker/dashboard mis-resolved the
  ACTIVE iteration as the already-closed iter-4 — same wrong-context-resolution class as the refocus
  session-id bug (GitHub #2446). Reverted; file as a candidate.
- **T050 finding + fix (handover provider mirror skew, FIXED this session):** the cross-host handover
  validation surfaced a real deployment bug — the rolling handover NEVER wrote at Stop on any host. Root
  cause: the iter-5 floor/body-split rewrote `scripts/internal/specrew-handover-provider.ps1` but left the
  deployable mirror `extensions/specrew-speckit/scripts/specrew-handover-provider.ps1` STALE (pre-iter-5). The
  stale mirror calls `Write-SpecrewRollingHandover -Sections` against the iter-5 HandoverStore that dropped
  that param, so the Stop provider failed OPEN silently (exit 0, stderr-only `PROVIDER_FAILED` WARN) and wrote
  nothing — host-independent (claude/codex/copilot all deploy the same mirror). Proven via byte-identity
  (deployed copy == stale mirror `a5e9…` != source `6556…`) + clean-env reproduction. **Fix:** re-synced the
  mirror to its source (dev tree + the installed 0.34.0 module so re-init redeploys it), and GENERALIZED
  `ProviderMirrorParity.Tests.ps1` from bootstrap-only to auto-discover ALL full-copy provider pairs (excludes
  the documented `sync-boundary-state.ps1` dispatcher wrapper) so the class cannot recur silently. Verified:
  parity green (5 pairs) + the synced extensions mirror writes the floor via the real deploy path (correct
  `HOLLOW_HANDOVER` warn, not `PROVIDER_FAILED`). The meta-gap was that the parity guard built for the iter-6
  bootstrap send-back was never extended to the handover provider.
- **T050 finding (Claude lifecycle-entry adherence, capture — candidate slice):** on the IDENTICAL small task
  (C skip-list library), Copilot ran a full discovery workshop (7 lens files + spec + checklist) and Codex ran
  a real one (spec + 2 lenses), but Claude free-ran the 54KB contract entirely — no spec, no workshop, no
  lenses, straight to code — despite the hoisted MANDATORY banner + "you DRIVE the gates, do NOT free-run the
  SDLC". Controlled three-way comparison (same input, same contract delivery), artifact-corroborated; Claude is
  the outlier. Delivery is solved (banner present, contract inlined); ADHERENCE is the open gap. More
  instruction text is the wrong fix (banner hoist already failed to bind Claude). The structural fix is the
  dormant `PreToolUse` gate seat (the dispatcher's `kind == 'gate'` path) enforcing lifecycle-entry at the
  first implementation tool call — the literal "hook DRIVES, not orients" thesis of F-174. Substantive →
  candidate proposal, not a T050 inline fix.
- **T050 validation round 1 (hofix re-test, codex + copilot, 2026-06-10):** the handover mirror fix is
  VALIDATED — codex's Stop floor now WRITES (`from_commit 810ae44`, proper frontmatter, 7 journal events) where
  every host previously failed silently with `-Sections`. The now-working floor exposes three deeper gaps it had
  masked: (1) **body not authored** — codex's 6 Pillar-2 sections are 0/6 (all placeholder); the agent never
  called `Write-SpecrewHandoverContext` (likely because no boundary-packet moment was reached — author-at-boundary
  vs the crash-safe floor-fallback; needs a deliberate stop AT a gate to disambiguate gap-vs-by-design).
  (2) **session anchor never populated** — BOTH hosts' `start-context.json` `session_state.feature_ref` /
  `boundary_type` are EMPTY even after codex wrote `specs/001-pomodoro-cli/spec.md`; in the hook-driven model
  (no `specrew start`) nothing writes the anchor, so the handover is anchorless (`active_feature:` blank) and
  resume cannot restore the lifecycle position. (3) **copilot stop-side does not fire** — copilot's SessionStart
  fires (bootstrap-journal present, host copilot, mode full) but agentStop->handover never fires (no
  handover-journal, no handover file) despite the FIXED provider being deployed. CORRECTION (maintainer, same session): copilot was likely NOT
  stopped — it was at a WORKSHOP QUESTION awaiting input, so `agentStop` (end-of-turn) had not fired and **no
  handover is expected yet** (consistent with no spec written = mid-workshop). This is NOT a confirmed
  stop-side gap; re-check only after copilot reaches a real stop / `/exit`. The known copilot handover/resume
  gap stays a separate, still-open question to test deliberately. Next: answer copilot's question and drive it
  to a real stop (ideally AT a gate, to test body persistence at a boundary); run Claude; decide which
  confirmed gaps are T050-inline vs follow-ups.
- **T050 round 1, Claude (hofix-claude):** floor WRITES (`from_commit 2438595`) — the mirror fix is now
  validated on ALL THREE hooked hosts. NOTABLY the **workshop-skip did NOT recur**: Claude rendered the MANDATORY
  banner and ran the product-domain-first workshop (scaffolded `001-pomodoro-timer`, loaded the product-domain
  lens); its "first stop" is the product-domain opening question awaiting input (a question end-of-turn, NOT a
  gate). So Claude's 0/6 hollow body is the EXPECTED floor-fallback (pre-gate), same as copilot. **Round-1
  conclusion:** the floor write is fixed + validated cross-host; all three bodies are hollow ONLY because all
  three stopped BEFORE a boundary packet; the real body-authoring test still needs a deliberate stop AT a gate.
  The one CONFIRMED gap is the empty session anchor (feature_ref/boundary_type blank on all three — the
  hook-driven model populates no anchor, so the handover is anchorless and resume cannot name the feature).
  Claude's n=1 no-skip is encouraging but does NOT retire Proposal 180 (the skip was intermittent to begin with).
- **T050 round 1, codex RESUME test (`/exit` -> re-enter -> "continue", 2026-06-10):** codex did NOT resume — it
  RESTARTED the workshop cold (re-rendered the welcome banner, re-ran the product-domain lens from scratch),
  losing the prior product-domain discussion. The handover was NOT surfaced on re-entry: the bootstrap logged
  `handover_valid:false, handover_placeholder:false` and the resume prompt never mentioned it, because the
  handover is anchorless (empty `feature_ref`) + hollow, so the bootstrap treats it as "no active session
  anchor". Codex fell back to DISK TRUTH (the empty spec scaffold) and restarted sensibly — the fallback
  degrades gracefully; there was simply nothing persisted to recover. Clean BEFORE-picture for the per-lens
  handover fix (had the product-domain decisions been in the body / on disk, resume would inherit "product-domain
  done -> next agenda"). Minor finding: `/exit` left a STALE session-marker -> re-entry false-warned "another
  session may be active in this worktree" (the exit should clear/age the marker).
- **T050 round 1, Claude RESUME test (`/exit` -> re-enter -> "continue", 2026-06-10):** Claude RESUMED CORRECTLY
  — the OPPOSITE of codex. It rendered a "Welcome BACK" banner and oriented accurately: "resuming
  001-pomodoro-timer, mid design-workshop, before the specify boundary; the product-domain lens is already
  captured + human-confirmed [read from `workshop/product-domain.md`]; what's missing is the per-lens workshop +
  `lens-applicability.json`" -> continued AT THE AGENDA, did not re-do product-domain. CRUCIAL: the bootstrap did
  NOT surface the handover (same `handover_valid:false` anchorless gap as codex) — Claude recovered by its OWN
  proactive orientation (it Read the handover + product-domain + spec + last-start-prompt to work out "where we
  are"). So resume quality turned on TWO host-variances: (a) persist-each-lens-to-disk — Claude did, codex
  skipped; (b) read-state-on-resume — Claude did, codex didn't. Claude won both -> correct resume; codex lost
  both -> cold restart. **Fix implication:** per-lens DISK persistence is sufficient WHEN the host reads it on
  resume, but to make resume HOST-INDEPENDENT (so codex-class hosts also recover) you need BOTH the handover BODY
  authored (the user's per-lens idea) AND a bootstrap resume-detection fix — today it logs `handover_valid:false`
  and never surfaces an anchorless handover, so only a proactively-reading agent recovers. The per-lens
  body-authoring fix should pair with bootstrap surfacing + anchor population.
- **T050 round 1, copilot (full workshop + `/exit` AT the specify boundary, 2026-06-10):** copilot is the
  best-behaved host — persisted the FULL workshop (6 lens md + `lens-applicability.json` + a real filled
  `spec.md`, 0 placeholders) and its agentStop DOES fire (handover floor + journal exist). TWO findings:
  (1) **body-authoring gap is UNIVERSAL and holds even at a gate** — copilot `/exit`'d with `active_boundary:
  specify` and the body is STILL 6/6 hollow. So the existing "author at a boundary packet" trigger does NOT fire
  in practice on ANY host; the per-lens write is the real fix, not a supplement. (2) **CORRECTION to the
  "anchor never populated" finding** — copilot's post-specify handover IS anchored (`feature 001-pomodoro-cli`,
  `boundary specify`, journal `material_reason: boundary-moved`). So the anchor fills when a boundary is CROSSED;
  it is empty only during the PRE-specify workshop (codex/Claude/copilot-mid-workshop hadn't crossed a boundary
  yet). The anchorless-handover problem is therefore concentrated in the pre-first-boundary workshop phase —
  exactly where a long workshop most needs the rolling handover, and exactly where the per-lens fix helps most.
  Copilot's re-entry is the best-case resume test (anchored handover + richest disk state) — pending.
- **T050 round 1, copilot RESUME (anchored + rich disk, 2026-06-10) — THE DECISIVE DATA POINT:** the bootstrap
  FINALLY surfaced the handover. Re-entry logged `mode: "welcome-back"` (not "full"), `handover_valid: true`,
  `handover_placeholder: true` — vs codex/Claude's `mode:full, handover_valid:false`. The ONLY difference was the
  ANCHOR (copilot had crossed specify -> anchored; codex/Claude were anchorless mid-workshop). So
  resume-detection WORKS when the handover is anchored; it is GATED on the anchor. `last-start-prompt.md`
  rendered "Welcome Back"; copilot did NOT restart the workshop (no workshop re-writes). **MATRIX COMPLETE:**
  codex (anchorless + empty disk -> cold restart), Claude (anchorless + partial disk -> self-recovered by reading
  disk), copilot (ANCHORED + rich disk -> welcome-back resume, surfaced). **REFINED 3-LAYER FIX:** (1) populate
  the anchor EARLIER — at feature-scaffold / workshop-start, not just at the specify boundary — so the long
  PRE-specify workshop is anchored and its handover gets surfaced (today it is anchorless -> not surfaced ->
  resume falls to the agent reading disk, which is host-variable). (2) per-lens body authoring (the user's idea)
  — the body is universally hollow even when surfaced, so author it during the workshop to carry the rich mental
  model. (3) bootstrap surfacing already WORKS once anchored (copilot proved it) — not broken, just gated on (1).
  Net: the load-bearing fix is EARLY-ANCHOR + PER-LENS-BODY; bootstrap surfacing is already in place.
- **T050 round 1, copilot RESUME *repaired* the handover (2026-06-10) — the self-healing chain WORKS end-to-end:**
  on resume copilot DETECTED the hollow handover (bootstrap surfaced `handover_placeholder:true`), REPAIRED it
  (body now 6/6 AUTHORED, reconstructed from the disk artifacts), resumed at the specify boundary, and rendered a
  full Rule-46 verdict packet asking for the specify->clarify approval. So body-authoring is NOT impossible — it
  fires REACTIVELY on resume once the placeholder is surfaced (which requires the anchor). This completes the
  intended chain: anchored -> surfaced-as-placeholder -> agent repairs -> resumes at the gate -> renders the
  packet. **REVISED FIX PRIORITY:** the load-bearing change is **EARLY-ANCHOR** (anchor at workshop-start so the
  pre-specify workshop also gets anchored->surfaced->repaired, extending copilot's behavior to the codex/Claude
  mid-workshop case). **Per-lens body authoring drops to a robustness layer** — it captures the live
  in-conversation reasoning before a crash, vs the resume-repair's disk-reconstruction (most valuable where disk
  is sparse, e.g. codex which persisted nothing). Surfacing + resume-repair already work once anchored; the gate
  packet renders correctly on copilot. Round-1 validation is COMPLETE.
- **T050 FIX IMPLEMENTED (2026-06-10) — handover-only branch-feature stamp; the "early-anchor write-back" was
  NOT needed (advisor-corrected).** The round-1 design above called EARLY-ANCHOR (writing `feature_ref` into
  `start-context.json` early) the load-bearing fix. Re-reading the engine disproved that: `Resolve-SpecrewBootstrapMode`
  is **handover-first** — it returns `welcome-back` on `HandoverValid` BEFORE it ever consults the anchor. And
  `Test-SpecrewHandoverValidity` only needs the handover's `active_feature` to be present + not-merged + fresh. So
  the entire fix reduces to ONE thing: **the Stop floor-writer stamps `active_feature` resolved from the current
  branch when the persisted `feature_ref` is blank** (the pre-specify workshop window). No write to the central
  state file from any hook; no change to resume classification; every read-side guard intact.
  - **Built:** `Resolve-SpecrewBranchFeatureRef` in `scripts/internal/bootstrap/ProjectMetadataAccessor.ps1`
    (branch -> must match Spec Kit's `^\d{3}[-_]` contract -> `specs/<branch>/` must exist -> return it, else
    `$null`; on main / non-feature branch / deleted feature dir -> `$null`, fail-safe; reuses `Test-SpecrewFeatureLocal`,
    no engine dot-source). `scripts/internal/specrew-handover-provider.ps1` dot-sources the accessor and falls back
    to it when the anchor's `feature_ref` is blank. Extension mirror re-synced (ProviderMirrorParity green).
  - **Why branch-keyed, not a `specs/` disk scan (advisor):** the branch IS the feature slug in Spec Kit and is
    unambiguous in a MULTI-FEATURE repo; a disk scan is not. Tested: a feature whose dir exists on disk is NOT
    resolved when the current branch is a different feature (`tests/bootstrap/ProjectMetadataAccessor.Tests.ps1`).
  - **Re-anchor-to-closed-feature regression killed two ways:** the `specs/<branch>/`-exists guard (a deleted/closed
    feature -> `$null`) AND the read-side `Test-SpecrewHandoverValidity` (re-checks present + not-merged + the 24h
    freshness bound). Handover-only is strictly SAFER here than the write-back would have been (the anchor has no
    freshness bound).
  - **Proof:** 4 resolver unit tests + 1 anchorless-workshop integration test (the floor stamps `001-pomodoro-cli`
    from the branch — empty before the fix), full `tests/bootstrap` suite 20/20 green, and an end-to-end check:
    a blank-anchor workshop handover flips `Test-SpecrewHandoverValidity` invalid(`no-feature`)->valid and
    `Resolve-SpecrewBootstrapMode` `full`->`welcome-back` — so resume now SURFACES the handover -> the copilot
    resume-repair path fires on every host (the "resync takes minutes" symptom is the unsurfaced-handover full
    re-derive; surfacing it is the fix).
  - **Conduct (problem #1, "don't redo lenses on exit"):** strengthened design-workshop skill step 7 to checkpoint
    each lens durable (lens-applicability.json record + `workshop/<lens-id>.md` + a `Write-SpecrewHandoverContext`
    body refresh) BEFORE advancing, so a resume continues from the next un-persisted lens. Honest residual (advisor):
    this is a skimmed instruction — even copilot, which did everything else, skipped per-lens body authoring — so it
    stays agent-dependent; the DETERMINISTIC win is the surfaced handover above (resume-repair re-derives from disk).
  - **DEFERRED (escalate only if the live re-test shows it):** writing `feature_ref` into `start-context.json` from
    the **SessionStart** provider (never the Stop hook — it fires every turn) for a feature-correct resume *contract*
    + >24h durability + hard-kill (no-Stop-fired) coverage. No dogfood evidence yet that the feature-blind contract
    slows a *surfaced-handover* resume, so not pre-paid. Candidate follow-up: a deterministic mid-workshop lens-
    persistence floor (vs the agent-dependent conduct above).
