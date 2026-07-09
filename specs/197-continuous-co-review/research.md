# Phase 0 Research: Continuous Co-Review

## Decision: Use PowerShell 7.x plus Markdown/YAML/JSON local contracts

**Rationale**: `implementation-rules.yml` and the code-implementation workshop bind Proposal 197 to existing Specrew implementation methods, PowerShell 7.x, Pester, and file/stdin/stdout/process-exit contracts. This avoids new dependencies.

**Alternatives considered**: New runtime/package (rejected by dependency policy); hosted service/daemon (rejected by OPS-001); in-session subagent API (rejected by host-neutral contract requirements).

## Decision: Compute change-sets from `git diff` against checkpoint baseline

**Rationale**: FR-003 and SC-007 require visibility into tool-call edits, formatter changes, generated files, hand edits, merge effects, and out-of-band worktree changes.

**Alternatives considered**: PostToolUse/hooks (out of scope); editor event streams (host-specific and incomplete); per-micro-edit review (too noisy).

## Decision: Define stable versioned JSON schemas

**Rationale**: FR-001, FR-002, INT-002, and NFR-010 require deterministic inputs/outputs, stable schemas, adapter seams, and standalone gate validator testability.

**Alternatives considered**: Provider-specific protocols (rejected; adapters translate); plain markdown findings (not machine-verifiable); hardcoded model IDs in policy (volatile).

## Decision: Use filesystem-only durable evidence and per-run temporary workspaces

**Rationale**: DS-001..DS-005 require `.specrew/review/inline/<run-id>/...`, no database/cache/queue/event stream/blob/search provider, immutable per-run bundles, cleanup by default, and schema-versioned artifacts.

**Alternatives considered**: Database/queue state (out of scope); bundle reuse (breaks replay/concurrency); raw prompt/transcript audit (secret/noise risk).

## Decision: Treat reviewer as trusted for read access but read-only for mutation

**Rationale**: SEC-001..SEC-003 require enough repository/design context for quality review while preventing source, Git, or Specrew state mutation. Iteration 001 must not claim hard OS/filesystem sandboxing.

**Alternatives considered**: Blind reviewer (reduces quality); hard sandboxing claim (deferred); reviewer-authored source edits (violates contract).

## Decision: Require explicit provider/model configuration and authorization

**Rationale**: FR-016, SEC-004, INT-006..INT-008, OBS-006, and OPS-004 require no implicit spend, no secret collection, no silent downgrade, and requested/actual host-model provenance. Availability fallback is limited to one pre-authorized alternate.

**Alternatives considered**: Auto-choose any installed model (cost/authorization risk); quota probing (out of scope); hardcoded model catalogs (volatile).

## Decision: Keep host behavior behind reviewer-domain adapter seams

**Rationale**: Stable contracts stay inward; host CLI details stay outward. Proposal 197 must not collide with F-184 provider files, so names use `reviewer-host-adapter-*`, `reviewer-model-capability`, and `reviewer-host-catalog`.

**Alternatives considered**: Editing F-184 provider files (forbidden); central host-name switches (poor separation); dynamic plugins (future scope).

## Decision: Inject the canonical reviewer definition into every runtime prompt

**Rationale**: The review send-back showed that a bare request JSON does not carry the Proposal 145 rubric, workshop-decision conformance policy, visibility policy, do-policy, or round/prior-finding context to a fresh reviewer model. Runtime correctness therefore depends on a Specrew-owned canonical reviewer instruction file at `scripts/internal/continuous-co-review/code-review-agent.md` and a prompt-composer boundary that injects that file's content, `ReviewRequest.v2` design-context content, exact diff content, round number, prior findings, visibility policy, do-policy, and `FindingsResult.v1` output contract into the headless `-p` / `exec` prompt before any adapter invocation.

**Alternatives considered**: Relying on host-native agent/skill folders (rejected because host auto-loading is inconsistent and not uniformly testable); duplicating rubric text in each adapter (rejected because adapters must remain transport-only); leaving instructions in durable request JSON only (rejected because the model receives the prompt, not an implicit contract document).

## Decision: Use deterministic gate states and structured infrastructure failures

**Rationale**: FR-006, FR-007, NFR-001, INT-005, OBS-004, and OBS-005 require blocking on unresolved `blocking` findings, malformed state, invalid schemas, timeouts, missing providers, invalid JSON, unavailable requested model, and non-convergence. No reviewable diff becomes explicit `ReviewRunSkipped` plus pass/no-op verdict.

**Alternatives considered**: Treat failures as no findings (unsafe); indefinite loops (rejected by two-round cap); text-only fixed markers (insufficient).

## Decision: Preserve CI/CD E2E hooks/fixtures without naming a new companion proposal

**Rationale**: Proposal 197 exposes contract hooks/fixtures for downstream CI/CD E2E coverage, composed later with Proposal 181 plus Proposal 194 canary, but does not add workflows, service identities, branch-protection changes, or a newly named E2E proposal.

**Alternatives considered**: Implement CI/CD E2E now (out of scope); name a new companion proposal (forbidden); remove fixture hooks (violates INT-009/OPS-006/OBS-003).

## Decision: Phase 1 quality uses bounded custom composition

**Rationale**: Required dimensions are code quality, design-quality-and-separation-of-concerns, verification-confidence, maintainability, security, and robustness. Required mechanical checks are dead-field, anti-pattern, and test-integrity.

**Alternatives considered**: Single recognized preset (not a match); Phase 2 hardening/bug-hunter/routing now (explicitly deferred); budget Proposal 196 lens-stamp provenance here (wrong scope).
