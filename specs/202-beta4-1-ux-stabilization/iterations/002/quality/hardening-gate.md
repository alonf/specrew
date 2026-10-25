# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/202-beta4-1-ux-stabilization/spec.md`
**Iteration Ref**: `specs/202-beta4-1-ux-stabilization/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner (Claude), planning-time analysis; the codex co-review covers the lenses at implement
**Reviewed At**: 2026-10-17T04:30:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | One human message gives at most one recorded approval of each kind, keyed by the host's message ID, never by the path that saw it (T017, SC-010). A hook stands down only on a positive match with another host's declared fields, so no host records under another's label, and an unknown shape is never silently ignored (T016). Nothing inside a paired paste and no quoted menu is an approval (T018). A spent approval from the same message is final. The receipt store refuses a duplicate ID. The append-only ledger is never rewritten; B4F-127's spare copies already in it stay as history. No new dependencies. | `true` | Iteration 002's whole scope is the trust boundary between a human act and the authority stores. B4F-127 (one approval recorded twice, the spare spendable) and B4F-129 (a second host's hooks recording the same acts) are the release gate. A false or doubled authorization is indistinguishable from a real one once written, so every control is proven from recorded payloads through the deployed hook command. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Failure modes: a payload matching no known host (handled as today, logged once); an approval-shaped Copilot message the prompt hook missed (journal row plus one visible line); a quoted menu (refused, named); a narrow delegation with lenses pending (one line naming the wide phrase); a transcript entry without `prompt_id` (not recorded on the turn-end path, disclosed). Each mode has a positive and a negative test. | `true` | The maintainer's design rule for iteration 002: no human act is dropped without a trace. Every path that declines to record says so once, in project terms, and the technical cause goes to the journal. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Idempotency is the iteration's mechanism: approvals keyed by message ID (first path wins, the second is a no-op); receipt IDs unique; the receipt outcome kept per session turn record so two sessions cannot read each other's (R5-5 test, T022). The retired journal is deleted once by `specrew update`, and a second update finds nothing to delete. | `true` | Two recording paths and two hosts' hooks observing one act are the iteration's defects; an idempotent key per act is the fix. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Each task maps its FR to named tests (tasks.md iteration 002): T017 message identity with a per-host replay (SC-010); T016 a fixture matrix of every recorded payload against every host's deployed command; T022 the R5-5 two-session test; T018 the B4F-125 live messages, a quoted closing tag, a quoted menu, and the observed paste-size boundary; T019 B4F-128's two lines; T020 wide, narrow and mixed lenses; T021 a text test over every shipped instruction. RED first through the shipped entry point. Synthetic fixtures stay marked as such and never count as recorded-host evidence. SC-011 is proven live by the maintainer's Copilot re-walk (T024). | `true` | Iteration 001's retro found 8 cases where a test went around the real path; every iteration-002 test drives the deployed command or the real script. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The log-once line for an unknown payload shape and the Copilot unrecorded-approval line are the operability surface; `specrew update` reports the journal deletion. No CI workflow change is planned. | `false` | 202 ships no server or on-call surface; its operability is local visibility of what the hooks did and did not record. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/202-beta4-1-ux-stabilization/iterations/002/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/202-beta4-1-ux-stabilization/iterations/002/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/202-beta4-1-ux-stabilization/iterations/002/quality/lenses/test-integrity.md` |

## Notes

- This is a planning-time artifact. Runtime evidence is collected after implementation in the planned evidence paths.
- Design source: `iterations/002/design-analysis.md` (DA-1 to DA-5, each with the maintainer's changes), including the
  finding that Claude Code tags only long pastes.
