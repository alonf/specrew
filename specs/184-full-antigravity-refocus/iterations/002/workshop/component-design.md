# Component Design Lens: Iteration 002

**Depth**: medium  
**Confirmation**: human-confirmed / lens-question

## Decision

Reuse the existing host registry, `InstructionsFile` manifest field,
managed-block merge pattern, and atomic-write helpers. Add one focused
manifest-driven instruction-file deployment component. It owns reading each host
`InstructionsFile` target, creating the file if absent, and replacing only the
Specrew-owned delimited section when present. It must leave user-authored
content outside that section untouched.

The content source should be a packaged static pointer-based template or
fragment, included in the package file list, rather than host-specific behavior
created ad hoc.

## Proposed Component Map

```text
Init orchestration
    |
    v
Host manifest resolver --> Instruction section renderer
    |                         |
    v                         v
Instruction file merger --> AGENTS.md / equivalent
    ^
    |
Bootstrap prompt builder
```

## Components

- `Host manifest resolver` - resolves each enabled host and its
  `InstructionsFile` declaration.
- `Instruction section renderer` - produces the Specrew-owned coordinator
  section with the anti-raw-workflow guard.
- `Instruction file merger` - preserves user content and replaces only the
  managed section.
- `Bootstrap prompt builder` - front-loads immediate action and carries the same
  guard in session bootstrap text.

## Key Flow

`specrew init` -> host manifest -> render Specrew section -> merge file ->
host launch reads persistent coordinator instruction.
