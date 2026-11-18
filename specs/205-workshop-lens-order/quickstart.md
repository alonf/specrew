# Quickstart: Workshop Lens Order

**Feature**: 205-workshop-lens-order
**Last verified**: planned (verified at review)

## Run it

```powershell
pwsh -NoProfile -File tests/unit/lens-order-parity.tests.ps1
pwsh -NoProfile -File tests/integration/workshop-agenda-confirmation.tests.ps1
```

## Try the canonical scenario

1. On the unchanged tree, before implementation, run the parity test.
   **Expected**: exit 1. Every disagreeing surface is listed in one run, with at least the five known orders: the
   skill, the full lists against `index.yml`, the methodology, before-specify, and the partial lists. Each line
   shows file:line, the expected order, the order found, and the fix.
2. After implementation, run it again.
   **Expected**: exit 0, with a summary line counting the surfaces, lens files and copies checked.
3. Open `extensions/specrew-speckit/knowledge/design-lenses/index.yml`.
   **Expected**: product-domain, requirements-nfr, ui-ux, security-compliance, data-storage, integration-api,
   devops-operations, architecture-core, component-design, observability-resilience, code-implementation, each
   with a `space`.

## Verify the edge cases

1. **Out-of-order agenda**: confirm an agenda that lists architecture-core before requirements-nfr.
   **Expected**: a refusal that names both lenses and the `index.yml` order. The agenda is neither reordered nor
   written.
2. **Old confirmed agenda (FR-013)**: resume a fixture agenda that was confirmed with architecture-core first, then
   close its lenses.
   **Expected**: it completes, and nothing re-checks the order.
3. **Stale deployed copy**: change one line in the source of a lens file only.
   **Expected**: the parity test fails on that copy and names `deploy-speckit-extension.ps1 -ProjectPath .
   -RefreshExisting` and `deploy-squad-runtime.ps1 -ProjectPath .`. It says they write inside the project only,
   and that they also restamp `.squad` files.
4. **Wrong heading**: move a solution question under `### Problem questions` in a lens tagged `solution`.
   **Expected**: check c fails for that lens.
