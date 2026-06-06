# Implementation Evidence: Iteration 001

**Feature**: 161-managed-skill-preserving-guard
**Created**: 2026-06-06 (T002)
**Status**: complete (iteration closed; PR-review safe-fix applied 2026-06-06 — see PR-Review Correction below)

## T001 — Boundary hygiene record

- Implementation baseline commit: `d7c23454`. Working tree clean except the
  two classified untracked generated outputs (`.cursor/rules` — host deploy
  surface, untracked on main; `.specrew/version-check-cache.json` —
  version-check cache, Feature 159 territory).
- Scope guard: no Feature 141, Feature 159, or Feature/Proposal 160 surfaces
  modified at baseline; re-verified at T009.

## Scenario Outcomes (T003, 2026-06-06) — PRE-FIX probe state, historical record

This table records the T003 investigation state BEFORE the fix (the repro that
drove the verdict). The FINAL post-fix state lives in the Conditional Fix
Evidence section below and in `quality/quality-evidence.md`. Two consecutive
full harness runs produced the identical OUTCOME-SUMMARY (SC-001 determinism
satisfied):

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
| Fix applied | **yes** — human released the stricter shape at the verdict stop; landed at `2a72d6bc` (+ `.specify` mirror parity); S4/S4g residual deferred per `F161-DEFER-001` |

## Conditional Fix Evidence (T006/T007, 2026-06-06)

- **Human release**: at the verdict boundary stop the human chose the
  **stricter shape** — fix only the generic-kind equality branch; leave the
  front-matter heuristic untouched.
- **T006 change** (`Test-IsManagedLegacySkillDirectory`, generic-kind branch):
  after the exact-equality check fails, recognize the pre-marker generic
  legacy signature — content (already past the front-matter check) whose first
  heading is `# <directory-name>` and which carries the structural
  `**Type**:` and `**Schema**: v1` lines. All four real v0.21-era artifacts
  match (verified against git history heads); anything else still falls
  through to preserve. Applied identically to the `.specify` mirror
  (ordinal-equality parity verified).
- **T007 pre/post evidence**: S7 (genuine v0.21-era content) observed
  `preserved-legacy-unmanaged-skill` pre-fix (recorded at commit `d5e53b89`)
  and `removed-legacy-managed-skill` post-fix; S7 promoted from neutral probe
  to regression assertion. New S8 guard: plain user content under a catalog
  generic name (no signature, no front matter) stays preserved. S2 user-
  authored content remained byte-identical in every post-fix run (no-loss
  invariant).
- **Accepted residual** (human decision, stricter shape): S4/S4g —
  stale-canonical content WITH front matter and no marker — remains frozen by
  the untouched front-matter heuristic. No released version ever produced that
  artifact in `.copilot/skills`; recorded here so the question stays closed
  rather than silently open.

## PR-Review Correction (post-closeout, 2026-06-06) — supersedes the generic legacy-signature fix above

At the Feature 161 PR, GitHub Copilot and Codex both raised a P1 data-loss finding
against the generic legacy-signature fix (T006/T007 above): the structural signature
(directory-name heading plus `**Type**`/`**Schema**` lines) cannot distinguish
Specrew's own drifted-legacy content from a user-edited copy of the same shape, so it
could classify a user-edited generic skill as managed and delete it — the exact data
loss this feature exists to prevent (spec: "genuinely user-authored skills must remain
preserved"). A case-insensitive `-eq` in the same branch also contradicted the ordinal
contract.

Maintainer decision (favor preserve over delete): the generic legacy-signature was
**removed**. A marker-less generic legacy skill is classified managed ONLY when its
decoded text exactly matches the current canonical template (the ordinal
`CurrentContent`/`LegacyContent` check); everything else is preserved. The redundant
case-insensitive `-eq` was dropped (the ordinal exact-match already covers it). Applied
identically to source and the `.specify` mirror (parity re-verified).

Consequences:

- **S7** (genuine v0.21-era generic content, drifted, marker-less) now resolves
  **preserved** (was removed under the brief signature fix) — the accepted
  "slightly reduced auto-recovery" tradeoff: heavily-drifted marker-less generic legacy
  skills stay stale-but-safe in `.copilot/skills` while active surfaces redeploy fresh
  (S6); re-deploy or manual cleanup recovers them without data-loss risk.
- **S3/S3g** (current-canonical, marker-less) still **removed** via exact-match (F-160
  recovery intact; `managed-runtime-sidecar.tests.ps1` Cases A–D still pass).
- New **S9** locks the data-loss case closed: signature-shaped generic content WITH a
  user edit resolves preserved and byte-identical.

Post-correction OUTCOME-SUMMARY (identical across two runs):

`S1=removed; S2=preserved-byte-identical; S2b=preserved; S3=removed; S3g=removed; S4=preserved-legacy-unmanaged-skill; S4g=preserved-legacy-unmanaged-skill; S5=idempotent; S6=active-roots-deployed; S7=preserved-legacy-unmanaged-skill; S8=preserved; S9=preserved-byte-identical`

Out of scope (logged to issue #1761): the slash legacy-signature (Namespace plus
Canonical-command lines) has the same theoretical flaw, but is effectively unreachable
(released slash skills carry front matter, preserved by the leading-`---` heuristic) and
is pre-existing F-160 code; not changed here.

## Regression Record (T008, 2026-06-06)

| Check | Result |
| --- | --- |
| `managed-skill-stuck-preserving.tests.ps1` ×2 (post-fix) | all assertions pass; identical OUTCOME-SUMMARY both runs: `S1=removed; S2=preserved-byte-identical; S2b=preserved; S3=removed; S3g=removed; S4=preserved-legacy-unmanaged-skill; S4g=preserved-legacy-unmanaged-skill; S5=idempotent; S6=active-roots-deployed; S7=removed-legacy-managed-skill; S8=preserved` |
| `managed-runtime-sidecar.tests.ps1` (F-160 fixture) | all assertions pass unchanged (Cases A–D + source/mirror parity) |
| `run-mechanical-checks.ps1` | zero findings (`quality/mechanical-findings.json`) |
| `validate-governance.ps1` | PASS for iteration 001; remaining WARNs are pre-existing repo-wide soft findings (F-048 dashboard note, legacy handoff-block format) |

## Scope-Guard Proof (T009)

- Files changed by this feature (vs `main`): `specs/161-managed-skill-preserving-guard/**`,
  `tests/integration/managed-skill-stuck-preserving.tests.ps1`,
  `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` + its
  `.specify` mirror (T006 only), `.specify/feature.json`, and
  boundary-sync/bootstrap runtime state (`.squad/**`, two managed agent
  surfaces refreshed by `specrew start`).
- No Feature 141, Feature 159, or Feature/Proposal 160 surface was edited
  (F-160 files were read and exercised as regression guards only).
- No release, no tag, no merge, no PR, no push to main — work pushed only to
  the feature branch `161-managed-skill-preserving-guard`.
