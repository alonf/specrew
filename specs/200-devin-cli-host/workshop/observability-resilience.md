# Observability and Resilience — Feature 200

```text
Devin lifecycle event
        |
        v
Shared dispatcher
        |
        +-- expected contract --------> journal / expected output
        |
        +-- malformed payload --------> bounded drift warning
        |
        +-- handover source missing
                |
                +-- event message ----> full handover
                +-- normalized export -> full handover
                +-- unavailable ------> explicit degraded handover
```

## Existing Signals Reused

- Dispatcher structured warnings.
- Hook journal and hook-health diagnostics.
- `specrew hooks status`.
- The bounded conversation-capture fallback ladder and honest no-transcript floor.

## Real-Host Evidence

Record:

- Devin tested-build identifier.
- Operating system.
- Hook event and source path.
- Selected handover mechanism.
- Pass, degraded, or fail result.
- Bounded reason code.

Reason-code vocabulary:

- `DEVIN_PAYLOAD_MESSAGE_AVAILABLE`
- `DEVIN_EXPORT_NORMALIZED`
- `DEVIN_HANDOVER_DEFERRED`
- `DEVIN_HOOK_PAYLOAD_CHANGED`
- `DEVIN_EXPORT_SHAPE_CHANGED`

## Failure Policy

- Bootstrap or handover enrichment failure degrades visibly; durable git and Specrew
  artifacts remain authoritative.
- Boundary Stop failure blocks release.
- Unreadable user hook configuration is not overwritten.
- Generation, parity, and migration drift block CI and release.
- Config mutation and migration do not retry; they must be deterministic and idempotent.
- A live canary may retry one transient provider/network failure.
- Contract-shape mismatch is not retried; it is reported as drift.

Evidence must not contain credentials, prompts, or full conversation transcripts.
