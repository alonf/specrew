# Quickstart: Cursor Host Package

**Feature**: `050-cursor-host-support`
**Last verified**: 2026-05-28 (planning artifact; manual smoke happens in Iteration 003)

## Prerequisites

- `cursor-agent` on PATH (verify: `cursor-agent --version` → e.g. `2026.05.28-...`). Install: <https://cursor.com/cli>.
- Authenticated: `cursor-agent status` (or `cursor-agent login`).

## Run it (tests — no Cursor needed)

```powershell
# Host-package unit tests (mock + real-binary-guarded)
Invoke-Pester -Path tests/hosts/cursor.tests.ps1

# Multi-host detection matrix (now includes cursor)
Invoke-Pester -Path tests/integration/multi-host-detection.tests.ps1

# Manifest validity + FileList coverage
Invoke-Pester -Path tests/integration/host-coupling-firewall.tests.ps1
```

## Try the canonical scenario (US1 — launch in Cursor)

1. In a Specrew-initialized project, run:
   ```powershell
   specrew start --host cursor "Add a health-check endpoint"
   ```
   **Expected**: `cursor-agent` launches in non-interactive Agent mode in this workspace, reads `AGENTS.md` (the Specrew coordinator prompt), and begins the specify phase.
2. Confirm the agent has the lifecycle context:
   **Expected**: `.cursor/rules/*.mdc` files are present (skill catalog + crew roles) and the agent references the spec→plan→implement→review flow.
3. Run an autonomous launch:
   ```powershell
   specrew start --host cursor --allow-all "Add a health-check endpoint"
   ```
   **Expected**: invocation includes `--force --trust`; without `--allow-all` those flags are ABSENT.

## Verify the edge cases

- **Binary missing** (rename/remove `cursor-agent` from PATH): `specrew start --host cursor "x"` → actionable InstallGuidance pointing at <https://cursor.com/cli>, NOT a raw stack trace. (US1 scenario 2/3)
- **No slash-command palette**: typing `/speckit.` in Cursor does NOT autocomplete — this is expected (`HasUserSlashCommandSurface=$false`). The lifecycle is driven by the `AGENTS.md` coordinator prompt + auto-attached rules, not a command palette. (US2 reframed)
- **Onboard menu**: `specrew onboard` on a machine with Cursor installed lists `Cursor (AI Code Editor)` at MenuPriority 1.5 (between Claude and Codex). (US4)
- **Crew re-sync**: add a role to `.specrew/team/agents/`, re-run start → `.cursor/rules/<role>.mdc` appears with no duplicate. (US3)
