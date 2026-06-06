# Workshop Record — architecture-core (Lens 1, full)

**Feature**: 171-specrew-refocus
**Date**: 2026-06-06
**Confirmation**: human-confirmed (5 decisions worked one-at-a-time, plus one human-raised addition)

## Agreed trigger/channel architecture

```text
            SPECREW TRIGGER CONTRACT (host-neutral, owned by F-171)
            B1 post-compaction | B2 launch/resume | B3 boundary-cross
                                   |
        +----------+---------------+--------------+--------------+
        v          v               v              v              v
   hosts/claude  hosts/antigravity hosts/cursor  hosts/codex  hosts/copilot
   binds B1+B2+B3  binds subset    binds subset   binds what   binds none today
   (documented)    (105 research)  (hooks.json,   notify can   (channels 1+2
                                    verify)        express      carry it)
        +----------+---------------+--------------+--------------+
                          every binding calls the SAME
                          deployed refocus engine

   + CHANNEL 1 (boundary-sync wrapper stdout)  - all hosts, hook or not
   + CHANNEL 2 (instruction-file primer floor) - all hosts, hook or not
   + CHANNEL 3 (host event hooks)              - strongest binding per host
```

```text
                       TRIGGER SURFACES (volatile, per-host)
  +------------------+---------------------+------------------------+
  | /specrew.refocus | host hook events    | Coordinator advisory   |
  | slash skill      | B1 compact          | (fallback for hosts    |
  | (all hosts)      | B2 startup/resume   |  with no hook surface) |
  |                  | B3 boundary-cross   |                        |
  +--------+---------+----------+----------+-----------+------------+
           | scope flags        | event -> scope map   | suggestion only
           v                    v                      v
  +-----------------------------------------------------------------+
  |              REFOCUS PAYLOAD ENGINE  (stable, host-neutral)     |
  |   canonical: scripts/internal/refocus.ps1                       |
  |   deployed:  .specify/extensions/specrew-speckit/scripts/       |
  |   scope resolution -> digest reads -> banner + markdown         |
  +------------------------------+----------------------------------+
                                 | reads at event time (never embedded)
                                 v
  +-----------------------------------------------------------------+
  |  REFOCUS DIGEST FAMILY (new, purpose-authored)                  |
  |  refocus/general.md + refocus/<stage>.md x 10 stages            |
  |  each: frontmatter-declared canonical sources + file:/// ptrs   |
  |  mapped by refocus-scopes.yml (data-driven catalog)             |
  +-----------------------------------------------------------------+
```

## Decisions

1. **Decomposition style + engine placement** — thin volatile per-host trigger adapters over a stable host-neutral payload engine (repo layering = IDesign volatility cut). Engine ships as a **deployed extension script** (canonical in `scripts/internal/`, mirrored to `.specify/extensions/specrew-speckit/scripts/` by the deploy loop) so Pillar B works in downstream projects; hooks invoke the project-local copy directly (no module import per fire).

2. **Trigger delivery = host-neutral contract + per-host bindings (maintainer-corrected from Claude-first framing).** Three channels: (1) in-band lifecycle stdout — the boundary-sync **wrapper** appends the next stage's refocus payload on ALL hosts (not in crew-169's footprint); (2) static instruction-file primer floor; (3) host event hooks as the strongest, per-host binding. **All hook-capable hosts bind in this feature**: Claude (full), Antigravity (105-researched subset), Cursor (hooks.json, verify), Codex (notify-if-expressible); Copilot = channels 1+2 only (documented variance). B3 detection principle: **watch the state, not the actor** — handler diffs `start-context.json`'s boundary cursor against its own runtime-local last-seen note (LastWriteTime cheap-guard; the note file doubles as the dedupe store). Check-often/inject-rarely: stat per event, inject only on actual crossing.

3. **Scope/trigger mapping is data-driven** — `refocus-scopes.yml` (deployed, schema-checked): scope -> digest files, trigger -> scopes, per-trigger token budget. Engine and all bindings stay dumb.

4. **Payload = general + per-stage digest family (human-proposed model)** — `refocus/general.md` (always-true core) + one digest per pipeline stage; every injection composes general + current/next stage. Digests are purpose-authored for injection, end with `file:///` pointers to canonical sources, and declare their sources in frontmatter for a **drift parity check**. `--role` keeps loading role charters directly (already compact).

5. **Binding constraints (all 7 recorded as binding for plan + review):**
   1. One payload engine for ALL surfaces (no per-trigger payload forks)
   2. Read-at-event (no embedded content in skills/hooks/handlers)
   3. Fail-open (no trigger may block a session; one visible warning line)
   4. Token budget per trigger from the catalog + scope banner on every injection
   5. Merge-aware hook deployment (F-161 managed-marker discipline; never clobber user hooks)
   6. Loop safety (per-session dedupe; re-fire only after real context loss)
   7. Digest drift guardrail (frontmatter sources + parity warn)

6. **Scope line** — IN: Pillar A on 5 hosts; contract; channels 1+2 everywhere; digest family + catalog; hook bindings for all hook-capable hosts (research-verified); **managed compaction points part (i)** — engine scope `--compact-instructions` generates the paste-ready `/compact` preserve-list from lifecycle state + boundary-packet context-hygiene guidance (human-raised addition, ~+1-2 SP); deploy/parity/tests/docs.
   OUT (named dispositions): B4 **widened to compaction-steering research** (PreCompact injection + persistent-instruction efficacy — research-gated, ships only on empirical confirmation); Copilot hook binding (no surface; closes when one exists); Proposal 133 full primer (compose, don't absorb; only the refocus pointer); Proposal 130-P4 handover content (we build ONE SessionStart dispatcher with a seat for it); validator-enforced mandatory refocus (triggers ARE the enforcement; 165-class gating is its own proposal if dogfooding shows ignored injections); Proposal 140 checklist matrix (digests integrate it as a declared source when it lands).

## Key flow (agreed)

```text
crew finishes implement; boundary-sync advances cursor to review-signoff
  -> CHANNEL 1: wrapper stdout appends general + review-signoff digest (all hosts)
  -> CHANNEL 3 (hook hosts): post-tool state-watch sees cursor moved; injects
     scoped payload even if stdout was ignored; dedupe prevents double-fire
  -> reviewer discipline is fresh in context exactly when the review begins
```

## Sizing note

All-host bindings + compaction part (i) move the feature from the amended 10-15 SP toward **15-25 SP**; per-host research tasks (Cursor/Antigravity/Codex surface verification) are named spec work.
