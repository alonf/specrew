# Plan: Validator Repetition Detector

**Spec**: [spec.md](spec.md)
**Proposal**: [Proposal 086 Pillar 5](../../proposals/086-validation-pipeline-performance-bundle.md)
**Created**: 2026-05-22
**Status**: Approved

## Approach

Add a lightweight invocation log + repetition detector to the validator entry. On 3rd consecutive identical invocation against unchanged code+content, emit a diagnostic warning. Composes with Proposal 086 P1 (memoization): cache serves the repetitions cheaply; detector flags the redundancy.

### Phase 1 — Helpers in shared-governance.ps1

1. `Add-SpecrewCommandInvocation` — JSONL append to `.specrew/.cache/last-commands.log`, file-locked, FIFO eviction at 20.
2. `Get-SpecrewRecentCommandInvocations` — reads the log; returns the most recent N entries.
3. `Test-SpecrewCommandRepetition` — counts consecutive entries matching `(target_hash, code_hash)`.

### Phase 2 — Validator integration

1. At the start of `validate-governance.ps1` main flow (after parameter parsing, before scope determination): compute target hash + code hash, call `Test-SpecrewCommandRepetition`, emit warning if count >= 2, then call `Add-SpecrewCommandInvocation`.
2. Wrap in try/catch; swallow any failure so the detector never blocks validation.

### Phase 3 — Tests + sign-off

1. Integration tests at `tests/integration/validator-repetition-detector.tests.ps1` covering helpers, FIFO, repetition counting, corrupt-log resilience.
2. CHANGELOG entry; INDEX update; proposal status update (Pillar 5 shipped, others remain candidate).

## Risk + Mitigation

| Risk | Mitigation |
|---|---|
| Detector failure breaks validation | Wrap entire detector logic in try/catch; never propagate |
| Log file race conditions across parallel subprocesses | `Invoke-WithFileLock` serializes append |
| False positives flag legitimate repeat | Streak resets when ANY hash changes; 2-prior threshold means real intent |
| Log grows unbounded | FIFO eviction at 20 entries |

## Composition with Other Proposals

- **Proposal 086 P1 (memoization)**: orthogonal. Cache makes repetitions cheap (~1ms each); detector flags them as worth questioning.
- **Proposal 078 (Handoff Conversation Quality)**: warning text becomes part of the Crew's "what I just did / why I stopped" preamble.
- **Proposal 045 (CI Watchdog)**: P5 is the local-side complement to 045's CI-side detector.

## Out of Scope (explicit deferral)

- Pillars 2, 3, 4 (deferred to future feature; this PR ships only Pillar 5)
- Auto-suggesting `-NoCacheRead` based on detection
- Cross-CI repetition tracking
