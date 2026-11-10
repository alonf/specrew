# Review Diagrams: Workshop Lens Order

**Feature**: 205-workshop-lens-order
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart LR
  IDX[index.yml<br/>order + space] -->|read at runtime| AW[confirm-workshop-agenda.ps1]
  IDX --> PT[lens-order-parity.tests.ps1]
  PT -->|exact| FULL[skill list, methodology catalog tables,<br/>catalog README, before-specify]
  PT -->|relative| PART[partial lists]
  PT -->|sweep| SHIP[other shipped text]
  PT -->|FR-005 a/b/c + extractor| LENS[11 lens files]
  PT -->|full content| COPY[deployed copies]
  SRC[extension sources] -->|deploy-speckit-extension<br/>deploy-squad-runtime| COPY
```

## Sequence: confirming a new agenda

```mermaid
sequenceDiagram
  participant Crew
  participant Writer as confirm-workshop-agenda.ps1
  participant Catalog as index.yml
  Crew->>Writer: agenda JSON (selected + skipped)
  Writer->>Catalog: read ids in list order
  alt selected keeps relative order
    Writer-->>Crew: canonical agenda (render) or persisted agenda (confirm)
  else out of order
    Writer-->>Crew: refusal naming the out-of-order lenses and the index.yml order (nothing written)
  end
```

## Sequence: a maintainer changes the order

```mermaid
sequenceDiagram
  participant Maint as Maintainer
  participant Test as lens-order-parity.tests.ps1
  Maint->>Test: edit index.yml, run the test
  Test-->>Maint: every stale surface, lens file and copy in one run, each with its fix
  Maint->>Maint: fix the surfaces, run the two deploy scripts for the copies
  Maint->>Test: rerun
  Test-->>Maint: exit 0
```
