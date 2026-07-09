# Software-Feature Lifecycle (template)

**Work kind**: `software-feature` · **Lifecycle weight**: full · **Produces a release**: yes (at feature-closeout → release)

Use this for product/runtime behavior and ordinary feature delivery — the **full** Specrew lifecycle.
If your change is docs-only, a defect fix, or CI/infra, it is **not** a software-feature — reclassify to
`docs-only` / `bug-bash` / `devops`, or split the PR.

Declare it: `.specrew/work-kind.yml` → `work_kind: software-feature` (branch prefix `feature/` gives the default).

## Required evidence (the full set)

- [ ] **Spec** — lens-informed `spec.md` (testable FRs, measurable SCs, scoped out-items).
- [ ] **Design workshop** — the applicable lenses worked with the human; design-analysis at the stop.
- [ ] **Plan** — iteration plan with FR→test mapping + capacity.
- [ ] **Tasks** — concrete tasks separated by work kind where relevant.
- [ ] **Implementation** — behaviour, not file-presence; runtime evidence.
- [ ] **Review** — the project's `review_gate`; a structured review against the requirement.
- [ ] **Retro** — estimation accuracy + lessons with owners.
- [ ] **Feature-closeout** — the closeout record; release/SDLC steps instantiated from the project's
      `.specrew/repository-governance.yml` (never assume a forge or registry).

## Flow

```text
specify -> clarify -> design-analysis -> plan -> tasks -> before-implement -> implement -> review ->
retro -> iteration-closeout -> feature-closeout -> (release per the project's mechanism)
```

## Notes

- Every boundary is a human-verdict stop; one approval advances at most one boundary.
<!-- specrew-self-ok: tracked debt - FR-030 (F-198 iteration 004) makes this line release-model-aware -->
- The release SDLC is instantiated from the project's governance — GitHub/PSGallery are a Specrew-own
  example, **not a downstream mandate**.
- A post-merge finding is a **new** work item, never a reopen of the merged feature.