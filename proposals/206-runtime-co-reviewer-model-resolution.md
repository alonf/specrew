---
proposal: 206
title: Runtime Co-Reviewer Model Resolution and Independence-Aware Selection
status: candidate
phase: phase-2
estimated-sp: 18-27
priority-tier: 1
discussion: tbd
---

# Runtime Co-Reviewer Model Resolution and Independence-Aware Selection

## Why

Feature 197 made reviewer **host** selection catalog-driven, but the catalog's
`model` value is descriptive metadata rather than an execution contract. A row
can claim `chatgpt`, `configured-by-user`, or a once-current model while the CLI
silently runs something else. The selected model is not consistently passed to
the host, the resolved model is not consistently captured, and availability is
not checked against the authenticated account before a quota-bearing review.

This is now a correctness problem, not merely stale documentation. Model
catalogs change independently of Specrew releases, access varies by plan,
region, account, and CLI version, and several harnesses expose multiple model
providers. On 2026-07-11 the installed CLIs demonstrated six different shapes:

| Harness | Installed discovery/selection surface |
| --- | --- |
| Claude Code 2.1.207 | `--model` accepts stable aliases (`fable`, `opus`, `sonnet`) or full IDs; no non-consuming list command was exposed. |
| Codex CLI 0.144.1 | `--model` is supported; account availability is surfaced by the product picker rather than a stable scriptable list command. |
| GitHub Copilot CLI 1.0.70 | `--model auto` and explicit `--model`; interactive `/models`; availability varies by plan and client. |
| Devin CLI 3000.1.27 | `--model` accepts aliases/IDs, but no non-consuming list command was exposed. |
| Antigravity CLI 1.1.1 | `agy models` returns the account-visible model set. |
| Cursor Agent 2026.06.15 | `cursor-agent --list-models` returns account-visible IDs and `--model` selects one. |

The same model can also appear through several harnesses. Cursor can expose
Claude Fable and GPT-5.6; Antigravity can expose Gemini, Claude, and GPT-family
models; Devin can select different backends. Therefore "different executable"
does not necessarily mean an independent reviewer. Host-only independence can
mislabel two sessions backed by the same model family as independent while a
different model family inside one multi-provider harness may provide more
model diversity than the label admits.

Proposal 102 Pillar 5 already identifies ranked models within a harness, but
its 2026-07-08 addendum chose release-curated static model data and explicitly
rejected runtime web discovery. That choice cannot represent account-specific
availability and still permits metadata to diverge from execution. This
proposal replaces that **model-resolution portion only** with a CLI-first,
evidence-backed contract. Official web sources enrich update recommendations;
they never override what the authenticated local CLI can actually run.

## What

### 1. Keep the reviewer-host catalog stable

The canonical host catalog continues to own durable adapter behavior:

- executable and headless invocation shape;
- prompt-delivery mode and output parser;
- read-only/sandbox controls;
- model and effort flags;
- non-consuming discovery command/parser when one exists;
- capability and failure-signature contracts;
- per-host timeout defaults.

The row MUST NOT claim a concrete model as the executed model. Replace fields
such as `model = 'chatgpt'` with policy metadata such as
`model_policy = 'best-available'` and `model_source = 'runtime-resolved'`.
Concrete model IDs belong in discovered account state, an explicit user
override, or an updateable capability catalog - never in invocation-core
branches.

### 2. Resolve models through an ordered authority chain

Immediately before a live review, resolve the model in this order:

1. An explicit `--model` requested by the human.
2. A project policy selecting a capability tier or approved model family.
3. A fresh, non-consuming local CLI discovery result where supported.
4. A vendor-supported stable alias (`fable`, `auto`, or equivalent) where the
   CLI exposes selection but no list operation.
5. The authenticated CLI default only when policy explicitly permits
   `host-default` and the result can be labeled honestly.

An explicit model request is honored or surfaced. It MUST NOT silently fall
back. Automatic walk-down is allowed only under an explicitly authorized
`best-available`/fallback policy and every attempted and selected rung is
recorded.

### 3. Make CLI discovery authoritative and web research advisory

Discovery adapters classify their command as `non-consuming`, `probe-cost`, or
`unsupported`. Specrew may automatically run only non-consuming discovery
commands (`agy models`, `cursor-agent --list-models`, and future equivalents).
Interactive pickers are not scraped. A model invocation is never used merely
to discover availability without a bounded, human-approved quota budget.

Official vendor documentation may be queried by an update/research workflow to
learn new model IDs, aliases, retirement dates, pricing classes, or capability
claims. Web results:

- MUST come from an allowlisted official vendor domain;
- MUST carry source URL and observation time;
- MUST be treated as candidate catalog enrichment, not local availability;
- MUST NOT directly rewrite project authorization or execute a new model;
- MUST NOT outrank authenticated CLI discovery;
- MUST remain usable offline from the last accepted catalog plus live CLI
  discovery.

This keeps the web useful for volatility without turning search results into
an execution supply chain.

### 4. Select by capability, availability, cost, and independence

Policy refers to capability classes rather than model release names:

- `frontier-review`: strongest available judgment for signoff/security/design;
- `balanced-review`: strong default with lower quota/cost pressure;
- `fast-review`: bounded mechanical or low-risk review;
- `host-default`: explicit delegation to the harness provider.

Selection first filters to installed, authorized, headlessly invokable hosts
and account-visible/alias-resolvable models. It then ranks candidates by:

1. minimum required independence;
2. required review capability;
3. current availability and failure health;
4. human cost/quota policy;
5. deterministic preference order as the final tie-breaker.

"Best" therefore means the strongest candidate that satisfies the review's
independence and budget constraints, not the newest marketing name.

### 5. Replace host-only independence with evidenced identity

Every review records, when observable:

- `harness_id` and CLI version;
- `provider`;
- `requested_model`;
- `resolved_model_id` and model family;
- `selection_mode` (`explicit`, `policy`, `alias`, `auto`, `host-default`);
- discovery source and observation time;
- fallback attempts and bounded failure reasons.

Independence becomes graded:

| Classification | Meaning |
| --- | --- |
| `cross-provider-model` | Different harness and different provider/model family. Strongest ordinary evidence. |
| `cross-harness-same-provider` | Different harness, but shared provider or model family. Context/tooling diversity, not full model diversity. |
| `same-harness-cross-model` | Same harness with a demonstrably different model family. Model diversity without harness diversity. |
| `same-host` | Same harness and same/unknown model family; existing degraded-evidence acknowledgement applies. |
| `independence-unknown` | Backend identity cannot be established; never promoted to independent. |

For aggregator harnesses such as Devin, Cursor, Copilot, and Antigravity, a
different executable alone is insufficient to claim cross-provider
independence. Unknown or provider-managed `auto` selections remain honest:
they can produce a valid review, but cannot satisfy a gate requiring proven
cross-provider independence unless the resolved backend is reported.

### 6. Make every operational catalog row real

A reviewer shown as operational MUST have a tested headless invocation. Empty
invocation arguments are represented as `discoverable-only` or `unsupported`,
not as a usable reviewer. Initial implementation covers:

- Claude: `--model`, stable alias policy, optional explicit fallback list;
- Codex: `--model`, capability policy mapping, resolved-model evidence;
- Copilot: `--model auto` or explicit model, bounded credit controls;
- Devin: `--model` with backend identity captured when the CLI exposes it;
- Antigravity: `agy models` discovery plus `--model` selection;
- Cursor: `--list-models`, `--model`, and a read-only/plan-mode reviewer
  contract despite print mode's normal write capability.

Adding a host requires both the durable adapter row and reviewer parity:
discovery classification, selection mechanism, read-only proof, identity
evidence, and failure signatures.

### 7. Cache volatility without hiding it

Discovery results are cached by host, CLI version, authenticated account
fingerprint (non-secret), and relevant endpoint/provider. A short TTL avoids
repeated network calls. Cache invalidates on CLI version/account changes,
explicit refresh, model-not-found, or provider retirement signals.

The cache records `observed_at`, `source`, and `stale_after`. Stale cache may
support an offline recommendation but MUST NOT assert live availability.
Secrets, auth output, prompts, transcripts, and model responses never enter the
cache or committed evidence.

### Functional requirements

- **FR-001**: Split durable host-adapter data from volatile model discovery and
  selection state; remove concrete executed-model claims from static host rows.
- **FR-002**: Add a generic model-resolution contract supporting explicit,
  policy, discovery, alias, auto, and host-default selection modes.
- **FR-003**: Explicit model requests are honored-or-surfaced and never silently
  substituted.
- **FR-004**: Add non-consuming discovery adapters for CLIs that expose them;
  classify unsupported and quota-consuming probes honestly.
- **FR-005**: Thread the resolved model into the actual CLI invocation and prove
  by canary that evidence matches execution.
- **FR-006**: Add capability-tier routing independent of vendor/model names.
- **FR-007**: Replace binary host-only independence with harness/provider/model
  identity classifications; unknown identity cannot satisfy an independent
  reviewer gate.
- **FR-008**: Record requested/resolved identity, selection source, CLI version,
  and bounded fallback attempts in review evidence.
- **FR-009**: Add version/account-keyed discovery caching with explicit
  freshness and invalidation semantics.
- **FR-010**: Official-web enrichment is allowlisted, cited, advisory, and
  incapable of directly authorizing or invoking a model.
- **FR-011**: Operational reviewer rows require tested headless invocation and
  read-only proof; catalog-only rows are not advertised as usable.
- **FR-012**: Automatic model walk-down requires an explicit project policy,
  bounded attempts, quota-group awareness where observable, and no downgrade
  below the gate's minimum capability/independence requirement.
- **FR-013**: Deterministic fixtures cover parser drift; bounded live canaries
  cover account-specific discovery, invocation, failure, and evidence truth.
- **FR-014**: The supported authorization UX remains
  `specrew review --host <host> --authorization-ref <ref>`; users do not edit
  `reviewer-hosts.json` manually and authorization never implies a model is
  currently available.

### Out of scope

- Automatically purchasing credits, changing subscriptions, or accepting new
  provider terms.
- Scraping interactive model pickers or undocumented private endpoints.
- Treating vendor benchmark claims as Specrew capability evidence without
  local canaries and empirical review outcomes.
- Replacing Proposal 040's full cost-accounting system.
- Weakening the existing explicit reviewer-host authorization boundary.
- Automatically authorizing a model or host because web research says it is
  available.

## Effort

- **Iteration 1 (~7-10 SP)**: catalog/schema split, generic resolver, explicit
  model threading, identity evidence, and compatibility migration.
- **Iteration 2 (~6-9 SP)**: discovery adapters and canaries for Claude, Codex,
  Copilot, Devin, Antigravity, and Cursor; operational-row parity.
- **Iteration 3 (~5-8 SP)**: independence-aware ranking, cache/invalidation,
  official-source enrichment workflow, docs, and migration diagnostics.
- **Total**: ~18-27 SP.

## Phase placement

Phase 2, as a Feature 197/200 hardening follow-up. The current catalog already
makes model claims and selection decisions during live review, so identity
truth and volatility handling should land before broader Phase-3 dynamic
routing. It implements the focused runtime substrate that Proposals 040, 068,
and 102 can consume later.

## Open questions

1. Which gates require `cross-provider-model` rather than accepting
   `cross-harness-same-provider`?
2. When a provider's `auto` mode does not report the resolved backend, should
   it always be `independence-unknown`, or may signed provider metadata prove a
   narrower classification?
3. Should official-web enrichment run only through `specrew update`, or also as
   an explicit `specrew reviewer models refresh --research` operation?
4. What is the minimum non-secret account fingerprint needed to prevent model
   cache leakage across accounts?
5. Should capability mappings be release-curated initially, then adjusted by
   Specrew's own reviewer outcome history under Proposal 040/068?

## Risks

- **False independence**: aggregator harnesses can hide the backend model.
  Mitigation: unknown is never promoted to independent; record provider/model
  only when evidenced.
- **Discovery parser drift**: human-oriented CLI output changes. Mitigation:
  prefer structured output, version-key fixtures, fail closed to alias/default
  policy, and run bounded live canaries.
- **Supply-chain influence from web research**: a search result could recommend
  a malicious or nonexistent ID. Mitigation: official-domain allowlist,
  citation, advisory-only status, and local CLI validation before use.
- **Quota burn**: availability probes can consume paid turns. Mitigation:
  auto-run only non-consuming discovery; require an enumerated human-approved
  budget for live probes and fallback attempts.
- **Overfitting to "strongest"**: newest models may be costly, slow, or share
  the writer's blind spots. Mitigation: independence and minimum capability
  precede strength in ranking; project policy controls cost.
- **Silent fallback lies**: host `auto` or provider safeguards may route to a
  different backend. Mitigation: record selection mode and resolved identity
  where available; otherwise label independence unknown.

## Cross-references

- [102 Cross-Model Independent Reviewer](102-cross-model-independent-reviewer.md)
  - replaces the static-only model-resolution mechanism in Pillar 5's
  2026-07-08 addendum; retains its authorization and fallback-policy goals.
- [197 Continuous Co-Review](197-continuous-co-review.md) - owns the reviewer
  execution lifecycle and host-neutral catalog seam.
- [200 Add Devin CLI Host](200-devin-cli-host-clean-extensibility-proof.md) -
  supplies the Devin parity forcing function and aggregator-backend case.
- [068 Cost-Aware Model Routing](068-cost-aware-model-routing.md) and
  [040 Token Economy Governance](040-token-economy-governance.md) - consume
  capability/model discovery and provide broader cost policy.
- [187 Volatile Runtime Dependency Monitoring](187-volatile-runtime-dependency-monitoring.md)
  - supplies volatility evidence and monitoring doctrine.
- [203 Reviewer Containment + Identity Hardening](203-reviewer-containment-identity-hardening.md)
  - complementary execution containment and review identity integrity.

Official source snapshot (2026-07-11):

- [OpenAI GPT-5.6 announcement](https://openai.com/index/gpt-5-6/) and
  [OpenAI model catalog](https://developers.openai.com/api/docs/models)
- [Anthropic Claude Fable 5](https://www.anthropic.com/claude/fable)
- [GitHub Copilot supported models](https://docs.github.com/en/copilot/reference/ai-models)
- [Cursor CLI parameters and model discovery](https://docs.cursor.com/en/cli/reference/parameters)

## Status history

- 2026-07-11: status set to `candidate` after live catalog review found that
  static model labels do not control execution, account-visible models differ
  by CLI, and host-only independence cannot represent multi-provider harnesses.
