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
