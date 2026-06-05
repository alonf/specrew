# Review: Iteration 010

**Schema**: v1
**Reviewed**: 2026-06-05
**Review method**: Proposal 145 (7-phase structured review + FR×phase matrix + claim-ledger + design-trace + report-falsification). 145 is a candidate (not validator-enforced), followed here as the review *method*.
**Overall Verdict**: accepted

## Summary

Iteration 10 is the **delivery relocation** the i9 dogfood demanded: the A4/A5/A6 lens conduct moves out of the
~50-rule one-shot launch prompt into a re-invokable `specrew-design-workshop` skill + per-lens conduct
co-located in each `design-lenses/<id>.md` + a trimmed prompt-pointer. Same intent, changed implementation; no
FR change (Option B, decision `65a5a534`). The headline is the **inverse of i9's falsification**: where
testLenses5 *falsified* the in-band-surfacing claim (the Claude agent wrote the diagram to an HTML file and
never showed it, gave a terse "4 Managers, 3 Engines" count), **testLenses6 CONFIRMED it** — the relocated
skill auto-loaded, re-invoked per lens, surfaced console-ASCII diagrams in-band the maintainer saw, named
every component with its responsibility, co-designed the map and walked the discover→use→rate flow WITH the
human, and **held the trade-off options until the map was agreed**. The SC-025 co-design floor validated
`Valid=True`; the agent additionally caught the Option-C-async vs FR-010 conflict and surfaced it as a
structured verdict question. **SC-024 — the i10 thesis (focused skill > diluted mega-prompt) — is confirmed at
runtime.**

The honest counterweight, and the thing this review refuses to over-claim: the testLenses6 dogfood ran on a
deployed skill that **predated all three same-session refinements** — proven by the agent hitting the OLD
SC-021 record shape (it failed the gate and self-corrected) and writing PROSE `diagram` fields. So the run
confirms the **relocation**, not `a38daa33` (question-FORM), `c80e7d58` (SC-021 record shape), or `49a9ff39`
(diagram persistence). Those three are **shipped + presence-locked** (this review added the assertions that
guard them — `e6d62ee7`) but **runtime-unconfirmed pending a fresh-deploy dogfood**. The 10-minute pauses are
host API latency, not an i10 defect.

## Phase 0 — Context load

Loaded: spec A4/A5/A6 (FR-034..FR-037, SC-021, SC-024/SC-025), [plan.md](plan.md) (Option B, decision
`65a5a534`, draft `deaa1b25`), [design-analysis.md](design-analysis.md), [state.md](state.md),
[tasks-progress.yml](tasks-progress.yml), the **testLenses6 dogfood transcript** (001-skill-mcp-catalog: the
full 8-lens workshop → specify → clarify → design-analysis co-design stop → design-gate pass → plan), and the
i10 diff: `extensions/specrew-speckit/squad-templates/skills/design-workshop.md` (new, the relocated conduct),
the nine `knowledge/design-lenses/*.md` + `lens-template.md` (each +`## Workshop Conduct`), `scripts/specrew-start.ps1`
(prompt trim), and `tests/unit/lens-conduct-delivery.tests.ps1`. **Verdict: pass.**

## Phase 1 — Branch hygiene

- Branch `141-design-gate-runtime-hardening`; i10 chain `deaa1b25` (design draft) → `65a5a534` (decision) →
  `84948675` (hash) → `f36fd4e6` (skill author) → `c462f749` (T002-T005 relocate + trim) → `a38daa33`
  (question-FORM) → `49a9ff39` (diagram persistence) → `c80e7d58` (SC-021 record shape) → `ee2c9b5c` (T006
  record) → `aef42c89` + `e6d62ee7` (review-driven presence-lock + precise framing).
- **No upstream / local-only is INTENTIONAL** (the standing "no push/PR while 141 in progress" constraint) —
  not a Shape-4 gap. `proposals/145` + `proposals/162` are NOT on this branch (proposals → main; 162 on main
  `0844b05d`).
- Shape-5 audit: every cited file is committed; working tree carries only `.specrew`/`.squad` session
  bookkeeping + the unstaged `proposals/145` (main-bound). **Verdict: pass.**

## Phase 2 — Functional correctness

- **The skill (T001):** `design-workshop.md` — frontmatter `name` + an engineered `description` carrying the
  literal design-moment triggers (design lens / workshop / design-analysis / architecture / co-design /
  RE-INVOKE) so the model auto-loads it; a **self-contained per load** + **self-reinvoking** body carrying the
  big-picture lens map + The Method (phase-framing, infer-then-confirm, per-lens discussion, ASCII-first
  in-band surfacing, co-design-not-handed-down, capture-agreements) + the per-lens load loop.
- **Per-lens conduct (T002):** all nine lens md + `lens-template.md` carry a `## Workshop Conduct` section
  (diagram type + facilitation nuance + the re-invoke instruction) read on-demand at point-of-use.
- **Prompt trim (T003):** Rule 9a is now a compact skill pointer (keeps the SC-021/SC-025 gate refs); 9b/9c are
  "Folded into the skill" stubs; the verbose A5 visuals rule body no longer lives inline. Parse-clean.
- **Deploy (T004):** unchanged — the flat `design-workshop.md` auto-discovers via the existing
  `Get-LegacySpecrewSkillDefinitions` path and deploys as `specrew-design-workshop/SKILL.md` to the host skill
  roots; no deploy-script edit; the skill-templates test enumerates dynamically.
- **Design → behaviour conformance:** Option B (relocate) → the testLenses6 dogfood is the behavioral evidence,
  and it **conforms**: the relocated delivery produced exactly the reliably-surfaced, co-designed workshop the
  diluted mega-prompt failed to in i9. **Verdict: pass.**

## Phase 3 — Non-functional requirements

- Determinism / no-LLM-no-network: the skill + lens md + prompt are inert markdown; the SC-021/SC-025 gates the
  skill points to remain deterministic, marker-gated, grandfather-safe. `index.yml` untouched. The deferred
  Proposal 156 scope stays out. **Verdict: pass.**

## Phase 4 — Code quality

- Lint / parse: PowerShell AST-clean (`specrew-start.ps1`, the test); markdown well-formed.
- **Dependency reality:** no new packages/imports — markdown templates + a line-anchored prompt regex + a
  PowerShell test. The deploy reuses the existing auto-discovery seam (no hardcoded skill list to drift).
- **Anti-pattern scan:** no sleep-as-sync, no hidden global state, no test-only production behavior; the
  trimmed prompt retains a reachable pointer (no orphaned conduct). **Verdict: pass.**

## Phase 5 — Test coverage + integrity

- The `lens-conduct-delivery` suite locks the **relocation structure**: skill exists + frontmatter trigger
  description + the relocated conduct keywords (ASCII-inline default, file:/// link, named-components,
  ui-ux capture, per-lens `<lens-id>.md` load, self-reinvocation, self-contained); all nine lens md carry
  `## Workshop Conduct` + ASCII + the re-invoke; the prompt points to the skill, 9a is the pointer, 9b/9c are
  stubs, the verbose 9b body is gone. SC-024 (runtime quality) is **behavioral → the dogfood, not a unit
  test** (stated in the suite header).
- **Gate-completeness (Shape 8) — review-driven fix this iteration:** the suite guarded the relocation but
  asserted **none of the three same-session skill refinements**, so a later skill edit could silently drop
  them — the said-it/didn't-do-it hole this feature's reviews keep missing. This review **closed the
  structural half** (`aef42c89`/`e6d62ee7`): presence assertions for the question-FORM text (a38daa33), the
  `workshop → <lens-id>` + singular-`decision` SC-021 shape (c80e7d58), and the workshop-folder diagram
  persistence (49a9ff39). They lock PRESENCE only — **not** agent obedience.
- **Honest limit:** the three refinements postdate the deployed skill the dogfood ran (the run hit the old
  SC-021 shape + prose diagram fields), so their **behavioral** confirmation is a fresh-deploy dogfood, not
  this run. Carried, not claimed. **Verdict: pass for the relocation structure; the three refinements
  presence-locked + runtime-carried.**

## Phase 6 — System safety + ops

- Backward compatibility: the deploy is an idempotent file copy (re-deploy overwrites the managed `SKILL.md`);
  skills enumerate dynamically; the skill ships to `.claude/skills` + `.agents/skills` (the two-folder covering
  set for all five hosts per the agentskills.io open standard). No release/publish/push while 141 is in
  progress. **Verdict: pass.**

## FR × Phase Coverage Matrix

| Requirement | P1 | P2 | P3 | P4 | P5 | P6 |
| --- | --- | --- | --- | --- | --- | --- |
| FR-034 (phase-framing) | pass | pass (skill Method 1) | n/a | pass | pass (skill content lock) | pass |
| FR-035 (design-method) | pass | pass (skill Method 5 + lens md) | n/a | pass | pass (content lock) | pass |
| FR-036 / SC-024 (co-design) | pass | **pass (dogfood CONFIRMED)** | n/a | pass | pass (dogfood; structure locked) | pass |
| FR-037 (in-band surfacing) | pass | **pass (dogfood CONFIRMED: ASCII seen in-band)** | n/a | pass | pass (ASCII-default locked) | pass |
| SC-021 (workshop records) | pass | pass (relocated to skill) | pass | pass | shape text presence-locked (c80e7d58, runtime-carried) | pass |
| SC-025 (co-design floor) | pass | pass (`Valid=True` in dogfood) | pass | pass | pass (unchanged gate) | pass (grandfather-safe) |

## Claim-to-Evidence Ledger

| Claim | Evidence |
| --- | --- |
| Relocation delivers SC-024 (in-band surfacing + co-design) | testLenses6: skill auto-loaded + re-invoked per lens; console-ASCII diagrams surfaced in-band; design-analysis named every component with responsibility, walked the flow, **held options until the map was agreed**; SC-025 floor `Valid=True` |
| The agent reasoned at design depth | caught the Option-C-async vs FR-010 conflict and surfaced it as a structured verdict question before recording the decision |
| The i9 failure mode did NOT recur | no terse manager count, no diagram-written-to-file-never-shown, no missing co-design record |
| Relocation structure is locked | `lens-conduct-delivery` suite: skill + 9 lens md + trimmed prompt assertions green |
| **The three refinements (a38daa33/c80e7d58/49a9ff39)** | **PRESENCE-locked only** (this review's assertions). **Runtime-UNCONFIRMED** — the deployed skill the dogfood ran predated them (old SC-021 shape hit; prose diagram fields). Behavioral confirmation = a fresh-deploy dogfood. |
| Skill re-invocation is viable cross-host | web docs (i9): name+description always resident; body loaded on-demand, multiple times/session; deployed two-folder covering set for all five hosts |

## Design → Code → Test Trace

| Design (Option B) | Implementation | Evidence | Status |
| --- | --- | --- | --- |
| Relocate conduct to a re-invokable skill | `squad-templates/skills/design-workshop.md` | testLenses6 (auto-load + re-invoke) + suite | matched (confirmed) |
| Co-locate per-lens conduct | `## Workshop Conduct` in 9 lens md | suite (all 9 asserted) | matched |
| Trim the launch prompt | `specrew-start.ps1` 9a pointer + 9b/9c stubs | suite (pointer + stubs + verbose-gone) | matched |
| Deploy unchanged (auto-discovery) | existing `Get-LegacySpecrewSkillDefinitions` path | skill-templates dynamic enumeration | matched |
| SC-021 record shape pin | skill step 6 exact JSON shape | presence-lock (c80e7d58) | content matched; **runtime-carried** |
| Diagram persistence | skill step 6 workshop-folder ref | presence-lock (49a9ff39) | content matched; **runtime-carried** |

## Phase 7 — Report falsification

- **Where i9 falsified its surfacing claim, i10 confirms it — and I checked the confirmation is real, not
  wishful.** The dogfood transcript shows the maintainer *saw* the ASCII in-band and co-designed the named map;
  this is not inferred from the floor passing.
- **Falsified the temptation to bank the three refinements.** The natural over-claim is "i10 shipped the SC-021
  shape fix + diagram persistence and the dogfood passed, so they work." It did not test them — the deployed
  skill predated them (the old-shape failure + prose diagram fields are the proof). Recorded as
  presence-locked + runtime-carried, NOT proven.
- **No claim stronger than its evidence:** the relocation/SC-024 claim rests on the transcript; the structure
  claim on the suite; the three refinements are explicitly DOWNGRADED to presence + carried.

## Per-Phase Verdict + Overall

per_phase: { p0: pass, p1: pass, p2: pass, p3: pass, p4: pass, p5: pass, p6: pass }. The relocation is
delivered + structurally tested and **SC-024 is confirmed at runtime** (the i10 thesis); the three
same-session skill refinements are presence-locked and carried as runtime-unconfirmed pending a fresh-deploy
dogfood. **Overall: ACCEPTED for review-signoff.**

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-034..FR-037 (delivery) | pass | The `specrew-design-workshop` skill: auto-load description + self-contained, self-reinvoking body. |
| T002 | FR-034..FR-037 (delivery) | pass | `## Workshop Conduct` co-located in all 9 lens md + lens-template. |
| T003 | FR-037 / SC-021 / SC-025 (refs) | pass | Prompt trimmed to a skill pointer; gate refs retained; parse-clean. |
| T004 | (deploy) | pass | Auto-discovery deploy unchanged; dynamic enumeration; ships to the two-folder covering set. |
| T005 | (tests) | pass | `lens-conduct-delivery` suite green; **extended this review** to presence-lock the 3 refinements; skill-templates + design-analysis-gate + design-gate-runtime-hardening + selector green. |
| T006 | SC-024 | pass | testLenses6 **confirmed** the relocation surfaces in-band + co-designs (the i9 failure did not recur). The three post-build refinements are runtime-carried (the deployed skill predated them). |

## Gap Ledger

- **No deferred FR/SC.** SC-024 (the i9 carry) is **delivered + confirmed** this iteration; FR-034/035/036/037
  and SC-021/SC-025 are all served by the relocation. There is nothing carried to a future 141 iteration —
  i10 is the last planned increment before feature-closeout.
- **Fixed-now:** the relocation (skill + 9 lens md + trimmed prompt + unchanged deploy) and the review-driven
  test hardening (presence-lock the 3 refinements) — all delivered + tested this iteration.
- **Fixed-now but runtime-unconfirmed (shipped, awaiting natural exercise — NOT a deferral):** `a38daa33`
  (question-FORM), `c80e7d58` (SC-021 record shape), `49a9ff39` (diagram persistence). The *fix* is in the
  skill + presence-locked; only the *behavioral observation* is pending, because the dogfood ran on the
  pre-refinement deployed skill. These ship with i10; the next downstream workshop run on the updated skill is
  the confirmation — no defer entry, no unmet requirement.

## Follow-ups

- **Next-dogfood watch (post-141):** confirm the three refinements behaviorally on a fresh-deploy run — the
  agent writes the gate-conformant SC-021 record first try (no shape dance), and persists keeper diagrams to
  the workshop folder as file refs (no prose `diagram` fields). Carried into the i10 retro.
- **B (options invisible at the AskUserQuestion verdict menu) → parked Rule-46** (handoff-quality track, NOT
  141).
- **Future (post-141):** the maintainer's sub-agent-per-skill + coordinator model; Proposal 162 (two-tier
  product-then-feature workshop) already filed to main.

## Notes

- Hardening-gate concerns promoted to runtime-evidence at this signoff (see
  [quality/hardening-gate.md](quality/hardening-gate.md)).
- Iteration 10 closes on its delivered + tested scope (the relocation + SC-024 confirmation + the review-driven
  presence-lock). The dogfood was again the gate-completeness check — this time it **confirmed** rather than
  falsified, the payoff of the i9 delivery-dilution diagnosis.
