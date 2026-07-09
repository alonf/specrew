# DevOps-Operations Lens Workshop

## Lens

- **Lens ID**: `devops-operations`
- **Depth**: light
- **Confirmation**: human-confirmed
- **Confirmation scope**: lens-question

## Deployment / Operations Topology

```text
DevOps / operations topology for Proposal 197 Iteration 001

Developer workstation / local Specrew checkout
+--------------------------------------------------------------------------+
| specrew orchestrator checkpoint loop                                     |
|                                                                          |
|  git diff / change-set                                                   |
|          |                                                               |
|          v                                                               |
|  local ReviewRequest bundle + config                                     |
|          |                                                               |
|          v                                                               |
|  provider/model selection + human authorization                          |
|          |                                                               |
|          v                                                               |
|  fresh reviewer process via host adapter                                 |
|    - claude / codex / copilot / cursor / antigravity                     |
|    - local CLI/stdout JSON contract                                      |
|          |                                                               |
|          v                                                               |
|  .specrew/review/inline/<run-id>/ durable evidence                       |
|          |                                                               |
|          v                                                               |
|  local gate validator: pass / blocked / infrastructure failure / unsafe  |
+--------------------------------------------------------------------------+

Feature branch / PR path
+----------------------+        +----------------------+        +------------------+
| feature branch       | -----> | GitHub PR to main    | -----> | protected main   |
| 197-continuous-...   |        | human review gate    |        | release truth    |
+----------------------+        +----------------------+        +------------------+
          |                              |
          |                              v
          |                     existing governance says:
          |                     - 1 human approval
          |                     - comments resolved
          |                     - Copilot review enabled
          |                     - required checks named in governance
          |
          v
Proposal 197 local validation evidence
- review contract fixtures
- provider adapter deterministic result/failure tests
- markdown/governance validation
- no direct mutation by reviewer
```

## CI/CD E2E Compatibility Path

```text
Adjusted CI/CD E2E coverage model

Local developer path
+----------------+      +----------------+      +----------------------+
| git change-set | ---> | reviewer agent | ---> | findings/gate verdict |
+----------------+      | fresh process  |      +----------------------+
                        +----------------+

CI/CD E2E proposal path
+----------------------+      +-------------------------+
| CI/CD test harness   | ---> | reviewer agent adapter  |
| deterministic setup  |      | real or controlled fake |
+----------+-----------+      +------------+------------+
           |                               |
           v                               v
+----------------------+      +-------------------------+
| ReviewRequest        |      | FindingsResult OR       |
| ReviewThread         | <--- | InfrastructureFailure   |
| GateVerdict          |      +-------------------------+
+----------------------+
```

## Agenda Raised

- What hosting model should run Proposal 197 Iteration 001?
- What infrastructure is code-owned, external, or manually configured?
- Which environments must behave equivalently, and where may provider/model availability differ?
- How are non-secret configuration, provider credentials, and dynamic authorization handled?
- What CI/CD stages, rollout strategy, rollback path, and forge-native lane are required?
- How should a downstream CI/CD E2E proposal include the reviewer agent path?
- What users, roles, service identities, and permissions are needed?

## Decisions and Agreement

Iteration 001 uses a local Specrew tool/module-command hosting model. The orchestrator runs in the developer's local checkout/session, computes a git-diff change-set, creates local review artifacts, invokes a fresh local headless reviewer process through an adapter, then gates locally. No server, daemon, queue, cloud resource, background service, or hosted reviewer worker is introduced in the first slice.

Proposal 197 owns the local review spine only: review contracts and schemas, provider adapter interfaces, static provider catalog/config references, durable review artifact writer, and local validator/test fixtures. Git, the repository checkout, PowerShell/Specrew runtime, installed AI host CLIs, provider accounts/quotas, existing GitHub branch protection, and PR review remain external prerequisites. Provider authentication, paid/external model authorization, branch-protection changes, and release/publish decisions remain human-owned or external.

Environment parity is required at the contract behavior level, not at the provider-account level. Schema validation, producer/consumer fixtures, deterministic infrastructure failures, durable artifact shape, reviewer mutation boundary, and no-silent-downgrade behavior must be equivalent. Installed reviewer CLIs, authorized models/accounts, paid-provider allowance, debug bundle preservation, and human provider/model/cost approvals may differ by environment and must surface as capability or authorization outcomes.

Configuration is explicit and non-secret. Proposal 197 may define allowed adapter names, allowed or preferred model IDs, default review effort/timeout, cost/external-provider policy, debug preservation flag, and contract schema version. Per-run authorization records the selected provider/model/cost/effort decision. Proposal 197 must not collect, store, copy, normalize, bundle, or persist provider credentials, environment variables, provider token stores, unrelated private config, raw provider transcripts, or secret values.

The CI/CD posture for Iteration 001 is local validation plus existing GitHub PR governance. No new GitHub Actions workflow, branch-protection mutation, release publishing, or automated rollout/rollback is authorized by this lens. Planning may add local tests and validators. Because this repository's governance provider is GitHub, any future forge-native CI lane for this repo would be GitHub Actions unless repository governance changes. Rollback/disable for the first slice is by configuration/not invoking the continuous review path, or reverting the PR if merged behavior must be removed.

Proposal 197 must explicitly preserve reviewer-agent contract hooks for a downstream or companion CI/CD E2E proposal. That E2E proposal should exercise the reviewer agent path end-to-end: request creation, adapter invocation, reviewer process or controlled fake, result/failure envelope, durable review artifacts, and gate verdict. Proposal 197 Iteration 001 exposes those hooks and compatibility fixtures but does not absorb CI/CD E2E implementation unless explicitly re-scoped.

No new service identity is introduced in Iteration 001. The human developer/operator runs the local command, authorizes provider/model/cost/effort, reviews durable findings and gate verdicts, and owns provider auth setup. The Specrew orchestrator may read the git diff and needed repository files, write local review request/evidence artifacts, invoke the provider adapter safely, and enforce timeout/schema/gate behavior. The fresh reviewer process may read the authorized bundle/repo context and emit stdout JSON findings/failures, but must not edit source, stage commits, push, or mutate Specrew state. Any CI/CD service identity or harness belongs to the downstream CI/CD E2E proposal.
