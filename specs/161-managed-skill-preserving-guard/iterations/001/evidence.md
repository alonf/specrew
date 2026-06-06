# Implementation Evidence: Iteration 001

**Feature**: 161-managed-skill-preserving-guard
**Created**: 2026-06-06 (T002)
**Status**: in progress

## T001 — Boundary hygiene record

- Implementation baseline commit: `d7c23454`. Working tree clean except the
  two classified untracked generated outputs (`.cursor/rules` — host deploy
  surface, untracked on main; `.specrew/version-check-cache.json` —
  version-check cache, Feature 159 territory).
- Scope guard: no Feature 141, Feature 159, or Feature/Proposal 160 surfaces
  modified at baseline; re-verified at T009.

## Scenario Outcomes (T003, 2026-06-06) — harness `tests/integration/managed-skill-stuck-preserving.tests.ps1`

Two consecutive full harness runs produced the identical OUTCOME-SUMMARY (SC-001
determinism satisfied):

`S1=removed; S2=preserved-byte-identical; S2b=preserved; S3=removed; S3g=removed; S4=preserved-legacy-unmanaged-skill; S4g=preserved-legacy-unmanaged-skill; S5=idempotent; S6=active-roots-deployed; S7=preserved-legacy-unmanaged-skill`

| Scenario | Fixture | Expectation | Observed (both runs) |
| --- | --- | --- | --- |
| S1 | marker-present legacy dir | removed-legacy-managed-skill | removed ✓ |
| S2 | user-authored legacy dir, no marker | preserved + byte-identical | preserved, byte-identical ✓ (no-loss invariant held) |
| S2b | non-catalog `specrew-*` dir | preserved (no-definition path) | preserved ✓ |
| S3 | current-canonical (slash), no marker | removed (F-160 guard) | removed ✓ |
| S3g | current-canonical (generic), no marker | removed (F-160 guard) | removed ✓ |
| S4 | stale older-canonical (slash, front matter), no marker | PROBE | **preserved-legacy-unmanaged-skill** (frozen) |
| S4g | stale older-canonical (generic, front matter), no marker | PROBE | **preserved-legacy-unmanaged-skill** (frozen) |
| S5 | second consecutive deploy run | idempotent end-state | idempotent ✓ |
| S6 | active roots after deploy | SKILL.md + marker ×4 roots | deployed ✓ |
| S7 | REAL-HISTORICAL generic content (no front matter), no marker | PROBE | **preserved-legacy-unmanaged-skill** (frozen) |

## Reachability Findings (T004, 2026-06-06)

Git-history facts (all verified in this repo):

1. **`29a130b2` (F-021, 2026-05-18, shipped as v0.21.0)**: the deploy script wrote
   BOTH generic skills (top-level template `*.md` → `specrew-<basename>` dirs) and
   slash-command skills into `.copilot/skills` via `Set-ManagedFile` with **no
   `.specrew-managed` sidecar marker** (the marker mechanism did not exist yet).
   Canonical content at the time had **no front matter** (verified:
   `specrew-help/SKILL.md` started `# specrew-help` + Namespace/Canonical-command
   lines; `capacity-planning.md` started `# specrew-capacity-planning`).
2. **`534b7430` (F-024, 2026-05-20, shipped as v0.24.x)**: in one commit,
   `.copilot/skills` became legacy-cleanup-only, the four active roots became the
   deploy targets, the `.specrew-managed` marker was introduced (written to
   **active roots only**), and slash templates gained front matter. **No released
   version ever wrote markers into `.copilot/skills`.**
3. **`7f6536b2` (2026-05-23, ~v0.26.0) and later**: generic template content
   changed (current `capacity-planning.md` differs from the v0.21–0.23-era text;
   verified non-equal ordinal comparison).

Consequences per kind for a marker-less `.copilot/skills` dir left by
v0.21.0–v0.23.0 (released 2026-05-18..19):

- **Slash-command dirs**: old content matches the legacy-signature fallback
  (starts `# <dir>`, contains Namespace + Canonical-command lines) → correctly
  classified managed → removed. NOT stuck. (F-160 fixture Case C covers this.)
- **Generic dirs** (`specrew-capacity-planning`, `specrew-drift-check`,
  `specrew-iteration-resume`, `specrew-traceability-check`): old content fails
  the exact-match recovery (content drifted), has no front matter, and fails the
  generic-kind equality check (`$content -eq $Definition.LegacyContent`, which
  compares against the CURRENT template) → falls through → **preserved forever**.
  Demonstrated live by S7 with the genuine 3816929c-era content.

Reachable upgrade path: bootstrap with Specrew v0.21.0–v0.23.0 → upgrade to
v0.26.0+ → the four generic legacy dirs are frozen permanently as
"user-edited", remaining visible to the Copilot host and never cleaned.

## Verdict (T005, 2026-06-06) — gates the conditional fix tasks

| Field | Value |
| --- | --- |
| Outcome | **CONFIRMED** (misclassified AND reachable) |
| Code path | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1::Test-IsManagedLegacySkillDirectory` — two freezing branches: (a) **generic-kind equality fallback** (`$content -eq $Definition.LegacyContent`, compares stale content against the CURRENT template → false → fallthrough → preserved) — REACHABLE via the real v0.21–0.23 → v0.26+ upgrade path (S7); (b) **leading-`---` front-matter heuristic** — freezes any stale-canonical front-matter content (S4/S4g); no in-repo released version produced that artifact in `.copilot/skills`, but it is one canonical-content revision away for any future marker-less dir. |
| Reachability | Real released-version path confirmed (facts 1–3 above); affected artifact set = the four generic skill dirs in `.copilot/skills` |
| Fix applied | pending T006 release (human gate) |

## Conditional Fix Evidence — T006/T007

Unlock condition met (CONFIRMED); awaiting human release at the verdict boundary stop.

## Regression Record — filled by T008

Pending.
