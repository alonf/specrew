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

- `architecture-core.md` - architecture framing, stakeholders, constraints,
  volatility, and decision records.
- `requirements-nfr.md` - measurable quality attributes, constraints, and
  requirement-discovery gaps.
- `data-storage.md` - databases, state ownership, storage choices, consistency,
  migrations, and retention.
- `ui-ux.md` - UI references, flows, state, paging/sorting/grouping, async
  behavior, accessibility, and themes.
- `devops-operations.md` - hosting, IaC, CI/CD, environments, secrets, rollout,
  and operability.
- `integration-api.md` - service contracts, REST, GraphQL, gRPC, events,
  queues, versioning, and compatibility.
- `security-compliance.md` - identity, authorization, privacy, auditability,
  threat surfaces, and regulatory constraints.
- `observability-resilience.md` - logging, metrics, traces, health, alerts,
  error handling, retry/idempotency, and recovery.
- `component-design.md` - layering, component responsibility, coupling,
  cohesion, DI, schema decoupling, and extension patterns.

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