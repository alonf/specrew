# T006 Documentation Evidence: Antigravity Host Parity Depth

## Scope

T006 updates user-facing Antigravity documentation to the same content depth as
the other supported hosts while keeping support status evidence-gated until the
T008 real-host `agy` run.

## Updated Surfaces

| Surface | Evidence |
| --- | --- |
| `README.md` | Lists `agy` as the native entry point, describes `.agents/hooks.json`, `PreInvocation` bootstrap + B3 refocus, `Stop` handover, B1 absence, hook repair/remove commands, `/permissions`, `agy --dangerously-skip-permissions`, `agy --sandbox`, `enableTerminalSandbox`, and `specrew start --host antigravity` fallback. |
| `docs/getting-started.md` | Updates host table, bootstrap path, Antigravity quickstart, hook-driven bootstrap callout, host switching, and caveats to include B3-on-`PreInvocation`, hook fallback, native resume, permissions, sandboxing, and evidence-gated support labels. |
| `docs/user-guide.md` | Updates refocus trigger matrix, session continuity, host-enforcement asymmetry, per-host capability matrix, and Antigravity interaction model with project-local hooks, B3 carrier behavior, B1 absence, hook install/remove/status, `/permissions`, and sandbox guidance. |
| `docs/api-reference.md` | Documents that `specrew hooks` preserves user-owned Antigravity hook definitions while adding/removing only Specrew-owned `PreInvocation` and `Stop` entries. |
| `docs/troubleshooting.md` | Updates no-banner/recovery guidance, `agy` resume checks, permission auto-approval, sandboxing, and hook opt-out commands. |

## Status Wording Check

- No public docs claim Antigravity is verified or stable before T008 evidence.
- Public docs describe implemented support in concrete carrier terms rather than
  the obsolete F-183 "bounded bootstrap-only" wording.
- Remaining caveat language is evidence-gated: release-specific real-host
  `agy` evidence is required before verified/stable labels.

## Mechanical Checks

```powershell
rg -n "Antigravity.*bounded|bounded.*Antigravity|not a full parity|no B3 parity|current slice remains bounded|bounded project hook|bounded project-hook|PreInvocation bootstrap injection|Stop handover decisions" README.md docs specs/184-full-antigravity-refocus -S
rg -n "enableTerminalSandbox|/permissions|specrew hooks remove --host antigravity|PreInvocation.*B3|B1 compaction|agy --dangerously|agy --sandbox|hooks status --host antigravity" README.md docs/getting-started.md docs/user-guide.md docs/troubleshooting.md docs/api-reference.md -S
```

The stale-phrase scan has no public-doc hits. The positive evidence scan finds
the required permission, sandbox, hook disable, B3 carrier, and fallback wording
across the updated docs.
