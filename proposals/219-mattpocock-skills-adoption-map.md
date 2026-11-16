---
proposal: 219
title: Adoption Map from mattpocock/skills - Mechanisms Taken, Re-Expressed for Evidence-Grade Work
status: candidate
phase: phase-2
estimated-sp: 8-13 (this proposal's own scope; adopted mechanisms are sized in their target proposals)
priority-tier: 2
discussion: maintainer conversation 2026-11-08 during Feature 203 - "Look at Matt Pocock's AI Skills, what can we take or learn from that for Specrew"; "search all of our proposals, and see what he has that maps to what we plan, and how and why we should change or add to what we have"; and the governing constraint - "whatever we take, we can't copy his philosophy. Specrew is for the projects where discipline, evidence and maturity are the highest requirements. Medical, defence, aerospace and such, and any other project that wants traceability, responsibility and more."
---

# Adoption Map from mattpocock/skills - Mechanisms Taken, Re-Expressed for Evidence-Grade Work

## Why

[`mattpocock/skills`](https://github.com/mattpocock/skills) is a widely used, MIT-licensed set of 27 small,
composable agent skills for Claude Code, Codex, Copilot and Gemini. Several of its mechanisms are sharper than
the corresponding parts of Specrew's plans: a gated bug-diagnosis loop, a two-axis code review, a retro that
turns mechanical lessons into checks, a project glossary, and rules for writing agent-facing text. A review of
all 217 Specrew proposals (2026-11-08) found that about two thirds of what the repository does is already
planned here, usually less precisely, and two things are real gaps: a shared domain glossary and a gated
diagnosis loop.

### The philosophy is not adopted

The two projects serve different users, and the difference decides how anything is taken.

| | mattpocock/skills | Specrew |
|---|---|---|
| Stated stance | Process frameworks such as Spec-Kit "try to help by owning the process", which takes control away from the developer | The process is the product: enforced boundaries, recorded human authority, and evidence at every step |
| Human role | Steers when they choose to; most skills run with no approval gates (`implement-spec` runs a whole spec with parallel agents and none) | Decides at every boundary by a typed, recorded verdict; nothing advances on the agent's assessment |
| Artifacts | Often ephemeral: reports, handoffs and research go to the OS temp folder; prototypes are thrown away | Durable and committed: every decision, finding and result is re-readable by a later auditor |
| Distribution | Plugins that update themselves | Pinned versions; the instruction text that ran is identifiable |
| Built for | Individual developers who want speed and control | Projects where discipline, evidence and maturity are the highest requirements: medical device software, defence, aerospace, and any project that needs traceability and named responsibility |

Regulated software regimes, for example IEC 62304 for medical device software and DO-178C for airborne
software, expect traceability from requirements through design, code and tests, recorded reviews, and
named accountability for decisions. Specrew does not claim compliance with any of them; it is built so that a
project working under such a regime is not fighting its tooling. A mechanism that is fast because it skips a
record, a gate or a named decision is the wrong mechanism for these users, however good it is elsewhere.

## What

### The adoption rule

A mechanism from outside Specrew is adopted only in a form that passes all five tests. Each target proposal
applies them when it absorbs a mechanism from this map, and the reviewer checks them.

1. **Governed.** It runs inside a lifecycle stage and its boundary, never as a parallel route around one.
2. **Traceable.** Every output cites the requirement, task, finding or drift entry it serves, and is reachable
   from the iteration's artifacts.
3. **Evidenced.** It leaves a durable, committed record that a later reader can re-check: not a chat-only
   statement, not a temp-folder file, not a discarded prototype with no record of what it showed.
4. **Accountable.** Every decision in it is the human's typed decision or a recorded delegation (Proposal 217).
   A recommended default the human accepts is recorded as the human's decision, with the recommendation shown
   (Proposal 053). The agent never proceeds on its own ranking because the human was unavailable.
5. **Reproducible.** Versions are pinned and recorded; no instruction source updates itself between runs.

### Mechanisms adopted, by target proposal

Each row names his form, the Specrew form that passes the five tests, and the proposal that carries it. The
target proposal owns the design and the effort; this map owns the rationale and the adoption rule.

| His skill | Specrew form | Target | Why |
|---|---|---|---|
| `retro` - mechanical lessons become checks | Every retro lesson is classified. A mechanical rule (a banned call, a file location, a required flag) becomes a check by default: a validator rule, hook, lint rule or test, linked to the lesson and the drift entry that motivated it. A judgement call becomes a code rule. Existing checks are read first, and a missing guardrail is itself a finding. | 017 Learning Loop Closure | 017 already wants lessons graduated to enforcement but gives no rule for which. In Feature 203 three written rules failed in one week because nothing enforced them (B5F-035, DRIFT-050, the sweep-launch trap). |
| `writing-for-agents` | An audit of every instruction surface Specrew deploys: a size budget for always-loaded text, the trigger word first in each pointer, a completion criterion on every step, positive instructions, and removal of lines that restate default behaviour. Each change is measured by the behaviour harness, not judged by reading. | 099 Instruction Audit; 207 Behaviour Evaluation | The session-start hook output alone was 12.2 KB after a reboot on 2026-11-08. Lean instructions are also easier to audit: a reviewer can verify what an agent was told. |
| `diagnosing-bugs` - six gated phases | The bug-fix slice runs six phases, each with a recorded gate: (1) one fast, deterministic command that goes red on this bug, run and recorded; (2) the user's reported symptom reproduced, not a nearby failure, and the scenario minimised; (3) three to five ranked hypotheses, each with a prediction that can be falsified, shown to the human; (4) probes that change one variable at a time, with tagged debug output; (5) a regression test seen to fail before the fix and pass after; (6) debug output removed and the confirmed hypothesis recorded with the fix. No phase is skipped because the human is unavailable. | 055 Bug-Fix Lifecycle; 112 Bug-Test-First | 112 says "test first" and 055 names the slice, but neither says how to get from report to cause. In 203, B5F-033's stale baseline was a nearby failure taken for the bug; B5F-034's git hang, solved with a memory dump and a minimal reproduction, is this loop done well. The recorded gates are the audit trail of the diagnosis. |
| `code-review` - Standards and Spec axes | Two independent reviewers with fresh context: one against the project's code rules, with a code-smell baseline that the project's own rules override; one against the spec, citing requirement IDs. The two reports are kept side by side in the review record and never ranked against each other. | 145 Structured Reviewer; 215 Agenda Bracketing; 197 Continuous Co-Review | Code can meet every standard and implement the wrong requirement, or the reverse. A merged verdict lets one axis hide the other, which is where real findings were demoted in 203 (B5F-017). Separate axes also map directly onto requirement traceability. |
| `tdd` - seams, vertical slices, independent expected values | Before tests are written, the seams under test (the public boundaries where behaviour is observed) are listed and confirmed with the human and recorded. Work proceeds one vertical slice at a time. Expected values come from an independent source (the spec, a worked example, a known-good literal), never from the same computation as the code; the reviewer flags a test that cannot disagree with the code. | 195 Quality & Testability Lens; 163 Code Lens | A test that recomputes its expected value the way the code does is form without meaning, the class Proposals 030 and 073 exist to catch. Recorded seams give each test a stated purpose an auditor can check. |
| `grilling` - frontier rounds with recommended answers | Inside a workshop lens, questions may be asked in rounds over the frontier (every question whose prerequisites are settled), each with the crew's recommended answer. Facts about the environment are the crew's job to establish, never the human's. Every answer, including an accepted recommendation, is recorded as the human's decision with the recommendation shown. Rounds are an expertise-dial option, never used at a boundary, where one decision per message stays the rule. | 043 Structured Question Protocol; 063 Intake Questioning | Fewer turns for an expert human, without weakening the record. "Yes accepts the recommendation" is acceptable only because the recommendation is recorded beside the human's acceptance. |
| `implement-spec` - parallel agents on a task graph | Tasks may run in parallel worktrees along the frontier of the task graph, each tied to its task ID, merged by one merger agent, with every merge reviewed. Worktrees are created and removed only through Proposal 218's guarded helper. | 139 Subagent Orchestration; 148, 166 Concurrent Work | The parallelism is useful; the gateless flow and the automatic worktree removal are not. Feature 203 lost lifecycle state to a worktree removal on 2026-11-08 (DRIFT-049). |
| `handoff` | The handover points to existing artifacts instead of copying them, names the skills the next session should load, redacts secrets, and is stored outside the worktree and in the record, not only in a temp folder. | 130 Handover; 078; 035 | A handover is part of the chain of custody of the work; a temp-folder file is not evidence. |
| `improve-codebase-architecture` - deep modules | Architecture candidates apply the deletion test (deleting a shallow module would only move complexity, not concentrate it) and carry a strength rating. A rejected candidate with a lasting reason is recorded as a decision so it is not raised again. | 026 Refactor Track; 091 Tech Debt; 025 Cartography | Recording why a proposal was rejected is the same discipline as recording why a finding was dismissed. |
| `to-tickets` - tracer bullets, expand-contract | Task decomposition guidance adds the expand-contract sequence for wide mechanical refactors (add the new form, migrate in batches, remove the old), each step a task with its dependency recorded. | 128, 129 Decomposition | Each batch stays green and reviewable on its own, which keeps every intermediate state verifiable. |
| `prototype` | A prototype that settles a design question is kept as evidence (its question, what it showed, the decision it informed), even when its code is not kept. | 137 Design Alternatives | A thrown-away prototype with no record leaves a decision without its evidence. |
| `to-questionnaire` | A decision owned by a named person other than the session's human is routed to them as a recorded questionnaire, and their answers come back as their attributed decisions. | 010 Multi-Developer | Named responsibility: the person who owns the decision is the one recorded as making it. |
| Plugin-marketplace distribution | The same skills ship through each host's plugin channel, pinned to a Specrew release, with no automatic update between releases. | 058 Plugin Distribution; 214 Skills Lens | His repository proves the multi-host plugin channel works; Specrew keeps the pinning that regulated users need. |

### New scope owned by this proposal

The review found two gaps no proposal covers.

- **Project glossary.** The product-domain lens (Proposal 176) starts `GLOSSARY.md` when the first domain term is
  settled and updates it as terms are resolved, with the session and decision that settled each term. Specs,
  packets and reviews use its terms; the reviewer flags a spec term that conflicts with it. A decision record
  is written only when a decision is hard to reverse, would surprise a later reader, and came from a real
  trade-off between alternatives. In regulated work a controlled vocabulary is a requirement-quality
  practice: an ambiguous term in a requirement is a defect.
- **`/specrew-explain`.** Re-explains the last message in plain, controlled English (in the spirit of ASD-STE100
  Simplified Technical English), using the glossary's terms and glossing every identifier. It extends Proposal
  208 (decision-ready stop packets) and turns the existing rule that identifiers are glossed into a command the
  human can call. It explains; it never decides or changes anything.
- **The adoption rule** above, written once into `docs/methodology/` so future comparisons (Proposal 207 used the
  same approach for `obra/superpowers`) apply it rather than restate it.

### Not adopted

- **Gateless execution.** No mechanism runs a stage, a merge or a release without the boundary verdicts the
  lifecycle requires.
- **Proceeding on the agent's own judgement when the human is unavailable.** The work waits, or proceeds only
  under a recorded delegation (Proposal 217).
- **Ephemeral evidence.** Reports, handoffs and research that matter are committed; the temp folder is only for
  scratch work.
- **Self-updating instruction sources.** Pinned and recorded instead.
- **The anti-process positioning.** Proposal 098 (strategic positioning) states Specrew's answer: in projects
  where traceability and responsibility are requirements, owning the process is the point. A light profile for
  less regulated projects belongs under Proposals 100 (friction dial) and 201 (SDD-framework abstraction), and
  even there the record is kept.

### Out of scope

- Copying skill text. Where wording is reused it is rewritten for Specrew's terms, with attribution under the MIT
  licence.
- Installing his skills into Specrew projects. Proposal 214 (skills lens) decides which publisher skills a
  project may install, and records them.

## Effort

- **This proposal (~8-13 SP):** the glossary (5-8), `/specrew-explain` (2-3), the adoption rule in
  `docs/methodology/` (1-2).
- **Adopted mechanisms:** sized and scheduled in each target proposal when it is drafted.
- **Suggested first targets:** 017 (checks over rules), 099 (instruction audit) and 055 (the diagnosis loop).
  They are small, and each answers a failure Feature 203 hit in the week before this proposal.

## Phase placement

Phase 2, as a methodology-quality map. It is not a feature on its own beyond the glossary and the explain
command; its rows are folded into the target proposals as each is drafted, and each target's status history
records the fold.

## Open questions

1. Should the glossary be mandatory for every feature, or required only at a strictness level set through the
   friction dial (Proposal 100)?
2. Does the adoption rule become a validator check on proposals (a section a proposal must fill when it adopts an
   external mechanism), or stay a reviewer checklist?
3. Should the two-axis review report both axes to the human at sign-off, or only the axis with findings?
4. Is `/specrew-explain` available at a boundary stop, where the packet must stay the single source of the
   decision, or only between stops?

## Risks

- **Philosophy creep.** Adopting fast mechanisms one at a time can erode the record without any single change
  looking harmful. Mitigation: the five-test adoption rule, applied and reviewed in each target proposal.
- **Instruction growth.** Each adopted mechanism adds text agents must read, against Proposal 099's budget.
  Mitigation: adopted mechanisms are enforced as checks where possible (the retro row), and measured by
  Proposal 207.
- **Ceremony without value.** Recording every accepted recommendation could make the workshop slower than it is
  today. Mitigation: rounds are an expertise-dial option, and the record is written by the tooling, not typed by
  the human.

## Cross-references

- Source: [`mattpocock/skills`](https://github.com/mattpocock/skills) (MIT), reviewed 2026-11-08: `retro`,
  `writing-for-agents`, `diagnosing-bugs`, `code-review`, `tdd`, `grilling`, `implement-spec`, `handoff`,
  `domain-modeling`, `wait-what`, `improve-codebase-architecture`, `to-tickets`, `wizard`.
- Target proposals: 010, 017, 025, 026, 035, 043, 055, 058, 063, 078, 091, 099, 112, 128, 129, 130, 137, 139,
  145, 148, 163, 166, 176, 195, 197, 207, 208, 214, 215.
- Related: 053 (decision transparency), 098 (positioning), 100 (friction dial), 201 (SDD-framework abstraction),
  207 (the same comparison method for `obra/superpowers`), 217 (delegation), 218 (guarded worktree removal).
- Feature 203 evidence: B5F-017, B5F-033, B5F-034, B5F-035, DRIFT-049, DRIFT-050.

## Status history

- 2026-11-08: created as candidate after a review of `mattpocock/skills` against all 217 proposals, with the
  maintainer's ruling that mechanisms may be taken but the philosophy may not: Specrew serves projects where
  discipline, evidence and maturity are the highest requirements.
