# Observability Resilience Lens

## Decision

Keep Antigravity hook failures fail-open for the host session, but make failures
diagnosable through existing Specrew warning codes, per-session runtime state,
bounded journal evidence, and required real-host validation before any full
parity claim.

## Request Trace And Evidence Flow

```text
agy hook fires
   |
   v
+---------------------------+
| SpecrewHookDispatcher     |
+-------------+-------------+
              |
      +-------+------------------+
      |                          |
      v                          v
stderr WARNs                 .specrew/runtime state
PROVIDER_FAILED              refocus-state-<conversationId>.json
STATE_UNAVAILABLE            boundary cursor / anchor
PAYLOAD_OVERSIZE             dedupe / breaker / journal
      |                          |
      +------------+-------------+
                   v
        review evidence bundle
        real agy transcript + logs
        hook fired / injection seen
        exit-reentry preserved state
        no false B3 / no false concurrency
```

## Required Signals

- `conversationId` after sanitization.
- Host event name: `PreInvocation`, `PostInvocation`, `PreToolUse`,
  `PostToolUse`, or `Stop`.
- Refocus trigger: `b2` or `b3`.
- Boundary cursor and whether it changed.
- Outcome: anchored, injected, deduped, skipped, failed, breaker-suppressed, or
  fallback.
- Provider warning code when a provider or dispatcher fails.
- Transcript path reference for real-host evidence, without copying full
  transcript content into runtime state.

## Failure Handling

- Hook execution must fail open and must not block `agy`.
- Provider failures emit existing stderr warning codes such as
  `PROVIDER_FAILED`.
- State read/write failures use the existing governed failure/fallback behavior
  and must not silently claim full refocus.
- Invalid Antigravity output schemas are treated as implementation defects; the
  known `PostToolUse`/`injectSteps` rejection must be avoided.
- The breaker and dedupe behavior remains shared with other hosts.

## Evidence Boundaries

- Review must require real-host `agy` evidence before the docs or host matrix
  claim full Antigravity parity.
- Evidence must prove hook firing, injection delivery, B3 correctness,
  self-marker concurrency behavior, handover, and exit/re-entry.
- Runtime state should store bounded diagnostic facts and journal entries, not
  full prompts, full transcript content, or large model responses.
- Machine-local evidence may be labeled as such during development, but release
  validation must either reproduce it from the repo or keep the machine-local
  limitation explicit.

## Failure Mode Matrix

```text
Failure mode                         Expected behavior
-----------------------------------  -----------------------------------------
missing conversationId               per-launch fallback only, no unknown key
state file corrupt/unreadable         STATE_UNAVAILABLE warning, no automation
provider non-zero/timeout             PROVIDER_FAILED warning, fail open
PostToolUse injectSteps attempted     forbidden; regression should catch it
payload over host cap                 PAYLOAD_OVERSIZE warning
false self-marker concurrency hit     fixed or explicitly red before parity
exit/re-entry loses anchor            red; full Antigravity claim blocked
```

## Confirmation

The human agreed to this observability/resilience model: fail-open hooks, loud
stderr warnings, bounded session/journal evidence, no full prompt/transcript
logging in runtime state, and real-host proof for Antigravity parity claims.
