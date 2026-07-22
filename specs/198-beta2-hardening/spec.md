# Feature Specification: 0.40.0-beta2 Hardening Bundle

**Feature Branch**: `198-beta2-hardening`
**Created**: 2026-07-09
**Status**: Draft
**Input**: User description: "0.40.0-beta2 hardening bundle: reviewer containment + identity hardening (proposal 203 W1-W16), consumer CI methodology gateway + distribution workflow hygiene (proposal 204 W1-W7, closes #2909 and #2903), self-leak firewall (proposal 205 W1-W6), boundary-approval bypass fix on non-stopping hosts (issue #2906), and toolchain bumps Spec-Kit 0.8.4 to 0.12.9 + Squad 0.9.1 to 0.11.0. Release v0.40.0-beta2 at feature close; stable 0.40.0 held on this bundle per DEC-197-REL-001."

## Product-Domain Summary

Standard-depth pass, human-confirmed 2026-07-09 (full record:
`workshop/product-domain.md` / `workshop/product-domain.yml`).

- **Who**: downstream consumer developers/agents (inherit broken CI,
  self-leaked methodology, silent boundary bypass, wrong per-host review
  budgets); the maintainer/release owner (stable 0.40.0 held per
  DEC-197-REL-001); reviewer agents across all five supported CLI harnesses; the governance trust
  story itself.
- **Pain** (field-evidenced): (1) reviewer containment/identity gaps (203);
  (2) broken-by-construction consumer distribution + self-leak (204/205);
  (3) p0 silent boundary-approval bypass on non-stopping hosts (#2906);
  (4) beta-1 E2E frictions — ceiling chicken-and-egg, flat-300s budget
  kills, tracker-edit-staled review evidence (203 W11–W16).
- **Gate** (maintainer-confirmed): all four streams landed with conditionals
  honestly resolved (203-W4 evaluate-first, 203-W7 decision item) — not
  "every W item implemented". Stable promotion needs a fresh consumer E2E on
  published beta2 bits plus the maintainer's manual PASS.
- **Non-goals**: model/quota fallback (Proposal 102); board-sync feature
  (Proposal 101); non-GitHub forges; 204-W6 (design note only); cross-host
  sandbox APIs; automatic bounded budget escalation.

## Workshop Decision Anchors

The design workshop (9 lenses + product-domain, all human-confirmed,
records under `workshop/`) bound these decisions; the requirements below
inherit them:

- **A1**: inherit Specrew's decomposition — every new volatile thing is
  data (deny-list file, catalog column, machinery list, release model),
  never host-conditional code.
- **A2 (#2906)**: deterministic ratchet in sync + shared authorization
  primitive across the covering set; host hooks are surfacing-only.
- **A3/W13**: fail-closed conditional tracker bypass, gate-level
  (mechanism b — the digest formula is unchanged).
- **A4**: four iterations — 001 substrate+firewall-first, 002 governance
  correctness core, 003 reviewer containment + round economy,
  004 distribution + release.
- **S1**: containment floor = W1–W3 + W4 as cheap detector (loud,
  never a mid-flight kill).
- **S2**: ONE path-granular machinery list; `.github/workflows/**` is
  content, host dirs + `.github` machinery subpaths are machinery.
- **S3**: teaching texts name the exact sanctioned door; T096 enforcement
  at input provenance; budget floor **600** (maintainer amendment).
- **S4/W15**: env cascade + `independence_source` provenance.
- **I1**: Spec-Kit opt-in extensions added only on probe-demonstrated
  dependency (scratch-dir probes only).
- **I2**: single tested pins — Spec-Kit 0.12.9, Squad 0.11.0.
- **I3**: asymmetric contract evolution (catalog additive-tolerant;
  deny-list versioned fail-open WARN consumer-side; honesty check
  fail-closed).
- **D1–D3**: full validator on consumer PRs; gateway keyed off recorded
  provider; action pins by major; hash-guarded healing; bootstrap commit
  auto-greenfield/offer-brownfield; pre-tag deterministic bookkeeping check.
- **NFR order**: honesty > agent-action transparency (human addition) >
  loud failure > host neutrality > teach-don't-trap > evidence-over-presence;
  paired-test rule binds every honesty invariant.
- **Iteration 005 reassessment (human-confirmed 2026-07-16)**: replace the failed
  process-owned mutable lease design with a `ReviewCampaign` above one-invocation
  `ReviewRun` state machines; dependency-free immutable JSON facts; repository-only
  authority mutation; run-owned claim generations; a synchronous process/file
  contract implemented by all five supported harness adapters; OS process-tree
  control on Windows, macOS, and Linux; explicit timeout results and recoverable
  partial findings; exact snapshot currentness; and P1 performance/cost optimization
  below P0 stability and integrity. Detailed records live under the Iteration 005
  workshop directory.

## Clarifications

### Session 2026-07-09 (clarify)

- Q: Which per-host `default_timeout_seconds` values ship in the catalog? →
  A (human): **antigravity 900** (measured 600–870s, headroom under its
  lifted 15-minute host-side kill so our watchdog owns the reap),
  **claude 600** (measured ceiling); **codex and copilot get measured on the
  consumer test project during iteration 002** and their rows are added from
  that evidence — absent rows fall to the 600 floor until measured. FR-022
  amended accordingly.
- Q: FR-014 (203-W7 standing-practice mechanism)? → A (human, approved with
  defaults at the specify gate): kept as written — refocus-instructed duty
  via the recorded-run wrapper is the host-neutral floor; hook-automated
  recording is an enhancement where a host supports it, never the dependency.
- Q: SC-014 stable-promotion E2E — scripted harness or manual? → A (human,
  approved default): stays a manual maintainer dogfood on the published
  beta2 bits; no scripted consumer-E2E harness in this feature.
- Q: Pre-existing validator WARNs (missing dashboard.md on closed iterations
  of F-048/141/174/182/197)? → A (human, approved default): left untouched —
  they predate this feature and do not gate it.
- Q: FR-036 consumer heal semantics when a shipped leak is found downstream?
  → A (self-answered from repo doctrine, FR-028 parity): flag-only for
  user-authored files; auto-rewrite only Specrew-owned deployed files whose
  content hash matches a shipped version.
- Q (2026-07-10, mid-iteration-001, maintainer-typed): what is the round
  ceiling FOR, and does a fix-responsive round reset it? → A (human): the
  ceiling is an **AI-usage spend allowance** — its purpose is to stop
  review spend and let the human approve more; therefore EVERY round
  counts, including fix-responsive ones ("it is ok to stop on a new
  finding even if we solved the previous one"). This supersedes the
  workshop's no-increment design for FR-019. The REAL fix is the halt
  message UX: consumer-legible ("review loop allowance exhausted…"),
  explaining that the guard protects AI-usage spending and why the human
  should approve a reset, naming the exact human-typed command — and
  carrying NO Specrew-internal identifiers (no trust-boundary rule names,
  feature numbers, or proposal references a downstream human cannot
  understand). FR-018/FR-019/SC-007 amended accordingly.
- Q (2026-07-11, maintainer-relayed from the parallel Devin-host crew):
  why do "fresh-context" reviews deliver stale blocks? → A (field
  diagnosis, three mechanisms confirmed against both sessions' run
  records): (1) launch-per-stop + verdict-surfaces-one-stop-later means a
  block can describe a tree that no longer exists (their run 4a052917;
  our fa5ff2f3/73700590); (2) threaded re-checks re-affirm against the
  thread's ORIGINAL material (their f22aa729 launched two fix-generations
  behind yet reported the original tree; deleting round-state broke the
  chain and their genuinely fresh b7a04055 returned zero findings);
  (3) nothing stamps or checks freshness on the NAVIGATOR surfacing path
  — the digest match exists only at the signoff gate. Fixes folded into
  FR-017 (amended) and T019: stamp the reviewed tree id into every run
  record surface, navigator digest-match before blocking (stale verdicts
  surface as stale-vs-current advisory), and in-flight dedup per lineage.
  T019 grows ~+0.5 SP; iteration 003's design-analysis details it.
- Q (2026-07-11, second maintainer-relayed Devin-crew field report, run
  `20260711T150802669-da2bc5cc`): what does a MIXED review run mean for
  staleness handling, and does an unmaterialized input consume spend? →
  A (recorded as T019/T020 acceptance input; explicitly NOT a scope
  expansion): their run carried SEVEN stale replays of already-fixed
  findings ALONGSIDE three genuinely new findings (~eleven one-stop-behind
  replays across their session), and a prior round spent budget after the
  engine failed to materialize its own changes.diff input. T019's
  acceptance therefore additionally covers: rejecting/superseding obsolete
  in-flight results; binding findings to the exact reviewed tree AND
  baseline; and distinguishing stale replays from still-valid findings
  WITHIN one mixed run (per-finding tree-binding, not only whole-run
  advisory). T020 must SEPARATE two budgets the report proved were
  conflated (provider spend = actual model/API cost; review-round
  allowance = the autonomous-round ceiling), across three cases (corrected
  at the maintainer's before-implement send-back, 2026-07-11): (a) a
  PREFLIGHT check that detects a missing input (e.g. absent changes.diff)
  BEFORE model invocation records an infrastructure failure consuming
  NEITHER provider budget NOR round allowance; (b) a model that WAS
  invoked records its actual provider spend even when no valid review
  resulted; (c) such a post-invocation failure DOES consume a
  round-allowance slot with a distinct failed-invocation disposition and
  never disappears from accounting. The "every round counts" ruling still
  governs rounds that actually reviewed; the preflight case consumes
  nothing because it PREVENTS the wasteful invocation the da2bc5cc round
  suffered. Their crew's forensics (tree-id/baseline/launch-commit deltas,
  in-flight overlap evidence) arrive as fixture data; their
  diff-materialization and strict-resolution commits (cca79708) get the
  T034 inspect/reuse doctrine with the strict fail-before-execution
  behavior preserved, never softened to a warn — never independently
  reimplemented.
- Q (2026-07-10, follow-up, maintainer-typed): who runs the remediation
  machinery? → A (human): "This is a very bad UX, why do you ask the user
  to run a script. Ask the user for approval to allow to reset the
  iteration." The human-typed trust boundary binds the DECISION, not the
  keystrokes: the agent asks a plain approve/deny question in the
  conversation; the human's recorded approval (the same conversational
  verdict capture boundary approvals use) is the authorization; the AGENT
  then executes the remediation command citing that approval as evidence.
  The human is never asked to copy-paste shell commands. Applies to every
  remediation/ack/budget-increase teaching in this feature (FR-018,
  FR-022 amended).
- Q (2026-07-11, field incident DEC-198-GOV-001): the pending-artifact
  fallback verdict capture recorded "approved for retro" that the human
  never gave — it read the Stop hook's own blocking feedback (machinery
  text injected as a user-role transcript turn, containing
  approval-shaped wording) as a human approval and synthesized the
  verdict phrase, 32 seconds after the prior capture and while the
  human's actual reply was a send-back. → A (human, retro
  approve-with-instructions): folded into iteration 003 as explicit
  requirements FR-041..FR-044 with tasks T030..T033 — machinery-turn
  exclusion, tokenizer tightening, exact-sequence regression fixtures,
  and a designed correction door that APPENDS invalidation records
  (original entry identity, correcting authority, reason, timestamp,
  resulting boundary state) instead of deleting history. All remaining
  ledger entries are audited against the transcript BEFORE iteration 002
  closeout (compact per-entry record; no automatic alterations; any
  further invalid entry requires its own explicit correction decision).
  Containment and T020 keep priority; the capture fix is sized at
  iteration 003's design-analysis, never displacing them silently.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One approval advances one boundary, on every host (Priority: P1)

A team runs the Specrew lifecycle on a host whose agent never stops
mid-run. The agent finishes retro and tries to advance through
iteration-closeout without a human verdict. The governance machinery
refuses the second unapproved advance, names the skipped boundary, and
offers exactly two doors: retroactive human approval, or reversion to the
last approved boundary commit.

**Why this priority**: severest correctness item in the bundle (p0,
issue #2906) — the core promise "one approval advances at most one
boundary" is currently unenforced on non-stopping hosts
(`Test-SpecrewBoundaryAuthorization` is dead code).

**Independent Test**: deterministic fixture with no host hooks: record one
authorized crossing, attempt a second unauthorized one; assert refusal,
message content, and both reconciliation paths (retro-approve advances the
cursor; non-approval reverts to the recorded AuthCommitHash only after
explicit confirmation).

**Acceptance Scenarios**:

1. **Given** a lifecycle position one boundary ahead of
   `last_authorized_boundary`, **When** the agent invokes boundary sync for
   the NEXT boundary, **Then** the sync refuses loudly, names the skipped
   boundary, and teaches both reconciliation doors — and no cursor or state
   advances.
2. **Given** an unreconciled skipped boundary, **When** the human
   retroactively approves it, **Then** the cursor advances and the
   verdict history records the retroactive approval distinctly.
3. **Given** an unreconciled skipped boundary, **When** the human declines,
   **Then** reversion targets the last approved boundary's AuthCommitHash
   and executes only after an explicit destructive-action confirmation.
4. **Given** any governed touchpoint (validator, resume/start, hard gates),
   **When** it runs with a skipped boundary outstanding, **Then** it
   surfaces the same finding via the same shared primitive.

---

### User Story 2 - The reviewer can only touch what it certifies (Priority: P1)

A co-review reviewer runs on a permissions-skipped host. Its worktree
lives outside the origin repo, its bundle carries no origin addresses, its
prompt names what was stripped and why, and if it still reaches the origin
by a remembered path, the run is marked `containment-violated` and fails
loudly. What the digest certifies and what the reviewer can see are the
same tree, governed by one machinery list.

**Why this priority**: the observed 2026-07-08 escape (origin Pester runs,
an interactive hang that burned the budget, a live review fired against
the origin) plus the certified-but-unreviewable machinery divergence are
the trust story the release ships with.

**Independent Test**: materialize a reviewer worktree from a fixture
digest; assert no git-upward resolution to origin, zero origin-absolute
paths in the bundle, digest-strip set == worktree-strip set, and detector
classification on seeded origin access vs a full legitimate in-worktree
run.

**Acceptance Scenarios**:

1. **Given** a materialized reviewer worktree, **When** any git command
   walks upward from inside it, **Then** it cannot resolve to the origin
   repository.
2. **Given** the reviewer-visible bundle, **When** scanned, **Then** it
   contains no origin-absolute paths.
3. **Given** a reviewer child process whose cwd or command line references
   the origin root, **When** the detector samples it, **Then** the run is
   marked `containment-violated`, fails loudly with an origin-side record
   (process, command line, path, timestamp), and is never killed
   mid-flight.
4. **Given** a legitimate full suite run inside the worktree, **When** the
   detector samples it, **Then** no violation is recorded (false-kill
   guard).
5. **Given** the ONE machinery list, **When** the digest strip and the
   worktree strip both consume it, **Then** their effective path sets are
   identical, `.github/workflows/**` is included on both sides, and every
   exclusion has a reviewer-can-still-see-it regression test.
6. **Given** a reviewer reviewing a tree with machinery stripped, **When**
   it encounters a reference into a stripped path, **Then** the prompt's
   stripped-paths teaching prevents an absence finding.

---

### User Story 3 - Review rounds spend human budget honestly (Priority: P2)

An implementer records test evidence a reviewer can trust because the
runner observed the run. Checkpoint reviews read incremental diffs, review
exactly the frozen checkpoint they were fired for, don't burn ceiling
rounds on honest progress, resolve per-host budgets from the catalog, and
every halt or kill teaches the sanctioned next step.

**Why this priority**: the beta-1 E2E burned full review cycles on
tribal-knowledge hunts, flat budgets, and whole-diff re-reads — the
correctness gates fired right, but the cost was wrong.

**Independent Test**: fixture sequences for each economy fix — forged
evidence rejected, baseline threading, frozen-digest materialization,
fix-responsive ceiling, budget resolution order incl. the 600 floor and
the W14 warning, halt/kill message content.

**Acceptance Scenarios**:

1. **Given** a suite run through the recorded-run wrapper, **When**
   evidence is written, **Then** it reflects what the runner observed, and
   caller-supplied numbers are rejected or labeled implementer-recorded
   (203-W8).
2. **Given** an auto-fired checkpoint review with a prior reviewed
   checkpoint, **When** the next fire occurs, **Then** its baseline is the
   last-reviewed checkpoint identity, falling back to merge-base when none
   exists; the signoff `--live` merge-base doctrine is unchanged (203-W9).
3. **Given** edits landing between fire and detached execution, **When**
   the child runs, **Then** it materializes the frozen fire-time tree and
   labels the run `snapshot-moved` when the tree has moved; it preserves
   findings and their severities with per-finding relevance hints while
   refusing to treat the result as approval of the current snapshot (203-W10).
4. **Given** round 1 found f1 and round 2 confirms f1 fixed while finding
   f2, **When** the ceiling is evaluated, **Then** the counter does not
   increment; only true no-movement rounds climb (203-W12).
5. **Given** a ceiling halt or a budget kill, **When** the message and
   durable record render, **Then** they name the exact remediation command
   and config key, state that a bare `--live` rerun will not re-review
   past the ceiling, and never suggest runtime-state surgery; the increase
   itself stays human-typed (203-W11/W16, T096).
6. **Given** budget resolution, **When** no explicit flag or project
   config exists, **Then** the catalog per-host default applies, an
   unknown host resolves the 600 floor, and an explicit value below the
   resolved default draws the warning at resolution time (203-W14/W16).
7. **Given** a manual `--live` run without `--code-writer-host`, **When**
   the session env names the implementer, **Then** independence is
   resolved via the cascade with `independence_source` recorded, and
   `unverified` stays fail-closed (203-W15, SEC-004).

---

### User Story 4 - A consumer project gets working, honest CI from minute one (Priority: P2)

A developer runs `specrew init` on a fresh GitHub project. The deployed CI
references only paths that exist downstream, triggers on generic feature
branches, states its advisory posture, and the scaffold is committed as a
clean baseline. An existing consumer heals on `specrew update`: retired
broken templates are removed (never user-modified files), and the refocus
scope rows sync. At feature-closeout, the packet teaches the project's OWN
release model — never Specrew's.

**Why this priority**: every consumer since F-031 received CI that can
only fail (issue #2909); the first consumer review flagged only OUR
scaffold; the beta-1 closeout taught PSGallery steps to a repo with no
remote (204-W7).

**Independent Test**: scratch-dir init/update fixtures per provider shape
(greenfield GitHub, brownfield, no-remote, non-GitHub) asserting deployed
set, commit behavior, healing behavior, and closeout rendering.

**Acceptance Scenarios**:

1. **Given** a fresh init on a recorded-GitHub project, **When** deployment
   completes, **Then** exactly the methodology gate + path-fixed work-kind
   templates deploy (self-host lanes never), pinned by action major, and
   the run ends with (greenfield) an announced bootstrap commit or
   (brownfield) an explicit offer (204-W1/W2/W3/W5b).
2. **Given** an explicitly non-GitHub provider, **When** init runs,
   **Then** no GitHub Actions files deploy and the output names the manual
   validator path (FR-024 honesty).
3. **Given** a consumer with beta-1 templates, **When** `specrew update`
   runs, **Then** byte-identical retired templates are removed, modified
   ones are left with a WARN naming them retired, and
   `refocus-scopes.json` rows sync into the existing `.specify`
   (204-W5, #2903).
4. **Given** feature-closeout in a repo with no git remote, **When** the
   packet renders, **Then** it shows local-only steps, names why release
   steps are N/A, and never mentions Specrew's own registry or
   beta-before-stable; a publish-target project renders the full chain
   (204-W7).
5. **Given** init deploys machine-local host config, **When** the
   `.gitignore` is inspected, **Then** the deployed local config is
   ignored (204-W4).

---

### User Story 5 - Specrew-self facts cannot ship to consumers (Priority: P2)

An author edits a deployed template with a Specrew-self fact in it. The
repo CI lane goes red naming the term and the annotation escape. The
prompt fixture proves built prompts stay clean for a project named
anything-but-Specrew. Consumers detect already-shipped leaks on update,
and a refocus line inoculates agents against identity conflation.

**Why this priority**: three field instances of the class (release-model
leak, identity conflation, self-host CI) were found by accident, never by
a gate; every template this feature touches must be born clean, so the
lint lands first.

**Independent Test**: seed each deny-list class into a deploy-surface
fixture and assert red; annotate and assert green-with-reason; render all
prompt surfaces against the fixture project and assert zero hits.

**Acceptance Scenarios**:

1. **Given** a deny-listed term in a deployed surface without an adjacent
   `specrew-self-ok: <reason>` annotation, **When** the repo lane runs,
   **Then** the build is red naming the file, term, and class (205-W1).
2. **Given** the same term with the annotation, **When** the lane runs,
   **Then** it passes and the reason is auditable (205-W1).
3. **Given** every built prompt surface rendered against an
   anything-but-Specrew fixture project, **When** scanned, **Then** zero
   deny-list hits (205-W4).
4. **Given** a consumer project with a previously-shipped leaked artifact,
   **When** `specrew update` or the gateway advisory runs, **Then** the
   leak is flagged (or healed) using the SAME shipped list the repo lane
   used (205-W5/W6).
5. **Given** the deployed refocus content, **When** a consumer session
   starts, **Then** it carries the inoculation line naming the governed
   project and Specrew's tool-never-subject role (205-W5c).

---

### User Story 6 - The toolchain pins are current and verified (Priority: P3)

The maintainer bumps Spec-Kit to 0.12.9 and Squad to 0.11.0. Init works on
the new CLI surface (`--integration`), the opt-in extension decisions are
recorded with probe evidence, and every pin surface agrees.

**Why this priority**: substrate for everything else (iteration 001), but
only one hard break and it is ours to fix.

**Independent Test**: scratch-dir probe of the 0.12.9 CLI + the existing
integration suites against a 0.12.9-initialized, no-extensions fixture;
pin-surface consistency assertions.

**Acceptance Scenarios**:

1. **Given** the migrated init, **When** it runs against Spec-Kit 0.12.9,
   **Then** it completes with `--integration <key>` (no `--ai` anywhere)
   and `--script ps` / `--ignore-agent-tools` usage verified by probe
   evidence (recorded).
2. **Given** the no-extensions 0.12.9 fixture, **When** the integration
   suites run, **Then** they are green, or any failure is traced and the
   needed extension is added with the evidence recorded (I1).
3. **Given** our `extension.yml`, **When** loaded under 0.12, **Then** the
   hooks schema (per-event lists + priority) loads without error.
4. **Given** all pin surfaces (CI env, version-check supported-versions,
   extension.yml requires, Get-SpecKitGitReference, dependency-install
   minimum, validate-versions defaults), **When** compared, **Then** they
   agree on 0.12.9 / 0.11.0.

---

### Edge Cases

- A delta mixing tracker and non-tracker files → stales unconditionally
  (the bypass is tracker-only by definition).
- Tracker claims the checker cannot parse or map → fail-closed: stale as
  today (W13).
- An explicit timeout ABOVE the resolved default → no warning (only
  downgrades warn, W14).
- Unknown host with no catalog row and no config → 600 floor (S3
  amendment).
- A user-modified retired template on update → left in place with a WARN
  naming it retired; never deleted (204-W5).
- Brownfield init where the human declines the bootstrap commit → the
  declined offer is recorded; reviews cope with the untracked scaffold as
  today (204-W5b).
- Reconciliation interrupted between decline and revert → no state
  advanced; the pending skip remains authoritative and re-surfaces at the
  next touchpoint (#2906).
- The detached review child fires after the branch moved → frozen
  fire-time tree is materialized; the run is labeled `snapshot-moved`, its
  findings remain visible with relevance hints, and it cannot approve the
  current snapshot (W10).
- A machinery-list edit that removes an exclusion → both strips change
  together; the paired reviewer-can-still-see-it test updates in the same
  change (W5).
- The allowance halts while the only open finding is already resolved in
  the disposition trail → the halt says so ("previous finding resolved; a
  fresh round is needed to confirm") and still waits for the human-typed
  reset — the spend checkpoint applies even to good news (FR-019 as
  amended).
- A deny-list annotation with no reason text → treated as unannotated:
  red (205-W1).
- The env cascade resolves a code-writer host equal to the reviewer host →
  independence is honestly `not-independent`; only differing hosts earn
  the independent label (W15).

## Requirements *(mandatory)*

### Functional Requirements

#### Governance boundary enforcement (#2906) — owner: implementer + spec steward; iteration 002

- **FR-001**: The system MUST provide one shared deterministic
  authorization check (the resurrected `Test-SpecrewBoundaryAuthorization`)
  that computes the delta between the actual lifecycle position and
  `last_authorized_boundary`, usable by every governed touchpoint with no
  host-hook dependency.
- **FR-002**: Boundary sync MUST refuse to record a new boundary crossing
  while a prior crossing lacks human authorization (delta > 1), with a
  loud refusal that names the skipped boundary and teaches both
  reconciliation doors; the first (unavoidable) unapproved crossing is
  still recorded mechanically per F-174.
- **FR-003**: The governance validator MUST emit a FAIL finding whenever an
  unreconciled skipped boundary exists.
- **FR-004**: Resume/start reconciliation MUST surface the skipped-boundary
  state as an "awaiting your verdict" re-confirm (extending the F-174
  backstop), independent of any inline hook output.
- **FR-005**: Reconciliation MUST support exactly two outcomes:
  retroactive human approval (advances the cursor; recorded distinctly in
  verdict history) or reversion to the last approved boundary's recorded
  AuthCommitHash (executed only after an explicit destructive-action
  confirmation).
- **FR-006**: Host hooks (Stop / conformance providers) MUST remain
  surfacing-only for boundary enforcement; no enforcement behavior may
  depend on a hook firing.
- **FR-007**: The honest limit MUST be documented and taught: on a
  non-stopping host one boundary of work can occur unapproved; it is
  caught at the next deterministic touchpoint and discarded if not
  retro-approved.

#### Reviewer containment (203 W1–W6) — owner: implementer + reviewer; iteration 003

- **FR-008 (W1)**: Reviewer worktrees MUST materialize outside the origin
  repository root (system-temp ephemeral root default) such that git
  upward discovery from inside the worktree cannot resolve the origin.
- **FR-009 (W2)**: The reviewer-visible context (`.review/process/**`,
  injected design docs) MUST NOT contain origin-absolute paths;
  strip/relativize at bundle build.
- **FR-010 (W3)**: The slim prompt and the reviewer spawn contract MUST
  state the confinement contract: worktree-only operations, origin paths
  out of bounds, lifecycle/governance script execution out of scope.
- **FR-011 (W4)**: The STRUCTURAL containment guarantee is FR-008 — the reviewer
  worktree materialized OUTSIDE the origin root, fail-closed. Riding the T100
  child-process registry, a containment MONITOR samples the reviewer process tree
  and classifies observed origin access by SIGNAL STRENGTH:
  - **Strong signal (fail-loud)**: a reviewer-tree process whose **cwd** or
    **executable** resolves UNDER an origin root MUST mark the run
    `containment-violated` and fail it loudly with a bounded, redacted origin-side
    record (process, path, timestamp; NEVER the raw command line/prompt/env/creds),
    never killing the reviewer mid-flight.
  - **Best-effort signal (diagnostic warning)**: a command-line ARGUMENT that
    resolves under an origin root is recorded as a bounded DIAGNOSTIC WARNING.
    Command-line/argv matching is inherently INCOMPLETE (it cannot cover every
    path-bearing argument form), so an argv match MUST NOT by itself discard an
    otherwise valid review. Best-effort coverage (absolute, quoted, relative
    traversal, `--name=value`) is provided without any completeness claim.
  The monitor MUST record its own HEALTH — sample attempts, successful samples,
  failures, and degraded visibility — so weaker visibility (a host with fewer
  samples, a sampling error, or a short-lived descendant that exits between
  heartbeats) is always VISIBLE and never silent inactivity. No origin-flavored
  data enters reviewer-visible artifacts.
- **FR-012 (W5)**: ONE path-granular machinery list MUST be the single
  source for both the digest strip and the worktree strip: host machinery
  (`.claude/**`, `.agents/**`, `.cursor/**`, `.copilot/**`,
  `.github/copilot-instructions.md`, `.github/instructions/**`,
  `.github/prompts/**`, `.github/agents/**`) excluded from both sides;
  `.github/workflows/**` and all other content included in both; every
  list change MUST ship a reviewer-can-still-see-it regression test.
- **FR-013 (W6)**: The reviewer prompt MUST teach what is intentionally
  absent from the worktree and instruct that absence findings for
  references into stripped machinery paths are not raised (runtime
  evidence, not path existence, is the verification shape for machinery).

#### Review evidence & round economy (203 W7–W12) — owner: implementer + reviewer; iteration 003

- **FR-014 (W7)**: The T111 standing practice MUST be resolved as: the
  refocus-instructed duty to record verification evidence via the **universal
  recorded-run runner** (FR-015) after a verification command runs is the
  host- AND framework-neutral floor; hook-automated recording (where a host
  supports it) is an enhancement, never the dependency — consistent with
  FR-006's hooks-are-UX doctrine.
- **FR-015 (W8, amended by maintainer ruling 2026-07-13 — language/framework-NEUTRAL)**: A
  **universal process runner** (`Invoke-ContinuousCoReviewRecordedRun`) MUST execute any
  DECLARED verification command and record ONLY what it DIRECTLY observed:
  - executable + arguments; working directory;
  - the exact reviewed-tree digest (evidence is bound to it);
  - start/end timestamps + duration;
  - exit code + timeout status;
  - stdout/stderr metadata: byte counts + sha256 integrity hashes; output TEXT is
    **PRIVATE BY DEFAULT** (amended by maintainer ruling 2026-07-14, run 20260714T130410888):
    the default persists NO output text (count/hash only) because no pattern redactor can
    recognize an arbitrary secret; a caller MAY explicitly opt into a bounded, engine-capped,
    credential-pattern-redacted tail (defense-in-depth only — the redactor is never claimed to
    catch arbitrary secrets); supplier-declared plan commands NEVER persist raw output
    automatically. A FAILED command whose output was suppressed records
    `failure_diagnostics: insufficient-without-disclosure` — missing diagnostics are surfaced
    honestly and NEVER become a clean or higher-confidence result. The ONLY door to persisted
    diagnostic text for a plan command is an explicit **human-authorized diagnostic disclosure**:
    `{ authorized_by, reason, command_id, max_tail_bytes? }` — bounded (engine cap), scoped to
    the ONE named command/run, auditable (the authorization persists in the durable record),
    labeled potentially sensitive, DURABLE in the digest-keyed store by design (durability is
    what makes it auditable and reviewer-reachable), and never automatic;
  - output-artifact digests;
  - whether the command executed successfully (`command_succeeded`).

  **Child-environment execution semantics (amended by maintainer ruling 2026-07-14)**: a
  supplier-declared plan command's child environment MUST be constructed from an **EMPTY map**
  plus a **normative, platform-specific engine baseline** in which EVERY variable is justified
  by paired runtime-evidence tests (currently EMPTY on both Windows and Linux — a resolved
  full-path child launches with no inherited environment), plus exactly the plan-declared
  `env_refs` names resolved from the ambient environment at spawn. `HOME`/`USERPROFILE`/
  `APPDATA`/`LOCALAPPDATA` are NEVER implicit baseline; `PSModulePath`, locale, terminal, and
  tool-specific variables are explicit `env_refs` unless runtime evidence proves the ENGINE
  requires them. The executable is resolved to a full path against the ambient parent
  environment BEFORE the child environment is constructed, so an inherited `PATH` is not
  implicitly required; an unresolvable executable is a RECORDED failure
  (`executable-not-resolvable`), never a silent skip. Purpose: reproducibility and least
  privilege — not hiding evidence from the reviewer.

  It MUST NOT build framework-specific parsers or maintain an adapter catalog, and MUST NEVER
  parse human-readable console output to infer test counts — Specrew cannot know every downstream
  language/framework/runner (custom included); the Specrew self-review is just ONE downstream.
  RICH test counts are OPTIONAL and come ONLY from a schema-valid **`SpecrewTestResult`** JSON the
  command PRODUCED DURING the recorded run, bound to the same tree digest:
  `{ "schema_version": "1.0", "result": "passed|failed|…", "counts": { "passed", "failed", "skipped" } }`.
  A downstream MAY supply a command/wrapper that translates its framework's output (Pester, pytest,
  Jest, Vitest, dotnet test, Maven, Gradle, Go, Rust, custom, …) into this contract; Specrew
  validates + records it WITHOUT knowing the framework. When no valid result is produced: record
  command-execution facts only, set counts **unavailable**, and classify exit 0 as `command_succeeded`
  (NOT "all tests passed"). When a structured result IS requested but missing / malformed / stale /
  schema-invalid: **FAIL LOUDLY** — never degrade to a richer pass claim. **Caller-supplied pass/fail
  counts are FORBIDDEN**; a rich claim comes only from a run-produced schema-valid result. The recorded
  command remains the reviewer's cheap re-run handle. (T018 is EVIDENCE-ONLY; scheduling, injection,
  digest collisions, stale results, and review lineage are T019.)
- **FR-016 (W9)**: The navigator MUST record the last-REVIEWED checkpoint
  identity and thread it as the next auto-fire's baseline, falling back to
  the trunk merge-base when none exists; the signoff `--live` merge-base
  doctrine is unchanged.
- **FR-017 (W10, amended by clarify 2026-07-11 — Devin-crew field
  diagnosis; currentness semantics amended by maintainer 2026-07-16)**: The fire-time checkpoint tree id MUST pass through the
  detached chain; the child MUST materialize exactly that frozen tree;
  the reviewed tree id MUST be stamped into EVERY run record surface
  (including the findings result, not only the run index); the NAVIGATOR
  surfacing path MUST perform the same digest match the signoff gate
  already does BEFORE blocking on a run's findings. A result whose reviewed
  snapshot no longer matches the current tree is labeled `snapshot-moved`,
  not discarded or described as irrelevant: it cannot approve or freshly
  block the current tree, but every finding remains visible with its original
  severity and seeds the next incremental review. Where a finding carries a
  precise path, compare that path's reviewed/current blob identity and label
  it `likely-still-relevant` when unchanged or `needs-re-evaluation` when
  changed; a finding without a precise target is `relevance-unassessed`.
  These relevance labels are informative and never independently grant gate
  authority. The implementer-facing message MUST name both snapshot identities,
  state that the review does not approve the current snapshot, summarize the
  changed-path count, and explain that relevant findings may be fixed before a
  re-review. A new
  hook-fired review MUST NOT launch while one is already in flight for
  the same lineage (in-flight dedup).
- **FR-018 (W11, amended by clarify 2026-07-10 + follow-up)**: The
  allowance-halt text (and the reap's surfacing note) MUST be
  consumer-legible spend-guard teaching: state that the review-loop
  allowance is exhausted (N of M rounds used), explain that the allowance
  guards the project's AI-usage spending (each round invokes a paid
  reviewer), state why a human decision is wanted now, and instruct the
  AGENT to ask the human a plain approve/deny question — on the human's
  recorded conversational approval the agent executes the remediation
  itself, citing the approval as authorization evidence (the human is
  NEVER asked to copy-paste a command; the trust boundary binds the
  decision, not the keystrokes). The text MUST state that a bare `--live`
  rerun will NOT re-review past the allowance, MUST NOT suggest touching
  runtime state, and MUST NOT contain Specrew-internal identifiers
  (trust-boundary rule names, self feature/iteration numbers, proposal
  references) — a message-content test asserts their absence.
- **FR-019 (W12, amended by clarify 2026-07-10 — supersedes the
  workshop's no-increment design; further amended by maintainer ruling
  2026-07-12, DRIFT-198-I003-005)**: The round ceiling is an AI-usage
  spend allowance: EVERY review round counts toward it, including
  fix-responsive rounds. The halt MUST distinguish the states honestly in
  consumer language — "your previous finding was resolved; a fresh round
  is needed to confirm" vs "a blocking finding is still open" — so the
  human's reset decision is informed; the resolved-prior-finding state
  MUST be computed from the disposition trail, never guessed.
  **Resolving vs replenishing are SEPARATE (2026-07-12 ruling):** resolving a
  finding (`resolved-against-disk`) clears the blocking finding + its lineage
  but MUST **PRESERVE the spent-round count** — it NEVER implicitly replenishes
  the allowance. Replenishing or extending the allowance is a **separate,
  explicit human-approved action** (`allowance-reset`) that MUST record the
  authorizer, the timestamp, and the previous/new allowance, and MUST leave the
  resolved-finding evidence intact. (Earlier, `resolved-against-disk` reset the
  round to 0 and unintentionally replenished the allowance — see
  DRIFT-198-I003-005.)

#### Digest identity & budgets (203 W13–W16) — owner: implementer + spec steward; iteration 002

- **FR-020 (W13)**: The signoff gate MUST grant a tracker-only evidence
  bypass ONLY when the deterministic honesty check passes: the edited
  tracker's claims are consistent with (a subset of) the accepted
  `review.md` verdict and recorded run evidence. Claims-increasing edits
  MUST stale the digest exactly as today; unparseable claims MUST
  fail-closed to stale. Scope: `specs/*/iterations/*/state.md` and
  `specs/*/iterations/*/tasks-progress.yml` only; the digest identity
  formula itself is unchanged (mechanism b) and the granted bypass is
  announced in the gate output.
- **FR-021 (W14)**: Budget resolution MUST warn, at resolution time, when
  an explicit `--timeout-seconds` undercuts the RESOLVED
  config/catalog/floor value it overrides; explicit-beats-config
  precedence (DEC-197-I010-007) is unchanged.
- **FR-022 (W16)**: The reviewer-host catalog MUST carry a per-host
  `default_timeout_seconds` column; resolution order MUST be explicit flag
  → project config → catalog per-host default → **600-second floor**
  (terminal fallback, never a clamp); on a plain timeout failure the
  durable record and CLI message MUST teach the sanctioned next steps
  (re-run with a larger explicit budget, or raise
  `co_review_timeout_seconds`) while the increase itself stays
  human-approved per T096 as amended (clarify 2026-07-10 follow-up: the
  agent asks a plain approve/deny question and executes on the recorded
  approval — the human never copy-pastes commands); the agent never
  self-escalates. Shipped values (clarify 2026-07-09): antigravity 900,
  claude 600 (field-measured); codex and copilot rows are added from
  timed reviews on the consumer test project during iteration 002 —
  absent rows fall to the floor until measured.
- **FR-023 (W15)**: The manual `--live` door MUST resolve the code-writer
  host, when the flag is absent, via the same env cascade as
  `--list-hosts` (`--code-writer-host` → `SPECREW_HOST` →
  `SPECREW_ACTIVE_HOST`, explicit flag wins) and MUST record
  `independence_source: flag | env | unverified` in the run evidence;
  SEC-004's fail-closed treatment of `unverified` is unchanged.

#### Consumer distribution (204) — owner: implementer; iteration 004

- **FR-024 (W1)**: A new consumer template `specrew-methodology-gate.yml`
  MUST run markdownlint with the same ignore set as the local F-033 gate,
  the governance validator at its DEPLOYED consumer path (full run), and
  PSScriptAnalyzer conditional on `.ps1` files existing; triggers MUST be
  generic (`main` + the `[0-9][0-9][0-9]-*` feature-branch pattern); the
  posture is advisory-first per F-182 (deterministic hard-fails may block,
  warnings never) with the posture stated in README/user-guide teaching.
- **FR-025 (W2)**: `specrew-work-kind.yml` MUST point at the deployed
  validator location and keep its advisory default.
- **FR-026 (W3, with 205-W3)**: The template deploy surface MUST become
  deny-by-default: only the consumer-ized set (FR-024 + FR-025) deploys;
  the self-host lanes (`deterministic-gate` job, `specrew-project-sync`,
  `specrew-confidence-lane`) move out of `templates/` into this repo's
  `.github/workflows/`; distribution assertions update to the new set.
- **FR-027 (W4)**: Init MUST add a `.gitignore` entry for the machine-local
  host config it deploys.
- **FR-028 (W5)**: `specrew update` MUST remove retired templates from
  existing consumers via the F-116 obsolete-file surface with a
  content-hash guard: byte-identical files are removed, user-modified
  files are left with a WARN naming them retired.
- **FR-029 (W5b)**: Init MUST end with an announced
  `chore(specrew): bootstrap scaffold` commit on greenfield projects and
  an explicit, recordable offer on brownfield projects — giving every
  review and feature diff a clean baseline.
- **FR-030 (W7)**: Feature-closeout teaching MUST resolve a release model —
  `repository-governance.yml` if present, else inferred (no remote →
  local-only; remote without forge config → push-only; forge → PR flow;
  publish target → beta→stable) — render ONLY the applicable steps, name
  why the rest are N/A, scope the beta-before-stable mandate to projects
  WITH a publish target, and let init record the model (ask once, infer as
  default); the lifecycle template's "Produces a release: yes" line
  becomes release-model-aware.
- **FR-031 (D1)**: Gateway deployment MUST key off the recorded provider:
  `github` or unset → deploy; explicitly non-GitHub → skip and name the
  manual validator path; shipped action pins are by major version and
  refresh via the update heal surface.
- **FR-032 (#2903)**: `specrew update` MUST sync `refocus-scopes.json`
  into an existing `.specify` so newly added provider/scope rows are never
  inert downstream.

#### Self-leak firewall (205) — owner: implementer + reviewer; iterations 001 (W1/W2/W6), 003 (W10 via FR-015/T018), and 004 (W3/W4/W5, W7–W9)

- **FR-033 (W1)**: A repo CI lane MUST scan exactly what ships to
  consumers (the deploy manifest's allowlist plus deployed scripts' string
  literals) against the deny-list; a deny-listed term without an adjacent
  `specrew-self-ok: <reason>` annotation is a red build. This lane lands
  in iteration 001 so every surface the feature touches is born clean.
- **FR-034 (W2)**: Deployed teaching MUST state the abstract rule plus a
  resolution point filled from project governance/config at render time —
  never Specrew's own instantiation as an example-that-reads-as-mandate
  (FR-030 is the first instance; FR-033 enforces mechanically).
- **FR-035 (W4)**: A runtime fixture test MUST render every built prompt
  surface (reviewer round teachings, navigator inject notes,
  boundary-packet scaffolds) against a fixture project named
  anything-but-Specrew and assert zero deny-list hits.
- **FR-036 (W5)**: The SAME deny-list MUST run consumer-side: as an
  advisory check in the methodology gateway, in `specrew update`'s heal
  surface (flag or rewrite already-shipped leaks), and one refocus
  inoculation line MUST deploy to consumers ("the project under governance
  is <resolved project name>; Specrew is the tool, never the subject").
- **FR-037 (W6)**: The deny-list MUST be one versioned data file (JSON,
  `schema_version`, entry shape pattern/class/reason/source/added;
  annotation syntax per file kind — HTML comment for `.md`, `#` line
  comment for `.ps1`/`.psd1`/`.yml`; same-line-or-line-above semantics)
  shipped with the module and read by both the repo lane and the
  consumer-side checks; consumer-side version mismatch is a fail-open WARN.

**Amendment — 2026-07-13 (technology-assumption firewall; proposal 205 W7–W10, merged to main `1210d4e7`).**
The original classes catch concrete Specrew-self facts (identity, path, release-model, self-host CI).
The F-198/T018 design review surfaced a broader semantic class: a downstream-FACING statement that
presents one stack, forge, test framework, package mechanism, or delivery model as universal WITHOUT
proving it applies — a leak even when it names no Specrew identifier. **W10 (generic contract before
adapters) is ALREADY realized in iteration 003 by FR-015/T018**: the recorded-run contract records
framework-NEUTRAL execution facts and accepts an OPTIONAL project-produced `SpecrewTestResult`, never
a built-in framework parser. **W7–W9 land in iteration 004 under T028**, composing with the
provider-gated consumer CI (T021–T023) and the release-model resolver (T027); they DO NOT reopen the
shipped firewall (T004–T006):

- **FR-046 (205-W7/W8)**: Every downstream-FACING technology or delivery statement MUST carry
  applicability provenance — exactly one of: `project-detected` (from repository evidence),
  `profile-selected` (by an explicit quality/work-kind profile), `provider-gated` (by repository
  governance), or `example-only` (worded so it cannot read as a mandate). An unqualified concrete
  technology statement is a leak EVEN WITH no Specrew identifier. The one versioned deny-list (FR-037)
  gains `stack-assumption` and `delivery-assumption` classes — concrete frameworks/runtimes/test tools
  used as universal requirements, and package/prerelease/registry/forge workflows used without a
  resolution point — matching ONLY consumer-DEPLOYED surfaces. This does NOT globally ban technology
  names: Specrew's own implementation code, explicitly selected stack presets, and provider-specific
  templates behind a matching provider gate are NOT findings.
- **FR-047 (205-W9)**: The FR-035 fixture matrix MUST additionally cover a Python project with a
  non-Pester test command, a non-GitHub repository, and an internal application with no publish/release
  target; rendered prompts, refocus teaching, lifecycle templates, evidence guidance, and deployed CI
  MUST contain no inapplicable technology or delivery mandate for those fixtures.

#### Downstream verification model — owner: T018/T019 (seam, iteration 003) + parallel crew (supplier)

- **FR-048 (T019 verification-plan seam)**: The recorded-run evidence path MUST accept its work as a
  framework-NEUTRAL ORDERED verification plan and execute it under these invariants (maintainer-approved with
  amendments 2026-07-13):
  - **Identity + joins**: the plan carries `schema_version` and a stable `plan_id`; every command carries a
    stable `command_id`. Every execution record binds to BOTH the exact reviewed-tree digest AND its
    `command_id`; T019 injects ONLY matching evidence and MUST reject digest-mismatched, DUPLICATE, or
    UNJOINABLE (no matching `command_id`) evidence.
  - **Command shape**: each command carries `executable`, `arguments` as a string ARRAY (never a shell
    command string — shell behaviour MUST be explicit, e.g. `pwsh -File …` / `bash -lc …`), optional
    `working_directory` / `result_path` that MUST be repository-relative + canonicalized and are REJECTED if
    rooted or if they escape via `..` or a link, and `timeout_seconds` bounded by ENGINE POLICY (a supplier
    can never request an unlimited run).
  - **Auditable provenance**: provenance is an OBJECT `{ kind, source, … }` where `kind` is exactly one of
    `project-config` / `project-detected` / `profile-selected` / `provider-gated` and `source` (plus
    provider/profile identity where applicable) makes it auditable — not a bare enum.
  - **No secrets**: neither the plan nor recorded evidence embeds secret environment VALUES; environment
    customization is expressed as named references / an allowlist, and recorded values are redacted.
  - **Execution + evidence**: A structurally-invalid plan — a malformed identity graph, e.g. a DUPLICATE
    `command_id` — is rejected FAIL-FAST at plan validation BEFORE any command executes, producing ZERO command
    side effects (the T019 evidence-join duplicate rejection remains as defense-in-depth). Otherwise T018 runs
    commands in DECLARED ORDER and records EVERY attempted command; a failure MUST NEVER become missing evidence
    or a clean result (a non-zero exit / timeout is recorded as a failed command, never dropped, never clean).
    Exit 0 records `command_succeeded`, never "all tests passed". `require_result=true` means the command MUST
    produce a schema-valid `SpecrewTestResult` — its absence or invalidity is a verification FAILURE; otherwise
    process evidence stays valid with counts unavailable.
  - **No discovery**: an absent/empty plan resolves to an explicit `verification-not-configured` state (never
    a silent success, never a Specrew/Pester default); T018/T019 MUST NOT discover, infer, or invent commands
    (no framework inference from file extensions) and accept plans of ARBITRARY commands + MIXED technologies
    unchanged. Producing the plan is the SEPARATE supplier workstream (FR-049).
- **FR-049 (beta2 RELEASE DEPENDENCY — command-plan supplier)**: The beta2 feature/release MUST NOT close
  while the production verification path has no command-plan SUPPLIER feeding T018 through the FR-048
  contract. This is a RELEASE DEPENDENCY, not optional future work. The supplier (a separate
  downstream-verification-selection workstream, delivered by the parallel crew) MUST provide a minimal usable
  beta contract with selection precedence: (1) explicit project configuration as the authoritative source;
  (2) reliable detection from existing project-owned CI/build/package metadata; (3) explicit quality-profile
  selection; (4) provider-specific commands ONLY when that provider is active; (5) a clear setup prompt or
  actionable error (the `verification-not-configured` state) when nothing trustworthy can be selected; (6) NO
  inference from file extensions and NO Specrew/Pester default. T018/T019 own execution + injection only
  (FR-048); they never own selection/discovery.

#### Local-host Beta2 compatibility — owner: implementer; iteration 005 (Beta2 RELEASE BLOCKER, before FR-040)

Beta2 is CLI-FIRST; cloud agents and cloud-gated development are explicitly UNSUPPORTED. GitHub issue #3084
(`https://github.com/alonf/specrew/issues/3084`) records the broader Beta3 modernization — host capability
negotiation, native lifecycle/subagent events, structured-output transport migration, plugin architecture, and
multi-version + desktop/IDE certification — which is OUT OF SCOPE here. These FRs are the NARROW local-host
blockers that MUST hold before beta2 ships; they must NOT be deferred into Beta3.

- **FR-050 (host-support model + truthful tiers)**: CLI is the AUTHORITATIVE supported surface. Every host /
  surface support claim MUST carry exactly one classification — `verified` (exercised end-to-end on that
  surface), `configuration-compatible` (documented shared configuration; lifecycle NOT independently
  exercised), `unsupported` (no reliable gated integration), or `unverified` (intended support exists but the
  conformance probe has not passed). NO cloud-agent support may be implied. Claude VS Code and Codex IDE/desktop
  are `configuration-compatible` (shared settings/hooks / shared Codex config layers); Copilot VS Code MUST NOT
  claim hook-gated CLI compatibility; Cursor desktop is `unverified`. Any claim that Copilot VS Code or a cloud
  agent receives CLI Stop-hook enforcement MUST be removed. Reference issue #3084 for the Beta3 follow-up.
- **FR-051 (Codex Stop-contract conformance)**: Specrew currently models the Codex Stop as Claude-style
  `{"decision":"block","reason":...}`, but the Codex manual documents shared hook control as
  `{"continue":...,"stopReason":...,"systemMessage":...}`. Do NOT guess. An ISOLATED executable conformance
  fixture (a SCRATCH dir, never the governed cwd — hooks self-bootstrap and mutate state) against the INSTALLED
  Codex CLI MUST prove: the hook is discovered; the Stop event fires; the accepted continuation/block response
  shape; the reason reaches the next turn; allowing Stop actually terminates; the loop guard prevents indefinite
  continuation; malformed output fails VISIBLY (never becomes a clean pass). Then update ONLY the Codex host
  adapter to the OBSERVED contract — the host-neutral dispatcher and the T019 Stop-intent semantics are
  preserved and translated at the adapter boundary.
- **FR-052 (Copilot CLI contract verification)**: Test interactive Copilot CLI user-hook discovery,
  non-interactive `copilot -p` user-hook + repository-hook discovery, any required prompt-mode opt-in, and
  agentStop blocking / continuation-reason delivery / allow-termination / loop behavior — do NOT rewrite the
  documented `{"decision":"block","reason":...}` speculatively. The reviewer path INTENTIONALLY suppresses
  Specrew governance hooks; the test MUST distinguish that intentional suppression from an accidental downstream
  governance bypass. If project hooks are not loaded in `-p` by default, EITHER set the documented opt-in
  whenever Specrew expects governance OR report that mode `unsupported` — never silently claim it is gated.
- **FR-053 (minimum hook-health evidence)**: A deployed configuration is NOT proof the host loaded it. A REAL
  host-triggered SessionStart/Stop fire MUST record a SANITIZED receipt (host; surface=cli; event; observed
  host version; timestamp; adapter contract version) — with NO prompt, command arguments, environment values, or
  secrets recorded. Missing / stale / conflicting / malformed receipts report `unverified` / `degraded`, and
  MUST NEVER report `healthy`. The result is exposed through the existing doctor/status surface (or the narrowest
  established equivalent). This is NOT Beta3's full capability-negotiation system.
  - **FR-053a (hook-liveness + non-authoritative version diagnostic — Prop-145 amendment 2026-07-14; explicit
    DESIGN DRIFT from the earlier "current host version" model)**: Hook health measures OBSERVED LIFECYCLE LIVENESS —
    a fresh, well-formed receipt shows the configured hook path was recently observed firing. This is MONITORING
    evidence, NOT authentication: the receipt store is project-writable and the dispatcher can be invoked directly,
    so `healthy` is operational confidence, never proof of the host process, and Specrew does not present a receipt
    as tamper-proof. SessionStart MAY collect a BOUNDED, shell-safe, cross-platform PATH-binding `--version` DIAGNOSTIC
    (source `ambient-path-binding`); it is NON-AUTHORITATIVE and NON-PROMOTING — it NEVER promotes hook-liveness or
    readiness, and a `diagnostic-match` means only that two readings resolved an equivalent reported version through
    the ambient command binding. Strong executable identity is UNAVAILABLE on current host contracts (no host event
    or adapter exposes a non-ambient executable path/version — characterized 2026-07-14) and is NOT claimed. The
    status shape is INDEPENDENT fields: `hook_status` (healthy | stale | malformed | conflicting | absent) and
    `version_status` (diagnostic-match | diagnostic-drift | unavailable | untrusted-source). Governance READINESS
    combines fresh lifecycle evidence with the independently validated host configuration/trust prerequisites (never
    the version). The probe is bounded in time AND memory (byte-capped output, tree-killed on timeout, fail-closed on
    overflow); a Windows `.cmd`/`.bat` shim uses the System32 cmd.exe with an injection-guarded path.
    The adapter contract version is bumped (v3) so every pre-amendment receipt retires. `SPECREW_OBSERVED_HOST_VERSION`
    remains removed.
- **FR-054 (Codex plugin packaging scope, CONDITIONAL)**: IF Beta2 ships Codex plugin installation, a regression
  MUST prove a plugin that intends no Codex hooks uses exactly `hooks: {}` and cannot auto-discover another
  host's `hooks/hooks.json`. IF plugin installation is NOT a Beta2 deliverable, it stays in issue #3084 and is
  NOT implemented here.
- **FR-055 (non-boundary Stop-packet classification honesty — maintainer directive 2026-07-14)**: The
  conformance Stop-provider MUST NOT classify an ordinary consultation, explanation, or read-only status turn
  as material merely because the working tree is dirty or a tool/file read occurred: the material demand keys
  on the TURN'S OWN delta — the dirty-tree surface captured at SessionStart (and advanced at every discharged
  stop) is the session BASELINE, and only a surface that DIFFERS from it owes the five-heading packet. The
  surface key MUST ignore Specrew-managed-count drift. The packet demand MUST still fire after actual
  state-changing work, after a genuinely LONG read-only investigation (deterministic assistant-entry count
  since the last human message at/over a fixed threshold — a real re-entry need), and the five-heading
  structure is unchanged where required. Lifecycle BOUNDARY packets and boundary authorization are untouched.
  Post-response duplication MUST be prevented by ARRANGING the packet in the original response: a PostToolUse
  tracked-change emits a ONE-PER-OBLIGATION-WINDOW non-blocking nudge instructing the agent to end its final
  message with the packet; an already-valid packet is accepted without another forced turn. Classification is
  deterministic (no model-judged compliance); where a host lacks the deterministic signals the provider fails
  OPEN toward the pre-existing enforcement, never toward a fabricated pass. Regression fixtures MUST cover:
  (a) short consultation with no writes → no demand; (b) read-only status over a pre-session dirty tree → no
  demand; (c) substantial state-changing work → packet required; (d) long read-only investigation → packet
  required; (e) an already-valid packet → accepted without another turn; (f) a boundary stop keeps the
  six-section contract.
- **FR-056 (workshop-aware intermediate Stop — maintainer directive 2026-07-16)**: While a design workshop is
  durably recorded as in progress and the assistant has rendered the current lens content plus a question that
  explicitly awaits the human's answer, the Stop provider MUST classify that pause as a workshop-intermediate
  stop and MUST NOT force the generic five-heading non-boundary context packet. The rendered workshop turn is
  already the re-entry context and remains the final visible message. This exception MUST be deterministic and
  narrowly scoped to either (1) the active feature-level specify/intake agenda before any iteration exists, or
  (2) the active feature + exact iteration during design analysis, plus the current lens and pending human
  question. The assistant marker MUST declare which scope it uses; a feature-scope marker after iteration
  activation or an iteration marker without active iteration truth MUST fail closed. Prose that merely claims to
  be a workshop MUST NOT suppress enforcement. Lifecycle boundary stops override workshop state and retain their
  full boundary packet. Leaving, abandoning, or handing over a workshop without a pending lens question retains
  the ordinary non-boundary material-work packet requirement. Regression fixtures MUST cover: (a) active
  feature-level intake and iteration-level workshop questions each stop once with no duplicate five-heading
  packet; (b) the same material turn outside durable workshop state still requires the packet; (c) fabricated
  workshop prose and cross-scope markers cannot bypass enforcement; (d) a lifecycle boundary during a workshop
  still requires the boundary packet; and (e) an interrupted workshop handover still renders sufficient durable
  re-entry context without inventing an iteration identity.

#### Controlled external review rearchitecture — owner: implementer + reviewer; Beta2 release blocker

- **FR-057 (campaign/run authority model)**: The review subsystem MUST model a
  `ReviewCampaign` above a sequence of `ReviewRun` records. A campaign owns target
  lineage, human-granted review allowance, reservations/spend, finding lineage, and
  selection of the current applicable result. Each run represents exactly ONE
  external reviewer invocation against ONE frozen target. Legal transitions MUST be
  decided by a pure state-machine core behind ports; Git, filesystem, process,
  harness, operating-system, and clock mechanisms remain adapters. Campaign, run,
  and claim repositories are the sole logical mutation paths for their authority
  records. The system guarantees at most one authoritative selected result for a
  campaign/target state; it MUST NOT claim exactly-once execution of an external AI
  process.
- **FR-058 (immutable JSON authority and allowance accounting)**: Durable review
  authority MUST use dependency-free, schema-versioned JSON facts organized by
  campaign and unique `run_id`. Lifecycle stages, results, validation,
  classification, grants, reservations, invocation/spend, pre-invocation release,
  claim-generation, and the optional campaign review-finalization binding are
  created once using atomic no-overwrite
  `CreateNew` semantics. Claims belong to run identities, not launcher/supervisor
  processes; released and abandoned generations are appended, never rewritten or
  deleted. Only a human may grant more allowance. Actual provider invocation spends
  its reserved slot even if it later fails; a proven pre-invocation failure releases
  the slot. An identical existing fact is idempotent success; a conflicting fact is
  repository corruption and fails closed. Beta2 MUST NOT introduce a generic lock,
  mutable revision/CAS framework, SQLite dependency, general event store, or
  automatic pruning subsystem. Legacy review state remains read-only and cannot be
  silently promoted into the new authority model.
- **FR-059 (review target isolation and currentness)**: Production code review MUST
  run in a disposable external Git worktree that shares Git objects without exposing
  the origin as the reviewer workspace. Specrew hooks/skills/machinery are disabled
  through the controlled harness environment and may be removed from the disposable
  tree; the reviewer is not required to have Specrew installed. The origin repository
  is the sole code-mutation authority. Pre/post origin HEAD plus the canonical
  reviewed-state digest determine exact currentness; execution observed with cwd or
  executable under the origin is `containment-violated`. Snapshot movement follows
  FR-017: findings remain visible with relevance provenance but cannot approve the
  current snapshot. The core MUST expose a real `ReviewTargetPort`, prove production
  code review, and include a thin non-code contract fixture so later gate/artifact
  support is not blocked by a code-specific abstraction.
- **FR-060 (common reviewer contract and complete harness implementations)**: The
  controller and harness adapters MUST use one synchronous, versioned local
  process/file contract carrying campaign/run identity, target digest, frozen
  workspace, review scope, bounded prompt reference, candidate JSON/report paths,
  and deadline. Reviewers write only candidate output in staging (or adapters
  materialize candidates from captured stdout); the controller alone validates and
  publishes authoritative `result.json` plus human-readable `report.md`. Candidate
  JSON MUST be bounded, closed-schema, and identity-bound; Markdown is never parsed
  for authority. Thin real adapters MUST implement this contract for Claude Code,
  Codex CLI, GitHub Copilot CLI, Cursor Agent, and Antigravity. Each adapter uses its
  conformance-proven prompt mechanism and may reuse necessary existing
  authentication/configuration for stable execution, but credentials, raw
  environments, full prompts, and unrestricted raw output MUST NOT enter durable
  records. Unsupported schemas, malformed output, unknown required fields, or
  identity mismatch fail closed. A shared contract plus only one implemented harness
  does NOT satisfy Beta2 completeness.
- **FR-061 (cross-platform runtime control and explicit terminal results)**: The
  controller MUST supervise the complete reviewer process tree through an OS runtime
  adapter: Windows Job Objects, Linux cgroups, and a conformance-proven macOS native
  process-group mechanism. Harness timeout is configurable; the default maximum
  termination grace is 10 seconds. On timeout, the controller MUST terminate and
  verify the process tree dead, close streams, capture and validate bounded partial
  output, and only then publish the controller-generated terminal `result.json` and
  `report.md` with `completion=partial`, `verdict=incomplete`,
  `runtime_outcome=timed-out`, observed timing, termination evidence, clear failure
  reason, and any valid partial findings. Every invoked run MUST publish exactly one
  terminal authoritative result envelope, including post-invocation failures;
  controller-owned runtime classification is not delegated to the reviewer.
- **FR-062 (re-review, recovery, finding lineage, and retrospective evidence)**:
  Valid findings recovered from an interrupted or snapshot-moved run remain advisory
  evidence with original severity and completeness/relevance provenance. They never
  form a complete verdict. A complete rerun is a separate `run_id`, consumes another
  already-authorized allowance slot, and is launched automatically only while such a
  slot remains; otherwise the system requests a new human grant. Adapters MUST NOT
  retry providers secretly. Finding lineage links likely matching findings across
  partial, complete, moved-snapshot, and rerun results without requiring AI harnesses
  to reproduce a shared ID. Restart reconciliation MUST deterministically continue
  validation/classification, release a non-invoked reservation, close an invoked dead
  run as spent/abandoned, and retire its claim through immutable facts. Retrospective
  generation consumes validated JSON findings—not Markdown—and retains campaign,
  run, finding, harness, target, completeness, relevance, and resolution provenance.
- **FR-063 (observable and economical execution)**: Informational CLI progress MUST
  distinguish lifecycle stage, elapsed/remaining time, process-tree liveness, and
  output activity without promoting activity to semantic review progress. Finding
  counts appear only from complete schema-valid checkpoints. Authority-bearing
  evidence MUST include target identity, invocation/spend, process start/terminal
  outcome, deadline/termination, containment, validation, and currentness. Production
  time records controller-observed UTC start/end plus monotonic duration with
  system-observed provenance; injected clocks are test-only. Cheap Git/target/store/
  contract/containment/harness preflight MUST finish before provider invocation and
  spend. Prompts MUST remain bounded and omit source content; incremental reruns may
  include changed-file and unresolved-finding summaries while the complete frozen
  snapshot remains reviewable and covered by the verdict. Duplicate target/harness/
  contract combinations are surfaced before spend; required identity hashing occurs
  only at integrity points; low-cost heartbeats MUST NOT rehash the repository. Phase
  durations and safe numeric token/usage/cost data are recorded when available.
- **FR-064 (conformance proof and truthful support)**: Beta2 completion requires one
  bounded real review from EACH of the five supported harnesses producing valid JSON
  and Markdown. Those five paid smokes are distributed so Windows, macOS, and Linux
  each have live evidence. Deterministic executable fixtures MUST exercise every
  adapter and all failure paths on the three-OS CI matrix, including malformed
  output, wrong identity, timeout, interruption, and complete-tree termination. A
  harness that is unavailable, unauthenticated, incompatible, or unable to finish
  its real smoke remains honestly unproven, and overall five-harness completeness
  does not pass. A particular harness/OS pair MUST NOT be described as live-proven
  without corresponding evidence.
- **FR-065 (delivery and deferral boundary)**: Beta2 owns the shared campaign/run
  foundation, production code review, the thin non-code target fixture, all five real
  harness adapters, and Windows/macOS/Linux runtime control. Production generic gate
  and artifact target adapters are deferred to Beta3 iteration A (estimated 12–16 SP,
  planning midpoint 14). Prioritized first-class lifecycle profiles are deferred to
  Beta3 iteration B (estimated 8–12 SP, planning midpoint 10). Beta3 MUST reuse the
  `ReviewTargetPort` and campaign/run foundation rather than create bespoke review
  engines per artifact type.

#### Toolchain currency — owner: implementer; iteration 001

- **FR-038 (Spec-Kit)**: The Spec-Kit pin MUST move to 0.12.9: init
  migrates `--ai copilot` → `--integration <key>`; `--script ps` /
  `--ignore-agent-tools` survival and `extension.yml` hooks-schema loading
  are verified by scratch-dir probe with recorded evidence; the opt-in git
  / agent-context extensions are added ONLY on demonstrated dependency
  (I1); all pin surfaces update (CI env `SPEC_KIT_VERSION`,
  `version-check.ps1` supported-versions, `extension.yml`
  requires/min_speckit, `Get-SpecKitGitReference`).
- **FR-039 (Squad)**: The Squad pin MUST move to 0.11.0
  (`@bradygaster/squad-cli`): `dependency-install.ps1` minimum, CI
  `SQUAD_VERSION`, `validate-versions.ps1` defaults; verified via the
  scratch-dir `squad init --non-interactive` probe and the existing
  `.squad` layout suites.

#### Release — owner: maintainer + implementer; iteration 004

- **FR-040**: The release MUST ship as tag `v0.40.0-beta2` (no-dot),
  ModuleVersion `0.40.0`, `Prerelease = 'beta2'`; a pre-tag deterministic
  check MUST verify the seven bookkeeping surfaces
  (`extensions/specrew-speckit/extension.yml`, its `.specify` mirror,
  `.specify/extensions.yml`, `.specrew/config.yml` specrew_version,
  CHANGELOG, README, Specrew.psd1 incl. FileList) before the tag is
  pushed; `docs/operations/psgallery-release-credentials.md` MUST be
  rewritten to describe the auto-publish reality.

#### Verdict-capture integrity (field incident DEC-198-GOV-001, maintainer-instructed 2026-07-11)

- **FR-041 (GOV-001a)**: Human-verdict capture MUST consider only
  genuinely human-typed turns as verdict evidence: hook-injected and
  machinery-generated transcript turns (host hook blocking feedback,
  injected governance/system text) are excluded regardless of their
  transcript role labeling. Paired tests: a genuine human verdict
  captures; the identical text arriving as hook feedback does not.
- **FR-042 (GOV-001b)**: Approval tokenization MUST NOT parse
  approval-shaped text that merely mentions, quotes, or teaches about
  approval (e.g. "if you already approved, please re-confirm") as an
  approval verdict; only an actual human verdict utterance authorizes.
  Abuse-path tests carry message-content assertions per NFR-007.
- **FR-043 (GOV-001c)**: Regression fixtures MUST reproduce the exact
  2026-07-11 fabrication sequence — rendered boundary packet, Stop-hook
  blocking feedback arriving as a user-role turn, no human reply — and
  assert that capture records nothing (no ledger entry, no pending
  artifact consumption).
- **FR-044 (GOV-001d)**: The authorization ledger MUST gain a designed
  correction mechanism that APPENDS an invalidation/correction record —
  preserving the original entry's identity, the correcting authority,
  the reason, the timestamp, and the resulting boundary state — never
  silently deleting history; every effective-state reader MUST honor
  invalidation records. (The 2026-07-11 surgery was a one-off deletion
  because no door existed; this requirement retires that class.)
- **FR-045 (GOV-002, stop-ordering; field incident 2026-07-12,
  maintainer-instructed)**: A user-facing lifecycle **verdict/boundary
  packet** (the six-section re-entry packet with approval options and a
  `SPECREW-VERDICT-BOUNDARY` marker) MUST NOT be rendered while a REQUIRED
  co-review of the boundary's increment is pending/in-flight, or before
  that review is clean or human-dispositioned and its reviewed-tree digest
  matches the EXACT current digest. One controller-owned carry-forward is
  permitted only for a clean result: the current commit MUST have the reviewed
  commit as its sole direct parent; its complete file-level diff MUST contain only the six
  generated iteration review artifacts (`review.md`, `reviewer-index.md`,
  `code-map.md`, `coverage-evidence.md`, `dependency-report.md`, and
  `review-diagrams.md`); scripts, tests, state/plan/tasks, and all
  specification/contract files are ineligible. The controller MUST validate
  the parent/digest/current-state binding, then publish exactly one immutable
  campaign fact `{run, reviewed digest, finalization commit}` through
  `CreateNew` in the authority store outside the reviewed digest. A second
  finalization, an envelope chain, any extra path/status, or later working-tree
  movement fails closed. The gate MUST record and display both identities as
  `reviewed at <commit>` and `finalized as <commit>`. A blocked or superseded review attempt
  MUST produce NO approval options and NO verdict-boundary marker. A human
  question genuinely needed DURING review MUST be a NARROW, non-boundary
  decision (no approval options, no marker), never a lifecycle verdict
  packet. The boundary packet is rendered ONLY after exact-current-digest
  review evidence is clean or human-dispositioned, or after the single
  validated clean-result finalization described above. Bound to the
  T019 in-flight/digest work (the reviewed-tree-digest acceptance gate) and
  the T030–T032 capture-integrity work so a blocked or superseded packet
  can NEVER be captured as authorization evidence. (Field incident: during
  iteration-003 continuous co-review, decision/verdict-shaped packets were
  rendered while co-reviews were still blocking — see
  `iterations/003/research/stop-ordering-defect.md`.)
- **FR-045a (stop-INTENT classification; dogfood incident + correction
  2026-07-13, maintainer-instructed)**: Specrew MUST classify each host Stop into
  THREE outcomes — `continue`, `intermediate`, or `real` — so an authorized
  workflow is neither stalled nor falsely handed back. The false premise "no
  in-flight work ⇒ real stop" is REJECTED: absence of async work only means the
  event is not an async yield; it does NOT create a reason to hand control to the
  user. `continue` (MARKER-AND-GATE): the CURRENT assistant turn declares the
  marker `<!-- SPECREW-STOP-INTENT: continue -->` AND lifecycle state confirms an
  already-authorized phase with NO unapproved boundary to cross, AND no async is
  pending, AND the message carries no review request / question / completion /
  blocker / hand-back → SUPPRESS the Stop (no packet, no message) and return an
  internal continuation directive; the agent then performs the NEXT authorized
  action, not another status packet. Neither the marker nor the phase alone
  suffices: the marker asserts only that executable work remains; the lifecycle
  state supplies authorization; work is never self-authorized across a pending
  boundary, and `continue` is never inferred merely from a task list on disk. `intermediate`: authorized work remains AND required owned
  ASYNC work is still running/awaiting a result and the agent resumes from it →
  ONE concise, rate-limited progress sentence plus the assistant-only marker
  `<!-- SPECREW-STOP-INTENT: intermediate -->`, with NO packet, NO verdict marker,
  and NEVER launching duplicate work. `real`: the requested work is complete and
  ready to report; a lifecycle boundary; human judgment/authorization/an external
  action is required; execution failed/timed out and cannot continue
  automatically; or the agent genuinely, intentionally transfers control → the
  existing boundary / non-boundary / final-report packet rules, clearly stating
  the actual user action when one is required. PRECEDENCE: (1) a pending lifecycle
  boundary OR a required human/external action (a substantive "What Needs Your
  Review" item counts) OR an unrecoverable failure / intentional hand-back →
  real; (2) terminal requested-work completion → real; (3) required owned async
  work in flight → intermediate; (4) a current-assistant `continue` marker PLUS
  confirmed lifecycle authorization → continue; (5) otherwise → real, WITH an
  explicit reason, never an empty handoff. LOOP GUARD: a `continue` requires
  intervening material progress / changed workflow state between consecutive
  continues; repeated no-progress continues are bounded and, past the bound, the
  hook trips to a REAL stop with a specific internal-routing failure (never an
  infinite loop). "Needs nothing from the user" is NOT sufficient for
  `continue`/`intermediate` (final completion also needs nothing yet is `real`);
  "the session is long / context is thin / a natural checkpoint" is an internal
  concern and NEVER a boundary — compaction handles session length. MARKER: a
  portable FALLBACK for host-native async work with no Specrew registry entry,
  never sole authority. A marker QUOTED IN USER CONTENT is IGNORED (not a signal
  and it does NOT force real). Only an AUTHORITATIVELY-KNOWN-TERMINAL task
  invalidates a stale marker; an UNKNOWN/UNREGISTERED task does not (that is what
  the fallback is for). A pending boundary, a required user action, a hand-back,
  or a known-terminal task override it. NOT a per-host capability matrix. PACKET
  CONSISTENCY: a real stop's sections MUST agree that control transferred. If
  "What Needs Your Review" carries a decision, approval request, unresolved
  tradeoff, or requested confirmation, then it IS a review-required real stop:
  "What I Need From You" MUST state the exact requested response, "What Happens
  Next" MUST say the work is HELD pending it, and the packet MUST NOT say "nothing
  blocking" / "flag this if…" / "I'll proceed"; an informational note is NOT a
  review item and does not belong under that section. A substantive review request
  combined with "nothing required" or automatic continuation FAILS packet
  validation.

### Non-Functional Requirements

- **NFR-001 (honesty)**: Every bypass, pass, or label in this bundle is
  earned by a deterministic check or carries recorded provenance; no
  false-green path is introduced (governs FR-011, FR-015, FR-020, FR-023).
- **NFR-002 (agent-action transparency — human addition)**: Any decision
  or action the agent/machinery takes is legible to the human: what was
  done or decided, why, and what happens next. Legitimate paths announce
  themselves too (the FR-020 bypass, the FR-029 bootstrap commit, FR-028
  healing output, FR-023 label provenance).
- **NFR-003 (loud failure)**: No silent degradation — refuse, warn, or
  mark; never swallow (FR-002 refusal, FR-011 violation record, FR-021
  warning, FR-018 halt).
- **NFR-004 (host neutrality)**: Enforcement teeth live in scripts and
  data seams; host hooks are surfacing-only (FR-006, FR-014); per-host
  variability lives in the catalog (FR-022).
- **NFR-005 (teach, don't trap)**: Every enforcement stop names the
  sanctioned next step (FR-002, FR-018, FR-022).
- **NFR-006 (evidence over presence)**: Claims verify against runtime
  evidence, never file existence (FR-013, FR-015; probe evidence in
  FR-038/FR-039).
- **NFR-007 (paired tests)**: Every honesty invariant ships as a paired
  test — legitimate path works + abuse path fails — with message-content
  assertions riding the pairs (binding acceptance shape from the
  requirements-nfr lens).

### Scope Boundaries

**In scope**: proposals 203 W1–W16 (W4 evaluate-first resolved to cheap
detector; W7 resolved per FR-014), 204 W1–W7, 205 W1–W6, issue #2906,
issues #2909/#2903 closure, Spec-Kit 0.12.9 + Squad 0.11.0 bumps,
v0.40.0-beta2 release + credentials-doc fix.

**Out of scope**: model/quota fallback (Proposal 102 owns it, including
any automatic bounded budget escalation); the board-sync feature (Proposal
101); non-GitHub forge gateway lanes (F-182 pattern later); 204-W6
co-review-evidence CI lane (design note only); cross-host OS sandbox APIs
(per-OS, non-host-neutral); rung-1/other F-197 deferred work.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story maps to one or more functional requirements
  (see Traceability Map).
- **TG-002**: Owner roles are named per FR group heading.
- **TG-003**: Delivery windows are named per FR group heading and in the
  Traceability Map (iterations 001–004 per the agreed slicing).
- **TG-004**: Spec/implementation conflicts reconcile through
  drift-log.md entries with requirement citations; workshop decision
  anchors are the tie-breaker, and changing one requires a recorded human
  decision.

### Traceability Map

| User story | FRs | Iteration |
| --- | --- | --- |
| US1 (boundaries) | FR-001..FR-007 | 002 |
| US2 (containment) | FR-008..FR-013 | 003 |
| US3 (round economy) | FR-014..FR-023 | 002 (FR-020..023), 003 (FR-014..019) |
| US4 (consumer distribution) | FR-024..FR-032 | 004 |
| US5 (self-leak firewall) | FR-033..FR-037, FR-046..FR-047 | 001 (FR-033, FR-034, FR-037), 003 (205-W10 realized by FR-015/T018), 004 (FR-035, FR-036, FR-046, FR-047) |
| US6 (toolchain) | FR-038..FR-039 | 001 |
| Release | FR-040 | 004 |

### Key Entities *(include if feature involves data)*

- **SelfLeakDenyList**: versioned JSON data file (schema_version; entries
  pattern/class/reason/source/added); single truth for repo lint and
  consumer checks.
- **MachineryPathList**: path-granular machinery globs; single truth for
  digest strip and worktree strip.
- **ReviewerHostCatalog row**: per-host harness data + new
  `default_timeout_seconds`; absent column → 600 floor.
- **Release model record**: in `repository-governance.yml`
  (local-only | push-only | pr-flow | beta-stable), recorded at init,
  resolved at closeout.
- **Boundary cursor + verdict history**: `last_authorized_boundary`,
  verdict_history entries (incl. retroactive approvals), AuthCommitHash
  anchors in `start-context.json`.
- **Containment record**: origin-side durable record of an observed
  escape (process, command line, path, timestamp, run id).
- **Tracker claims**: parsed task statuses / capacity lines / test counts
  from `state.md` + `tasks-progress.yml`, compared against the accepted
  review verdict + run records.
- **Run record (extended)**: gains `independence_source`, frozen fire-time
  tree id, currentness (`exact | snapshot-moved`), last-reviewed checkpoint
  identity, and per-finding relevance hints (`likely-still-relevant |
  needs-re-evaluation | relevance-unassessed`) that never grant authority.
- **ReviewCampaign**: target lineage plus human allowance grants, atomic
  reservations/spend, finding lineage, ordered runs, and the selected applicable
  terminal result.
- **ReviewRun**: one unique reviewer invocation against one frozen target, with
  immutable requested/running/terminal/result/validation/classification facts and
  controller-observed runtime evidence.
- **Claim generation**: immutable held/released/abandoned facts that serialize one
  active run per lineage without process ownership or mutable lease handoff.
- **ReviewTarget**: versioned target identity and frozen workspace supplied through
  a target adapter; code review is production, while a non-code fixture proves the
  abstraction boundary.
- **Terminal review result**: controller-published machine envelope for every invoked
  run, including complete, partial, timed-out, and failed outcomes; Markdown is its
  human projection.
- **Finding lineage**: controller-owned cross-run relationship retaining per-run IDs,
  severity, completeness, currentness/relevance, and retrospective resolution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a hookless fixture, a second unapproved boundary advance
  is refused deterministically; the refusal names the skipped boundary and
  both doors; retro-approval advances; decline reverts only after explicit
  confirmation. (US1)
- **SC-002**: From inside a materialized reviewer worktree, git upward
  discovery cannot resolve the origin, and the reviewer bundle contains
  zero origin-absolute paths. (US2)
- **SC-003**: Seeded origin access via a STRONG signal — a reviewer-tree process
  whose cwd or executable resolves under an origin root — marks the run
  `containment-violated` with a bounded, redacted origin-side record. A seeded
  origin access observed only as a command-line ARGUMENT is recorded as a bounded
  diagnostic warning (best-effort; it does NOT by itself discard the review). The
  monitor records its own sampling health, so degraded visibility is surfaced and
  never silent. A full legitimate in-worktree suite run produces zero strong-signal
  violations and zero argv warnings. (US2)
- **SC-004**: The digest strip and worktree strip resolve identical path
  sets from the ONE list; `.github/workflows/**` is reviewable AND
  certified; each exclusion has a passing reviewer-can-still-see-it test.
  (US2)
- **SC-005**: A reconcile-toward-truth tracker edit after an accepted
  review does not demand a fresh live review and announces the bypass; a
  falsify-forward edit stales exactly as today. (US3)
- **SC-006**: Budget resolution resolves catalog defaults per host, the
  600 floor for unknown hosts, and warns at resolution time on explicit
  downgrades — proven by fixture across all four cascade positions. (US3)
- **SC-007 (amended by clarify 2026-07-10)**: When the allowance is
  exhausted after a fix-responsive sequence, the halt renders the
  resolved-prior-finding state and the exact reset command in
  consumer-legible spend-guard language; a message-content test proves the
  halt contains zero Specrew-internal identifiers; a human-typed reset
  resumes review on the next run. (US3)
- **SC-008**: A fresh `specrew init` on a scratch GitHub-provider project
  yields CI referencing only paths that exist in that project, generic
  triggers, an announced bootstrap commit, and an ignored local host
  config — zero broken-by-construction lanes. (US4)
- **SC-009**: `specrew update` on a beta-1-shaped consumer removes the
  retired unmodified templates, WARNs on a modified one, and syncs the
  refocus-scopes rows; issues #2909 and #2903 close on this evidence.
  (US4)
- **SC-010**: Feature-closeout renders local-only guidance on a no-remote
  fixture (no registry, no beta-before-stable) and the full chain on a
  publish-target fixture. (US4)
- **SC-011**: A seeded self-fact in any deploy-surface file reds the repo
  lane; the annotated escape passes with its reason recorded; the
  all-prompt-surfaces fixture render yields zero hits. (US5)
- **SC-012**: `specrew init` completes against Spec-Kit 0.12.9 with probe
  evidence recorded; the integration suites are green on the 0.12.9
  no-extensions fixture (or the added extension carries its dependency
  evidence); all pin surfaces agree. (US6)
- **SC-013**: v0.40.0-beta2 publishes via tag push with the pre-tag
  seven-surface bookkeeping check green. (Release)
- **SC-014**: A fresh consumer E2E on the PUBLISHED beta2 bits reproduces
  none of the four beta-1 friction classes (ceiling chicken-and-egg,
  flat-budget kill, tracker-staled review, closeout self-leak) — the
  stable-promotion gate input, maintainer-assessed.
- **SC-015 (verification-plan end-to-end; RELEASE DEPENDENCY per FR-049)**: On
  a downstream project, a command plan selected by the supplier (FR-049
  precedence) is executed by T018 in order, producing exact-reviewed-digest
  evidence that T019 injects for review; a project with no trustworthy command
  source resolves to `verification-not-configured` with an actionable setup
  prompt — never a silent success and never a Specrew/Pester default. The
  beta2 feature/release MUST NOT close until this end-to-end path has a
  production plan supplier feeding the FR-048 seam. (Release dependency.)
- **SC-016 (workshop-intermediate Stop UX)**: Material architecture-lens turns with either durable feature-level
  intake state or durable exact-iteration design-analysis state, rendered lens content, an explicit matching
  scope marker, and a pending human question stop exactly once without a generic five-heading follow-up. The
  equivalent non-workshop or scope-mismatched turn still demands that packet, and a lifecycle boundary still
  demands its boundary packet. (FR-056)
- **SC-017 (authority/allowance concurrency)**: Barrier-synchronized multi-process
  fixtures prove exactly one winner for the next claim generation, no two active
  claims per lineage, no reservation/spend above human grants, idempotent identical
  recovery, and fail-closed conflicting facts. (FR-057, FR-058)
- **SC-018 (isolated exact target)**: A reviewer runs in an external disposable
  worktree with Specrew disabled and cannot mutate the origin; equal pre/post HEAD
  plus canonical digest permits current classification, while a seeded origin
  movement yields `snapshot-moved`, retains findings/relevance hints, and cannot
  approve the current snapshot. The non-code target fixture passes the same target
  contract. (FR-017, FR-059)
- **SC-019 (five harnesses / three platforms)**: Claude, Codex, Copilot, Cursor, and
  Antigravity each complete one bounded real review with valid identity-bound JSON
  and Markdown; the five runs collectively include Windows, macOS, and Linux live
  evidence, while every adapter and runtime passes the deterministic three-OS
  contract/termination matrix. Missing live evidence keeps the related support claim
  unproven. (FR-060, FR-061, FR-064)
- **SC-020 (timeout, partial evidence, and recovery)**: A seeded process-tree timeout
  proves every descendant dead within the configured grace before a timed-out result
  is published; valid partial findings remain visible but incomplete; a permitted
  rerun uses a new run ID and allowance slot; fault injection at every lifecycle
  publication boundary reconciles without overwrite, duplicate spend, or incomplete
  approval. (FR-061, FR-062)
- **SC-021 (diagnostics, cost, and retrospective traceability)**: A review exposes
  bounded stage/liveness/activity progress and phase timing; preflight failures spend
  no allowance; incremental rerun context remains bounded while full-snapshot access
  is preserved; no durable diagnostic contains credentials/raw environment; and a
  complete plus partial finding pair is deduplicated into retrospective problem
  evidence retaining all required provenance. (FR-062, FR-063)

## Assumptions

- `--script ps` and `--ignore-agent-tools` survive on the Spec-Kit 0.12.9
  CLI and our `extension.yml` hooks schema loads under 0.12
  (research-needed, non-load-bearing; verified by the FR-038 probe before
  the migration lands).
- Squad 0.11.0 is genuinely non-breaking per its release notes; the probe
  - existing suites are sufficient verification (FR-039).
- The tag-push workflow's auto-publish behavior for prereleases is
  current reality (observed for beta1) and remains the release mechanism
  for beta2; the credentials doc is stale and will be fixed (FR-040).
- The T100 child-process registry provides cwd/command-line visibility on all
  five supported CLI harnesses for the FR-011 monitor; strong-signal (cwd/exe-under-origin) access
  fails loud, an argv-under-origin match is a best-effort diagnostic warning, and
  the monitor records its sampling health so weaker visibility (fewer samples, a
  sampling error, or a short-lived descendant between heartbeats) degrades to fewer
  samples and a recorded degraded state — never to silent inactivity.
- Consumer projects obtain spec-kit/squad through Specrew's
  dependency-install path (the I2 single-pin posture depends on it).
- The stable 0.40.0 promotion remains a separate maintainer PASS after
  SC-014; nothing in this feature auto-promotes.

## Governance Alignment *(mandatory)*

- **Spec Steward**: maintainer (Alon) + spec-steward delegated agent;
  workshop decision anchors are binding and changes require a recorded
  human decision.
- **Iteration Facilitator**: Crew coordinator (this session), one
  iteration at a time per the A4 slicing.
- **Capacity Model**: the original four iterations plus the first Iteration 005
  compatibility slice consumed/planned roughly 26 SP under the maintainer-approved
  2026-07-14 variance. The final authorized review proved that slice architecturally
  unsound. The replacement Beta2 architecture is provisionally 30–34 additional SP
  including deterministic proof, five bounded live harness smokes, and expected
  review/rework; it MUST be split into capacity-compliant implementation iterations
  rather than hidden inside the old ~4 SP estimate. Exact task estimates and the
  split require plan approval. Beta3 generic gate/artifact adapters add ~14 SP and
  prioritized lifecycle profiles ~10 SP outside the Beta2 release blocker.
- **Drift Signals**: drift-log.md with requirement citations; the
  governance validator at every boundary commit; the paired-test rule
  (NFR-007) as review enforcement; SelfLeakLintLane red as an
  author-time drift signal.
- **Human Oversight Points**: the nine policy-class boundaries (specify,
  clarify, plan, tasks, before-implement, review-signoff, retro,
  iteration-closeout, feature-closeout) per `.specrew/config.yml`; plus
  the SC-014 stable-promotion PASS which stays outside this feature.
