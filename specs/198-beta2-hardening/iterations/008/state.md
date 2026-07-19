# Iteration State: 008

**Schema**: v1
**Current Phase**: before-implement
**Iteration Status**: executing
**Last Completed Task**: T070 host-independent conformance turn-delta core and supported-host adapters
**Tasks Remaining**: T066, separately authorized T029, and T067
**In Progress**: T066 correction and deterministic candidate preparation (no fresh provider grant)
**Baseline Ref**: 364fbe88ef29cce5ac74d8086c1d78d8b8363197
**Updated**: 2026-07-19T14:54:10Z

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

## Full-Scope T070 Authorization

- **Authorization**: reprice T070 honestly and complete the full scope with no SP ceiling before T066
  re-preparation; stop only for non-convergence or a genuine architectural surprise.
- **Estimate**: 4.0 SP. Iteration capacity becomes 22/26 SP with 4 SP headroom.
- **Architecture**: one host-independent core owns the live owner-scoped baseline, status/content fingerprints,
  delta, and packet-demand decision. Host adapters supply only genuine prompt-boundary events.
- **Host scope**: Claude/Codex `UserPromptSubmit`, Copilot `userPromptSubmitted`, Cursor `beforeSubmitPrompt`, and
  Antigravity `PreInvocation`; a proven capability-absent future host uses the explicit degraded contract.
- **Required evidence**: stale-handover read-only, consecutive turns, same-path re-edit, concurrent sessions,
  production host registrations, and honest degraded display.
- **Provider effect**: the earlier exact grant raced with the subsequent read-only investigation request and was
  invoked once. Its valid incomplete result is retained in the attempt ledger; no replacement grant exists.

## Readiness Summary

- **Plan/capacity**: 22/26 story_points; 18 tasks; 4 SP headroom. Historical +17% variance forecasts about
  25.7 SP, still below capacity.
- **Traceability**: PASS; 18/18 tasks have valid selected refs and metadata, 32/32 selected requirements have
  coverage, and no task/progress mismatch exists.
- **Hardening**: planning-time `Overall Verdict: ready`; the exact before-implement verdict is captured. Runtime
  evidence remains task-owned.
- **Plan-boundary verification**: scoped governance and markdownlint passed; cross-platform CI run `29659141998`
  completed successfully at plan commit `08e86496`.
- **Team/sequence**: one serial Implementer; T068 then T069 before supplier/distribution work; T066 is the
  independent Reviewer boundary.
- **Provider budget**: one exact Claude slot was granted and spent by
  `run-t066-claude-windows-8daac538-e03a4139-01`; no fresh slot is granted. Every correction rerun requires
  separate human authorization, a new run ID, and no hidden retry.
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
- T023 reduces the consumer template directory and module FileList to exactly the methodology and work-kind
  workflows; Specrew's CI, confidence, and project-sync lanes remain only under `.github/workflows`. The package
  manifest now also declares the previously omitted hooks-doctor and T060 operator scripts, closing the release
  completeness failure surfaced during T021. Source/manifest/real-deploy allowlist tests, all adjacent workflow
  suites, the bidirectional 390-entry FileList guard, and packaged-artifact deploy checks pass.
- T024 classifies `.claude/settings.local.json` as machine-local per-session state. The real init ordering writes
  its ignore rule before hook deployment; a Git-backed fixture proves an already-tracked config is removed only
  from the index, preserved on disk, ignored thereafter, and not duplicated on repeated init. The adjacent
  Feature 051 classification suite remains green with the expanded canonical pattern set.
- T025 points update inventory at the packaged consumer template roots. Retired files are removed only when the
  exact previous-source SHA-256 still matches the consumer bytes; modified files remain untouched and produce a
  named warning plus `.deletion` review artifact. The extension deploy now treats `refocus-scopes.json` as a
  required managed item, with the existing user overlay reapplied after refresh. The beta1-shaped production-path
  fixture, missing-source and registration fixtures, and the 390-entry package completeness guard pass. The broad
  provider-mirror test also exposed an older committed bootstrap-provider comment/newline mismatch outside T025;
  it remains visible for the T065/T066 quality sweep instead of being hidden in this task.
- T026 classifies a project from its pre-mutation content and Git history. A genuinely greenfield init creates and
  announces `chore(specrew): bootstrap scaffold`, commits its automatic-baseline record, and ends clean; a missing
  Git identity uses a command-scoped fallback without changing user configuration. Brownfield init never creates
  history and writes a structured offered/declined record instead, with an explicit CLI decline surface. Real-Git
  fixtures prove the exact subject, clean greenfield state, no brownfield HEAD movement, durable decline, dry-run
  non-mutation, production wiring, and adjacent local-host/file-list behavior.
- T027 records one closed release model in repository governance, preferring an existing record and otherwise
  resolving explicit init selection, publish target, configured forge, generic remote, then local-only. The launch
  contract renders model-specific agent/human actions plus named N/A reasons; only `beta-stable` receives the
  prerelease-to-stable chain. Local, push, PR, publish-target, invalid, dry-run, quote, record-once, schema, production
  wiring, lifecycle, and seven mirrored-surface fixture groups pass, as do the updated legacy closeout and launch
  contract suites. The broad changed-only governance run exceeded its 120-second local bound without output; T066
  retains the bounded full-governance obligation rather than treating that timeout as a pass.
- T028 extends the single shipped deny-list with `stack-assumption` and `delivery-assumption` while requiring
  exactly one closed-set applicability marker for those classes; the older self-reference escape cannot suppress
  them. The same data file now deploys with the extension and drives both the provider-gated methodology advisory
  and update's post-refresh, flag-only consumer check. Refocus distinguishes the governed project from the tool,
  platform-specific launch guidance is rendered only after platform detection, and hard-coded self paths and
  unconditional delivery instructions were removed from consumer teaching. Paired lint/consumer/update fixtures,
  package deployment, release-model, forge-neutralization, launch-contract parity, and a 38-surface runtime render
  covering reviewer rounds, navigator notes, boundary scaffolding, lifecycle templates, Python/pytest, GitLab, and
  local-only delivery all pass. PSScriptAnalyzer was unavailable locally; T066 retains that CI obligation.
- T065 adds a ten-case production-path downstream project matrix. Explicit config, package metadata, a selected
  quality profile, an active provider, mixed Python/.NET/Node-shaped content, and a repository-relative working
  directory all materialize through the real supplier and reach the T018 runner, durable recorder, exact-digest
  join, and campaign harness in declared order. No-source, malformed explicit, and escaping-path projects stop
  before harness preflight, command execution, or spend; a three-command pass/fail/pass plan records every attempt
  and forces an optimistic reviewer result incomplete. The consolidated supplier/contract/runner/recorder/campaign
  set passed 114/116 with two intentional platform skips in 170.9 seconds. The preceding T028 CI run
  `29666586025` exposed an older Windows fixture that returned to its divergent branch via `git checkout -`; the
  fixture now records its actual base branch and asserts non-ancestry before exercising the production guard.
- Initial T066 deterministic preparation was green at the T065 commit: all 72 explicitly registered Feature 198 suites
  passed locally in 998.6 seconds; the explicit Iteration 008 governance validator passed in 18.0 seconds with
  historical warnings only; and hosted Windows/Linux/macOS run `29666927862` passed every job at commit
  `b97dd63370faa687e39ae224b93b938ebb7e20df`. The scoped validator first rejected descriptive runtime-evidence
  status tokens, so the three affected hardening rows now use its exact closed value `recorded`. That documentation
  correction was part of the first independent-review candidate; no release action occurred.
- T066 attempt 01 invoked Claude once as
  `run-t066-claude-windows-8daac538-e03a4139-01` against commit `8daac53888f29c47cab0c23531e9fbf53ec38729`
  and digest `e03a413985002981933eccdbcd7b25c5b6c6df96`. The valid incomplete result reported two blocking command
  failures and one major evidence-honesty finding: the project plan omitted the `env_refs` needed by the
  production runner's empty child environment, so the registry could not create a temp file and governance could
  not resolve Git. The slot is spent; the result cannot approve the candidate.
- T070 completed at its honest 4.0 SP estimate under the no-ceiling full-scope authorization after a read-only
  session was falsely charged for eight absolute dirty files. One host-independent live-Git core owns baseline,
  status/content fingerprints, delta, and packet demand; thin manifests map all five supported prompt events.
  SessionStart-only operation is explicitly degraded and never says `this turn`. Focused core/provider/host suites,
  mirror/package checks, and all 73 registered Feature 198 suites passed in 740.4 seconds. Exact-commit hosted run
  `29691361750` passed every Windows, Ubuntu, and macOS job at commit `dbbabcd9ff6fdb6fa2f453df9df485c4594ba576`.
- T066 correction now versions the self-review plan as `f198.i008.signoff.v4`, explicitly allows only the ambient
  variable names required by its tools (`PATH`/Windows application and process-launch state, temp paths, PowerShell
  module/home paths), and adds paired
  production-runner evidence: the declared environment succeeds and the same probe without declarations fails.
  The exact full plan must pass through the production runner before a replacement provider slot is requested.
- Iteration 008 combines the FR-048/FR-049/SC-015 production supplier/injection slice with the never-opened
  Iteration 004 distribution/release tail because the combined 15 SP core fits the 26 SP cap.
- T070 is complete. T066 is correcting the first review findings and will receive a new committed candidate and
  deterministic preparation record; provider invocation still requires a fresh explicit grant against that exact
  commit/digest/run ID.

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
