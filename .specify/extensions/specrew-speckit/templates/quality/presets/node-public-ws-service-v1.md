# Stack Preset: node-public-ws-service v1.0.0

| Field | Value |
| --- | --- |
| Preset ID | `node-public-ws-service` |
| Version | `v1.0.0` |
| Phase Scope | `phase-1-first-slice` |
| Intent | Reviewable Phase 1 quality baseline for a public Node.js websocket service with long-lived connection state. |

## Supported Stack Signals

| Signal | Match Examples | Why it qualifies |
| --- | --- | --- |
| `package.json` | Service root manifest | Establishes a Node.js runtime/toolchain surface. |
| Websocket transport dependency | `ws`, framework websocket adapter, or explicit upgrade handler | Indicates bidirectional realtime behavior. |
| Public websocket endpoint | internet-facing `/ws` route, upgrade path, or documented client channel | Activates external trust-boundary and session-lifecycle review. |

## Required Quality Dimensions

| Dimension | Activation Rule | Phase 1 Expectation |
| --- | --- | --- |
| `security` | Anonymous or authenticated clients can open a live connection. | Validate handshake/auth assumptions, payload validation, and sensitive-message leakage boundaries. |
| `robustness` | Connections are long-lived and can reconnect, disconnect, or back up. | Make failure handling, cleanup, and degraded behavior explicit and reviewable. |
| `verification-confidence` | Realtime behavior is stateful and timing-sensitive. | Require deterministic assertions for connect, authorize, message, and disconnect behavior. |

## Required Mechanical Checks

| Check | Required Configuration | Blocking Expectation |
| --- | --- | --- |
| `dead-field` | Inspect websocket payload DTOs, connection context fields, and subscription metadata for unused members. | Unused fields are removed or explicitly justified instead of silently drifting. |
| `anti-pattern` | Review message handlers for synchronous blocking work, hidden fire-and-forget failures, and ambiguous partial success. | Request/response and push handlers remain bounded, observable, and explicit about failure semantics. |
| `test-integrity` | Require assertion-driven lifecycle tests for handshake, authorization failure, message handling, and disconnect cleanup. | Tests prove observable websocket outcomes rather than only opening a socket. |

## Required Lens Checklist References

| Lens | Version | Activation Rationale |
| --- | --- | --- |
| `security-baseline` | `v1.0.0` | Public ingress, token handling, and message trust boundaries require explicit review. |
| `robustness-baseline` | `v1.0.0` | Session lifecycle, retries, cleanup, and degraded operation are material to websocket services. |
| `test-integrity` | `v1.0.0` | Realtime tests must prove more than happy-path connectivity. |

## Toolchain / Evidence Expectations

| Area | Concrete Selection | Evidence Expectation |
| --- | --- | --- |
| Package + test workflow | `npm` with `npm test` | Test evidence covers connection lifecycle and message semantics. |
| Static feedback lane | Repo-standard Node lint/static-analysis command when configured | Findings or pass output are retained in reviewable evidence. |
| Integration focus | Deterministic websocket integration checks | Evidence proves connect, authorize, send, receive, and disconnect behavior. |
| Governance artifacts | Preset reference plus iteration `quality/` artifacts | Reviewers can trace the selected preset to concrete evidence. |

## Worked Example

### Example Context

- Runtime: public Node.js websocket service
- Repo signals: `package.json`, websocket transport dependency, documented public `/ws` endpoint
- Phase boundary: Phase 1 / first slice only; no hardening gate, bug-hunter routing, or drift automation implied

### Example Preset Resolution

| Profile Field | Concrete Selection |
| --- | --- |
| Inferred profile ID | `quality-profile.node-public-ws-service.v1` |
| Preset Ref | `node-public-ws-service@v1.0.0` |
| Stack Surfaces | `service-runtime`, `websocket-boundary`, `session-state` |
| Tool Bundle ID | `node-websocket-phase1` |
| Evidence Directory | `specs/<feature>/iterations/<NNN>/quality/` |

### Example Lens Activations

| Lens Ref | Why it is active | Expected Review Focus |
| --- | --- | --- |
| `security-baseline@v1.0.0` | The websocket endpoint is externally reachable and may carry auth/session data. | Handshake trust boundary, payload validation, secret leakage, auth assumptions. |
| `robustness-baseline@v1.0.0` | Connection churn and fan-out behavior can fail in non-obvious ways. | Cleanup, timeout handling, retry/idempotency, degraded behavior. |
| `test-integrity@v1.0.0` | Realtime tests often look green while proving little. | Assertion quality, negative-path proof, determinism. |

### Example Mechanical Check Configuration

| Check | Concrete Configuration | Gate Category | Expected Outcome |
| --- | --- | --- | --- |
| `dead-field` | Review message payload schemas, connection context DTOs, and subscription metadata for fields that are written but never read. | `mechanical` | Remove dead payload fields or record an explicit rationale. |
| `anti-pattern` | Flag synchronous file/database work inside message handlers and hidden background exceptions in broadcast flows. | `mechanical` | Handler behavior stays bounded and failures remain visible. |
| `test-integrity` | Require assertions for successful handshake, rejected handshake/auth failure, message side effects, and disconnect cleanup. | `mechanical` | Tests demonstrate meaningful lifecycle behavior, not smoke-only connectivity. |

### Example Risk Dimension Mapping

| Dimension | Concrete Risk Surface | Evidence Expectation |
| --- | --- | --- |
| `security` | Untrusted clients, auth/session propagation, payload validation, cross-session leakage | Security checklist rows and test evidence cover handshake and message-boundary rules. |
| `robustness` | Connection churn, retry/reconnect semantics, cleanup, backpressure, shutdown behavior | Robustness evidence shows explicit lifecycle ownership and failure handling. |
| `verification-confidence` | Timing-sensitive tests, asynchronous ordering, false-positive websocket smoke tests | Test-integrity evidence shows deterministic assertions for both happy and unhappy paths. |

### Example Evidence Expectations

| Evidence Item | Concrete Expectation |
| --- | --- |
| Tooling evidence | `npm test` includes websocket integration scenarios with explicit assertions. |
| Mechanical findings | `mechanical-findings.json` records any dead-field, anti-pattern, or test-integrity violations against websocket paths. |
| Manual review evidence | `quality-evidence.md` references the activated lens rows with notes for handshake, lifecycle, and test quality. |
| Not-applicable rationale | Any skipped gate or row records why it does not materially apply to the reviewed websocket surface. |

## Upgrade Guidance

1. Review websocket transport or session-model changes before adopting a newer preset version.
2. Update lens references independently; a newer lens does not require a new preset unless stack expectations changed.
3. Re-check the worked example whenever the expected Node toolchain or evidence path changes.
4. Keep later-phase hardening, bug-hunter execution, and drift automation explicitly deferred unless a future preset version is approved to include them.

## Change Log

| Version | Date | Change | Review Notes |
| --- | --- | --- | --- |
| `v1.0.0` | 2026-05-07 | Initial Phase 1 public websocket preset with a fully specified worked example. | Establishes the FR-024 / FR-024a baseline without implying later-phase workflows. |
