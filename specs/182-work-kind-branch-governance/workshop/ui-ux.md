# UI/UX Workshop Record: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Depth**: light (text/CLI surface)
**Confirmation**: human-confirmed (lens-question)

## Surfaces (rendered + agreed)

**Validator output** (advisory, names the gap — SC-005):

```text
[work-kind] PR #123 declares work_kind: docs-only
  ✓ exactly one work_kind declared        ✓ no open lifecycle boundary
  ✗ changed-file scope: src/validator/WorkKindValidator.ps1 is outside docs-only scope
       docs-only allows: **/*.md, docs/**, proposals/**, CHANGELOG.md
       → reclassify to software-feature/devops, OR move this change to a separate PR
  verdict: ADVISORY-FAIL (1 issue) — not blocking (phased: advisory mode)
```

**Capability report** (honest):

```text
[capability] provider=github  visibility=public  plan=pro
  → enforcement available: branch-protection (rulesets also available)
  → recommended: protect 'main' (PR-required · no force-push/delete · checks: specrew-governance, tests)
  apply? describe-only by default — apply_protection requires your approval
[capability] provider=unknown (no adapter)
  → enforcement available: ci-only / manual
  → the work-kind CI check runs anywhere; name your forge and I'll synthesize a read-only adapter
```

**Brownfield governance prompt** (adapt-or-change, FR-021):

```text
[devops-governance] detected existing posture on this repo:
  branch 'main': protected ✓ (PR-required ✓ · force-push off ✓) · required checks: [ci]
  review: 1 approval required ✓
  → ADAPT (slot the work-kind check into your existing 'ci' lane) or CHANGE (to recommended posture)?
```

**Declaration template** `.specrew/work-kind.yml` — a short commented file (`work_kind: <kind>`
plus optional notes).

## Decision

Confirmed (human-confirmed): validator messages **name the exact gap + the allowed scope +
the fix** and carry the **advisory/blocking label**; capability/brownfield reports state the
**honest mechanism** and the **adapt-or-change** choice; **describe-only by default**;
nothing claims enforcement it cannot deliver. Source of UX truth is text/console (no GUI);
accessibility/locale/RTL n/a.
