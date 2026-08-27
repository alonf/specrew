---
proposal: 214
title: Governed Skills Lens
status: candidate
phase: unphased
estimated-sp: 8-12
discussion: tbd
---

# Governed Skills Lens

## Why

Skills are becoming the distribution unit for agent capability: Anthropic's skill format in
Claude Code, GitHub Copilot's plugin marketplace (`plugin marketplace add`, `plugin install`),
`npx skills add`, and curated publisher repositories such as `microsoft/skills`. A project whose
stack is known — .NET on Azure, a React SPA, a Python data service — has well-known skills that
would materially help every implementing session, and today nothing in the lifecycle ever asks
whether they should be installed. Consumers either don't know the ecosystem exists or install
things ad hoc, outside any record.

At the same time, **installing a skill is injecting standing instructions into every future
agent session of the project** — exactly the class Specrew exists to govern: authority entering
sessions from outside the human's explicit decisions. The beta3 stabilization record shows what
agents do with instruction text: a single ambiguous sentence in Specrew's own launch contract
("once implementation approval is granted") was resolved by a weak model into unauthorized
product code. A third-party skill is that same risk surface — unaudited, from an untrusted
author, silently versioned. An ungoverned install path would be a prompt-injection on-ramp
wearing a convenience feature's clothes.

Specrew already owns both halves of the solution: the design workshop knows the project's
domain and stack at exactly the right moment, its consent machinery (visible prose, typed
replies, dismissed-picker-is-absence) is the approval flow a choosing step needs, its
deployment machinery already writes skills across four host directories per project, and the
deployed-runtime integrity pattern (marker plus content hash, drift refused) extends naturally
to third-party content.

## What

**Not a lens of its own.** A capability the workshop invokes, with two fixed touchpoints and
demand-driven acquisition between them. This shape is corrected from the original proposal by
field evidence — see *Timing, corrected by the field* below.

**Touchpoint 1 — inventory, once, immediately after product-domain.** Cheap and offline: what is
already installed, project-level and (read-only) user-level, reported per host so coverage gaps
are visible ("this skill exists for claude; this project's crew runs copilot"). No network, no
installs, no decisions. Its purpose is to tell the workshop what expertise it already has, which
is what any later lens needs in order to know what it lacks.

**Between them — acquisition on demand, at the lens that needs it.** The trigger is not a
schedule: it is a lens reaching a question the project's current knowledge cannot answer well,
stated as such. That moment is when a proposal is made and a decision taken.

**Touchpoint 2 — a closing pass before planning**, for implementation-time skills the
code/technology lens identified: tooling, generators, CLIs. A different category, because those
shape how the work is done rather than what is decided.

At every acquisition the capability:

1. **Inventories** what is already installed: project-level skill directories across the host
   mirrors, and (read-only) user-level skill locations, reported per host so coverage gaps are
   visible ("this skill exists for claude; this project's crew runs copilot").
2. **Proposes** relevant skills from a **curated registry first** — known publishers
   (`microsoft/skills`, host marketplaces, an allowlist shipped with Specrew and extensible per
   project) — matched against the workshop's recorded domain and stack. Web search is a later,
   explicitly-flagged fallback, never the default.
3. **Installs only what the human chooses, one typed decision per skill,** with the consequence
   stated on the option (what the skill does, who publishes it, which hosts it serves, where it
   will be written). The lens proposes; the human disposes. No "install the recommended set."
4. **Records provenance as facts**: a skills manifest carrying source, version/commit, content
   hash, approving human, and timestamp for every installed skill — written like every other
   workshop decision, into the governed record.
5. **Verifies integrity thereafter**: the deployed-extension integrity pattern extends to
   manifest-listed skills — a skill whose on-disk content drifts from its recorded hash is
   detected and named, with `re-approve or remove` as the exits. A skill cannot quietly change
   under the project after it was approved.

Project-level install (committed host directories — reviewable, governed, travels with the
repo) is the default and the only target in the first iteration. User-level install
(`~/.claude/skills` and peers) affects every other project on the machine — an outward-facing
act — and requires its own explicitly separate consent in a later iteration, if ever.

Offline-graceful by construction: inventory is local, the registry ships as a bundled snapshot,
and downloads defer with a plain statement rather than failing the lens — the no-network
assumption has already failed silently once in a downstream walk and is treated as the normal
case, not the exception.

### Timing, corrected by the field

The original proposal placed a skills lens **after** the code/technology lens, reasoning that
domain and stack must both be known before skills can be chosen. A dogfood walk on 2026-08-28
disproved that, unprompted and in the first workshop to reach the UI lens.

At **UI/UX — lens 4 of 6** — the agent had to answer "what should this visually follow?" for a
WinUI reactive application and had nothing to follow. The human asked whether skills existed;
the agent found Microsoft's official Reactor skill kit and OpenAI's curated WinUI skill, and the
framework's own `design.md` then shaped the layout decisions. Under the original placement that
guidance would have arrived at lens 6, two lenses after the design it governs.

The premise was wrong in a specific way: **skills are not only implementation aids. They carry
design knowledge that shapes lens decisions.** A schedule cannot know which lens will need them,
because the need is discovered rather than planned — which is why acquisition is demand-driven
and only inventory is scheduled.

### Mid-lens installs change the agent's instructions

The same walk surfaced a hazard nothing had named. The skills were installed **mid-lens**: the
first half of UI/UX ran under one knowledge base and the second half under another, and the
agent said so plainly — it applied the new guidance to the *next* decision in that lens.

That is not wrong; new information mid-conversation is normal. But it is invisible in the record.
The lens artifact reads as one coherent decision set when it was taken under two different sets
of instructions, and a later reader cannot tell whether an early decision would survive the
guidance that arrived after it. Concretely in that walk, the layout sketch was agreed before the
framework's design guidance was read, and nobody checked whether it still held under it.

Requirement: **a lens whose knowledge base changed partway through records that fact**, naming
the acquisition and the decisions that preceded it, so those decisions are flagged for re-check
rather than silently inheriting authority they were not given.

### Functional requirements

High-level capabilities (candidate stage):

- Run inventory once after product-domain; make its result available to every later lens so a
  lens can state what it has before asking for more.
- Accept an acquisition request from any lens, triggered by a stated knowledge gap rather than by
  schedule; produce a record like any other workshop decision (visible prose, typed human
  replies, receipts).
- Record an acquisition against the lens that requested it, with the decisions that preceded it
  in that lens flagged for re-check.
- Inventory installed skills per host directory and render the coverage honestly, including
  host-format mismatches.
- Propose from the curated registry with publisher, description, hosts served, and version
  pinned; require a typed per-skill decision; record declines as decisions too.
- Install to project-level host directories through per-host adapters (skill format differs
  per host); never shell out to third-party installers blindly.
- Write the skills manifest fact-store entries (source, version, content hash, approver,
  timestamp) and extend the integrity check to refuse silent drift against them.
- Fail open into "proposed, not installed" whenever network, registry, or adapter is
  unavailable — the lens records what it could not do.

### Out of scope

- **Web-search skill discovery** in iteration 1 — the trust machinery ships before the open
  web is invited through it.
- **User-level (machine-wide) installs** — outward-facing; separate consent design, later.
- **Skill authoring or publishing** — this lens consumes the ecosystem; Specrew publishing its
  own consumer skills through the same channels is a separate, natural follow-on.
- **Auto-update of installed skills** — version bumps are new approvals, not background acts.
- **Runtime sandboxing of skill content** — out of Specrew's reach; the mitigation here is
  provenance, pinning, integrity, and explicit human choice.

## Effort

- **Iteration 1 (~6 SP)**: inventory at touchpoint 1; the acquisition capability callable from any
  lens with typed per-skill decisions; curated-registry proposal; project-level install via
  claude + copilot adapters; the skills manifest; the integrity extension; and the mid-lens
  knowledge-change record.
- **Iteration 2 (~3 SP)**: remaining host adapters (cursor, codex/agents), registry
  extensibility per project, decline/defer records surfaced at later lenses.
- **Iteration 3 (~2-4 SP)**: flagged web-search fallback with unvetted-source labeling;
  user-level install consent design if demand exists.
- **Total**: ~11 SP (9-13 range).

## Phase placement

Beta4, per the maintainer's direction (2026-08-24). Composes with the workshop consent
machinery, the multi-host skill deployment Specrew already performs for itself, and the
deployed-runtime integrity pattern. Sits in the ecosystem cluster near 211 (Process Advisor)
and 213 (Walk Harness) — and the walk harness is the natural place to adversarially test this
lens's refusal paths before consumers meet them.

## Open questions

- **First registry seed**: `zio-net/skills` is the natural first curated publisher — it installs at
  project scope for Codex and Claude Code (the shape this lens must handle), and its progressive
  code review skill is prior art this project already draws on in Proposals 212 and 215. Reviewing
  this lens's own trust machinery against a skill from a known publisher is the gentlest possible
  first field test.
- **Registry curation ownership**: who maintains the shipped allowlist, and what qualifies a
  publisher — the first governance question of someone else's content.
- **Hash target per format**: a skill may be one file or a directory tree per host; the
  manifest needs a canonical content-hash rule per adapter (the deployed-extension manifest
  already solves this shape once — reuse it).
- **Copilot marketplace mechanics**: `plugin install` manages its own state outside the
  project tree; whether the adapter wraps it or records-and-delegates needs a spike.
- **Skill/lens interaction**: whether installed skills should be surfaced to later lifecycle
  stages (e.g., the implement phase's code-rules skill naming the installed capability set) —
  likely yes, likely trivial, decide at draft stage.
