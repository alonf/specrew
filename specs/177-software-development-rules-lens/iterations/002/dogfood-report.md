# T017 -- Deployed-module dogfood report (Feature 177, iteration 002)

**Date**: 2026-06-10
**Gate**: This is the load-bearing acceptance gate for F-177 (SC-004 / SC-007 / SC-008). It runs the
feature on the **deployed module layout** (FileList-only, version `0.35.0`), NOT the dev-tree fast-path,
so it catches deploy/resolve/wiring defects the in-repo unit suites cannot.

## Method

1. **Staged a deployed-layout module** from `Specrew.psd1` `FileList` into a clean scratch root
   (`<temp>/specrew-dogfood-*/Specrew`) -- the same copy set PSGallery would publish. `copied=271`,
   `missing-on-disk=0` (this also confirms the declared->disk FileList direction, complementing the
   in-repo source->declared `filelist-completeness` check).
2. **Resolved the staged module by path** via `SPECREW_MODULE_PATH`. `Import-Module <stage>\Specrew.psd1`
   reports version **0.35.0** -- the discriminator that proves the dogfood exercises the F-177 build, not
   the published `0.34.0-beta1`.
3. **Ran `specrew init`** from the staged CLI into a fresh empty project. Init succeeded.
4. **Inspected the fresh project** for the downstream deployment of the F-177 surfaces.
5. **Hand-authored an `implementation-rules.yml`** for a sample C#/.NET feature (the path the corrected
   conduct mandates -- author by hand against the schema, no PowerShell writer call) and validated it with
   the **deployed** `Test-SpecrewImplementationRulesManifest` + deployed schema + deployed catalog.

## Discriminator (not the published module)

`specrew version`'s "Installed version" line reads the machine-global installed module
(`0.34.0-beta1`) and does NOT honor `SPECREW_MODULE_PATH` -- so it is NOT a reliable discriminator here
(pre-existing version-command behavior, not an F-177 defect; noted as a minor follow-up). The reliable
discriminators used instead:

- `Import-Module <stage>\Specrew.psd1 -PassThru` -> **0.35.0**.
- Feature presence: the staged/init'd project carries the F-177 surfaces that `0.34.0` does not.

## Results -- deployment + wiring (objective)

| Check | Result |
| --- | --- |
| Deployed-layout stage builds from FileList (271 files, 0 missing) | PASS |
| Staged module resolves as version 0.35.0 (import-by-path) | PASS |
| `specrew init` succeeds from the deployed module | PASS |
| F-177 catalog (`code-rules.yml`, `code-implementation.md`, `implementation-rules.schema.json`) deployed into downstream `.specify/.../design-lenses` (catalog resolves downstream) | PASS |
| `specrew-code-rules` guidance skill deployed to all four host roots (`.claude`, `.github`, `.agents`, `.cursor`) | PASS |
| `specrew-design-workshop` deployed to all four host roots AND carries the F-177 code-implementation lens turn | PASS |
| Hand-authored manifest is schema-valid + catalog-valid on the **deployed** module | PASS |

## Defect surfaced AND fixed by this dogfood

A hand-authored `enforcement: [review]` (a **single-element** inline list) failed schema validation on the
deployed module: it projected to a JSON **string** instead of an **array**
(`Value is "string" but should be "array, null" at /selections/1/enforcement`).

- **Root cause**: `ConvertFrom-SpecrewCodeInlineList` returned `@(...)`, and PowerShell **unwraps a
  single-element array on function return** -- so `enforcement` was read back as the scalar `"review"`.
  (selections / custom_rules / dependency_policy.selected are unaffected: they are assigned via
  `.ToArray()`, not returned.) The unit round-trip only ever exercised a **two-element** list, so this
  slipped past unit-green -- exactly the class of gap the deployed dogfood exists to catch.
- **Fix**: the leading-comma idiom (`return ,$items`) in `code-implementation-lens.ps1`, which preserves
  array-ness through the function return.
- **Regression test**: added a single-element-enforcement round-trip + schema-validation assertion to
  `tests/unit/code-implementation-lens.tests.ps1` (would have failed before the fix; passes after).
- **Re-validated** on the deployed layout after the fix: **0 errors**.

## Success-criteria assessment -- behavioral SCs are NOT YET VERIFIED here

SC-004 / SC-007 / SC-008 are **behavioral** criteria (the agent is *actually* guided; the human is *not*
walled; a new dependency is *not* added without surfacing). Those cannot be established by inspecting the
deployed artifacts, nor by the author of those artifacts reading them and judging them followable -- that
is circular. This project has direct counter-evidence that correct conduct can still produce wrong
behavior: the testLenses8/11 in-band under-surfacing on the Claude host and the workshop "Approve+Delegate"
collapse both happened with the conduct authored correctly. So this report does **not** grade these PASS.

What this dogfood DID verify (artifact-level, against a sample C#/.NET "user-profile read endpoint" whose
manifest selects DI, idiomatic-error-handling = Result-type + ProblemDetails, authz = imperative ownership
check, DTOs-between-services, the C# net8 posture, `comments-wisely` as a recorded exception, and
`dependency_policy.stance = use-existing-no-new-dependency`):

- **SC-004 (agent actually guided)** -- NOT-YET-VERIFIED. Artifact-level: the deployed `specrew-code-rules`
  skill resolves the active feature, reads the manifest + catalog, composes baseline + overlay, and is
  worded to surface task-scoped; the sample manifest's decisions are concrete enough to shape code. Whether
  the agent actually follows it without re-pasting is the human-on-beta confirmation.
- **SC-007 (no rule wall)** -- NOT-YET-VERIFIED. Artifact-level: the deployed conduct is worded to surface
  the baseline as a **summary (exceptions only)**, pace the consequential decision prompts, and show
  applicability-filtered rules only in context -- structurally a handful of grouped decisions, not the
  60-rule catalog. Whether the agent actually paces vs dumps a wall on a given host is the human-on-beta
  confirmation (under-surfacing has regressed here before).
- **SC-008 (dependency stance honored)** -- NOT-YET-VERIFIED (most content-checkable of the three). The
  conduct presents "use existing project tools / no new dependency" FIRST and the skill instructs the agent
  not to silently add a package; "honored" still means the agent actually refrains, which is behavioral.

## Residual -- DEFERRED-WITH-GATE (recorded variance D-003, maintainer-approved 2026-06-10)

The behavioral SC-004 / SC-007 / SC-008 are NOT left as a floating "not-yet-verified" claim: they are a
**recorded, maintainer-approved variance** (`drift-log.md` **D-003**, accepted at the 2026-06-10
review-signoff). Their **definitive** confirmation is **DEFERRED** to an independent human running the
**published** `v0.35.0-beta.1` on a real host (the beta-before-stable mandate: the maintainer manually
validates the installed prerelease). **Gate**: that beta install-dogfood MUST confirm SC-004 / SC-007 /
SC-008 before the 0.35.0 line is promoted to stable. The defer is necessary because publish is gated to
feature-closeout approval, and because autonomous artifact inspection cannot establish behavior.

**Verdict: PASS** for the deployed-module **wiring + manifest-authoring** gate (everything in the
deployment table above plus the hand-authored-manifest validation, all objectively checked). The
**behavioral** SC-004 / SC-007 / SC-008 are **DEFERRED-WITH-GATE** to the published-beta human validation
at feature-closeout (variance D-003). This report's value is that the human beta validation starts from a
de-risked base: the deployed layout installs, wires up, and validates, and the manifest-authoring path the
corrected conduct mandates works end-to-end on the deployed module. The T012/T013 writer-call ->
hand-authored manifest change is the accepted variance **D-002**.

## D-003 RESOLVED -- behavioral SCs confirmed on the published beta (2026-06-11)

The deferred-with-gate behavioral criteria are now **CONFIRMED**. The gate this report set -- "the published
`v0.35.0-beta1` install-dogfood MUST confirm SC-004 / SC-007 / SC-008 before the 0.35.0 line is promoted to
stable" -- was met:

- **What was run**: the maintainer installed the published `v0.35.0-beta1` and built a real greenfield
  Casio F-91W watch on the **Claude host** through the full `specify -> implement` lifecycle, governed by the
  F-177 `specrew-code-rules` skill + the code-implementation lens.
- **How it was made conclusive (head-to-head)**: a side-by-side **ungoverned "vibe" control** (`casioWatch`)
  built the same watch with no Specrew governance, so the two builds could be diffed to prove governance
  *changed behavior* -- not merely that the governed output "looked fine".
- **SC-004 (agent actually guided)** -- CONFIRMED via a falsifiable probe: the human overrode the
  recommended functional-switch with the **State pattern**, and the governed code came back as per-mode
  `IModeState` classes (`TimeModeState` / `AlarmModeState` / `StopwatchModeState` / `SetModeState` behind an
  `IModeState` interface, `WatchReducer` delegating) -- the override was carried into the code, not ignored.
- **SC-007 (no rule wall)** -- CONFIRMED: the baseline surfaced as paced, applicability-filtered decisions,
  not the full catalog dumped as a wall; the human was able to drive the design and was not blocked.
- **SC-008 (dependency stance honored)** -- CONFIRMED: the governed build honored "use existing / surface
  before adding"; the ungoverned control silently grabbed `Plugin.Maui.Audio` with no surfacing.
- **Craft delta (the measurable governance value)**: the governed build shipped immutable `sealed record`
  state, a discriminated-union event type, named constants, derive-from-timestamp time math, and a **real
  unit-test suite (8 files, incl. a Reducer purity assertion)**; the ungoverned control had **0 tests**,
  mutable public fields, stringly-typed mode, and magic numbers. Honest calibration: a strong base model
  converged with the governed plan on **architecture** even ungoverned (both chose a core/shell split,
  drift-free time, the same audio package) -- so governance's measurable value landed on **craft discipline,
  tests, and decision-traceability**, which is where the two builds genuinely diverged.

On the strength of this gate the 0.33.0-0.35.0 line was promoted to **stable `v0.35.0`** on 2026-06-11.
This resolves drift **D-003** (`drift-log.md`, Status: resolved). The behavioral assessment above
**supersedes** the NOT-YET-VERIFIED grading recorded in the earlier sections of this report, which were
accurate at the time of the deployed-module dogfood (2026-06-10) and are retained for the audit trail.
