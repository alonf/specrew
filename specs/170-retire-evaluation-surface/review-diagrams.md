# Review Diagrams: Retire Top-Level Evaluation Surface

**Feature**: 170-retire-evaluation-surface
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart LR
  subgraph deleted [Deleted public surface]
    Readme[evaluation/README.md]
    Report[evaluation/report.md]
    OldScorer[evaluation/scorers/process-scorer.ps1]
  end
  subgraph tests [Test infrastructure]
    Scorer[tests/support/process-quality-scorer.ps1]
    ScorerTest[tests/integration/process-quality-scorer.ps1]
    ReportTest[tests/integration/process-quality-report.ps1]
    Smoke[multi-host-lifecycle-smoke.tests.ps1]
    PathReg[project-path-resolution-regression.ps1]
  end
  OldScorer -. moved 99% rename .-> Scorer
  ScorerTest --> Scorer
  ReportTest --> Scorer
  Smoke -- parses + path assertion --> Scorer
  PathReg --> Scorer
  ReportTest --> Scratch[(untracked test-results/)]
```

## Sequence: CI process-quality regression run

```mermaid
sequenceDiagram
  participant CI
  participant Test as process-quality-report.ps1
  participant Scorer as tests/support scorer
  participant FS as untracked scratch space
  CI->>Test: invoke (pwsh -File)
  Test->>FS: build scratch project fixture
  Test->>Scorer: invoke -ProjectPath scratch -WriteReport
  Scorer->>FS: write test-results/process-quality-report.md
  Scorer-->>Test: JSON result (overall, criteria, iterations)
  Test-->>CI: PASS lines + exit 0
```
