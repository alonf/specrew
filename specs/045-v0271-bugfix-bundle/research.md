# Phase 0 Research — v0.27.1 Bug-Fix Bundle

## Decision 1: Top-level version aliases must be handled at CLI entrypoint level

- **Decision**: Add explicit top-level handling for `--version` and `-v` in `scripts/specrew.ps1` with behavior parity to the `version` subcommand.
- **Rationale**: Current top-level command routing only switches on named subcommands; alias support belongs in the root parser for deterministic UX parity.
- **Alternatives considered**:
  - Handle aliases only inside `scripts/specrew-version.ps1` (rejected: alias never reaches that script today).
  - Document current behavior without code fix (rejected: does not satisfy FR-001 / SC-001).

## Decision 2: False-positive version warning must be emitted only on true unknown state

- **Decision**: Gate “version could not be determined” warning in `scripts/specrew-version.ps1` strictly behind unknown-state checks.
- **Rationale**: Warning noise in deterministic contexts undermines operator trust and violates FR-002 / SC-002.
- **Alternatives considered**:
  - Keep warning as-is and clarify docs (rejected: preserves regression).
  - Remove warning entirely (rejected: hides real unknown-state failures).

## Decision 3: Missing skill-catalog directories are recoverable gaps, not hard-stop state

- **Decision**: Treat missing `.claude/skills`, `.github/skills`, `.agents/skills` as auto-repairable both in `specrew start` and `specrew init` flows.
- **Rationale**: This aligns runtime behavior with deployment intent and directly addresses FR-004 and FR-005.
- **Alternatives considered**:
  - Keep current warning-only behavior in start (rejected: violates auto-repair requirement).
  - Require manual `specrew init` rerun every time (rejected: operator friction + patch objective miss).

## Decision 4: Brownfield ownership requires explicit self-hosting signal override

- **Decision**: In brownfield conflict logic, classify existing `.squad/agents/` as canonical when `extensions/specrew-speckit/` exists.
- **Rationale**: Self-hosting repos intentionally own these paths and should not be blocked by conflict detection (FR-006 / SC-004).
- **Alternatives considered**:
  - Keep generic conflict rules for all repos (rejected: blocks legitimate self-hosting setups).
  - Add manual bypass flag only (rejected: unsafe and non-default).

## Decision 5: Patch evidence must be command-backed and artifact-backed

- **Decision**: Use concrete regression commands and quality artifacts:
  - `pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1`
  - `pwsh -NoProfile -File tests/integration/brownfield-conflict-handling.ps1`
  - `pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1`
  - `pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 -ProjectPath C:/Dev/Specrew -IterationPath specs/045-v0271-bugfix-bundle/iterations/001`
- **Rationale**: Meets SC-006 and before-plan quality evidence expectations with deterministic proof.
- **Alternatives considered**:
  - Ad-hoc manual checks only (rejected: insufficient auditability).
  - Full CI lane only (rejected: slower and less targeted for patch iteration).

## Decision 6: Update guidance is part of patch closure, not optional follow-up

- **Decision**: Update operator-facing docs to explicitly cover update path selection, `-Force`/publisher-check semantics, and re-deploy triggers for missing skill-catalog surfaces.
- **Rationale**: FR-007 and SC-005 require actionable operator clarity, not only code fixes.
- **Alternatives considered**:
  - Defer docs to future release note cycle (rejected: leaves patch operationally incomplete).
