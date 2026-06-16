<p align="center">
  <img src="assets/specrew-icon.png" alt="Specrew" height="100" align="middle" />
  &nbsp;&nbsp;
  <img src="assets/specrew-wordmark-light.svg#gh-light-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
  <img src="assets/specrew-wordmark-dark.svg#gh-dark-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
</p>

# Specrew User Guide

This guide covers the day-to-day Specrew lifecycle: planning, execution, review/demo, retrospective, and drift handling.

If the lifecycle state, installed module, or managed project surfaces drift out of sync, start with [troubleshooting.md](troubleshooting.md) before hand-editing generated files or session-state artifacts.

## Recommended Downstream Entry Point

After `specrew init`, start feature work with:

```powershell
specrew start
```

`specrew start` is the canonical downstream entrypoint. On **macOS/Linux**, `specrew`
is a native shell command installed by `install.sh` (or `specrew install-shell-wrappers`)
that forwards to the runtime internally — you never type `pwsh`. On **Windows**, the
`specrew` command resolves through the PowerShell module alias (installed via
`Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck`, or via
`Import-Module C:\Dev\Specrew\Specrew.psd1` from a local clone). For environments
that can't load the module, the direct-script fallback is
`pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 start` — same arguments otherwise.

It prepares the Crew handoff, launches the selected host CLI (`--host copilot|claude|cursor|codex|antigravity`, default `copilot`) when available, and tells the Crew to drive the full Spec Kit lifecycle with an explicit clarify gate: `specify`, then `clarify`, then `plan`, `tasks`, and `implement`, with skip rationale reserved for resumed specs that are already clarified and materially unchanged. The intended human role is to answer only the unresolved questions the Crew cannot safely answer from repo context or current artifacts. You can optionally pass a short plain-language request if you already know the next feature or fix.

For new brownfield projects, the handoff includes discovery from existing code, manifests, docs, and recent git history so the Crew can reconstruct the current system baseline, seed the starting spec, and propose concrete stack/domain specialists before it asks broad intake questions. If you start without a grounded request, Specrew keeps the host out of autopilot so the Crew can ask the next intake question and wait for your answer before it invokes `speckit.specify`.

Once the scope is grounded, Specrew launches from the project directory, reuses the current terminal by default, and auto-loads a compact bootstrap message that points the host at `.specrew\last-start-prompt.md`, `.specrew\start-context.json`, and the human-readable `.specrew\start-summary.md`. Specrew defaults to **gate-respecting mode** — the Crew stops at every lifecycle approval boundary (specify, clarify, plan, tasks, implement, review, retro) and waits for explicit human verdict before advancing. Specrew also defaults to `--allow-all` for tool-call approval (translated per host: Copilot `--allow-all`, Claude `--dangerously-skip-permissions`, Cursor `--force`, Codex `--dangerously-bypass-approvals-and-sandbox`, Antigravity `--dangerously-skip-permissions`); use `--prompt-approvals` to keep each tool call interactive. The two flags are independent: `--allow-all` controls tool-call approval; `--autonomous` controls whether the Crew advances through lifecycle gates without human input. Pass `--autonomous` only for unattended runs such as overnight execution where you have already authorized the full lifecycle. Pass `--new-window` if you explicitly want a detached PowerShell window.

Five host runtimes are supported — Claude Code, Cursor (`cursor-agent`), Codex CLI, GitHub Copilot CLI, and Antigravity (`agy`). The interactive host-selection menu shows installed hosts in priority order (Claude → Cursor → Codex → Copilot → Antigravity); the `--host` flag non-interactive default remains `copilot` for predictability in CI/automation. Each host launches with the same Specrew bootstrap context but uses host-native CLI flags via Specrew's per-host translation layer (see the "Multi-Host Launch" section below for the per-host flag matrix). Optional delegated agents such as Claude and Codex are *also* available as additive routing choices for review-heavy and problem-solving-heavy work when enabled — that's an orthogonal concern from `--host` (which picks the launching CLI), captured in `.squad\decisions.md` as the requested agent family, effective agent family, concrete model ID, and fallback reason when routing is not honored. Specrew applies a **no-gap policy** at review/closure time: known gaps across spec, implementation, tests, docs, or observability must be fixed in the current iteration or explicitly deferred with your approval and recorded evidence before the run is claimed complete. The selected host may still ask you to trust the project directory on first launch.

If you want a repeatable mission-completion smoke check of the real handoff boundary, run `tests\manual\copilot-squad-smoke.ps1`. It provisions a fresh repo, runs `specrew init`, runs `specrew start`, and can optionally launch the real Copilot+Squad session for operator-observed end-to-end validation. When launched, the smoke harness now defaults to same-window monitoring so the live session can be observed directly; use its `-NewWindow` switch only when you intentionally want a detached window.

## Boundary Enforcement (v0.25.0)

Starting in v0.25.0, Specrew enforces lifecycle boundary discipline **mechanically** at the tool-call layer, not just by prose convention. Proposal 065 (Feature 039) ships skill-level authorization gates inside every boundary-advancing skill. The Crew cannot chain past a boundary without an explicit, recognized verdict from you.

### Recognized verdict shapes

When the Crew surfaces a boundary handoff and asks for your verdict, the parser accepts exact shapes only. Ambiguous prose (`looks good`, `yep`, `continue`, `fine`, `okay`) is rejected and re-prompted. The canonical forms:

- `approved for <boundary>-boundary entry` — authorize advance INTO the named boundary
- `approved for <boundary>` — shorter equivalent
- `approved for review-boundary AND review-signoff` — compound, for legitimate two-boundary progression where a substantive review covers both at once
- `rejected for <boundary>` — explicit refusal; Crew returns to clarify or re-plan
- `parked` — hold the current state; no advancement

The full nine boundaries are: `specify`, `clarify`, `plan`, `tasks`, `before-implement`, `review-signoff`, `retro`, `iteration-closeout`, `feature-closeout`.

### Emergency bypass

For migration replays, debugging stuck enforcement, or batch lifecycle work where every-boundary authorization would create unsafe friction:

```powershell
specrew start --bypass-boundary-enforcement --reason "schema migration replay"
```

The `--reason` flag is **mandatory**. Session-scoped (not per-boundary) — one bypass disables enforcement for the whole session, which discourages casual use. Every bypassed boundary writes an audit-trail entry to `.squad/decisions.md`.

### How this composes with `--autonomous`

`--autonomous` (Proposal 066, shipped 2026-05-20) controls whether the host runtime advances **between agent turns** without user input. Boundary enforcement (F-039) controls whether the agent can chain **across boundaries within a single turn**. They are independent:

- `--autonomous` alone: agent advances turn-by-turn but still hits skill-level gates at every boundary
- Boundary enforcement alone (default): gates always fire; turns wait for input
- Both: gates still fire; turns advance without input but every boundary surfaces a directive
- `--bypass-boundary-enforcement`: suspends gates; `--autonomous` still controls turn advancement

## What you'll see at every stop

Every time the Crew stops at a boundary, the console shows a **six-section human re-entry packet** in this exact shape:

```text
## What I just did

[Substantive narration of what changed — features advanced, artifacts written, tests run, decisions
 captured. Numeric references are paired with plain-language scope phrases (`FR-007, the sin/cos
 extension`). The committed-evidence reference (commit SHA range) appears here too.]

## Why I stopped

I stopped at the <boundary> boundary because <reason the next step needs you>.

## What needs your review

[The artifacts, decisions, risks, skipped checks, and safe-skim areas that matter for this verdict.
 Review targets are linked via BARE `file:///` URIs (NOT markdown-link form `[name](url)`) so you
 can Ctrl+Click through to the artifact.]

## What happens next

[The next lifecycle phase, artifacts that will be produced, and the next expected boundary stop.]

## Discussion prompts

[One to three targeted prompts, each with context, the question, the recommended/default path when
 one exists, and the consequence of changing direction.]

## What I need from you

[The single best immediate action. Names the canonical verdict shape you should type.]
```

When the Crew stops after substantial work outside a boundary verdict, it uses the same context minus `Discussion prompts`: `What I just did`, `Why I stopped`, `What needs your review`, `What happens next`, and `What I need from you`. This is mandatory in downstream projects and on every host, even when hooks are unavailable or failed open.

These sections are not stylistic — they are a methodology guarantee from Feature 016 (Substantive Interaction Model, Pillar 1). The format lets you scan a handoff in seconds and decide whether to advance, even when you have been away from the session.

**Bare `file:///` URIs, not markdown link form.** Modern PowerShell terminals (Windows Terminal, VS Code integrated terminal) auto-detect bare `file:///` URIs and make them Ctrl+Clickable. They do NOT render markdown — so if the Crew emits `[plan.md](file:///C:/foo/plan.md)`, the URL is hidden inside the parentheses and you cannot click through. If you see markdown-link form in a handoff, that is the regression: re-prompt the Crew with `please emit bare file:/// URIs, not markdown-link form`.

**What to do**:

1. Read the packet sections. The flow is intentional: what happened → why it stopped → what to inspect → what happens next → what to type.
2. Ctrl+Click any bare `file:///` link the Crew shows you — those are the artifacts the verdict applies to.
3. Type one of the canonical verdict shapes from the "Recognized verdict shapes" section above. Ambiguous prose (`looks good`, `continue`) is rejected and re-prompted.

**If you see a stop that doesn't follow this format** — for example, a bare technical status line, a pile of tool output, or a question without context — that is a methodology regression. Re-prompt the Crew with `please use the Specrew stop context packet` and the Crew should regenerate the handoff. If it persists across hosts (Copilot / Claude / Cursor / Codex / Antigravity), open an issue — the canonical templates govern this UX promise.

> Mid-task progress updates are NOT stop packets. When the Crew is still actively working (writing a file, running a test, waiting on a background process), it uses single-line prose without the user-action section. The packet format is reserved for boundary stops, real human blockers, long-work pauses, and handoff-worthy stops.

## Closing iterations + features

The lifecycle does not end at `implement`. Two more boundaries close the work: **iteration-closeout** and **feature-closeout**. They are not ceremonial — they are what produces the final artifacts, marks the work durably "done", and gates the next iteration / next feature from starting.

### Iteration-closeout

Fires after the Crew passes review-signoff and writes `retro.md`. Your verdict (`approved for iteration-closeout`) triggers `Invoke-SpecrewBoundaryStateSync -BoundaryType iteration-closeout`, which:

1. **Generates `specs/<feature>/iterations/<NNN>/dashboard.md`** — per-iteration snapshot with task verdicts, phase variance, drift summary, FR scoreboard, velocity.
2. **Appends the iteration to `.specrew/closed-iterations.yml`** — the closed-iterations index is what the validator uses to skip already-finished iterations on later runs (Proposal 085, F-036). Without this entry the validator re-validates the iteration on every future run.
3. **Updates the feature's iteration `Status` to `complete`** in `iterations/<NNN>/plan.md`.
4. **Sets `session_state_boundary: iteration-closeout`** in `.specrew/start-context.json` so the next `specrew start` knows the iteration is done.

The next iteration cannot start until this one closes. If you skip iteration-closeout and just start typing about iter-002 work, the Crew will resume the open iter-001 because that is what session-state says is in flight.

### Feature-closeout

Fires after the LAST iteration of a feature is closed. Your verdict (`approved for feature-closeout`) triggers the same sync script with `-BoundaryType feature-closeout`, which:

1. **Generates `specs/<feature>/closeout-dashboard.md`** — cross-iteration FR scoreboard, pillars-delivered table, cross-feature bundle disclosure (if any), velocity snapshot.
2. **Marks the feature complete** in `.specrew/roadmap.yml` (if the feature appears there).
3. **Sets `session_state_boundary: feature-closeout`** — the next `specrew start` knows this feature is done and can start a new one.

The next feature cannot start until this one closes. Same mechanic as iteration-closeout: in-flight features stay in flight until you say "done".

### Verdict shapes

The canonical forms (other parser-recognized shapes are listed in the "Boundary Enforcement" section above):

- `approved for iteration-closeout`
- `approved for feature-closeout`
- `approved for iteration-closeout AND feature-closeout` — compound, when the closing iteration is also the feature's last iteration

### When you should NOT close

Closeout is the explicit "this is done" gate, not the "I'm pausing" gate.

- If you only want to stop for the day, close the terminal. Session state in `.specrew/start-context.json` resumes you at the same boundary on next `specrew start`.
- If you discover unfinished work after starting closeout, type `rejected for iteration-closeout` (or `parked`) — the Crew returns to plan, you can add another iteration, and re-attempt close later.
- If a feature genuinely never finishes (long-running spike, abandoned exploration, deferred-to-rewrite), the methodology stance is still to close — with a feature-closeout artifact that explicitly records the abandonment reason. **Never-closing is not a state Specrew supports**; it pollutes the session-state machinery and the closed-iteration index. Use `rejected for feature-closeout` only if you genuinely intend to continue the feature later.

### What closeout produces, at a glance

| Boundary | Files written | State changes |
|---|---|---|
| `iteration-closeout` | `iterations/<NNN>/dashboard.md` | `closed-iterations.yml` += this iter; `plan.md` Status = complete |
| `feature-closeout` | `closeout-dashboard.md` (one per feature, at feature root) | `roadmap.yml` feature status = complete; `start-context.json` session_state_boundary = feature-closeout |

These artifacts are the canonical input for future estimation calibration (velocity reads them) and for any historical reconstruction of "what did this feature ship?". If you skip closeout, you keep the work but lose the index entry, the dashboard rendering, and the calibration data.

## Walkthrough: a two-iteration calculator

A narrative-only worked example showing how a real two-iteration feature flows end-to-end. The first iteration builds the calculator MVP. The second iteration adds scientific functions. Read this once before trying it — it is the shortest path to understanding what Specrew does at each boundary.

### Setup

```powershell
mkdir C:\Dev\calculator-walkthrough
cd C:\Dev\calculator-walkthrough
git init
specrew init
```

`specrew init` deploys the governance scaffold, slash-command catalog, and canonical Crew agents to `.specrew/team/agents/`. Same as the Quickstart in [getting-started.md](getting-started.md#3-bootstrap-a-project).

---

### Iteration 1 — Calculator MVP (+ − × ÷ and memory)

#### Start the feature

```powershell
specrew start "Build a web-based calculator with only the + - * / MR MC M+ M- operations"
```

Specrew refreshes the runtime handoff, picks the default host (Copilot CLI), and launches with bootstrap context auto-loaded. The Crew (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) reads the canonical agents from `.specrew/team/agents/`.

#### Boundary 1: `specify`

Before drafting the spec, the Crew runs the **Design Workshop** intake: it hands you a lens agenda and opens with the **product & problem domain** lens (who the calculator is for, the core job, MVP scope) before any technical lens. The Spec Steward then asks for any clarifications it cannot answer from the prompt + repo, and proposes `specs/001-calculator/spec.md` with:

- 6 functional requirements (FR-001 four arithmetic operations / FR-002 memory store/recall/add/subtract / FR-003 input validation / FR-004 division-by-zero handling / FR-005 keyboard support / FR-006 form-submit prevention)
- 4 acceptance criteria
- Stack pick: vanilla HTML/CSS/JS (no framework — the prompt is small)

You see a handoff in the console: "Spec ready. What I just did: drafted spec.md with 6 FRs. Why I stopped: spec needs your sign-off before clarify. What I need from you: `approved for specify` to advance."

Type: `approved for specify`.

#### Boundary 2: `clarify`

The Crew surfaces 2 questions: should division-by-zero throw, display `Error`, or display `Infinity`? Should sin/cos/etc. be in scope?

You answer "display `Error`" + "no — out of scope for this iteration".

The Crew commits `specs/001-calculator/clarifications.md` and asks for `approved for clarify`. Type it.

#### Boundary 3: `plan`

The Planner writes `specs/001-calculator/plan.md` with:

- Phase plan: Discovery (0.5) / Implementation (4) / Review (1) / Rework (0.5) = 6 SP
- File map: `calculator.html` / `calculator.css` / `calculator.js` / `calculator.test.js`
- Routing policy: standard reasoning class for the implementer

Type: `approved for plan`.

#### Boundary 4: `tasks`

The Planner writes `specs/001-calculator/tasks.md` and the iteration plan `specs/001-calculator/iterations/001/plan.md` with 4-6 tasks bounded by FRs.

Type: `approved for tasks`.

#### Boundary 5: `before-implement`

The Implementer surfaces a short pre-flight: scaffolds will write to these files, here is the testing strategy, here is the validation criterion.

Type: `approved for before-implement`.

#### Implement → Review → Retro

Because this feature writes code, the **code & implementation** lens (run at design time) captured the craft rules — vanilla JS, no framework, small pure functions — into `specs/001-calculator/implementation-rules.yml`, and the lens's implement-time guidance skill surfaced them to the Implementer as it wrote. The Implementer writes the four files + 11 unit tests. Tests run; all 11 pass. The Reviewer reads the implementation, runs the validator, writes `iterations/001/review.md` with task verdicts.

Type: `approved for review-signoff`.

The Retro Facilitator writes `iterations/001/retro.md` with Phase Variance, Drift Summary (0 drift events), What Went Well / What Didn't Go Well, Improvement Actions.

Type: `approved for retro`.

#### Boundary 9: `iteration-closeout`

The Crew runs `sync-iteration-closeout`, which generates `iterations/001/dashboard.md` and appends iter-001 to `.specrew/closed-iterations.yml`. The Spec Steward summarizes: "iter-001 complete. 6 SP delivered. 11 tests green. 0 drift events. Velocity: 6 SP / 1 day."

Type: `approved for iteration-closeout`.

The Crew now asks: "More iterations on this feature, or feature-closeout?" — this is the **explicit decision point** where you either continue with iter-002 (which we will, below) or end the feature.

---

### Iteration 2 — Scientific functions (sin, cos, atan, sqrt)

You have a working calculator. Now you want to add scientific operations. **This is a NEW iteration of the SAME feature** — the spec scope changes, but the feature identity does not.

#### Re-open the feature

```powershell
specrew start "Add sin, cos, atan, and sqrt to the calculator"
```

Specrew sees `session_state_boundary: iteration-closeout` (last state from iter-001) and the same feature 001-calculator still open. Instead of starting a new feature, it offers iter-002 on the existing feature. You accept.

#### Boundary 1: re-`specify` (scope extension)

The Spec Steward re-reads `spec.md` and proposes 4 additional FRs (FR-007 sin / FR-008 cos / FR-009 atan / FR-010 sqrt) and 2 new ACs. It also flags a small drift candidate: the original FR-005 said "keyboard support" — should `s`, `c`, `t`, `r` shortcuts now bind to the new functions? You decide: yes.

Type: `approved for specify`.

#### Boundary 2: `clarify`

The Crew asks: angle mode for trig functions — radians, degrees, or user-toggle? `sqrt` of a negative number — `Error`, `NaN`, or display `i` (imaginary unit)?

You answer: "radians (no toggle in this iter)" + "display `Error` (match div-by-zero handling)".

Type: `approved for clarify`.

#### Boundary 3-4: `plan` + `tasks`

The Planner extends `iterations/002/plan.md` with 3-4 tasks for the 4 new operations + keyboard binding update + 8 new unit tests. Phase plan: Implementation (3) / Review (0.5) / Rework (0.5) = 4 SP.

The Crew notes in `plan.md` Phase Baseline: "Cross-iteration velocity calibration: iter-001 was 6 SP / 1 day. iter-002 estimated at 4 SP." This is what the iter-001 `dashboard.md` made possible.

Type each: `approved for plan`, `approved for tasks`.

#### Implement → Review → Retro

The Implementer adds 4 button handlers + 8 unit tests + updates keyboard event listener. All 19 tests (11 old + 8 new) pass. Reviewer signs off. Retro records the variance: actual 4.5 SP vs estimated 4 SP, +0.5 SP from `sqrt(-1)` edge case requiring an extra unit test.

Type: `approved for review-signoff`, `approved for retro`.

#### Boundary 9: `iteration-closeout`

`iterations/002/dashboard.md` written; iter-002 appended to the closed-iterations index. Velocity now reads as 4.5 SP / 1 day for iter-002, cross-iteration average 5.25 SP/day. Future iterations on this feature will use that figure for calibration.

Type: `approved for iteration-closeout`.

#### Boundary 10: `feature-closeout`

You decide iter-002 is the last iteration of this feature. The Crew runs `sync-feature-closeout`, which:

- Generates `specs/001-calculator/closeout-dashboard.md` with the cross-iteration FR scoreboard (FR-001 through FR-010 all ✅ shipped), Pillars delivered, velocity table (iter-001 6 SP / iter-002 4.5 SP).
- Marks the feature complete in `.specrew/roadmap.yml`.
- Sets `session_state_boundary: feature-closeout` in `.specrew/start-context.json`.

Type: `approved for feature-closeout`.

The next `specrew start "<new feature description>"` now starts a fresh feature, because session-state says calculator is done.

---

### What this walkthrough demonstrates

- **The lifecycle has a defined end.** `feature-closeout` is the canonical "this is done" gate. Until you authorize it, the feature is in flight.
- **Iterations are scoped, not chunked.** Each iteration extends or refines the feature's spec. The spec is the durable artifact; iterations are how you grow it.
- **Velocity calibration is a closeout side-effect.** `dashboard.md` from iter-001 made iter-002's estimate land more accurately. This compounds — features with many iterations get better calibration over time.
- **Session-state preserves your place.** Closing the terminal between iter-001 and iter-002 (or in the middle of an iteration) is safe. The next `specrew start` resumes where you left off.

If you want to try the walkthrough yourself, run the commands above against your own machine. The exact wording of Crew handoffs will vary by host (Copilot / Claude / Cursor / Codex / Antigravity) and by model, but the boundary sequence and the artifacts produced are identical.

## What's New (v0.24.3 + v0.25.0 release bundle)

The v0.24.3 process-optimization bundle and v0.25.0 boundary-enforcement release together shipped substantial discipline and performance improvements. Headline items:

- **F-039 / Proposal 065 — Launch-Mode Boundary Enforcement** (v0.25.0): the section above
- **F-032 / Proposal 090 — Closeout Lifecycle Sync Commands**: `/speckit.specrew-speckit.sync-review-signoff`, `sync-retro`, `sync-iteration-closeout`, `sync-feature-closeout` — canonical sync slash commands that wrap `Invoke-SpecrewBoundaryStateSync` and prevent the non-canonical boundary-string bug class (`feature-closed`, `iteration-closed`, etc.). Use these instead of inline PowerShell at every closeout boundary.
- **F-033 / Proposal 088 — Markdown Lint Pre-Boundary Auto-Fix**: every `Invoke-SpecrewBoundaryStateSync` invocation runs `markdownlint-cli --fix` on changed `.md` files BEFORE any state-file writes. Auto-fixable violations get fixed and surface a directive to commit the fixes as `chore(lint):`. Unfixable violations halt boundary sync with file:line:rule diagnostics.
- **F-034 / Proposal 086 Pillar 1 — Validator Result Memoization**: per-iteration validator results cached at `.specrew/.cache/validator-cache.json` (gitignored). Edit-validate-edit loops drop from ~30s to <100ms on cache hits. Use `-NoCacheRead` to force fresh validation.
- **F-035 / Proposal 084 — Validator Iteration Parallelization**: `validate-governance.ps1` parallelizes iteration validation via `ForEach-Object -Parallel`. Cold-cache 44-iteration runs project ~5× speedup at default throttle 6. `-NoParallel` falls back to serial; `-ThrottleLimit <N>` tunes concurrency.
- **F-036 / Proposal 085 — Closed-Iteration Index**: `.specrew/closed-iterations.yml` records every closed iteration. Validator's full-repo path skips them unless `-IncludeClosed` is set. Use `-RebuildClosedIndex` to regenerate from state.md walk.
- **F-037 / Proposal 086 Pillar 5 — Repetition Detector**: logs validator invocations to `.specrew/.cache/last-commands.log` (FIFO at 20); emits `[validator-repetition-warning]` on the 3rd consecutive identical run against unchanged code. Diagnostic only — non-blocking.
- **F-038 / Proposal 089 minimal slice — PR Review Integration**: validator soft-warning surfaces when host has automated review available (e.g., GitHub Copilot reviewer detected via `gh` CLI + github.com remote) and `pr-review-resolution.md` artifact is missing. Captures Copilot's PR findings into a structured per-iteration artifact.
- **F-031 / Proposal 082 Tier 1 — Boundary Commit + Upstream Push Discipline**: methodology text additions across coordinator-governance.md + all 5 agent charters mandating semantic commit groups before boundary sync and immediate push after each commit. See the "Boundary Commit Discipline" section below.
- **F-030 / Proposal 083 — Local Validator Auto-Scope**: feature-branch `validate-governance.ps1` runs auto-detect the base ref and default to changed-only scope. Use `-FullRun` to force a complete sweep.

## Lifecycle at a Glance

1. Planning
2. Execution
3. Review/Demo
4. Retrospective

## Lifecycle-adjacent Spec Kit commands

Specrew surfaces these lifecycle-adjacent Spec Kit commands at specific lifecycle points. They are additive aids — they complement the governed lifecycle and do not replace governance.

| Command | Lifecycle point | When to use | Status |
|---|---|---|---|
| `/speckit.checklist` | before-plan | Requirements-quality aid that catches vague, incomplete, inconsistent, or missing requirements before planning. Recommended for substantive work; optional for low-risk slices. | Surfaced |
| `/speckit.analyze` | before-implement (after a complete `tasks.md`) | Additive cross-artifact consistency review across `spec.md`, `plan.md`, and `tasks.md`. Complements governance validation; does not replace it. | Surfaced |
| `/speckit.taskstoissues` | — | Known but **deferred** for Feature 054; not part of the default lifecycle in this slice. | Deferred |

## Project Status Dashboard

Use the dashboard whenever you need a one-screen delivery summary:

```powershell
specrew where
specrew status --compact
specrew where --team --no-color
```

> Direct-script equivalent (no module): replace `specrew` with
> `pwsh -NoProfile -File C:\Dev\Specrew\scripts\specrew.ps1`.

The dashboard reads:

- `.specify/feature.json` for the active feature
- `specs/<feature>/iterations/<NNN>/` artifacts for closed and active iteration data
- `.specrew/roadmap.yml` for roadmap phases when present

Closeout workflows now preserve historical dashboard snapshots:

- `specs/<feature>/iterations/<NNN>/dashboard.md`
- `specs/<feature>/closeout-dashboard.md`

These snapshots are generated automatically during iteration-closeout and
feature-closeout scaffolding and are preserved as immutable historical records.

The validator may emit `WARN [dashboard]` lines when roadmap declarations drift
from canonical shipped work or when required dashboard artifacts are missing
after the rollout cutover (historical pre-rollout iterations are grandfathered).

Core iteration artifacts live under `specs/<feature>/iterations/<NNN>/`.

## Crew Interaction Profile

Your **Crew Interaction Profile** is a per-user setting that tells Specrew *how much to ask, explain,
recommend, and auto-decide* across four decision areas: **Product Strategy**, **UX/UI Design**,
**Software Architecture**, and **AI Delivery Planning**. Higher settings (7–10) get concise,
expert-level questions and assume you make the call; lower or `auto` settings get more explanation,
recommended defaults, and transparent auto-decisions.

These four decision-area labels are **display only**. They are not job titles you must hold, and they
do not rename Specrew's internal **persona lenses** — the four perspectives the intake engine applies
to your request. The profile is your collaboration setting; the persona lenses are Specrew's internal
analysis machinery.

**Where it lives (loader/path rule).** The profile is resolved per current user from a local file —
never from shared repository content:

- **Windows**: `$env:USERPROFILE\.specrew\user-profile.yml`
- **Unix (Linux/macOS)**: `~/.specrew/user-profile.yml`
- Resolved by the shared loader `scripts/internal/user-profile.ps1`.

Shared instructions and agent guidance always point to this loader/path rule rather than embedding a
specific developer's dial values, so the profile stays current-user-specific.

**Where it applies.** Outside `/speckit.specify`, the resolved profile is surfaced in session context
as **soft** collaboration guidance for all agents — it is current-user runtime context, not shared
project truth. `/speckit.specify` is the only surface that **hard-applies** it (to drive per-lens
question depth and auto-decisions) in this release.

**Multi-developer safety.** Because the profile lives in each developer's home directory and is never
persisted into shared repository artifacts, two developers can work in the same repository with
different local `user-profile.yml` files and each receives their own resolved guidance — with no shared
repository changes and no profile-value collisions.

Manage it with `/specrew-user-profile show | edit | reset`. It is created on first `specrew start` and
reused across all Specrew projects. Legacy profiles created before this wording correction keep working
unchanged: the same persisted keys and internal persona IDs remain valid; only the visible labels and
explanatory text changed.

## 1. Planning

Goal: produce a requirement-traceable plan before execution starts.

> **Before the plan: the Design Workshop.** For substantive features, planning does not start from a blank page. The Crew facilitates a [Design Workshop](methodology/design-workshop-methodology.md) at intake (selecting the design lenses that matter) and again at the design-analysis stop (co-designing the component map, responsibilities, and flows with you before alternatives are compared). The human-selected design option recorded in `design-analysis.md` is authoritative plan input — `plan.md` must consume it, not re-decide it.
>
> The workshop persists durable artifacts you can review: the product & problem domain record at `specs/<feature>/workshop/product-domain.{md,yml}` (users, pain, MVP, constraints — captured before any technical lens), and, for code-writing features, a per-feature `specs/<feature>/implementation-rules.yml` manifest of the implementation-craft rules selected from Specrew's shipped `code-rules.yml` catalog. At implement time, the code-implementation lens's implement-time guidance skill reads that manifest — plus an optional project-wide `code-rules.local.yml` overlay for your company/org rules — and guides the coding agent as it writes. It is guidance, not a review-time gate.

Minimum artifact: `plan.md`

Helpful scaffold:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-iteration-plan.ps1 `
  -SpecPath .\specs\001-your-feature\spec.md `
  -IterationNumber 001
```

Checklist:

- Every task maps to requirement IDs
- Effort and owner are filled
- Capacity is explicit
- `plan.md` includes an `## Effort Model` snapshot that matches `.specrew/iteration-config.yml`
- The plan reflects `.specrew/iteration-config.yml` values for effort unit, bounding mode, overcommit threshold, and defer strategy
- If the plan exceeds the configured threshold, `validate-governance.ps1` must fail the planning artifact and name explicit deferral candidates from the lowest-priority requirement slices first
- Status is `planning` until approved

## 2. Execution

Goal: complete tasks while keeping task state and drift evidence current.

Minimum artifacts: `state.md`, `drift-log.md`

Helpful scaffold:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-iteration-artifacts.ps1 `
  -SpecDirectory .\specs\001-your-feature `
  -IterationNumber 001
```

Checklist:

- Update task status in `plan.md`
- Keep `state.md` current (`Last Completed Task`, `Tasks Remaining`)
- Log drift events with requirement citations in `drift-log.md`

If execution is interrupted, use the resume helper to recover the next task from `state.md` and `plan.md`. The helper repairs stale or partial execution metadata when the task table provides enough information to continue safely:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\resume-iteration.ps1 `
  -IterationDirectory .\specs\001-your-feature\iterations\001 `
  -ResumeMode continue
```

## 3. Review/Demo

Goal: record per-task verdicts against requirements.

Minimum artifact: `review.md`

Helpful scaffold:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-review-artifact.ps1 `
  -IterationDirectory .\specs\001-your-feature\iterations\001
```

Checklist:

- Verdict for each completed task: `pass`, `needs-work`, or `blocked`
- Overall verdict recorded
- Any unresolved drift explicitly called out

## Reviewer-Regression Routing and Lockout-Cap Behavior

Specrew treats a concrete human-found defect in a slice that the Squad reviewer already approved or marked ready as a **Reviewer Regression Event**. The event stays a soft-warning governance signal, but it immediately changes the next review path for that feature:

1. Route to the **lowest stronger reviewer class** that is actually available.
2. If no stronger class exists, route to an **independent reviewer owner at the same class**.
3. If the strongest class is already active and no independent reviewer remains, **hold for explicit human direction** before review continues.

This reviewer-side routing is additive to the existing implementer-side escalation flow; Specrew does not replace the original implementer FR-027 behavior just because a reviewer regression occurred.

### Lockout-cap rule

Reviewer regressions do not allow unlimited implementer rotation. By default, Specrew caps the implementer chain at **two rotations beyond the original implementer**. Once the cap is active, the next revision must be:

- a **human-owned revision**, or
- an **explicitly justified alternate owner** recorded in `.squad\decisions.md`

Specrew does not synthesize another implementer specialist after the cap is reached.

When reviewer closeout artifacts are scaffolded, the lockout-cap handoff is visible in both `reviewer-index.md` and `specrew review`. The following lines were verified against actual `scaffold-reviewer-artifacts.ps1` and `specrew review` output on the lockout-cap fixture:

```text
Lockout Cap: active | chain=3/2 | locked_out=Standard implementer rotation pool (original + 2 rotations exhausted)
Next Owner: Awaiting human-owned revision or explicitly approved alternate owner recorded in `.squad/decisions.md`
SPECREW_REVIEW schema=v1 iter=001 feature=008-sample verdict=blocked tasks=3/3 reqs=3 files=0 new_deps=0 vuln=unscanned cov=not_executed escalations=1 routing_fallbacks=0 cap=active cap_chain=3/2 drift=0/0 index=specs\008-sample\iterations\001\reviewer-index.md
```

### Withdrawal and misreport handling

If a reviewer-regression report is later withdrawn or classified as a misreport, Specrew preserves the ledger audit trail and reverses only the still-pending state created by that event, such as:

- an in-flight reviewer escalation
- an awaiting-human-owned-revision hold
- an alternate-owner path that has not yet completed

Completed ownership changes remain historical fact. Unapproved candidate trap entries derived from the withdrawn event are removed, but already approved corpus entries stay under the normal corpus-change workflow instead of being auto-removed.

## 4. Retrospective

Goal: capture estimation accuracy, drift summary, and improvement actions.

Minimum artifact: `retro.md`

Helpful scaffold:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-retro-artifact.ps1 `
  -IterationDirectory .\specs\001-your-feature\iterations\001
```

Checklist:

- Task and phase variance captured
- Drift totals and resolutions summarized
- Improvement actions listed

## Troubleshooting

### Review boundary fails with a form-vs-meaning gap

If `validate-governance.ps1` reports a `review-evidence-integrity` failure, the
iteration artifacts declare completed work but the committed git diff since the
iteration baseline is empty. In practice, that usually means implementation was
not committed before review started.

Fix it in this order:

1. Commit the implementation work.
2. Re-run the validator.
3. Rebuild reviewer artifacts if review evidence was already scaffolded.

When you re-run `scaffold-reviewer-artifacts.ps1` with `-Force`, Specrew
overwrites the generated review artifacts after confirmation. Use
`-Confirm:$false` only for non-interactive automation.

**Important**: put human annotations and reviewer notes in `review.md`, not in
generated artifacts such as `code-map.md`, `dependency-report.md`,
`coverage-evidence.md`, or `review-diagrams.md`. Generated artifacts are
regenerated from git state and are expected to be disposable.

## Extending the Team After Bootstrap

Specrew bootstrap always installs and protects the same five baseline governance roles:

- Spec Steward
- Planner
- Implementer
- Reviewer
- Retro Facilitator

Each baseline role's charter is the canonical source-of-truth at `.specrew/team/agents/<role>.md` (e.g., `.specrew/team/agents/reviewer.md`). Every `specrew start --host <kind>` translates these canonical charters to the selected host's native subagent format:

- **Copilot** → `.squad/agents/<role>/charter.md` (raw markdown, consumed by Squad CLI)
- **Claude** → `.claude/agents/<role>.md` (YAML frontmatter + body)
- **Cursor** → `.cursor/rules/<role>.mdc` (MDC front-matter `description`/`alwaysApply` + charter body — Cursor Project Rules)
- **Codex** → `.codex/agents/<role>.toml` (TOML manifest)
- **Antigravity** → `.agents/agents/<role>.md` (YAML frontmatter + body)

The generated host-native files carry a `Specrew-managed` marker comment. Edits to the canonical charters propagate to all hosts on the next `specrew start`. Edits to a generated host-native file are preserved only if you also delete the `Specrew-managed` marker (in which case Specrew leaves the file alone). The baseline 5 are intentionally deterministic; do not remove or rewrite the canonical charters as your customization mechanism.

To add domain-specific help after bootstrap, use Specrew's command-driven team management interface:

```powershell
# Add a new domain-specific member
specrew team add security-analyst `
  --role "Security Analyst" `
  --charter "Review code for security vulnerabilities, ensure secure coding practices."

# List all current team members
specrew team list

# Update an existing member's charter
specrew team update security-analyst `
  --charter "Updated security review charter..."

# Remove a domain-specific member (baseline roles cannot be removed)
specrew team remove security-analyst
```

Replace `C:\Dev\Specrew` with the actual path where you cloned the Specrew repository.

### Optional: Adding Specrew to PATH

For convenience, you can add the Specrew scripts directory to your PATH to use short commands like `specrew team list` instead of typing the full path each time.

**Current Session Only** (temporary, lost when shell closes):

```powershell
$env:PATH = "$env:PATH;C:\Dev\Specrew\scripts"
```

**Persistent** (all future sessions):

```powershell
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$pathEntries = $currentPath -split ";"
if ($pathEntries -notcontains "C:\Dev\Specrew\scripts") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\Dev\Specrew\scripts", "User")
    Write-Host "Added Specrew scripts to user PATH. Restart your shell to apply." -ForegroundColor Green
}
```

After adding to PATH persistently, restart your PowerShell session, then use the short form:

```powershell
specrew start "Build a REST API for user management"
specrew team list
specrew team add my-specialist --role "Role" --charter "Charter text"
```

The `add` command creates all required Squad artifacts atomically: (1) adds a row to `.squad\team.md` outside the baseline block, (2) creates `.squad\agents\<member>\charter.md`, and (3) initializes `.squad\agents\<member>\history.md`. The `update` and `remove` commands modify or delete these artifacts consistently. All commands validate that baseline roles remain protected.

Use this path for additive specialization only. Specrew still expects the baseline governance crew to remain present.

## Updating and Redeploying Specrew

Use `Update-Module Specrew` for the normal installed-module update path, then reload the module and verify the version:

```powershell
Update-Module Specrew
Import-Module Specrew -Force
specrew --version
```

If the module needs a clean reinstall from the trusted Gallery source, use:

```powershell
Install-Module Specrew -Scope CurrentUser -Force -SkipPublisherCheck
Import-Module Specrew -Force
specrew --version
```

`-Force` in `Install-Module`/`Update-Module` is package-manager force: it refreshes or overwrites the installed module copy. It does not approve Specrew lifecycle boundaries, does not bypass brownfield conflicts, and does not make project-local edits safe by itself. `-SkipPublisherCheck` bypasses publisher validation; use it only for the official Specrew Gallery package or a package source you trust. If the source is unknown, stop and verify the package instead of bypassing the check.

After updating the module, rerun `specrew init` from each project that needs refreshed project-local assets:

```powershell
cd C:\Dev\your-project
specrew init
```

Run init again when any of these are true:

- The release notes mention runtime, extension, template, governance, or skill-catalog deployment changes.
- `.specify\extensions\specrew-speckit\` is missing or stale compared with the installed module.
- `.claude\skills\`, `.github\skills\`, or `.agents\skills\` is missing `/specrew-*` skills.
- `specrew start` reports a missing skill-catalog or runtime deployment gap.
- You intentionally want to refresh managed Specrew project files after a module update.

`specrew start` repairs missing skill catalogs on the normal launch path. Use `specrew init` when you want the explicit redeploy pass for the whole project-local Specrew surface, especially after a module update. Use `specrew init -Force` only when you intentionally want a forced redeploy of managed surfaces; it still preserves conflict checks and brownfield safety rules.

## Brownfield Bootstrap

When `specrew init` detects an existing `.specify/` or `.squad/` directory in the project, it operates in brownfield mode:

1. **Preserves existing configuration**: Existing specs, governance artifacts, and user customizations are never overwritten.
2. **Merges baseline roles**: Specrew's five baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) are merged into `.squad/team.md` only if they don't already exist.
3. **Reports conflicts**: If existing roles or ceremonies conflict with Specrew's baseline, the script reports them and provides resolution guidance.
4. **Blocks deployment on conflicts**: When conflicts are detected, bootstrap exits with code 5 and deployment is blocked until conflicts are manually resolved.
5. **Supports dry-run**: Use `specrew init --dry-run` to preview changes and generate a reviewable report artifact before applying them.

### Brownfield Dry-Run Artifact

When running `specrew init --dry-run` in brownfield mode, Specrew creates a timestamped report artifact at `.specrew\bootstrap-dry-run-{timestamp}.md` containing:

- Brownfield analysis summary (preserved specs, roles, ceremonies)
- Detected conflicts with resolution guidance
- Warnings and recommendations
- Planned actions that would be performed during actual bootstrap

This artifact provides a reviewable record of the brownfield merge plan before committing to changes.

### Brownfield Merge Analysis

Run `extensions\specrew-speckit\scripts\brownfield-merge.ps1` directly to analyze an existing project's compatibility with Specrew:

```powershell
pwsh -File .\extensions\specrew-speckit\scripts\brownfield-merge.ps1 `
  -ProjectPath .\path\to\existing\project `
  -DryRun
```

The analysis reports:

- **Preserved artifacts**: Existing specs, roles, and ceremonies that will not be modified
- **Mergeable content**: Baseline roles and ceremonies that can be safely added
- **Conflicts**: Naming collisions that require manual resolution
- **Canonical roles**: Existing `.squad\agents\` baseline roles preserved as project source when the project itself contains `extensions\specrew-speckit\`
- **Warnings**: Partial platform installations or other non-blocking issues

### Conflict Resolution

If Specrew detects role name conflicts (e.g., an existing "Implementer" role), it:

1. Reports the conflict in the console output
2. Exits with code 5 to prevent deployment
3. Provides guidance to manually merge or rename conflicting roles before re-running bootstrap

The `-Force` flag does NOT bypass conflict checks. Conflicts must be manually resolved before bootstrap can proceed.

Self-hosting Specrew repositories are the exception to the baseline-role conflict rule. When a project contains `extensions\specrew-speckit\` and existing `.squad\agents\`, those baseline agent directories are treated as canonical project source, not conflicts to overwrite. Non-self-hosting projects keep the normal protection behavior.

1. Record event in `drift-log.md` with exact requirement reference.
2. Decide one resolution path:

- Update spec (tracked change)
- Rework implementation
- Escalate for human decision

1. Reflect the decision in `review.md` verdict notes and next tasks.

## Boundary Commit Discipline

Specrew lifecycle work flows through several boundaries — specify, clarify, plan, tasks, implementation, review-signoff, retro, iteration-closeout, and feature-closeout. At each boundary, the Crew (the agent team executing the lifecycle) produces artifacts: spec.md, plan.md, code, tests, review.md, retro.md, closeout-dashboard.md, decisions ledger entries, and more.

**Commit at every boundary. Push after every commit.** This is the methodology's commit discipline:

- At every lifecycle boundary, the Crew commits the boundary-phase work in semantic commit groups BEFORE invoking `Invoke-SpecrewBoundaryStateSync` or signaling boundary readiness. Working-tree-only changes are not durable boundary evidence — a power loss, working-tree corruption, or `git clean -fd` would erase them.
- After every commit, the Crew pushes the feature branch to `origin/<feature-branch>` immediately. Local-only commits are not upstream-backed-up; a workstation failure loses them.
- The Crew verifies `git rev-parse HEAD` equals `git rev-parse origin/<feature-branch>` BEFORE signaling boundary readiness. The committed evidence reference (commit SHA or hash range) appears in the boundary handoff's `What I just did` section.
- If no `origin` remote is configured (e.g., a local-only project), push silently skips. Commit discipline still applies.

### Why it matters

Without this discipline:

- Boundary-sync's validator passes because it reads working-tree content, but anyone cloning the branch from origin sees no work. The methodology claims discipline it doesn't deliver.
- Premium agent quota is wasted on rejection-redo cycles when boundary signals are issued before the work is committed.
- Audit trail (`.squad/decisions.md`, scribe logs, retro evidence) drifts from actual git history, making methodology evolution decisions harder.

### Per-role responsibilities

- **Implementer** is the primary committer for implementation work. Commits in semantic groups before invoking boundary-sync at implementation → review-signoff.
- **Spec Steward** oversees boundary-commit discipline at every advancement decision. Verifies push parity before signing off.
- **Reviewer** rejects PRs containing WIP at PR-open time as a hard reject. Commit + push first, then re-request review.
- **Retro Facilitator** evaluates commit-discipline at retro and records `boundary-commit-discipline-violations` count as a standard signal.
- **Planner** anticipates commit cadence in plan.md output; each boundary's tasks map to a semantic commit group.

### Enforcement layers

This discipline ships in three tiers:

- **Tier 1 (text-only, this release)**: explicit instructions in the Coordinator governance prompt + all 5 baseline agent charters + this section. The discipline is conveyed; the Crew applies it.
- **Tier 2 (future)**: a validator rule (`boundary-wip-uncommitted` at warning severity) flags WIP-at-boundary in `validate-governance.ps1` output. Surfaces violations without blocking.
- **Tier 3 (future)**: `Invoke-SpecrewBoundaryStateSync` refuses to advance if WIP is present. Auto-push hook after every commit (configurable via `iteration-config.yml`).

Each tier is its own slice; Tier 1 ships first as a methodology-text addition, Tier 2/Tier 3 follow as later releases when empirical data justifies the additional enforcement weight.

## Refocus — Drift Recovery + Automatic Discipline Injection (Feature 171)

Long sessions drift: compaction destroys methodology context, cold launches never load it, and stage discipline goes stale across lifecycle gates. The refocus surface fixes all three:

- **Manual recovery (every host)**: run `/specrew-refocus` any time — no-args loads the always-true core + the current stage's discipline digest; `--boundary <stage>` and `--role <name>` scope it; `--status` shows the operational truth (kill switches, breaker state, injection journal); `--compact-instructions` emits a paste-ready `/compact` preserve-list built from live lifecycle state.
- **Boundary-cross injection (every host, mechanical)**: every boundary sync appends the INCOMING stage's digest to its own output — treat any `[specrew-refocus]` block in tool output as binding stage discipline.
- **Hook triggers (per host, per the verified matrix)**: Claude re-injects after compaction and on session start; Codex binds the full triad (post-compaction, launch, and per-prompt boundary checks); Copilot and Cursor re-ground on session start. Antigravity has bounded project hook support through `.agents/hooks.json`: `PreInvocation` injects the bootstrap message and `Stop` returns the handover decision. If those hooks do not fire, recover with `specrew start --host antigravity`. Hooks deploy to PER-USER config where the host supports it; Antigravity's supported slice is project-local and merge-aware. All hosts respect a recorded opt-out.
- **Safety**: a per-session circuit breaker trips on runaway injection (loudly once, with re-enable guidance); kill switches at three levels (`SPECREW_REFOCUS_DISABLE=1` env, per-trigger `enabled: false` in `refocus-scopes.json`, hook de-registration via `specrew hooks remove`); `specrew update` never silently flips a disable decision in either direction.

## Session Continuity — Auto-Bootstrap, Rolling Handover, Host Switching

Sessions end — you `/exit`, close a window, hit a crash, or simply switch to a different AI host. Specrew treats every restart as a resume problem, so the next session starts where the last one stopped instead of asking "what do you want to build?".

- **Auto-bootstrap (the way in)**: once `specrew init` has set things up, you just launch your host (run `claude`, `codex`, `copilot`, `cursor-agent`, or `agy`) inside the project. Specrew greets you with an orientation banner, reminds the agent of the governed lifecycle, and surfaces where you left off. You no longer need to run `specrew start` to get going — launching the host is the front door. Antigravity has bounded project-hook bootstrap when `.agents/hooks.json` fires; `specrew start --host antigravity` remains the recovery path if it does not.
- **Rolling handover (the way out)**: as you work, Specrew keeps a single up-to-date handover file on disk that captures what the agent just did, why it stopped, where to pick up next, and the context the next session needs. It is refreshed as you go and written safely, so even an abrupt shutdown leaves a usable resume point rather than a corrupted one. This file — together with the rest of your work, which lives in files on disk — is what makes your progress durable: it follows the project, not the agent's memory.
- **You resume right where you stopped**: on every launch Specrew reads your committed work and that handover, then tells the agent concretely where to continue — "resume the design workshop at the next remaining lens" or "the workshop is done; you're at the approval gate". Because your work lives on disk, even a hard crash can lose a little of the most recent conversation but never the work itself.
- **Switching hosts mid-feature**: the handover is portable across hosts. Exit one host, launch a *different* one in the same project, type `continue`, and the new session picks up the same feature at the same spot — your work follows you. One behavior note: if you switch to a non-Claude host and resume right at an approval boundary, the new session may ask you to re-confirm your last approval before it moves on. That is a safety choice, not a loss of progress — your work and your place are intact.
- **Approvals stay real through every resume**: resuming never lets the agent skip a gate. A boundary that was reached but not yet approved still surfaces as awaiting your verdict on the next launch, a bare `continue` never auto-advances past it, one approval advances at most one boundary, and the agent never invents your approval. Stopping and resuming — even in a different host — changes none of that.

## What's Coming

The next release queue focuses on intake quality, expert-developer ergonomics, and multi-host expansion. Active proposals worth tracking:

- **F-040 / Proposal 069 — Multi-Host Launch Path (SHIPPED v0.26.0)**: `specrew start --host claude|codex|copilot` launches the alternate CLI with Specrew's bootstrap context. Per-host flag translation (`--remote`, `--allow-all`, `--autopilot`) + universal Crew-coordinator prompt header + Squad-runtime-path directive strip for non-Copilot + Codex pwsh-form boundary-advance instructions. Tactical MVP slice of [Proposal 024](../proposals/024-multi-host-runtime-abstraction.md) (Multi-Host Runtime Abstraction). Composes with Proposals 068 (cost-aware model routing) and 070 (token economy MVP). See "Multi-Host Launch" section below for the per-host flag matrix.
- **Proposal 063 — Substantive Intake Questioning**: persona-driven adaptive intake (PM / UX / Architect / Researcher), 12-category catalog, Mode A/B/C input-quality assessment. Fires at `/speckit.specify`, `/speckit.clarify`, iteration kickoff, mid-feature pivot. The intake interview that stops the Crew from auto-resolving scope decisions silently. Source: [Proposal 063](../proposals/063-substantive-intake-questioning.md).
- **Proposal 099 — Installed-File SDLC Instruction Audit**: closes the dogfooding deficit between paste-prompt scaffolding and the discipline carried by installed instruction files (coordinator-governance.md, agent charters, sync command docs). Three small-fix closure slices identified: recognized verdict shapes catalog, reconciliation directive, smaller refinements bundle. Source: [Proposal 099](../proposals/099-installed-file-sdlc-instruction-audit.md).
- **Proposal 100 — Friction Dial**: three canonical modes (strict / default / autonomous) controlling verdict-parser acceptance, reconciliation posture, drift-log granularity, and compound-verdict eligibility. Composes Proposals 015 + 047 + 066 into a coherent surface. Persistence in `.specrew/config.yml`; session override via `specrew start --friction <mode>`. Source: [Proposal 100](../proposals/100-friction-dial.md).
- **Proposal 068 — Cost-Aware Model Routing** + **Proposal 070 — Token Economy MVP**: agent-discovered model catalog routes Junior/Implementer tasks to cheap models, Senior/Reviewer tasks to strong. `cost.yml` per iteration tracks token consumption + cost estimate; `specrew where` dashboard gains a COST section. Sequenced as F-041 + F-042 (next features after F-040).
- **Proposal 104 — Multi-Host Onboarding + Selection Flow**: first-run host probe + `.specrew/host-history.yml` for last-host default + `specrew host` command. UX layer on top of F-040. Sequenced as F-043. Source: [Proposal 104](../proposals/104-multi-host-onboarding-and-selection-flow.md).
- **Proposal 105 — Host-Native Hook Deployment**: elevate F-039 boundary enforcement from cooperative to runtime on hook-supporting hosts. Claude, Codex, Copilot, Cursor, and Antigravity now have verified hook slices where the host exposes the needed events; Antigravity remains bounded to project `.agents/hooks.json` `PreInvocation` and `Stop`. Source: [Proposal 105](../proposals/105-host-native-hook-deployment.md).
- **Proposal 098 — Launch Posture Visibility (candidate)**: surfaces enforcement state (`[BYPASS ACTIVE]` indicator, active friction mode) at `specrew start` banner. Companion to Proposal 100 and Proposal 065.

Full proposal catalog with status (Shipped / Draft / Candidate) lives at [proposals/INDEX.md](../proposals/INDEX.md).

## Practical Operating Notes

- Treat the spec as source of truth.
- Keep artifacts small and current; avoid end-of-iteration backfilling.
- Use `validate-governance.ps1` before closing an iteration.

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

The process-quality scorer is an internal regression helper and is exercised
through the CI integration tests rather than a public `evaluation/` surface.

## Troubleshooting

### Copilot CLI "Failed to load N skills" warning at startup

If you see this warning after `specrew init`, it is an upstream Copilot CLI behavior, not a Specrew issue. Copilot CLI scans `~/.claude/skills` and `~/.agents/skills` in your home directory. If you also use Claude Code or OpenCode, those directories may contain skills with colon-delimited names such as `ck:foo`; Copilot CLI's parser rejects those names because it only accepts letters, numbers, hyphens, underscores, dots, and spaces.

Specrew's own slash-command surface (`/specrew-where`, `/specrew-help`, `/specrew-version`, `/specrew-update`, `/specrew-team`, `/specrew-review`, `/specrew-status`) uses hyphenated names and is unaffected. To confirm a Specrew skill loaded correctly, run `/skills info specrew-help` inside the Copilot CLI session and verify that Copilot reports the expected Specrew skill path and metadata.

Upstream tracking: <https://github.com/github/copilot-cli/issues/2689>. Copilot CLI does not currently provide a config switch to exclude those directories from scanning. The warning is cosmetic and does not block Specrew's own skills from working.

## Multi-Host Launch (v0.27.0+)

`specrew start --host <kind>` launches the lifecycle on the named CLI runtime. Supported kinds: `copilot` (`--host` flag default), `claude`, `cursor`, `codex`, `antigravity`. The interactive menu (shown when `--host` is omitted in a TTY) lists installed hosts in priority order Claude → Cursor → Codex → Copilot → Antigravity.

```powershell
specrew start --host claude "Build a TODO list app"
specrew start --host cursor "Add a health-check endpoint"
specrew start --host codex "Fix the auth bug"
specrew start --host antigravity "Add precision-aware arithmetic to the calculator"
specrew start --host copilot           # Equivalent to no --host flag
```

### Per-host flag translation matrix

Specrew translates user-facing Specrew flags to host-appropriate CLI flags. The user-facing surface stays uniform across hosts.

| Specrew flag | Copilot | Claude Code | Cursor | Codex CLI | Antigravity |
|---|---|---|---|---|---|
| `--remote` | `--remote` | `--remote-control` | (warn-and-continue, no remote wiring) | (warn-and-continue, no remote wiring) | (warn-and-continue, no remote wiring) |
| `--allow-all` | `--allow-all` | `--dangerously-skip-permissions` | `--force` | `--dangerously-bypass-approvals-and-sandbox` | `--dangerously-skip-permissions` |
| `--autopilot` | `--autopilot` | (drop with notice — use `--autonomous` for unattended runs) | (folds into `--force`) | (folds into `--dangerously-bypass-approvals-and-sandbox`) | (drop with notice — use `--autonomous` for unattended runs) |
| `--autonomous` | (Specrew-side only — handled by lifecycle boundary enforcement per F-039; not translated per-host) | | | | |

### Per-host launch invocation shape

The bootstrap-context handshake ("Read `.specrew/last-start-prompt.md` and `.specrew/start-context.json`") is identical across all hosts. Only the host-CLI invocation differs.

```text
copilot:     copilot --agent Squad --add-dir <project> -i <bootstrap-prompt> [--allow-all] [--autopilot] [--remote]
claude:      claude -p <bootstrap-prompt> --add-dir <project> [--dangerously-skip-permissions] [--remote-control]
cursor:      cursor-agent <bootstrap-prompt> --workspace <project> [--force]
codex:       codex exec --cd <project> [--dangerously-bypass-approvals-and-sandbox] <bootstrap-prompt>
antigravity: agy -i <bootstrap-prompt> --add-dir <project> [--dangerously-skip-permissions]
```

### Coordinator-prompt rewrite per host (FR-011 / FR-012)

The opening line of the coordinator prompt is universal across all hosts: `"You are the Crew team coordinator running inside a Specrew-bootstrapped repository."` This aligns with the project terminology: **"the Crew"** is the team role (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator); **"Squad"** is the npm runtime product (one of several possible Crew runtimes).

For non-Copilot hosts, Specrew additionally strips directives that reference Squad-specific runtime paths (`.squad/decisions.md`, `.squad/config.json`, `agentModelOverrides`, `sync-squad-model-overrides.ps1`) since those paths don't exist when running outside the Copilot/Squad runtime.

For **Codex and Cursor** specifically, Specrew rewrites slash-command boundary-advance references (e.g., `/speckit.specrew-speckit.sync-plan`) to direct PowerShell invocations (`pwsh -File .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 -BoundaryType plan`) because neither has a user-defined slash-command surface.

### Host-enforcement asymmetry (FR-015)

F-039 (Launch-Mode Boundary Enforcement) is **cooperative**, not runtime-enforced. The boundary-authorization gate fires only when the agent invokes Specrew's canonical sync path:

- **Copilot, Claude**: Slash command `/speckit.specrew-speckit.sync-<boundary>` → boundary-state-sync script → authorization helper. Discoverable, mechanical.
- **Codex and Cursor**: Direct `pwsh -File ...` invocation (per FR-014 rewrite) → boundary-state-sync script → authorization helper. Less discoverable, but functionally equivalent.
- **Antigravity**: Project `.agents/hooks.json` handles the verified bootstrap/handover slice, and the lifecycle still advances through the same boundary-state-sync script. If Antigravity hooks do not fire, `specrew start --host antigravity` re-anchors the session through the same artifacts.

In all cases, if an agent writes directly to `.specrew/start-context.json` boundary_enforcement section without going through the canonical path, no gate fires. Runtime enforcement (host-layer interception of any write to boundary state) is **out of scope for F-040** and tracked as [Proposal 105](../proposals/105-host-native-hook-deployment.md). When Proposal 105 ships, Claude Code's PreToolUse hook layer can elevate F-039 from cooperative to runtime enforcement.

**Recommendation**: strict-mode users should prefer Copilot or Claude over Codex until Proposal 105 ships, because Copilot/Claude's slash-command surface makes the canonical path easier for agents to discover and invoke. Codex still works correctly when the agent follows the FR-014 pwsh-form instructions in the coordinator prompt.

### Per-host capability differences (research.md Task 5)

| Capability | Copilot | Claude | Cursor | Codex | Antigravity |
|---|---|---|---|---|---|
| User-defined slash commands | ✅ `.github/skills/<name>.md` | ✅ `.claude/skills/<name>/SKILL.md` | ❌ **Not supported** (skills deploy as `.cursor/rules/*.mdc` context) | ❌ **Not supported** | ✅ `.agents/skills/<name>.md` |
| Hooks (PreToolUse, etc.) | ✅ Session-start refocus/bootstrap | ✅ Rich, configured in `.claude/settings.json` | ✅ Session-start refocus/bootstrap | ✅ Full refocus triad | ⚠️ Bounded `.agents/hooks.json` support: `PreInvocation` bootstrap + `Stop` handover decision; use `specrew start --host antigravity` if hooks do not fire |
| Subagents (multi-agent teams) | ⚠️ Via `--agent <name>` (Squad) | ✅ `.claude/agents/*.md` | ⚠️ Crew charters deploy as `.cursor/rules/*.mdc` (no native agent picker) | ✅ `.codex/agents/*.toml` | ✅ `.agents/agents/*.md` |
| MCP server config | ⚠️ Limited (recent) | ✅ `.mcp.json` first-class | ✅ `cursor-agent mcp` + `--approve-mcps` | ✅ `.codex/mcp.toml` first-class | ⚠️ Unverified at graduation time |
| Project memory | ⚠️ None native | ✅ `CLAUDE.md` | ✅ `AGENTS.md` | ✅ `AGENTS.md` | ⚠️ Unverified at graduation time |

F-040 managed skills + slash commands (uniformly via existing F-021 multi-host deploy) and deferred hooks, MCP, project memory, and subagents to later work. Current Specrew releases add hook-driven bootstrap/refocus where verified; Antigravity's current slice remains bounded to `PreInvocation` bootstrap and `Stop` handover decisions.

### Cursor host interaction model (F-050)

Cursor's host is the standalone **`cursor-agent`** CLI (not the `cursor` editor launcher). `specrew start --host cursor "<feature>"` runs `cursor-agent "<prompt>" --workspace <project>` — an **interactive** Agent session (the developer drives the lifecycle), matching Claude/Codex/Antigravity rather than the headless `cursor-agent --print` scripting mode. Key differences from the slash-command hosts:

- **No slash palette.** Cursor has no user-typed `/speckit.*` commands (`HasUserSlashCommandSurface = $false`, same as Codex). The lifecycle is driven by the **`AGENTS.md`** coordinator prompt; Speckit skills + Crew role charters deploy as **`.cursor/rules/*.mdc`** Project Rules — auto-attached *context*, not an invokable command surface. The Crew therefore uses pwsh-form boundary-advance instructions (the FR-014 rewrite, shared with Codex).
- **Auto-approve.** `--allow-all` maps to `cursor-agent --force` (run-everything). `--trust` is headless-only (works only with `--print`) and is **not** used in the interactive launch.
- **Detection.** `cursor-agent` must be on PATH (install + verify: [cursor.com/cli](https://cursor.com/cli), `cursor-agent --version`, `cursor-agent login`); otherwise `specrew start --host cursor` exits with install guidance instead of launching. Cursor sits at menu priority **1.5** (between Claude and Codex).
- **Out of scope (v2 follow-up).** `--plugin-dir` plugin packaging — the first slice maps Speckit onto Cursor's native rules surface; richer plugin integration can follow.

### Antigravity host interaction model

Antigravity's host binary is **`agy`**. After `specrew init`, the primary path is to run `agy` in the project and type your feature request or `continue`; the project `.agents/hooks.json` slice injects Specrew's bootstrap when Antigravity fires `PreInvocation`, and `Stop` records the handover decision.

- **Resume.** `agy -c` resumes the latest Antigravity conversation, and `agy --conversation <id>` resumes a specific conversation. This is native Antigravity conversation state; Specrew's durable source of truth remains the project artifacts and rolling handover.
- **Explicit Specrew launch.** `specrew start --host antigravity "<feature>"` launches `agy -i <bootstrap-prompt> --add-dir <project>` and remains the fallback when project hooks do not fire.
- **Auto-approve.** `--allow-all` maps to `agy --dangerously-skip-permissions`. If you launch Antigravity directly and want to skip tool permission prompts, run `agy --dangerously-skip-permissions` from the project root. This affects tool-call approval only; it does not bypass Specrew lifecycle boundaries.
- **Sandbox.** Antigravity also exposes `--sandbox`, which enables terminal restrictions. That is separate from Specrew's `--allow-all`; use it when you want a constrained Antigravity terminal session, not when you want to auto-approve tools.
- **Hooks.** Current Specrew support is bounded to project-local `.agents/hooks.json` with `PreInvocation` bootstrap and `Stop` handover decisions. If those hooks are missing, stale, opted out, or simply do not fire in a particular Antigravity build, run `specrew hooks status` / `specrew hooks install --host antigravity`, or recover with `specrew start --host antigravity`.

### Missing-host guidance

If you invoke `specrew start --host claude` but Claude Code is not installed on PATH, Specrew exits with the install URL for that host and a non-zero exit code. No CLI is launched. Same behavior for `--host codex` when Codex CLI is missing.

`--host antigravity` is supported. Launch shape: `agy -i <prompt> --add-dir <path> [--dangerously-skip-permissions]`. If you are not using `specrew start`, run `agy` directly in the project and type your request or `continue`. `--host auto` is still accepted by the parser but rejected with explicit "deferred to follow-up" guidance pointing to [Proposal 104](../proposals/104-multi-host-onboarding-and-selection-flow.md) (auto-selection logic). When `--host` is omitted entirely, Specrew shows an interactive numbered menu listing installed hosts first and "(not installed)" hosts with install URLs.
