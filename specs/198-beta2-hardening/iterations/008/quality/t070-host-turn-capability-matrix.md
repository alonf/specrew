# T070 Host Turn-Start Capability Matrix

**Recorded**: 2026-07-19
**Scope**: conformance turn-baseline adapters
**Core**: `extensions/specrew-speckit/scripts/conformance-turn-delta.ps1`

The host-independent core owns the live Git `HEAD`, dirty-user-path status and content fingerprints,
owner-scoped `turn-baseline.json`, delta calculation, and packet-demand decision. Host manifests own only the
translation from a genuine native prompt boundary to the core's `UserPromptSubmit` or `PreInvocation` event.

| Host | Capability | Native event | Dispatcher event | Production registration | Evidence |
| --- | --- | --- | --- | --- | --- |
| Claude | exact | `UserPromptSubmit` | `UserPromptSubmit` | `.claude/settings.local.json` event-map hook | Anthropic documents that the event runs whenever the user submits a prompt, before Claude processes it; the deployment fixture executes the real manifest/deployer path. |
| Codex | exact | `UserPromptSubmit` | `UserPromptSubmit` | `~/.codex/hooks.json` event-map hook | Existing live-verified binding retained; manifest/deployer and dispatcher fixtures prove the registered path. |
| GitHub Copilot CLI | exact | `userPromptSubmitted` | `UserPromptSubmit` | `~/.copilot/hooks/specrew-refocus.json` dual-shell entry | GitHub's hook reference identifies `userPromptSubmitted` / `UserPromptSubmit` as the user-prompt hook; the deployment fixture proves both generated shell entries reach the normalized dispatcher event. |
| Cursor Agent CLI | exact | `beforeSubmitPrompt` | `UserPromptSubmit` | `~/.cursor/hooks.json` command entry | Cursor's official hook catalog/changelog exposes `beforeSubmitPrompt`; the deployment fixture proves the generated command reaches the normalized dispatcher event. |
| Antigravity | exact | `PreInvocation` | `PreInvocation` | project `.agents/hooks.json` named definition | Existing verified project-hook binding retained; the real encoded launcher fixture proves `PreInvocation` reaches the dispatcher. |

Official capability references:

- Claude hooks: https://code.claude.com/docs/en/hooks
- GitHub Copilot hooks: https://docs.github.com/en/copilot/reference/hooks-reference
- Cursor prompt hook: https://cursor.com/marketplace/hooks/beforesubmitprompt
- Cursor CLI hook coverage: https://cursor.com/changelog/page/9

## Capability-Absent Contract

No currently supported host is declared capability-absent. The core nevertheless fails honestly when a prompt
baseline is absent, corrupt, or not refreshed by a stale host installation:

1. `SessionStart` always captures a new baseline from live Git state and never consumes rolling handover dirt.
2. A discharged `Stop` snapshot is marked degraded until the next genuine prompt event replaces it.
3. Owner-attribution suppression remains active.
4. The cooperative display says `CURRENTLY DIRTY IN THE WORKTREE (...)`; degraded output never says `this turn`.

A future host may use `TurnStartCapability.Mode = capability-absent` only after its real host surface is checked
and no per-prompt event can be demonstrated. Such an adapter must retain the four degraded behaviors above.

## Verification

- `tests/unit/conformance-turn-delta.tests.ps1`: deterministic live-Git core fixtures, including stale dirt,
  same-path fingerprints, consecutive turns, commit-only progress, degraded mode, and packet-demand suppression.
- `tests/integration/refocus-deploy.tests.ps1`: production manifest/deployer registrations for all five hosts.
- `tests/integration/host-registry.tests.ps1`: closed capability declaration and exactly-one registration mapping.
- `tests/integration/conformance-detection.tests.ps1`: real provider-path prompt capture, exact/degraded messages,
  stale-handover read-only session, and concurrent owner isolation.
- Full Feature 198 registry: 73/73 suites passed locally in 740.4 seconds on 2026-07-19.
