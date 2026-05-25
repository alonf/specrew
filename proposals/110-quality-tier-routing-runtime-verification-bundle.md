---
proposal: 110
title: Quality-Tier Routing + Runtime Verification + Domain Specialists + Bug-Test-First + Canonical Verdict Menu + Token Budget Awareness
status: candidate
phase: phase-2
estimated-sp: 35-50
discussion: 2026-05-25 4-host smoke test (Antigravity / Codex / Claude / Copilot) on C++ DirectX dice-app prompt — identified 6 systemic methodology gaps with empirical evidence from each host
depends-on:
  - 040  # Token Economy as Governance Driver (Pillar 6 extends this)
  - 055  # Post-Ship Bug-Fix Lifecycle (Pillar 4 composes with this)
  - 067  # Small-Fix Slice Type (Pillar 4's bug-fix slice rides on this)
  - 068  # Cost-Aware Model Routing (Pillar 1 is the empirical refinement)
composes-with:
  - 030  # Quality Hardening Bundle (Pillar 2 + Pillar 3 strengthen quality lenses)
  - 057  # Roadmap Spine (no direct overlap; co-existent)
  - 105  # Host-Native Hook Deployment (Pillar 1 + Pillar 5 strengthen on hook-enforced hosts)
blocks: []
---

# Quality-Tier Routing + Runtime Verification + Domain Specialists + Bug-Test-First + Canonical Verdict Menu + Token Budget Awareness

## Why

Specrew today encodes **process discipline** (gates, artifacts, audit trails) and **artifact discipline** (FR-traceability, drift logs, retros). It does NOT yet encode **engineering discipline** — the practical habits a senior engineer applies that the methodology layer assumes will emerge but doesn't enforce.

The 2026-05-25 cross-host smoke test ran the same C++ DirectX dice-app prompt against all 4 supported hosts (Antigravity, Codex, Claude, Copilot). The test produced empirical evidence of 6 distinct systemic gaps that the methodology layer must close — because no single host today encodes more than 2 of them, and even the gold-standard hosts (Claude, Copilot) each shipped a real bug because of one of the missing pillars.

Each pillar in this proposal has a concrete empirical anchor from the smoke test — both a positive case (a host that did it right) and a negative case (a host where the gap caused real failure).

## What — 6 pillars

### Pillar 1: Quality-Tier Routing (per-role model dispatch)

**Rule**: Implementer/scaffolder roles route to cost-tier `cheap-fast` (Haiku, Gemini Flash, GPT-4o-mini). Reviewer/auditor/hardening roles route to cost-tier `strong-strict` (Sonnet, Opus, GPT-5). Spec Steward + Retro Facilitator default to `balanced` (Sonnet-class). Configured per project at plan-time, overridable per task in `iteration-config.yml`.

**Empirical evidence**:

- **Positive**: Copilot session with full Squad routing dispatched Reviewer to **Claude Haiku 4.5** for iteration-closeout sync, separate from the launching Copilot CLI model. Per-role routing engaged automatically. 63 tests passing at feature-closeout.
- **Negative**: Antigravity v1 (Gemini Flash) collapsed all 5 roles to a single model. Skipped plan-approval gate. Shipped dice-penetration bug at runtime. Higher-tier "QA pass" surfaced no model session marker — 3 fixes landed as direct hotfixes outside the lifecycle, contradicting the original "zero rework" retro.

**Why model strength matters at the per-role level**: cooperative-gate enforcement (Proposal 066) is a methodology layer the model must *choose* to honor. Weaker models chase delivery; stronger models honor boundaries. Routing reviewer/hardening tasks to strong models gives the methodology more cooperative-gate compliance per dollar.

### Pillar 2: Runtime Verification Mandate

**Rule**: When the feature has a runtime component (GUI, daemon, network service, etc.), the Reviewer MUST run the deliverable and capture concrete evidence. "Reading code carefully" is not sufficient. The deliverable's executable MUST implement at least one non-visual smoke-test verification path (e.g., `--smoke-test` exit code 0/non-zero, process-stays-alive ≥ 2s, FindWindow returns the window class). Visual evidence may be deferred to the human only when no agent-accessible runtime check exists.

**Empirical evidence**:

- **Positive**: Codex iter-002 (DirectX render shell) built `DiceApp.exe --smoke-test` flag UNPROMPTED. The Reviewer ran `DiceApp.exe --smoke-test` and verified exit code 0 before signing off. Catches Win32+D3D integration bugs that headless unit tests cannot.
- **Negative**: Claude built a clean app — `WinMain.cpp` with explicit MessageBox-on-init-failure, ShowWindow with SW_SHOW, 34 cases / 25,507 assertions including no-penetration property test. Deferred visual verification to the user honestly ("non-interactive agent session, can't open a window"). User ran it on desktop → no window appeared. Diagnosed as `WM_NCCREATE` window-proc bug. Methodology accepted the deferral too easily — a `--smoke-test` flag or process-stays-alive check would have caught the regression without a display.

**The pattern**: the Reviewer should never accept "deferred visual verification" without first exhausting every non-visual runtime check. The methodology layer must enforce that exhaustion.

### Pillar 3: Domain-Specialist Crew Members

**Rule**: When the spec touches a domain with known LLM blind spots — game physics, concurrency, cryptography, distributed systems, ML, embedded, networking, security/auth, real-time systems — the Spec Steward MUST propose adding a domain-specialist Crew member at plan-boundary. The specialist's charter is to enumerate the field's typical traps as property-based test requirements BEFORE implementation begins. Specialist composition is part of the plan artifact; reviewer signs off on specialist roster before T001 starts.

**Empirical evidence**:

- **Positive**: Claude's plan included property-based tests for "containment at max speed" and "no-penetration" — exactly the domain-specialist tests a Game Physics expert would flag at plan time. Caught the dice-through-surface bug class at test-first time. Did NOT ship the bug Antigravity shipped.
- **Negative**: Antigravity, Codex (iter-001), and Copilot (terminal state) all lacked the no-penetration property-based test. Antigravity shipped the bug; Codex hadn't reached physics in iter-001; Copilot hadn't reached physics before token exhaustion. 3 of 4 hosts missed the same test class because no domain specialist was in their plan.

**The pattern**: agents don't enumerate domain-typical bugs from raw prompts — but a specialist Crew member at plan time CAN.

### Pillar 4: Bug-Report → Regression-Test FIRST

**Rule**: When the user reports a bug, the Implementer MUST write a failing test that reproduces the bug BEFORE writing the fix. The test stays in the test suite as a permanent regression guard. The fix's PR/commit MUST include the test in the same diff. The methodology layer rejects fix-without-test commits. Composes with Proposal 055 (post-ship bug-fix lifecycle) and Proposal 067 (small-fix slice type) as the WHAT-MUST-BE-IN-A-BUG-FIX specification.

**Empirical evidence**:

- **Negative case 1**: Antigravity post-closeout hotfixes — 3 bug-fix commits landed as direct hotfixes outside the lifecycle. ONLY 1 of 3 fixes got a regression test, and it was the WRONG one (face-snap orientation, not dice-penetration). The penetration bug (the most user-visible) still has no test guarding against re-regression.
- **Negative case 2**: Claude's WM_NCCREATE window-proc fix landed with screenshot evidence + deferral resolved + commit. No mention in handoff of a new smoke test that launches `dice_app.exe` and polls FindWindow. If a future change re-breaks `WM_NCCREATE`, no automated check catches it — only the next user trying to run the app.

**The pattern**: even gold-standard hosts ship bug-fixes without regression tests. The methodology layer must mandate it explicitly.

**Required bug-fix slice artifact set** (extending Proposal 067 small-fix slice):

```text
specs/<feature>/iterations/<NNN>/bug-fix/<bug-id>/
├── repro.md          # how to reproduce manually (user's exact report quoted)
├── test.<lang>       # the failing test (MUST fail before fix)
├── fix-commit.md     # the fix + before/after test outputs
└── verification.md   # test now passes; smoke verified
```

Validator rule (new): commits matching `(fix|bug|regression)` keywords in subject MUST have a co-committed test file in the same iteration's bug-fix directory.

### Pillar 5: Canonical Verdict Menu Surfacing

**Rule**: When the agent emits a boundary handoff, the verdict-action surfacing MUST present the exact parser-accepted canonical verdict shapes as numbered/keyed options. Labels like "Approve" / "Decline" / "Other" are acceptable for display but MUST round-trip losslessly to the canonical shape (`approved for <boundary>`, `rejected for <boundary>`, `parked`) when recorded in `decisions.md` / `state.md` / scribe logs.

**Empirical evidence**:

- **Positive**: Copilot's menu surfaced the canonical shapes verbatim — `approved for before-implement`, `approved for before-implement-boundary entry`, `rejected for before-implement`, `parked`. The user picks one and the parser accepts it bit-identically. No translation drift.
- **Mid**: Codex's menu used Approve/Decline/Other labels. Friendlier-looking but requires translation back to canonical shapes when written to `decisions.md`. A drift surface where labels could come unstuck from the parser-accepted forms.
- **Negative**: Antigravity v1 didn't surface a verdict menu at all — chained past gates without asking.

**Why this matters**: the parser is the authority. Surfacing the parser's accepted shapes verbatim eliminates the translation layer where drift creeps in.

### Pillar 6: Token Budget Awareness (NEW — empirically motivated)

**Rule**: At plan-boundary, the methodology layer projects per-iteration token cost based on (a) historical iteration cost trends, (b) feature scope (LOC + test count estimates), (c) per-role tier assignments from Pillar 1. The plan declares a budget; the Reviewer surfaces budget status at each boundary; iterations pause cleanly at safe boundaries (review-signoff, retro, iteration-closeout) when projection exceeds budget. Composes with Proposal 040 (Token Economy as Governance Driver) by adding plan-time projection + boundary-aware pause behavior.

**Empirical evidence**:

- **Smoke test data point 1**: Copilot hit token exhaustion at Phase 1 completion (11% of plan). Held gates correctly until exhaustion. Session later resumed and finished. No work lost because exhaustion happened at a safe boundary.
- **Smoke test data point 2**: Codex (gpt-5.5 xhigh) hit token exhaustion at iter-003 completion mid-feature. Same pattern — paused cleanly at review-signoff boundary. User waiting until 13:44 for budget reset.
- **The pattern**: methodology rigor INCREASES token cost (more tests + more substantive handoffs + per-role routing dispatches more agent turns). Both gold-standard hosts paid for that rigor with budget exhaustion. The methodology must be budget-aware to be sustainable.

## How

Sequencing strategy: each pillar is independently shippable. The proposal's value is documenting them as a coherent set with shared empirical evidence; the implementation can ship pillars in priority order.

### Sequencing recommendation (based on smoke-test pain ranking)

| # | Pillar | Effort | Why this order |
|---|---|---|---|
| **1** | **Pillar 4** (Bug → Regression-Test FIRST) | 5-8 SP | Pure methodology + 1 validator rule. Cheapest pillar; closes the most empirically-visible gap (3 of 4 hosts shipped bug-fixes without regression tests). Composes with already-drafted Proposal 055 + 067 |
| **2** | **Pillar 2** (Runtime Verification Mandate) | 8-12 SP | Direct fix for Claude's WM_NCCREATE bug class. New Reviewer charter directive + validator rule that flags GUI/runtime features without `--smoke-test` flag at review boundary |
| **3** | **Pillar 5** (Canonical Verdict Menu) | 4-6 SP | Specrew already encodes the canonical shapes — this just mandates surfacing them in handoffs. Host adapters propagate the requirement; existing Copilot pattern is reference impl |
| **4** | **Pillar 3** (Domain-Specialist Crew Members) | 8-12 SP | New plan-boundary checklist + Spec Steward charter directive. Specialist catalog starts with the 8 named domains; agents can propose specialists outside the catalog |
| **5** | **Pillar 1** (Quality-Tier Routing) | 10-15 SP | Extension of Proposal 068. Cheaper to ship if Squad's per-role engine (Copilot) is the reference impl; harder on non-Copilot hosts that don't have multi-model dispatch natively. Wait for at least one non-Copilot host to grow per-role routing before mandating |
| **6** | **Pillar 6** (Token Budget Awareness) | 12-18 SP | Largest scope; depends on Proposal 040 (Token Economy) shipping first to have cost-per-iteration data. Plan-time projection + boundary-aware pause behavior + Reviewer-surfaced budget status |

**Total**: 47-71 SP across 6 pillars. Spans Phase 2 + Phase 3 sequencing.

### Validator rule additions (mechanical enforcement layer)

| Rule | Pillar | Scope |
|---|---|---|
| `bug-fix-requires-regression-test` | 4 | Reject commits matching `(fix\|bug\|regression)` in subject without co-committed test file in `bug-fix/<bug-id>/test.*` |
| `runtime-component-requires-smoke-test-flag` | 2 | At review boundary, if spec mentions GUI/daemon/service, executable must implement `--smoke-test` flag (check via `--help` parse or named-export grep) |
| `verdict-menu-shape` | 5 | If host adapter surfaces a verdict menu, options must round-trip to canonical shapes (parser test) |
| `plan-declares-domain-specialists` | 3 | At plan boundary, plan.md must declare specialist roster if spec mentions any of the 8 named domains (catalog list) |
| `plan-declares-token-budget` | 6 | At plan boundary, plan.md must declare a token-budget projection or explicit `unlimited` opt-out |

### Charter updates (cooperative-prompt layer)

| Role | Pillar | New directive |
|---|---|---|
| Reviewer | 2, 5 | Run the deliverable. Surface verdict menu via canonical shapes |
| Spec Steward | 3 | At plan-boundary, propose domain specialists if spec touches the 8 named domains |
| Implementer | 4 | Write the failing test BEFORE the fix; commit both together |
| Planner | 1, 6 | Per-role tier assignments in plan; declare token budget |

## Composition notes

- **Proposal 040 (Token Economy)** is the foundation for Pillar 6. This proposal extends 040 with plan-time projection + boundary-aware pause behavior. 040 must ship first.
- **Proposal 055 (Post-Ship Bug-Fix Lifecycle)** + **Proposal 067 (Small-Fix Slice Type)** are the slice-type homes for Pillar 4's bug-fix slice. Pillar 4 supplies the WHAT-MUST-BE-IN spec; 055/067 supply the WHERE-IT-LIVES.
- **Proposal 068 (Cost-Aware Routing)** is the cost-side of Pillar 1. This proposal adds the quality-side (per-role tier assignment).
- **Proposal 105 (Host-Native Hook Deployment)** strengthens Pillar 5: hook-enforced hosts can MECHANICALLY require the canonical verdict shape, not just cooperatively prompt for it.
- **Proposal 030 (Quality Hardening Bundle)** is a sibling — Pillar 2 (runtime verification) and Pillar 3 (domain specialists) compose naturally as additions to the hardening quality lens.

## Open questions

1. **Should the 6 pillars be one proposal or six separate proposals?** Bundling preserves the design coherence and shared empirical motivation but makes incremental shipping harder. Recommendation: keep as one design document; ship as 6 separate slices. Each slice references this proposal for empirical motivation.
2. **Pillar 1's per-role tier assignment — is it part of Specrew or part of Squad?** Copilot's per-role routing engine is Squad-internal. Replicating it for non-Copilot hosts requires either (a) Squad becoming host-agnostic OR (b) host-native per-role dispatch (e.g., Claude's subagent mechanism, Codex's TOML agents). Architectural decision needed at Pillar 1 implementation time.
3. **Pillar 3's specialist catalog — finite or extensible?** Recommend: start with 8 named domains (game physics, concurrency, crypto, distributed, ML, embedded, networking, security/auth), allow agents to propose new specialists with rationale, validator accepts any specialist with a charter ≥ 100 words covering "what this specialist watches for" + "typical traps in this domain".
4. **Pillar 4's "fix" detection — keyword-based brittle?** Yes. Suggestion: agent self-declares `bug-fix` slice type in iteration plan; validator checks for accompanying regression test. Keyword-based commit-message check is a fallback for free-form commits.
5. **Pillar 6's projection accuracy — how to bootstrap?** First N iterations have no historical data. Suggestion: first iteration declares a budget guess (`100K tokens`); subsequent iterations refine based on actuals captured in retro `Token Cost` row. Calibration improves over time.

## Empirical Motivation Captured

The 2026-05-25 4-host smoke test on the C++ DirectX dice-app prompt produced this proposal in real time. The user (Alon) ran:

1. Same prompt to all 4 hosts (Antigravity, Codex, Claude, Copilot)
2. Audited the resulting projects across 5 dimensions (SDLC artifacts, code quality, tests, static analysis, engineering process)
3. Switched Antigravity to a higher-tier model for a "QA pass" — discovered no Stage-2 iteration artifact; 3 fixes landed as out-of-lifecycle hotfixes
4. Reported the dice-penetration bug from Antigravity that persisted across multiple fix attempts
5. Reported Claude's WM_NCCREATE bug found via desktop run
6. Reported Copilot's per-role routing engaged (Reviewer → Haiku 4.5)
7. Reported 2 token-exhaustion events (Copilot first, Codex at iter-003 with gpt-5.5 xhigh)

Specific commit/file references:

- Antigravity hotfixes outside lifecycle: commits `67521bd`, `91541ab`, `095c0a8` (no iter-002 artifact authored)
- Codex `--smoke-test` flag: iter-002 review confirmed via "DiceApp.exe --smoke-test exited 0"
- Claude `no-penetration` test: `tests/test_collision.cpp` "body does not sink through felt"
- Copilot per-role routing: `Speckit.specrew-speckit.sync-iteration-closeout(claude-haiku-4.5)` log line
- Claude WM_NCCREATE diagnosis: identified post-screenshot, no regression test added

These references make the proposal's empirical motivation auditable and concrete.

## Not in scope

- **Pillar enforcement on existing closed iterations**: applies only to NEW work post-shipping. Retroactive enforcement would invalidate existing closed iterations.
- **Specific model selection within tiers**: this proposal mandates the tier (cheap-fast / balanced / strong-strict) but not the specific model (Haiku vs Gemini Flash vs GPT-4o-mini). Model selection within tier is project preference.
- **Hardware-resource budgeting**: out of scope. Only token/$$ budget addressed.
- **Multi-host concurrent execution**: Proposal 024 territory. This proposal's per-role routing is single-host multi-model.
