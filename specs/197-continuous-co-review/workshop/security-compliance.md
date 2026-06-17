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
