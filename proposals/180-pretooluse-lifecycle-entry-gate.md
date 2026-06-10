---
proposal: 180
title: PreToolUse Lifecycle-Entry Gate — non-discretionary enforcement of lifecycle ENTRY at the first implementation tool call (Claude Code) — RESEARCH-NEEDED
status: candidate
phase: phase-2
estimated-sp: 8-15 (detection-design-dependent; see Research Needed)
priority-tier: 2
discussion: surfaced 2026-06-10 during the Feature 174 cross-host handover-validation dogfood. Same greenfield task (a C skip-list library, "homework, my choice of data structure") on three hosts from the IDENTICAL SessionStart bootstrap contract — Copilot ran a full discovery workshop (7 lens records + spec + checklist), Codex ran a real one (spec + 2 lenses), and Claude free-ran the 54KB contract entirely (no spec, no workshop, no lenses, straight to writing skiplist.h). The mandatory orientation banner was already hoisted to the TOP of the contract and still did not bind Claude. A controlled, artifact-corroborated three-way comparison.
---

# PreToolUse Lifecycle-Entry Gate (Claude Code)

## Why

Feature 174 made the SessionStart hook **deliver** a full launch contract on every host — the orientation
banner, the lifecycle table, the design-workshop pointer, "you DRIVE the gates and do NOT free-run the SDLC."
The F-174 cross-host dogfood proved **delivery is solved** but **adherence is host-variable**, and Claude is the
outlier: on the identical small task, from the identical 54KB contract, Copilot and Codex both entered the
discovery workshop and wrote a spec, while **Claude bypassed the entire governed lifecycle** — it never invoked
`/speckit.specify`, never ran the workshop, and went straight to the implementation tools (`Write skiplist.h`).
This is artifact-corroborated (the codex/copilot trials have `spec.md` + `workshop/` lens records; the Claude
trial has only an initial commit) and not n=1 — it is a same-task, same-contract controlled comparison.

The existing enforcement does **not** catch this:

- **Proposal 065** (shipped F-039, *Launch-Mode Boundary Enforcement*) gates the boundary-**advancing skills** —
  `Test-SpecrewBoundaryAuthorization` throws inside `/speckit.plan`, `/speckit.tasks`, etc. unless the prior
  boundary was authorized. But it gates the **skills**: if the agent never **calls** a lifecycle skill, no
  skill-gate ever fires. 065 stops over-**advance** *within* the lifecycle; it is silent when the agent never
  **enters** it.
- **Proposal 150 Item 3** (candidate, *"Next authorized action only" prompt block*) adds a prompt-layer block at
  the top of `last-start-prompt.md` telling the agent the single allowed next action. But it is **prose in the
  model's context** — the exact thing Claude skimmed when it skimmed the whole 54KB contract.
- **Proposal 066** (shipped, *Gate-Respecting Default*) is host-autopilot posture — irrelevant when the agent is
  not on autopilot and simply *chooses* to start coding.

The gap: **nothing enforces lifecycle ENTRY at the layer where it matters — the implementation tool call
itself.** Every existing lever is either gating skills the agent declines to call, or prose the agent can skim.

This is the same lesson **Proposal 165** drew for render-before-a-menu: prose in-context can be skimmed; the only
**non-discretionary** lever is a PreToolUse hook that lives in the Claude Code runtime, *outside* the model's
context, and gates the tool call itself. 180 applies that lever to **lifecycle entry**.

## What

A Claude Code **PreToolUse hook** matched to the **implementation tools** (`Write`, `Edit`, `MultiEdit`, and
code-creating `Bash`) that — when the project is a Specrew-bootstrapped repo with an **active feature whose
specify/plan gates have not been passed** — **denies (or downgrades to `ask`)** the first source write, returning
a reason the model must satisfy: *"enter intake first — run the design workshop and `/speckit.specify` before
writing implementation."* The gate **biases hard to allow**.

### Mechanism

- **Rides the existing dormant gate-provider seat.** The dispatcher already has a `kind == 'gate'` path
  (PreToolUse, returns `allow`/`deny` `permissionDecision` — the F-165 forward-compat seat, the same one
  Proposal 165 keys on for `AskUserQuestion`). No new host wiring; a second gate provider registers for
  `PreToolUse` with an implementation-tool matcher.
- **The hook receives** `tool_name`, `tool_input` (the target path + content), and the session state.
- **Detection** (the crux — see Research Needed):
  1. **Is this an implementation-class action?** `Write`/`Edit`/`MultiEdit` on a *source* file, or a
     code-creating `Bash`. Edits to governance artifacts (`specs/`, `.specrew/`, proposals, docs) are NOT
     implementation and pass.
  2. **Is lifecycle entry owed?** Read `.specrew/start-context.json` (the `boundary_enforcement` state Proposal
     065 already maintains): if the session is anchored to a feature with **no `spec.md` / no workshop record**
     and the agent reaches for a source write, that is a lifecycle-entry skip.
- **Decision:** `deny` (or `ask`) with the enter-intake reason. **Bias to allow** — a wrong deny that blocks
  legitimate work is worse than a missed skip.
- **Default-allow** everything else: non-Specrew repos, a session explicitly marked "quick task / you decide",
  governance-artifact writes, reads, and a feature already past `tasks`.

### This is NOT 065 / 150 / 165 (composition)

| Lever | Layer | What it catches |
| ----- | ----- | --------------- |
| 065 (shipped) | the boundary-**advancing skills** | over-**advance** *within* the lifecycle |
| 150 Item 3 (candidate) | **prompt prose** (in-context) | teaches the next allowed action; skimmable |
| 165 (candidate) | PreToolUse on **`AskUserQuestion`** | render-before-a-menu skim |
| **180 (this)** | **PreToolUse on `Write`/`Edit`** | never-**ENTER** the lifecycle |

180 **reuses** 065's `start-context.json` authorization state to know whether entry is owed, and is the
out-of-context **enforcement** for when 150 Item 3's in-context prose is skimmed. It is to 150-Item-3 what 165 is
to the workshop-conduct prose. 165 and 180 are **sibling** PreToolUse gates on the same dormant seat.

### Host posture

**Claude-only by design.** Hooks are a Claude Code feature; Copilot and Codex entered the workshop naturally in
the dogfood, so the skip is Claude-specific and they do not need it. This composes with the host-neutral
contract per the **Proposal 145** matrix: the bootstrap *teaches* every host, validators/hooks *enforce* where
the host supports them. 180 is a Claude-only enforcement accelerator layered on the host-neutral bootstrap.

## The crux: WHEN is a first-write a governance-skip vs a legitimate quick task? (RESEARCH-NEEDED)

Gating `Write`/`Edit` is **far more intrusive** than gating `AskUserQuestion`. The skip-list homework was
arguably reasonable to *just do* — a one-file exercise the user wanted done. A gate that fires on EVERY greenfield
first-write is worse than the disease, and it would cut against Specrew's own posture (Specrew fights
**under**-engineering; it must not impose ceremony on a genuinely small task). The decisive design question is
the same shape as 165's detection problem:

1. **Marker-driven vs heuristic.** The clean design has the bootstrap set an explicit
   `lifecycle_entry_required` marker in `start-context.json` when it anchors a governed feature, cleared when the
   specify boundary is passed — turning the hook's fuzzy "should this have been governed?" into a **deterministic
   flag check**. The alternative (the hook infers implementation-class + no-spec from repo state) is fuzzier and
   higher false-positive.
2. **The "just do it" escape MUST be one keystroke.** There has to be a low-friction way for the user to say
   "this is a quick task, skip governance" — a session flag, a verdict, or the gate downgrading to **`ask`** (a
   one-key permission prompt) rather than a hard `deny`. The skip-list case should be a single keystroke to
   proceed, not a wall.
3. **Which tools, which paths.** Source writes yes; governance-artifact writes no; reads never. The matcher +
   path classification need care to avoid gating legitimate scaffolding.
4. **Deny vs ask.** `ask` is gentler than deny-and-retry: it preserves the user's ability to just-do-it while
   still **surfacing** that governance was skipped — arguably the better default for a gate this intrusive.
5. **Does it earn its keep?** Is reliable lifecycle entry on Claude worth host-specific machinery given the cost
   of a false block? The maintainer must clear that bar (165 set the same bar for itself).

## Research Needed (before spec conversion)

1. **Marker design** — the `lifecycle_entry_required` flag's lifecycle (set at bootstrap-anchor, cleared at the
   specify boundary), and how the hook reads it deterministically. Validate against transcript/repo-state
   heuristics on robustness, testability, and false-positive rate.
2. **The Claude Code PreToolUse contract** — confirm the current stdin schema and the `deny`/`ask`
   `permissionDecision` output shape against the live docs, plus the `.claude/settings.json` matcher shape for
   `Write`/`Edit`/`MultiEdit`/`Bash`.
3. **Deployment** — the settings entry + provider registration land downstream **without clobbering** a user's
   own hooks; mirror-parity (Proposal 132) for the gate-provider artifact.
4. **The escape-hatch UX** — exactly how the user signals "quick task, skip" (flag vs verdict vs `ask`-prompt),
   and how that state is recorded so the gate stays quiet for the rest of the session.
5. **Scope** — Claude-only, or design the provider interface so Codex/Gemini hook surfaces (per 145's matrix) can
   add parallel adapters later. Keep v1 Claude-only.

## Sizing

~8–15 SP, detection-design-dependent (the bulk is the detection + the escape-hatch UX, mirroring 165): the gate
provider + matcher, the marker plumbing in the bootstrap + `start-context.json`, the `.claude/settings.json`
deploy wiring (merge, not overwrite), tests (deny/ask fires on an unentered governed feature's source write,
allows a governance-artifact write, allows a quick-task-flagged session, allows a non-Specrew repo), and a
Claude-host dogfood (the skip-list-class task now surfaces intake before the first source write). Lower end if
marker-driven (deterministic); upper end if the detection must reason from repo state heuristically.

## Open questions

1. Marker-driven (the bootstrap emits `lifecycle_entry_required`, the hook checks it) vs heuristic (the hook
   infers from repo state)? Marker is more deterministic and testable.
2. `deny`-and-retry vs `ask` (downgrade to a permission prompt the human resolves with one key)?
3. What is the exact "quick task / skip governance" escape, and how is it recorded for the session?
4. Which tool/path matchers count as "implementation" vs "governance/scaffolding"?
5. Stay Claude-only, or design for parallel Codex/Gemini hook adapters later (per 145's host matrix)?

## Risks

- **False positives blocking legitimate work** — the dominant risk; the gate must bias hard to allow, and
  `ask`-not-`deny` + the one-key escape are the mitigations.
- **Over-process on small tasks** — Specrew fights under-engineering, not over-engineering; a too-eager entry
  gate could feel like ceremony on a genuinely quick task. The escape hatch is **load-bearing**, not optional.
- **Host-specific + maintenance** — Claude-only, rides Claude Code's evolving hook API; needs a currency check.
- **Deploy collision** — injecting the `PreToolUse` entry into `.claude/settings.json` must merge with, not
  overwrite, a user's hooks.
- **Scope creep** — "a general governance gate on all writes" could balloon; keep v1 to the first-source-write
  lifecycle-entry case.

## Cross-references

- **Sibling:** [165](165-pretooluse-render-gate-hook.md) (PreToolUse render-gate — same dormant seat, same
  research posture, same Claude-only enforcement-accelerator framing).
- **Complements:** [065](065-launch-mode-boundary-enforcement.md) (shipped F-039 — boundary-**advance** gate;
  180 reuses its `start-context.json` state), [150](150-agent-support-hardening-bundle.md) Item 3 (candidate —
  the in-context prompt block 180 enforces out-of-context).
- **Posture:** [145](145-structured-multi-phase-reviewer.md) (host-capability matrix — teach vs enforce),
  [146](146-specrew-refocus-slash-command.md) (sibling Claude-hook use).
- **Empirical:** the Feature 174 cross-host handover-validation dogfood (2026-06-10) — Claude lifecycle-entry
  skip, artifact-corroborated against the codex/copilot trials.
- **Infra:** the dispatcher's dormant gate-provider seat (F-165 forward-compat, `kind == 'gate'` PreToolUse).
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md

## Status history

- 2026-06-10: captured as candidate from the Feature 174 cross-host dogfood (Claude bypassed lifecycle entry on
  the same task Copilot and Codex governed). RESEARCH-NEEDED: the detection ("governance-skip vs legitimate quick
  task") is the crux; convert to a spec only after the marker-vs-heuristic design and the escape-hatch UX are
  settled.
