# Review Diagrams: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-03

## FR-012 — multi-developer signal: write-signals corroborate, never trigger alone

```mermaid
flowchart TD
    A[Get-SpecrewMultiDeveloperSignals] --> B{distinct-actor signal?<br/>authors>=2 OR machines>=2 OR numbered-branch-fanout>=3}
    B -- no --> C[has_multi_developer_signal = false<br/>NO recommendation<br/>fresh single-dev bootstrap = quiet]
    B -- yes --> D[has_multi_developer_signal = true<br/>recommendation fires]
    D --> E{writeSignals >= 1?}
    E -- yes --> F[append 'N close-together shared-state writes'<br/>as CORROBORATING detail]
    E -- no --> G[recommendation without write detail]
```

## FR-013 — fresh-greenfield baseline (C+nudge, no auto-commit)

```mermaid
flowchart TD
    S[specrew start] --> H{git HEAD resolves?}
    H -- no commit yet --> N[guidance nudge:<br/>'make an initial commit'<br/>NO baseline stamped<br/>NO commit created]
    H -- commit exists --> R[boundary refresh:<br/>Get-SpecrewCurrentHeadCommitHash + Update-BaselineCommitHashInFrontmatter]
    R --> K[baseline_commit_hash == HEAD<br/>consistent across start packet + boundary state]
    N -.-> |user commits, next boundary| R
```

## Notes

- Both diagrams reflect the as-built behavior verified by SC-008 (`feature-051-iteration2b`) and
  SC-009 (`design-gate-runtime-hardening-greenfield-baseline`). The dashed edge in the FR-013 diagram
  is the Feature-029 fail-safe path: the baseline self-heals at the next boundary once the user makes
  a commit — Specrew never creates one on their behalf.
