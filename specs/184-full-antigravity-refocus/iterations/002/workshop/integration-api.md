# Integration API Lens: Iteration 002

**Depth**: medium  
**Confirmation**: human-confirmed / lens-question

## Decision

The integration contract is the host manifest's `InstructionsFile` field.
`specrew init` must use that contract to deploy persistent instructions.
`specrew update` should refresh the managed section. `specrew start` can heal
or refresh the file, but it must not be the only delivery path for the
coordinator instruction file.

`AGENTS.md` is not sufficient as the only instruction surface. It is correct for
Codex, Cursor, and Antigravity CLI, but Claude needs `CLAUDE.md` and Copilot
needs `.github/copilot-instructions.md`. Therefore the implementation should
project one shared Specrew coordinator template into each supported host's
manifest-declared instruction file.

No new per-host write handler is needed in this iteration because all known
supported hosts differ only by target path. Add such an extension point later
only if a host needs custom semantics beyond managed-section file merge.

## Diagram

```text
hosts/<kind>/host.psd1
    |
    +-- InstructionsFile:
        AGENTS.md | CLAUDE.md | .github/copilot-instructions.md
    |
    v
instruction deployer
    |
    +-- enumerate supported manifests
    +-- render shared Specrew coordinator section
    +-- create/update target file
    +-- merge managed section
    +-- preserve user content outside managed section
    |
    v
host instruction file
    |
    +-- user content
    +-- Specrew managed coordinator section
    +-- user content

specrew start may heal/refresh the file, but init is the primary deploy path
```

## Contract Points

- Contract owner: host manifest registry.
- Contract field: `InstructionsFile`.
- Content source: one packaged Specrew coordinator template/fragment.
- Versioning: current host manifest schema; no new per-host handler unless a
  future host needs custom write semantics.
- Idempotency: reruns replace only the Specrew-owned section.
- Compatibility: tests add/read manifests, not shared-core host literals.

## Guard Text

Both persistent instructions and bootstrap must prominently carry:

```text
You are the Specrew Crew coordinator. Drive the lifecycle via the
design-workshop skill and the per-boundary speckit slash-commands. Do NOT run
the raw specify.exe workflow / bundled SDD engine - it bypasses the governed
boundary gates.
```
