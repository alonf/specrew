---
proposal: 055
title: Always-In-Flow Discipline + Slice-Type Catalog (Including Bug-Fix Lifecycle)
status: candidate
phase: phase-2
estimated-sp: 18
discussion: tbd
---

# Always-In-Flow Discipline + Slice-Type Catalog

## Why

Specrew's 7-boundary lifecycle (specify → clarify → plan → tasks → implement → review → retro → iteration-closeout → feature-closeout) was designed for new features. The trial-project case study on 2026-05-18 surfaced a real gap:

A downstream Specrew project hit a rendering bug ("balls are black" — a `vertexColors: true` flag on a geometry without per-vertex color attribute). Squad was correctly invoked: Reviewer + Implementer ran in parallel, the Reviewer flagged a plausible-but-incorrect root cause (missing environment map for metallic materials), the Implementer identified the actual cause (the vertexColors flag), and a guard test was added.

The fix was captured pragmatically — `.squad/decisions.md` entry, session log, bookkeeping commit (`4b0d830`). But the formal lifecycle was bypassed:

- No spec amendment recording what changed in Feature 002's behavior contract
- No new iteration or retro artifact set
- No SP accounting (the work doesn't appear in velocity metrics)
- No traceable scope authorization (who decided this fix should ship vs being deferred?)
- No roadmap.yml update
- No proposal/issue linkage

**Squad invented a lightweight path that happened to work.** Next time someone fixes a bug, Squad may invent a different path. Inconsistency creeps in.

The underlying methodology directive (per user, 2026-05-18): **Specrew must govern ALL user requests through a sanctioned flow with evidence of any change.** Not just new features — bug fixes, test additions, refactors, doc updates, dependency upgrades, hot fixes all need a sanctioned flow.

This proposal formalizes that directive: a slice-type catalog with per-slice flows, intake routing, a universal evidence rule, and override discipline.

## Background and design context

The trial-project bug fix is the motivating case. But the same pattern recurs across many change types Specrew doesn't currently govern:

| Change type | Current Specrew governance | Typical handling | Evidence captured |
|---|---|---|---|
| New feature | 7-boundary lifecycle | Full lifecycle | Comprehensive |
| Bug fix on shipped feature | None (ad-hoc) | Squad invents a path | Decision-ledger entry; guard test if author thinks of it |
| Test addition | None | Chore commit | Commit message only |
| Refactor | None | Chore commit or unspoken | Often nothing beyond the diff |
| Documentation update | None | Chore commit | Commit message only |
| Dependency upgrade | None | Manual edit + check tests | Decision-ledger entry occasionally |
| Hot fix (urgent prod issue) | None | Whatever the maintainer thinks of in the moment | Often nothing |

Every row except "new feature" is a methodology gap. The trial-project case proved the gap is real and the cost is real (lost spec-amendment, lost retro lesson, lost SP accounting).

Specrew's 7-boundary lifecycle is wrong as a one-size-fits-all because it assumes scope is unknown at start. For a bug fix, scope IS known (the bug is the scope). specify/clarify are 90% overhead. So projects rationally skip the lifecycle for these changes — and lose all governance for them.

The solution: per-slice-type flows with sanctioned minimum boundaries. Each slice has a different lifecycle shape appropriate to its change class. All share the universal evidence rule.

## What

### The universal principle

**Every user request enters a sanctioned flow that produces durable evidence of every change.**

There is no "ad-hoc work" path. Whether the request is a new feature, a bug fix, a test addition, a refactor, a documentation update, or a dependency upgrade — it enters a flow at intake, follows that flow's boundaries, and produces evidence (artifacts + decision-ledger entries + commit references + retro contributions).

### The slice-type catalog (v1)

Seven slice types. Each has a defined flow shape, minimum boundaries, evidence bundle, capacity model, and retro requirement.

| Slice | Use case | Boundaries | Min evidence | Capacity model |
|---|---|---|---|---|
| **new-feature** | A new capability not yet specified | specify → clarify → plan → tasks → implement → review → retro → iteration-closeout → feature-closeout (current 7-boundary, unchanged) | Full lifecycle artifacts | SP-based, multi-iteration |
| **bug-fix-repair** | Bug in a shipped feature | diagnose → fix-with-guard-test → verify → retro+close | Bug context (root-cause analysis); fix commit; guard test; spec amendment if behavior changed; retro entry | SP-bounded (default ≤8 SP per slice; escalate to new-feature if larger) |
| **test-add** | Adding test coverage for existing behavior | scope → write → verify → close | Coverage scope statement; test file commits; passing run; brief lessons-learned | SP-bounded (default ≤5 SP) |
| **refactor** | Restructuring without behavior change | justify → execute → verify-no-regression → close | Justification (why refactor; what changes); diff; passing test suite; brief impact note | SP-bounded (default ≤8 SP; >8 SP escalates to new-feature) |
| **doc-update** | Documentation-only changes | scope → write → review-by-human → close | Scope; commit; brief review confirmation | SP-bounded (default ≤3 SP) |
| **dependency-upgrade** | External tool/library version bump | assess → upgrade → test → close | Upgrade rationale; lockfile/version-pin diff; passing test suite; security/breaking-change notes | SP-bounded (default ≤5 SP) |
| **hot-fix** | Urgent production issue | diagnose (compressed) → fix → close → mandatory-post-hoc-retro | Bug context; fix commit; mandatory retro within 48 hours; spec amendment if needed | Time-bounded (≤4 hours wall-clock; no SP cap) |

The catalog is extensible — community-contributed slices can extend it per Proposal 052's profile architecture (see "Composition" below).

### Intake routing

Squad's first question at intake shifts from "what feature do you want to build?" to **"what type of change is this?"**:

```text
What type of change are you making?
  [1] New feature             — new capability not yet specified
  [2] Bug fix                 — fix a defect in shipped behavior
  [3] Test addition           — add coverage for existing behavior
  [4] Refactor                — restructure without behavior change
  [5] Documentation update    — docs/README/comments only
  [6] Dependency upgrade      — external tool/library version bump
  [7] Hot fix                 — urgent production issue (compressed flow)
  [other]                     — describe and I'll route to the closest slice
```

The user selects (or describes) the change type. Squad routes to the appropriate slice template. The user can override the routing but cannot bypass having a flow.

### The universal evidence rule

Regardless of slice type, every change must produce:

1. **Scope statement** — what changed, by what authority, when. Records human authorization or auto-routed slice activation.
2. **Implementation evidence** — commit references with explicit change rationale.
3. **Verification evidence** — tests run, validators invoked, what passed.
4. **Post-change reconciliation** — spec.md amendments if behavior changed; roadmap.yml SP accounting if applicable; INDEX or similar surface updates.
5. **Lessons captured** — retro contribution, even if light. Minimum: a sentence or two for trivial slices; full retro structure for larger.

The evidence bundle is per-slice-tailored (a doc-update doesn't need extensive test evidence; a refactor needs strong "no regression" evidence). But all slices produce the five categories at appropriate scale.

### Override discipline

The user can override slice routing — e.g., "I know this is technically a bug fix but I want to treat it as a new feature for the additional governance." Override is recorded as part of the scope statement.

The user can NOT bypass having a flow. There is no "no governance" emergency path. Even hot-fix has a mandatory post-hoc retro within 48 hours; the slice shape just compresses the upfront work, not the evidence.

If the user attempts to bypass (e.g., directly commits to main without a slice authorization), Squad records the bypass as a flow violation in `.squad/decisions.md` and surfaces it in the next dashboard render. The bypass itself is the evidence, but it's flagged for retrospective review.

### Per-slice minimum-viable evidence bundle (illustrative)

**bug-fix-repair** slice (e.g., the trial-project "balls are black"):

```text
Scope statement:
  Type: bug-fix-repair
  Authority: Alon Fliess (or other human approver)
  Date: 2026-05-18T17:18:00Z
  Trigger: User reported "the balls are black" on 2026-05-18
  Feature ref: 002-ball-appearance (shipped)

Diagnose (Implementer + Reviewer):
  - Implementer root-cause: vertexColors flag on geometry without color attribute
  - Reviewer competing hypothesis: missing environment map (rejected after Implementer evidence)
  - Captured as decision-ledger entry; divergence preserved for retro

Fix + guard test:
  - Commit 81df10f: remove vertexColors flag from BallGeometry.tsx
  - Commit (new): add tests/integration/ball-rendering-vertex-color.tests.ps1
    asserting BallGeometry.tsx never sets vertexColors without color attribute

Verify:
  - tests/integration/ball-rendering-*.tests.ps1: PASS
  - Manual visual check: balls render with correct colors
  - Specs/002-ball-appearance regression suite: PASS

Post-change reconciliation:
  - specs/002-ball-appearance/spec.md amended:
    - "vertexColors flag MUST NOT be set on BallGeometry's meshStandardMaterial
       unless the geometry includes a per-vertex color attribute"
  - .specrew/roadmap.yml feature 002 phase-2 entries: +2 SP for the repair
    (categorized as bug-fix SP, not new-feature SP)

Lessons captured (retro):
  - Three.js vertexColors flag requires geometry color attribute; missing
    attribute makes shader read black
  - Reviewer's first-pass hypothesis (env map for metallic) was plausible
    but incorrect; Implementer's code-trace caught the actual cause
  - Guard test pattern: assert configuration consistency (vertexColors ⟺
    color attribute present); prevents recurrence
```

Compare to today's ad-hoc capture: decision-ledger entry + session log + bookkeeping commit. Same artifacts, but the slice flow ensures consistency.

## Effort

~18 SP across two iterations:

### Iteration 1 (~10 SP) — Catalog + intake + bug-fix slice

- Catalog definition (the 7 slice types with their flows + evidence bundles) — ~2 SP
- Intake routing — Squad coordinator-prompt update to ask the type-of-change question — ~2 SP
- Bug-fix-repair slice implementation (boundary scripts + templates + decision-log conventions) — ~3 SP
- Hot-fix slice implementation (compressed boundaries; mandatory post-hoc retro tracking) — ~2 SP
- Override semantics (record overrides in scope statement; surface in dashboard) — ~1 SP
- Bypass detection (catch direct main commits without slice authorization; flag in dashboard) — ~1 SP (composes with Proposal 021 Bypass Detector if shipped)
- Tests + documentation — ~1 SP

### Iteration 2 (~8 SP) — Remaining slices + composition

- Test-add slice — ~1 SP
- Refactor slice — ~1.5 SP
- Doc-update slice — ~1 SP
- Dependency-upgrade slice — ~2 SP
- Composition with Proposal 054 (each slice has its own gate scenarios) — ~1 SP
- Composition with Proposal 047 (slice routing as governance dial) — ~1 SP
- Composition with Proposal 052 (slices as profile-extensible) — ~0.5 SP

## Phase placement

**Phase 2 HIGH-PRIORITY, post-F-022 consolidation.** Multiple arguments for early shipping:

1. **Foundational**: every subsequent Specrew change should run through a slice. Earlier shipping = more downstream changes get the discipline.
2. **Recurring gap evidence**: F-019, F-020, F-021, F-022 all exhibited bookkeeping/discipline issues that slice-type flows would address.
3. **Trial-project gap**: the "balls are black" case is empirical proof that downstream projects already need this.
4. **Composes with multiple in-flight proposals**: 030, 052, 054, 047 all reference slice concepts that Proposal 055 formalizes.

Sequencing: ship after the consolidation pass + Phase A first-priority items, before larger architecture work (024, 052, 057, 058).

## Composition with existing queue

| Proposal | How 055 composes |
|---|---|
| **030 (Quality Hardening Bundle — Form-vs-Meaning Verification)** | The evidence rule IS the form-vs-meaning enforcement layer for non-feature changes. 055's evidence requirements absorb 030's relevant sub-components. |
| **052 (Specrew Profile System)** | Slice types are profile-extensible. Community/ecosystem can author additional slice types per their domain (security-incident-response slice, accessibility-audit slice, etc.). |
| **054 (Pre-Merge Lifecycle Verification Gate)** | Each slice type needs its own gate scenarios. 054's Scenario A (full lifecycle ship-and-restart) becomes a family of scenarios — one per slice. |
| **047 (Project Governance Profile)** | Slice routing default becomes a configurable dial (`default_slice_routing: interactive` vs `auto-detect` vs `always-new-feature` etc.). |
| **021 (Bypass Detector)** | Bypass detection in 055 composes tightly with 021. If 021 ships first, 055 uses its detector. If 055 ships first, it includes a minimal bypass-detection rule. |
| **022 (Spec-Reconciliation Detector)** | When a slice amends a spec, 022's detector verifies the amendment is consistent with iteration history. |
| **017 (Learning Loop Closure)** | Each slice retro feeds 017's corpus. Slice-tagged retro entries enable per-slice-type learning. |

## Open questions

1. **Slice escalation semantics**: if a bug-fix-repair starts as ≤8 SP but grows during diagnose, when does it escalate to new-feature? Recommend: at the diagnose-completion checkpoint, the slice authorizer reviews scope; if >8 SP, escalate explicitly.
2. **Hot-fix authorization**: who can authorize a hot-fix (compressed flow)? Recommend: any human; but the post-hoc retro must record who and why.
3. **Dependency-upgrade slice vs new-feature**: when does a dependency upgrade graduate to needing new-feature treatment? E.g., a major-version SDK bump that breaks behavior contracts. Recommend: if the upgrade requires spec amendments to >2 features OR introduces breaking API changes, escalate.
4. **Slice nesting**: can a bug-fix slice contain a refactor slice? E.g., "fix this bug AND refactor adjacent code". Recommend: prefer two slices in sequence rather than nesting; document the dependency in scope statements.
5. **Per-slice retro requirement**: doc-update slice's retro could be a single sentence ("LGTM; no lessons"). What's the minimum? Recommend: one sentence is acceptable for trivial slices; longer for non-trivial.
6. **Slice numbering**: do slices get the same `NNN-name` numbering as features, or a distinct identifier scheme? Recommend: distinct — slices use `slice-<NNN>` or short prefix. Numbers continue across slice types.
7. **Multi-slice features**: can a single user request decompose into multiple slices (e.g., "add doc + fix bug + write test for both")? Recommend: yes; intake routing surfaces this; the user confirms decomposition.
8. **Override audit**: when a user overrides the routing (e.g., treats bug-fix as new-feature), is the original routing recommendation captured? Recommend: yes; the override record includes the auto-detected slice for retrospective analysis.
9. **Bypass remediation**: if a bypass is detected (direct commit to main without slice), what's the remediation? Recommend: capture as a flow-violation slice (a meta-slice); next session prompts the maintainer to retroactively author the missing slice.
10. **Slice catalog evolution**: how do new slice types get added (community-contributed vs core-authored)? Recommend: profile-extensible per Proposal 052; core-authored anchors first, community follows.

## Risks

- **Over-governance for tiny changes**: a doc fix shouldn't require a multi-step flow. Mitigation: doc-update slice is intentionally minimal (1-3 SP, scope+write+review+close); slice ceremony is proportional to change size.
- **Slice catalog drift**: too many slice types becomes confusing. Mitigation: v1 ships 7 well-defined slices; community-contributed slices come through Proposal 052's profile mechanism with quality review.
- **Override misuse**: users override routing to dodge appropriate governance. Mitigation: override is recorded; periodic retros flag override patterns; dashboard surfaces them.
- **Slice nesting confusion**: if slices can nest, the boundary semantics get unclear. Mitigation: v1 forbids nesting; multi-change requests decompose into sequential slices.
- **Methodology learning curve**: existing Specrew users (who know the 7-boundary lifecycle) must learn the slice catalog. Mitigation: documentation; intake routing prompt is self-explanatory; existing features continue using new-feature slice unchanged.
- **Bypass detection accuracy**: detecting direct main commits without slice authorization may produce false positives (e.g., legitimate emergency commits). Mitigation: WARN-only initially; promote to FAIL after observed practice.

## Cross-references

- **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning Verification)** — evidence rule layer
- **Proposal 052 (Specrew Profile System)** — slice extensibility
- **Proposal 054 (Pre-Merge Lifecycle Verification Gate)** — per-slice gate scenarios
- **Proposal 047 (Project Governance Profile)** — slice routing as configurable dial
- **Proposal 021 (Bypass Detector)** — composes with bypass detection in 055
- **Proposal 022 (Spec-Reconciliation Detector)** — slice spec amendments trigger reconciliation check
- **Proposal 017 (Learning Loop Closure)** — slice retros feed the corpus pipeline
- **Memory: [Always-in-flow + universal-evidence](file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/feedback_always_in_flow_universal_evidence.md)** — the principle this proposal formalizes
- **Trial-project case study (sphere-rendering "balls are black", 2026-05-18)** — motivating empirical evidence

## Status history

- 2026-05-18: candidate captured after trial-project bug-fix analysis surfaced the methodology gap. User directive: Specrew must govern ALL user requests through a sanctioned flow with evidence. Slice-type catalog (7 types) + intake routing + universal evidence rule + override discipline drafted as the resolution.
- 2026-05-19: drafted as full proposal during the post-F-022 consolidation pass. Composition with proposals 030, 052, 054, 047, 021, 022, 017 made explicit.
