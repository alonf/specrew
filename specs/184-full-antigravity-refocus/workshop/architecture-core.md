# Architecture Core Lens

## Decision

Reuse the current Specrew refocus architecture and design. F-184 should isolate
Antigravity-specific behavior in bounded host adapter/state changes while
continuing to use the existing dispatcher, session state accessor,
classification engine, B3 decision logic, dedupe, breaker, bootstrap, and
handover machinery.

## Architecture Sketch

```text
Antigravity CLI: agy
        |
        v
.agents/hooks.json
  PreInvocation --------------+
  Stop ---------------------+  |
                            |  |
                            v  v
                  Specrew hook dispatcher
                            |
        +-------------------+-------------------+
        |                                       |
        v                                       v
SessionStateAccessor                  ClassificationEngine
per-session anchor/state              lifecycle boundary cursor
        |                                       |
        +-------------------+-------------------+
                            |
                            v
                    Test-B3ShouldInject
                boundary-cross decision
                            |
                            v
                    Refocus provider
            inject only when boundary changed
```

## Binding Choices

- **Decomposition style**: IDesign / volatility-based reuse. Antigravity event
  variance belongs in the host binding/event adapter and state plumbing, not in
  a parallel refocus subsystem.
- **Proof sequence**:
  1. Prove `PreInvocation` sees a fresh enough boundary cursor before a turn.
  2. Wire Antigravity to the existing per-session refocus state/anchor path.
  3. Prove B3 fires once on a real boundary crossing and does not fire on
     ordinary turns.
- **Split guard**: if B3-on-`PreInvocation` requires a broad host-model rewrite
  beyond bounded adapter/state extension, stop for a human split/defer decision
  before absorbing the scope.
- **Preservation constraint**: F-183 bootstrap injection, Stop handover,
  welcome-back resume, and real conversation-id session keys must not regress.

## Rejected Alternatives

- Leave Antigravity as bounded support: rejected because the product goal is
  completeness.
- Build a parallel Antigravity-only refocus system: rejected unless discovery
  proves reuse cannot support B3-on-`PreInvocation`.
- Start with a broad host-model refactor: rejected as premature; discovery must
  prove the need before scope expands.

## Confirmation

Human confirmed the architecture-core lens decision and approved moving on from
this lens.
