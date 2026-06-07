# Quickstart: Specrew Refocus

**Feature**: 171-specrew-refocus
**Last verified**: pre-implementation (planning artifact; re-verify at review)

## Run it

```powershell
# Manual scoped refocus (any host, any time)
pwsh -NoProfile -File .specify\extensions\specrew-speckit\scripts\refocus.ps1                       # general + current stage
pwsh -NoProfile -File .specify\extensions\specrew-speckit\scripts\refocus.ps1 --boundary review-signoff
pwsh -NoProfile -File .specify\extensions\specrew-speckit\scripts\refocus.ps1 --role reviewer
pwsh -NoProfile -File .specify\extensions\specrew-speckit\scripts\refocus.ps1 --status              # whole truth: env/catalog/breaker/journal tail
pwsh -NoProfile -File .specify\extensions\specrew-speckit\scripts\refocus.ps1 --compact-instructions # paste-ready /compact preserve-list
```

In an agent session the same surface is the `/specrew-refocus` slash command.

## Try the canonical scenario (B3 boundary-cross, works on EVERY host)

1. In a Specrew project mid-feature, advance a lifecycle boundary (the crew runs the boundary-sync wrapper as usual).
2. Observe the wrapper's stdout now ends with: `[specrew-refocus] trigger=boundary scope=general+<next-stage> sources=<n> tokens~<est>` followed by the digest content.
3. Run `--status`: the journal tail shows `{trigger: channel1, outcome: injected}` for the crossing.

## Try the hook scenario (hook-bound hosts, e.g. Claude)

1. With hooks deployed (`specrew update` wrote the dispatcher registration into `.claude/settings.local.json`), run `/compact` in a session.
2. After compaction, the next turn opens with the B1 banner + the general + current-stage digest — re-injected automatically.
3. `--status` journal shows `{trigger: b1, channel: hook, outcome: injected}`.

## Verify the edge cases

- **Kill switch (fast)**: set `SPECREW_REFOCUS_DISABLE=1`; cross a boundary on the hook path — nothing fires from hooks; the slash command still works; unset to restore.
- **Dedupe**: cross a boundary (wrapper emits), then watch the next hook check stay silent — journal shows `outcome: deduped`, not a second payload.
- **Fail-open**: rename the catalog temporarily; any trigger yields ONE `[specrew-refocus] WARN CATALOG_SCHEMA ...` line and the session continues; restore the file.
