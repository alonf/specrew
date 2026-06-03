# Investigation Evidence: Iteration 001

**Feature**: 160-unix-resolver-sidecar-hardening
**Iteration**: 001
**Purpose**: Record, per suspected Feature-140 fast-follow, the attempted repro
path, the observed result, the disposition (`confirmed` / `not-confirmed` /
`environment-blocked`), any conditional source changes, and matching tests.
This is the authoritative no-blind-fix evidence record (FR-001, FR-005, FR-009).

**Host environment note**: This investigation runs on Windows
(`[IO.Path]::DirectorySeparatorChar` = `\`). No live macOS/Linux PowerShell host
is available in the workspace, so Unix behavior is proven via deterministic
cross-platform fixtures that exercise the exact path/marker semantics rather than
guessing (spec clarify 2026-06-03; hardening-gate error-handling concern).

---

## Finding 1: resolver-path (Proposal 160)

**Suspected issue**: The boundary-sync wrapper resolver builds candidate paths
with hardcoded backslash separators, which are not POSIX-safe, so on Unix the
dev-tree (Path 1) and installed-module (Path 2) probes can never match.

**Authoritative surfaces inspected (T003)**:

- `extensions/specrew-speckit/scripts/sync-boundary-state.ps1` (source) and its
  deployed mirror `.specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1`.
- `Specrew.psm1` module loader (L4-24) — uses single-segment
  `Join-Path -Path .. -ChildPath ..` and is already separator-safe; NOT in scope.

**Exact candidate expressions under test** (identical in source + mirror):

- Path 0 (L53): `Join-Path $env:SPECREW_MODULE_PATH 'scripts\internal\sync-boundary-state.ps1'`
- Path 1 (L65): `Join-Path $searchRoot 'scripts\internal\sync-boundary-state.ps1'`
- Path 1 (L66): `Test-Path -LiteralPath (Join-Path $searchRoot '.specrew\config.yml')`
- Path 2 (L89): `Join-Path $specrewModule.ModuleBase 'scripts\internal\sync-boundary-state.ps1'`

**Repro command (T004/T005)**: `pwsh -NoProfile -File tests/integration/unix-resolver-path-semantics.tests.ps1`

**Observed (T005)**: exit code 1. Semantic + behavioral sections PASS on Windows
(embedded-backslash ChildPath = 1 segment under POSIX `/`, 3 under Windows `\`;
multi-segment Join-Path resolves a real nested file; buggy form latent-resolves
on Windows). The SOURCE REGRESSION section FAILS (4 assertions): both
`extensions/specrew-speckit/scripts/sync-boundary-state.ps1` AND its `.specify`
mirror embed `scripts\internal\sync-boundary-state.ps1` and `.specrew\config.yml`
as single backslash ChildPaths. The repro-first test fails on the live source,
proving the bug is present (it will pass once the fix lands).

**Disposition**: **CONFIRMED**. The resolver builds non-POSIX-safe candidate
paths (Path 0/1/2 + the config probe) in both the source and the deployed mirror.
The fix is low-risk: multi-segment `Join-Path` / `[IO.Path]::Combine`, which is
identical behavior on Windows and correct on Unix. Conditional fix T010/T011
ACTIVE.

**Windows symptom root-cause (Proposal 160 Open Question / AC3)**: Observed live
during this iteration's own before-implement sync — the wrapper resolved the
INSTALLED module `C:\Users\alon.HOME\OneDrive\Documents\PowerShell\Modules\Specrew\0.31.0`
over the dev tree. Cause: `$env:SPECREW_MODULE_PATH` is SET to the installed
module path, so Path 0 wins by design. This is Proposal 160 hypothesis (a) — an
invocation-path expectation, NOT a Path-1 walk-up bug. (Backslashes resolve on
Windows, so Path 0's `Test-Path` succeeds there.)

---

## Finding 2: managed-refresh-sidecar (Proposal 161)

**Suspected issue**: `Test-IsManagedLegacySkillDirectory` uses a SKILL.md content
heuristic where a leading `---` (front matter) classifies a dir as user-edited →
preserve. Hypothesis: a Specrew-managed skill with no `.specrew-managed` marker
gets misclassified as user-edited and frozen (canonical refresh stops).

**Authoritative surfaces inspected (T006)**:

- `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`:
  - `Test-IsManagedLegacySkillDirectory` (L502-542): marker present → managed
    (L511-514); else SKILL.md heuristic where leading `---` → **not managed**
    (L526-528), then generic exact-match (L531) or legacy-signature match
    (L537-541).
  - Legacy cleanup path (L570-589): calls the classifier on
    `.copilot/skills/specrew-*` dirs; managed → removed, else
    `preserved-legacy-unmanaged-skill`.
  - Active-root deploy (L591-600): always writes BOTH `SKILL.md` and the
    `.specrew-managed` marker via `Set-ManagedFile` — so the active path is not
    the reachable trigger.
- `extensions/specrew-speckit/squad-templates/skills/*/SKILL.md`: ALL current
  canonical managed-skill templates start with `---` (front matter is REQUIRED by
  the F-044 iter-003 `skill-templates.tests.ps1` regression test).

**Reachability (T006)**: Because canonical content now starts with `---`, the
L526 front-matter check short-circuits to "not managed" BEFORE the
managed-signature check can run. Therefore the `.specrew-managed` marker is the
ONLY signal that can classify a current-canonical skill dir as managed. A
marker-less legacy `.copilot/skills/specrew-*` dir (e.g. deployed by an older
Specrew before markers, then carrying current front-matter content) is classified
as user-edited and preserved — even though the content is Specrew's own.

**Repro command (T007/T008)**: `pwsh -NoProfile -File tests/integration/managed-runtime-sidecar.tests.ps1`

**Observed (T008)**: exit code 1. Reachability proofs PASS (both generic
`specrew-capacity-planning` and slash `specrew-help` canonical content start with
`---`). **Case A FAILS for both kinds** (canonical content + NO marker classified
NOT-managed) — the misclassification. Case B (marker present → managed), Case C
(legacy signature, no front matter, no marker → managed via signature fallback),
and Case D (genuine user-edited front-matter content, no marker → preserved) all
PASS. The repro-first test fails precisely on the canonical-content-without-marker
case and will pass once the marker-provenance fix lands.

**Disposition**: **CONFIRMED**. A marker-less legacy skill dir holding Specrew's
own canonical content is misclassified as user-edited and frozen. The fix is
focused and data-loss-safe (see note below): recognize content that byte-matches
the definition's canonical content as managed, before the front-matter bail.
Cases C and D prove the signature fallback and the user-data guard stay intact.
Conditional fix T012/T013 ACTIVE.

**Fix-safety note (for T009/T012)**: The current preserve-on-ambiguity behavior
errs toward NOT deleting (safe against user-data loss). Any fix must keep
genuinely user-authored skills preserved; a safe formulation recognizes managed
content only by exact match against the definition's canonical content, so no
customized file is ever removed.

---

## T009 — No-Blind-Fix Gate

Verified before any source change:

- **Dispositions exist for both findings**: `resolver-path` = CONFIRMED (T005);
  `managed-refresh-sidecar` = CONFIRMED (T008).
- **No shipped behavior changed before the dispositions**: only repro tests
  (`tests/integration/unix-resolver-path-semantics.tests.ps1`,
  `tests/integration/managed-runtime-sidecar.tests.ps1`) and this evidence note
  were written. Both tests FAIL on the live source, proving the bugs before the
  fixes. Git history records the repro-first commit before the fix commit.
- **Conditional fix paths**:
  - Resolver fix T010/T011 → **ACTIVE** (confirmed).
  - Sidecar fix T012/T013 → **ACTIVE** (confirmed).
- No finding is not-confirmed or environment-blocked, so no fix task is skipped.
