# Contract: v0.27.1 Bug-Fix CLI Behavior

## Scope

Contract for externally visible behavior changes in the 7-item patch bundle.

## Contract 1 — Root version aliases

- **Input**: `specrew --version` or `specrew -v`
- **Expected**:
  - Exit code `0`
  - Output parity with `specrew version` report
  - No unsupported-command error

## Contract 2 — Version warning correctness

- **Input**: `specrew version` in non-project and project contexts where version is resolvable
- **Expected**:
  - No false-positive `WARNING: Specrew version could not be determined.`
  - Warning appears only when both installed/baseline resolution are actually unknown

## Contract 3 — Start skill-catalog auto-repair

- **Input**: `specrew start` with one or more missing skill directories
- **Expected**:
  - Missing roots are re-created/redeployed before normal continuation
  - Start flow does not hard-stop on recoverable missing roots

## Contract 4 — Init deployment-gap handling (force and non-force)

- **Input**: `specrew init` and `specrew init -Force` with missing skill directories
- **Expected**:
  - Missing catalogs are treated as deployable gaps
  - Flow continues into deployment instead of false “already valid” early exit

## Contract 5 — Brownfield ownership classification

- **Input**: Brownfield init with:
  - `extensions/specrew-speckit/` present
  - existing `.squad/agents/`
- **Expected**:
  - `.squad/agents/` is canonical-source and not emitted as blocking conflict
  - Non-self-hosting repos continue to use standard conflict behavior

## Contract 6 — Update/redeployment documentation

- **Input**: Operator follows update guidance
- **Expected**:
  - Doc distinguishes normal/force/publisher-check update paths
  - Doc explicitly states redeploy trigger conditions (including missing skill catalog surfaces)
  - Doc includes stale review finding closure narrative without behavior inflation

## Verification Commands

- `pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1`
- `pwsh -NoProfile -File tests/integration/brownfield-conflict-handling.ps1`
- `pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1`
