# Design Lens Knowledge Pack

This folder is the source catalog for design-analysis lenses. A lens is a
small, reusable knowledge file that tells the Crew when an architectural area
is relevant, which questions to ask, which alternatives to compare, and what
planning obligations must be recorded before implementation.

<!-- specrew-self-ok: catalog source attribution - the lens corpus is distilled from the credited book/course -->
The initial catalog is distilled from Alon Fliess' architecture book markdown
and Software Architecture course material. It is deliberately paraphrased into
Specrew-operational questions instead of copying source text.

## Current Lenses

In `index.yml` order, which is the one workshop order (problem space first); `index.yml` also gives each lens
its `space` (problem, solution or both):

- `product-domain.md` - users and stakeholders, pain and current workaround,
  constraints, outcomes, MVP and non-goals (the required first phase).
- `requirements-nfr.md` - measurable quality attributes, constraints, scope,
  and requirement-discovery gaps.
- `ui-ux.md` - UI references, flows, state, paging/sorting/grouping, async
  behavior, accessibility, and themes.
- `security-compliance.md` - identity, authorization, privacy, auditability,
  threat surfaces, and regulatory constraints.
- `data-storage.md` - databases, state ownership, storage choices, consistency,
  migrations, and retention.
- `integration-api.md` - service contracts, REST, GraphQL, gRPC, events,
  queues, versioning, and compatibility.
- `devops-operations.md` - hosting, IaC, CI/CD, environments, secrets, rollout,
  and operability.
- `architecture-core.md` - architecture framing, stakeholders, decomposition,
  volatility, and decision records.
- `component-design.md` - layering, component responsibility, coupling,
  cohesion, DI, schema decoupling, and extension patterns.
- `observability-resilience.md` - logging, metrics, traces, health, alerts,
  error handling, retry/idempotency, and recovery.
- `code-implementation.md` - how the code is written: the code-rules catalog,
  the per-feature implementation-rules manifest, and dependency policy (runs last).

## Adding A New Area

1. Copy `lens-template.md` to `<area-id>.md`.
2. Fill every required section from `lens-schema.md`.
3. Add the new entry to `index.yml`.
4. Keep source notes as high-level anchors, not long copied passages.
5. Prefer questions that affect a design choice, not generic checklists.

## Runtime Intent

Future implementation should load this catalog during design-analysis and use
the applicability signals to select only the lenses that fit the feature. The
catalog should remain editable data, not hard-coded prompt prose.
