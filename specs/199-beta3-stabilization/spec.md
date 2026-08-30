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
4. **Given** the campaign's round budget (default 4) is exhausted, **When** any
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
(cloud-family hydrated, junction/symlink refused, non-linking admitted — the fixture
values MEASURED from a real install, not composed); junction and symlink filesystem
fixtures stay green; a source guard proving no call site downstream of the classifier
executes admitted content; the hydration leg measured manually on the recorded
T067-class environment with the proof line transcribed and scoped.

**Acceptance Scenarios**:

1. **Given** a module tree containing cloud-placeholder files, **When** the integrity
   check runs, **Then** placeholders are hydrated, hash-verified, and accepted (trust
   rests on the hash of hydrated bytes, never the placeholder).
2. **Given** a junction or symlink inside a containment root, **When** the integrity
   check runs, **Then** it is refused exactly as in beta2, and the refusal message
   states what happened and the next step in consumer language.
3. **Given** a reparse point that is neither a link nor a cloud placeholder, **When**
   the integrity check runs, **Then** it is admitted as ordinary content and trusted on
   the hash of the bytes actually read, and no call site downstream of the classifier
   executes what was admitted — it is only read, hashed, and containment-checked.
   *(AMENDED 2026-08-11 by maintainer ruling; was "an unknown tag ... is refused
   (allowlist, not blocklist)". Refusing every unrecognised tag refused the real
   OneDrive case this story exists to fix. See FR-011 and DRIFT-199-I001-024, -031.)*

---

### User Story 5 - The fresh-project consumer bootstraps (Priority: P3)

A consumer runs `specrew init` on a fresh project and gets a strict starter verification
plan (governance validator plus a working env_refs allowlist) and a sibling guide containing
copy-ready dotnet/npm build-test templates. When verification fails, the error names the missing piece and the exact
next step instead of sealing the cause behind diagnostics.

**Why this priority**: T067's agent reverse-engineered the plan schema by hand (ledger
F2 — no verification-plan bootstrap) and met an empty-environment failure whose cause
was sealed (F3 — env_refs sanctioned but undiscoverable).

**Independent Test**: Fresh-project fixture: run init, verify the scaffolded plan
passes campaign preflight; break each named piece (env_refs, plan schema, defer-record
format) and verify each error names it.

**Acceptance Scenarios**:

1. **Given** a fresh project, **When** `specrew init` completes, **Then**
   `.specrew/verification-plan.json` exists with the governance validator and the default
   env_refs allowlist (PATH, PATHEXT,
   SYSTEMROOT, COMSPEC, TEMP, TMP, TMPDIR, HOME, USERPROFILE, APPDATA, LOCALAPPDATA,
   PROGRAMFILES, PROGRAMFILES(X86), PROGRAMDATA), while
   `.specrew/verification-plan.templates.md` contains copy-ready dotnet/npm build-test
   templates, and a full campaign round completes
   end to end (amended 2026-08-10 — preflight alone is not acceptance).
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

### User Story 8 - The two field walks: what review could not see (Priority: P1)

Added 2026-08-29 under TG-004's own exception (the findings block the acceptance bar) by
maintainer ruling, from two live walks against the released build: KeyContextAI (iterations
002 sealed, 003 parked; source of the eight-stop friction measurement) and HelloWinUIReactive
(a greenfield project taken through the six-lens workshop into the specify boundary, where it
is blocked). Thirty-three review rounds on this feature produced none of these findings.

As a beta tester on a fresh project, I reach the specify boundary without being asked to publish
a repository; the first artifact my workshop writes cannot be refused with the wrong cause; a lens
I confirm advances; a "yes" where a phrase is required tells me what was received and what is
still needed; the specification does not exist before the workshop that decides it. As a
maintainer, a stray or misdirected phrase cannot become a recorded authorization over work that
does not exist, the file I open to learn where the work stands agrees with the authority record
after every crossing, and the first sealed closeout validates clean.

**Why this priority**: these are the four findings that block the tag - forged authority, a
greenfield project blocked outright, a wrong-cause refusal that costs a source-reading expedition,
and an engine-side standing violation of the honest-state rule - plus the friction a first-time
user meets before they have any reason to trust the tool.

**Independent Test**: the two walks' blocking moments replayed as fixtures: the crossing ladder at
one commit with no iteration directory; `pr-flow` + `enforcement_mode: manual` + no origin at
specify; a JSON-shaped `product-domain.yml`; a confirmed lens followed by outside work; a
scaffolded feature's `spec.md` at the specify gate; a crossing followed by a read of `state.md`
and `plan.md`; a closeout sync followed by the validator.

**Acceptance Scenarios**:

1. **Given** a crossing whose stage owes artifacts that do not exist, **When** any capture or
   packet path runs, **Then** no crossing is minted and no verdict options or marker are rendered,
   and the message names what is owed.
2. **Given** a greenfield project recording `pr-flow` with `enforcement_mode: manual` and no
   origin, **When** the specify boundary syncs, **Then** it is not asked to publish.
3. **Given** a crossing recorded in the authority store, **When** a human opens `state.md` or
   `plan.md`, **Then** every enumerated mirror agrees with the store.

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

## Clarifications

### Session 2026-08-10 (clarify stage, after the specify verdict)

- **Q: What does the default round budget of 4 count against?** → **A (human ruling):
  per campaign.** The fuse counts reviewer-invoked rounds across the whole campaign
  for the artifact under review, regardless of tree-state movement; a literal
  per-tree-state budget would reset on every fix round and never bind against the
  F8-style runaway. FR-003, US1 scenario 4, and Key Entities updated accordingly.
- **Resolved by recorded default — stop-surface consult with no recorded gate
  decision**: when the signoff-gate decision store holds no decision for the current
  state, the stop surface evaluates as it does today; the consult rule (FR-007)
  applies only when a recorded decision exists.
- **Resolved by recorded default — hydration unavailable**: when a cloud placeholder
  cannot hydrate (for example, offline), the integrity check refuses in the consumer
  message shape, naming the file and the next step (bring it online / mark "Always
  keep on this device"); this refusal is distinct from the hash-mismatch corruption
  refusal (FR-011).
- **Resolved by recorded default — capture scan window**: the verdict scan runs from
  the boundary marker forward; the first verdict-bearing human turn wins and
  intervening non-verdict turns are skipped, never misclassified (FR-010).
- **Resolved by recorded default — abandon semantics**: choosing abandon closes the
  campaign as abandoned; sign-off remains un-passed; recorded findings persist; a
  later campaign starts fresh with a fresh budget (FR-002's third option).
- **Human ruling from the live capture-lag instance (2026-08-10)**: FR-010 amended —
  prompt-submit capture is the primary path (Stop-time is fallback only); the
  diagnosed stale-wiring gap (a deployed hook-settings file missing the registered
  UserPromptSubmit event is never reconciled or flagged) is in scope under FR-010;
  and the sync skills carry the defense rule that a boundary sync never runs in the
  same turn that received its verdict and never asks the human for a catch-up nudge.
  Diagnosis evidence: hosts/claude/host.psd1 Registrations list all four events;
  this worktree's .claude/settings.local.json carried only the older three-event
  set with no reconciliation on deploy and no drift flag from hooks status.

## Requirements *(mandatory)*

### Functional Requirements

Review-loop economics (bridge — beta4 replaces the pause plumbing; the decision-surface
contract is durable):

- **FR-001**: After every campaign round's ingest that leaves a DECISION TO MAKE, the
  engine MUST render the decision surface and terminate the round loop (pause as the
  orchestrator's terminal state); no reviewer invocation or spend may occur while the
  decision is pending. A round returning a complete, current, approvable `pass` leaves
  no decision: the engine renders no surface and states plainly that none is needed.
  **Why this carve-out exists, and why removing it is a regression:** the surface was
  once rendered after every round including clean ones, and it asked for an answer the
  machinery never consulted — the signoff gate already released the boundary on that
  result shape. Worse than useless, it MANUFACTURED FORGEABLE AUTHORITY: a live walk
  recorded a grant, a pause-decision and a human-disposition, all marked `human`, for a
  round the human never authorized and a decision they never made. Ceremony is not
  merely annoying; a question nobody needed still gets STORED as a human decision. The
  amendment records the behaviour ruled on 2026-08-19 (drift DRIFT-199-I001-077, "W27").
- **FR-002**: The decision surface MUST show findings grouped by severity with
  locations, minors as visibly non-gating, cumulative cost (rounds, minutes), budget
  position, a one-line severity-derived recommendation, and three TYPED DECISIONS
  (`run another round` / `stop the review here` / `abandon this review campaign`) whose
  consequences are stated in the option text, plus the explicit
  nothing-spends-until-you-answer line. The decisions carry NO numbered labels.
  **Why this form, and why numbering it back is a regression:** a number indexes nothing
  the authority layer can accept. Every authority in this system is a typed phrase
  captured from the human's own chat turn, and since the pause-decision gate landed, both
  `stop the review here` and `abandon this review campaign` REQUIRE such a capture — so a
  menu offering "reply 2" instructs the human to produce something that creates no
  authority at all, and then blames them when nothing happens. Numbered labels also teach
  bare-number replies, which this system can never treat as authority. The amendment
  records the behaviour ruled on 2026-08-23 (drift DRIFT-199-I001-110, "W49").
- **FR-003**: Continuation MUST always be an explicit human choice consuming a
  single-run grant; agents MUST NOT mint continuation authorizations from a prior
  grant; a default round budget of 4 per campaign MUST force refusal of further
  rounds once exhausted until the human explicitly resets the allowance (the budget
  counts reviewer-invoked rounds across the whole campaign regardless of tree-state
  movement — Clarifications, 2026-08-10).
  - **CARVE-OUT, one typed act may mint at most once PER CHANNEL** (maintainer ruling
    2026-08-27, amending this requirement rather than reconciling it): exhaustion is
    tracked per delivery channel, so on a host that delivers a human turn through both
    prompt-entry and the end-of-turn transcript, one typed act MAY produce two round
    authorizations. **At most two — bounded, and recorded as a `cross-channel-double-mint`
    observation every time it happens.**
  - **The reason, inline, because a requirement recording only its conclusion invites
    the next author to simplify it back into the defect.** Cross-channel identity was
    attempted twice and failed twice: these hosts expose no shared per-turn identifier —
    prompt-entry has an event clock, the transcript has an index — so any match on
    content is a heuristic, not an identity. The first attempt let a spent approval be
    re-minted without limit; the second wedged a genuinely later retype forever, with no
    recovery. The two findings that killed it contradicted each other, which is what a
    guess looks like when it is asked to be an identity twice.
  - **Why this is acceptable where the original hole was not**: the pre-fix behaviour was
    UNLIMITED re-minting from one act; this is bounded at one extra per channel. And it is
    a SPEND-ACCOUNTING cost, not a forgery — the human did approve a round, and the ledger
    records a real typed act behind every authorization. What may be wrong is the count,
    never the consent. Whether a host-provided turn identifier exists is a beta4 discovery
    task; if one does, this carve-out is withdrawn and the requirement returns to its
    unqualified form.
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
  **Amendment (human ruling, 2026-08-10, from the live capture-lag instance)**:
  verdict capture MUST execute at prompt submission as the primary path — the verdict
  is durable before the agent's next turn begins — with Stop-time capture as the
  fallback only. The prompt-submit wiring gap diagnosed live in this worktree is in
  scope: the claude host manifest registers UserPromptSubmit, but a previously
  deployed hook-settings file lacking a newly registered event is never reconciled
  and nothing flags the drift — the hooks deploy/status path MUST detect and repair a
  missing registered event so the primary capture path cannot silently degrade.
  Defense-in-depth instruction rule for the sync skills: a boundary sync never runs
  in the same turn that received its verdict, and never asks the human for a nudge to
  let the record catch up — if the record lags, end the turn and resume on the next
  natural exchange.

OneDrive / reparse policy (durable):

- **FR-011**: The review engine's integrity check MUST discriminate reparse tags:
  cloud-family placeholders are hydrated then hash-verified; junction/symlink tags
  remain refused; a reparse point that is **not a link and not a cloud placeholder** is
  **admitted as ordinary content and trusted on the hash of the bytes actually read**.
  The policy is symmetric across module install, authority store, and frozen snapshot.
  The refusal message follows the consumer message shape; the default CurrentUser
  install path MUST be able to run campaigns. Docs carry the AllUsers alternative and
  one advisory sentence on synced folders.
  **AMENDED 2026-08-11 by maintainer ruling** (was: *"unknown tags are refused
  (allowlist)"*). Refusing every unrecognised tag was measured to refuse the real,
  common case: OneDrive-backed installs present attribute combinations .NET does not
  expose as links, and the original wording made the default install path unusable —
  the very failure FR-011 exists to fix. Without P/Invoke the engine cannot read the
  true tag, so the allowlist could only ever be an allowlist over what .NET happens to
  surface, not over tags. **The boundary that carries the trust is narrower than an
  allowlist and enforced instead of asserted**: admitted content is only ever read,
  hashed, and containment-checked — never executed. The residual is recorded as *not
  known* rather than argued away, and reading the real tag routes to beta4.
  See DRIFT-199-I001-024, -031.

Campaign bootstrap (durable):

- **FR-012**: `specrew init` MUST scaffold a strict starter verification-plan.json
  (governance validator) with the default env_refs allowlist (N4 list including TMPDIR),
  plus a sibling verification-plan.templates.md carrying copy-ready dotnet/npm build-test
  command templates. Templates stay outside JSON because the plan contract rejects unknown
  and disabled fields rather than allowing documentation to masquerade as executable authority.
  Acceptance is a fresh project completing a FULL
  campaign round, not merely passing preflight (amended 2026-08-10; see SC-007).
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

The beta3 tag batch (iteration 002; added 2026-08-29 by maintainer ruling under TG-004's
exception; design and rulings in the crew report of 2026-08-29 and the iteration 001 retro):

- **FR-024**: A boundary crossing is not minted until the stage it leaves has its owed
  artifacts per the boundary evidence contract, checked on the live filesystem at mint time in
  every minting mechanism (the sync's successor auto-open, the authorization writer's rebind,
  and the post-capture packet re-mint); and no packet renders verdict options or the verdict
  marker for a crossing whose owed artifacts do not exist - it states what is owed and the one
  step that produces it. The gate-stop skill (every copy), Rule 53, `refocus/general.md` and
  `lifecycle-discipline.md` carry that one discipline; the conformance provider's existing
  counter-discipline is the wording of record. Recognized capture of a stray phrase against an
  empty stage is the mutation this requirement must turn red.
- **FR-025**: `pushed-head` is a delivery check scoped to iteration-closeout and
  feature-closeout, reading `release_model` and `repository_governance.enforcement_mode`:
  `manual` (or no governance block) with no origin is declared-future posture and returns
  not-applicable naming when delivery becomes owed; an active enforcement mode with no origin
  fails naming the contradiction; origin present keeps today's pushed-at-HEAD requirement. A
  separate named check, `verdict-commit-durable`, runs at every boundary: with an origin
  configured, `origin/<branch>` must be at HEAD (today's strength, unchanged); with no origin it
  is not-applicable with a message that states the record binds to a local commit that only local
  history protects. Every message meets the refusal standard (what failed, the instance, one
  reachable action).
- **FR-026**: The constrained YAML readers for `product-domain.yml` and
  `implementation-rules.yml` report a non-empty document that matches none of their constructs
  as unparseable, and the validators' parse-failure message names the representation found
  (JSON detected by its first character), states that the recorded answers are intact and that
  no re-confirmation is owed, and names the re-write action. The field backstops never fire on
  an unparsed record.
- **FR-027**: A governed lens-checkpoint writer closes a lens: it consumes the typed-turn
  receipt for that lens, requires the lens record, runs the lens's already-existing validator
  where one exists (product-domain, code-implementation), writes `moved_on` and the confirmation
  fields, and refreshes the handover. The transition table gains the `confirm-lens` operation
  with every cell pinned; the workshop skill's checkpoint step invokes the writer instead of a
  hand edit; no new validators are built and the boundary validators remain.
- **FR-028**: When a lens reply is received without closing the lens, the next message opens
  with one line that acknowledges what was recorded and names what is still needed; the
  workshop-repair authorization gate's refusal routes through the workshop refusal contract,
  naming the received reply and the exact phrase. No recognizer changes.
- **FR-029**: Feature creation replaces the scaffolded `spec.md` with a stub that carries a
  not-yet-authored sentinel and no requirement placeholders; the specify boundary gate refuses
  while the sentinel stands, with a message that says the workshop answers are safe and names
  the specify step; the upstream scaffold is untouched.
- **FR-030**: The crossing writer writes every enumerated COPY of `last_authorized_boundary` -
  `state.md` Current Phase (the boundary name) and `plan.md` Status (the validator's own enum,
  mapped) - for the active iteration at the moment the crossing is recorded, in each file's
  existing vocabulary with no migration; the boundary sync re-mirrors the copies from the store at
  its start; the iteration-state truth gate compares every enumerated copy at every
  iteration-scoped boundary. `state.md` Iteration Status is NOT a copy: it is derived from task
  progress by its own writer in its own enum (`not-started | executing | blocked |
  ready-for-review`, plus `complete`, which the crossing writer sets only at iteration-closeout),
  and the truth gate holds it to a consistency relation with the store instead of equality
  (`complete` iff the last authorized boundary is iteration-closeout; `ready-for-review` only with
  every task done). A copy may lead the store by exactly the pending crossing during the
  arrival-to-verdict window and never otherwise; a copy ahead of the store is refused, not
  rewritten. (Corrected 2026-08-29 at the plan verdict: the first enumeration named Iteration
  Status as a mirror; it is not one.)
- **FR-031**: The closeout sync writes the iteration seal after every record it produces,
  including the re-rendered `dashboard.md`, so the first validation of a sealed iteration
  passes; a test asserts the seal hashes the rendered dashboard.
- **FR-032**: A pending crossing is owed by the actor that recorded its arrival. The Stop-hook
  boundary demand ("render the packet, emit the marker") fires only in the session that recorded
  the pending crossing; every other session in the governed project sees one informational line
  naming that a crossing is pending, which session owes it, and that this session does not - and
  is then free to hold an ordinary conversation. The crossing record carries its owning session;
  the demand names its owner; TB-1's mint gate, item eight's mirror ownership and this share one
  rule: the actor that produced an arrival owes its packet, its mirrors and its evidence.
  (Observed 2026-08-29: the demand for `iteration-closeout -> plan` rendered into the reviewer
  session, which had produced none of it, on every Stop.)
- **FR-033**: Method, binding on every fix in the batch: a mutation that turns its own case
  red by asserting observable state, never call existence; every refusal touched meets the
  refusal standard; every mirrored copy lands byte-identical in the same commit; review and
  rework effort are tracked separately from implementation; one covering round runs on the
  shipping tree over the whole delta since tree `1b50ae60` (W76, W77 and this batch) before the
  tag decision.
  - **The limit of mutation proving, stated as a rule rather than an observation** (maintainer
    ruling, 2026-08-29, after the covering round): *mutation proving shows a control is wired to
    its own test; it never shows the control is wired to the system.* All three findings the
    round returned were invisible to it **by construction** - a name mismatch across a seam
    (writer wrote `turn_receipt`, reader read `human_turn_receipt`), an effect nothing asserted
    (a flag set and never consumed), and a test pinning current behaviour (a bare marker
    certified as correct on a justification that had expired). Every one of those suites was
    mutation-proved and green.
  - **The consequence, binding from here**: a fix that crosses a SEAM owes one case that
    exercises **writer and reader together**, and a fix whose control is a FLAG owes one case
    that asserts the flag's **effect**, not its value. Neither is satisfied by a mutation of the
    control alone. Where the seam's far side has a switch that disables its own check - as the
    canonical workshop reader does, skipping receipt validation unless `human_turn_contract` is
    declared - the fixture must turn that switch ON, or the case proves nothing while passing.
  - **Where the general instrument goes**: a contract test exercising writer and reader together
    in one case belongs in beta4's composition harness, alongside the two-gates-disagree
    scenarios - the same family seen from the test side (maintainer instruction, 2026-08-29).
  - **The line between repairing machinery and impersonating a human** (maintainer ruling, 2026-08-29,
    on approving the restore of a dropped pause fact): **machinery may restore a fact that RE-ENABLES a
    human decision; it may never write a fact that CONSTITUTES one.** A pause is the prompt for the
    human's choice, not the choice. Restoring it gives back a decision the machinery dropped; writing
    the choice would be taking one. This is what separates an authority-store repair from the
    fabrication risk that iteration 001's `security-surface` concern exists to prevent, and it is
    written down so the next agent facing a wedged store knows which side of the line it is on.
    Conditions that make such a restore safe, all four required: derive every field from the subject's
    own published record and STOP rather than default anything that will not derive; make the restored
    fact distinguishable from an organically written one by carrying its provenance; journal the repair,
    because the defect being repaired is a write that failed and left nothing; and snapshot the store
    first, so the write is reversible.
  - **A safety feature can guarantee the silence it was meant to prevent** (maintainer,
    2026-08-29, generalising the FR-032 defect): `$blockReasonOwnerScoped` was assigned in one
    branch and declared nowhere, under `Set-StrictMode -Version Latest`. Strict mode protects
    against READING a variable nobody declared and gives nothing against WRITING one nobody
    reads. The louder failure was therefore unavailable, and the defect took the only shape it
    could - silent, and inert. The rule that follows is general and not about PowerShell: **when
    a language or framework guard makes one direction of a mistake loud, the same mistake will
    migrate to the direction it does not cover.** Ask what the guard does NOT catch, because
    that is where the surviving instances live; a codebase under a strict reader-check will
    accumulate write-only state specifically, and nothing in its test output will say so.
  - **BETA4 ITEM — the authority store owes a provenance slot to any repaired fact, not to this one**
    (maintainer, 2026-08-30). `PendingPauseFact` and its siblings have closed field contracts with no
    way to say "this fact was reconstructed, from what, when and why", so a legitimately repaired fact
    is indistinguishable from an organically written one. The right fix is an optional provenance slot
    on repairable fact kinds. It was NOT taken here, and the reason is the item's own framing: *"a
    schema change to the trust anchor made under an operational blockage is the wrong way to land a
    right idea."* The blockage passes; the schema stays.
  - **EVERY GUARD HERE PROTECTS LESS THAN ITS NAME CLAIMS, AND THE GAP IS ALWAYS THE HALF NOBODY
    TESTED** (maintainer, 2026-08-30, on the third instance in one day). Stated as a beta4 principle in
    exactly those terms.

    **THE SENTENCE THAT SUBSUMES THE REST, and the maintainer's instruction is that it heads the
    principle rather than sitting under it:**

    > **The fixture wrote the precondition the product denies.**

    Every instance below is a special case of it. A mutation proves the control against the state its
    fixture built. Mirror parity compares two copies the test put there. A fail-soft is exercised on the
    failure the test could stage. Hook health is asked about the receipts the fixture wrote. In each, the
    guard is measured against a world the test authored, and the half nobody tested is the half the test
    could not imagine - which is why the gap is never random and never found by more of the same testing.
    **It is found by running the thing against a state it did not choose**: a real project, a real host, a
    real package. Four of the five instances below were found that way; none was found by a suite.

    The measured instances:
    1. **Mutation proving** covers control-to-TEST wiring, not control-to-SYSTEM. It proved eleven suites
       and caught none of round 1's three findings.
    2. **Mirror parity** covers DIVERGENCE between mirrors, not OMISSION from the package. Both copies of
       `confirm-workshop-lens.ps1` were byte-identical and neither shipped.
    3. **The pause fail-soft** covered ARGUMENT BINDING, not WRITE FAILURE. It named the root cause on its
       first run and is still blind to the failure mode it was written for.
    4. **Hook health** covers AGGREGATE liveness and per-event REGISTRATION, not per-event ARRIVAL.
       Registered is not fired, and nothing compared the declared event set against the arrived one -
       though both were already on disk.
    5. **A green suite** covers the states its FIXTURES can build, not the states the product can reach.
       `workshop-lens-checkpoint` was green through a deadlock that stopped every greenfield workshop at
       its first lens, because its fixture wrote `product-domain` into `selected` - a state the real flow
       structurally denies (DRIFT-199-I002-027).
    The shape is constant: each guard's NAME describes the whole hazard, its IMPLEMENTATION covers one
    half, and nothing states which half. So the beta4 work is not "add more guards" - it is **make every
    guard declare its scope, and test the half it does not cover.** A guard whose name overstates it is
    worse than no guard, because it retires the question.
  - **THE REFUSAL STANDARD'S CLAUSE, SHARPENED BY FIVE MEASUREMENTS** (maintainer, 2026-08-30). FR-033
    requires a refusal to name what is wrong, say the human's work is safe, and give one concrete action.
    Five refusals in this batch satisfied that clause completely and still sent the reader wrong, because
    **each accurately described WHAT IT CHECKED and misdescribed WHAT WENT WRONG**: the update advice that
    would have reverted the tree (-021); the pause recovery that redirected in a loop (-018); the
    host advice unreachable from the host it was given on (-026); a fact failing two contracts reporting
    one (-020); and a binding rejected for its NAME being told about its VALUE, with a valid value printed
    and casing advice attached (-029).

    > The clause cannot just be **"name one reachable action"**. It has to be **"name the thing that
    > actually failed."**

    The two are independent and both are required: an action reachable from the reader's state, about the
    thing that actually failed. Four of the five had a perfectly reachable action attached to the wrong
    subject, which is worse than vagueness - it is a confident instruction to look somewhere else.
  - **THE DEEPEST PATTERN OF THE FORTNIGHT, recorded for beta4 (maintainer, 2026-08-29): every silent
    failure in this batch converted a recoverable problem into an unfalsifiable one.** Four instances,
    and the fourth found its own root cause the moment the rule was applied to it:
    1. The instruction layer inventing a gate no code refused.
    2. The capture ignoring a near-miss phrase.
    3. Strict mode guaranteeing that set-never-read could only ever be silent.
    4. A bare `catch` discarding the exception that would have named DRIFT-199-I002-018 - and which,
       once the trace was added, named it on the very first run.
    **The rule: a fail-soft that discards its cause guarantees that whatever reads its absence will
    misdiagnose it** - as that refusal did, sending the maintainer to check a folder permission that was
    fine. **Every fail-soft owes a trace.** The tolerance is usually right; the silence never is.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: US1 -> FR-001..FR-006; US2 -> FR-007..FR-009; US3 -> FR-010; US4 ->
  FR-011; US5 -> FR-012..FR-013; US1/US5 -> FR-014; US6 -> FR-015..FR-017, FR-019,
  FR-020; US7 -> FR-018; release leg -> FR-021..FR-022; all -> FR-023.
- **TG-002**: Owner roles: implementer (engine/scripts/tests), spec-steward
  (records/claim alignment), reviewer (codex campaign + certification), maintainer
  (all boundary verdicts, release rulings, manual OneDrive measurement).
- **TG-003**: Iteration 001 (FR-001..FR-023; closed 2026-08-29 on the signed-off tree) and
  iteration 002 (FR-024..FR-033, the beta3 tag batch); the release leg (FR-021) executes at
  feature-closeout per the resolved beta-stable model, after iteration 002's covering round.
- **TG-004**: Scope is CLOSED: anything discovered during this feature goes to the
  ledger's beta4 list unless it blocks the acceptance bar itself; the reconciliation
  path for any spec/implementation conflict is a drift-log entry citing the governing
  FR plus a maintainer ruling.
  Exercised once, 2026-08-29: the two field walks' findings entered as FR-024..FR-033 by
  maintainer ruling because they block the acceptance bar; the six items ruled out (F-2, TB-5,
  B-5, B-1/B-1a, B-2, B-3) and the UX programme (B-4) go to beta4 as decisions, not omissions.

### Key Entities

- **Decision surface**: the per-round pause rendering — findings by severity,
  non-gating minors, cost, budget position, recommendation, numbered options.
- **Round allowance / budget**: per-campaign spend state; default 4; consumed only by
  reviewer-invoked rounds regardless of tree-state movement; reset only by explicit
  human action.
- **Signoff-gate decision store**: the recorded allow/block decisions the stop surface
  must consult (`.specrew/review/signoff-gate/latest.json` + history).
- **Pending pause decision**: sanctioned quiet state — round complete on current tree,
  surface rendered, human unanswered.
- **Verification plan**: `.specrew/verification-plan.json` — executable commands and the
  env_refs allowlist scaffolded by init; `.specrew/verification-plan.templates.md` is the
  non-executable guide for optional ecosystem commands.
- **Reviewer-host catalog row**: per-host defaults including the review window.
- **Gloss helper**: renders id + title for every ID in consumer prose.

## Success Criteria *(mandatory)*

### Measurable Outcomes

Each criterion is proven by a RED-first fixture through the shipped entry point
(FR-023); the ten were confirmed at the requirements-nfr lens:

- **SC-001**: After every campaign round that leaves a decision to make, the decision
  surface renders and nothing spends until the human's TYPED DECISION — one of the three
  phrases named in FR-002, sent as an ordinary chat message. A clean round (complete,
  current, approvable `pass`) renders no surface and says so; a reply inside a question
  UI or picker is not captured and therefore authorizes nothing.
  **Why measured this way:** rendering a surface after a clean round stored a human
  decision nobody made (FR-001's carve-out), and a numbered reply cannot become authority
  in a system whose every authority is a captured phrase (FR-002's form). Measuring the
  old shape would pass a build that had reintroduced both defects.
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
- **SC-007**: Fresh project + `specrew init` completes a FULL campaign round — not
  merely preflight. (Amended 2026-08-10 by maintainer ruling: getting a single round to
  run during this feature required clearing seven distinct defects, which means the
  first-run path has never been exercised end to end. Preflight-only acceptance would
  have passed while the path stayed broken.)
- **SC-008**: Infrastructure failures leave the allowance intact.
- **SC-009**: Zero machinery nouns and zero unglossed IDs in rendered consumer
  surfaces.
- **SC-010**: The banner renders the full prerelease version (0.40.0-beta3).
- **SC-011**: The KeyContextAI crossing ladder, replayed as a fixture, mints nothing past the
  first stage that owes an artifact, and the packet for an empty stage carries no verdict options
  and no marker.
- **SC-012**: The HelloWinUIReactive posture (`pr-flow`, `enforcement_mode: manual`, no origin)
  clears the specify boundary's preflight; this repository still requires a pushed HEAD at every
  boundary.
- **SC-013**: A JSON-shaped `product-domain.yml` is refused in one line that names JSON and no
  backstop line; at the lens checkpoint, not at the boundary.
- **SC-014**: After a confirmed lens, outside work produces no re-ask naming that lens; a "yes"
  at an open lens is answered with the one-line acknowledgment.
- **SC-015**: A freshly created feature's `spec.md` carries no requirement placeholders and
  cannot cross specify.
- **SC-016**: After every crossing on a fixture, `state.md` Current Phase, `state.md` Iteration
  Status and `plan.md` Status agree with the store; a mirror ahead of the store is refused.
- **SC-017**: A closeout sync followed immediately by the validator reports no closed-iteration
  edit.
- **SC-018**: One covering round is delivered against the shipping tree, covering the delta
  since `1b50ae60`, before the tag decision; the plan's review and rework actuals are recorded
  separately from implementation.
- **SC-019**: With a crossing pending, a second session in the governed project can end a
  turn on an unrelated topic without being told to render a packet or emit a marker; the
  owning session still is.
- **SC-020** (FR-010, existing): a verdict-shaped turn that the capture does not record
  produces a visible line naming what was received and what would capture; a leading quote
  bar before the phrase is the pinned fixture (it cost the maintainer two retries on
  2026-08-29).

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
