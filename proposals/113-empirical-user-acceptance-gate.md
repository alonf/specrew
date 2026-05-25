---
proposal: 113
title: Empirical User-Acceptance Gate — Required Human Verification Before review-signoff
status: candidate
phase: phase-2
estimated-sp: 5-8
discussion: 2026-05-25 4-host smoke test surfaced that three of four hosts (Antigravity, Claude, Copilot) reached feature-closeout with agent-asserted "63/63 tests passing" + validator PASS while the user-facing deliverable was non-functional at runtime
depends-on:
  - 112  # Quality-Tier Routing + Runtime Verification Bundle (Pillar 2 = agent-side runtime verification; this proposal adds the human-side counterpart)
composes-with:
  - 055  # Always-In-Flow Discipline (this proposal prevents the upstream cause — closeout without empirical user-acceptance — that 055 then governs the downstream effect of)
  - 067  # Small-Fix Slice Type
  - 030  # Quality Hardening Bundle (Form-vs-Meaning Verification)
  - 073  # Review Evidence Integrity (this proposal extends the evidence surface)
blocks: []
---

# Empirical User-Acceptance Gate — Required Human Verification Before review-signoff

## Why

Specrew's 9-boundary lifecycle (`specify → clarify → plan → tasks → before-implement → implement → review-signoff → retro → iteration-closeout → feature-closeout`) encodes **what the agent does**. None of the boundaries require the human user to physically open / run / use / verify the deliverable and confirm it works before the iteration closes.

The result: closeout is approved on **agent-asserted metrics** ("63 tests pass", "validator clean", "all FRs mapped") that may have nothing to do with whether the user-facing artifact actually works. When tests verify the deterministic core but the runtime integration is broken, the methodology accepts the closeout and the user discovers the gap only later — usually after the methodology layer has already terminated.

### Empirical motivation — 2026-05-25 4-host smoke test

The user ran the same C++ DirectX dice-app prompt against four hosts. Three of four reached feature-closeout with agent-blessed completion claims, then revealed non-functional deliverables when the user finally ran them:

| Host | Closeout claims | Actual deliverable state when user ran it |
|---|---|---|
| **Antigravity** (Gemini Flash) | "24/24 tasks done, 7/7 tests passing, full lifecycle complete" | Dice penetrated the table surface — physics bug shipped to closeout |
| **Claude** (Sonnet) | "34 test cases / 25,507 assertions passing, all FRs mapped, validator clean, deferred only the visual screenshot to user" | App launched with no visible window — `WM_NCCREATE` Win32 bug shipped to closeout |
| **Copilot** (Squad with per-role Haiku 4.5 Reviewer) | "63/63 tests passing, governance validation PASS, all tasks complete, iteration + feature closeout synced" | App rendered white screen, then green background after fix, then required a debug rotating-cube placeholder. Production renderer was never functional |
| **Codex** (gpt-5.5 xhigh) | "iter-001 + iter-002 closed cleanly; deterministic core proven; `--smoke-test` exit 0" | (Halted before feature-closeout via token exhaustion; smoke-test pattern in `dice_app.exe --smoke-test` was the ONLY host-side runtime verification observed) |

Three of four hosts reached agent-blessed completion with a non-functional user-facing artifact. The methodology had no gate that would have caught this. **Codex's `--smoke-test` flag is the agent-side runtime verification pattern Proposal 112 Pillar 2 captures — but even that is the agent reporting to the agent. The human user is never in the verification loop today.**

### Why this is structurally distinct from Pillar 2 of Proposal 112

Proposal 112 Pillar 2 (Runtime Verification Mandate) says **the Reviewer agent must run the deliverable + capture concrete evidence**. That's necessary but not sufficient. The agent can run the app, observe what it thinks is correct behavior, capture a screenshot, and still be wrong about whether the deliverable matches the user's intent. The user is the ground truth.

This proposal adds the **human-in-the-loop step**: before `approved for review-signoff` can be parsed, the verdict text must include explicit acceptance evidence from the human. The methodology layer enforces that closeout-direction motion cannot happen without the user's empirical confirmation OR an explicit, recorded deferral.

The two pillars compose:

- **P-112 Pillar 2 (agent-side runtime verification)**: Reviewer ran the deliverable; captured screenshot, exit code, logs
- **P-113 (this proposal — human-side acceptance)**: User opened/ran/used the deliverable; confirmed expected behavior OR recorded an explicit deferral with rationale + when-to-revisit

Without 113, P-112 Pillar 2 can be satisfied by an agent that thinks it ran the app correctly but didn't. Without P-112 Pillar 2, P-113 forces the user to do all the runtime work the agent could have automated. **Together they form complete runtime-verification discipline.**

## What

### The `Acceptance Evidence` field in `review.md`

Add a required section to the canonical `review.md` template:

```markdown
## Acceptance Evidence

**Verification mode**: [verified | deferred | delegated]

[For `verified`]
**What the user did**: <describe the user-visible action — ran the app, opened the page, hit the API endpoint, used the new flag>
**What the user observed**: <describe the visible result — dice rolled and showed face 4, page rendered the form, API returned 200 OK>
**Result**: matches expected behavior per spec FR-NNN(s): <list the FRs covered>
**Captured by**: <user name>
**Captured at**: <ISO-8601 timestamp>

[For `deferred`]
**Why deferred**: <one of: agent-session has no display; deliverable requires real-world environment not accessible to agent; user time-constrained; other (specify)>
**Re-verify by**: <explicit ISO-8601 date OR explicit milestone (e.g., "before v0.28.0 PSGallery publish")>
**Risk if untested**: <one sentence describing the worst-case outcome of shipping unverified>
**Approving user**: <name>

[For `delegated`]
**Runtime evidence**: <cite the agent-captured artifact — `iterations/NNN/quality/screenshots/foo.png`, `coverage-evidence.md#smoke-test-exit-code`>
**User trust statement**: "I accept the agent-captured runtime evidence as sufficient for this review-signoff." — <user name>
**Captured at**: <ISO-8601 timestamp>
```

### Verdict parser extension

`approved for review-signoff` (and the compound variants) cannot be persisted to `decisions.md` unless `review.md` contains a populated `Acceptance Evidence` section with `Verification mode` set to `verified`, `deferred`, or `delegated`. The parser:

1. Reads the iteration's `review.md`
2. Locates the `## Acceptance Evidence` section
3. Confirms `Verification mode:` is present and non-empty
4. Confirms the mode-specific required fields are populated (timestamps non-empty, user name non-empty, etc.)
5. If any required field is missing → rejects the verdict with a clear diagnostic naming the missing field
6. If all fields populated → accepts the verdict

The user re-attempts the verdict with the missing fields filled, OR explicitly chooses the `deferred` mode (which is also recorded).

**No bypass via prose**. The parser is structured-field; ambiguous user replies cannot satisfy it.

### Default-deny semantics

Currently, the lifecycle's default behavior accepts closeout-direction motion. This proposal flips that to **default-deny without acceptance evidence**. Three explicit choices for the user:

| User intent | Verification mode | What the methodology records |
|---|---|---|
| "I ran it, it works" | `verified` | Concrete acceptance — closeout proceeds with empirical evidence |
| "I haven't run it yet but I want to proceed" | `deferred` | Explicit deferral with re-verify-by date — closeout proceeds, but the deferral surfaces in the next iteration's review.md as an open item until cleared |
| "The agent ran it, I trust the captured evidence" | `delegated` | Composes with P-112 Pillar 2 — the agent's runtime artifact is cited; user delegates verification without running themselves |

All three are explicit, recorded, and surfaced. The methodology no longer accepts "approved for review-signoff" with no acceptance dimension.

### Why three modes (not just "verified" or "deferred")

The smoke test surfaced the empirical edge case `delegated` covers: when the agent session has no display, the user can't physically run a GUI app from inside that session. P-112 Pillar 2 captures agent-side runtime evidence; P-113's `delegated` mode lets the user accept that evidence as sufficient without re-running themselves. This is the pragmatic middle ground that:

- Doesn't force the user to manually run every deliverable (which would be friction for headless / CI / scripted runs)
- Doesn't let the agent self-approve without a human in the loop (which is the current gap)
- Doesn't make `deferred` the only "I'm not running it right now" option (which would inflate deferral counts and lose signal)

The user explicitly opts into trusting the agent's evidence by choosing `delegated`. Auditable, recorded, traceable.

### The deferred-evidence ledger

When `Verification mode: deferred` is chosen, the deferral is recorded in `.specrew/deferred-acceptance-evidence.yml` (new file) at iteration close. Schema:

```yaml
deferred_acceptance_evidence:
  schema_version: 1
  entries:
    - id: defer-feature-NNN-iter-NNN
      iteration: specs/NNN-name/iterations/NNN/
      review_signoff_at: 2026-05-25T11:35:00Z
      re_verify_by: 2026-06-01T00:00:00Z
      risk_if_untested: <one-line summary>
      approving_user: <name>
      cleared: false
      cleared_at: null
      cleared_evidence: null
```

`specrew where` and the Spec Steward's session-start summary surface unresolved deferrals. Each one shows up in subsequent reviews as an open item until `cleared: true` is recorded (via either a follow-up `verified` event or an explicit "deferral expired, accept the risk" event).

## How

| Step | Implementation surface | Effort |
|---|---|---|
| Extend `review.md` template to include the Acceptance Evidence section | `extensions/specrew-speckit/squad-templates/review/review.md` (or wherever the canonical template lives) | 1 SP |
| Update `scaffold-reviewer-artifacts.ps1` to populate the Acceptance Evidence section as required-not-yet-filled | `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` | 1 SP |
| Extend the verdict parser (likely `shared-governance.ps1` or `Invoke-SpecrewBoundaryStateSync`) to enforce the Acceptance Evidence presence check at `review-signoff` boundary | `extensions/specrew-speckit/scripts/shared-governance.ps1` (or wherever the parser lives) | 2 SP |
| Author `.specrew/deferred-acceptance-evidence.yml` schema + helper (read/write/clear) | `scripts/internal/deferred-acceptance.ps1` (new) | 1 SP |
| Surface unresolved deferrals in `specrew where` + Spec Steward charter directive | `scripts/internal/dashboard-renderer.ps1` + `.specrew/team/agents/spec-steward.md` | 1 SP |
| Integration tests | `tests/integration/acceptance-evidence-gate.tests.ps1` (new) | 1 SP |
| Documentation update — coordinator-governance directive + user-guide + getting-started | template files + docs | 1 SP |

**Total**: 7-8 SP. Small-fix-adjacent (per Proposal 067 contract; this proposal's slice is "methodology evolution" not "small fix", but the effort scale is similar).

### Default-deny rollout sequence

To avoid breaking existing in-flight iterations:

1. **v0.27.x patch**: ship the Acceptance Evidence section as RECOMMENDED but not enforced (WARN-level). Reviewer agents populate it when present; validator flags missing instances without blocking.
2. **v0.28.0 minor**: promote to ERROR-level + verdict-parser rejection. Backwards-incompatible at the methodology layer (existing in-flight iterations get warned + auto-deferred at upgrade time).
3. **v0.29.0 minor**: deferred-acceptance-evidence ledger first-class surface in `specrew where` + Spec Steward directive.

Phased rollout lets existing projects migrate without rework.

## Why this is genuinely new (not absorbed by existing proposals)

| Existing proposal | What it covers | Why it doesn't subsume this proposal |
|---|---|---|
| **Proposal 054** (Pre-Merge End-to-End Lifecycle Verification Gate) | CI testing of the methodology itself — does the lifecycle work end-to-end? | This is about METHODOLOGY testing, not user-acceptance of the produced ARTIFACT. Codex green CI ≠ user can use the dice app |
| **Proposal 112 Pillar 2** (Runtime Verification Mandate) | Agent-side runtime verification — Reviewer runs the deliverable, captures screenshot/exit-code | Agent reports to agent. The smoke test demonstrated Claude's agent-side mandate was honored ("I can't run it, no display") and the bug still shipped. Need human in the loop |
| **Proposal 030** (Quality Hardening Bundle — Form-vs-Meaning Verification) | Form-vs-meaning bug class: tests pass with correct shape but wrong behavior | Sibling concept but addresses a different layer. 030 is about the test ↔ implementation gap. 113 is about the implementation ↔ user-experience gap. Both together catch more bugs |
| **Proposal 073** (Review Evidence Integrity) | Reviewer must commit before scaffolding evidence | Composes — this proposal EXTENDS the evidence surface to include explicit user-acceptance. 073's commit-evidence gate stays; 113's acceptance-evidence gate adds |
| **Proposal 055** (Always-In-Flow Discipline) | Bug fixes / refactors / hot fixes need a sanctioned flow | 055 governs the DOWNSTREAM of closeout. 113 prevents the UPSTREAM cause (closeout reached without acceptance) that creates so many post-closeout fixes |

The novel piece is the **human-in-the-loop step**. Specrew today has 9 boundaries that encode agent action; this proposal adds the missing boundary semantics for human verification of the produced artifact.

## Open Questions

1. **What counts as a "deliverable" that requires user-acceptance?**: should this fire on every iteration's review-signoff, or only at feature-closeout? Recommendation: every review-signoff for an iteration that produced user-visible artifacts (GUI, API endpoint, CLI command, documentation file, etc.); skipped for iterations that produced only internal refactors. The spec's `requires_user_acceptance: true/false` field declared at planning time decides.
2. **What about headless CI runs that have no human user?**: the `delegated` mode covers this — the agent's runtime evidence is captured + a user-trust statement is required at PR-open time. The user is still in the loop, just asynchronously.
3. **What about iterations whose deliverable is "tests pass"?**: testing-only iterations (test infrastructure, coverage improvements) get `Verification mode: verified` by the implementer themselves running `ctest` / `pytest` / etc. The fact of test execution IS the acceptance evidence.
4. **Should `deferred` have a max age?**: maybe. If a deferred acceptance ages beyond N days without being cleared, the methodology layer auto-fails subsequent iterations of the same feature with a "stale deferral" diagnostic. N starts at 14 days; tunable via `.specrew/config.yml`. Possibly skip for v1 to avoid scope creep.
5. **Composition with Proposal 105 (Host-Native Hook Deployment)**: on hosts with PreToolUse hooks (Claude / Antigravity per P-105), the verdict parser's structured-field check could be elevated from "cooperative methodology rule" to "host-runtime hook enforcement". Would close the cooperative-vs-runtime gap for this specific gate. Phase 3 follow-up after P-105 ships.

## Empirical Motivation Captured

The 2026-05-25 4-host smoke test on the C++ DirectX dice-app prompt produced this proposal by sequential surface failure across three hosts:

1. **Antigravity v1**: shipped at feature-closeout with claimed 24/24 tasks + 7/7 tests; user ran app + dice penetrated table; agent then made 3 post-closeout hotfix commits OUTSIDE the lifecycle (`67521bd`, `91541ab`, `095c0a8`); 1 of 3 fixes got the wrong regression test.
2. **Claude**: shipped at feature-closeout with claimed 34 cases / 25,507 assertions + visual evidence deferred to user; user ran app + saw NO window (WM_NCCREATE Win32 init bug); fix added as post-feature-closeout amendment without regression test.
3. **Copilot**: shipped at feature-closeout with claimed 63/63 tests + per-role Squad routing + governance validation PASS; user ran app + saw WHITE SCREEN; agent modified `win_main.cpp` + `camera_render_pipeline.cpp` outside the lifecycle; second user report "GREEN BACKGROUND ONLY"; agent added rotating-cube DEBUG PLACEHOLDER also outside the lifecycle.

User exact phrasing (2026-05-25, after observing the Copilot session):

> *"I see two problems: 1. It works and change code out of any iteration with no spec, or documentation. 2. I as a user did not understand the status of the implementation."*

Problem 2 is exactly this proposal's scope. Problem 1 is Proposal 055's scope (post-closeout sanctioned flow). The two compose.

## Not in Scope

- **Replacing agent-side runtime verification (P-112 Pillar 2)**: this proposal ADDS the human side; P-112 Pillar 2 stays as the agent-side requirement.
- **Forcing user verification on every iteration regardless of scope**: this proposal applies when iterations produce user-visible artifacts. Refactor-only / test-only / docs-only iterations have lighter acceptance requirements (Implementer self-verification + spec author sign-off).
- **Hook-level mechanical enforcement on every host**: cooperative methodology rule first; mechanical enforcement on hook-capable hosts (P-105) is a Phase 3 follow-up.
- **Automated "is the deliverable working?" testing**: out of scope. The whole point of this proposal is that automated tests miss the integration bugs the user-acceptance gate catches. If automated tests COULD catch them, we wouldn't need this proposal.
