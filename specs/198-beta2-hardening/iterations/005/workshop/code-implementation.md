# Code-implementation reassessment

**Status**: complete
**Iteration**: 005

## Source and stack

The maintainer confirmed the existing Specrew repository doctrine and feature implementation manifest as the sole coding-convention source. No external guideline or example project is ingested.

Resolved stack remains `powershell-markdown-yaml-json`: PowerShell 7, Git, Pester, existing .NET runtime APIs, and existing Markdown/YAML/JSON tooling.

```text
Existing Specrew rule catalog
             |
             v
Retained baseline defaults
             |
             +---- revised decisions forced by rearchitecture
             |
             v
implementation-rules.yml
             |
             +---- actively guides implementation
             +---- drives Pester/fixture/live-smoke evidence
             +---- gives reviewer traceable rule decisions
```

## Retained baseline

- Intent-revealing names, short focused functions, low nesting, guarded invariants, SOLID, deliberate comments, secure defaults, and named configuration values remain checked.
- Composition uses functions, modules, scriptblocks, configuration, and injected paths; no DI framework or class hierarchy is added.
- Avoid broad utility modules and leaky mutable internals.
- External records use closed DTO/contracts and are mapped before core policy.
- Strict mode and terminating internal errors remain binding.
- Existing provider-mirror, package FileList, born-clean, scratch-probe, remote-main-sync, and paired-honesty custom rules remain active.

## Revised decisions

| Rule area | Confirmed implementation decision |
|---|---|
| State mutation | Repository functions publish immutable authority facts using atomic `FileMode.CreateNew`; no `Test-Path` then write. |
| Concurrency | Unique files and claim generations replace generic locks, mutable revision/CAS, SQLite, and event sourcing. |
| Ownership | Campaign, run, and claim repositories are the only logical mutation paths. |
| State machine | Pure transition functions do not call filesystem, process, Git, harness, or wall-clock mechanisms. |
| Adapters | Target, harness, runtime, repository, and clock volatility stays behind explicit contracts. |
| Harness variation | Native invocation and defaults live in the catalog and thin adapters, never host-name branches in core policy. |
| Result ingress | Strict bounded JSON schema and identity validation precedes mapping and authority promotion; Markdown is a consumer. |
| Timeout | Terminate and verify the process tree, close streams, validate partial findings, then publish the timeout result. |
| Errors | Expected external failures are structured outcomes; contradictory authority facts fail closed as corruption. |
| Retry/recovery | No hidden provider retry; reruns use new authorized run identities; reconciliation creates missing facts idempotently. |
| Testing | Pure Pester tests, repository concurrency/fault injection, executable reviewer fixtures, three-OS runtime fixtures, and one bounded live smoke per supported harness. |
| Performance | `evidence-driven-performance` is now checked: phase timing, preflight-before-spend, shared-object worktrees, bounded prompts, delta-assisted full-snapshot re-review, duplicate warnings, low-cost heartbeats, minimal hashing, and safe usage metrics. |
| Retrospective | Read validated JSON findings through a projection; do not scrape Markdown. |
| Workshop Stop | Implement a workshop-native intermediate-stop path that suppresses the generic five-section packet. |

The unchanged non-applicable rules remain unchecked: pagination, collection-query semantics, cache, queue/pub-sub/event processing, and UI/rendering rules.

## Dependency policy

`use-existing-no-new-dependency` remains binding. The macOS runtime first uses a conformance-proven native mechanism accessible through existing PowerShell/.NET/platform facilities. If real proof requires an external helper/package, dependency selection must be reopened rather than changed silently.

## Reviewer selection and authorization

The canonical installed-host command was run with Codex as code-writer. It reported Claude as the strongest independent default, followed by Copilot, Cursor Agent, and Antigravity; Codex remained selectable as the same-host option.

The maintainer selected `claude`. The canonical authorization command succeeded with authorization reference `workshop-198-beta2-hardening`; the reviewer registry was not hand-edited. No model or effort is pinned because Specrew uses the host's own default model.

## Human agreement

The maintainer confirmed the existing repository/manifest source, the full grouped retained and revised rule set, the no-new-dependency stance, and Claude as the independently authorized implementation reviewer.
