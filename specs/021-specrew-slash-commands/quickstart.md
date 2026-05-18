# Quickstart: Validate the Specrew Slash-Command Surface

**Feature**: 021-specrew-slash-commands  
**Audience**: Maintainers, reviewers, and implementation owners  
**Purpose**: Validate the planned slash-command slice after implementation without crossing the task-generation boundary during planning.

## Overview

This quickstart validates the planned Feature 021 slice across five concerns:

1. Distribution/setup provisions the slash-command assets
2. Discovery works through host-native `/specrew.` or `/specrew.help`
3. Routing reaches the correct existing Specrew workflows
4. Compatibility failures stay explicit
5. `/specrew.*` coexists with `/speckit.*` without boundary bypass

## Prerequisites

- PowerShell 7+
- A Specrew-managed project with the Feature 021 implementation applied
- Access to a Squad/Copilot session
- Repository references:
  - [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md)
  - [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/slash-command-catalog.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/slash-command-catalog.md)
  - [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/slash-command-routing.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/slash-command-routing.md)

## Step 1: Provision the command surface

Use a fresh project or refresh an existing supported project:

```powershell
specrew init
```

or

```powershell
specrew update
```

**Verify**:

- `.copilot/skills/specrew-*` contains the deployed slash-command skill directories
- `.specrew/config.yml` reflects a slash-command-capable Specrew baseline

## Step 2: Validate discovery

Inside the session surface:

1. Type `/specrew.` and confirm the host surfaces Specrew commands when supported.
2. Run `/specrew.help`.

**Expected result**:

- The catalog lists `/specrew.where`, `/specrew.status`, `/specrew.update`, `/specrew.team`, `/specrew.review`, `/specrew.help`, and `/specrew.version`
- `/specrew.status` is clearly marked as an alias for `/specrew.where`
- New-user guidance points to the next appropriate action

## Step 3: Validate routing and alias parity

Run the routed commands in a session:

```text
/specrew.where --compact
/specrew.status --compact
/specrew.update --info
/specrew.team list
/specrew.review --help
/specrew.version
```

**Expected result**:

- `/specrew.where` and `/specrew.status` produce the same semantic result
- Each command reaches the intended existing Specrew workflow
- Output stays native/minimally wrapped rather than being re-summarized

## Step 4: Validate failure surfaces

Run at least one unsupported-argument scenario and one compatibility/setup scenario:

```text
/specrew.update --bogus
```

Also validate one of:

- A project that has not run `specrew init`
- A project whose baseline predates the first release shipping Feature 021

**Expected result**:

- Unsupported arguments are rejected explicitly with help guidance
- Missing setup fails with a supported remediation path
- Outdated compatibility fails with upgrade guidance rather than silent fallback

## Step 5: Validate namespace coexistence and boundary safety

In the same session:

```text
/specrew.where
/speckit.plan
```

**Expected result**:

- Both namespaces remain independently available
- `/specrew.where` does not imply approval to advance the lifecycle
- `/specrew.review` may support review work but still preserves required human approval

## Step 6: Record evidence

Capture evidence in the Feature 021 review path after implementation using:

- the hardening gate at [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md)
- command/routing expectations from the contracts in [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/)
- the measurable outcomes in [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md)

## Stop Condition

This planning quickstart ends with a validation recipe only. It does **not** authorize task generation or implementation on its own; human review of the completed plan remains the next boundary.
