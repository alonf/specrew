# Quickstart: Release Pipeline Hardening + Substantive Intake Slice

**Feature**: `049-pipeline-hardening-intake`  
**Last verified**: 2026-05-27

## Run it

To execute the pre-publish Docker E2E layout harness locally, run:

```powershell
# Build and run the local E2E verification container
docker build -t specrew-publish-test -f ./tests/Dockerfile.publish-test .
docker run --rm specrew-publish-test
```

To try the new `/speckit.specify` persona intake, run:

```powershell
# Run specify with a targeted persona
pwsh -File ./.specify/scripts/powershell/create-new-feature.ps1 -ShortName test-feature -Json "test"
# Run interactive specify (Mode C)
specrew specify --persona product-manager --interactive
```

---

## Try the canonical scenario

### Scenario 1: Pre-Publish Layout Verification Passes

1. Run `docker build` on the package candidate.
   - **Expected result**: PowerShell container pulls base LTS, installs `v0.27.6`, bootstraps, and successfully verifies all `FileList` items.
2. The E2E test completes and logs `PASS: FileList integrity check passed.`

### Scenario 2: Specify Persona Intake Mode C (PM Persona)

1. Run `specrew specify --persona product-manager --interactive`.
   - **Expected result**: The console displays the Product Manager introduction and presents numbered categories.
2. Select target MVP scope and enter text.
3. Select `"I don't know, you decide"` on database storage.
   - **Expected result**: The agent runs a quick domain-research scan and auto-selects the appropriate lightweight option.
4. The spec is successfully generated as `specs/test-feature/spec.md`.

---

## Verify the edge cases

- **FileList Omission Block**: Intentionally delete a required file (e.g. `docs/user-guide.md`) from the package candidate folder before running the Docker harness.
  - **Expected result**: The harness fails, prints `FAIL: FileList item docs/user-guide.md is missing on disk!`, and exits with code `1` (blocking release).
- **Version Manifest Drift Check (Prop 134)**: Modify `.specrew/config.yml` version to `0.27.8` while leaving `Specrew.psd1` at `0.27.7`, then run the harness.
  - **Expected result**: The harness fails immediately and logs `FAIL: Version mismatch detected between config (0.27.8) and manifest (0.27.7)`.
