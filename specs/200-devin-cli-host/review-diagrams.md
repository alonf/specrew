# Review Diagrams: Devin CLI Host — Clean-Extensibility Proof

**Feature**: 200-devin-cli-host
**Phase**: pre-implementation planning artifact for reviewer

## Component Diagram

```mermaid
flowchart LR
  CLI[specrew start/init/update] --> Validation[Registry Validation]
  Validation --> Registry[Single Host Registry]
  Registry --> Existing[Existing Host Packages]
  Registry --> Devin[hosts/devin Package]

  Devin --> Launch[Five Existing Handlers]
  Devin --> Adapter[Devin Hook + ATIF Adapter]
  Adapter --> Dispatcher[Shared Hook Dispatcher]
  Dispatcher --> Handover[Unchanged Handover Provider + Parser]

  Registry --> Coordinator[Coordinator Descriptor Projection]
  Coordinator --> Managed[Managed iteration-config agents Block]

  Packages[hosts/* Packages] --> Generator[Host FileList Generator]
  Generator --> Manifest[Generated Specrew.psd1 Segment]

  Shared[Shared Production Source] --> Firewall[Host Purity Firewall]
  Firewall --> Proof[Five Exceptions Removed; No Devin Exception]
```

## Sequence: Interactive Devin Session and Handover

```mermaid
sequenceDiagram
  participant User
  participant Start as specrew start
  participant Registry
  participant Devin as Devin CLI
  participant Adapter as hosts/devin hook-adapter
  participant Dispatcher as Shared Dispatcher
  participant Handover as Unchanged Handover Pipeline

  User->>Start: specrew start --host devin
  Start->>Registry: validate and dispatch NewLaunchInvocation
  Registry-->>Start: devin argv + export path + notices
  Start->>Devin: interactive positional bootstrap prompt
  Devin->>Adapter: SessionStart / UserPromptSubmit JSON
  Adapter->>Dispatcher: unchanged event forwarding
  Dispatcher-->>Devin: governed context output
  Devin->>Devin: write ATIF export before Stop
  Devin->>Adapter: Stop payload
  Adapter->>Adapter: normalize ATIF to existing JSONL shape
  Adapter->>Dispatcher: Stop + transcript_path
  Dispatcher->>Handover: invoke existing provider
  Handover->>Handover: unchanged parser captures turns and packet
  Dispatcher-->>Adapter: decision response
  Adapter-->>Devin: preserve Stop decision response
```

## Sequence: One-Run Coordinator Migration

```mermaid
sequenceDiagram
  participant User
  participant Update as specrew update
  participant Registry
  participant Merge as Managed Agent Projection
  participant Config as iteration-config.yml

  User->>Update: run once in installed project
  Update->>Registry: get coordinator descriptors
  Registry-->>Update: eligible hosts + defaults
  Update->>Config: read content and managed markers
  Update->>Merge: existing managed rows + descriptors + detection
  Merge-->>Update: canonical preserved projection
  Update->>Config: replace managed block only
  User->>Update: run again
  Update->>Merge: same inputs
  Merge-->>Update: byte-identical projection
  Update-->>User: no managed configuration diff
```

## Proof Boundary

```mermaid
flowchart TD
  Add[Add or change a host package] --> Scan[Discover manifests and package files]
  Scan --> Validate[Validate contract and generated projections]
  Validate --> Purity{Shared production contains host-specific routing?}
  Purity -- Yes --> Fail[Firewall fails; no exception growth]
  Purity -- No --> Tests[Registry / launch / hooks / migration / package tests]
  Tests --> Real{Volatile real-host surface changed?}
  Real -- Yes --> Canary[Pinned-build prerelease canary]
  Real -- No --> Ready[Review-ready]
  Canary --> Ready
```
