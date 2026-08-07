# T034a — Devin shared-engine seam inspection

**Task**: T034a (Option B: runs FIRST, before containment)
**Date**: 2026-07-11
**Purpose**: record the exact integration seam between the Devin crew's
co-review engine changes (branch `200-devin-cli-host`) and this iteration's
containment tasks (T013/T014/T017), so our work is DESIGNED to compose with
theirs rather than collide at the T034b landing checkpoint.
**Repo inspected (read-only)**: file:///C:/Dev/specrew-200-devin-cli-host

## Inspected commits (precursors on their branch)

| Commit | What it changes | Files / functions it OWNS |
| ------ | --------------- | ------------------------- |
| `a697cefe` | comma-split `--design-context-ref`; loud warn on an unresolvable ref | `specrew-review.ps1` (arg parse); `worktree-reviewer.ps1` (materializer warn) |
| `ec90e1b6` | (1) plumb `-DesignContextFiles` through the service; (2) restore 100755 exec bits after digest staging | `co-review-service.ps1` :: `Start-ContinuousCoReviewServiceRun`; `reviewed-state-digest.ps1` :: `Get-ContinuousCoReviewReviewedStateDigest` |
| `cca79708` | STRICT resolution: explicitly-supplied unresolved design-context refs FAIL before reviewer selection (`design-context-unresolved:`; status `unresolved_design_context`); omitted/empty keeps `DESIGN_CONTEXT_EMPTY` | `worktree-review-orchestrator.ps1` :: `Invoke-ContinuousCoReviewWorktreeReviewRun` (~line 437, at the design-context resolution point) |

Their T024 also adds a Devin **reviewer-catalog row** + authorization-parity
tests (`reviewer-host-catalog.ps1`); whether that lands in the agreed
incoming change set is a T034b decision (maintainer instruction 2026-07-11).

## The seam (where their code and ours meet)

| Engine file / function | Devin OWNS | Our task TOUCHES | Composition rule |
| ---------------------- | ---------- | ---------------- | ---------------- |
| `worktree-review-orchestrator.ps1` :: `Invoke-ContinuousCoReviewWorktreeReviewRun` | strict design-context resolution block (~437), before reviewer selection | **T013** (relocate the worktree OUTSIDE origin root) | Relocation changes WHERE files materialize, not the resolution LOGIC. Their strict block resolves `DesignContextFiles` relative to `$RepoRoot` (origin) — correct even after relocation (context is resolved from origin, materialized into the temp worktree). Keep their block intact; insert relocation around materialization, not through the resolution. |
| `worktree-reviewer.ps1` :: reviewer-context assembly + design-ref warn | the a697cefe loud-warn on an unresolvable ref | **T014** (strip/relativize origin-absolute paths from reviewer context) | Our path-hygiene strip must RELATIVIZE, never REMOVE, the design-context refs their plumbing supplies — they are legitimate reviewer context. Coordinate the two edits in the same function; do not regress their comma-split/warn. |
| `reviewed-state-digest.ps1` :: `Get-ContinuousCoReviewReviewedStateDigest` | exec-bit restoration (guarded to `core.filemode=false`) | **T017** (ONE machinery list; digest strip == worktree strip) | Their exec-bit restore RESOLVES our DRIFT-198-I001-001 (phantom mode-diffs on `bin/*`, `install.sh`) — we WANT it; reuse, do not reimplement. Our machinery-list strip (excluding `specrew-*` machinery) is orthogonal to the exec-bit restore; keep both. |
| `co-review-service.ps1` :: `Start-ContinuousCoReviewServiceRun` | the `-DesignContextFiles` param + forwarding | **T013** (relocation may thread through the service run) | Consume their param signature; do not change its shape. |
| `specrew-review.ps1` :: `--design-context-ref` parse | comma-split multi-value | (none this iteration) | Untouched by our tasks; no conflict. |

## Load-bearing behavior our tasks MUST preserve (never soften)

- **Strict design-context resolution (`cca79708`)**: explicitly-supplied
  unresolved refs FAIL before reviewer selection — no design-blind pass.
  T034 preserves it; paired tests mirror their 7f/7g (mixed valid+invalid,
  all-invalid → reviewer never invoked). Recorded in the iteration-003
  hardening gate error-handling row.
- **Exec-bit restoration (`ec90e1b6`)**: reuse it — it is the fix for our
  own DRIFT-198-I001-001 materialization class. T017 verifies against it.

## Conflict doctrine at T034b (maintainer-typed, binding)

- **MECHANICAL** conflicts (line/rename/formatting, plumbing shape) resolve
  toward the Devin-owned design-context seam; ours adapts.
- **SEMANTIC** conflicts — anything that would change containment,
  authorization, evidence integrity, or fail-closed behavior — ESCALATE to
  the maintainer; never auto-resolved. Concrete watch items:
  - T013 relocation changing how `$RepoRoot`-vs-worktree paths resolve such
    that their strict design-context check could misfire → escalate.
  - T017 strip touching the digest's exec-bit restore in a way that alters
    fail-closed behavior → escalate.

## Devin authorization / runtime constraints (maintainer instruction 2026-07-11)

- Devin is logged in (another window) and AVAILABLE for LATER compatibility
  validation only. Do NOT wire Devin independently; do NOT run it from the
  governed worktree (its hooks self-bootstrap and mutate lifecycle state).
- The bounded live Devin compatibility review is authorized ONLY after the
  T034b integration is verified, and runs FROM A SCRATCH DIRECTORY under an
  explicit authorization at that time.
- Do NOT alter or overwrite `.specrew/reviewer-hosts.json` while handling
  T034a (its current changes stand untouched). Any Devin catalog row is a
  T034b concern, decided then.

## Outcome

Seam recorded; T013/T014/T017 will be implemented to compose with the above.
T034b (cherry-pick + strict-preserve + regression set + live-round compat +
exec-bit verification vs DRIFT-198-I001-001, plus the catalog row if in the
agreed set) executes at the landing checkpoint when the final Feature 200
commits are available.
