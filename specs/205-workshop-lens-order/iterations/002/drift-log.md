# Drift Log: Iteration 002

**Schema**: v2

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

**Total drift events**: 27
**Resolution rate**: 100% (5/5 resolved for this feature; DRIFT-001 to DRIFT-003 and DRIFT-005 class closure open; DRIFT-004 is a planning decision)
**Specification drift**: None detected

## Events

### DRIFT-001 — the quality-profile resolver read the stack as Node plus a browser SPA again (observation, recurrence)

- **Observed**: 2026-11-13, before-plan for iteration 002. `resolve-quality-profile.ps1` returned
  `quality-profile.custom-composition.v1` with stack signals `node-rest-with-postgres` and `react-spa-public`, and the
  plan scaffold called the scope "frontend-oriented".
- **Real stack**: PowerShell 7 scripts, lens markdown, the spec template and tests.
- **Resolution**: the plan states the real stack; the profile's required dimensions (code quality, design quality,
  verification confidence, maintainability) still apply.
- **Class closure**: NONE — the resolver is outside 205's scope. Recurrence of iteration 001's DRIFT-001 and feature
  203's plan-verdict finding.

### DRIFT-002 — the iteration plan scaffold rejects every requirement of this spec when given a scope (finding)

- **Observed**: 2026-11-13. `scaffold-iteration-plan.ps1 -RequirementScope FR-022,FR-024` refused with
  `Requirement(s) not found in spec: FR-022,FR-024`, although both are in `spec.md`'s Functional Requirements. The same
  script with no scope listed them. The plan was scaffolded without a scope and its scope written by hand, as in
  iteration 001.
- **Class closure**: NONE — the scaffold is part of the deployed extension. Candidate for feature 203's hand-over.

### DRIFT-003 — after a closed iteration, the clarify sync opens no approval point (finding, handed over)

- **Observed**: 2026-11-13. Recorded first as DRIFT-205-INTAKE-005 (feature-level intake drift log), before this
  iteration's folder existed. The clarify sync for Amendment A1 recorded its boundary but opened no crossing, so the
  amendment reaches planning with no approval of its own.
- **Resolution**: the maintainer approves A1 at this iteration's plan boundary.
- **Class closure**: NONE — the sync is feature 203's area. Handed over as H-015.

### DRIFT-004 — the review-signoff crossing is not planned capacity in this iteration (maintainer's decision)

- **Decided**: 2026-11-13, 13:19 local, by the maintainer, relayed by the reviewer session under the wider delegation
  with the question and the time. The question: the recorded Light workshop run is the only proof that the new
  workshop behaviour works, and its 2 SP were spent on the review-signoff crossing line, which does no work; option 1
  keeps the crossing line and moves the run to iteration 003, option 2 drops the crossing line and puts the run back.
  The maintainer's answer: "2".
- **Effect**: T026 is the recorded Light workshop run (2 SP, last, SC-012) instead of the crossing line. The plan stays
  at 20/20. The crossing's cost is not planned capacity in this iteration; the retro reports its actual cost, as
  iteration 001's did.
- **What it reverses**: the iteration 001 retro's calibration line (2 SP for the review-signoff crossing until H-003 and
  H-007 are fixed), for this iteration only.
- **Class closure**: NONE — a planning decision by the maintainer, not a defect. The underlying cost belongs to H-003
  and H-007 (feature 203); the retro reports it.

### DRIFT-005 — an INCONCLUSIVE test result failed the Deterministic gate on a records-only commit (external CI failure; handed over)

- **Observed**: 2026-11-13, Specrew CI run 43420704956 on `7d3b55b9`, Deterministic gate job (attempt 1), the F-198
  honesty regression suite: 1 of 131 files failed, `tests/unit/pretag-slice3-certify-findings.tests.ps1`, exit 2. The
  test reported itself `INCONCLUSIVE (fixture defect, NOT a pass)`, case f3: "the capped evidence-absent invocation
  emitted nothing at all — the cap path was never reached". Every other case in the file passed. The Contract lane was
  skipped.
- **Cause, as far as 205 can see**: `7d3b55b9` changed only iteration 002's `design-analysis.md`; the same suite passed
  on `2011e854` just before.
- **Resolution**: the reviewer session ruled one rerun (routine, under the maintainer's delegation). The rerun of job
  131871436437 passed (attempt 2: Lint, Self-leak firewall, Deterministic gate and Contract lane all green). The plan
  sync then ran bound to `7d3b55b9`. Recorded after the plan verdict, so no commit fell between the sync and the
  verdict.
- **Class closure**: NONE — the test and the stop-hook cap belong to feature 203. Handed over as H-017. It is a
  different test from those in H-006, and an inconclusive result that fails a gate is its own shape.

### DRIFT-006 — the scaffolded state.md lacked two canonical fields once the plan moved to executing (local check; fixed)

- **Observed**: 2026-11-13, local `validate-governance.ps1 -ProjectPath . -ChangedOnly` before pushing the
  before-implement boundary commit `22337b64`: iteration 002 `state.md` "is missing canonical field 'Current Phase'"
  and "... 'Iteration Status'". The same state.md passed CI on `f23f8941`; the verdict capture had moved the
  iteration plan's Status from planning to executing in between.
- **Cause, as far as 205 can see**: the iteration scaffold creates state.md without the two fields. The file passed
  while the plan said planning, and failed once the verdict capture moved the plan to executing. The capture moves
  plan.md but leaves state.md without the fields the validator then requires.
- **Resolution**: stopped before the push and reported. The maintainer answered "yes" to adding the two lines. The
  reviewer session then ruled the values (routine, under the maintainer's delegation): the same lines iteration 001
  carried during its build, `Current Phase: before-implement` (the last authorized boundary, not the activity) and a
  bare `Iteration Status: executing`, with the commit and next task in the Execution Summary. One records commit, the
  checks rerun, then both commits pushed.
- **Class closure**: NONE — the scaffold and the verdict capture belong to feature 203. Handed over as H-018.

### DRIFT-007 — the plan filed four problem questions under a solution lens (plan defect; placement ruled by the reviewer)

- **Observed**: 2026-11-13, at T021. The plan's twelve-question table (and spec FR-025's last line) put four questions
  under observability-resilience's `### Problem questions`. That lens is `space: solution` in index.yml by the
  maintainer's plan-verdict ruling of 2026-11-10, and has "No problem questions". lens-order-parity (FR-005c) fails a
  solution lens with problem questions and says the tag goes to the maintainer.
- **Ruling**: the reviewer session, under the maintainer's workshop delegation, 2026-11-13. Options that retag or move
  the lens were not open, since they would reverse the 2026-11-10 ruling. Each question goes where its subject lives:
  operator diagnosis to devops-operations; SLO/alerting and the domain's expected failures to requirements-nfr; what
  must never be logged to security-compliance; the observability budget is product-domain's budget fact.
  observability-resilience receives all four as hand-forward lines.
- **Resolution**: done as ruled. **FR-024's source is widened**: a hand-forward line may come from any earlier lens,
  not only product-domain, in the same line form, naming its source lens and the answer's key. The section is renamed
  `## Handed Forward From Earlier Lenses`, and the length test checks that the source runs earlier and defines the key.
  The recorded length numbers moved with the reviewer's agreement: Light 51/16/21 (was projected 51/16/18), Standard
  and Deep 66/16/6 (was 63/16/6). Light's must-answer count stays at 51. The plan's table, hand-forward text and length
  table are updated. No tag, lens order or parity rule changed.
- **Open (closed by DRIFT-010)**: spec FR-025's last line still named observability-resilience, and FR-024 still named
  only product-domain as a source. The maintainer decided to reword both; see DRIFT-010.
- **Class closure**: NONE — a planning error caught by the existing FR-005c check before anything shipped; that check
  is the mechanism that made it loud.

### DRIFT-008 — the deployed spec template copy is left without `## Problem Context` (as T024 directs)

- **Observed**: 2026-11-13, T024. The source `templates/specify/templates/spec-template.md` gains `## Problem Context`
  (the eleven consumer lines). Neither project-only deploy script (`deploy-speckit-extension.ps1`,
  `deploy-squad-runtime.ps1`) writes `.specify/templates/spec-template.md`; the init/update template deploy does, and
  `specrew update` is on the never-run list in this worktree.
- **Resolution**: the deployed copy is left as it is, per T024. The consumer test reads the source. Reported at the
  review stop: a project gets the new section on its next `specrew update`.
- **Class closure**: NONE — not a defect; the copy is refreshed by the normal update path outside this worktree.

### DRIFT-009 — macOS hook-output journal wrote two appends twice (external CI failure; handed over at higher severity)

- **Observed**: 2026-11-13, Cross-Platform Validation run 43478045076 on `0b3fc589`, attempt 1, job 132066984294
  "Deterministic fake-provider review runtime (macos-latest)", step "Hook-output journal concurrent append (case e)
  and outage buffer" (`tests/unit/journal-fault-injection.tests.ps1`): "FAIL: (e) the journal holds exactly one line
  per append (4002/4000)" and "FAIL: (e) no degraded health transition" (the health record went degraded, then
  recovered). The same job was green on Windows and Ubuntu; every other job of the run was green.
- **Cause, as far as 205 can see**: not 205's change. The push touched lens files, the workshop skill, the spec
  template, two tests and one CI step; nothing in the hook dispatcher or its journal. Two appends written twice reads
  as the journal's retry writing a line that had already landed: product behaviour in the dispatcher, not a slow test.
- **Resolution**: reported to the maintainer; one rerun ruled by the reviewer session under the maintainer's
  delegation (not covered by the standing co-review-service exception). Attempt 2 passed: macOS job 132081743155 and
  every other job green. `0b3fc589` is fully green.
- **Class closure**: NONE — the dispatcher's journal belongs to feature 203's area. Handed over as H-019 at the higher
  severity feature 206 gave HO-206-10 (the first macOS failure of the same case, with a different symptom).

### DRIFT-010 — spec FR-024 and FR-025 reworded to match the placement ruling (maintainer's decision)

- **Decided**: 2026-11-13, 21:36 local, by the maintainer, relayed by the reviewer session under the wider delegation
  with their words and the time. Asked whether to reword FR-024 and FR-025 to match what was built, their answer: "2:
  yes".
- **Cause**: DRIFT-007. The placement ruling moved observability-resilience's four problem questions to the lenses
  whose subject they are, and widened FR-024's source; the spec still said what the plan had said before.
- **Change**: `spec.md` FR-024 now says an answer may be handed forward from any earlier lens that defines it, not only
  product-domain, and the source lens must run earlier in index.yml; the "not stated" line names its source lens.
  FR-025 lists the four questions under the lenses that hold them (requirements-nfr twice, security-compliance,
  devops-operations) and says observability-resilience, a solution lens with no problem questions, receives them
  handed forward, with the observability budget as product-domain's budget fact. Nothing else in the spec changed.
- **Class closure**: NONE — a spec wording update decided by the maintainer; FR-005c and the length test's consumer
  check already make a misplaced question or an undefined hand-forward source loud.

### DRIFT-011 — the recorded Light workshop run (T026) is answered by the reviewer session, each reply confirmed by the maintainer first (maintainer's decision)

- **Decided**: 2026-11-13, 21:36 local, by the maintainer, relayed by the reviewer session under the wider delegation
  with their words and the time: "1: you answer, but with me, meaning you write here first your answer and the
  reason - in short. I say - send, or ask to change".
- **Plan said**: the maintainer types the replies in a host session.
- **Effect**: for every workshop question the reviewer session writes its proposed reply and a short reason in its own
  session; the maintainer says "send" or asks for a change; only then does the reviewer send the reply to the workshop
  session. The maintainer opens the host session, since the reviewer cannot open an interactive one. The T026 evidence
  records it this way: the replies were sent by the reviewer session, each confirmed by the maintainer beforehand; they
  are not the maintainer's typed turns in the workshop session. The run proves that a lens shows its recommendations
  as one list, that "accept" closes it, that the compliance question is asked at Light, and that the maintainer read
  and agreed each answer. It does not prove a person typing in that session. On this engine the workshop hook records
  the reviewer's messages as typed replies (feature 203's B5F-064); the evidence file is the truthful record of who
  answered.
- **Class closure**: NONE — a decision on how the evidence is gathered, not a defect.

### DRIFT-012 — the Windows review-runtime job hung and was cancelled at its limit, with no log kept (external CI failure; handed over as a second sighting)

- **Observed**: 2026-11-13, Cross-Platform Validation run 43494561579 on `70c8cea9`, attempt 1, job 132124152471
  "Deterministic fake-provider review runtime (windows-latest)". The step "Run bounded deterministic review fault and
  conformance suites" started at 21:44 local and never finished; the job was cancelled at 22:11 local, past its
  25-minute limit. GitHub kept no log for the cancelled job (the log request returns "BlobNotFound"), so which suite
  hung cannot be read. Every other job of the run was green, and the same suites passed on macOS and Ubuntu. On the
  seven runs of this branch before it, the same Windows job took 5 to 6 minutes.
- **Cause, as far as 205 can see**: not 205's change. `70c8cea9` and `2cba60de` changed only `spec.md` and this drift
  log.
- **Resolution**: reported to the maintainer; one rerun ruled by the reviewer session under the maintainer's
  delegation (not covered by the standing co-review-service exception). Attempt 2 passed on 2026-11-14 (Windows job
  132456949975, 5 min 22 s; every job green). `70c8cea9` is fully green.
- **Class closure**: NONE — the suites and the step belong to feature 203's area. Feature 203 already holds the same
  failure as B5F-067 (run 43270394765, 2026-11-12), with a proposal to run each suite under its own limit and print
  its name as it starts. Handed over as H-020, a second sighting of B5F-067, not a new item.

### DRIFT-013 — a push of Markdown records only needs markdownlint and the governance check (maintainer's standing rule)

- **Decided**: 2026-11-14, 15:23 local, by the maintainer, relayed by the reviewer session under the wider delegation
  with their words and the time: "203: yes", given to a question from the feature 203 crew; the reviewer told them it
  also sets a standing rule for the crews.
- **Rule**: when the only difference between the last commit on which the full pre-push checks were green and the
  commit to be pushed is Markdown records under `specs/` or `docs/`, markdownlint and the governance check are run and
  the push goes out; the workshop regression set need not be repeated for that difference alone. The changed-file list
  between the two commits is printed first, and every file must be a Markdown record. Anything else in the
  difference (a lens file, skill, template, script, test, deployed copy or hash record) gets the full checks as before.
  CI is still followed to its conclusion after every push.
- **Not changed**: the standing rerun exception still covers only `co-review-service.Tests.ps1:129`; the standing
  derived-block exception is unchanged.
- **Effect here**: the held records commits (`176882ff` and this one) may go out under it at the next push.
- **Class closure**: NONE — a process decision by the maintainer, not a defect.

### DRIFT-014 — the agenda shows one flat list, so the problem and solution parts are not visible (observation from the T026 run; candidate for iteration 003)

- **Observed**: 2026-11-14, during the recorded Light workshop run (T026), by the maintainer. The agenda rendered the
  selected lenses in index.yml order as one flat "Selected lenses" list; nothing on screen showed which lenses are
  problem-space and which are solution-space. Their words, at 19:44 local: "So in the agenda we do not show that there
  is a product part and a solution part? Is it good or bad? Also it would be nice to use colors if possible for the
  names of each lens".
- **Decided**: the reviewer session recommended three groups from index.yml's `space` tag (problem / both / solution),
  each with a text label and one coloured marker per group (not per lens), the marker repeated in each lens's opening
  heading; the text label stays because colour alone must not carry the meaning. The maintainer's answer, at 19:48
  local, relayed by the reviewer session under the wider delegation: "Agree with your recomandation of 3 parts, color
  per part." Skipped lenses stay in their own list.
- **Placement**: proposed for iteration 003 (labels only, not waiting on feature 203), on the reviewer's reading; the
  maintainer agreed with the recommendation without naming the iteration. It is put to them when iteration 003's plan
  is brought.
- **Effect in iteration 002**: none. Nothing changes for it in this iteration.
- **Class closure**: NONE — a presentation improvement found by the run, not a defect in what iteration 002 built.

### DRIFT-015 — what the T026 run found in the workshop's records (observations; for later iterations)

- **Observed**: 2026-11-14, the recorded Light workshop run (T026), from its transcript and records
  (`quality/t026-recorded-run.md`); the first two by the reviewer session, reading the records against the replies.
- **A stale open point**: the scratch feature's `product-domain.md` still ends with "How the external accountant
  reaches the shared folder ... is not yet stated", though security-compliance decision 2 answered it. The session
  updated product-domain's first-version list with the 30-day removal on its own initiative, but not that line. The
  skill asks for no write-back to an earlier lens's record today; the partial update was the session's own, not
  specified behaviour. The end-of-lens back-check, held for after feature 203, is what closes this gap.
- **An unlabelled inference**: `security-compliance.md` ends with "Controls that follow from the named threat actors
  (for plan)", derived by the session from the two threat actors the human named. Every decision row carries a Source;
  that section carries none, so a reader cannot tell it is the session's inference.
- **A hand-forward line outside the lens file**: data-storage opened with "Handed forward, security-compliance: files
  are removed 30 days after they are written". data-storage's lens file does not define that line and the source lens
  defines no key for it, so the length test does not count it. The two lines the file defines were shown as written.
- **Placement**: not decided here. All three are candidates for the iteration that holds the back-check; the second
  may fit iteration 003. They are put to the maintainer with iteration 003's plan. Nothing changes in iteration 002.
- **Class closure**: NONE — the run is the detector; the mechanism that would make these loud is the back-check, which
  is later work.

### DRIFT-016 — a typed turn got no turn token, so its turn-end declaration was refused (finding in the T026 run; handed over)

- **Observed**: 2026-11-14 19:38 local, in the T026 host session. The maintainer's correction of the reviewer's name
  arrived 19 seconds after the previous turn ended. No fresh `[specrew-turn]` token came with it; the session reused the
  previous turn's token, which Stop had consumed, and `declare-turn-end.ps1` refused: "the token '67d32311...' matches
  no live session in this project (0 live tokens)". Every other turn of the run got its own token. The session
  recorded it as D-001 in the scratch feature's drift log and reported it plainly; no workshop answer was affected.
- **Class closure**: NONE — the turn-token hooks belong to feature 203's area. Handed over as H-021.

### DRIFT-017 — the review round's verification plan still pointed at iteration 001 (re-pointed by ruling)

- **Observed**: 2026-11-14, preparing the review stop. `.specrew/verification-plan.json` (plan_id `f205.i001.v1`),
  which the round's preflight runs, still ran the governance check on iteration 001, which fails today on the standing
  derived-block exception. A round launched on it would fail preflight before the reviewer starts, as iteration 001's
  first launch did on feature 202's plan (iteration 001 DRIFT-008). It also lacked iteration 002's new test.
- **Ruling**: the reviewer session, routine and in plan, under the maintainer's delegation, 2026-11-14: re-point it to
  iteration 002, in one commit before the review-round ask, with the full checks because the file is JSON. Keeping the
  iteration 001 command, or leaving the plan, was refused for the same preflight failure.
- **Change**: plan_id `f205.i002.v1`. The governance command is now `iteration-002-governance-205` on iterations/002.
  `tests/unit/workshop-length-budget.tests.ps1` joins the suite list, with 12 suites and the count pinned to 12.
  The labels keep iteration 001's note not to restore the 202/199 lanes when 203 merges. The round's scope file
  `review-scope-round-1.md` is committed in the same commit, so it is in the reviewed tree.
- **Class closure**: NONE — the plan is project configuration that each iteration re-points by hand; making a stale
  plan loud at launch is feature 203's area.

### DRIFT-018 — review round 1's three findings fixed, failing test first (maintainer's decision; capacity over plan)

- **Round 1**: 2026-11-14, campaign `cmp-205-workshop-lens-order-i002`, run `run-20261114-192351085-49d20b6b`, codex
  on `3ddcd185`, 14 minutes, 1 of 4 rounds. Three findings, all minor, all in `tests/unit/workshop-length-budget.tests.ps1`,
  each confirmed against the code:
  1. SC-009 was not checked fact by fact. Exchanging the `compliance_regime` and `data_residency` suffixes left every
     total unchanged and passed. Reported as major; the engine demoted it for lack of a concrete failure scenario,
     though the finding states one.
  2. Exempt questions without a suffix were exempted by count, so replacing or rewording one passed.
  3. A `lens: <id>` consumer was accepted on catalog order alone, without the target receiving the answer.
- **Decided**: by the maintainer, at 21:44 local, relayed by the reviewer session under the wider delegation with their
  words and the time: "205: fix all". Fix all three now, each failing test first, then a second round. The pause
  question of round 1 stays open and is the maintainer's.
- **Capacity**: about 2 SP over the iteration's planned 20.
- **Ruling (finding 2)**: the identity check flagged product-domain area 4 ("Constraints"), to which T019 appended one
  pointer sentence. The reviewer session ruled, under the maintainer's delegation: keep it at its current text, with a
  comment saying why; no lens or template change. The exempt list holds 69 questions: 68 identical to `d4c11236` by
  normalized text, and area 4 at its current text. (The reviewer was first told "66 of 67"; that was a miscount,
  corrected here.)
- **Done**, one finding per fix commit, each after its red test commit:
  - finding 1: red `8347d9d5` (6 self-tests failing), fix `598d0836`;
  - finding 3: red `3a13eaa4` (4 failing), fix `22c0a583`;
  - finding 2: red `335de732` (3 failing), fix `398e9520`.
  No lens file changed. The shipped files pass the stronger checks unchanged.
- **Class closure**: the test itself is the mechanism. Each of the three shapes now fails loudly, and the self-tests
  prove it, including the reviewer's swap on a copy of the real catalog.

### DRIFT-019 — the scratch workshop run to the spec: supplementary observations (outside T026 and SC-012)

- **Run**: 2026-11-14, 19:35 to 21:56 local, session `specrew-205-t026-4a`, Light, eight lenses selected, ui-ux and
  integration-api skipped. The maintainer continued past T026's pass, with the reviewer session relaying each reply
  after the maintainer's go-ahead. The spec is committed in the scratch project (`55de1c4`), and the session stopped
  at the specify packet. The observations are the reviewer session's, from the transcript and the records.
- **Counts**:
  - 10 relayed replies answered workshop steps (prompts 3 to 12, verified from the transcript): product-domain, the
    agenda, and one per lens. Every lens closed on one reply.
  - 4 further relayed prompts (13 to 16) dealt with the post-close correction and the pre-spec check. The reviewer
    counts five such replies.
  - Must-answer questions shown, per the reviewer: product 5, requirements 6, security 6, data 6, operations 7,
    architecture 5, components 4, failures 5, code 6.
  - Recommendation lines shown: product 5, requirements 4, security 4, data 6, operations 4, failures 6.
- **What held**: iteration 002's deliverable. All eleven Problem Context lines in the spec are filled, with "not stated"
  and "not applicable" written out, and the compliance regime and residency reached the lenses that use them by name.
- **Observations** (candidates for later iterations; nothing changes in 002):
  1. **The pre-spec lint check stopped four times on the scratch project.** MD013 fired on the workshop's records,
     then MD013/MD033 and MD041 on `.specrew/last-start-prompt.md` and `.specrew/handover/session-handover.md`. It
     passed only after the session wrote a `.markdownlint.json` and a `.markdownlintignore`. Before that, the session
     reflowed ten records to 80 columns, which made tables and diagrams worse to read. **This is an artefact of how
     the T026 scratch project was built, not a defect a new user meets.**
     - `specrew init` runs `extensions/specrew-speckit/scripts/scaffold-governance.ps1` (called from
       `scripts/specrew-init.ps1:388`). Lines 313 to 344 write a project-root `.markdownlint.json` with MD013, MD033
       and MD041 off.
     - Init also adds the per-session patterns to `.gitignore` (`scripts/specrew-init.ps1:888-896`, patterns in
       `scripts/internal/file-classification.ps1:23-34`): `.specrew/last-*`, `.specrew/handover/`,
       `.specrew/runtime/` and the rest.
     - The gate lints only changed files that git does not ignore (`Get-ChangedMarkdownFiles`, `shared-governance.ps1`,
       `git ls-files -m -o --exclude-standard`).
     - The scratch project, built without init, had neither file, so the two `.specrew/` files were untracked and
       linted, and MD013 applied.
     - Two residual points are real, though not 205's: nothing tells the human why a lint stop happened; and the
       session's response, reflowing tables, was worse than asking. They are for the lint gate's owner to weigh.
     - The T026 build script is corrected for the future: a scratch project must also get init's `.markdownlint.json`
       and `.gitignore` patterns.
  2. **A correction after a lens closed.** The maintainer changed code-implementation's answer 2 (.NET 10 to .NET 11)
     after every lens had closed. The hook said the reply was not used, because the lens was closed. The session
     amended the readable record and `implementation-rules.yml` by hand, left `lens-applicability.json` alone, and
     logged it. On approval, the closing step accepted a re-record, but the entry still points to the first answer's
     receipt. This is the amendment flow iteration 004 holds.
  3. **Write-back happened in every later lens**, on the session's initiative:
     - one row per treatment written back into requirements-nfr;
     - the 30-day removal, the check command and the failure notice into product-domain's first-version list;
     - operating hours and alerting into product-domain and requirements-nfr.
     The component map was left as pending for design analysis, which is the better behaviour. product-domain's stale
     "open point" stayed stale. This is the DRIFT-015 gap; the back-check (iteration 004) closes it.
  4. **Labelling of the session's own inferences is inconsistent.** security-compliance has the unlabelled "Controls
     ... (for plan)" section (DRIFT-015), while devops-operations and observability-resilience label their notes "not
     as decisions". The spec labels them properly: an Assumptions section with nine readings and two NEEDS
     CLARIFICATION marks. One inference is missing there: its FR-021 has the tool remove run-record lines older than
     90 days, where the human said only "kept for 90 days".
  5. **For iteration 003's code-lens refresh (FR-030)**: the session looked versions up at run time and cited sources,
     but first called .NET 11 a short-support release, then corrected itself. The lens should require the lookup,
     its sources and the date, and should carry no version facts of its own.
  6. **For proposal 177** (workshop decisions reaching the coding agent): `implementation-rules.yml`, written by the
     code lens, is already described as "the rule set the coding agent and the reviewer read". Proposal 177's notes
     should start from what that file covers.
- **Class closure**: NONE — observations from an exploratory run; each is placed above with its owner or iteration.

### DRIFT-020 — `empty-result-retry` read a non-empty first attempt as empty on a records-only commit (external CI failure; handed over as a sighting)

- **Observed**: 2026-11-14, Specrew CI run 43635706006, attempt 1, job 132572686582, ubuntu-latest, on `b15c5dd1`
  (drift log only). Deterministic gate, step "F-198 honesty regression suite (NFR-007)": 1 of 131 failed, the only
  failure, `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1`, case "does NOT retry a non-empty result
  (single spawn, no retry telemetry)", line 86: `Expected regular expression '"run_id":"t108"' to match <empty>, but it
  did not match.` The first attempt's stdout came back empty. The Contract lane was skipped.
- **Resolution**: reported to the maintainer; one rerun ruled by the reviewer session, routine, under the maintainer's
  first delegation (not under the standing co-review-service exception). Attempt 2 passed (Deterministic gate job
  132576425761, Contract lane job 132582698037). `8ee7b109`'s Specrew CI passed on its first attempt. Recorded after
  review round 2, by the reviewer's ruling, so the sighting did not cost another CI cycle before the round.
- **Count**: the fifth sighting in the records. Feature 206's bug list item 3 lists four: `700e6127` and `cf01f599` on
  205's branch, `c2f2c67d` on 203's, `995851d2` on 206's.
- **Class closure**: NONE — the test and the code under it belong to feature 203; the test is on 205's do-not-edit
  list. Handed over as H-022.

### DRIFT-021 — the sign-off push takes iteration 001's knowingly-red path again (decision, this push only)

- **Observed**: 2026-11-15, after round 2. The local governance check fails iteration 002 on one item: "plan.md status
  'executing' is stale: review.md exists, so the iteration must be in reviewing, retro, or complete". The sync needs
  `review.md` on origin with state.md and plan.md still at `before-implement` / `executing` (DRIFT-013 of iteration
  001), so the commit it binds to fails that check again.
- **Decision**: the maintainer, relayed by the reviewer session under the wider delegation. The reviewer put two
  options: "205: allow" (this push only) or "allow, standing" (a standing exception for review-record and retro
  pushes). The maintainer's reply, at 01:19 local on 2026-11-15, quoted both back without choosing: "\"205: allow\" or
  \"allow, standing\"". Both allow this push, so the reviewer relayed the narrower reading and asked which was meant.
- **Resolution**: for this push only, `review.md` is pushed with that one named local failure; Specrew CI may be red on
  Lint for this push and on nothing else; the review-signoff sync binds to this commit; a fully green records push
  follows. A standing exception is not decided: the retro push of iteration 002 needs its own answer. H-022 waits for
  the push after the sign-off verdict, because only `review.md`, `drift-log.md` and `state.md` change between the last
  round and the sync.
- **Class closure**: NONE — the same gap as iteration 001's DRIFT-013 and H-007; the sign-off gate and the
  governance check are feature 203's area.

### DRIFT-022 — the review-signoff sync: a held hand-over, a gate that needed no override, and a corrected record (decision)

- **Observed**: 2026-11-15, after `fa65488d` was pushed.
  1. The first review-signoff sync refused, and nothing was changed: "Boundary gate preflight failed before
     packet/state mutation: - [working-tree] The boundary tree has 1 uncommitted product/methodology path(s); commit or
     dispose them before rendering a packet." The path was `handover-to-203.md` (H-022). It was held back because only
     `review.md`, the drift log and `state.md` change between the last round and the sync.
  2. The second sync passed. The gate's decision was "allow", reason "records-only-delta-does-not-stale", matched to
     round 2's run `run-20261114-205542888-e1efcdea`, with no override. No partial review signoff line was asked for.
  3. `review.md` as pushed in `fa65488d` said in three places that the records after round 2 rest on the maintainer's
     partial-coverage approval. The gate needed none, so those lines were wrong.
- **Rulings** (the reviewer session, routine, under the maintainer's delegation; rulings 2 and 3 were shown to the
  maintainer first):
  1. H-022 is held by exact path, not committed before the sync. The reviewer withdrew their earlier line that H-022
     goes in "with these records", because the standing file-limit rule wins. The copy was checked, and only that
     one file was restored to HEAD before a single rerun of the sync.
  2. The Deterministic gate and the Contract lane, skipped on `fa65488d` only because of the allowed Lint item, are
     acceptable for that push. They ran green on `b15c5dd1`, and they must run green on the first records commit
     after the verdict.
  3. The `review.md` correction follows the verdict, so the tree does not move before it. The packet named the three
     wrong lines in plain words.
- **Resolution**: the maintainer typed `approved for review-signoff`; boundary commit `9c9a132f`. H-022 is back, and the
  three `review.md` lines are corrected in the records commit after it.
- **Class closure**: NONE — a record written before the sync must guess whether the gate will want an override; the
  gate's decision is known only after the record is pushed. That belongs to the sign-off gate, which is feature 203's
  area (iteration 001's H-007 is the same seam).

### DRIFT-023 — Cross-Platform Validation's Windows job could not install Pester (external CI failure)

- **Observed**: 2026-11-14 23:22:51Z, Cross-Platform Validation run 43652924955, attempt 1, job 132625113293,
  "Deterministic fake-provider review runtime (windows-latest)", step "Verify PowerShell and install pinned Pester",
  on `fa65488d` (two Markdown records): `Install-Package: No match was found for the specified search criteria and
  module name 'Pester'. Try Get-PSRepository to see all available registered module repositories.` It then threw
  `pester-allusers-install-failed`. No test ran. The other seven jobs were green, among them the same job on macOS and
  Ubuntu.
- **Resolution**: reported first. One rerun of the failed job was ruled by the reviewer session (routine; infrastructure
  outside the push). Attempt 2 was green in all eight jobs (Windows job 132627411329).
- **Class closure**: NONE — the cause is the package gallery or the runner, not 205's change, and it differs from the
  `empty-result-retry` sighting (DRIFT-020). The workflow is not 205's to change.

### DRIFT-024 — the derived-block item now also fails iteration 002 locally; covered by the standing exception (reviewer's reading)

- **Observed**: 2026-11-15, the full checks on `38aebf0e`. Once plan.md was at `reviewing`, the local governance check
  failed iteration 002 on the item iteration 001 already fails: "review.md carries no derived independent-review
  block, and this record was written after the block existed (its authorship was observed: implementing-session)".
- **Ruling**: the reviewer session, routine, 2026-11-15 02:58 local. The item is covered. It is the same item with the
  same cause as iteration 001's: the block is computed from a review store that exists only on the machine that ran
  the review (iteration 001 DRIFT-012). The maintainer's exception is a standing one for that item, not for one
  iteration. This is the reviewer's reading of the standing exception. Anything else red, locally or in CI, still
  stops the work.
- **Resolution**: the block is not added. `review.md`'s Independence section says what the record's independence rests
  on.
- **Class closure**: NONE — the derived block's store is local to the reviewing machine; that is the review engine's
  area (feature 203), as in iteration 001.

### DRIFT-025 — the retro push is red on Lint by the maintainer's allowance, this push only (decision)

- **Decided**: the maintainer, relayed by the reviewer session under the wider delegation. The reviewer summarized the
  drafted retro and said it waits on "allow" (this push only) or "standing". The maintainer's words, at 03:52 local on
  2026-11-15: "OK for the retro, but it raises a question." The question that followed was about what happens to
  retro findings afterwards, not about the push. The reviewer relayed it as "allow" for this push; the maintainer did
  not say "standing".
- **Effect**: `retro.md` and DRIFT-024 to DRIFT-026 are pushed with one red Specrew CI run, on Lint only, for "plan.md
  status 'reviewing' is stale: retro.md exists" plus the standing derived-block item. Anything else red stops the
  work. Then the retro sync and the retro packet.
- **Class closure**: NONE — the record order at the retro boundary is a bug list item on feature 206 (maintainer,
  2026-11-14 22:39) and a candidate for 206's iteration 002; H-003 is the hand-over.

### DRIFT-026 — the retro scaffold again refuses a review verdict that wraps onto a second line (recurrence)

- **Observed**: 2026-11-15, at the start of the retro. `scaffold-retro-artifact.ps1 -IterationDirectory
  .\specs\205-workshop-lens-order\iterations\002` stopped with `review.md contains an invalid overall verdict:
  'accepted: two rounds; round 1's three minor findings fixed failing-test first; round 2 passed with'.` It read only
  the first line of the wrapped `**Overall Verdict**`. The governance check accepts the same `review.md`. This is
  iteration 001's DRIFT-024 again.
- **Resolution**: `retro.md` was written by hand to the ceremony's output contract, as in iteration 001. `review.md`
  was not changed.
- **Class closure**: NONE — the scaffold is part of the deployed Specrew extension, which 205 does not change for this;
  it is the second sighting of iteration 001's DRIFT-024.

### DRIFT-027 — the closed iteration's records corrected after the closeout verdict, then resealed (maintainer's decision)

- **Observed**: 2026-11-15, after the closeout boundary commit `4c6108fa`, before any push.
  1. The dashboard was drawn by the closeout sync before the verdict, so it read "phase RETRO". It did show iteration
     002 as closed, with 20 SP.
  2. With plan.md at `complete`, the governance check failed iteration 002 on "Complete iterations must record a
     Completed date in plan.md" and "hardening-gate.md still requires runtime evidence or explicit closure
     follow-through for concern(s): error-handling-expectations, test-integrity-targets". This is the same pair as
     iteration 001's closeout.
- **Decided**: the maintainer, relayed by the reviewer session under the wider delegation, for features 205 and 206. The
  reviewer's question was: "add the Completed date, close the hardening rows with evidence, redraw the dashboard if
  needed, reseal and push". The maintainer's words, at 04:55 local on 2026-11-15, quoting that wording back:
  "\"closeout fixes: yes\"."
- **Resolution**:
  - plan.md Completed is 2026-11-15.
  - The two hardening rows are closed with runtime evidence from `quality/quality-evidence.md` and CI.
  - The dashboard was redrawn with `scripts/specrew-where.ps1 -CaptureKind iteration-closeout`, the command feature
    206 used. It was tried first on a scratch worktree at `4c6108fa`, which was removed by its exact path. It now
    reads "phase ITERATION-CLOSEOUT".
  - `specrew reseal --feature 205-workshop-lens-order --iteration 002` resealed the folder. It reported plan.md,
    dashboard.md and quality/hardening-gate.md as drifted, then touched nothing else.
  - Iteration 001's folder was not touched. The home hook files were unchanged.
- **Class closure**: NONE — the closeout sync draws the dashboard before the verdict and does not fill the Completed
  date or the hardening rows; that is the lifecycle engine's area (feature 206 met the same three items).

<!--
  Every new ### DRIFT-... event includes:

  - **Class closure**: the executable mechanism that makes the next instance impossible or loud

  If the change fixes only this instance, write NONE — <why class closure is not in scope>.
  A bare Resolution: FIXED is not class closure.
-->

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
