# Review Diagrams: Iteration 001

**Schema**: v1
**Diagram Format**: mermaid

## Structure Diagram

```mermaid
graph TD
    Start["scripts/specrew-start.ps1"]
    Handoff[".specrew/last-start-prompt.md"]
    PromptFiles["Session-loaded prompt files"]
    DetectorTest["specrew-start-change-detector.ps1"]
    BaselineTest["specrew-start-baseline-tracking.ps1"]
    AutoContinueTest["specrew-start-auto-continue-preservation.ps1"]
    TrapCorpus[".specrew/quality/known-traps.md"]

    Start --> Handoff
    Start --> PromptFiles
    DetectorTest --> Start
    BaselineTest --> Start
    AutoContinueTest --> Start
    TrapCorpus --> Start
```

## Flow Diagram

```mermaid
flowchart TD
    A["specrew-start.ps1 begins"] --> B{"Bootstrap surface valid?"}
    B -- No --> Z["Preserve existing failure path"]
    B -- Yes --> C["Read baseline_commit_hash from YAML frontmatter"]
    C --> D["Diff baseline commit to HEAD across session-loaded paths"]
    D --> E{"Any committed prompt-surface changes?"}
    E -- No --> F["Preserve auto-continue handoff"]
    E -- Yes --> G["Record changed-file signal for later pause logic"]
    F --> H["Write updated baseline_commit_hash to handoff frontmatter"]
    G --> H
    H --> I["Persist start artifacts"]
```

## Omissions

- None.

## Local View Hints

- specs\011-specrew-start-conditional-pause\iterations\001\review-diagrams.md
