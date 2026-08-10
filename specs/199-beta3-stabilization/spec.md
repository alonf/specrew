# Feature Specification: Beta3 Stabilization (v0.40.0-beta3)

**Feature Branch**: `199-beta3-stabilization`
**Created**: 2026-08-10
**Status**: Draft
**Input**: User description: "Build the v0.40.0-beta3 release of Specrew: a narrow stabilization release whose one goal is also its acceptance bar — a consumer completes their first feature without hitting an endless review loop, a wedged gate, or a sentence they cannot understand. Scope is CLOSED to the Beta3 section of the 198 carry ledger (ten items); the beta4 section is out of scope."

**Input of record**: the findings ledger at `C:\Dev\specrew-beta2-hardening\specs\198-beta2-hardening\beta3-carry-ledger.md` (committed at b9c5bacb on branch 198-beta2-hardening; read-only input) and the feature closeout at `C:\Dev\specrew-beta2-hardening\specs\198-beta2-hardening\closeout.md`. Workshop decisions in `specs/199-beta3-stabilization/workshop/` and `lens-applicability.json` are binding design inputs.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The consumer survives the review loop (Priority: P1)

A consumer developer runs their first governed feature. After EVERY review campaign
round, the loop pauses: spend stops, the console frees, and one decision surface shows
the findings by severity, the cumulative cost, a severity-derived recommendation, and
numbered options. Continuation is always their explicit choice; when they choose "stop
here", the whole landing (final check on their files exactly as they are, remaining
findings saved as follow-ups, review sign-off completed) happens as one action.

**Why this priority**: The endless review loop is the headline failure (ledger F8 — the
review-loop economics finding: 20 runs, 15 fix rounds, 79 findings before a line of
code); it is the first clause of the acceptance bar, and the ledger records that a
rational consumer's response to it is disabling the campaign.

**Independent Test**: Run a campaign round through the shipped entry point in a fixture
project; verify the decision surface renders after ingest, the engine exits, no further
spend occurs without a numbered reply, and the stop-here option completes sign-off
without manual gate untangling.

**Acceptance Scenarios**:

1. **Given** a campaign round has just ingested reviewer results, **When** the round
   completes, **Then** the engine renders the decision surface (findings by severity
   with locations, non-gating minors, cost in rounds and minutes, budget position,
   one-line recommendation, three numbered options) and exits without launching
   another round.
2. **Given** the decision surface is pending, **When** no human reply has been given,
   **Then** no reviewer invocation, spend, or continuation occurs.
3. **Given** the human chooses "stop here", **When** the landing runs, **Then** the
   frozen-tree verification, identity-bound residual acceptance, and gate
   synchronization complete as one action with no signoff-gate collision left for the
   human to resolve by hand.
4. **Given** the digest's round budget (default 4) is exhausted, **When** any
   continuation is attempted, **Then** the engine refuses until the human explicitly
   resets the allowance.
5. **Given** only minor findings remain, **When** the round completes, **Then** the
   minors are recorded as follow-ups and never gate sign-off.

---

### User Story 2 - The consumer's gates never wedge (Priority: P2)

The consumer commits governance records, or has an authorized review run in flight, or
is looking at a pending pause decision — and the campaign stop surface stays coherent:
one authority, no stale-review demands the sign-off gate already answered, no blocks
for work that is already running.

**Why this priority**: The two-governors disagreement (ledger F5 — stop-gate reads only
terminal results) forced an agent to adjudicate between contradictory gate rulings — a
call a consumer cannot make; the treadmill (recording the gate's decision re-staled the
gate) makes currency unachievable by construction.

**Independent Test**: Reproduce the F5 instances as fixtures: a records-only commit
after a reviewed state, an authorized in-flight run at stop time, and a pending pause
decision — verify zero stop-blocks fire in each.

**Acceptance Scenarios**:

1. **Given** a reviewed state followed by a commit touching only governance/records
   files, **When** the stop surface evaluates, **Then** no stale-review block fires.
2. **Given** an authorized review run in flight, **When** the stop surface evaluates,
   **Then** the block is suppressed rather than demanding an already-granted action.
3. **Given** a completed round with its decision surface rendered and unanswered,
   **When** the stop surface evaluates, **Then** the pending pause decision is treated
   as quiet — no review demand, no disposition demand.
4. **Given** the sign-off gate has recorded an allow decision, **When** the campaign
   stop surface evaluates the same state, **Then** it consults that decision and does
   not contradict it.

---

### User Story 3 - The maintainer's verdicts always capture (Priority: P2)

A human replies to a boundary stop with a recognized approval phrase — possibly
followed by instructions, possibly after discussion turns, possibly using words like
"clarify" or "prompt" as plain English — and the verdict is captured exactly as given.

**Why this priority**: Verdict-capture defects were root-caused at the 198 closure with
reproductions (iteration 011): instruction text containing "prompt" flipped approval to
discuss; first-human-turn shadowing lost verdicts; "clarify" in filename prose parsed
as a boundary name. A lost verdict wedges the lifecycle at its most human-critical
point.

**Independent Test**: Replay the iteration 011 reproductions as capture fixtures
through the real Stop-hook entry point; verify each captures per the response contract.

**Acceptance Scenarios**:

1. **Given** a reply beginning with a recognized approval phrase followed by
   instruction wording, **When** capture runs, **Then** it records
   approve-with-instructions — the leading phrase wins over any wording that follows,
   and the classifier and response contract agree.
2. **Given** a verdict given after intervening non-verdict turns since the boundary
   marker, **When** capture runs, **Then** the scan finds the verdict past the
   non-verdict turns instead of examining only the first turn.
3. **Given** a reply using boundary-name words as plain English ("please clarify the
   wording", "the prompt file"), **When** capture runs, **Then** classification does
   not flip to a different verdict class on those words.

---

### User Story 4 - The OneDrive consumer can run campaigns (Priority: P2)

A consumer whose Documents folder lives under OneDrive Known Folder Move installs
Specrew with the default `Install-Module -Scope CurrentUser` and runs a review
campaign. Cloud-placeholder files are hydrated and verified; only real folder links
are refused, with a message that says what happened and what to do.

**Why this priority**: The default corporate install path is unusable today (ledger
F1); T067's agent had to hand-copy the module to work around it. This is the most
consumer-common install shape.

**Independent Test**: Tag-classifier fixtures with real reparse-tag constants
(cloud-family accepted, junction/symlink/unknown refused); junction and symlink
filesystem fixtures stay green; the hydration leg measured manually on the recorded
T067-class environment with the proof line transcribed and scoped.

**Acceptance Scenarios**:

1. **Given** a module tree containing cloud-placeholder files, **When** the integrity
   check runs, **Then** placeholders are hydrated, hash-verified, and accepted (trust
   rests on the hash of hydrated bytes, never the placeholder).
2. **Given** a junction or symlink inside a containment root, **When** the integrity
   check runs, **Then** it is refused exactly as in beta2, and the refusal message
   states what happened and the next step in consumer language.
3. **Given** a reparse point with an unknown tag, **When** the integrity check runs,
   **Then** it is refused (allowlist, not blocklist).

---

### User Story 5 - The fresh-project consumer bootstraps (Priority: P3)

A consumer runs `specrew init` on a fresh project and gets a starter verification plan
(governance validator plus dotnet/npm build-test templates, with a working env_refs
allowlist). When verification fails, the error names the missing piece and the exact
next step instead of sealing the cause behind diagnostics.

**Why this priority**: T067's agent reverse-engineered the plan schema by hand (ledger
F2 — no verification-plan bootstrap) and met an empty-environment failure whose cause
was sealed (F3 — env_refs sanctioned but undiscoverable).

**Independent Test**: Fresh-project fixture: run init, verify the scaffolded plan
passes campaign preflight; break each named piece (env_refs, plan schema, defer-record
format) and verify each error names it.

**Acceptance Scenarios**:

1. **Given** a fresh project, **When** `specrew init` completes, **Then**
   `.specrew/verification-plan.json` exists with the governance validator, dotnet/npm
   build-test templates, and the default env_refs allowlist (PATH, PATHEXT,
   SYSTEMROOT, COMSPEC, TEMP, TMP, TMPDIR, HOME, USERPROFILE, APPDATA, LOCALAPPDATA,
   PROGRAMFILES, PROGRAMFILES(X86), PROGRAMDATA), and campaign preflight passes.
2. **Given** a verification command failing because a needed environment variable is
   not in env_refs, **When** the error renders, **Then** it names `env_refs` and shows
   the exact line to add.
3. **Given** an invalid plan or a malformed defer record, **When** the failure
   renders, **Then** the error names the schema element or required defer format
   rather than a generic verification-command-failed.

---

### User Story 6 - The consumer understands every sentence (Priority: P3)

Every sentence Specrew shows a human is about their project and their decision. IDs
are always glossed. Decision stops arrive as one message. The banner tells beta
consumers which channel they are on.

**Why this priority**: The acceptance bar's third clause. T067's sign-off prose
required six pieces of internal machinery knowledge in two sentences (ledger F6);
decision stops arrived as hook bounces (208 rule); the banner hid the prerelease tag
(obs-2 — the banner version finding).

**Independent Test**: Rendered-surface fixtures: zero banned machinery nouns and zero
unglossed IDs across packet templates, stop messages, skill instructions, and the
banner; banner fixture asserts the full prerelease string.

**Acceptance Scenarios**:

1. **Given** any consumer-facing surface (packet template, stop message, skill
   instruction, orientation banner), **When** it renders, **Then** it contains none of
   the banned machinery nouns (crossing, mint, marker, digest, boundary sync, verdict
   capture, controller truth, ratchet, claim-ordered, terminalize); lifecycle stage
   names and approval phrases remain by design.
2. **Given** a task/requirement/finding reference in human-visible prose, **When** it
   renders, **Then** it carries both the identifier and a short plain description via
   the gloss helper ("task T007 — the external URL checker"); records keep bare IDs.
3. **Given** a decision stop, **When** it renders, **Then** the context packet and
   decision surface arrive as ONE message; a stop-hook bounce at a decision stop is an
   instruction defect.
4. **Given** a prerelease install, **When** the orientation banner renders, **Then**
   it shows the full version including the prerelease tag (0.40.0-beta3).

---

### User Story 7 - The review window fits the reviewer (Priority: P3)

A consumer's codex-class review of a planning-scale digest gets a 900-second default
window, and a timeout tells them which setting to change.

**Why this priority**: Ledger F7 — the review-window miscalibration: a 300 s default
silently killed a codex run that produced real findings when given 900 s.

**Independent Test**: Catalog fixture asserts the codex row's default window is 900 s;
timeout-message fixture asserts the message names `co_review_timeout_seconds`.

**Acceptance Scenarios**:

1. **Given** a codex-class reviewer with no explicit window configured, **When** the
   window resolves, **Then** the default is 900 seconds; other hosts are unchanged.
2. **Given** a review that exceeds its window, **When** the timeout message renders,
   **Then** it follows the what-happened / what-it-means / exact-next-step shape and
   names `co_review_timeout_seconds`.

---

### Edge Cases

- Budget exhausted while the human chose fix-and-continue: the engine refuses the next
  round and the refusal message offers the explicit reset action.
- Session exits while a pause decision is pending: on resume the same decision surface
  is re-rendered from persisted state; the pending state stays quiet to the stop
  governor.
- Cloud placeholder whose hydrated bytes fail hash verification: refused as corruption
  (same as any hash mismatch), not accepted because the tag was allowlisted.
- Infrastructure failure sequence (preflight-failed, claim-contended, launch-failed):
  run records publish honestly; the allowance is untouched (ledger F4 — infra failures
  consuming rounds).
- A reviewer returns findings via file with empty stdout (codex quirk): out of scope,
  recorded beta4 watch item; the harvest path recovers today.
- An approval reply that itself contains the word "prompt" or "clarify" inside the
  instruction tail: captures as approve-with-instructions (US3 scenario 1/3 compose).

## Requirements *(mandatory)*

### Functional Requirements

Review-loop economics (bridge — beta4 replaces the pause plumbing; the decision-surface
contract is durable):

- **FR-001**: After every campaign round's ingest, the engine MUST render the decision
  surface and terminate the round loop (pause as the orchestrator's terminal state);
  no reviewer invocation or spend may occur while the decision is pending.
- **FR-002**: The decision surface MUST show findings grouped by severity with
  locations, minors as visibly non-gating, cumulative cost (rounds, minutes), budget
  position, a one-line severity-derived recommendation, and three numbered options
  (fix-and-continue / stop-here / abandon) whose consequences are stated in the option
  text, plus the explicit nothing-spends-until-you-answer line.
- **FR-003**: Continuation MUST always be an explicit human choice consuming a
  single-run grant; agents MUST NOT mint continuation authorizations from a prior
  grant; a default round budget of 4 per digest MUST force refusal of further rounds
  once exhausted until the human explicitly resets the allowance.
- **FR-004**: Minor findings MUST never gate sign-off; they are auto-carried as
  recorded follow-ups.
- **FR-005**: The stop-here option MUST compose the full landing as one action:
  frozen-tree verification run, identity-bound residual acceptance, and gate
  synchronization — never leaving the human to discover a signoff-gate collision.
- **FR-006** (durable): The reviewer prompt contract changes from a findings-goal to a
  verdict-goal: a justified clean verdict naming what was verified is a blessed
  output; every finding must state a concrete failure scenario or it is not a
  finding; output is ranked and capped. (Machine-readable consequence tags are beta4.)

Single-authority stop surface (bridge — beta4's stop-surface state model subsumes the
point checks; consult-before-block and pending-decision-quiet are the durable
semantics):

- **FR-007**: The campaign stop surface MUST consult the signoff-gate decision store
  before firing a block and MUST NOT contradict a recorded gate decision.
- **FR-008**: An authorized in-flight review run MUST suppress the stop-block; a
  pending pause decision (round complete on the current tree, surface rendered, human
  unanswered) is a sanctioned quiet state demanding neither review nor disposition.
- **FR-009**: Commits touching only governance/records files MUST NOT stale a reviewed
  digest.

Verdict capture (durable):

- **FR-010**: A leading recognized approval phrase MUST win over any instruction
  wording that follows (approve-with-instructions captures; the response contract and
  the classifier agree); capture MUST scan past non-verdict turns instead of examining
  only the first turn after a marker; boundary-name words appearing as plain English
  MUST NOT flip classification. Reproductions: the iteration 011 closeout notes.

OneDrive / reparse policy (durable):

- **FR-011**: The review engine's integrity check MUST discriminate reparse tags:
  cloud-family placeholders are hydrated then hash-verified; junction/symlink tags
  remain refused; unknown tags are refused (allowlist). The policy is symmetric across
  module install, authority store, and frozen snapshot. The refusal message follows
  the consumer message shape; the default CurrentUser install path MUST be able to run
  campaigns. Docs carry the AllUsers alternative and one advisory sentence on synced
  folders.

Campaign bootstrap (durable):

- **FR-012**: `specrew init` MUST scaffold a starter verification-plan.json
  (governance validator + dotnet/npm build-test templates) with the default env_refs
  allowlist (N4 list including TMPDIR).
- **FR-013**: Verification failures MUST name the missing piece (env_refs, plan
  schema, defer-record format) in the error with the exact next step, not seal it
  behind diagnostics.

Review economics accounting (durable):

- **FR-014**: Only rounds that actually invoked a reviewer consume the round
  allowance; preflight/infrastructure failures publish run records but consume
  nothing (aligned to the legacy spend-class rule).

Consumer-language layer (durable):

- **FR-015**: Every human-visible sentence MUST be about the user's project and the
  user's decision; the banned machinery nouns MUST NOT appear in consumer surfaces
  (packet templates, stop messages, skill instructions, orientation banner); lifecycle
  stage names and approval phrases remain consumer-visible by design. Enforced by a
  failing test, not review notes.
- **FR-016**: Human-visible prose MUST render task/requirement/finding IDs through the
  gloss helper requiring id + title; records keep bare IDs canonical. An unglossed ID
  in a consumer surface is a failing test.
- **FR-017**: Decision stops MUST render context packet and decision surface as ONE
  message; a stop-hook bounce at a decision stop is an instruction defect (208 rule,
  instruction layer).

Review windows (durable):

- **FR-018**: The codex-class default review window MUST be 900 seconds
  (planning-scale digests); other hosts unchanged; the timeout message names
  `co_review_timeout_seconds` in the consumer message shape.

Version truth and records (durable):

- **FR-019**: The orientation banner and every version render MUST show the full
  prerelease version (0.40.0-beta3, never a bare 0.40.0); the deployed mirror updates
  in lockstep.
- **FR-020**: The flagged 009/010 registry-vs-claim wording inconsistency is resolved
  records-only (specifics pulled from the 198 records during implementation).

Release (per the devops lens record):

- **FR-021**: The release follows the beta2 discipline: certification review before
  the tag, tag v0.40.0-beta3 at the merge commit, publish workflow, Gallery
  verification. Release notes MUST carry: what this release fixes (the review-loop
  experience), the updated known-issues list, and the explicit sentence that the
  evidence-pipeline and path-identity consolidations named in the beta2 claim ship in
  beta4. Stable promotion is out of scope (beta-stable model).
- **FR-022**: The markdownlint-cli CI install lands as release hygiene (198-carried
  chore, ruled in scope under the closed-scope exception).

Method (binding on every fix):

- **FR-023**: Every fix lands RED-first with an instance-pinned fixture through the
  SHIPPED path including the real event entry points; proof lines are transcribed
  from measurements, never drafted ahead; records state facts and never evaluate
  Specrew's own components; evidence tools are verified before their output is
  trusted. Bridge design records name, per bridge item, what beta4 is expected to
  replace.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: US1 -> FR-001..FR-006; US2 -> FR-007..FR-009; US3 -> FR-010; US4 ->
  FR-011; US5 -> FR-012..FR-013; US1/US5 -> FR-014; US6 -> FR-015..FR-017, FR-019,
  FR-020; US7 -> FR-018; release leg -> FR-021..FR-022; all -> FR-023.
- **TG-002**: Owner roles: implementer (engine/scripts/tests), spec-steward
  (records/claim alignment), reviewer (codex campaign + certification), maintainer
  (all boundary verdicts, release rulings, manual OneDrive measurement).
- **TG-003**: Single iteration (001) for all FRs; the release leg (FR-021) executes at
  feature-closeout per the resolved beta-stable model.
- **TG-004**: Scope is CLOSED: anything discovered during this feature goes to the
  ledger's beta4 list unless it blocks the acceptance bar itself; the reconciliation
  path for any spec/implementation conflict is a drift-log entry citing the governing
  FR plus a maintainer ruling.

### Key Entities

- **Decision surface**: the per-round pause rendering — findings by severity,
  non-gating minors, cost, budget position, recommendation, numbered options.
- **Round allowance / budget**: per-digest spend state; default 4; consumed only by
  reviewer-invoked rounds; reset only by explicit human action.
- **Signoff-gate decision store**: the recorded allow/block decisions the stop surface
  must consult (`.specrew/review/signoff-gate/latest.json` + history).
- **Pending pause decision**: sanctioned quiet state — round complete on current tree,
  surface rendered, human unanswered.
- **Verification plan**: `.specrew/verification-plan.json` — commands, templates, and
  the env_refs allowlist scaffolded by init.
- **Reviewer-host catalog row**: per-host defaults including the review window.
- **Gloss helper**: renders id + title for every ID in consumer prose.

## Success Criteria *(mandatory)*

### Measurable Outcomes

Each criterion is proven by a RED-first fixture through the shipped entry point
(FR-023); the ten were confirmed at the requirements-nfr lens:

- **SC-001**: After every campaign round the decision surface renders and nothing
  spends until a numbered human reply.
- **SC-002**: Budget exhaustion hard-refuses continuation without an explicit human
  reset.
- **SC-003**: Zero stale-review blocks on records-only deltas; an authorized in-flight
  run suppresses the block; a pending pause decision is quiet.
- **SC-004**: Stop-here composes frozen-tree verification + residual acceptance + gate
  sync as one action.
- **SC-005**: Leading approval phrase with trailing instructions captures as
  approve-with-instructions; capture scans past non-verdict turns; "clarify"/"prompt"
  as plain English never flip classification (iteration 011 reproductions).
- **SC-006**: Cloud-placeholder install hydrates and verifies; junction/symlink still
  refuses; refusal message is consumer-shaped.
- **SC-007**: Fresh project + `specrew init` passes campaign preflight.
- **SC-008**: Infrastructure failures leave the allowance intact.
- **SC-009**: Zero machinery nouns and zero unglossed IDs in rendered consumer
  surfaces.
- **SC-010**: The banner renders the full prerelease version (0.40.0-beta3).

## Assumptions

- The beta3 carry ledger (b9c5bacb) is the closed scope of record; its beta4 section
  is out of scope; new discoveries route there unless they block the acceptance bar.
- One iteration, ~10–12 SP planned against the 20 SP convention.
- Beta4 redesigns the disposition vocabulary and the evidence/authorization pipelines;
  bridge items stay minimal and each bridge design record names its beta4 replacement.
- The end-to-end OneDrive hydration leg is verified by manual measurement on the
  recorded T067-class environment (no CI sync root); the proof line is transcribed
  from that measurement and scoped.
- The 198-inherited implementation rules (`implementation-rules.yml`) bind the
  implementation; reviewer host codex is human-authorized for the campaign.

## Governance Alignment *(mandatory)*

- **Spec Steward**: maintainer (Alon Fliess) with the spec-steward agent; the ledger
  is read-only input of record.
- **Iteration Facilitator**: coordinator (this session) under the governed lifecycle;
  boundary verdicts are the maintainer's alone.
- **Capacity Model**: story points; 20 SP iteration convention; ~10–12 SP planned for
  the single iteration.
- **Drift Signals**: drift-log.md entries with FR citations; validator/parity checks
  at each boundary; amendment accumulation surfaced at the next boundary as a
  diff-to-approve (198 obs-7 lesson — unratified post-boundary amendments).
- **Human Oversight Points**: specify, clarify, plan, tasks, before-implement,
  review-signoff, retro, iteration-closeout, feature-closeout — all
  human-judgment-required per the boundary policy; release mutations (push, PR,
  publish) each need the maintainer's explicit go.
