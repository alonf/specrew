# Review Diagrams: Product & Problem Domain Lens

**Feature**: 176-product-domain-lens
**Phase**: pre-implementation (planning artifact for the reviewer)

## Component diagram

```mermaid
flowchart TD
  subgraph Catalog[Catalog knowledge]
    LensMd[product-domain.md<br/>decision areas + depth model + evidence vocab + conduct]
    Index[index.yml<br/>first-stage registration]
    Vocab[diagram-vocabulary.json<br/>context diagram]
  end
  subgraph Conduct[Workshop conduct - 4 host surfaces]
    Skill[specrew-design-workshop skill<br/>runs product-domain FIRST]
  end
  subgraph Artifacts[Per-feature artifacts]
    Writer[product-domain-lens.ps1<br/>scaffold / format / validate]
    Yml[workshop/product-domain.yml<br/>structured record]
    MdRec[workshop/product-domain.md<br/>human-readable]
  end
  subgraph Enforce[Enforcement]
    Gate[specify-gate floor<br/>record + SC-026 provenance, rejects batch]
  end
  subgraph Tests[Tests]
    Pester[Pester unit + integration<br/>depth / dual-artifact / evidence / FR-009 / gate / host-parity / schema]
  end

  LensMd --> Skill
  Index --> Skill
  Skill --> Writer
  Writer --> Yml
  Writer --> MdRec
  Yml --> Gate
  MdRec --> Gate
  Gate --> Pester
  Yml -. forward-compatible .-> P156[Proposal 156 workshop-decisions.yml - deferred]
  Yml -. product_id / context_scope hooks .-> P162[Proposal 162 product baseline - deferred]
```

## Sequence: product-domain phase at feature intake

```mermaid
sequenceDiagram
  participant Human
  participant Crew as Crew (workshop)
  participant Lens as product-domain.md
  participant Writer as product-domain-lens.ps1
  participant Gate as specify-gate floor

  Crew->>Lens: load first-stage lens (before applicability questionnaire)
  Crew->>Crew: select depth by risk + novelty (FR-002)
  Crew->>Human: reframe solution-first request into the problem; ask product/problem questions
  Human-->>Crew: answers (or explicit delegate/skip)
  Crew->>Crew: tag each material statement (known/assumed/unknown/research-needed)
  Crew->>Writer: write product-domain.yml + .md (context_scope=feature_standalone)
  Crew->>Gate: sync specify boundary
  Gate->>Writer: validate record (schema + non-batch confirmation provenance)
  alt valid + genuine confirmation
    Gate-->>Crew: pass -> proceed to applicability questionnaire + technical lenses
  else missing / batch-approved / malformed
    Gate-->>Crew: fail-closed with reason (FR-009/FR-010)
  end
```

## Sequence: conditional research-needed plan-block (FR-011)

```mermaid
sequenceDiagram
  participant Crew
  participant Writer as product-domain-lens.ps1
  participant Plan as plan boundary

  Crew->>Plan: attempt plan boundary
  Plan->>Writer: Test-SpecrewProductDomainResearchBlock
  alt load-bearing research-needed present
    Writer-->>Plan: blocking statements
    Plan-->>Crew: block until researched or human accepts
  else only non-load-bearing research-needed
    Writer-->>Plan: none blocking
    Plan-->>Crew: advance, gaps recorded + carried
  end
```
