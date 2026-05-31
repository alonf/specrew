# Quickstart: Discoverable Spec Kit Surfaces

## Goal

Make `/speckit.checklist` and `/speckit.analyze` easy to discover as standard Specrew capabilities while keeping their lifecycle placement truthful and keeping `/speckit.taskstoissues` explicitly deferred.

## Implementation-ready walkthrough (for the later approved boundary)

1. Update the standard user-facing discovery surfaces:
   - `README.md`
   - `docs/user-guide.md`
   - `.github/agents/speckit.plan.agent.md`
   - `.github/agents/speckit.tasks.agent.md`
   - `.github/prompts/speckit.checklist.prompt.md`
   - `.github/prompts/speckit.analyze.prompt.md`
   - `.github/agents/speckit.taskstoissues.agent.md` and `.github/prompts/speckit.taskstoissues.prompt.md` only where needed to make its deferred status explicit
2. Apply the lifecycle contract consistently:
   - `/speckit.checklist` appears before-plan as a requirements-quality aid
   - `/speckit.checklist` remains proportional for lightweight/low-risk slices
   - `/speckit.analyze` appears before-implement only after `/speckit.tasks` has produced a complete `tasks.md`
   - `/speckit.analyze` is described as additive to Specrew governance, never a replacement
   - `/speckit.taskstoissues` is called out as deferred, not silently omitted or implied active
3. Keep discovery surfaces aligned with supported extension metadata and existing lifecycle boundaries; do not invent new hooks or move the approved commands to different stages.

## Validation commands

```powershell
npx --yes markdownlint-cli README.md docs/user-guide.md .github/agents/*.md .github/prompts/*.md specs/054-activate-spec-surfaces/*.md
pwsh -NoProfile -File tests/integration/slash-command-discovery.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-routing.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-coexistence.tests.ps1
pwsh -NoProfile -File tests/integration/lifecycle-boundary-sync.tests.ps1
pwsh -NoProfile -File tests/integration/validation-contract-lane.ps1
```

## Manual acceptance checks

1. A user reading the standard lifecycle guidance can identify `/speckit.checklist` as a before-plan capability without opening the proposal.
2. The same user can tell that `/speckit.checklist` is recommended for substantive work but not falsely mandatory for lightweight slices.
3. A user looking for `/speckit.analyze` before `tasks.md` exists is told when it becomes relevant.
4. Every updated surface uses the same lifecycle placement for checklist and analyze.
5. Any mention of `/speckit.taskstoissues` states that it is deferred for a later version.

## Boundary reminder

This feature is currently at the approved `tasks` boundary and `tasks.md` exists. Do not start before-implement work, implementation edits, or hardening execution evidence until a later human approval advances the next boundary.
