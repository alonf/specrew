# Review Diagrams: Post-Ship Proposal Amendment Discipline

**Feature**: 168-post-ship-proposal-amendment-discipline
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart LR
  Proposal[Proposal Markdown] --> Parser[Proposal Front Matter and Amendment Reader]
  Parser --> Mutability[Mutability Classifier]
  Mutability --> Validator[Governance Validator]
  Parser --> Status[Proposal Index or Status Surface]
  Validator --> Findings[Warning and Malformed-Amendment Findings]
  Status --> Backlog[Unimplemented Amendment Visibility]
  Proposal --> Reviewer[Reviewer Guidance]
  Reviewer --> Evidence[Delta-Based Review Evidence]
```

## Sequence: shipped proposal amendment validation

```mermaid
sequenceDiagram
  participant Maintainer
  participant Proposal as Proposal Fixture
  participant Validator
  participant Status as Index/Status Surface
  participant Reviewer

  Maintainer->>Proposal: records post-ship amendment delta
  Validator->>Proposal: reads status and amendments
  Validator-->>Maintainer: warns only for unsafe normative body edits
  Status->>Proposal: reads unimplemented amendment states
  Status-->>Maintainer: shows A1 accepted-unimplemented
  Reviewer->>Proposal: checks amendment id, preserve list, tests required
  Reviewer-->>Maintainer: confirms delta-based evidence or sends back
```
