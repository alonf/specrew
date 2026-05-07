# Spike Results: Agent HQ Detection API Validation

**Schema**: v1  
**Iteration**: 001  
**Spike**: V-R7-1  
**Created**: 2026-04-19  
**Research Reference**: [research.md R7](../research.md) (FR-021, FR-022)

## Objective

Validate the shape and availability of Copilot / Agent HQ detection APIs before implementing T-011 (agent detection + consent). Confirm that `specrew init` can non-destructively probe delegated-agent availability and document graceful degradation patterns when probes fail.

## Findings

### Copilot Runtime Detection

**Primary Surface**: Standalone `copilot` CLI (not `gh copilot`)

- ✅ `copilot --version` succeeds; returns version string (`GitHub Copilot CLI 1.0.31` in this environment)
- ✅ `copilot --help` and `copilot help config` are the documented metadata surfaces
- ✅ Environment markers `COPILOT_CLI`, `COPILOT_AGENT_SESSION_ID`, `COPILOT_CLI_BINARY_VERSION` confirm active Copilot session context
- ✅ Copilot availability is deterministic: CLI presence = Copilot availability

**Inference**: Copilot runtime is reliably detectable. Non-availability is silent (command not in PATH or returns non-zero exit code).

### Delegated-Agent Enumeration

**Primary Surface**: `copilot help config` → `models` section

- ✅ Section contains agent model IDs (Claude family, Codex family, Copilot family)
- ✅ Enumeration format is stable and parseable using regex or line-based parsing
- ✅ Agent availability reflects user's GitHub Copilot subscription and tenant policy
- ✅ Safe to probe: read-only operation, no side effects, fast execution

**Failure Mode**: If `copilot help config` fails or section is absent, treat all delegated agents as unavailable. Bootstrap continues with Copilot-only default.

**Inference**: Delegated-agent enumeration is optional but available; bootstrap gracefully continues when unavailable.

### GitHub Auth Context (Secondary Probe)

- ✅ `gh api /user` confirms GitHub identity context (enables scope validation)
- ⚠️ Does **not** enumerate delegated-agent availability (use `copilot help config` instead)
- ⚠️ Missing auth context is non-fatal; user can bootstrap without GitHub auth for local-only iteration

### Consent Model

**User Validation**: Manual testing confirms that using different delegated agents for review (e.g., Claude for review vs. Copilot for implementation) yields higher-quality feedback than same-agent self-check. This justifies FR-021 (cross-agent routing) as a v2 feature.

**Spec Implication**: FR-022 (v1) captures consent gates; FR-021 (v2+) uses consent to enable selective routing. The v1 consent mechanism must not block v2 routing features.

## Acceptance Criteria

- ✅ Detection API shape is stable and deterministic
- ✅ Graceful degradation documented (no blocking failures for missing probes)
- ✅ Probe order specified (runtime → auth → delegated-agent enumeration)
- ✅ Non-fatal error semantics confirmed (all probe failures are recoverable)
- ✅ Environment marker presence confirmed for session continuity
- ✅ Billing/cost context explicitly out-of-scope (consent is the only gate)

## Design Decisions for T-011 Implementation

### Probe Sequence

1. **Runtime detection**: `copilot --version` → confirms Copilot CLI availability
2. **Auth context (optional)**: `gh api /user` → confirms GitHub identity (non-blocking)
3. **Delegated-agent enumeration**: `copilot help config` → parse `models` section for Claude/Codex

### Consent Prompt Format (Interactive)

For each detected agent that is available, `specrew init` prompts the user individually:

```
---
Agent Name: Copilot
Access Path: copilot_default
Availability: available
---
Enable copilot for Specrew-managed delegation? (y/N)
```

### Non-Interactive Defaults

- **`--agents=copilot`** (default): Enable Copilot only
- **`--agents=copilot,claude`** or **`--agents=copilot,codex`** (explicit): Enable specified agents
- **`--agents=all`**: Enable all detected agents
- **`--no-agents`**: Disable all agents (spec-only mode, no delegation available)
- **`--force`**: Accept requested agents without prompting

### Config Persistence Schema

**File**: `.specrew/iteration-config.yml` (created at bootstrap in project root)

```yaml
# >>> specrew-managed agents >>>
# Specrew-managed agent consent and detection state (FR-022).
agents:
  copilot:
    enabled: true
    access_path: copilot_default
    availability: available
  claude:
    enabled: false
    access_path: copilot_agent_hq
    availability: available
  codex:
    enabled: false
    access_path: copilot_agent_hq
    availability: unavailable
# <<< specrew-managed agents <<<
```

### Graceful Degradation

| Scenario | Behavior |
| -------- | -------- |
| Copilot CLI missing | Warn, continue with spec-only iteration (no agent routing available) |
| `copilot help config` fails | Warn, assume Copilot-only available, continue |
| GitHub auth missing | Warn (non-critical), continue with local-only iteration |
| All agents unavailable | Warn but proceed; iteration runs under Copilot default or uses spec-authority fallback |

## Unresolved Questions (Out of V-R7-1 Scope)

- **FR-021 (Cross-Agent Routing)**: How does per-role agent preference routing work? Deferred to Iteration 2.
- **Cost/Billing Context**: Should Specrew display per-agent cost estimates? Deferred to Iteration 2+ (explicitly out of FR-022 scope).
- **Agent Capability Matching**: Should Specrew validate that selected agents support iteration tasks? Deferred to Iteration 2+.

## Blocked / Unblocked

- ✅ **Unblocks T-011**: Detection API shape is stable. T-011 can implement agent detection + consent with confidence.
- ✅ **Ready for Review**: V-R7-1 complete. Findings are actionable and deterministic.

## References

- **Source Research**: [research.md § R7](../research.md) — Full findings and decision rationale
- **Requirement**: FR-022 (Agent detection + consent-gated opt-in)
- **Implementation Task**: T-011 (detect agents + interactive consent)
- **Future Work**: FR-021 (cross-agent routing, per-role preference) → Iteration 2
