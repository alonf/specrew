# Review Diagrams: Release Pipeline Hardening + Substantive Intake Slice

**Feature**: `049-pipeline-hardening-intake`  
**Phase**: pre-implementation (planning artifact for reviewer)

---

## Component Diagram: Docker Pre-Publish Harness

```mermaid
flowchart TD
    Candidate[Package Candidate .nupkg / .zip] --> Docker[Docker E2E Test Harness]
    Baseline[Install Stable v0.27.6] --> Docker
    Docker --> FileListCheck[FileList Existence Scan]
    FileListCheck --> UpdateTest[specrew update E2E Test]
    UpdateTest --> ParityCheck[Mirror Parity Parity validation]
    ParityCheck --> PassVerdict{All Checked PASS?}
    PassVerdict -- Yes --> Publish[Publish to PSGallery]
    PassVerdict -- No --> Block[HALT Pipeline & Block Publish]
```

---

## Sequence: Persona-Driven specify Intake Flow

```mermaid
sequenceDiagram
    participant User as Human Developer
    participant Specify as specrew specify CLI
    participant AI as AI Research & Parser
    participant Spec as spec.md + checklists/requirements.md
    
    User->>Specify: specrew specify --persona pm --interactive
    Specify->>User: Displays PM intake intro & numbered 12-category options
    User->>Specify: Enters MVP criteria (with "I don't know" database fallback)
    Specify->>AI: Resolves missing database constraints (stack-aware)
    AI-->>Specify: Returns optimal lightweight database configuration
    Specify->>Specify: Dynamically selects Mode B (partial targeted clarification)
    Specify->>User: Asks 2 targeted questions
    User->>Specify: Resolves targeted questions
    Specify->>Spec: Compiles draft spec.md & checklists/requirements.md
    Specify-->>User: Outputs spec files on disk & triggers PASS confirmation
```
