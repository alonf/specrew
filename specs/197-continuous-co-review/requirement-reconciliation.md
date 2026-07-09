# Requirement Reconciliation — F-197 Continuous Co-Review

**Feature**: 197-continuous-co-review
**Date**: 2026-07-01
**Author**: Crew coordinator (maintainer-approved reconciliation)
**Purpose**: Record the disposition of the requirements left open/ambiguous by the iteration-008 worktree cutover, so the spec stays authoritative and no capability — or reviewer instruction — is silently dropped. Companion drift findings: D-197-I009-016 (canonical-instruction orphan) and D-197-I009-017 (cluster reconciliation) in file:///C:/Dev/specrew-197-continuous-co-review/specs/197-continuous-co-review/iterations/009/drift-log.md.

## Context

The iter-008 cutover (`c66e5df6`) replaced the *diff-cramming* reviewer (ReviewRequest.v2 object + prompt-composer + workspace-mutation-guard, all deleted) with an **ephemeral read-only `git archive` worktree + a `.review/` directory contract + a self-contained slim prompt** where the reviewer browses and runs the real project. Several iteration-002 requirements described the deleted machinery; `tasks.md` still marked them `[X]`. This document disposes each against the shipped architecture.

Disposition vocabulary: **SUPERSEDED** (intent delivered differently by the worktree model; original mechanism obsolete) · **SATISFIED** (delivered; may need a trace line) · **OWED** (still genuinely outstanding) · **DECISION** (resolved by an explicit maintainer decision, see manifest).

## A. Iteration-002 "abandoned" cluster (16 requirements)

| Requirement | Original intent | Disposition | Note |
| --- | --- | --- | --- |
| FR-017 | Canonical `code-review-agent.md` reviewer definition | **DECISION** | Orphaned (D-197-I009-016); fold essentials into the slim prompt, retire the file. See §D. |
| FR-018 | Inject the canonical instruction into the real prompt | **DECISION** | Re-mapped to the slim prompt (fold). §D. |
| FR-019 | `ReviewRequest.v2` schema fields | **SUPERSEDED** | Replaced by the `.review/` contract: `changes.diff` + `design/` + `design/contracts/` + `process/`. |
| FR-020 | Read-only flags + uniform mutation guard | **SUPERSEDED** | The discarded ephemeral worktree makes source mutation structurally impossible; no in-process guard needed. |
| FR-021 | Tests assert the real outbound prompt content | **DECISION** | Re-point `reviewer-instruction.Tests.ps1` at `Get-ContinuousCoReviewSlimPrompt`. §D. |
| FR-022 | SC-012 runbook uses the implemented composer path | **SUPERSEDED** | Runbook points at the worktree path; composer gone. Doc update owed with the fold. |
| FR-023 | Pre-implementation rebase/merge latest main | **SATISFIED** | Process discipline; architecture-neutral. |
| SEC-007 | Canonical-instruction integrity via hash | **DECISION** | Slim prompt is code-generated (integrity via source control), not a hashed injected artifact; hash requirement retired with the fold. §D. |
| SEC-008 | Enforced read-only invocation posture | **SATISFIED** | Read-only-to-source by construction (ephemeral `git archive` worktree; source never touched). |
| SEC-009 | Mutation-invalidation boundary | **SUPERSEDED** | No in-place mutation possible in a discarded worktree copy. |
| SC-013 | `code-review-agent.md` verified rubric content | **DECISION** | Rubric preserved via the fold + slim-prompt content test. §D. |
| SC-014 | Prompt-composer tests prove outbound content | **DECISION** | Re-mapped to a slim-prompt content assertion. §D. |
| SC-015 | `ReviewRequest.v2` fixture validation | **SUPERSEDED** | Folded into the `.review/` contract + FindingsResult schema tests. |
| SC-016 | Mutation-guard invalidates the run | **SUPERSEDED** | See FR-020 / SEC-009. |
| SC-017 | Adapters receive only the composed prompt | **SUPERSEDED** | The worktree agent receives the slim prompt via stdin/arg through the host catalog. |
| SC-018 | Manual validation uses the composer path | **SUPERSEDED** | Uses the worktree path (overlaps SC-012). |

## B. Untraced requirements (5)

| Requirement | Original intent | Disposition | Trace to add |
| --- | --- | --- | --- |
| NFR-004 | Fix-verification needs real diff/re-check | **SATISFIED (untraced)** | Round-aware review re-verifies prior blocking findings are resolved in the new change (`Get-ContinuousCoReviewSlimPrompt` round block). |
| NFR-007 | Least-privilege honesty; no false hard-sandbox claim | **SATISFIED (untraced)** | Design is explicit: read-only to source, write-capable in the disposable copy; no hard-sandbox claim (`New-ContinuousCoReviewStrippedWorktree`). |
| NFR-009 | Paid spawn needs authorization | **SATISFIED (untraced)** | `Resolve-ContinuousCoReviewReviewerHost` requires an authorized host from `reviewer-hosts.json` (overlaps FR-016 / SEC-004). |
| FR-026 | Per-stop Stop-hook trigger | **SATISFIED** | The iter-005 async Stop-hook navigator (`continuous-co-review-navigator.ps1` + `worktree-navigator.ps1` + `co-review-service.ps1`; T076–T081). |
| SC-022 | Stop-hook fires across all 5 harnesses | **OWED (partial)** | Navigator is host-neutral; the cross-host manual validation (like SC-012) is outstanding — carried to iter-010 / feature-closeout. |

## C. Owed items (carried)

- **SC-012 / SC-022** — maintainer manual real-host validation across all 5 harnesses (claude, codex, copilot, cursor-agent, antigravity). Partial today; carried to iter-010 or feature-closeout. This is the same "cross-host live validation" theme deferred at Proposals 181/194 for the *automated* case.

## D. `code-review-agent.md` preservation manifest (the fold acceptance checklist)

Maintainer decision 2026-07-01: **fold the essentials into the slim prompt; do not lose any critical instruction.** Every element of `code-review-agent.md` is classified below. The iter-010 fold task is **not complete** until every `TO-FOLD` row is present in `Get-ContinuousCoReviewSlimPrompt` and asserted by the re-pointed `reviewer-instruction.Tests.ps1`.

Legend: **IN-SLIM** = already present in the slim prompt · **TO-FOLD** = must be grafted in · **DROP** = intentionally omitted as stale/contradictory to the worktree model (reason given).

| # | `code-review-agent.md` element | Classification | Rationale |
| --- | --- | --- | --- |
| 1 | Mission: read-only design-conformance, judge diff vs design, return FindingsResult.v1 | IN-SLIM | Slim prompt covers this (and adds the process axis). Drop the `ReviewRequest.v2` framing. |
| 2 | **Report-Falsification Policy** (actively seek evidence the report is false; challenge pass claims; treat empty prompts / substitute prompts / stale mirrors / fake-only assertions / hidden mutation / schema mismatch as falsification risks) | **TO-FOLD** | HIGHEST VALUE. The slim prompt has no adversarial stance. This is what makes the reviewer catch rather than rubber-stamp. |
| 3 | **Workshop-Decision Conformance** (workshop/design-analysis are binding; conflict if it bypasses approved seams, absorbs deferred work, edits protected surfaces, or changes host/runtime assumptions; don't accept convenience over agreement) | **TO-FOLD** | Not in the slim prompt; directly guards the seams F-184/F-197 care about. |
| 4 | **Per-Lens Workshop Validation** (validate against each applicable lens — architecture, component, requirements/NFR, data, security, integration, devops, observability, code-impl; name the violated lens for every blocking finding; UI/UX N/A unless supplied) | **TO-FOLD** | Slim prompt says "architecture/boundaries" generally; naming the lens sharpens findings. |
| 5 | P145 phase — Requirement conformance (every material change justified by an in-scope FR/SC/TG/SEC/INT/OBS/IMPL/data-contract) | TO-FOLD | Make the trace obligation explicit (slim prompt implies it). |
| 6 | P145 phase — Architecture & separation (don't collapse transport/policy/contract/persistence responsibilities) | TO-FOLD | The "don't collapse responsibilities" specificity is worth stating. |
| 7 | P145 phase — Security & privacy (secret exclusion; safe invocation; redaction; no exposure of prompts/transcripts/tokens/env/ambient state) | TO-FOLD | Secret-exclusion + no-exposure specifics (aligns with SEC-002/SEC-006). |
| 8 | P145 phase — Verification confidence (tests prove changed behavior; not empty, bypassed, or fixture-owned substitutes) | TO-FOLD | Slim has "test confidence"; add the "not fixture-owned substitute" specificity. |
| 9 | P145 phase — Operations & observability (deterministic failure; provenance/hashes/timestamps; no live CI or new deps) | TO-FOLD | Add the deterministic-failure + no-new-deps specifics. |
| 10 | P145 phase — Review decision: **unresolved design-contract violations MUST be blocking** | TO-FOLD | The mandatory-blocking rule is load-bearing for the gate. |
| 11 | Claim/Design Trace Policy (cite the strongest reference per finding; a compliance claim without a traceable basis is itself a finding; verify a changed test connects to implementation, not just a fixture) | TO-FOLD | Slim says "cite reference"; add "claim-without-basis = finding" + fixture-connection check. |
| 12 | "Don't treat infrastructure failure / invalid JSON / empty stdout / empty prompt / missing diff / unreadable context as *no findings*" | TO-FOLD | Deterministic-failure ≠ clean pass; central to the never-false-green invariant (SC-024, D-197-I009-010). |
| 13 | No live web search / new dependencies / paid or non-default providers / hidden host tools | TO-FOLD | Cost + determinism guardrail (overlaps NFR-009). |
| 14 | Secret non-exfiltration (don't request/infer secrets, token stores, env values, ambient state; don't persist or echo sensitive content) | TO-FOLD | The valuable half of the visibility policy; keep it. |
| 15 | Round Protocol (round_number/prior_findings; round 1 initial, round 2 verify fixes; escalate to human if a blocking finding survives initial + one fix round; include prior IDs) | IN-SLIM | The slim prompt's round block already covers this. |
| 16 | Output Contract (FindingsResult.v1 fields; JSON only, no prose wrapper) | IN-SLIM | Slim prompt already emits the schema + "no prose around it". |
| 17 | Visibility: "You may read only the content included in the composed prompt" | **DROP** | STALE + CONTRADICTORY — the worktree reviewer is *supposed* to browse the whole repo and run tests. Keeping this would defeat the architecture. |
| 18 | Mission/header framing around `ReviewRequest.v2` + "the prompt composer injects this file into every adapter-bound prompt" | **DROP** | The composer and ReviewRequest.v2 were deleted by the cutover; the statement is now false. |
| 19 | Do-policy: "mark **missing runtime prompt injection** as blocking" | **DROP** | There is no prompt injection step in the worktree model. |
| 20 | "Native host copies are best-effort mirrors; don't rely on native mirrors as authority" | **DROP** | Mirror-authority framing is not relevant to the worktree slim-prompt path. |

**Acceptance:** rows 2–14 present in the slim prompt and asserted by the re-pointed test; rows 17–20 confirmed absent; `code-review-agent.md` moved to a reference location (not deleted — retained as the rubric's prose source of record) or clearly marked non-runtime.
