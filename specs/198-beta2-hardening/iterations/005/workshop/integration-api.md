# Integration and API reassessment

**Status**: complete
**Iteration**: 005

## Confirmed integration style

The review subsystem uses a local synchronous CLI, process, and file contract. Beta2 introduces no network API, queue, daemon, webhook, streaming protocol, or background scheduler.

```text
Implementer / CLI
        |
        | review request; caller waits
        v
Campaign Controller
        |
        | creates unique run + frozen external worktree
        v
Harness Adapter --------------------+
        |                            |
        | native CLI invocation      | OS runtime control
        | stable environment mapping | Job Object / cgroup
        v                            |
External Reviewer <-----------------+
        |
        | candidate output
        v
Run Staging Directory
  candidate-result.json
  candidate-report.md
        |
        | schema + identity + completeness validation
        v
Authoritative Run Repository
  result.json
  validation.json
  report.md
```

The reviewer never writes authoritative repository facts directly. It writes candidate output into its unique staging area, or the adapter materializes candidate files from captured standard output. Only the controller validates and publishes authoritative facts.

## Common adapter contract

Every harness adapter accepts the same versioned logical request:

```text
ReviewInvocation
  schema_version
  campaign_id
  run_id
  target_digest
  snapshot_path
  review_scope
  prompt_path
  candidate_result_path
  candidate_report_path
  deadline
```

The adapter translates this request into the harness-native command line. Prompt delivery uses the most stable conformance-proven mechanism for that harness: standard input, a bounded prompt file, or a native prompt flag.

The candidate machine result has a closed, bounded schema:

```text
ReviewerResult
  schema_version
  run_id
  target_digest
  completion: complete | partial
  verdict: approved | changes-requested | incomplete
  runtime_outcome
  termination_verified
  summary
  findings[]
    finding_id
    severity
    title
    description
    evidence[]
    recommendation
```

`finding_id` identifies a finding within one run. The controller assigns cross-run finding lineage; different AI harnesses are not expected to reproduce a shared identifier for the same issue.

Every invoked run publishes one terminal authoritative `result.json`. For a timeout or other post-invocation failure, the controller generates the result after the process tree is terminated and output streams are closed. The result uses `completion: partial`, `verdict: incomplete`, the controller-owned `runtime_outcome`, termination evidence, and any bounded partial findings that validate. This lets consumers understand failure without inferring it from an absent result file.

## Controller-owned runtime outcomes

The controller classifies outcomes because a killed or failed reviewer cannot reliably describe its own failure:

```text
completed
preflight-failed
launch-failed
timed-out
terminated
invalid-output
identity-mismatch
containment-violated
```

- The public CLI call waits until the run reaches a terminal state or its deadline.
- OS containment supervises the process tree and enforces the deadline.
- An adapter never retries secretly. Every additional provider invocation has a new `run_id` and reserves another already-authorized allowance slot.
- Authentication comes from existing conformance-backed harness configuration. Credentials are not fields in the contract and are not persisted in run records.
- The request and result contracts are versioned by `schema_version`; each adapter declares its supported contract versions.
- Observed harness version is recorded as evidence. Version-specific behavior stays in its adapter or the existing reviewer-host catalog rather than branching the controller core.
- Unsupported contract versions, malformed outputs, unknown required fields, and identity mismatches fail closed with visible diagnostic outcomes.

## Confirmed five-harness completeness bar

The shared contract must be implemented and proven for every reviewer harness Specrew currently claims to support, not merely demonstrated by one reference adapter:

```text
Common Review Contract
       |
       +-- Claude adapter ------ real smoke + contract fixtures
       +-- Codex adapter ------- real smoke + contract fixtures
       +-- Copilot adapter ----- real smoke + contract fixtures
       +-- Cursor adapter ------ real smoke + contract fixtures
       +-- Antigravity adapter - real smoke + contract fixtures
```

| Harness | Executable |
|---|---|
| Claude Code | `claude` |
| Codex CLI | `codex` |
| GitHub Copilot CLI | `copilot` |
| Cursor Agent | `cursor-agent` |
| Antigravity | `agy` |

Each adapter must prove native launch translation, stable environment mapping, prompt delivery without Specrew skills or hooks, bounded JSON plus Markdown output, timeout and process-tree termination, and partial-output preservation.

Completion requires two complementary evidence layers:

1. One minimal bounded real-CLI review smoke per supported harness proves that an installed and authenticated harness can review a frozen snapshot and return valid outputs.
2. A shared deterministic executable-fixture suite covers timeout, malformed output, wrong run identity, unsupported schema, interruption, and termination without repeatedly spending AI tokens.

If a claimed harness is unavailable, unauthenticated, or incompatible and cannot complete its real smoke, that harness and the overall five-harness completeness criterion remain honestly unproven. Constructing a command line or passing only a mock test is insufficient.

## Human agreement

The maintainer confirmed the local synchronous process/file contract, controller-owned validation and runtime classification, controller-owned cross-run finding lineage, visible separate retries, conformance-backed existing authentication, versioned compatibility rules, and real implementations plus bounded live proof for all five supported harnesses before this lens was closed.
