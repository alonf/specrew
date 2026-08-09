# Beta3 Carry Ledger

**Maintained by**: reviewer session (observer), at the maintainer's direction
**Status**: holding ledger — fold into the official beta3 handoff prompt after T067 concludes
**Last updated**: 2026-08-09, mid-T067 (planning review loop; run-7 in flight)
**Context**: v0.40.0-beta2 published (tag at 67a5d7bc, Gallery live 2026-08-09). T067 dogfood
running on published bits at `C:\Temp\t067-linkcheck` (blind consumer session — do not reference
this ledger there).

---

## A. T067 findings — published bits, all new (not in the release's twelve known issues)

| ID | Finding | Fix shape | Est. |
|----|---------|-----------|------|
| T067-F1 | OneDrive cloud-placeholder reparse points refused by the review engine's integrity check. The default corporate `Install-Module -Scope CurrentUser` path (`Documents\PowerShell\Modules` under OneDrive Known Folder Move) is unusable for campaigns. Agent workaround: byte-identical copy to a local dir, hashes verified. | Discriminate reparse tags (cloud placeholder vs junction/symlink), hydrate-and-verify, consumer-readable preflight message; document AllUsers-scope alternative | 1.5–2 SP |
| T067-F2 | Fresh consumer projects have no verification plan; the campaign preflight cannot proceed and cannot bootstrap one — the agent reverse-engineered the schema by hand. | `specrew init` scaffolds a starter verification-plan.json (governance validator + `dotnet build/test` templates) | 1 SP |
| T067-F3 | Verification child processes run with an empty environment by engine design — `git` not found; cause sealed behind human-authorized diagnostics; `env_refs` sanctioned but undiscoverable. | Default env allowlist in the scaffolded plan + unsealed error hint naming `env_refs` | 0.5–1 SP |
| T067-F4 | Campaign round allowance consumed by infrastructure failures (runs 1–3 never invoked a reviewer, spent nothing provider-side, yet exhausted the allowance). Consumer pays rounds for engine defects; replenishment needs human remediation. | Only reviewer-invoked rounds count against the allowance; sharpens the rounds-bounding item in cluster D | 1 SP |
| T067-F5 | Campaign stop-gate reads only terminal results — an authorized in-flight run is invisible. Two instances: (a) stale run-4 timeout block re-fired while run-6 executed, demanding an already-granted remediation; (b) `review-stale` block fired while run-7 (the exact requested review) was already running. | Part of the Stop-surface family (B) | — |
| T067-F6 | Engine vocabulary leaks into consumer-facing surfaces: "claim-ordered result", "digest", "reconciled the reservation slot", "terminalizes", "review-stale", "request-current-digest-review". A consumer developer cannot decode their own gate status. | Consumer-language pass over all campaign stop messages and packet prose (the #3091 discipline applied to runtime surfaces) | 1–1.5 SP |

### T067 observations (smaller)

| ID | Observation | Est. |
|----|-------------|------|
| obs-1 | Scaffold returns `BRANCH_NAME` but creates no branch — seeded false agent prose ("scaffolded on branch..."). Rename field (`FEATURE_REF`) or create the branch. Agent later created the branch itself at the specify boundary. | 0.3 SP |
| obs-2 | Orientation banner shows `0.40.0`, dropping the prerelease tag — beta consumers can't tell they're on the beta channel. | 0.2 SP |
| obs-3 | Governance validator emits `handoff-block-missing` WARNs in a fully clean flow (all verdicts independently verified hook-captured). Trains consumers to ignore WARNs. | 0.5 SP |
| obs-4 | Quality-profile resolver auto-marks concurrency-correctness and retry semantics not-applicable on weak signals for a concurrency-bearing CLI; agent had to override by hand with disclosure. | 0.5 SP |
| obs-5 | Governance records carrying self-praise ("the codex co-review earned its keep here" in a drift-log). Instruction fix: records state facts and cite evidence; never evaluate Specrew's own components. | 0.1 SP |
| obs-8 | Defer-record canonicity friction: the governance validator's no-gap policy demands a machine-parseable defer block (Type/Affected Iteration/Approving Human) AND the ledger reference in exact backslash form — the T067 agent had to read validator source to comply, and the failed preflight consumed a run number (another F4 instance: infra failure charged to the campaign). A consumer meets "verification-command-failed" with no path to the canonical format. Fix: validator error names the required format; scaffolded defer template. | 0.5 SP |

| T067-F7 | Default 300 s review window mis-calibrated for codex-class reviewers: run-4 timed out silently at 300 s; runs 6/7 completed with real findings inside a 900 s window. Heartbeats prove liveness but don't extend the window; the engine cannot distinguish silent work from a hang. | Per-reviewer-host default windows (codex ≥ 900 s for planning-scale digests); heartbeat-aware soft extension or at minimum a consumer-readable timeout message naming the window flag | 0.5–1 SP |

| obs-6 | Grant-scope vocabulary gap: the human granted one codex retry ("Reset allowance, retry codex with a 900 second timeout"); the agent continued the grant across the fix-verify cycle under self-minted references, disclosed each time — ultimately stretched through **round 7** without the human ever returning to the decision. The engine has no vocabulary distinguishing single-run from until-terminal grants. Joins cluster D (grant kinds: single-run / until-terminal / until-new-blocking). | folds into D |

| **T067-F8** | **HEADLINE — the campaign has review quality but no review economics.** Pre-implementation loop ran 7 rounds, 28+ findings fixed, hours of wall-clock and real tokens, before a line of code existed — and was still going when the human intervened. Three gaps compound: (a) any fix, however minor, stales the whole digest and costs a full re-review round; (b) no severity floor and no surfaced triage off-ramp — the fix-everything default is unbounded because "accept as recorded residuals and proceed" is never offered, though human-approved gaps ARE expressible (the skip option proves it); (c) the stretched grant (obs-6) removed per-round human checkpoints. Diminishing returns were real and visible: rounds 1–2 found essential security flaws (SSRF chain — high value); round 6 was taxonomy gold-plating on a planning doc. A real consumer's rational response is to disable the campaign. Fix shape: severity-floor triage presented to the human after each round; residual-acceptance as a first-class authorized state; digest-staling granularity (doc-only deltas don't void a review); hard default round ceiling per digest with human continuation. Gives clusters D's rounds-bounding item its consumer evidence. Sharpened live: (d) **ask-then-spend** — the agent eventually surfaced a convergence-policy prompt with options, yet launched round 7 in the same message, spending before the human could answer; (e) **the console was held** — continuous stop-block processing and background-run notifications kept the session mid-turn, so the human reported "I still can't paste anything": the intervention point was unavailable exactly while the spend continued. A spend-continuation question must PAUSE the loop until answered. **Empirical basis (8 rounds observed)**: finding rate FLAT at 7→5→6→7→3→7→5 — two mechanisms prevent convergence: the spec is a moving target that grows with every fix round (new text = new review surface), and fixes inject defects (round 7 caught round 6's own CRLF-blind edit). Zero-findings is NOT a reachable terminal for spec reviews; termination must be policy-based. **Settled design (maintainer + reviewer, 2026-08-09)**: (1) after EVERY round the loop PAUSES — spend stops, console frees — and renders one decision surface: findings by severity, trajectory, cumulative cost (rounds/minutes/tokens), and a recommendation with numbered options (fix-and-continue / proceed-with-residuals / stop); (2) severity gating feeds the RECOMMENDATION, not an autopilot — and needs calibration (wrong-or-unsafe-code vs better-document), since codex labels spec-tightening "major"; (3) a fixed round count is a default checkpoint cadence, never a ceiling (rounds 1/2/5 found real blockers a fixed-2 would skip; 6-7 were polish); (4) delta-scoped re-review so continuation is cheap — minor-only fix rounds must not void the whole digest; (5) minors never gate — auto-carry as recorded follow-ups. **Instrument panel (maintainer-requested measurement design)**: the pause surface renders five metrics, all computable from existing data — (i) severity-weighted yield per round (blocking 8 / major 3 / minor 1, from result.json) and its trajectory; (ii) marginal yield = score / round cost (duration_ms already recorded; tokens where the host reports them); (iii) self-churn ratio = findings targeting text introduced by the previous fix round (finding locations ∩ last fix commit diff) — high self-churn means the original artifact converged; (iv) new-class ratio via lineage clustering (the third-layer-same-class stop rule as metric); (v) consequence class — REQUIRES the one schema/prompt addition: reviewer tags each finding runtime-defect vs document-quality (severity alone is gamed: codex labels spec-tightening "major"). Headline = recommendation + numbered options, thresholds sourced from the QUALITY PROFILE (internal utility vs published product get different defaults — gives the resolver a second job). The panel informs; the human decides — an autopilot recommendation rebuilds the unbounded loop. +~1.5 SP on top of F8's base. | 2–3 SP |

### T067 pending / watch items (resolve before the handoff is cut)

- Codex file-delivery quirk (findings via file, empty stdout → possible "partial" mislabel and
  wasteful retry) — watch at review-signoff on the real code review.
- Whether anything downstream expects the feature git branch to exist (obs-1 watch).
- Planning-review loop convergence: run-6 seven findings (design-level) → run-7 five (all
  fix-reviews, healthy shape) → run-8 in flight. If run-8 returns NEW findings rather than
  clean/residual, stop looping and decide by hand (trajectory rule).

---

## B. Stop-surface state-model family — one design, three instances (~3–4 SP)

The stop-enforcement layer evaluates snapshots without modeling in-progress or foreign work:

1. **Author-attributed turn deltas** — reviewer/observer sessions blocked for *other* sessions'
   commits landing in their delta window. Evidence: this repo's
   `.specrew/runtime/conformance-journal.jsonl`, entries 2026-08-08/09 with `material: true`,
   `dx_foreign_owner_suppressed: false` on zero-write turns. The runtime already records owner
   identity — partition the delta by writer, suppress when all-foreign.
2. **Decision-yield stop composition** (folds into proposal 208) — packet and decision surface
   must be ONE message; hook firings at decision stops are instruction defects to drive to zero.
   Evidence: T067 design-analysis stop 2026-08-09 (ask → hook bounce → packet carrying the
   resolver-override disclosures the human needed before deciding). Maintainer ruling: applies
   to every decision-yield stop.
3. **T067-F5** — in-flight-run blindness and stale directives (above).

---

## C. Design owners from the certify rounds — must-ship, named in the release claim

- **Evidence-pipeline choke point** (~4–6 SP): authority advances only on positively verified
  evidence; single authorization write path. Four patch layers (provider blockKind → cap path →
  capture ordering → unverifiable-authorizes) proved per-site guards fail. Consolidates the
  capture-on-unverifiable named limitation.
- **Path-identity containment** (~3–5 SP): every containment check routes through the
  volume-derived path-identity primitive. Four layers likewise (prefix → case → link →
  platform-default case-fold). Consolidates the containment-platform-case named limitation.

## D. Crossing-vocabulary / disposition cluster (~8–12 SP — SPIKE FIRST; outcome swings everything)

- Retroactive closeout (-020), successor evidence (-021), fresh-finding deferrals (-034)
- Attempted-to-cap terminal verdict (-044) — the standing waived Lint red on main
- Rounds bounding (-I010-001) — now sharpened by T067-F4 (infra failures must not consume rounds)
- Waiver-expressible-to-CI; campaign-terminated-by-rule-inexpressible
- B3-003 decision-pending crossing state (design-analysis verdicts agent-transcribed; both fix
  shapes in the drift log)
- Second-feature arrival edge (no crossing into the next feature's specify after feature-closeout)

## E. Link/reparse hardening cluster (~3–4 SP)

- Release-claim limitations 1 and 3 (checkout-borne link vectors, no link fixtures shipped)
- Quality-profile link escape (routed at certify round 3)
- **T067-F1 joins as the most consumer-common instance** (OneDrive placeholders)
- Work: link fixtures across the three CI volumes; reparse-tag-aware checks everywhere

## F. Residuals and small tail (~6–8 SP)

- Bootstrap-mints-authorization (certify f1) + mint-guard design spike (FR-066 residual)
- Write-Utf8FileAtomic silently succeeds onto a directory destination (certify f5)
- B3-001 dashboard leak writer (scaffold-iteration-artifacts.ps1:737-744 +
  run-mechanical-checks.ps1:516 coupling)
- Generator single-sourcing (nine-skill parity)
- AST-based rule enforcement replacing grep (release-claim limitation 5, internal)
- Carried F3/F4/F5/F8/F14 from the beta2 window
- Ceremony-bypassed reviewer writer
- Status-based navigator design note
- Method-rules-for-shipped-guidance documentation

## G. Method rules and process records to carry into the handoff

- **Proof lines are transcribed from measurements, never drafted ahead of them** (release-window
  lesson: the pre-measurement merge proof line was wrong; corrected durably in PR #3318 comment
  and the release tag-basis note; alignment PR approved for the in-repo claim).
- Records state facts, never self-praise (obs-5).
- RED fixtures must exercise the SHIPPED path including event entry points (slice-4 lesson:
  capture-path RED needed marker-first + prompt-submit).
- Evidence-integrity annotation: frozen repo `C:\Temp\testbeta3-842854746` was touched
  2026-08-09 00:00:27–00:48 by accidentally resumed session 659f661d (beta3-findings.md,
  design-analysis.md, two runtime journals). Canonical record unaffected (lives in the 198
  drift-log); exact delta recoverable from that session's transcript. Action: archive both
  frozen evidence dirs as read-only zips — policy-freeze must become mechanical-freeze.

**F8 final tally**: TWENTY runs, FIFTEEN fix rounds, 79 findings resolved on the planning
digest before a line of code existed. Round series: 7,5,6,7,3,7,5,3,5,2,7,5,5,5,8 —
oscillating, never converging, exactly as predicted. Policy (b) (blocking/major-free exit
test) did NOT terminate — codex labels document-tightening "major". The loop ended only
when the AGENT itself paused and returned the cost decision to the human ("continuing is
a genuine cost decision that belongs to you, not something I should keep extending in
your name") — the instruction layer eventually compensating for the missing engine
economics, at fifteen rounds' cost. Genuine value ledger: ~6 blocking security holes
(SSRF chain, config re-enable, UNC/SMB reach from markdown, contributor-controlled
oracle, address-classification contradiction, symlink scan escapes) — front-loaded;
the long tail was document-quality.

**obs-7 — unratified post-boundary amendments**: review-driven spec/task amendments from
rounds 6–15 landed AFTER the last human boundary verdict (before-implement ratified only
through round 5). The artifacts the implementation will build from are "dramatically
harder than what the human approved at the plan boundary" (the agent's own words), with
no boundary verdict covering the delta. Review-signoff must sweep and ratify accumulated
amendments explicitly; beta3: amendment-accumulation should be surfaced at the next
boundary as a first-class diff-to-approve.

**F8 completion — the pattern is reviewer-inherent, not artifact-specific**: after option
(c) ended the planning loop, the CODE review at review-signoff restarted the identical
unbounded pattern — rounds of 5, 6, 4, 5 findings (flat), per-round self-minted
authorization refs, no pause, no human checkpoint (the option-(c) ruling carried no
bounds into the code phase; loop-until-clean is the engine default everywhere). Code
findings again real and front-loaded (blocking IPv6 policy bypass, no-follow reparse
detection, NXDOMAIN honesty, probe canonicalization). Conclusion for the design: the
convergence policy and instrument panel must govern EVERY campaign loop, not per-phase —
codex yields ~5 findings/round against any artifact type indefinitely.

## Positive validations to cite in the handoff (what beta2 got RIGHT on published bits)

- **The implement phase, end-to-end clean on published bits**: nine tasks executed with a
  boundary commit each, 212 tests at warnings-as-errors, live-external dogfood exit 0,
  published standalone executable verified, review.md authored and committed so the
  review-signoff crossing rebinds per the evidence gate's demand, mechanical checks run.
  Zero human friction through the whole phase.
- **The FR-068 stage-evidence gate, live and flawless**: the before-implement→review-signoff
  crossing minted bound to a tree lacking review.md, and the stop surface REFUSED to offer
  approval options or a verdict marker — plain report, missing artifact named, recovery
  stated ("produce, COMMIT, stop again so the crossing rebinds"). The exact class the -012
  arc and certify f2/f4 hardened, demonstrated in a consumer flow on published bits.
- **Sync ratchet**: a duplicate boundary-sync invocation was cleanly refused as a re-run
  guard — no state damage, honestly disclosed.
- **The identity-bound disposition route, end to end**: the bounded verification run
  (run-review-signoff-10) reviewed the frozen tree, re-raised ZERO of 35 prior findings
  (R-1..R-5 reviewer-confirmed, R-6 closed), its 3 new findings were accepted via the
  pre-authorized `override-block --ack-reason` disposition, and the signoff gate opened
  through `boundary-human-disposition` / `complete-current-findings-human-accepted`. The
  residual-acceptance vocabulary EXISTS and WORKS — it just needs the composed landing
  path beta3's F8 fast core specifies.

**F5 final sharpening — the treadmill closes on itself**: the boundary(review-signoff)
commit that RECORDS the gate's allow decision immediately re-staled the campaign stop
surface, which demanded yet another current-digest review — currency is unachievable by
construction, since satisfying the gate moves the digest. Worse: TWO governors disagreed
(signoff evidence gate: allow; generic campaign stop-block: blocked) and the AGENT had to
adjudicate between them, correctly citing signoff-gate/latest.json as authoritative — a
consumer cannot make that call. Beta3 F5 scope: the campaign stop surface must consult
the signoff-gate decision, and governance-artifact-only deltas must not stale a digest.

- Boundary machinery flawless across five human decisions: specify/clarify/plan/tasks
  hook-captured verbatim; design-analysis transcribed verbatim with disclosure (B3-003 path).
- First-crossing translation (`from_boundary: null`) and intake display vocabulary working live.
- Navigator quiet window held through specify→tasks; campaign went LIVE exactly at
  before-implement.
- Campaign block-kind vocabulary (f3 fix) steering clean formal escalations; no marker invention
  anywhere.
- Hardening gate scaffolds `blocked` and flips only when genuinely filled (f7 fix).
- Pre-named deferral governance applied exactly as designed when review grew T007's scope.
- The codex planning review produced a genuine blocking security catch (SSRF destination policy)
  pre-code — the campaign's value proposition demonstrated.

---

## Sizing and the beta3/beta4 split (maintainer ruling, 2026-08-09)

**Criterion**: beta3 ships what makes a consumer's first feature survivable (the endless
review loop and the worst UX); beta4 ships the deep redesigns.

**Beta3 — stabilization, ONE iteration (~10–12 SP)**: F8 fast core (pause after every
round: findings-by-severity + cumulative cost + numbered options; continuation always
human; no self-minted grant refs; minors never gate; hard default round budget — AND a
gate-compatible landing path: the pause's "stop here" option composes one final
frozen-tree verification + identity-bound acceptance as a single action, because
T067's endgame proved a bare stop ruling wedges against the signoff gate:
accepted-residuals-on-an-unreviewed-tree is INEXPRESSIBLE — the waiver-inexpressible
class caught live; the session correctly refused to bypass and surfaced the sanctioned
paths), F5 fast
fix (no stop-block while an authorized run is in flight), F1 OneDrive (tag-discriminating
integrity check or preflight message + documented workaround), F2+F3 (scaffolded
verification plan with env_refs default + unsealed hint), F4 (infra failures don't
consume rounds), **F6 expanded to the consumer-language layer (maintainer ruling
2026-08-10)**: every human-visible sentence is about the user's PROJECT and the user's
DECISION — internal vocabulary (crossing, mint, marker, digest, boundary sync, verdict
capture, controller truth, ratchet, claim-ordered, terminalize) never appears in
consumer prose, only in records and diagnostics; acceptance test: a developer who has
never read Specrew docs understands every sentence shown to them. Evidence: the T067
signoff-stop prose required six pieces of internal machinery knowledge in two sentences
("the crossing is minted... the packet's marker is the one the verdict capture binds
to") where "linkcheck is ready for your final approval — reply approved for
review-signoff" carries the same content. Scope: packet templates, skill instructions,
stop messages, orientation banner (~1.5–2 SP), decision-yield
one-message composition (208 rule, instruction layer), F7 review-window defaults,
obs-2 banner tag.

**Beta4 — deep work (~24–32 SP, two iterations)**: crossing-vocabulary/disposition
cluster (grant-scope kinds, B3-003, second-feature edge, waiver-to-CI, -044, rounds
bounding formalization), evidence-pipeline choke point, path-identity containment, full
link/reparse hardening, full instrument panel (consequence tags, self-churn,
delta-scoped re-review), author-attributed turn deltas, amendment-diff-at-boundary
(obs-7), small-fix tail (atomic writer, B3-001 leak, generator single-sourcing, AST
enforcement, carried F3/F4/F5/F8/F14, ceremony-bypassed writer, mint guard/f1,
obs-1/3/4).

**Claim-alignment note**: the beta2 release claim names the two design owners as "beta3
vehicles" — this split moves them to beta4. Beta3's release notes must say so explicitly
to keep the claim chain unbroken. All deferred items are named limitations on narrow
edges; nothing degrades by waiting.
