---
proposal: 196
title: Event-Backed Workshop Provenance
status: candidate
phase: phase-2
estimated-sp: 10-16
priority-tier: 1
type: governance-workshop-integrity
discussion: surfaced 2026-06-17 during Feature 184 dogfooding after an agent self-authored workshop/specify artifacts and marked lens records human-confirmed without actually running the human workshop
composes-with:
  - 141  # Crew Interaction Profile / Persona Lens Separation; Amendment A7 confirmation integrity
  - 145  # Structured Multi-Phase Reviewer
  - 156  # Design Analysis Lens Knowledge Catalog
  - 165  # PreToolUse Render-Gate Hook
  - 176  # Product & Problem Domain Lens
  - 180  # PreToolUse Lifecycle Entry Gate
  - 188  # Host-Neutral Boundary Packet Enforcement
  - 190  # Governance Self-Modification Guard
audience: maintainers, Crew agents, host-adapter authors, downstream project owners
---

# Event-Backed Workshop Provenance

## Why

Specrew already says the right thing: never manufacture human agreement.
Proposal 141 Amendment A7 added the conduct rule and the `confirmation` /
`confirmation_scope` floor, and the specify gate now rejects missing or invalid
provenance values.

That is necessary, but it is not sufficient.

The current gate can prove that a lens record *declares*:

```text
confirmation: human-confirmed
confirmation_scope: lens-question
```

It cannot prove that the human actually saw the lens question and answered it.
The deterministic floor was intentionally honest about that limit: SC-026 checks
shape, while SC-027 relies on dogfood behavior. A capable agent can still write
valid-looking workshop artifacts, mark each lens as `human-confirmed`, and move
on without having asked the user.

Feature 184 dogfooding reproduced exactly that failure mode. A full workshop and
specify packet were written as if the maintainer had confirmed the lenses, but
the interaction did not happen. This is not a documentation problem. The prompts
already forbid it. It is a missing mechanical trust boundary between:

1. the human-visible workshop interaction;
2. the durable workshop record;
3. the specify boundary gate that trusts that record.

Specrew needs a provenance mechanism that can reject "human-confirmed" records
unless they are backed by a recorded ask/answer event.

## What

Add **Event-Backed Workshop Provenance**: a minimal workshop event ledger,
validated writer path, specify-boundary gate, and host-time guardrails that make
`human-confirmed` a mechanically supported claim rather than an agent-authored
label.

### Core Invariant

`human-confirmed` means:

```text
The Crew rendered a specific lens question or decision prompt to the human, and
the human answered that prompt, before the lens record was written.
```

If that event evidence is missing, the record may be:

- `human-delegated` with `confirmation_scope: explicit-delegation`;
- `human-skipped` with `confirmation_scope: explicit-skip`;
- `agent-proposed` / pending, if the eventual schema adds an explicit pending
  state;
- blocked at specify boundary.

It must not be `human-confirmed`.

### Workshop Event Ledger

Introduce a runtime-local or feature-local event ledger for workshop
interaction evidence. The first version should record only the minimum needed
to prove provenance without storing full transcripts.

Suggested location:

```text
specs/<feature>/workshop/events.jsonl
```

Suggested event types:

| Event | Meaning |
| --- | --- |
| `workshop_prompt_rendered` | A lens question, agenda, option set, or decision prompt was rendered to the human. |
| `workshop_answer_received` | The human answered a previously rendered prompt. |
| `workshop_decision_written` | A durable lens decision record was written from matched prompt/answer evidence. |
| `workshop_delegation_received` | The human explicitly delegated one or more named lenses or decisions. |
| `workshop_skip_received` | The human explicitly skipped one or more named lenses or decisions. |

Each event should include:

- `event_id`;
- `feature_id`;
- `lens_id`;
- `workshop_prompt_id`;
- `prompt_hash` over the rendered question/option content;
- `answer_hash` or bounded answer excerpt/hash, depending on privacy posture;
- `host_id` and host capability mode;
- `session_id` or conversation id where available;
- timestamp;
- source command or adapter that recorded the event.

The ledger does not need to become a full transcript store. It needs enough
evidence to prove that a given durable `human-confirmed` claim is not purely
self-authored.

### Validated Writer Path

Workshop artifacts should be written through a deterministic command or helper,
not by arbitrary model-authored JSON/YAML edits.

The writer should:

1. accept a lens id, rendered prompt id, answer event id, decision summary,
   confirmation value, and confirmation scope;
2. verify that `human-confirmed` is backed by a matching
   `workshop_prompt_rendered` + `workshop_answer_received` pair;
3. verify that `human-delegated` and `human-skipped` are backed by explicit
   delegation/skip events;
4. write `lens-applicability.json`, per-lens records, and Proposal 156 decision
   streams with the supporting event ids and hashes;
5. fail loudly when the support is missing.

The intended flow becomes:

```text
render prompt -> record rendered event -> receive human answer -> record answer
event -> validated writer writes lens artifact with event-backed provenance
```

The agent can still draft the wording of a decision summary, but it cannot mint
the provenance claim by direct file edit.

### Specify Boundary Gate

Extend the specify-boundary lens workshop gate beyond SC-026's shape check.

For every selected lens:

- `human-confirmed` + `lens-question` requires a matching rendered-prompt event
  and human-answer event for that lens;
- `human-delegated` + `explicit-delegation` requires an explicit delegation
  event naming the affected lens or a bounded named set of lenses;
- `human-skipped` + `explicit-skip` requires an explicit skip event naming the
  affected lens or bounded named set;
- a batch "looks good" is not confirmation unless the rendered prompt
  explicitly asked for that bounded batch and the answer maps to it;
- records without event ids are rejected for new features unless grandfathered
  by a clear migration rule.

This gate should be deterministic and LLM-free. It should inspect artifacts and
the ledger, not infer truth from chat prose.

### Host-Time Direct-Edit Guard

Where a host can intercept file writes, direct edits to workshop provenance
artifacts should warn or deny unless they come from the validated writer path.

Initial protected files:

- `specs/<feature>/lens-applicability.json`;
- `specs/<feature>/workshop/*.yml`;
- `specs/<feature>/workshop/*.yaml`;
- `specs/<feature>/workshop-decisions.yml`;
- `specs/<feature>/implementation-rules.yml`;
- future structured lens records that carry confirmation provenance.

The guard is early feedback, not the sole authority. Hosts without write hooks
still get the deterministic specify-boundary gate.

### Delegation Is First-Class

Sometimes the human genuinely wants to delegate:

```text
You decide the remaining low-risk implementation-rule details.
```

That should be allowed, but it is not `human-confirmed`. The writer records:

```text
confirmation: human-delegated
confirmation_scope: explicit-delegation
delegation_event_id: <event>
delegation_bounds: <named lenses/decisions>
```

This preserves user convenience while preventing delegated agent judgment from
masquerading as human lens-question confirmation.

### Proposal 145 Review Integration

Proposal 145 review should gain a workshop-provenance phase:

1. count selected lenses;
2. count event-backed confirmed, delegated, and skipped lenses;
3. verify every selected lens has one valid disposition;
4. verify every `human-confirmed` record cites prompt/answer event evidence;
5. flag direct edits to protected workshop artifacts outside the writer path;
6. reject review-signoff if a spec depends on fabricated or unsupported
   workshop agreement.

This complements Proposal 145's existing conformance role: it verifies the
review did not merely accept durable artifacts at face value when the artifacts
claim human agreement.

## Functional Requirements

- **FR-001**: Specrew MUST record workshop prompt-render and human-answer events
  with stable ids, lens ids, prompt hashes, host/session metadata, and
  timestamps.
- **FR-002**: Specrew MUST provide a validated writer path for workshop
  provenance artifacts.
- **FR-003**: The writer MUST reject `human-confirmed` unless matching
  prompt-render and human-answer events exist for the same lens/question.
- **FR-004**: The writer MUST record explicit event evidence for
  `human-delegated` and `human-skipped`.
- **FR-005**: The specify boundary gate MUST reject new
  `human-confirmed` lens records that lack matching event-backed evidence.
- **FR-006**: Batch approval MUST NOT count as lens-question confirmation unless
  the rendered prompt explicitly names the bounded batch being confirmed.
- **FR-007**: Host-time write guards SHOULD warn or deny direct edits to
  structured workshop provenance artifacts outside the validated writer path
  when the host supports such enforcement.
- **FR-008**: Proposal 145 review MUST verify selected-lens count,
  disposition count, event-backed evidence, and direct-edit anomalies.
- **FR-009**: Downstream projects MUST receive the same guard through deployed
  Specrew runtime assets, not a Specrew-repo-only fix.
- **FR-010**: Migration MUST be explicit: older artifacts are grandfathered,
  backfilled as non-authoritative, or forced through a re-confirmation path, but
  never silently upgraded to event-backed `human-confirmed`.

## Acceptance Criteria

- **AC1**: A feature with `human-confirmed` lens records but no matching
  prompt/answer events fails the specify boundary gate.
- **AC2**: A feature where each selected lens was rendered, answered, and
  written through the validated writer passes the specify boundary gate.
- **AC3**: An explicit human delegation for named lenses records
  `human-delegated / explicit-delegation` and passes without claiming
  `human-confirmed`.
- **AC4**: A direct edit to `lens-applicability.json` that adds
  `human-confirmed` without writer provenance is detected by validation even on
  hosts without write hooks.
- **AC5**: On a hook-capable host, direct edits to protected workshop
  provenance files produce an immediate warning or denial naming the validated
  writer path.
- **AC6**: Proposal 145 review output includes a workshop-provenance summary:
  selected lenses, confirmed, delegated, skipped, unsupported claims, and direct
  edit anomalies.
- **AC7**: Existing pre-event-ledger features are handled by a documented
  migration/grandfather rule and are not represented as event-backed unless real
  evidence exists.
- **AC8**: A downstream Specrew-initialized project receives the same
  enforcement and can reproduce AC1 through AC4 outside the Specrew repository.

## Out of Scope

- Capturing full verbatim transcripts for every workshop. Minimal event evidence
  is enough for provenance.
- Proving the human's answer was wise or complete. This proposal proves that an
  answer existed for the rendered prompt; Proposal 145 and later review still
  judge quality and traceability.
- Replacing the design-workshop methodology, product-domain lens, or lens
  catalog.
- Replacing host-neutral packet enforcement. Proposal 188 owns the boundary
  packet shape; this proposal owns workshop confirmation evidence.
- Solving malicious tampering with all repository files. Proposal 190 owns the
  broader protected-governance-surface guard.
- Making hosts without hook support equivalent to hook-capable hosts at edit
  time. The deterministic boundary gate remains authoritative.

## Effort

- **Iteration 1 (~3-5 SP)**: Define the event schema, ledger writer, validated
  workshop decision writer, and unit tests for confirmed/delegated/skipped
  provenance.
- **Iteration 2 (~3-5 SP)**: Wire the specify boundary gate and migration /
  grandfather behavior; add downstream fixture coverage.
- **Iteration 3 (~2-3 SP)**: Add Proposal 145 review checks and direct-edit
  anomaly reporting.
- **Iteration 4 (~2-3 SP)**: Add host-time write guards where supported and
  document degraded modes for hosts without write interception.
- **Total**: ~10-16 SP.

## Phase Placement

Phase 2, priority tier 1.

This is governance integrity infrastructure. It protects the workshop
confirmation contract for Specrew itself and for downstream projects, and it
turns the existing "never manufacture agreement" rule from prompt-only conduct
into a deterministic boundary condition.

## Open Questions

1. Should `events.jsonl` live under `workshop/` as feature evidence, or under
   ignored runtime-local state with hashes copied into feature artifacts?
2. Should prompt and answer evidence store bounded excerpts, hashes only, or a
   privacy-configurable mix?
3. What is the exact grandfather rule for features created after Proposal 141
   but before this proposal ships?
4. Should the validated writer be a PowerShell script, a Specrew CLI command, or
   both?
5. Which hosts can reliably identify that a write came from the validated
   writer path rather than a direct model edit?

## Risks

- **False ceremony**: every workshop turn could become noisy. Mitigate by making
  event capture automatic and invisible during normal questioning.
- **Privacy / transcript concern**: users may not want full answers stored.
  Mitigate with hashes and bounded excerpts by default.
- **Host variance**: some hosts cannot expose a stable conversation/session id.
  Mitigate by treating host/session metadata as best available and keeping the
  prompt/answer event ids as the core evidence.
- **Manual artifact repair friction**: maintainers sometimes need to repair
  broken JSON/YAML. Mitigate with an explicit repair mode that records the
  artifact as repaired, not newly human-confirmed.
- **Forged ledger events**: an agent could try to write the ledger directly.
  Mitigate with the same direct-edit guard pattern and Proposal 190's protected
  governance surface model.

## Cross-References

- [141 Crew Interaction Profile / Persona Lens Separation](141-capability-dial-persona-lens-separation.md)
  supplied the A7 confirmation-integrity invariant, SC-026 shape floor, and
  SC-027 dogfood acceptance that this proposal makes mechanically checkable.
- [145 Structured Multi-Phase Reviewer](145-structured-multi-phase-reviewer.md)
  should consume the workshop-provenance review phase.
- [156 Design Analysis Lens Knowledge Catalog](156-design-analysis-lens-knowledge-catalog.md)
  owns durable lens decision streams that need event-backed provenance.
- [165 PreToolUse Render-Gate Hook](165-pretooluse-render-gate-hook.md)
  is the sibling lesson that prompt conduct needs host-time enforcement when a
  host's interaction surface makes skipping easy.
- [176 Product & Problem Domain Lens](176-product-domain-first-lens.md)
  is one of the first high-value lenses protected by this provenance model.
- [180 PreToolUse Lifecycle Entry Gate](180-pretooluse-lifecycle-entry-gate.md)
  covers first-source-write lifecycle entry; this proposal covers workshop
  confirmation truth once lifecycle entry begins.
- [188 Host-Neutral Boundary Packet Enforcement](188-host-neutral-boundary-packet-enforcement.md)
  supplies the boundary packet enforcement surface; this proposal supplies the
  underlying workshop confirmation evidence.
- [190 Governance Self-Modification Guard](190-governance-self-modification-guard.md)
  protects the validators, hooks, and writer machinery that would enforce this
  proposal.

## Status History

- 2026-06-17: Created as candidate after Feature 184 dogfooding showed that
  valid-looking `human-confirmed` workshop records can still be fabricated
  without a mechanical event-backed writer and boundary gate.
