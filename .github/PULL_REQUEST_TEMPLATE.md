## Summary

<!-- One or two sentences. What changed and why. -->

## Type of change

<!-- Pick the one work kind that fits. `main` is protected — every change merges via PR (see Proposal 182). -->

- [ ] Software feature closeout (full Specrew lifecycle; PR-at-feature-close)
- [ ] Bug bash / bug fix
- [ ] Docs-only (README, docs, proposals, methodology, examples — no runtime change)
- [ ] DevOps (CI/CD, repo settings, branch protection, release workflows, packaging)
- [ ] Hotfix
- [ ] Chore / repo hygiene

## Lifecycle evidence (software feature closeouts only)

<!-- Skip for docs-only / devops / hotfix / chore PRs -->

- Spec: `specs/NNN-name/spec.md`
- Plan: `specs/NNN-name/plan.md`
- Tasks: `specs/NNN-name/tasks.md`
- Iteration evidence: `specs/NNN-name/iterations/`
- Retro: `specs/NNN-name/iterations/NNN/retro.md`
- Validator status: green / warnings / failures

## Checklist

- [ ] `validate-governance.ps1` runs clean (or deferrals are documented)
- [ ] Tests pass locally (or N/A for docs-only)
- [ ] Markdown lint passes on touched docs (docs-only / proposals)
- [ ] CHANGELOG entry added (feature closeouts and hotfixes; not required for docs-only / devops with no runtime change)
- [ ] Version bumped (software-feature closeouts only, per Rule 15; never for docs-only)
- [ ] Documentation updated where shipped behavior changed
- [ ] Docs-only / devops PRs do not touch runtime source unless explicitly reclassified
