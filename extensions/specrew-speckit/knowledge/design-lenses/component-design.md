# Component Design Lens

## Lens ID

`component-design`

## Purpose

Keep implementation structure aligned with responsibilities, volatility,
coupling, cohesion, extension needs, and testability.

## Applicability Signals

- The feature introduces or modifies shared modules, helpers, generators,
  services, layers, engines, accessors, SDKs, plugins, or schema mapping.
- The change risks duplicated logic, hidden coupling, or unclear ownership.
- Different callers need the same capability with different policies.

## Design Decision Points

- What responsibilities belong together, and what should stay separate?
- Which dependencies point inward vs outward?
- Is the right abstraction a function, helper, module, service, plugin, engine,
  accessor, data file, generated artifact, or SDK?
- Where should schemas be decoupled from internal models?
- What extension mechanism fits: inheritance, composition, configuration,
  events, aspect, plugin, or generated code?

## Question Bank

- What is the unit of responsibility?
- Which part changes most often?
- Which part should be stable and depended on by others?
- What dependency would make future change expensive?
- Is the abstraction created because there is real variation?
- How will tests exercise the component without relying on implementation
  internals?
- Are we sharing schema/contract or sharing classes/binaries?
- Does this need DI, factory, registry, plugin lookup, or simple construction?

## Alternative Dimensions

- **Simplest**: local implementation with named boundaries and no premature
  abstraction.
- **Reasonable**: helper/module with clear contracts, tests, and limited
  extension points.
- **By the book**: layered design, explicit contracts, dependency inversion,
  schema decoupling, plugin/extension mechanism, and component-level diagrams.

## Plan Obligations

- Record ownership, dependencies, extension points, and test seams.
- Justify any new abstraction by variation, complexity, or reuse.
- Identify schema/DTO mapping and compatibility if external contracts exist.

## Validation Signals

- Tests cover behavior through the public seam.
- Review checks that coupling did not increase across ownership boundaries.
- Generated or configured behavior has parity/drift checks when applicable.

## Source Notes

- Book Chapters 3 and 5.
- Course Modules 3, 4, and 5.
