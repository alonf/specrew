# Workshop Record — devops-operations (Lens 6, light→deep on kill-switch)

**Feature**: 171-specrew-refocus
**Date**: 2026-06-06
**Confirmation**: human-confirmed (topology + CI split + release path agreed; kill-switch design human-probed twice and bound with full semantics)

## Deployment topology (agreed)

```text
SPECREW MODULE (PSGallery package)                      [canonical sources]
  scripts/internal/refocus.ps1            (engine)
  scripts/internal/specrew-hook-dispatcher.ps1
  extensions/specrew-speckit/refocus/*.md (11 digests)
  extensions/specrew-speckit/refocus-scopes.yml
  squad-templates/skills/specrew-refocus/SKILL.md
  hosts/<kind>/  hook-binding declarations per host
        |
        |  specrew init / specrew update  (deploy loop — the ONLY writer)
        v
DOWNSTREAM PROJECT                                      [deployed mirrors]
  .specify/extensions/specrew-speckit/scripts/   engine + dispatcher
  .specify/extensions/specrew-speckit/refocus/   digests + catalog
  .claude/skills/ + .github/skills/ + .agents/skills/   (+ .cursor rules)
  .claude/settings.local.json    hook registration (merge-aware, per-machine)
  .specrew/runtime/              created at runtime, gitignored
```

Deploy classifications: engine/dispatcher/digests = managed mirrors (refresh); catalog = **managed-with-overlay** (canonical keys refresh, user keys — `enabled:` flags, added providers — preserved); settings.local.json = merge-aware C6 writes. Idempotence tests: deploy twice → byte-identical; deploy over user edits → user keys survive.

## CI honesty split (agreed)

- Unit/integration lanes (Windows + Ubuntu): engine scope/budget/banner/confinement; dispatcher ordering/dedupe/fail-open/sanitization via **simulated event JSON fixtures**; deploy merge/parity/FileList. These are proxy checks.
- **Real trigger firing is NOT CI-provable** → beta validation (per the universal mandate): fresh downstream project; verify hook registration; real boundary cross → B3 banner in-band; real `/compact` → B1 banner + digest; kill-switch walk at each level; on ≥2 hook-bound hosts. Fixture-drift risk named: research matrix records where each host's hook surface is documented.
- FileList: ~15 new shipped files; the F-141 manifest-derived completeness gate covers them; named explicitly (two historical FileList breakages).

## Kill-switch + automatic circuit breaker (agreed, human-probed)

### Automatic — per-session circuit breaker (dispatcher path ONLY)

| Trip condition | Scope of trip | Why |
|---|---|---|
| Repeat-injection runaway (same trigger > N fires in short window) | ONLY that trigger | malfunction is per-trigger; keep B1 alive when B3 loops |
| Session token runaway (total injected > ~15k) | ALL hook triggers | budget is global |
| State file unreadable/corrupt | ALL hook triggers | no state → no safe dedupe → no safe automation |

Constitutionally NEVER tripped: `/specrew-refocus` slash (engine never dedupes humans) and channel-1 wrapper emission (intrinsically bounded — once per boundary-sync call; emits WITHOUT dedupe if state unavailable).

On trip: write `{tripped, reason, at}` to per-session state; emit ONE visible WARN naming the reason + re-enable paths (the incident is the documentation delivery); silent for the REST OF THIS SESSION only.

### Manual levels + reset matrix

```text
SWITCH                     RESET BY                       SPECREW UPDATE DOES…
session breaker trip       auto: next session clean;      prunes stale session
                           mid-session: refocus.ps1       state files only
                           --reset-breaker
env SPECREW_REFOCUS_       unset (shell-scoped)           nothing
  DISABLE=1 (first-line
  check in dispatcher)
catalog enabled: false     human edits yml back           PRESERVES (user key);
  (durable, per-project,                                  prints re-enable HINT if
  per-trigger granular)                                   the update changed refocus
                                                          components
hook de-registration       explicit re-opt-in flag        RESPECTS recorded opt-out;
  (update --no-refocus-                                   plain update does NOT
  hooks)                                                  silently re-register
```

**Principle (binding): `specrew update` never silently flips a human's disable decision in either direction** — re-deploys code, prunes runtime debris, hints at re-enables; the flip is always the human's.

**Fail-open refined (binding):** session-blocking failures forbidden (P1); injection failures degrade to silence + one visible WARN — "fail-open for the session, fail-quiet-but-loud-once for the automation." When in doubt, don't inject.

### Discoverability

- Trip WARN names the switches at the moment of need
- `refocus.ps1 --status`: env-var state, per-trigger catalog flags, session breaker state, injection count + tokens spent (added to contract C1)
- Troubleshooting-doc section + skill help text

## Release path (agreed)

Merge after crews 169/170 land (no file collision; shared-churn floor merges serially). Version bump → `-beta.N` publish → manual runtime validation per above → promote stable via `workflow_dispatch promote-prerelease`. Any FAIL keeps it beta (v0.30.0 precedent). No secrets introduced.

## Sizing note

Breaker + `--status` + `--reset-breaker` + opt-out memory: ~+1-2 SP on top of the running total.
