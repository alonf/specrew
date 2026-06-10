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

## Success-criteria assessment

The deployed artifacts contain actionable, grouped, dependency-aware guidance, demonstrated against a
sample C#/.NET "user-profile read endpoint" feature whose manifest selects DI, idiomatic-error-handling
(Result-type + ProblemDetails), authz (imperative ownership check), DTOs-between-services, and the C# net8
posture, with `comments-wisely` recorded as an exception and `dependency_policy.stance =
use-existing-no-new-dependency`.

- **SC-004 (the agent is actually guided at implement time)** -- PASS at the artifact + exercise level.
  The deployed `specrew-code-rules` skill resolves the active feature, reads the manifest + catalog,
  composes baseline + overlay, and surfaces it task-scoped; the sample manifest's decisions are concrete
  enough to shape the code.
- **SC-007 (the human faces a grouped checklist, not a wall)** -- PASS at the artifact level. The deployed
  conduct surfaces the baseline as a **summary (exceptions only)**, paces the consequential decision
  prompts, and shows applicability-filtered rules only in context -- so a code feature sees a handful of
  grouped decisions, not the 60-rule catalog.
- **SC-008 (a new dependency is never added without surfacing the decision)** -- PASS at the artifact
  level. The conduct presents "use existing project tools / no new dependency" FIRST; the skill instructs
  the agent not to silently add a package and to surface any new dependency as a decision.

## Residual (the feature-closeout gate)

The **definitive** SC-004 / SC-007 / SC-008 confirmation is an independent human running the **published**
`v0.35.0-beta.1` on a real host (per the beta-before-stable mandate: the maintainer manually validates the
installed prerelease). That cannot run before publish, which is gated to feature-closeout approval. This
report establishes that the deployed layout installs, wires up, and validates correctly, and that the
manifest-authoring path the corrected conduct mandates works end-to-end on the deployed module -- so the
human beta validation starts from a de-risked base.

**Verdict: PASS** for the deployed-module wiring + manifest-authoring gate; the human-on-published-beta
behavioral confirmation remains the feature-closeout step.
