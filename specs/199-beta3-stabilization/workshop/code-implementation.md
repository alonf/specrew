# Code-Implementation Lens Record: 199-beta3-stabilization

**Feature**: 199-beta3-stabilization
**Depth**: standard (inherit + deltas)
**Captured**: 2026-08-10
**Confirmation**: human-confirmed (inherit-with-deltas confirmed; reviewer host codex selected)

## Source of code-rules truth

The feature-198 `implementation-rules.yml` is the product-level rule set for this exact
machinery (resolved stack `powershell-markdown-yaml-json`). Per the lens run cadence the
199 manifest INHERITS it wholesale and re-opens only the deltas below. No external
guideline or example project beyond the repo's own conventions.

## The 199 deltas (human-confirmed)

1. **New custom rule — consumer-language enforcement** (from the ui-ux U2 contract):
   consumer-facing surfaces render IDs through the gloss helper (id + title required)
   and pass the banned-machinery-noun check; both are failing tests, not review notes.
2. **New custom rule — pause-economics fixtures**: every economics invariant (nothing
   spends until a numbered reply; budget exhaustion refuses; infra failures never
   spend) ships as a RED-first instance-pinned fixture through the shipped entry point.
3. **Dependency stance unchanged** (`use-existing-no-new-dependency`): the
   markdownlint-cli CI install is a runner tool in the workflow file, not a module
   dependency.

Also updated in inherited decisions: `no-magic-numbers` now names the round budget
default (4) and codex window (900 s) as named configuration values;
`authz-security-context` records the beta3 single-run continuation-grant rule.

All six 198 custom rules carried, re-scoped to feature-199: provider-mirror parity,
psd1 FileList, born-clean lint, scratch-probes-only, remote-main sync, paired honesty
tests.

## Reviewer selection (INT-006)

The live `specrew review --list-hosts --code-writer-host claude` output was presented
verbatim. **Human pick: codex** — the strongest independent host while Claude writes
the code; reviewing this feature dogfoods the exact fixes it ships (900 s window,
verdict-goal prompt contract, pause economics). The codex file-delivery quirk (findings
via file, empty stdout, wasteful retry + "partial" mislabel, harvest recovers) stays a
recorded beta4 watch item.

Authorization persisted via the command path:
`specrew review --host codex --authorization-ref workshop-199-beta3-stabilization`
-> `.specrew/reviewer-hosts.json` (command-written; never hand-authored).
