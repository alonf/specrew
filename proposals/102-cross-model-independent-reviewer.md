---
proposal: 099
title: Cross-Model Independent Reviewer (Structural Author-Reviewer Independence)
status: candidate
discussion-status: ad-hoc
spec-status: none
relationship-status: clean
phase: phase-3
estimated-sp: 15-25
discussion: ad-hoc 2026-05-22 session
---

# Cross-Model Independent Reviewer (Structural Author-Reviewer Independence)

## Why

Specrew's lifecycle includes review boundaries (`/speckit.review`, PR-review-integration via Proposal 089) that gate features before they ship. Today the review is typically performed by:

- The same LLM that authored the code (when the implementer agent also drafts the review)
- The same vendor's automated reviewer (e.g., GitHub Copilot reviewing PRs authored by Copilot)
- A human reviewer with limited time to deeply inspect every change

All three share a problem: **the reviewer and author have overlapping blind spots**.

Three distinct failure modes the current review system does not structurally prevent:

1. **Author-bias** — implementer rationalizes its own choices when asked to review them. Well-documented in human cognition; equally present in LLMs that "self-review."
2. **Model-specific blind spots** — every LLM has classes of bugs it consistently misses. Claude-style models miss things that Codex-style models catch (and vice versa). When implementer and reviewer are the same model family, those blind spots compound rather than cancel.
3. **Training-data overlap** — the subtlest mode. Even when implementer and reviewer are *different* vendors, they may have trained on overlapping data. If both saw the same bug-pattern get marked "fine" in training, both will rationalize it in production. **Cross-vendor is necessary but not sufficient — cross-training-lineage is the deeper protection.**

Empirical signal: F-035 / F-036 / F-037 / F-038 each had Copilot PR review findings that landed in their respective PRs — useful catches. But the catches were of a specific class (style, cross-platform shell compatibility, ValidateSet enums). Each finding was Copilot pointing out something Copilot-authored. The pattern is reactive — Copilot finds things in Copilot's own output that Copilot's review pass catches. It would be much stronger to also see what a *different* model catches.

User-stated motivation (2026-05-22, from external research document review):

> "Specrew standardizes the validation phase ... utilizing a dedicated, independent validation LLM to cross-reference the generated code against the Spec-Kit requirements. This ensures objective verification regardless of whether Copilot, Claude, or Gemini wrote the code."

The research document's framing was correct in shape; this proposal sharpens it with concrete failure-mode analysis and the cross-training-lineage requirement.

## What (6 Pillars)

### Pillar 1 — Reviewer-author independence: three levels

The proposal commits to **structural** independence, not just nominal independence. Three escalating levels, profile-configurable:

| Level | Implementer | Reviewer | Protects against |
|---|---|---|---|
| L0 (current state) | Any model | Same model | Nothing structurally — relies on prompt discipline |
| L1 (cross-instance) | Claude session A | Claude session B | Author-bias only — same model, different conversation context |
| L2 (cross-vendor) | Copilot | Claude | Author-bias + most model-specific blind spots |
| L3 (cross-training-lineage) | Anthropic-family | Non-Anthropic-family (Gemini / OpenAI / DeepSeek / open-weights) | All three failure modes — including training-data overlap |

L0 is today. L1 is cheap and gets some lift. L2 is the natural target. L3 is the most rigorous but constrains model selection. Profile chooses the target level; sensible defaults per slice type.

### Pillar 2 — Cost arithmetic + profile/slice-type gating

Cross-model review **roughly doubles inference cost per reviewed iteration**. For a $5 Copilot iteration, adding a Claude reviewer adds $2-4. That's 40-80% overhead.

**Not every iteration warrants this.** The proposal commits to slice-type-aware activation:

| Slice type | Default L | Rationale |
|---|---|---|
| Feature (full lifecycle) | L2 | High-stakes; doubling cost is worth catching architecture/security issues early |
| Hot-fix / security-fix | L3 | Highest stakes; insist on maximum independence |
| Small-fix slice (Proposal 067) | L1 | Cost-sensitive; minor gains from cross-vendor |
| Debt-fix slice (Proposal 091) | L1 | Same as small-fix |
| Chore (typo, version bump) | L0 | No review escalation needed |

Profile (Proposal 047) can override per-project. The defaults are sensible, not mandatory.

### Pillar 3 — Routing design (static MVP → dynamic later)

MVP ships with **static config**: project declares "implementer = X; reviewer = Y" in `.specrew/agent-routing.yml`. No dynamic per-task routing. Predictable, debuggable, cheap to ship.

Iteration 2 adds **dynamic routing** based on:

- File-type affinity (some models better at PowerShell; others at TypeScript)
- Change-size class (small changes: cheap L1 reviewer; large: L3)
- Risk class detected by file paths (auth/security/CI-config → L3 reviewer mandatory)
- Per-feature override declared in plan.md

Static config is enough for the MVP value proposition. Dynamic routing is a follow-up optimization.

### Pillar 4 — Form-vs-meaning safeguards (composes with Proposal 073)

A lazy reviewer says "looks good" indiscriminately. The proposal must defend against this.

Three concrete safeguards (each composing with Proposal 073 Review Evidence Integrity's pattern):

**4a. Required evidence in reviewer output.** Reviewer must cite specific files+lines for each finding (positive or negative). "Looks good" without file-citation is rejected as form-not-meaning by the validator.

**4b. Synthetic-bug injection (periodic).** Specrew internally maintains a small bug-catalog (deliberately-broken code patterns). Periodically, the reviewer pipeline runs against an injected bug; if the reviewer misses it, alarm + retro discussion of why. Frequency: once per N iterations (N ≈ 10-20). Burden is small; signal is high.

**4c. Cross-reference against spec.** Reviewer must explicitly map findings back to specific FRs in spec.md or acceptance criteria in tasks.md. Findings that don't trace to spec/tasks are flagged as out-of-scope.

### Pillar 5 — Availability fallback policy

Cross-model reviewer is sometimes unavailable: rate-limited, network down, quota exhausted, model deprecated. The proposal must define behavior explicitly. Four options:

| Policy | Behavior on reviewer unavailable | When right |
|---|---|---|
| Hard-block | Boundary refuses to advance | Highest-stakes (security-fix slice; L3 mandated) |
| Soft-warn + proceed | Lifecycle continues; audit log records bypass | Default; most common |
| Mandatory human review | Falls through to human-only review | Medium-stakes; reviewer-required-not-specific |
| Retry-with-backoff | Block briefly; retry; then soft-warn | Default for transient outage |

Profile chooses the policy. Audit log captures every bypass so retros can detect "we relied on the reviewer but it was bypassed 40% of the time" pattern.

### Pillar 6 — Composition with Proposal 089 (PR Review Integration)

089 shipped F-038 as a minimal slice. It **surfaces external reviewer findings** (currently Copilot's automated PR review) into Specrew's lifecycle — pull-style.

099 **commissions a reviewer** — push-style.

These are duals. The same adapter machinery can underlie both: 089's "reviewer-finding ingestion" generalizes to "commission a review and ingest its findings." Specifically:

- 089 owns the `pr-review-resolution.md` artifact format and the address-pr-review-gate boundary
- 099 owns the model-routing + cost-aware-activation + cross-model-independence policy
- They share the artifact-ingestion + finding-classification + form-vs-meaning machinery

The proposal should be drafted as an **extension** of 089, not a parallel system. Concretely: 099's iteration 1 reuses 089's `pr-review-resolution.md` format; reviewer commissioned by 099 produces output in the same shape that 089 already parses.

## Functional Requirements

- **FR-001**: `.specrew/agent-routing.yml` configuration file with `implementer:` and `reviewer:` entries per slice type
- **FR-002**: L0 / L1 / L2 / L3 independence levels defined and enforced; profile can set defaults per slice type
- **FR-003**: Reviewer commission via the same execution-host machinery used by 069 (Multi-Host Launch Path) — reuses the launch abstraction, doesn't fork it
- **FR-004**: Cross-model routing static-config MVP; per-slice-type defaults; profile overrides
- **FR-005**: Reviewer output format reuses Proposal 089's `pr-review-resolution.md` shape
- **FR-006**: Reviewer findings must cite file:line; findings without citation are flagged as form-not-meaning
- **FR-007**: Reviewer findings must trace to spec FR or task AC; orphan findings flagged as out-of-scope
- **FR-008**: Synthetic-bug-injection catalog under `.specrew/quality/reviewer-test-corpus/`; periodic injection at ~1-in-N iterations
- **FR-009**: Availability-fallback policy per slice type; audit log captures every reviewer bypass
- **FR-010**: Cost-tracking integration — reviewer costs feed Proposal 070's token-economy ledger
- **FR-011**: Dashboard (Proposal 092) shows reviewer-pair effectiveness: catches per iteration, false-positive rate, bypass rate
- **FR-012**: Composition with Proposal 047 — governance profile sets per-project independence-level defaults and acceptable model pairs
- **FR-013**: Composition with Proposal 069 — reviewer execution uses the same multi-host launch infrastructure
- **FR-014**: Dynamic routing (iteration 2): file-type / change-size / risk-class based selection
- **FR-015**: Self-applied: Specrew's own development adopts L2 for feature PRs (default after this proposal ships)

## Out of scope

- **Replacing human review** — 099 is *additive* to human review, never substitutive. Final boundary approval remains human-controlled.
- **Custom reviewer prompt engineering per project** — initial reviewer prompts are Specrew-curated; per-project customization is a future enhancement
- **Multi-reviewer aggregation** ("commission 3 reviewers, vote") — interesting but expensive; out of scope at MVP; possibly future
- **Reviewer training / fine-tuning on Specrew-specific patterns** — out of scope; we rely on base model capability
- **Inference-cost optimization within reviewer (caching, batching)** — composes with Proposal 086 perf bundle but is its own work
- **Reviewer for non-code artifacts** (spec.md review, plan.md review) — out of scope at MVP; possibly future

## Effort

- **Pillar 1 (independence levels + config)**: ~2 SP — small schema work; mostly policy
- **Pillar 2 (slice-type defaults + profile integration)**: ~2 SP
- **Pillar 3 (static routing MVP)**: ~3 SP
- **Pillar 4 (form-vs-meaning + synthetic injection)**: ~4-5 SP — synthetic catalog + injection mechanism + validator rules
- **Pillar 5 (availability fallback)**: ~2 SP
- **Pillar 6 (composition with 089's adapter)**: ~3-4 SP — extends 089's address-pr-review-gate
- **Dashboard integration**: ~2 SP
- **Self-applied dogfooding (Specrew adopts L2)**: ~1 SP
- **Total iteration 1**: ~17-21 SP
- **Iteration 2 (dynamic routing)**: ~5-8 SP
- **Realistic total**: ~22-29 SP across 2 iterations; **MVP target**: 15-18 SP if synthetic injection is deferred to iter 2.

## Phase placement

**Phase 3 — quality + independence tier**. Composes with shipped/late-phase-2 work:

- Requires Proposal 089 shipped (which F-038 covered minimally; richer PR-review-integration may need to ship first)
- Requires Proposal 069 (Multi-Host Launch Path) or its equivalent — without multi-host execution, cross-model reviewer can't actually launch a different model
- Composes with Proposal 047 (Governance Profile) for per-project defaults
- Composes with Proposal 086 (perf bundle) for caching reviewer outputs

Sequencing: ships after 069 enables practical multi-host execution. Plausible Q3 2026 with the right prerequisites.

## Open questions

1. **L1 (same-model, different-instance) — meaningful protection or theatrical?** Recommendation: include in the spec but flag as "limited value; consider L2 minimum for production." User picks at clarify.
2. **Cross-training-lineage detection** — how do we know that two models genuinely have different training lineages, vs. nominally different vendors? Models from the same lab (e.g., GPT-4 + GPT-5) are not training-lineage-independent. Recommendation: curated allowlist of known-independent pairings; user can override with explicit acceptance.
3. **Open-weights models as reviewers** (DeepSeek / Qwen / Llama) — viable? Recommendation: yes, but local inference often slow; profile decision.
4. **Synthetic-bug catalog curation** — who maintains? Recommendation: Specrew core owns initial; community contributions via PR with sanity checks; growing the catalog is a long-term effort.
5. **Synthetic-bug detection by the reviewer (gaming the test)** — the reviewer might learn to spot synthetic patterns specifically. Recommendation: rotate synthetic catalog frequently; mix real-world bug patterns; track catch-rate decay.
6. **Reviewer prompts as Specrew assets** — what's in them? Recommendation: prompts live in `.specrew/charters/reviewer-<model>.md`; per-model templates; explicit form-vs-meaning instructions; reviewer must cite-or-decline.
7. **False-positive rate management** — overzealous reviewer flags everything, retro pain. Recommendation: severity-tagging in reviewer output; low-severity findings can be batch-dismissed at retro; track false-positive rate as a dashboard metric.
8. **What if user can't afford L2 even for feature work?** Recommendation: cost-affordability profile setting; if disabled, lifecycle falls through to L0 with clear documentation that no structural reviewer independence is in place.
9. **Reviewer for closed-iteration retro** — should reviewer also review the retro? Recommendation: out of scope for MVP; possibly future.
10. **L3 cross-training-lineage is hard today** — most powerful models are from a handful of labs with potential data overlap. Recommendation: acknowledge L3 is aspirational at MVP; treat L2 as the practical maximum until more diverse models mature.

## Risks

1. **Cost overhead bounces adoption** — 40-80% inference-cost overhead is significant. *Mitigation*: profile-conditional; slice-type defaults; cost-affordability override.
2. **Reviewer becomes ceremonial form-without-meaning** — passes everything indiscriminately. *Mitigation*: form-vs-meaning safeguards (Pillar 4); synthetic injection; retro tracks catch-rate.
3. **Cross-vendor doesn't deliver promised independence** — training-data overlap defeats Level 2. *Mitigation*: explicit L3 level for cases where this matters; honest framing in docs ("L2 protects against most blind spots; L3 protects against more").
4. **Provider outage cripples lifecycle** — reviewer down → boundary blocked. *Mitigation*: availability fallback policy (Pillar 5).
5. **Routing config drift** — `.specrew/agent-routing.yml` gets stale; reviewer points at deprecated model. *Mitigation*: routing validator checks model availability; composes with Proposal 068 (cost-aware-routing + agent-discovered-model-catalog).
6. **Reviewer prompt becomes its own debt** — long, brittle, requires retuning. *Mitigation*: small core prompt; per-model templates; composes with Proposal 015 (expertise-aware) for tone tuning.
7. **Synthetic-catalog rot** — bugs become unrepresentative of real defects. *Mitigation*: catalog refresh policy; pulls real defects from retro / PR-review-resolution history.
8. **Dual-reviewer creates contradictions** — reviewer says "fix this", implementer (or human) disagrees. *Mitigation*: explicit conflict-resolution flow at boundary; reviewer findings don't unilaterally block; human-or-implementer can dispute with reason.
9. **Reviewer's findings become a target for prompt-injection** — malicious code attempts to suppress reviewer comments. *Mitigation*: composes with Proposal 100 (Agent-Class Threat Surface).
10. **Per-project model pair selection is hard** — users don't know which models pair well. *Mitigation*: Specrew core publishes recommended pairings; default is sensible; advanced users override.

## Cross-references

- **Composes with**:
  - [014 Red Team Agent](014-red-team-agent.md) — 099 implements a structural version of what 014 proposes; possibly subsumes 014 at clarify time
  - [018 Source-Spec Fidelity Contract](018-source-spec-fidelity.md) — 099's spec-traceback (FR-007) is the mechanism; 018 sets the contract
  - [030 Quality Hardening Bundle (Form-vs-Meaning)](030-quality-hardening-bundle.md) — same form-vs-meaning pattern
  - [047 Project Governance Profile](047-project-governance-profile.md) — sets per-project independence-level defaults
  - [068 Cost-Aware Model Routing + Agent-Discovered Catalog](068-cost-aware-model-routing.md) — supplies the catalog of available models; 099 consumes
  - [069 Multi-Host Launch Path](069-multi-host-launch-path.md) — supplies multi-host execution; 099 uses
  - [070 Token Economy MVP](070-token-economy-mvp.md) — reviewer cost feeds the ledger
  - [073 Review Evidence Integrity](073-review-evidence-integrity.md) — form-vs-meaning safeguards pattern shared
  - [086 Validation Pipeline Performance Bundle](086-validation-pipeline-performance-bundle.md) — caching pattern for reviewer outputs
  - [089 PR Review Integration](089-pr-review-integration-address-pr-review-gate.md) — primary composition; 099 extends 089's adapter machinery rather than parallel system
  - [092 Specrew Dashboard Web App](092-specrew-dashboard-web-app.md) — reviewer-pair effectiveness view
  - [100 Agent-Class Threat Surface](100-agent-class-threat-surface.md) — protects against reviewer-suppression attacks
- **Possibly subsumes** (at clarify time):
  - 014 Red Team Agent — if 099's L2/L3 reviewer covers the adversarial-review use case
- **Sources**:
  - External research document received 2026-05-22 (raised the cross-model-reviewer pattern; this proposal sharpens with three-failure-mode + cross-training-lineage analysis)

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to external research document's "dedicated independent validation LLM" framing, sharpened with concrete failure-mode analysis and the cross-training-lineage requirement. Awaiting clarify-time decisions on independence-level defaults, synthetic-catalog curation, and L3 viability.
