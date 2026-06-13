# Quickstart: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Last verified**: 2026-06-11 (planning artifact — runtime steps land in Iter 1/2)

## Run it

```pwsh
# From the repo root. (Iter 2 deliverables — paths per plan.md Project Structure.)
Import-Module ./Specrew.psd1 -Force

# 1) Declare a work kind for the current work item
@'
work_kind: docs-only
schema_version: "1.0"
notes: "README clarification, no runtime change"
'@ | Set-Content .specrew/work-kind.yml

# 2) Run the provider-neutral work-kind validator against the current branch vs the base
pwsh -File extensions/specrew-speckit/scripts/work-kind-validator.ps1 -ProjectPath . -BaseRef origin/main

# 3) Detect what branch protection this repo can actually enforce (read-only)
pwsh -File extensions/specrew-speckit/scripts/capability-detector.ps1 -ProjectPath .
```

## Try the canonical scenario

1. **Declare** `work_kind: software-feature` in `.specrew/work-kind.yml` on a feature branch.
2. **Change** a runtime file + its test, and add the feature's closeout evidence.
3. **Run** the validator → expect `ADVISORY-PASS` (one kind, changed files within
   `software-feature` scope, closeout evidence present, no open lifecycle boundary).
4. **Now** declare `work_kind: docs-only` on that same branch and re-run → expect
   `ADVISORY-FAIL` naming the exact gap: the runtime file is outside `docs-only` scope, with the
   allowed scope listed and the fix (reclassify, or split the change).

## Verify the edge cases

- **No declaration** → the validator infers from the branch prefix if configured (`docs/…`),
  else emits an advisory WARN telling you to add `.specrew/work-kind.yml` — never a hard block.
- **No provider adapter** (non-GitHub or unknown) → the validator still runs via `git diff` +
  `branch_model`; `capability-detector` reports `ci-only`/`manual` and offers to synthesize a
  read-only adapter once you name your forge.
- **Brownfield repo** with existing protection + a CI lane → the DevOps lens shows the detected
  posture and asks **ADAPT** (slot the check into your existing lane) or **CHANGE** (recommended
  posture) — it never overwrites.
- **Post-merge finding** → follow `docs/methodology/work-kinds.md`: open a NEW docs-only/devops/
  bug-bash work item + a release-validation record; do NOT reopen the merged feature.
- **apply_protection** → `describe_protection` runs read-only by default; applying protection
  requires explicit human approval and your own forge token (Specrew stores no secret).
