# Review: Iteration 006

**Schema**: v1
**Reviewed**: 2026-06-04
**Overall Verdict**: accepted (on delivered scope; the workshop re-scope is forward work — Amendment A4 / Iteration 7)

## Summary

Iteration 006 delivered the Amendment A3 re-scope of the lens intake: it is now **interactive,
expertise-adapted, and run early — inside specify, before clarify**, with the placement
**gate-enforced** (not prompt-only). Delivered:

- **FR-025/SC-018 (dial-adapted depth):** `Get-SpecrewLensQuestionDepth` maps the user-profile
  expertise dials → question depth (`52ff74b1`).
- **FR-027 (intake before sync-specify, enforced):** `Invoke-SpecrewSpecifyBoundaryLensGate` refuses
  `sync-specify` until the feature-level `lens-applicability.json` exists, wired into
  `sync-boundary-state.ps1` parallel to the plan gate, with a committed scripted proof
  (`bd3216ee`); the coordinator-prompt wiring tells the Crew to run the intake + amend spec/checklist
  before sync (`c349b6a5`). Prompt-only was explicitly insufficient per maintainer mandate.
- **FR-026 feature/iteration resolution (instruction #1):** the coverage gate resolves
  `iterations/<NNN>/lens-applicability.json` → feature-level → graceful no-op, with the regression set
  (`dd02c205`); a selected lens without a non-placeholder `Addressed:` entry still FAILS and names it.
- **FR-028 (file-reference context model)** + the handoff bare-path fix (RRT/Bug1, FR/SC no longer
  flagged) and **FR-029 (downstream FileList-sort guard)** (`6c78fa13`).
- **Expertise-transparency surfacing (A3 transparency half):** the orientation now renders the assumed
  profile as a correctable one-liner (`706b2a51`) — *committed and unit/block-tested, but absent from
  the dogfood transcript; runtime-unverified (see Gap Ledger).*
- Formal test set (`2e8a7dda`): dial→depth (6 cases), FR-026 resolution regressions, FR-028 render +
  handoff, the specify-gate scripted proof. Validator **PASS 7/7** (hard=0, medium=0).

**Iteration 005's improvement action worked.** 005's retro required that a feature whose value is a
human interaction must get a **human-experience dogfood**, not only a mechanics dogfood. The maintainer
ran exactly that — a real downstream greenfield `specrew start --host claude` — and it caught the gap
the mechanics could never reveal.

## Post-signoff (second maintainer manual end-to-end test — honest record)

The downstream run surfaced three things:

1. **The intake is a *questionnaire*, not a *workshop* (the headline).** It asks the human to confirm
   *obvious* applicability the AI already infers ("is there UI?") and never *discusses* any lens. The
   maintainer's intent is a **per-lens facilitated design workshop**: AI infers applicability (human
   confirms), then for each lens the Crew raises that lens's real design questions, captures decisions
   and agreement, adapts depth to expertise, and iterates until "move on". **Re-scoped to Amendment A4
   / Iteration 7.** This is **not a defect in Iteration 6's code** — the deterministic intake + gate +
   transparency machinery stand and are retained as the engine beneath the workshop. Critically, the
   FR-026 coverage gate **cannot** catch this: the agent emitted a structurally valid
   `lens-applicability.json` the gate PASSES, while the behavior is exactly what the maintainer rejects
   — so the workshop is a **behavioral/prompt** capability whose only real check is the runtime dogfood.
2. **The Rule 46 six-section re-entry packet collapsed into the verdict menu** on the Claude host (the
   agent jumped straight to AskUserQuestion). Known, persistent Claude-host prompt-adherence weakness
   (F-054 class) — **handoff-quality track, NOT Feature 141** (141 neither touched nor broke it).
3. **The expertise-transparency line was absent from the transcript** — committed but runtime-unverified
   (the run likely predated the on-disk fix). To be confirmed on a fresh `specrew start`.

## Review Dimensions (Proposal 145 framing)

### State truth

- Ledger: `tasks-progress.yml` — T001/T002/T004/T005/T006 `done`, T007 closed below, **T003 `deferred`**
  (subsumed by the A4 workshop → Iteration 7). **Delivered capacity 16/20** (T003's 3 SP deferred);
  `plan.md` shows the original 19/20 and is annotated for the deferral. Design-analysis gate passed
  (Option B); decision commit `3e610c4a` ≠ draft `92286c76`. (State-truth correction at closeout: T003
  had been left `planned` in the ledger while a working task-pane marked it done — reconciled to
  `deferred` here, not silently passed.)

### Branch hygiene

- Branch `141-design-gate-runtime-hardening`. Iteration-6 commits: design-analysis `92286c76`/`3e610c4a`;
  plan `81d8ce2e`/`e93cfd25`; T001 `52ff74b1`; T002 `dd02c205`/`bd3216ee`/`c349b6a5`; T004/T005 `6c78fa13`;
  T006 `2e8a7dda`; docs `54caa4bb`; transparency `706b2a51`; Amendment A4 `a50d5413`.
- **No push / no PR** while the feature is in progress. `index.yml` kept pure (decoupled sibling map only).
  No release / Unix / wrapper / bootstrap surfaces touched.

### Functional correctness

- The specify-boundary lens gate blocks `sync-specify` before the feature-level artifact exists (scripted
  proof: blocks-before-artifact / passes-after / skips-without-catalog). FR-026 resolution order verified
  (feature-level fails+names / iteration overrides / neither no-ops). FR-028 render (console `file:///` vs
  persisted markdown) + handoff bare-path discrimination verified. FR-029 guard skips cleanly downstream.
- Deterministic + LLM/network-free throughout; the deferred Proposal 156 deep scope stays out.

### Test integrity

- Selector suite (incl. 6 dial→depth cases) and the design-analysis-gate suite (incl. FR-026 resolution
  regressions) green; the feature suite carries the specify-gate proof + the handoff bare-path cases;
  the multi-host + f049 suites carry the expertise-line block/unit tests. Validator PASS 7/7.

### Evidence integrity

- Runtime-verified for the deterministic surfaces (gate, resolution, render, depth — exercised on real
  inputs). **Behavioral surfaces are NOT unit-provable**: the expertise line and (now) the workshop
  conduct require a runtime dogfood — flagged honestly rather than claimed from a green unit run.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-025, SC-018 | pass | `Get-SpecrewLensQuestionDepth` dial→depth; fail-safe moderate. |
| T002 | FR-027, FR-026, FR-025 | pass | Enforced specify-boundary lens gate + scripted proof; FR-026 feature/iteration resolution; coordinator wiring. |
| T004 | FR-028 | pass | `Format-SpecrewFileReference` (console/persisted/both); handoff bare-path fix (RRT/Bug1, FR/SC not flagged). |
| T005 | FR-029 | pass | FileList-sort guarded (skipped when no `Specrew.psd1`); verified downstream. |
| T006 | TG-006 | pass | Formal test set; validator PASS 7/7. |
| T007 | TG-006, dogfood | pass (its purpose) | The human-experience dogfood RAN and surfaced the workshop gap + the two side findings — exactly what 005's improvement action required. Docs delivered (`54caa4bb`). |

*(T003 / FR-009 is not in this table — it was not delivered this iteration; it is `deferred` to Iteration 7, classified in the Gap Ledger below.)*

## TG-006 classification (Rule 39)

| Requirement | Implemented | Enforced | Observable | Documented |
| ----------- | ----------- | -------- | ---------- | ---------- |
| FR-025 depth adaptation | yes — `Get-SpecrewLensQuestionDepth` | n/a (input to behavioral conduct) | yes — depth applied in intake | yes — spec/SC-018 |
| FR-027 intake before sync | yes — specify-boundary gate | yes — refuses sync-specify before the artifact | yes — gate error | yes — spec/quickstart |
| FR-026 resolution | yes — feature/iteration order | yes — blocks plan; names lens | yes — gate error | yes — spec/tests |
| FR-028 / FR-029 | yes | yes (handoff validator / sort guard) | yes | yes |
| Expertise transparency | yes — orientation line | n/a (visible prose) | **unverified at runtime** | yes — spec FR-025 |

## Gap Ledger

- **FR-025 lens-intake interaction model (workshop):** the intake is an interactive questionnaire, not the per-lens workshop; engine retained, not an Iteration-6 code defect. **deferred** to Amendment A4 / Iteration 7 — canonical defer entry + maintainer approval in file:///C:/Dev/Specrew-design-analysis/.squad/decisions.md ("Feature 141 Iteration 006 Gap Ledger Deferrals").
- **T003 / FR-009 per-phase decision-point flow:** only the high-level Rule 9a sentence shipped; subsumed by the A4 workshop. **deferred** to Iteration 7 — same canonical defer entry in file:///C:/Dev/Specrew-design-analysis/.squad/decisions.md.
- **Delivered deterministic surfaces — no FR/SC gaps:** FR-025(depth)/FR-026/FR-027/FR-028/FR-029 implemented, enforced, observable, and tested (validator PASS 7/7). **fixed-now.**

## Follow-ups (not iteration-006 gaps)

- **Expertise-transparency line — runtime-unverified:** the orientation line is committed (`706b2a51`) and unit/block-tested but was absent from the dogfood transcript (likely predated the fix). A delivered item awaiting a fresh-start runtime confirmation, not a deferred scope item; if still missing on a fresh `specrew start`, it becomes a live bug to fix.
- **Rule 46 re-entry packet collapse (Claude host):** the six-section packet collapsed into the verdict menu — a known, persistent Claude-host prompt-adherence weakness (F-054 class). Out of Feature 141 (handoff-quality track); 141 neither touched nor broke it.
- Deferred Proposal 156 deep scope (overrides, schema-validation enforcement, broad automation) remains future; FR-010 keeps it out.

## Notes

- Hardening-gate concerns promoted to runtime-evidence at this signoff (see `quality/hardening-gate.md`).
- Iteration 6 closes on delivered scope; the per-lens workshop is Iteration 7 (Amendment A4).
