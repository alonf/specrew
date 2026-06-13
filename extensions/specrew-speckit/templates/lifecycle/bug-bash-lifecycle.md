# Bug-Bash Lifecycle (template)

**Work kind**: `bug-bash` · **Lifecycle weight**: focused · **Produces a release**: per the fix (often a patch)

Use this for defect fixes or a bundled regression sweep — a **focused** bug lifecycle, lighter than a
software-feature but heavier than docs-only. If the change adds new product behavior, it is a
`software-feature`, not a bug-bash — reclassify or split.

Declare it: `.specrew/work-kind.yml` → `work_kind: bug-bash` (branch prefix `fix/` gives the default).

## Required evidence (the focused set)

- [ ] **Bug list** — the defect(s) being fixed, each with a reproduction or failing signal.
- [ ] **Root cause** — the named cause per bug (not just the symptom).
- [ ] **Fix evidence** — the change + proof the failing signal now passes.
- [ ] **Regression tests** — a test that would have caught each bug, now green.
- [ ] **Closeout** — a closeout note; release per the project's mechanism if the fix ships.

## Flow

```text
bug-list + root-cause -> fix -> regression-tests -> review -> closeout -> merge -> (patch release if shipped)
```

## Notes

- A fix that grows into new behavior should be split: keep the bug-bash focused, open a separate
  `software-feature` for the new behavior.
- Release steps, if any, instantiate from the project's `.specrew/repository-governance.yml` — never
  assume a forge or registry.
