# Data and Storage — Feature 200

No database or new runtime store is required. The feature changes declarative manifests and
a managed project configuration projection.

```text
Canonical package data

hosts/<kind>/host.psd1
  identity / status
  runtime capabilities
  CanCoordinate
  coordinator defaults
  tested-build metadata
  volatile-monitor metadata
             |
             v
Registry-driven projection
             |
             v
.specrew/iteration-config.yml
  # >>> specrew-managed agents >>>
  agents:
    <coordinator-capable host>:
      enabled
      access_path
      availability
      strength_rank
  # <<< specrew-managed agents <<<

Future operational monitor output is separate:
  observed version, canary result, timestamp, evidence
```

## Ownership

- Host manifests own package-level capabilities and defaults.
- The registry owns discovery and validation.
- The managed `agents:` block owns project-specific routing choices.
- Future monitor reports own observed operational history; they do not overwrite manifests.
- Shared tools such as Spec Kit and Squad remain in `supported-versions.yml`.

## Migration

One `specrew update` run must handle:

- No managed agents block.
- The legacy three-host block.
- A partially populated managed block.
- A current registry-derived block.

Migration behavior:

- Preserve existing mutable values by host key.
- Add newly coordinator-capable hosts with manifest defaults.
- Remove no-longer-eligible entries only from the Specrew-managed block.
- Preserve all unrelated configuration and user-owned content.
- Produce no diff when rerun.

Devin is coordinator-capable, uses `host_process` access, and defaults to disabled unless it
is the selected launch host.

## Deferred Upgrade Work

Feature 200 does not solve general arbitrary-version update convergence. A separate proposal
and PR will define historical-version fixtures, direct-upgrade floors, convergence tests, and
safe behavior when the old baseline module is unavailable.
