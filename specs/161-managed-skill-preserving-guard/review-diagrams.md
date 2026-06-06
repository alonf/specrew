# Review Diagrams: Managed-Skill "Stuck Preserving" Guard

**Feature**: 161-managed-skill-preserving-guard
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart LR
  Templates[Canonical skill templates\nsquad-templates/skills] --> Defs[SkillDefinitions\nGet-LegacySpecrewSkillDefinitions]
  Defs --> Classifier{Test-IsManagedLegacySkillDirectory}
  Legacy[Legacy root\n.copilot/skills/specrew-*] --> Classifier
  Classifier -- managed --> Remove[removed-legacy-managed-skill]
  Classifier -- user-edited --> Preserve[preserved-legacy-unmanaged-skill\n<== stuck-preserving risk lives here]
  Defs --> Active[Active roots deploy\nSet-ManagedFile: SKILL.md + .specrew-managed]
  Harness[NEW: deploy-level repro harness\nS1..S6 scratch project] -. executes real script .-> Classifier
  Harness -. asserts .-> Remove
  Harness -. asserts .-> Preserve
  Harness -. asserts .-> Active
```

## Sequence: stale-canonical probe (S4 — the residual hypothesis)

```mermaid
sequenceDiagram
  participant H as Repro Harness
  participant D as deploy-squad-runtime.ps1
  participant C as Classifier
  participant FS as Scratch .copilot/skills

  H->>FS: seed specrew-X dir: STALE older-canonical SKILL.md, NO marker
  H->>D: run real deploy against scratch project
  D->>C: classify specrew-X (marker absent)
  C->>C: exact-match vs CURRENT canonical -> no match (content is stale)
  C->>C: content starts with '---' -> classified user-edited
  C-->>D: not managed
  D->>FS: preserved-legacy-unmanaged-skill (dir kept, frozen)
  D-->>H: action record
  H->>H: capture S4 outcome -> verdict input (CONFIRMED if reachable / REFUTED otherwise)
```

## Sequence: verdict-gated fix flow

```mermaid
sequenceDiagram
  participant I as Implementer
  participant E as Evidence
  participant Hu as Human

  I->>E: run S1-S6 + reachability analysis
  E-->>I: S4 outcome + upgrade-path evidence
  alt CONFIRMED (misclassified AND reachable)
    I->>Hu: verdict visible at boundary stop
    Hu-->>I: approve fix scope
    I->>I: narrow classification fix + mirror parity
    I->>E: S4 flips managed; S2 still preserved; F-160 fixture green
  else REFUTED
    I->>E: record refutation + code-path citation
    I->>I: no behavior change; fix budget unspent
  end
```
