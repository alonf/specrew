# Specrew — Spec-Governed AI Crew Operating Model

Specrew is a spec-governed operating model for AI crews that combines [Spec Kit](https://github.com/microsoft/copilot-specify) as the specification/governance layer with [Squad](https://github.com/microsoft/copilot-squad) as the persistent multi-agent runtime layer.

## Status

**Current Phase**: Foundation (Iteration 0)  
**Branch**: `001-specrew-product`  
**Version**: Pre-MVP Development

## What is Specrew?

Specrew ensures AI agent teams build what was specified by:

- Making the **spec** the authoritative source of truth
- Providing **structured iteration delivery** with planning, execution, and review ceremonies
- Detecting and surfacing **drift** when implementation diverges from specification
- Enabling **traceability** from requirements to tasks to implementation
- Supporting **governance** through roles, capacity planning, and retrospectives

## Architecture

Specrew is delivered as two companion extensions:

1. **Spec Kit Extension** (`extensions/specrew-speckit/`) — Governance artifacts, templates, validation scripts
2. **Squad Extension** (`extensions/specrew-squad/`) — Skills, ceremonies, and directives for iteration delivery

## Repository Structure

```
extensions/          # Specrew extensions (Spec Kit + Squad)
specs/               # Feature specifications and iteration plans
tests/               # Test suites
evaluation/          # Evaluation harness and scorers
docs/                # Documentation
.github/             # GitHub workflows and templates
```

## Getting Started

Specrew is currently under active development. Bootstrap and installation instructions will be available after Iteration 0 completes platform validation.

## Development

This project uses:
- **Spec Kit** >= 0.7.3 for specification governance
- **Squad** >= 0.9.1 for multi-agent orchestration
- Markdown, YAML, and PowerShell for extension assets

## License

TBD

## Contributing

Contribution guidelines will be established post-MVP.
