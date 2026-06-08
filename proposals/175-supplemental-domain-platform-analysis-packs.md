---
proposal: 175
title: Supplemental Domain/Platform Analysis Packs (routing lens plus source packs)
status: candidate
phase: phase-2
estimated-sp: 10-16
priority-tier: 2
discussion: surfaced 2026-06-08 during Proposal 163 code-implementation lens research. The maintainer identified that cloud-provider, CNCF, workload, and other domain-specific guidance should be brought into the workshop when relevant, but a fixed "cloud lens" would duplicate existing lenses and still miss unpredictable domains. This proposal creates an 11th routing lens that activates source-backed supplemental analysis packs across the existing lens set.
---

# Supplemental Domain/Platform Analysis Packs

## Why

The design lens catalog intentionally covers broad design dimensions:
architecture, data, UI, security, integration, devops, observability, NFR, and
component design. Proposal 163 adds implementation craft.

Those lenses are necessary but not sufficient for domain/platform-specific
design work. A cloud workload on Azure, AWS, Google Cloud, Alibaba Cloud, or a
CNCF/Kubernetes stack has provider and ecosystem guidance that changes the
questions Specrew should ask. The same is true for AI workloads, IoT/edge,
mobile, regulated finance, healthcare, data analytics, realtime streaming, and
other domains we cannot enumerate in a fixed lens list.

Adding a normal "cloud lens" as lens 11 would be too narrow and too broad at the
same time:

- too narrow, because the same mechanism is needed for non-cloud domains;
- too broad, because cloud guidance affects architecture, data, integration,
  security, devops, observability, NFR, and code implementation;
- duplicative, because provider well-architected frameworks overlap the current
  lenses rather than replacing them;
- stale-prone, because provider services, CNCF maturity, support status, and
  workload guidance change over time.

The needed capability is an **extra analysis router**: when the problem domain,
platform, provider, or workload class matters, Specrew should load a focused,
source-backed analysis pack and merge its questions into the relevant existing
lenses.

## What

Add an 11th lens with working id `domain-platform-analysis`.

This lens is not a cloud checklist. It is a routing lens that answers:

1. Does this feature require supplemental domain/platform analysis?
2. Which source-backed analysis packs apply?
3. Which existing lenses receive additional questions?
4. Which provider/domain recommendations are relevant, current, and mature
   enough to show the human?
5. Which assumptions or recommendations are non-exclusive, meaning the Crew
   must still consider better protocols, services, products, or designs for the
   actual solution?

The output is a set of selected **analysis packs**, each one source-backed and
mapped into the normal workshop flow.

## Core decision

Use **routing lens plus supplemental packs**, not a standalone cloud lens.

The routing lens appears in the workshop agenda only when applicability signals
exist. It then selects one or more packs, such as:

- `cloud-azure`
- `cloud-aws`
- `cloud-gcp`
- `cloud-alibaba`
- `cncf-cloud-native`
- `ai-workload`
- `iot-edge`
- `mobile`
- `regulated-finance`
- `healthcare`
- `data-analytics`
- `realtime-streaming`
- `multi-cloud-hybrid`

Each pack contributes targeted questions into the existing lenses. For example,
`cloud-azure` may add:

- architecture-core: workload class, region/zone topology, reference
  architecture fit, landing-zone assumptions;
- requirements-nfr: reliability, security, cost, operations, performance, and
  sustainability tradeoffs;
- data-storage: replication, backup, retention, residency, consistency, and
  service selection;
- integration-api: API gateway, messaging, eventing, streaming, managed service
  vs open-source choices;
- security-compliance: identity, network isolation, secrets, policy, regulatory
  scope, shared responsibility;
- devops-operations: IaC, environment topology, deployment, rollback, runbooks,
  quotas, support model;
- observability-resilience: telemetry, alerting, SLOs, DR, chaos/failure tests;
- code-implementation: provider SDK/version posture, platform abstractions,
  managed identity, retries, idempotency, cache, queue, and protocol choices.

The pack never replaces the base lens. It adds source-backed questions and
recommendations where the base lens would otherwise be too generic.

## Source-pack shape

Each supplemental pack should be data, not prompt prose. Proposed schema:

```yaml
id: cloud-azure
title: Azure Cloud Workload Analysis
applicability_signals:
  - target platform includes Azure
  - deployment uses Azure services
  - architecture mentions Azure, Entra, AKS, Functions, App Service, Storage, SQL,
    Cosmos DB, Service Bus, Event Hubs, Event Grid, APIM, Front Door, or Key Vault
source_anchors:
  - title: Azure Architecture Center
    url: https://learn.microsoft.com/en-us/azure/architecture/
  - title: Azure Well-Architected Framework workloads
    url: https://learn.microsoft.com/en-us/azure/well-architected/workloads
affected_lenses:
  architecture-core:
    questions:
      - Which Azure workload class or reference architecture best matches this
        solution, and what is explicitly different?
    plan_obligations:
      - Record region/zone, landing-zone, identity, network, and service-choice
        assumptions.
    validation_signals:
      - Plan references the checked Azure source anchors and records deviations.
  requirements-nfr:
    questions:
      - Which Well-Architected tradeoffs dominate: reliability, security, cost,
        operational excellence, or performance efficiency?
currentness:
  requires_web_check: true
  record_checked_date: true
recommendation_policy:
  non_exhaustive: true
  must_explain_alternatives: true
```

## Initial source packs

### `cloud-azure`

Use when the target or likely deployment platform is Azure.

Seed sources:

- <https://learn.microsoft.com/en-us/azure/architecture/>
- <https://learn.microsoft.com/en-us/azure/architecture/guide/>
- <https://learn.microsoft.com/en-us/azure/architecture/patterns/>
- <https://learn.microsoft.com/en-us/azure/well-architected/>
- <https://learn.microsoft.com/en-us/azure/well-architected/workloads>

Prompt themes:

- workload class and reference architecture fit;
- architecture style and design patterns;
- Azure Well-Architected pillars and workload-specific guidance;
- landing zone, identity, network, region, availability zone, and data residency;
- Azure service choice vs open-source/CNCF vs custom implementation;
- managed identity, Key Vault/secrets, policy, monitoring, backup, DR, and cost.

### `cloud-aws`

Use when the target or likely deployment platform is AWS.

Seed sources:

- <https://aws.amazon.com/architecture/>
- <https://aws.amazon.com/architecture/well-architected/>
- <https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html>
- <https://docs.aws.amazon.com/whitepapers/latest/aws-overview/architecting-on-aws.html>

Prompt themes:

- AWS Well-Architected pillar fit and review risks;
- account, organization, network, identity, region, and availability-zone
  posture;
- managed service vs Kubernetes/CNCF/open-source choices;
- service integration, eventing, queues, serverless, data stores, edge/CDN;
- operational runbooks, quotas, resilience, cost controls, and support model.

### `cloud-gcp`

Use when the target or likely deployment platform is Google Cloud.

Seed sources:

- <https://cloud.google.com/architecture>
- <https://cloud.google.com/architecture/framework>
- <https://cloud.google.com/architecture/framework/perspectives>

Prompt themes:

- Google Cloud Well-Architected pillars and perspectives;
- project/folder/org, IAM, VPC, region/zone, and data locality posture;
- GKE/serverless/managed service choices;
- SRE/operations, observability, reliability, cost, sustainability, and
  performance guidance;
- workload/domain perspectives such as financial services when applicable.

### `cloud-alibaba`

Use when the target or likely deployment platform is Alibaba Cloud.

Seed sources:

- <https://www.alibabacloud.com/en/architecture/index>
- <https://www.alibabacloud.com/help/en/well-architected/latest/foreword>
- <https://www.alibabacloud.com/help/en/well-architected/latest/overview-1>
- <https://www.alibabacloud.com/help/en/cloud-network-well-architected-design/>
- <https://www.alibabacloud.com/en/architecture/ref-architecture/index>

Prompt themes:

- Alibaba Cloud Well-Architected pillars and reference architectures;
- region, account, network, ACK/container, ECS, database, eventing, and edge
  choices;
- "Go China" or regional compliance/data-residency implications when relevant;
- reliability, security, performance, cost, and operations tradeoffs.

### `cncf-cloud-native`

Use when the target solution is Kubernetes/cloud-native, or when a cloud-native
open-source project may be a better fit than a managed provider service.

Seed sources:

- <https://www.cncf.io/projects/>
- <https://landscape.cncf.io/>
- <https://www.cncf.io/project-metrics/>
- <https://contribute.cncf.io/projects/lifecycle/>

Prompt themes:

- matching CNCF projects to requirement category: orchestration, ingress,
  service mesh, observability, policy/security, runtime, secrets, storage,
  messaging/streaming, workflow, GitOps, delivery, autoscaling;
- explaining project maturity: Sandbox, Incubating, Graduated;
- comparing CNCF/open-source vs managed provider service vs framework-native
  option;
- operator skill, support model, release cadence, security posture, and
  lifecycle risk.

## Workshop behavior

When this lens activates, the Crew must render the selected packs to the human
before using them:

```text
Supplemental analysis needed

Why: <signals found in the feature>
Selected packs:
  <pack-id> - <why it applies>
  <pack-id> - <why it applies>

Sources checked:
  <source title> - <URL> - checked <date>
  <source title> - <URL> - checked <date>

How it affects the workshop:
  architecture-core - <additional question>
  security-compliance - <additional question>
  devops-operations - <additional question>
  ...
```

Then the Crew asks an open question:

```text
These packs add provider/domain-specific analysis to the normal lenses. What
constraints or preferences should I know before I weave them into the workshop?
```

The Crew must not treat pack activation as human approval of all pack questions.
Each selected pack must still be discussed at the relevant lens depth, or be
marked `human-delegated` / `human-skipped` honestly.

## Non-exhaustive recommendation rule

Every pack must carry this rule:

```text
The listed technologies, provider services, protocols, patterns, and source
anchors are prompts and starting points, not the only valid solution. The Crew
must consider whether another provider service, open-source project, protocol,
managed platform, custom implementation, or simpler design is a better fit for
the actual problem.
```

This prevents the workshop from collapsing into "Azure says X, therefore X" or
"CNCF has a project, therefore use it." The output should be a decision with
tradeoffs, not a vendor checklist.

## Currentness rule

Supplemental packs are source-sensitive. For any selected pack, the Crew must:

- check official/current source anchors during the workshop or design-analysis;
- record the checked date;
- avoid claiming "latest", support status, service maturity, CNCF maturity,
  preview/GA status, or provider recommendation from model memory alone;
- ask the human before selecting a preview, non-LTS, region-limited, deprecated,
  niche, or short-lived technology;
- record when the recommendation is based on an assumption rather than verified
  source text.

## Artifact contract

Extend `lens-applicability.json` with a supplemental analysis section:

```json
{
  "selected": ["architecture-core", "domain-platform-analysis"],
  "supplemental_analysis": {
    "selected_packs": ["cloud-azure", "cncf-cloud-native"],
    "sources_checked": [
      {
        "pack": "cloud-azure",
        "title": "Azure Architecture Center",
        "url": "https://learn.microsoft.com/en-us/azure/architecture/",
        "checked_date": "2026-06-08"
      }
    ],
    "non_exhaustive_acknowledged": true
  }
}
```

For each affected lens, the existing workshop record should include the pack
questions that were raised and the human's decision/confirmation. Selected pack
decisions also feed Proposal 156's canonical `workshop-decisions.yml` manifest
with source provenance (`pack`, source URL/title, checked date), applicability
state, non-exhaustive acknowledgement, and expected evidence. Pack activation
is therefore visible to later agents, but it is not approval of all pack
questions.

## Functional requirements

- **FR-001**: Specrew SHALL include a `domain-platform-analysis` routing lens.
- **FR-002**: The routing lens SHALL activate only when feature signals indicate
  a relevant platform, provider, workload class, domain, or ecosystem.
- **FR-003**: The routing lens SHALL select source-backed supplemental packs,
  not hard-code all extra questions in the prompt.
- **FR-004**: Each pack SHALL define applicability signals, source anchors,
  affected lenses, questions, plan obligations, validation signals, and a
  non-exhaustive recommendation rule.
- **FR-005**: For cloud-provider packs, Specrew SHALL use official provider
  architecture and well-architected sources where available.
- **FR-006**: For cloud-native packs, Specrew SHALL surface CNCF project
  maturity where CNCF projects are considered.
- **FR-007**: Specrew SHALL record source checked dates for selected packs.
- **FR-008**: Specrew SHALL not treat pack activation as approval of all pack
  questions; each affected lens still needs human-confirmed, human-delegated, or
  human-skipped provenance.
- **FR-009**: Specrew SHALL allow project-local supplemental packs so teams can
  add industry, vendor, framework, or domain guidance without changing Specrew
  runtime code.
- **FR-010**: Specrew SHALL preserve the base lens boundaries: packs add
  questions to existing lenses, they do not replace architecture/security/data
  or other base lenses.
- **FR-011**: Selected pack decisions SHALL be emitted into the Proposal 156
  `workshop-decisions.yml` manifest with pack ID, affected lens, source
  provenance, checked date, applicability/human-confirmation state, and expected
  evidence.
- **FR-012**: Proposal 145 SHALL be able to verify selected pack decisions
  through `workshop-decision-conformance.yml`, including source-currentness
  evidence when a decision depends on current provider, CNCF, support, maturity,
  GA/preview, or regional availability claims.

## Out of scope

- Building a full cloud-advisor or recommendation engine.
- Exhaustively cataloging all Azure/AWS/GCP/Alibaba services.
- Treating provider guidance as mandatory policy.
- Replacing the code-implementation lens from Proposal 163.
- Replacing the two-tier product/workshop memory from Proposal 162.
- Replacing review-time evidence checks from Proposal 145.

## Composition map

- [[156-design-analysis-lens-knowledge-catalog]] - provides the catalog/schema
  foundation and canonical `workshop-decisions.yml` producer manifest; 175
  extends it with pack routing and source packs.
- [[162-two-tier-product-then-feature-workshop]] - product-level platform
  decisions can preselect or default packs for future features.
- [[163-code-implementation-lens]] - code implementation consumes pack-specific
  SDK, protocol, cloud-native, and provider-service constraints.
- [[164-risk-assessment-mitigation-workshop]] - packs seed domain/provider risks
  into the risk register.
- [[174-boundary-variance-disclosure]] - if later evidence contradicts pack
  assumptions, the gate must disclose variance and reconcile artifacts.
- [[145-structured-multi-phase-reviewer]] - verifies selected pack decisions,
  source-currentness evidence, and accepted exceptions through
  `workshop-decision-conformance.yml`.
- Provider well-architected frameworks - source packs feed their guidance into
  existing lenses instead of creating parallel provider checklists.

## Sizing

- **MVP (~10-16 SP)**:
  - routing lens file + registration + applicability map updates (~3-4 SP);
  - source-pack schema and loader/validation (~3-5 SP);
  - initial packs for Azure, AWS, GCP, Alibaba, and CNCF (~3-5 SP);
  - workshop rendering, artifact persistence, and tests (~1-2 SP).
- **Expanded pack library**: separate follow-up work per domain/provider.

## Open questions

- Should packs live under `design-lenses/packs/` or a sibling
  `supplemental-analysis-packs/` directory?
- Should the routing lens be a normal selected lens in `selected[]`, or should
  it be a separate `supplemental_analysis` activation outside the base lens list?
- Should pack currentness checks happen at specify/intake only, or again at
  design-analysis when service choices become concrete?
- How much of pack selection should be deterministic vs Crew judgment with human
  confirmation?
- Which initial non-cloud packs should ship after the cloud/CNCF seed set?

## Risks

- **Question explosion**: packs can make the workshop too long. Mitigation:
  applicability signals and depth control; only affected lenses receive pack
  questions.
- **Vendor checklist theater**: provider docs can become unexamined mandates.
  Mitigation: mandatory non-exhaustive rule and tradeoff recording.
- **Stale recommendations**: cloud/provider guidance changes. Mitigation:
  checked-date recording and web verification for selected packs.
- **Duplicate lens responsibilities**: cloud concerns overlap base lenses.
  Mitigation: packs inject questions into existing lenses; they do not replace
  them.
- **Source quality drift**: community articles can be useful but less
  authoritative. Mitigation: official provider/CNCF sources first; clearly mark
  non-official sources when used.

## Status history

- 2026-06-08: Candidate created after maintainer asked whether cloud/provider
  and unpredictable domain-specific analysis needs an 11th lens. Decision:
  routing lens plus supplemental source packs, not a standalone cloud lens.
- 2026-06-08: clarified that selected pack decisions feed Proposal 156's
  `workshop-decisions.yml` manifest and are verified by Proposal 145's
  `workshop-decision-conformance.yml`, with checked-date/source provenance
  preserved for current provider/CNCF claims.
