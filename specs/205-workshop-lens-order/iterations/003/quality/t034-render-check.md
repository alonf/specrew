# T034: Recorded render check of the grouped agenda (FR-032)

**Run**: 2026-11-16, local, by the crew in this session (no human turns were needed)
**Code**: `8717afc0` (T027 to T033 done), the deployed copies refreshed in T033

## Setup, and the home folder

- Scratch projects under this session's temp folder, built by a script: `git init`, then
  `deploy-speckit-extension.ps1` and `deploy-squad-runtime.ps1` from the worktree source, and a minimal
  `.specrew/config.yml`. No `specrew init`, `start` or `update`, and no hook deployer. Removed afterwards by
  their exact paths.
- A feature awaiting agenda confirmation: the deployed controller initializer, one product-domain typed-reply
  receipt, and the two product-domain records.
- Home hook files: matched the known-good set before and after each of the two runs (0 differences).

## What was rendered

A sample agenda with lenses in all three groups, rendered by the **deployed** `confirm-workshop-agenda.ps1
-RenderOnly` in a child `pwsh`, once with this console's encoding (`utf-8`) and once with a Latin-1 console:

```text
Workshop agenda

Selected lenses:

🟦 Problem space
- requirements-nfr (medium): Choose the timeouts, the error output and the exit codes.

🟪 Both spaces
- data-storage (light): Choose where the report history is kept and for how long.
- devops-operations (light): Choose how the tool is released and run on a schedule.

🟧 Solution space
- architecture-core (medium): Choose the processing pipeline and its concurrency boundary.
- code-implementation (medium): Choose the implementation rules and the dependency stance.

Skipped lenses:
- ui-ux: The tool is terminal-only.
- security-compliance: It handles no credentials or personal data.
- integration-api: It calls no outside service.
- component-design: The pipeline already sets the component boundary.
- observability-resilience: A local tool with no long-running service.

Does this complete selected + skipped agenda look right? Reply with confirm or tell me what to change.
```

- **Both renders equal the stored `canonical_text`**, so the block reaches the reader as UTF-8 even from a console
  that is not UTF-8.
- **Heading bytes** (UTF-8): `F0 9F 9F A6` (U+1F7E6, problem), `F0 9F 9F AA` (U+1F7EA, both), `F0 9F 9F A7`
  (U+1F7E7, solution).
- **The binding**: the real conformance provider (deployed copy, unedited) read a transcript whose last assistant
  message was an introduction plus the Latin-1 render pasted unchanged. It recorded the agenda question (phase
  `agenda`) with an agenda digest equal to the proposal's, and `Test-SpecrewWorkshopAgendaVisibleInText` found
  the block. The confirmation would bind.
- **One harness artefact**: the provider also returned a stop-block saying the turn "touched work outside the
  workshop notes" (`agenda.json` and two untracked scripts in the scratch git tree). It comes from the scratch
  project's untracked files, not from the agenda; it does not change the binding. Not a finding.

## What the human sees

- **In this Claude Code terminal**: the crew can check the bytes, not how the terminal draws them. The same block is
  shown to the maintainer in the review packet, so they see it on this machine; the design expects colour emoji two
  cells wide before each label, and that is theirs to confirm.
- **On a host that cannot draw them**: the label still reads "Problem space", "Both spaces" or "Solution space"; no
  meaning is lost.
