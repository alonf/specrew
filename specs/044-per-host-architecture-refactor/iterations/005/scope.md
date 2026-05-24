# Iteration 005 Scope

**Feature**: F-044 | **Iteration**: 005 — Antigravity Launch Fix + v0.27.0 Release Prep (LIVE-TRACKED)

## User-surfaced concerns addressed

1. **Antigravity launch shape wrong** — user's iter-004 dogfood produced `flags provided but not defined: -output-format` from agy CLI. Closed by T001.
2. **Version bump to v0.27.0** — user selected option (a) status-quo bump per drift analysis. Closed by T002.
3. **Tests for iter-003 / iter-004 changes** — surface had no automated regression tests; smoke tests in `.scratch/`. Closed by T003 + T004 + T005.
4. **Doc audit + Crew-language sweep** — README, getting-started, user-guide had stale 3-host language + missing F-043/F-044 references. Closed by T006.
5. **Pre-PR readiness** — bundle is ready when antigravity launches + tests cover changes + docs reflect shipped state. Closed by T008.

## Task → user concern mapping

| Task | Closes | Files |
| ---- | ------ | ----- |
| T001 | Concern 1 (Antigravity launch) | `hosts/antigravity/handlers.ps1` |
| T002 | Concern 2 (version bump) | `Specrew.psd1`, `CHANGELOG.md` |
| T003 | Concern 3 (UX tests) | `tests/integration/host-detection-ux.tests.ps1` (new) |
| T004 | Concern 3 (bootstrap-message tests) | `tests/integration/post-bootstrap-output.tests.ps1` (new) |
| T005 | Concern 3 (skill-template tests) | `tests/integration/skill-templates.tests.ps1` (new) |
| T006 | Concern 4 (doc audit) | `README.md`, `docs/getting-started.md`, `docs/user-guide.md` |
| T007 | Concern 4 (INDEX) — deferred | `proposals/INDEX.md` (on-main post-merge chore) |
| T008 | Concern 5 (verification) | (verification only) |

## Antigravity launch shape — verified canonical

Per user's pasted `agy --help` output:

```text
Usage of agy.exe:
  --add-dir                       Add a directory to the workspace (repeatable)
  -i                              Short alias for --prompt-interactive
  -p                              Short alias for --print
  --dangerously-skip-permissions  Auto-approve all tool permission requests
  --prompt-interactive            Run an initial prompt interactively and continue the session
```

The shape Specrew now generates: `agy -i '<prompt>' --add-dir '<project>' [--dangerously-skip-permissions]`

Matches Claude's invocation convention (which uses the same `--dangerously-skip-permissions` flag name). The earlier antigravity-followup spec FR-005 reference (`-p ... --output-format json --cwd`) was wrong; will need a small-fix slice to update that spec text OR rely on iter-005 as the canonical now.

## Out of iter-005 scope

- **Proposal 108 + F-043/F-044 entries in `proposals/INDEX.md`**: deferred to on-main post-merge chore per "proposals always commit to main" policy.
- **Antigravity-followup spec FR-005 amendment**: out-of-scope; tracked as follow-up small-fix slice.
- **Versioning-policy validator** (Test-VersionAlignedToFeature): tracked as candidate proposal for restoring feature-aligned minor versioning.
- **Tests for closeout-dashboard auto-render**: optional dashboard.md artifact for the 5 backfilled iterations; tracked but not in iter-005 scope.

## Verification

Empirically verified — all 7 host-related integration tests pass:
- `host-registry.tests.ps1`
- `crew-bootstrap-contract.tests.ps1`
- `host-coupling-firewall.tests.ps1`
- `multi-host-launch-path.tests.ps1`
- `host-detection-ux.tests.ps1` (new)
- `post-bootstrap-output.tests.ps1` (new)
- `skill-templates.tests.ps1` (new)
