# Security-Compliance Lens Workshop

## Lens

- **Lens ID**: `security-compliance`
- **Depth**: medium
- **Confirmation**: human-confirmed
- **Confirmation scope**: lens-question

## Trust Boundary Diagram

```text
+--------------------------- trusted read path ----------------------------+
|                                                                         |
|  +----------------------+      repo context as needed      +---------+  |
|  | Specrew Orchestrator |---------------------------------->| Reviewer|  |
|  | trusted coordinator  |                                   | Process |  |
|  +----------+-----------+<----------------------------------+----+----+  |
|             |         stdout JSON findings/provenance only       |       |
|             |                                                    |       |
|             | durable evidence, redacted                         | read  |
|             v                                                    v       |
|  +------------------------------+          +--------------------------+  |
|  | .specrew/review/inline/run-id|          | Repository working tree  |  |
|  | findings/provenance/audit    |          | trusted review context   |  |
|  +------------------------------+          +--------------------------+  |
|                                                                         |
+-------------------------------------------------------------------------+
```

## Agenda Raised

- What repository or bundle context may a trusted reviewer inspect?
- What ambient machine state and sensitive data must never be deliberately packaged or persisted?
- What authority does the reviewer process have over source files, Specrew state, and Git state?
- What provider/model authorization is required before reviewer invocation?
- What command-construction and malformed-output controls are required for provider adapters?
- What audit metadata is enough for Iteration 001 without leaking secrets?

## Decisions and Agreement

The reviewer is a trusted component, not an adversary. Iteration 001 must not artificially blind the reviewer from repository context needed to do a high-quality design-conformance review. The security boundary is therefore not "hide normal repo context"; it is "do not package or persist ambient secrets or private machine state, and do not allow the reviewer to mutate the project."

Agreed controls:

- The reviewer may inspect repository context needed for correct review, including source files and design/spec context relevant to the change-set.
- Review bundles and durable artifacts must never deliberately include environment variables, credentials, access tokens, token stores, local private config, unrelated temp files, raw prompts, raw provider transcripts, or secret values.
- If a finding involves sensitive text, persisted evidence references the location and redacts the secret value.
- The reviewer may read needed repo context and call its configured provider/model, but may not directly edit source files, stage commits, push branches, or mutate Specrew state.
- Provider/model invocation is limited to allowed project or run configuration; non-default, paid, external, or newly added providers require explicit human authorization before use.
- Durable review artifacts may include findings, traceability IDs, provider/model/run metadata, status, bounded snippets needed to explain findings, and audit/provenance metadata.
- Provider adapters must invoke CLIs with structured argument arrays or equivalent safe invocation APIs rather than concatenating untrusted shell strings.
- Run IDs and paths are generated or normalized by Specrew.
- Timeout, nonzero exit, empty output, invalid JSON, malformed schema, or unknown blocking state deterministically blocks the run instead of being treated as a clean review.

## Audit Record Requirements

Each review run should record:

- run ID
- target change-set or checkpoint baseline
- reviewed requirement/task/design references
- provider and model actually invoked
- start and end timestamps
- exit/failure classification
- findings count
- fix-verification round number
- durable artifact paths

The audit record must not record secret values, raw ambient machine state, or full raw provider transcripts.

## Out of Scope for Iteration 001

- OS-level sandboxing or hard filesystem isolation.
- Treating the reviewer as hostile.
- Dynamic provider plugin loading.
- Persisting full raw prompts or provider transcripts for audit.
- Allowing reviewer-authored source edits as part of the review run.

## Iteration 002 Send-Back Addendum: Reviewer Definition Trust Boundary

The review send-back tightens the security/compliance lens around the actual
reviewer-definition delivery path. The reviewer remains trusted for bounded read
access, but the execution path must prove that the canonical reviewer instruction,
visibility policy, do-policy, design context, round context, and prior findings
were injected before any host adapter invokes a model.

```text
Reviewer-definition security boundary

                         trusted Specrew-controlled inputs
+----------------------------------------------------------------------------------+
|                                                                                  |
|  +----------------------+      load canonical text       +----------------------+ |
|  | code-review-agent.md |------------------------------->| Instruction Source   | |
|  | Specrew-owned file   | source path + content hash     | no host invocation   | |
|  +----------------------+                                +----------+-----------+ |
|                                                                     |             |
|                                                                     v             |
|  +----------------------+      structured request         +----------------------+ |
|  | Design Context       |------------------------------->| ReviewRequest.v2     | |
|  | Diff / Change-set    |                                | visibility/do policy | |
|  | Prior Findings       |                                +----------+-----------+ |
|  +----------------------+                                           |             |
|                                                                     v             |
|                                                        +----------------------+  |
|                                                        | Prompt Composer      |  |
|                                                        | injects reviewer     |  |
|                                                        | definition + policy  |  |
|                                                        +----------+-----------+  |
|                                                                   |              |
+-------------------------------------------------------------------|--------------+
                                                                    |
                                                                    v
                                                        +----------------------+
                                                        | Host Adapter Edge    |
                                                        | Claude/Codex/etc.    |
                                                        | transport + flags    |
                                                        +----------+-----------+
                                                                   |
                        isolated disposable review workspace        |
+-------------------------------------------------------------------|--------------+
|                                                                  v               |
|  +----------------------+   pre baseline     +----------------------+            |
|  | Mutation Guard       |------------------->| Reviewer Process     |            |
|  | pre/post compare     |                    | may read review ctx   |            |
|  +----------+-----------+<-------------------| must not mutate       |            |
|             | post baseline / mutation diff  +----------------------+            |
|             v                                                                    |
|  +----------------------+       orchestrator-owned durable writes                 |
|  | Invalid execution if |-----------------------------------------------------+  |
|  | mutation detected    |                                                     |  |
|  +----------------------+                                                     |  |
+-------------------------------------------------------------------------------|--+
                                                                                v
                                                                  +----------------------+
                                                                  | Redacted evidence    |
                                                                  | findings/gate/audit  |
                                                                  | no raw secrets       |
                                                                  +----------------------+
```

### Send-Back Decisions

- **Visibility policy**: The reviewer may read supplied `ReviewRequest.v2`
  content, the exact diff/change-set, prior findings, design context content,
  and bounded repository context needed to validate the changed surface. The
  reviewer must not inspect or persist ambient secrets, token stores, environment
  variables, unrelated local config, or private machine state.
- **Do-policy**: The reviewer is review-only. It may analyze and emit exactly one
  `FindingsResult.v1` object. It must not modify, create, delete, format, or
  stage files; commit, push, or switch branches; mutate Specrew state; run
  repair tools, generators, installers, or migrations; or emit alternate output
  schemas.
- **Host read-only enforcement**: Adapters pass native read-only,
  permission-deny, sandbox, no-write, or equivalent flags where supported. Lack
  of native support is recorded as capability metadata, not hidden. Native flags
  are defense-in-depth; the mandatory mutation guard is the uniform enforcement
  layer.
- **Mutation guard**: Review runs in an isolated disposable workspace. Pre/post
  validation detects source, spec, state, and Git mutations. Any mutation
  invalidates the review execution and blocks the gate. Mutation evidence records
  paths and classification only; changes are never copied back or treated as
  fixes. A narrow explicit allowlist is permitted only for harmless host
  byproducts.
- **Redaction and audit**: Real runs persist hashes, versions, source references,
  run metadata, gate verdicts, failure classifications, and mutation status, not
  raw prompts, raw provider transcripts, environment variables, tokens, token
  stores, credentials, private local config, or secret values. Deterministic
  fixture tests may capture sanitized composed prompts to prove the real prompt
  path includes the Proposal 145 rubric, design context, round number, and prior
  findings.
- **Adapter safety**: Host adapters receive a complete composed prompt and remain
  transport-only. They use safe argv or equivalent invocation, apply timeouts and
  read-only flags where available, and report deterministic
  `InfrastructureFailure.v1` for unavailable, unsupported, or malformed host
  execution. Adapters do not own rubric text, policy wording, prior-finding
  semantics, durable writes, or gate verdicts.

### Done Interpretation

A reviewer-definition run is security-acceptable only when the actual outbound
host path carries the canonical reviewer instruction and policy, the reviewer is
constrained to read-only analysis, durable artifacts avoid raw secrets and raw
transcripts, and any reviewer mutation in the disposable workspace invalidates
the run instead of being treated as a fix.
