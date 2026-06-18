# Code-Implementation Lens

## Lens Decision

Use the current Specrew implementation as the source of code-rules truth for
Proposal 197. No external coding guideline or example project is ingested for
this feature.

## Visible Workshop Flow

```text
Current Specrew patterns
      |
      v
implementation-rules.yml
      |
      +--> Baseline craft defaults ON
      |       names, short functions, low nesting, DI/composition seams,
      |       stronger contracts, invariants, secure defaults, simple tests,
      |       rationale-only comments, docs/examples as API tests
      |
      +--> Proposal 197 decisions
      |       structured operational outcomes; hard internal defects
      |       max one authorized fallback; no silent downgrade
      |       versioned additive local contracts
      |       function/module Strategy seams for host/provider adapters
      |       validation at input/execution/output artifact boundaries
      |       deterministic Pester + contract fixtures; live smoke only authorized
      |       existing tools/no new dependency by default
      |       existing Specrew module/deployment surfaces; no broad utility package
      |
      +--> Explicit non-drivers for Iteration 001
              no performance tuning focus
              no UI/render/hosting rules
              no distributed cache/messaging surface
              no new CI/service identity/release automation
```

## Resolved Stack

- PowerShell 7.x scripts/modules.
- Markdown, YAML, and JSON governance artifacts and schemas.
- Pester unit, contract, fixture, and integration tests.
- Local file/stdin/stdout/process-exit contracts for reviewer-agent execution.
- Existing Specrew helpers and standard PowerShell/.NET APIs.

## Decisions Captured

1. **Source of code-rules truth**: Continue with the same methods as the current
   Specrew implementation and the existing feature manifest pattern. No external
   guideline or example repository is ingested.
2. **Error and failure shape**: Represent expected operational outcomes as
   structured records/artifacts; keep internal invariant, schema, or code defects
   as hard failures in tests and review.
3. **Retry and fallback posture**: Allow at most one authorized availability
   fallback attempt from explicit configuration; never silently downgrade
   provider/model and never retry schema or invariant defects.
4. **Contract and versioning posture**: Treat local file/stdin/stdout/CLI shapes
   as public integration contracts with schema versions, stable fields, and
   additive evolution. Provider-specific payloads stay behind adapters.
5. **Extension points**: Use PowerShell-friendly function/module Strategy seams
   and capability descriptors rather than inheritance or growing central
   host-name switches.
6. **Validation boundaries**: Validate request, capability, invocation, result,
   thread, verdict, run, skipped-run, and infrastructure-failure artifacts at
   input, execution, and output boundaries.
7. **Testing posture**: Use deterministic Pester and contract fixtures for the
   required path. Real AI-host smoke is optional and only when configured and
   explicitly authorized.
8. **Dependency policy**: Use existing project tools and no new dependency by
   default. Any future new dependency requires explicit review of version,
   license, source, URL, maintenance/security status, compatibility, cost/quota,
   coupling, replaceability, and test impact before it is added.
9. **Shared-code packaging**: Ship reusable implementation through existing
   Specrew module/deployment surfaces. Do not create a separate package or broad
   common utility library in Iteration 001.
10. **Protected-surface constraint**: Do not edit F-184-protected host-runtime,
    hook, provider, registry, refocus, or shared governance surfaces without
    explicit coordination. Treat Proposal 197 reviewer-agent host/model provider
    adapters as a separate domain from F-184 repository/provider infrastructure,
    and avoid ambiguous provider-file names that would blur the two.
11. **Fallback scope**: Fallback is only for availability. If the primary
    authorized host/model is unreachable, at most one explicitly authorized
    alternate may be tried; a requested model that is unavailable remains a hard
    block unless the exact alternate was already human-authorized.

## Explicit Exceptions / Non-Drivers

- Performance tuning is not a design driver for Iteration 001 unless a measured
  local timeout issue appears.
- UI/render/hosting rules do not apply; Proposal 197 does not introduce an app
  UI in this slice.
- Distributed cache, messaging, event streams, queues, and background service
  workers are out of scope.
- New CI workflow, service identity, branch-protection mutation, release
  automation, and CI/CD E2E implementation remain out of scope for Proposal 197
  Iteration 001.

## Durable Manifest

The binding manifest is `specs/197-continuous-co-review/implementation-rules.yml`.

## Iteration 002 Send-Back Addendum: Reviewer Definition Implementation Rules

The review send-back is a focused additive repair to the existing Proposal 197
implementation-rules manifest. It keeps the current Specrew implementation
methods, PowerShell/Markdown/YAML/JSON stack, deterministic Pester fixture
posture, no-new-dependency policy, protected-surface constraint, and local
file/stdin/stdout/process contracts. The repair adds explicit implementation
rules for the reviewer definition, prompt-composition path, host mirrors,
mutation guard, and SC-012 manual validation.

```text
Code-implementation flow — reviewer-definition repair

Current Specrew methods + implementation-rules.yml
        |
        v
+-----------------------------+
| No new dependency baseline  |
| PowerShell + JSON/YAML/MD   |
| Pester + fixtures           |
+-------------+---------------+
              |
              v
+-----------------------------+        +------------------------------+
| Canonical instruction file  |        | Host mirror deployer         |
| code-review-agent.md        |------->| copies to host folders only  |
| Specrew-owned source        |        | best-effort consistency      |
+-------------+---------------+        +------------------------------+
              |
              v
+-----------------------------+
| ReviewRequest.v2 builder    |
| design context content      |
| diff/change-set content     |
| round + prior findings      |
| visibility/do-policy        |
+-------------+---------------+
              |
              v
+-----------------------------+
| Prompt composer             |
| injects instruction +       |
| structured request content  |
| creates host-ready prompt   |
+-------------+---------------+
              |
              v
+-----------------------------+        +------------------------------+
| Fixture prompt capture      |------->| Pester asserts rubric,       |
| sanitized deterministic     |        | design context, round/prior, |
| no live host/secrets        |        | policy, FindingsResult-only  |
+-------------+---------------+        +------------------------------+
              |
              v
+-----------------------------+        +------------------------------+
| Transport-only adapters     |------->| safe argv, read-only flags,  |
| Claude/Codex/Copilot/etc.   |        | timeout, stdout/stderr meta  |
+-------------+---------------+        +------------------------------+
              |
              v
+-----------------------------+
| Mutation guard tests        |
| isolated workspace pre/post |
| mutation => invalid run     |
+-----------------------------+
```

### Send-Back Decisions

- **Source of rules**: Continue using current Specrew implementation methods and
  the existing `implementation-rules.yml` manifest. No external coding guideline
  or example-project ingestion is needed for this repair.
- **Dependency posture**: Keep
  `dependency_policy.stance: use-existing-no-new-dependency`. Implement prompt
  composition, hashing/provenance, sanitized fixture capture, host mirror
  deployment, and mutation detection with existing PowerShell, .NET, and Pester
  patterns only. Any future dependency still requires the full IMPL-006 evidence
  gate before it can be added.
- **Focused implementation seams**: Add narrow PowerShell/function seams for
  `ReviewerInstructionSource`, `ReviewRequest.v2` builder,
  `ReviewPromptComposer`, `ReviewRoundContext`/prior-findings builder,
  `WorkspaceMutationGuard`, and `HostAgentMirrorDeployer`. Do not create broad
  utility modules or central host-name switch logic.
- **Prompt-composer evidence**: Tests must exercise the same prompt composer used
  by real host adapters. A deterministic sanitized fixture must capture or
  inspect the actual outbound prompt and fail if it omits canonical
  `code-review-agent.md` content, Proposal 145 rubric, workshop-decision
  conformance instructions, design context content, exact diff/change-set
  content, `round_number`, `prior_findings` and verification instructions,
  visibility policy, do-policy, or output-only `FindingsResult.v1`
  instruction.
- **Adapter implementation**: Host adapters receive a complete composed prompt
  and remain transport-only. They use safe argv/equivalent invocation, pass
  read-only flags where supported, apply timeout, and translate CLI outcomes into
  the existing contract/failure envelope. They do not compose host-specific
  reviewer prompts.
- **Host mirrors**: Deploy the same canonical `code-review-agent.md` content to
  supported host folders via the existing skill/"just folders" mechanism for
  consistency and best-effort native load. Runtime correctness depends only on
  injected prompt composition, not host auto-execution of those files.
- **Mutation tests**: Use disposable review workspace fixtures to prove
  source/spec/state/Git mutations invalidate review execution. Mutation changes
  are evidence only and are never copied back or treated as fixes.
- **Manual validation**: Update SC-012 manual validation to invoke the exact
  injected-prompt reviewer path used by automation. The runbook must not ask
  maintainers to paste or run a hand-written reviewer prompt.
- **Remote-main sync before implementation**: Before implementation starts,
  merge or rebase the feature branch with the latest remote `main` and resolve
  conflicts. This can be the first step of the implementation iteration or a
  dedicated preparatory iteration if the conflict surface is large.
- **Scope guard**: No rung-1 hooks/PostToolUse trigger, Proposal 139 foundation,
  Proposal 196 provenance work, automated live cross-host CI, new dependencies,
  or edits to F-184 protected host/hook/provider/registry/refocus surfaces.

### Done Interpretation

The repair is implementation-ready only when the canonical reviewer instruction
is delivered through the same prompt-composer path used by all real adapters,
fixture tests inspect that actual prompt content, host-folder mirrors are
non-authoritative consistency copies, mutation guard tests invalidate reviewer
writes in disposable workspaces, SC-012 uses the exact injected-prompt path, and
the branch has been synchronized with remote `main` before implementation begins.
