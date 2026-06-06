# Workshop Record — integration-api (Lens 4, medium)

**Feature**: 171-specrew-refocus
**Date**: 2026-06-06
**Confirmation**: human-confirmed (six contracts + C6 placement decision agreed in one pass)

## Agreed contract inventory

```text
C1  Engine CLI (refocus.ps1)            owner: F-171 · consumers: skill, provider,
    --boundary <name> | --role <name> | wrapper, humans
    --shape-catalog | --everything |    OUT: markdown payload; line 1 = banner
    --trigger <b1|b2|b3> |              [specrew-refocus] trigger=<t> scope=<s>
    --compact-instructions | (no args)  sources=<n> tokens~<est>
                                        ERR: warnings to stderr as
                                        [specrew-refocus] WARN <msg>; missing
                                        canonical file -> partial payload + warn
                                        (fail-open); bad args -> exit 2 (human
                                        surface only; dispatcher never passes bad args)

C2  Host hook protocol (per host)       owner: the HOST (we conform) · adapter:
    Claude: settings registration +     dispatcher normalizes event JSON ->
    event JSON on stdin (session_id,    {event, source, session_id, tool} for
    source, tool_name…) + output        providers; per-host shapes VERIFIED in
    (additionalContext / exit codes)    the research matrix before binding

C3  Provider registry row               owner: F-171 catalog · consumers: dispatcher
    {id, events[], order, budget_share, provider contract: normalized event in ->
     command}                           markdown fragment out, exit 0, per-provider
                                        timeout; crash -> skipped + WARN (fail-open)

C4  Catalog schema (refocus-scopes.yml) owner: F-171 · schema_version field REQUIRED;
    scopes, triggers, budgets, registry additive-only evolution; engine validates and
                                        fail-opens with WARN on version mismatch

C5  Digest frontmatter                  owner: each digest · consumers: drift check,
    {scope, sources[], reviewed_at}     engine banner; sources[] are repo-relative
                                        canonical paths

C6  Merge-aware hook deployment         owner: DeployIntegration · invariants:
    add-if-absent; update ONLY entries  identify Specrew's entries by their command
    recognized as Specrew's; NEVER      path; idempotent re-deploy; user entries
    touch user rows; remove only our    byte-untouched (F-161 marker discipline
    own on uninstall                    applied to hook config)
```

## C6 placement decision (agreed)

Hook registration deploys to **per-user project-local settings** — on Claude: `.claude/settings.local.json` (gitignored), written by `specrew init`/`specrew update` per machine; per-host equivalents follow the same per-user/project-local principle. Rationale: no auto-executing hooks surprise collaborators on clone; the trust-prompt behavior for project-shared hooks is host-variable; `specrew update` is already the per-machine refresh path. User-global placement ruled out (would fire in non-Specrew projects without a self-gate).

## Key contract sequence (B1 post-compaction, Claude)

```text
Claude Code                Dispatcher              Engine            Files
    | SessionStart            |                      |                 |
    | (source: compact)       |                      |                 |
    +-- stdin: event JSON --->|                      |                 |
    |                         +- read registry (C4) -+---------------->|
    |                         +- provider #1: refocus|                 |
    |                         |   normalized event ->|                 |
    |                         |                      +- catalog (C4) ->|
    |                         |                      +- digests (C5) ->|
    |                         |   payload + banner <-+                 |
    |                         +- budget check, dedupe|                 |
    | <-- additionalContext --+   fingerprint write -+---------------->|
    |     (C2 output shape)   |                      |            (state file)
    v
 context now holds general + current-stage digest, banner names the trigger
```

## Plan obligations from this lens

- Contract tests: producer + consumer fixtures for C1 (golden payloads per flag), C3 (provider crash/timeout -> skip + WARN), C4 (schema-version mismatch -> fail-open WARN), C6 (user entries byte-untouched across re-deploys)
- Research matrix verifies C2 per host BEFORE binding that host's hooks (exact event names, stdin shape, output/injection mechanism, trust-prompt behavior, settings file analog)
- Error envelope standardized: `[specrew-refocus]` banner + `[specrew-refocus] WARN` lines everywhere
