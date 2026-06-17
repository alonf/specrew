# T008 Real-Host Antigravity Evidence

## Verdict

PASS, machine-local.

This evidence was captured on Alon's Windows workstation from a real
Antigravity CLI run. It is valid review evidence for F-184, but it is not
repo-reproducible evidence until the release gate repeats or preserves an
equivalent run from a clean packaged install.

## Environment

| Field | Value |
| --- | --- |
| Scratch project | `C:\Temp\f184-agy-20260617040442` |
| Host command | `agy` |
| Antigravity CLI | `1.0.8` |
| Specrew branch | `184-full-antigravity-refocus` |
| Specrew dev module | `C:\Dev\183-stability-quality-bundle` |
| Evidence label | machine-local |

## Pre-Fix Defect Found During T008

The first real-host run proved that Antigravity hooks fired, but the
host-spawned PowerShell child did not inherit the development-tree module
context. Provider child processes fell through to the stale installed Specrew
module path, so the hook could execute the wrong dispatcher/provider version.

The T008 repair changes `deploy-refocus-hooks.ps1` so the generated launcher
accepts `-ModulePath`, the generated Antigravity hook command bakes the current
valid `SPECREW_MODULE_PATH` into launcher invocations, and the launcher exports
that module path before dispatching the project hook.

Automated regression: `tests/integration/refocus-deploy.tests.ps1` now proves
the encoded Antigravity launcher command carries the development-tree
`SPECREW_MODULE_PATH` and that the launcher exports it before invoking the
project dispatcher.

## Hook Install And Command Shape

After reinstalling hooks from the development module with:

```powershell
specrew hooks install --host antigravity --force
```

the project `.agents/hooks.json` contained Specrew-owned `PreInvocation` and
`Stop` entries. Decoding the generated `PreInvocation` command produced:

```powershell
& 'C:/Users/alon.HOME/.specrew/specrew-hook-launch.ps1' -Event 'PreInvocation' -HostKind antigravity -ModulePath 'C:\Dev\183-stability-quality-bundle'
```

This proves the real Antigravity hook path used the current development module
instead of falling back to a stale installed module.

## Real-Host Runs

| Run | Command shape | Evidence |
| --- | --- | --- |
| Fresh hook-firing smoke | `agy --log-file .specrew/runtime/agy-print-after-modulepath.log --print ...` | `PreInvocation` executed multiple times, `Stop` executed, `.specrew/handover/session-handover.md` was written, and `.specrew/runtime/bootstrap-journal.jsonl` was appended. No `PROVIDER_FAILED` appeared after the module-path repair. |
| B3 anchor setup | `agy --conversation eba5a643-d9cc-44b4-94ae-8e55d03ca139 ...` with boundary `before-implement` | `.specrew/runtime/refocus-state-eba5a643-d9cc-44b4-94ae-8e55d03ca139.json` was created with `last_seen_boundary: before-implement` and no B3 journal entries. |
| B3 boundary crossing | same conversation after setting boundary `review-signoff` | The same state file advanced to `last_seen_boundary: review-signoff` and recorded exactly one journal entry with `trigger: b3`, `scope: general+boundary.retro`, `channel: hook`, `tokens: 863`, `outcome: injected`. |
| Unchanged-boundary resume | `agy -c ...` on the same conversation without changing the boundary | The conversation resumed as `eba5a643-d9cc-44b4-94ae-8e55d03ca139`; the state file still contained one B3 journal entry, proving no repeated injection on an ordinary unchanged-boundary turn. The transcript included the expected `B3_UNCHANGED_ONLY` response. |

Stable conversation id used for the controlled B3 proof:
`eba5a643-d9cc-44b4-94ae-8e55d03ca139`.

## Acceptance Criteria

| Requirement | Result | Evidence |
| --- | --- | --- |
| SC-002: exit/re-entry preserves identity and anchor | PASS | `agy --conversation` and `agy -c` both resumed `eba5a643-d9cc-44b4-94ae-8e55d03ca139`; the per-session state file remained keyed by that real id. |
| SC-003: B3 injects once on real boundary crossing and not ordinary turns | PASS | One B3 journal row was written after the boundary changed to `review-signoff`; unchanged resume did not add another row. |
| SC-005: bootstrap, Stop handover, and resume still work | PASS | Antigravity logs show `PreInvocation` and `Stop` hook execution; `session-handover.md` was updated by the `Stop` hook; resume used the same conversation id. |
| SC-009: split-guard proof remains true on real host | PASS | `PreInvocation` saw a fresh enough boundary cursor, exactly-once B3 was recorded through the existing dedupe/breaker state, and no broad host-model refactor was needed. |
| TG-004/TG-005: evidence is labeled and caveated | PASS | This artifact labels the evidence as machine-local and records the known caveats below. |
| TG-006/SC-010: release honesty remains intact | PASS | This does not promote stable support. The eventual release gate still must validate beta-before-stable and legacy upgrade/config migration before stable promotion. |

## Self-Marker Concurrency

The real-host bootstrap journal repeatedly recorded:

```json
{"host":"antigravity","concurrent_session":false,"concurrency_reason":"same-session","dedupe_key":"eba5a643-d9cc-44b4-94ae-8e55d03ca139"}
```

This proves same-session Antigravity marker entries are classified as
`same-session` and do not produce the prior false competing-session advisory.

Known bounded caveat: a first fresh marker can still warn if a previous marker
belongs to a different conversation. That is the intended real-competition
behavior, not the Edge 1 self-marker false-positive.

## Caveats

- Evidence is machine-local under `C:\Temp\f184-agy-20260617040442`; release
  validation must reproduce it from the repo or keep the machine-local label
  explicit.
- One earlier anchor run timed out after three minutes and Antigravity canceled
  its `Stop` hook, but the per-session anchor state was written correctly. Later
  `Stop` runs succeeded and updated handover.
- Antigravity logs include expected auth/cache noise before silent auth. Those
  lines are host auth noise and not Specrew provider failures.
- The controlled B3 fixture used a scratch feature path that did not exist, so
  the bootstrap journal recorded `mode: cleared-anchor` and findings about the
  fake feature. That is acceptable for the B3 state/journal proof and is not a
  parity claim about an active real feature.
- Antigravity logs do not expose raw `injectSteps` payload text. The B3 proof is
  therefore the persisted refocus state journal plus host behavior/resume, not a
  raw hook-stdout transcript.
