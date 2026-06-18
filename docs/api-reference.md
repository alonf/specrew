# Specrew API Reference

## `Test-FormMeaningParity`

Location: `extensions/specrew-speckit/scripts/shared-governance.ps1`

```powershell
Test-FormMeaningParity -Declared <int> -Observed <int>
```

Returns a `PSCustomObject` with:

- `Declared`
- `Observed`
- `Gap`
- `Severity`

Severity contract:

- `error` when declared work is non-zero and observed changes are zero
- `warning` when declared and observed differ but both are non-zero
- `info` when declared and observed match, including legitimate empty iterations

This is the immutable v1 contract established by Feature 028 for Proposal 030
composition.

## `scaffold-reviewer-artifacts.ps1 -Force`

Location: `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`

```powershell
pwsh -NoProfile -File .\extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1 `
  -IterationDirectory .\specs\<feature>\iterations\<NNN> `
  -Force
```

Behavior:

- prompts before overwriting generated reviewer artifacts in interactive runs
- honors `-Confirm:$false` for non-interactive automation
- rewrites generated artifacts from the current git diff state

Keep reviewer notes and annotations in `review.md`. Generated reviewer artifacts
are intended to be safely replaceable.

## `specrew handover author`

Location: `scripts/specrew-handover.ps1`

```text
specrew handover author [--from <file>] [--feature <ref>] [--boundary <stage>] [--host <kind>]
<markdown> | specrew handover author --stdin
```

Persists the agent's **interpretive** handover sections — the open questions and
working hypothesis that no hook can author — into the rolling handover
(`.specrew/handover/session-handover.md`), so the next session or host inherits
authored context instead of placeholders.

Flags:

- `--from <file>` reads the markdown body from a file
- `--stdin` reads the body piped on stdin (only behind this explicit flag, so an
  inherited/empty pipe never blocks)
- `--feature <ref>`, `--boundary <stage>`, `--host <kind>` override the committed
  session state these would otherwise default to
- `--project-path <path>` selects the target project (defaults to the cwd)

Behavior:

- the body is markdown; each section is a `##` header, matched tolerantly
  (short or reordered headers map to the canonical section title)
- only authorable sections are written; unrecognized headers are reported and ignored
- the write goes through the same atomic writer the Stop hook uses, so it honors
  the clobber guard (a hook-captured boundary packet is preserved) and keeps the
  `session-handover.md.old` crash backup
- fail-open: a missing section or unresolved feature degrades to a best-effort
  write, never a throw

## `specrew hooks status | install | remove`

Location: `scripts/specrew-hooks.ps1`

```text
specrew hooks status  [--host <claude|codex|copilot|cursor|antigravity>]
specrew hooks install [--host <h>] [--force]
specrew hooks remove  [--host <h>]
```

The canonical, run-anywhere hook install / repair / diagnostic surface. Use this —
not the internal `deploy-refocus-hooks.ps1` — to provision, repair, or inspect the
Specrew hooks.

Flags:

- `--host <kind>` scopes the action to one hook-capable host; otherwise all
  hook-capable hosts (claude, codex, copilot, cursor, antigravity) are acted on
- `--force` forces a re-install that clears a recorded opt-out
- `--project-path <path>` selects the target project (defaults to the cwd)

Behavior:

- `status` reports per host: installed / missing / stale / opted-out / failed, plus
  a diagnostic when hooks are installed yet did not fire this session; it never
  records an opt-out and always exits zero
- `install` (bare) provisions missing/stale hosts but respects and reports recorded
  opt-outs; `install --host <h>` (or `--force`) clears that opt-out and re-installs
- `remove` removes Specrew hook entries and records an opt-out, so a later
  `specrew update` does not silently re-add them
- for Antigravity, hook config is project-local `.agents/hooks.json`; install
  adds/replaces only the Specrew-owned definition for `PreInvocation` and
  `Stop`, and remove preserves user-owned hook definitions
- it does not gate on project setup (so `status` works in a broken project) and is
  fail-open; the exit code is non-zero only when a host genuinely fails to deploy
  (an opt-out skip is not a failure)
