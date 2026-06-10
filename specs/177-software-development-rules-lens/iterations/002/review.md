# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-10
**Overall Verdict**: accepted (for i2 delivery scope only -- see the gate below)
**Baseline Ref**: 96ded099a4e29db56c8e26de441af9da13896db4 (i1-closeout)
**Reviewed Implementation Head**: da7a0129 (the packet commit advances HEAD past this; the metadata is pinned)

> Proposal-145-style structured packet (Phase 0-7 + FR x phase matrix + drift/conformance + falsification).
> Proposal 145 is unshipped, so this is authored manually, not produced by 145 machinery. Machine-readable
> companion: `review-report.yml`. **Acceptance is scoped to i2 DELIVERY + DEPLOYMENT WIRING + manifest-
> authoring (objectively verified). The behavioral SC-004 / SC-007 / SC-008 are NOT verified here** -- they
> are an open beta-gate obligation (`drift-log.md` **D-003**) confirmed only at the published-beta human
> dogfood before stable promotion. No push / tag / publish / beta release until feature-closeout approval.

## Summary

Iteration 002 (i2 -- delivery + guidance) ships the runtime half of the code-implementation lens: the
`specrew-code-rules` implement-time guidance skill, the design-workshop code-lens conduct turn (source-of-
truth-first, grouped checklist, assisted ingestion), the plan/implement wiring, the skill + multi-host
parity tests, the **deployed-module dogfood** (T017), and release-prep (T018, prepare-only). The deployed
dogfood **objectively verified deployment wiring + manifest-authoring** on a staged FileList-only 0.35.0
module (`dogfood-report.md`). The **behavioral** success criteria -- the agent is *actually* guided
(SC-004), the human is *not* walled (SC-007), the dependency stance is *actually* honored (SC-008) -- are
**deferred-with-gate** to the published-beta human run (D-003); they are NOT claimed verified in i2.

## Phase 0-7 Review

| Phase | Name | Verdict | Evidence |
| --- | --- | --- | --- |
| 0 | Context load | pass | spec/plan/tasks/i1-closeout loaded; scope = i2 (T010-T018); baseline 96ded099. |
| 1 | Branch hygiene | pass-with-notes | ahead 35 (F-177 commits), behind 4 (merge at feature-closeout); dirty tree classified below -- none F-177 source. |
| 2 | Functional correctness | pass (delivery) | guidance skill resolves feature -> manifest+catalog -> baseline+overlay, task-scoped, fail-open, dependency_policy honored; conduct turn shipped (hand-author manifest, D-002); deployed dogfood proved downstream catalog+skill+lens deployment + a hand-authored manifest validates on the deployed module. Behavioral surfacing = SC-004/007/008 gate (not this phase's claim). |
| 3 | NFR | pass | multi-host parity (byte-identical design-workshop across 4 hosts + code-rules deploys to all hosts); constrained-YAML; fail-open; forward-compat hooks. |
| 4 | Code quality | pass | PSScriptAnalyzer Errors=0 (pre-existing New-/plural Warnings repo-tolerated); ASCII .ps1; markdownlint clean. |
| 5 | Test coverage + integrity | pass | code-rules-skill-multihost + code-implementation-lens (incl. the new single-element-enforcement regression) + lens-conduct-delivery PASS; behavior-proving at the unit/parity level (the runtime-behavioral level is the deferred dogfood gate). |
| 6 | System safety + ops | pass | no auth/secrets/PII/network; fail-open; mechanical-checks 0 findings; FileList bidirectional + version triple (0.35.0) consistent; release prepare-only, nothing published. |
| 7 | Falsification + synthesis | pass | see Report Falsification; the SCOPED accepted verdict survives refutation; the behavioral SCs are explicitly an open gate, not a claim. |

## Branch Hygiene Classification (Phase 1)

Branch ahead 35 (the F-177 lifecycle commits), behind 4 (origin/main advanced -> reconcile by **merge at
feature-closeout**, not mid-iteration). The dirty working tree is **not** F-177 source:

| Path(s) | Class | F-177? | Action |
| --- | --- | --- | --- |
| `.claude/agents/*.md` (5) | pre-existing session churn | no | present before this session (session-start git status); review separately |
| `.specrew/last-validator-summary.json`, `.specrew/runtime/refocus-channel1.json`, `.specrew/version-check-cache.json` | runtime state/cache | no | gitignore-class; not source |
| `.squad/active-features.yml`, `config.json`, `decisions.md`, `events/lifecycle-events.jsonl`, `identity/now.md` | Squad runtime state | no | written during the lifecycle; runtime-local |
| `specs/171-specrew-refocus/iterations/002/tasks-progress.yml` | stale 171 leftover | no | unrelated (recovery-B bypassed feature); cleanup-class |

**Conclusion**: every F-177 i2 deliverable is committed (26 files in `git diff 96ded099..da7a0129`); no F-177 source change is uncommitted.

## FR x Phase Coverage Matrix

Per the maintainer constraint, the four **workshop-conduct** FRs (FR-003/009/010/011) read **delivered --
behavioral-deferred-with-gate (D-003)**, never "verified" on their behavioral claim.

| Requirement | Status | Phases | Evidence |
| --- | --- | --- | --- |
| FR-001 | verified | 2,5 | registration (i1; reconfirmed green) |
| FR-002 | verified | 2,5 | catalog 60 rules (i1; reconfirmed) |
| FR-003 | delivered; behavioral deferred-with-gate (D-003) | 2,5 | conduct turn shipped + deployed; the grouped-checklist *behavior* is the SC-007 gate |
| FR-004 | verified | 2,5 | schema + hand-authored manifest validates on the deployed module |
| FR-005 | verified | 2,3,5 | `specrew-code-rules` deploys to all 4 hosts (dogfood + parity test) |
| FR-006 | verified | 2 | Planner directive + Implementer charter pointer shipped (T014) |
| FR-007 | verified | 2,5 | context_scope hook (i1; reconfirmed) |
| FR-008 | verified | 2,5 | baseline-only skill mode (skill content + fail-open test, SC-006) |
| FR-009 | delivered; behavioral deferred-with-gate (D-003) | 2 | set/unset + custom rules in conduct + schema; the *interactive* behavior is the SC-007 gate |
| FR-010 | delivered; behavioral deferred-with-gate (D-003) | 2 | source-of-truth-first in conduct; the *agent-asks-first* behavior is the SC-004/007 gate |
| FR-011 | delivered; behavioral deferred-with-gate (D-003) | 2 | assisted ingestion in conduct; the *agent-ingests* behavior is the SC-004 gate |
| FR-012 | verified | 2,5 | overlay never-drops + custom provenance (i1; reconfirmed) |
| FR-013 | verified | 2,5 | dependency_policy capture + the dogfood manifest exercised the stance |

SC coverage: SC-001/SC-002/SC-003/SC-005/SC-006 verified; **SC-004 / SC-007 / SC-008 NOT verified --
deferred-with-gate (D-003)**. Full matrix in `review-report.yml`.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T010 | FR-005 | pass | guidance skill (resolver + baseline+overlay + task-scoped + fail-open). |
| T011 | FR-005 | pass | skill in the canonical template; auto-enumerated to all hosts (no host-scope). |
| T012 | FR-003 | pass (variance D-002) | design-workshop code-lens turn; manifest capture changed to hand-authored (accepted variance). |
| T013 | FR-011 | pass (variance D-002) | assisted ingestion conduct; same hand-author capture variance. |
| T014 | FR-006 | pass | Planner directive + Implementer charter pointer. |
| T015 | FR-005 | pass | guidance-skill conduct-content tests green. |
| T016 | FR-005 | pass | multi-host parity (4 deployed copies byte-identical; code-rules all-hosts). |
| T017 | SC-004 | pass for wiring+manifest-authoring; behavioral SC-004/007/008 deferred-with-gate (D-003) | deployed-module dogfood; surfaced+fixed the single-element-enforcement defect. |
| T018 | SC-003 | pass (prepare-only) | FileList +5, version triple 0.35.0, CHANGELOG, .specify parity; nothing published. |

## Drift / Conformance Review (D-002, D-003)

Per the maintainer constraint, the two recorded variances (`drift-log.md`) are reviewed here as conformance
items:

- **D-002 -- manifest capture: PowerShell writer-call -> hand-authored. CONFORMANT (accepted variance).**
  The change keeps the requirement intent (a schema-valid reference-by-ID manifest is still captured); it
  only swaps the authoring mechanism to the portable, deployed-safe `product-domain` pattern. The PS
  writer/validator are now test-only by design (not dead code). Verified: a hand-authored manifest validates
  schema+catalog on the deployed module. **Status: resolved/accepted.**
- **D-003 -- T017 behavioral SC-004/007/008 deferred-with-gate. OPEN beta-gate obligation.** This is NOT
  resolved in i2 and MUST NOT be treated as satisfied. The conduct + skill + deployment are in place and
  wiring is verified, but the behavioral satisfaction (agent actually guided, human not walled, dependency
  stance actually honored) is confirmed only by the human-on-host dogfood of the published `v0.35.0-beta.1`,
  and that confirmation is a hard precondition for promoting the 0.35.0 line to stable. **Status: OPEN;
  carried to feature-closeout / beta validation.**

## Gap Ledger

- **D-003 behavioral SC-004/007/008**: OPEN -- deferred-with-gate to the published-beta human dogfood
  (necessary: publish is gated to feature-closeout, and behavior cannot be established by autonomous
  artifact inspection). Not a defect; a recorded, maintainer-approved, gated obligation.
- No other FR/SC gap in i2 delivery scope: the guidance skill, conduct turn, ingestion, wiring, tests,
  parity, dogfood wiring, and release-prep are delivered + (where non-behavioral) verified.

## Report Falsification (Phase 7)

Adversarial attempts to refute the SCOPED accepted verdict (full list in `review-report.yml`):

- "Behavioral SC-004/007/008 claimed verified?" -> FAILS (they are explicitly deferred-with-gate, D-003; the report and every matrix say NOT verified).
- "D-003 hidden or treated as resolved?" -> FAILS (recorded OPEN in drift-log + this conformance section + the gap ledger; it gates stable promotion).
- "Guidance skill mis-resolves / mis-composes?" -> FAILS (resolves feature -> manifest+catalog -> baseline+overlay, fail-open; dogfood + skill tests).
- "Manifest-authoring broken on the deployed module?" -> FAILS (hand-authored manifest schema+catalog valid on the staged 0.35.0 module; single-element-enforcement defect fixed + regression-tested).
- "Multi-host parity over-claimed?" -> FAILS (4 design-workshop copies byte-identical; code-rules deploys to all hosts; dogfood confirmed downstream deployment).
- "Release over-reaches (published)?" -> FAILS (prepare-only: FileList + version triple + CHANGELOG + .specify; nothing pushed/tagged/published).
- "Conduct FR (003/009/010/011) over-claimed as verified?" -> FAILS (each reads delivered; behavioral deferred-with-gate).

**Result**: the accepted verdict survives falsification **for i2 delivery + deployment-wiring scope**. The
behavioral SCs are an open, recorded, maintainer-approved beta-gate (D-003), not an i2 claim.

## Notes

- **Verdict scope**: "accepted" covers delivery + deployment wiring + manifest-authoring (objectively
  verified). It does NOT absorb SC-004/007/008, which remain the open D-003 beta-gate.
- **D-002** (hand-author manifest change) recorded + accepted; **D-001** (conduct-driven registration) is
  the feature-level decision from i1.
- **Carried to feature-closeout**: the published-beta human dogfood confirming SC-004/007/008 (D-003), the
  push/PR/merge/tag/publish, and the proposal candidates (145-packet self-reference fields -- partially
  applied here via the pinned `Reviewed Implementation Head`; scaffolder `-Force` defect; Deploy-SpecrewSkill
  extraction; Proposal 178).
- **code-map form-vs-meaning WARNING reviewed + benign + JUSTIFIED**: 9 tasks vs **26 files** since the
  i1-closeout baseline (96ded099). Breakdown: **8 implementation/template** (code-rules.md skill,
  design-workshop.md conduct turn, implementer + planner charters, code-implementation.md example,
  code-implementation-lens.ps1 fix, code-rules-skill-multihost + code-implementation-lens tests) + **4
  deployed host copies** (.claude/.cursor/.github/.agents design-workshop SKILL.md) + **4 .specify mirrors**
  (code-rules.md, design-workshop.md, 2 charters) + **4 release-prep** (Specrew.psd1, extension.yml,
  .specrew/config.yml, CHANGELOG.md) + **6 iteration governance/review artifacts** (dogfood-report,
  drift-log, plan, state, quality/hardening-gate, quality/mechanical-findings.json) = 26. All in `git diff
  96ded099..da7a0129`; the heuristic expects a 1:1 task-to-file mapping, which legitimately does not hold;
  no uncommitted or unexplained source change. (Do NOT re-run the scaffolder with -Force -- known
  ShouldProcess defect.)
- Mechanical-checks: 0 findings. Validator: PASSES iterations/002 (38/38).
