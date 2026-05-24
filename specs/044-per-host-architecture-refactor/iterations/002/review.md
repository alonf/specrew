# Iteration 002 Review: Deep-Analysis Bug-Fix Slice

**Feature**: F-044 | **Iteration**: 002 | **Date**: 2026-05-24

## Outcome

**APPROVED** — all 22 iter-001 findings closed; verification gates all green; advisor-flagged Squad CLI parse risk addressed via the sidecar marker pattern.

## Finding closure scoreboard

See [`scope.md`](./scope.md) for the finding-by-finding mapping. Summary:

| Tier | Count | Status |
|---|---|---|
| BUG | 3 (+1 cross-feature A-1) | ✅ All closed |
| WARN | 11 | ✅ 9 closed in this iteration; W-7 + W-8 deferred to on-main work (proposal/INDEX touches per "proposals to main only" rule) |
| NIT | 8 | ✅ 6 closed; N-4 false-positive (no-op); N-6 cosmetic-only (not changed); N-7 out-of-scope |
| Validator gap | 1 | ✅ Closed (advisor-caught) |

## Verification evidence

### Lint + parse

- PSScriptAnalyzer (Error severity): **0 violations** across 13 touched .ps1 files
- markdownlint: **0 violations** across 6 touched .md files
- Parse-check: **14/14 files OK** (`[Parser]::ParseFile` returns no diagnostics)

### Integration tests

| Test file | Result |
|---|---|
| `tests/integration/host-registry.tests.ps1` | 17 PASS (3 new asserts: InstallCrewRuntime contract slot, Install-<Kind>CrewRuntime existence per supported host, AgentDir presence per supported host) |
| `tests/integration/crew-bootstrap-contract.tests.ps1` (new) | 9 PASS (canonical seeding, AgentDir resolution per host, 4-host deploy, B-1 regression check, Claude YAML frontmatter, Codex TOML fields, Antigravity YAML frontmatter, sentinel-preserves-user-edits, sentinel-still-rewrites-managed-files) |
| `tests/integration/host-coupling-firewall.tests.ps1` | PASS (allow-list extended for new contract test) |
| `tests/integration/multi-host-launch-path.tests.ps1` | 21 PASS |
| `tests/integration/specrew-start-baseline-tracking.ps1` | PASS (A-1 regression closed) |
| `tests/integration/specrew-start-auto-continue-preservation.ps1` | PASS (sentinel-string update for F-040 surgery; A-1 regression closed) |
| `tests/integration/specrew-start-change-detector.ps1` | PASS (A-1 regression closed) |

### Manual verification (Copilot sidecar)

Reproduction script ran post-fix:

```text
PS> Initialize-SpecrewTeamCanonical -ProjectPath C:/Dev/Specrew/.scratch/copilot-sidecar-verify
PS> Invoke-HostHandler -Kind copilot -ContractFunction InstallCrewRuntime -Arguments @{ ProjectPath = ... }
PS> ls .squad/agents/reviewer/
charter.md                  3858 bytes
charter.md.specrew-managed   187 bytes

PS> diff <(head -3 .squad/agents/reviewer/charter.md) <(head -3 .specrew/team/agents/reviewer.md)
(no diff)
```

Confirms: charter.md is byte-identical to canonical; sidecar marker present. Squad CLI parse safety preserved.

## Form-vs-meaning verification

- **Form**: Every iter-001 finding has a corresponding code/doc change in `dcc4beb7`. Mapping in [`scope.md`](./scope.md).
- **Meaning**: The fixes work — verified empirically via the integration test suite + manual Copilot sidecar verification + advisor sanity-check before close.

## Sidecar pattern rationale

The advisor flagged that prepending `<!-- Specrew-managed -->` to Copilot's `charter.md` could break Squad CLI parsing. Two options were considered:

1. **Empirical verification** — run `specrew start --host copilot` against a test project and confirm Squad parses cleanly with the HTML comment header.
2. **Sidecar marker** — write `<path>.specrew-managed` alongside the file; keep `charter.md` byte-identical to canonical.

Option 2 was chosen because: (a) lower risk — Squad's parser never sees the marker; (b) cleaner conceptual model — "file IS the canonical content; sidecar marks ownership"; (c) extensible — any future host whose subagent format cannot tolerate comments uses the same pattern. The other 3 hosts (Claude / Codex / Antigravity) still use inline markers since YAML frontmatter and TOML headers tolerate comments natively.

## Sign-off

**APPROVED** for feature-closeout. F-044 closes via this iteration with no remaining known issues (modulo deferred follow-ups documented in iter-001 [`drift-log.md`](../001/drift-log.md) + spec [`out-of-scope section`](../../spec.md#out-of-scope-deferred-to-future-work)).
