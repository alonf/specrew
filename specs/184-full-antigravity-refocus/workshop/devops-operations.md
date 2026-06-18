# DevOps Operations Lens

## Decision

Antigravity support is a local-tool integration for downstream Specrew projects.
Users run Antigravity with `agy`; Specrew deploys and removes Antigravity hooks
through the existing host-manifest-driven hook deployment path.

## Operational Topology

```text
developer machine / downstream project
        |
        v
specrew update / install
        |
        v
+--------------------------+
| host manifest            |
| hosts/antigravity        |
+------------+-------------+
             |
             v
+--------------------------+
| deploy-refocus-hooks.ps1 |
| -HostKind antigravity    |
+------------+-------------+
             |
             v
.agents/hooks.json
  PreInvocation -> launcher -> dispatcher -> bootstrap/B3
  Stop          -> launcher -> dispatcher -> handover

Disable path:
  deploy-refocus-hooks.ps1 -HostKind antigravity -Remove
  opt-out marker under .specrew/runtime
  Antigravity /permissions and enableTerminalSandbox guidance in docs
```

## Install And Enablement

- User-facing Antigravity command is `agy`.
- Specrew hook deployment uses `deploy-refocus-hooks.ps1 -HostKind
  antigravity`.
- Hook configuration lives in workspace `.agents/hooks.json`.
- Deployment must preserve user hook definitions and replace only
  Specrew-owned hook definitions.
- The deployer remains generic; Antigravity specifics live in the
  `hosts/antigravity` manifest.

## Disable And Permissions

- Specrew disable path mirrors other hosts:
  `deploy-refocus-hooks.ps1 -HostKind antigravity -Remove`.
- Removal writes/uses the Antigravity opt-out marker under `.specrew/runtime`.
- Documentation must include Antigravity's own permission controls:
  `/permissions` for autonomy level and
  `~/.gemini/antigravity-cli/settings.json` `enableTerminalSandbox` for
  terminal sandbox behavior.
- Specrew must not require users to weaken Antigravity permissions to get
  lifecycle support; hooks must fail open.

## CI And Validation

- CI/static validation can check host manifest shape, generated
  `.agents/hooks.json` shape, JSON validity, Pester regression tests, and
  deploy/remove idempotency.
- Full Antigravity parity cannot be claimed from CI-only evidence.
- Manual real-host `agy` validation is required for hook firing, injection,
  B3 behavior, Stop handover, exit/re-entry, and permission/sandbox docs.
- The release evidence must distinguish repo-reproducible evidence from
  machine-local evidence.

## Release And Rollback

- Release path is beta first after manual real-host evidence, then stable only
  after release validation passes.
- Stable promotion must include the existing-config / legacy-upgrade path, with
  user hook preservation.
- Rollback removes the Specrew Antigravity hook definition and leaves user hooks
  intact.
- If packaged install/upgrade validation cannot be completed before stable, the
  release gate must surface that limitation for a human verdict instead of
  proceeding silently.

## Confirmation

The human agreed to this operations model: `agy` is the Antigravity command;
Specrew deploys/removes hooks through the host-manifest path; `.agents/hooks.json`
preserves user hooks; docs include Antigravity permission/sandbox controls; CI
handles static/proxy checks; full parity requires manual real-host validation;
and release proceeds beta first, then stable after upgrade/release validation.
