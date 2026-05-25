# Contract: v0.27.1 Bug-Fix CLI Behavior

## Scope

Contract for externally visible behavior changes in the 7-item patch bundle.

## Contract 1 — Root version aliases

- **Input**: `specrew --version` or `specrew -v`
- **Iteration 001 status**: implemented
- **Expected**:
  - Exit code `0`
  - Output parity with `specrew version` report
  - No unsupported-command error
  - `--project-path` remains supported when routed through the alias

## Contract 2 — Version warning correctness

- **Input**: `specrew version` in non-project and project contexts where version is resolvable
- **Iteration 001 status**: implemented
- **Expected**:
  - No false-positive `WARNING: Specrew version could not be determined.`
  - Missing project baseline alone may leave compatibility `UNKNOWN`, but must not emit the version-undetermined warning when the installed Specrew version is known
  - The version-undetermined warning is reserved for cases where the installed Specrew version cannot be resolved

## Contract 3 — Start skill-catalog auto-repair

- **Input**: `specrew start` with one or more missing skill directories
- **Iteration 001 status**: implemented
- **Expected**:
  - Missing roots are re-created/redeployed before normal continuation
  - Start flow does not hard-stop on recoverable missing roots
  - Start reports the auto-repair attempt and successful completion

## Contract 4 — Init deployment-gap handling (force and non-force)

- **Input**: `specrew init` and `specrew init -Force` with missing skill directories
- **Iteration 001 status**: implemented
- **Expected**:
  - Missing catalogs are treated as deployable gaps
  - Flow continues into deployment instead of false “already valid” early exit
  - Successful init validates that required skill catalog roots exist before returning success

## Contract 5 — Brownfield ownership classification

- **Input**: Brownfield init with:
  - `extensions/specrew-speckit/` present
  - existing `.squad/agents/`
- **Iteration 001 status**: deferred to iteration 002
- **Expected**:
  - `.squad/agents/` is canonical-source and not emitted as blocking conflict
  - Non-self-hosting repos continue to use standard conflict behavior

## Contract 6 — Update/redeployment documentation

- **Input**: Operator follows update guidance
- **Iteration 001 status**: deferred to iteration 002
- **Expected**:
  - Doc distinguishes normal/force/publisher-check update paths
  - Doc explicitly states redeploy trigger conditions (including missing skill catalog surfaces)
  - Doc includes stale review finding closure narrative without behavior inflation

## Verification Commands

- `pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1`
- `pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1`

Iteration 002 adds the brownfield and operator-documentation verification commands.
