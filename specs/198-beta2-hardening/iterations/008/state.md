# Iteration State: 008

**Schema**: v1
**Current Phase**: before-implement
**Iteration Status**: executing
**Last Completed Task**: T022 work-kind template deployed-path correction
**Tasks Remaining**: T023–T028, T065, T066, separately authorized T029, and T067
**In Progress**: T023 deny-by-default consumer deploy-list surgery
**Baseline Ref**: 364fbe88ef29cce5ac74d8086c1d78d8b8363197
**Updated**: 2026-07-18T22:54:15Z

## Planning Authorization

- The human authorized planning only, explicitly bound to the actual Iteration 007 closeout commit
  `ec2287c0b950ceb78522f3b5aae8dd94d4710a88`.
- The pending record's citation of `744e77d8` / tree `542c54f0` is stale, is tracked as
  `DRIFT-198-I008-001`, and carries no authority.
- Task authoring was separately authorized from plan commit `08e86496f2475bb970ff1eafeedf3d58ee897a53`.
  At that boundary, implementation, provider invocation, and release action remained unauthorized.
- Selected capacity is 18/26 SP. T068 (0.75 SP) and T069 (2.25 SP) are included and execute first.
- Proposal 209 remains separately scheduled.

## Fresh Tasks Verdict

- **Verdict**: `approved for tasks — include T068 and T069`
- **Authorized plan**: `08e86496f2475bb970ff1eafeedf3d58ee897a53`
- **Scope**: author task/readiness artifacts for the 18 SP selection; do not implement.
- **Sequence**: T068 then T069, before every supplier/distribution task, so later boundaries dogfood them.
- **T069 ceiling**: 2.25 SP is hard. Any larger correction stops for human replan instead of swelling the release
  slice.
- **Required T069 evidence**: multi-session and injected-context fixtures reproduce DRIFT-198-I007-025, shared
  material-baseline attribution, and stale-binding-class behavior; instruction-bearing approval remains complete.
- **Release boundaries**: T029 still needs its own explicit release grant; T067 validates published beta and does
  not promote stable.
- **Separate work**: Proposal 209 remains independently scheduled.

## Before-Implement Verdict

- **Verdict**: `approved for before-implement`
- **Authorized task commit**: `364fbe88ef29cce5ac74d8086c1d78d8b8363197`
- **Authorized Git tree**: `1e5cf50256303efc81d6282315d1818ff2eebae4`
- **Capture evidence**: hook-captured ledger entry `auth-18b9c1d0569aa911cd6a7bc3f73587524c83f0b6f2fbd431c4711a49f3dcaf9a`
  records `tasks -> before-implement` at the exact commit. The preceding null-pending sync result remains repair
  evidence, not authority.
- **Scope**: execute the selected 18 SP implementation in order. This verdict grants no provider invocation,
  beta publication, or stable promotion.

## Readiness Summary

- **Plan/capacity**: 18/26 story_points; 17 tasks; 8 SP headroom. Historical +17% variance forecasts about
  21.1 SP, still below capacity.
- **Traceability**: PASS; 17/17 tasks have valid selected refs and metadata, 32/32 selected requirements have
  coverage, and no task/progress mismatch exists.
- **Hardening**: planning-time `Overall Verdict: ready`; the exact before-implement verdict is captured. Runtime
  evidence remains task-owned.
- **Plan-boundary verification**: scoped governance and markdownlint passed; cross-platform CI run `29659141998`
  completed successfully at plan commit `08e86496`.
- **Team/sequence**: one serial Implementer; T068 then T069 before supplier/distribution work; T066 is the
  independent Reviewer boundary.
- **Provider budget**: zero slots granted. T066 and every correction rerun require separate human authorization,
  a new run ID, and no hidden retry.
- **Release**: T029 has a separate release gate; T067 validates published beta without stable promotion.
- **Authorization**: implementation is authorized against task commit `364fbe88`; provider and release actions
  remain separately gated.
- **Live sync containment**: canonical sync at task commit `29cf84084fd65da9f4199466a9aa4dccc5105958`
  returned success with `pending_verdict_has_pending: false` and null pending identity despite the open
  `tasks -> before-implement` crossing. This is recorded under DRIFT-198-I008-001 and grants no authority.

## Execution Summary

- T068 is implemented: stale supplied boundary commits fail before state mutation, while an already-authorized
  completed boundary opens its next crossing at current `HEAD` and the corresponding Git tree.
- T069 is implemented within its 2.25 SP ceiling: injected `<environment_context>` turns are non-authoritative,
  instruction-bearing approvals retain their complete instruction through the real writer path, genuine host
  sessions receive owner-scoped material state, and a fresh exact-surface owner record prevents cross-session
  billing without weakening same-session packet enforcement.
- T069 focused/neighbor suites passed, HookRenderDedupe passed serially, and all 60 registered Feature 198 suites
  passed in 788.5 seconds; commit `9ef3b137` then passed three-OS CI run `29662556573`. No provider slot or release
  authority was used.
- T062 is implemented as one ordered selector over normalized named sources. The closed versioned catalog ships
  one unambiguous `package.json#scripts.test` detector and the existing explicit Node/React/Python/.NET quality
  profiles; its provider row set is deliberately empty by default rather than inventing an unbound provider
  command. Fourteen supplier pairs plus the adjacent T018 contract/runner matrix (70 passing, 2 platform skips)
  prove strict precedence, explicit-invalid short circuit, extension/inactive-provider refusal, stable identities,
  schema-valid output, actionable no-source behavior, and secret-safe provenance.
- T063 wires the selector into both real init and update callers. A hash sidecar distinguishes generated content
  from explicit project-owned configuration: explicit valid or invalid plans are preserved byte-for-byte; only a
  hash-matching generated plan may refresh or be removed when its source disappears; any project modification
  warns and survives. Eleven focused fixtures, 61/62 supplier/materializer/contract cases (one platform skip),
  package import/deploy, FileList parity, and update-resync passed. The older local Spec Kit 0.8.13 blocked the
  legacy packaged-init fixture at its pre-existing minimum-version gate before T063 ran; committed three-OS init
  CI run `29663339974` passed at commit `7e8d9df1` as the production-path confirmation.
- T064 freezes the selected plan's exact bytes alongside the external code snapshot and includes that hash in
  currentness because `.specrew/**` intentionally remains outside the canonical code digest. The existing T018
  runner executes before provider launch; every record must join on the frozen digest plus a unique declared
  command ID before one bounded `.review/implementer-evidence.json` copy reaches the reviewer. Missing/invalid
  plans and source mutation release the reservation without spend; configured failures remain injected and force
  the terminal result incomplete. Seven production-path fixtures and 163/165 adjacent cases (two platform skips)
  passed, including origin HEAD/status preservation, exact-once order, stale/unjoinable refusal, and plan drift.
- T021 adds the generic advisory methodology workflow with the F-033 Markdown ignore set, a full deployed-path
  governance run, conditional PSScriptAnalyzer, major-pinned actions, and provider-aware init deployment. Scratch
  projects prove GitHub and unset providers receive it, while explicit non-GitHub providers receive no Actions
  workflows and an actionable manual-validator command. The focused contract/deploy suite, packaged-artifact
  checks, and Markdown lint passed; the broader FileList completeness check still reports four pre-existing T060
  root scripts outside the manifest, which T021 did not alter and the deny-by-default distribution slice will
  reconcile rather than hiding here.
- T022 removes the work-kind workflow's repository-source fallback. Consumer execution now resolves only the
  shipped `.specify/extensions/.../work-kind-validator.ps1` path, while a missing deployed validator remains an
  explicit advisory warning and `MODE: advisory` remains the default. The existing deployed-shape behavioral
  suite was updated to prove deployed-only, hybrid, source-only, and absent layouts through the new contract.
- Iteration 008 combines the FR-048/FR-049/SC-015 production supplier/injection slice with the never-opened
  Iteration 004 distribution/release tail because the combined 15 SP core fits the 26 SP cap.
- T023 executes next to reduce the consumer workflow package to the methodology and work-kind allowlist while
  preserving Specrew's self-host workflows only in its repository CI surface.

## Notes

- T068 retains the stale record and null-pending sync as regression evidence; neither is authority. New boundary
  syncs must bind current `HEAD` and its Git tree or fail before state mutation.
- Planned execution order is T068 → T069 → T062 → T063 → T064 → T021–T028 → T065 → T066 → separately
  authorized T029 → T067.
- Update this file after each authorized task completes and keep identifiers aligned to plan.md.

<!-- >>> specrew-managed escalation-state >>> -->
## Repair Escalation

- **Status**: inactive
- **Artifact**: (none)
- **Gate**: (none)
- **Failure Count**: 0
- **Current Tier**: efficiency
- **Current Owner**: (none)
- **Locked Out Agents**: (none)
- **Last Escalated**: (none)
- **Resolved At**: (none)
- **Notes**: (none)
<!-- <<< specrew-managed escalation-state <<< -->
