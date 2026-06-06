# Quality Evidence: Iteration 001

**Feature**: 161-managed-skill-preserving-guard
**Iteration**: 001
**Status**: runtime evidence recorded (post-fix, 2026-06-06)

## Stack Tooling Evidence (gate: `stack-tooling-evidence`)

| Surface | Selected Tooling | Command | Status |
| --- | --- | --- | --- |
| PowerShell deploy logic + harness | direct pwsh integration tests | `pwsh -File tests/integration/managed-skill-stuck-preserving.tests.ps1` (×2 for determinism) | executed — pass (22/22 assertions, identical OUTCOME-SUMMARY both runs) |
| F-160 regression guard | existing fixture | `pwsh -File tests/integration/managed-runtime-sidecar.tests.ps1` | executed — pass (all cases + mirror parity, unchanged) |
| Mechanical lenses | repo mechanical checks | `run-mechanical-checks.ps1 -FeaturePath ... -IterationPath ...` | executed — zero findings (`mechanical-findings.json`) |
| Governance | repo validator | `validate-governance.ps1 -ProjectPath .` | executed — PASS for iteration 001 (known repo-wide soft WARNs only) |
| Markdown | markdownlint | `npx markdownlint` on touched md files at each boundary commit | executed — clean at every boundary commit |
| CI | repo integration lane | explicit F-161 step added to `.github/workflows/specrew-ci.yml` | wired (runs on next CI execution) |

## Scenario Outcome Record (final post-fix state, 2026-06-06)

Pre-fix probe state (S4/S4g/S7 all frozen) is preserved in git history at
commit `d5e53b89` and in `../evidence.md`; this table is the FINAL state
after the human-released T006 fix (stricter shape).

| Scenario | Expectation | Observed Outcome (post-fix) | Run 1 | Run 2 |
| --- | --- | --- | --- | --- |
| S1 marker-present legacy dir | removed-legacy-managed-skill | removed | pass | pass |
| S2 user-authored legacy dir | preserved + byte-identical | preserved, byte-identical (no-loss invariant held pre- and post-fix) | pass | pass |
| S2b non-catalog `specrew-*` dir | preserved (no-definition path) | preserved | pass | pass |
| S3 current-canonical (slash), no marker | removed (F-160 guard) | removed | pass | pass |
| S3g current-canonical (generic), no marker | removed (F-160 guard) | removed | pass | pass |
| S4 stale-canonical (slash, front matter), no marker | frozen-by-design (accepted residual F161-DEFER-001) | preserved — matches the approved deferral | recorded | recorded |
| S4g stale-canonical (generic, front matter), no marker | frozen-by-design (accepted residual F161-DEFER-001) | preserved — matches the approved deferral | recorded | recorded |
| S5 second deploy run | idempotent / no-change | idempotent | pass | pass |
| S6 active roots | SKILL.md + marker in all 4 roots | deployed | pass | pass |
| S7 real-historical generic (v0.21-era), no marker | **removed** (F-161 fix; regression assertion) | **removed** — was frozen pre-fix (`d5e53b89`) | pass | pass |
| S8 plain user content under catalog generic name | preserved (fix's preserve side) | preserved | pass | pass |

Identical OUTCOME-SUMMARY across both full post-fix runs (SC-001 determinism):
`S1=removed; S2=preserved-byte-identical; S2b=preserved; S3=removed; S3g=removed; S4=preserved-legacy-unmanaged-skill; S4g=preserved-legacy-unmanaged-skill; S5=idempotent; S6=active-roots-deployed; S7=removed-legacy-managed-skill; S8=preserved`

## Reachability Findings (T004)

See the iteration evidence note (`../evidence.md`): released Specrew
v0.21.0–v0.23.0 (2026-05-18..19) deployed generic + slash skills into
`.copilot/skills` with no markers and no front matter; markers were never
written to that root by any version; generic template content drifted from
v0.26.0 (2026-05-23). Pre-fix, the four generic legacy dirs from that window
froze forever on upgrade; the F-161 fix cleans them. Slash dirs were always
recovered by the legacy-signature fallback and were never stuck.

## Verdict Record (T005; gated T006/T007)

| Field | Value |
| --- | --- |
| Outcome | **CONFIRMED** (misclassified AND reachable) |
| Code path | `deploy-squad-runtime.ps1::Test-IsManagedLegacySkillDirectory` — (a) generic-kind equality fallback vs CURRENT LegacyContent (reachable, S7); (b) leading-`---` front-matter heuristic (S4/S4g, synthetic) |
| Reachability | v0.21.0–v0.23.0 bootstrap → v0.26.0+ upgrade; artifacts: 4 generic skill dirs in `.copilot/skills` |
| Fix applied | **yes** — human released the stricter shape at the verdict stop (generic-kind branch only); landed at commit `2a72d6bc` with `.specify` mirror parity; S4/S4g residual deferred per `F161-DEFER-001` in `.squad\decisions.md` |

## Quality Lens Review (gate: `quality-lens-review`)

All three required lenses executed; records in `lenses/*.md`:

- `security-baseline@v1.0.0` — pass: no-loss invariant held in every state
  (S2/S8 byte-preserved pre-fix, post-fix, and across re-runs); harness
  sandbox-confined; fix cannot widen managed classification past the
  structural legacy signature.
- `robustness-baseline@v1.0.0` — pass: every classification decision observed
  from the deployment-action record; idempotency proven (S5); edge inputs
  (no-definition dir, plain non-signature content) exercised.
- `test-integrity@v1.0.0` — pass: repro-first ordering auditable in git
  (`d5e53b89` probe-frozen → `2a72d6bc` fix + assertion flip); S7 promoted
  only after the fix landed; F-160 fixture untouched and green.
