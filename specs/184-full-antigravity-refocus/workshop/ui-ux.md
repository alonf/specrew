# UI UX Lens

## Decision

F-184 has no application UI. The user-facing experience is documentation,
status/help wording, host matrix placement, warning language, and operational
guidance for Antigravity users. Antigravity must appear at the same level as
other supported hosts, while the wording must distinguish bounded support,
full support, verified support, machine-local evidence, beta, and stable.

## User-Facing Journey

```text
developer in a downstream project
        |
        v
read README / getting-started / host matrix
        |
        | sees Antigravity beside other hosts
        | command: agy
        | hook config: .agents/hooks.json
        | deploy: deploy-refocus-hooks.ps1 -HostKind antigravity
        | remove: deploy-refocus-hooks.ps1 -HostKind antigravity -Remove
        v
run agy
        |
        +--> normal path:
        |       bootstrap/refocus/handover messages are concise and actionable
        |
        +--> warning path:
        |       hook fails open, warning names the failed provider/event/session
        |       user is told to run specrew start or redeploy hooks when needed
        |
        +--> disable/permissions path:
                docs point to Antigravity /permissions and
                enableTerminalSandbox in Antigravity settings
```

## UX Source Of Truth

- Existing Specrew README, getting-started, host matrix, status/help wording,
  and host-specific docs are the source of truth.
- There is no Figma, screenshot, or new visual product surface for this
  feature.
- Antigravity docs should follow the same structure and prominence as Claude,
  Codex, Copilot, Cursor, and other supported hosts.

## Primary User Journeys

- A new user checks whether Specrew supports Antigravity and sees `agy` listed
  as the command to run.
- A user installs or updates Specrew and deploys Antigravity hooks without
  hand-editing `.agents/hooks.json`.
- A user disables Specrew Antigravity hooks and can confirm user-owned hooks
  were preserved.
- A user sees a refocus/handover warning and receives a short recovery path:
  use `specrew start`, redeploy hooks, or check Antigravity permissions.
- A maintainer reads the host matrix and can tell whether Antigravity support
  is bounded, full, verified, machine-local, beta, or stable.

## Interaction And State Wording

- Use `agy` consistently for the Antigravity CLI command.
- Use `Antigravity` as a peer host name, not as an experimental footnote after
  full real-host evidence lands.
- Before evidence lands, do not use a full parity claim. Say "bounded",
  "candidate", "machine-local evidence", or "requires real-host validation" as
  applicable.
- Error and warning text must name the failing event and recovery action, but
  must not dump full prompts, transcript content, or large model responses.
- Status/help wording must make the beta-before-stable rule visible at release
  gates.

## Recovery And Permission UX

- Permission guidance must be easy to find from getting-started and host docs.
- Antigravity disable guidance must include both Specrew hook removal and
  Antigravity-native controls:
  - `/permissions`
  - `~/.gemini/antigravity-cli/settings.json` `enableTerminalSandbox`
- Specrew must not tell users to weaken permissions as a prerequisite for
  lifecycle support.
- Hook failures must fail open while telling the user what Specrew lifecycle
  support was skipped and how to re-enter with `specrew start`.

## Accessibility And Clarity

- Commands should be copyable as literal monospace commands.
- Host support status must not depend on color alone; use explicit text labels.
- Keep host matrix rows scannable and avoid burying Antigravity behavior in
  release notes only.
- Prefer short, direct recovery language over long diagnostic paragraphs.

## Confirmation

The human agreed to the light UI/UX scope: no app UI, but Antigravity must be
documented and surfaced at the same level as other hosts, with clear status,
permission, disable, recovery, beta, stable, and evidence wording.
