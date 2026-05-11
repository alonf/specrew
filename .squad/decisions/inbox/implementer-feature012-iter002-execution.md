# Implementer Decision Inbox: Feature 012 iteration 002 execution

## Decision

For feature 012, descriptive references in handoffs, iteration 002, the replay proof uses fixture-backed invocations of `extensions\specrew-speckit\validators\handoff-governance-validator.ps1` as the real governance review path, and the new tests assert on the validator's user-visible `status`, `findings`, and `summary` output instead of checking runtime state alone.

## Why

The signed iteration hardening gate called out replay-path integrity as a blocking concern, and the active known-traps corpus already requires user-facing handoff coverage to exercise the actual replay surface. Encoding the replay path in fixture manifests also makes the proof auditable in feature-level quality artifacts and keeps the lane aligned with the seeded corpus row.
