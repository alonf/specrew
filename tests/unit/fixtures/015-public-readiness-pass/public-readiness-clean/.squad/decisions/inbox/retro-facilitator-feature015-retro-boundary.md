# Retro Facilitator Inbox: Feature 015 Iteration 001 Retro Boundary

**Date**: 2026-05-13  
**Feature**: `015-public-readiness-pass`  
**Iteration**: `001`

## Candidate Rule 1

**Name**: `boundary-claim-without-commit`  
**Category**: `boundary-discipline`

### Proposed Rule: Boundary Claim

Do not narrate a lifecycle boundary as complete until the matching durable commit already contains the
boundary artifact plus truthful `plan.md` and `state.md` lifecycle updates. Until Feature 016
Substantive Interaction Model Pillar 1 graduates hard rule
`validation-fail.bundled-boundary-advance`, treat this as a manual stop condition.

### Evidence: Boundary Claim

- Feature 014 iteration 001 review boundary commit `8e99013`
- Feature 014 iteration 001 retro boundary commit `a5fcb90`
- Feature 015 iteration 001 review boundary commit `6ca218f`

## Candidate Rule 2

**Name**: `branch-name-mismatch-with-feature-directory`  
**Category**: `planning-discipline`

### Proposed Rule: Branch Name

Before scaffolding planning artifacts or recording a planning boundary, verify that the active branch
name matches the feature directory. If they differ, stop, repair the branch, and fix any generated
references before the next durable commit.

### Evidence: Branch Name

The mistaken orphan branch `016-public-readiness-pass` required cleanup plus repaired references in:

- `specs/015-public-readiness-pass/research.md`
- `specs/015-public-readiness-pass/data-model.md`
- `specs/015-public-readiness-pass/quickstart.md`
- `specs/015-public-readiness-pass/checklists/requirements.md`
- `specs/015-public-readiness-pass/iterations/001/plan.md`

### Current Gap

No validator rule currently checks branch name against feature directory before the planning boundary
is committed.
