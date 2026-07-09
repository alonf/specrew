# Feature 197 Iteration 002 Review

**Reviewer**: Reviewer
**Requested by**: Alon Fliess
**Review type**: Human-led Proposal 145 pass for Iteration 002 repair
**Prior rejected range**: `e54cb30cf2d8a6b796572a82e82e3eb4258f47b2..f279301eb73e60012c100cd34d5339f59f6a363e`
**Repair commit reviewed**: `a9b358eb65489a3d6809879f6209d39653820f4f`
**Implementation tip reviewed**: `a9b358eb65489a3d6809879f6209d39653820f4f`
**Verdict**: **APPROVED FOR REVIEW-SIGNOFF READINESS**

## Verdict rationale

Fresh review resolves prior blocking finding `B-197-I002-001`.

The repair commit fixes the failed Windows Codex live path by resolving `codex.ps1`
through a PowerShell `-File` argv invocation, keeps the logical provider argv
summary as `codex exec --sandbox read-only`, captures Codex
`--output-last-message`, and injects the concrete `FindingsResult.v1` schema plus
JSON-only/no-extra-properties instructions into the adapter-bound prompt.

The repaired path is implemented, enforced, observable, and documented in
Iteration 002 state evidence. It remains bounded to the Iteration 002 repair
diff and the existing continuous-co-review runtime path; it does not advance
retro, iteration closeout, feature closeout, or manual SC-012.

## Evidence inspected

- `.squad/agents/reviewer/history.md`
- `.squad/decisions.md` Feature 197 / Proposal 145 relevant entries
- `specs/197-continuous-co-review/spec.md`
- `specs/197-continuous-co-review/tasks.md`
- `specs/197-continuous-co-review/iterations/002/plan.md`
- `specs/197-continuous-co-review/iterations/002/state.md`
- Prior Iteration 002 review rejection evidence in this artifact
- Repair commit `a9b358eb65489a3d6809879f6209d39653820f4f`
- `scripts/internal/continuous-co-review/review-prompt-composer.ps1`
- `scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1`
- `scripts/internal/continuous-co-review/reviewer-host-adapter-codex-exec.ps1`
- `tests/continuous-co-review/unit/review-prompt-composer.Tests.ps1`
- `tests/continuous-co-review/unit/reviewer-host-adapter-codex-exec.Tests.ps1`
- Focused related runtime suites under `tests/continuous-co-review/unit/`

## Validation evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Focused deterministic repair Pester | PASS | `review-prompt-composer`, `reviewer-host-adapter-codex-exec`, `workspace-mutation-guard`, `review-prompt-adapter-seam`, `reviewer-execution-engine`, and `reviewer-host-adapter-claude-prompt` passed `24/24` with repo-local `TEMP`/`TMP`. |
| Windows `.ps1`/shim command resolution | PASS | Deterministic test created a real `codex.ps1` shim on `PATH` and exercised the adapter default process path, stdin delivery, `--sandbox read-only`, `--output-last-message`, and schema-valid `FindingsResult.v1` normalization. |
| Unix/direct-command preservation | PASS | `Resolve-ContinuousCoReviewAdapterProcessCommand` returns the original executable and argument list unchanged off Windows, and also leaves Windows non-`.ps1` commands unchanged. |
| Codex read-only posture | PASS | Deterministic and live invocations recorded `codex exec --sandbox read-only --output-last-message reviewer-last-message.json`; `readonly_mode_supported=True`; `readonly_mode_detail=codex exec --sandbox read-only`. |
| Mutation guard | PASS | Focused mutation guard tests still passed source, Specrew-state, and Git mutation invalidation; full live Codex smoke recorded `mutation_guard_mutated=False`. |
| Prompt contract injection | PASS | Runtime prompt probe for the repair diff produced `ReviewRequest.v2`, output contract `FindingsResult.v1`, prompt chars `218926`, and confirmed schema heading, schema `additionalProperties: false`, `finding_id` instruction, no-extra-properties instruction, and JSON-only/no-Markdown instruction. |
| Repair-diff live smoke through implemented path | PASS | Codex smoke on `a9b358eb^..a9b358eb`: `kind=findings-result`, `FindingsResult.v1` present, `status=no_findings`, exit code `0`, changed paths `5`, diff chars `15869`, gate state `pass`. |
| Full Iteration 002 live dogfood through implemented path | PASS | Codex smoke against baseline `e54cb30cf2d8a6b796572a82e82e3eb4258f47b2` with 300s bound: `kind=findings-result`, `FindingsResult.v1` present, `status=findings`, finding count `2`, exit code `0`, changed paths `26`, diff chars `148365`, gate state `blocked`. A shorter 120s bounded rerun timed out and is not counted as SC-012 closeout evidence. |
| Protected edit constraints | PASS | Repair diff touches only continuous-co-review runtime/test files plus Iteration 002 state evidence. It does not touch F-184 protected surfaces, hooks/PostToolUse, Proposal 139, Proposal 196, `proposals/197-continuous-co-review.md`, or `.squad/agents/spec-steward/history.md`. |

## Workshop-decision conformance matrix

| Lens decision | Implementation mapping | Fresh review result |
| --- | --- | --- |
| Architecture: canonical instruction remains runtime authority | Prompt composition still loads `scripts/internal/continuous-co-review/code-review-agent.md` and verifies the instruction hash before adapter invocation. | PASS |
| Architecture: runtime path is `ReviewRequest.v2 -> composed prompt -> adapter -> FindingsResult.v1` | Repair keeps request/prompt construction in core and routes Codex through the same shared adapter command. Live repair-diff and full Iteration smokes returned valid `FindingsResult.v1`. | PASS |
| Integration/API: host adapters use safe argv/equivalent invocation | Windows `.ps1` shims are invoked as PowerShell `-File` with argument-list tokens; non-Windows/direct command behavior is unchanged. | PASS |
| Security: read-only where supported, guard authoritative otherwise | Codex retains `--sandbox read-only`; mutation guard remains enforced around adapter execution. | PASS |
| Requirements/NFR: actual outbound prompt includes rubric, design context, exact diff, round/prior findings, visibility/do policy, and output contract | Prompt probe and focused tests confirm the outbound prompt contains the required contract content and now the concrete schema. | PASS |
| Component boundary: provider-clean core | Shim resolution and Codex last-message handling are transport-specific adapter behavior; review semantics stay in request/prompt/contract components. | PASS |

## Abstraction-leak gate

**Result**: PASS.

The repair does not move provider-specific concerns into the core reviewer
semantics. `ReviewRequest.v2` construction and prompt composition remain
host-neutral. Windows `.ps1` resolution, Codex `--sandbox read-only`, and Codex
`--output-last-message` handling stay in the shared adapter/transport seam.

## Protected constraint gate

**Result**: PASS.

The repair does not start rung 1, hook/PostToolUse triggers, Proposal 139
foundation work, Proposal 196 provenance/audit work, or protected F-184 edits.
The repair also avoids `proposals/197-continuous-co-review.md` and
`.squad/agents/spec-steward/history.md`.

## Runtime prompt correctness

**Result**: PASS.

The repaired prompt now includes the full `FindingsResult.v1` schema when
`SchemaRoot` is available, including `additionalProperties: false`, and ends
with a direct output instruction:

- return only valid `FindingsResult.v1` JSON;
- use `finding_id`, not `id`;
- do not emit properties absent from the schema;
- return JSON only, with no Markdown or prose.

Fresh prompt probe evidence for the repair diff:

- `schema_version`: `2.0`
- `output_contract`: `FindingsResult.v1`
- `changed_paths`: `5`
- `diff_chars`: `15869`
- `prompt_chars`: `218926`
- schema heading present: `true`
- schema `additionalProperties: false` present: `true`
- `finding_id` instruction present: `true`
- no-extra-properties instruction present: `true`
- JSON-only instruction present: `true`

## Mutation-guard assessment

**Result**: PASS.

The repair leaves the guard position intact: request-bundle/prompt artifacts are
excluded as legitimate adapter workspace output, while source, Git, and
Specrew-state mutation still invalidate the run. Focused tests passed and full
live Codex smoke recorded a clean mutation guard.

## Dogfood smoke result

**Result**: PASS for review-signoff readiness; manual SC-012 remains feature-closeout scope.

Prior rejection evidence is preserved: before repair, Codex could not be
started through `.NET ProcessStartInfo` in this Windows environment because the
available command was `codex.ps1`, and Claude timed out on the full prompt.

Fresh repair evidence:

- Codex command availability: `codex-cli 0.139.0`; command type
  `ExternalScript`; path resolves to `codex.ps1`.
- Repair-diff live smoke through implemented path:
  - `kind=findings-result`
  - `FindingsResult.v1` valid/present
  - exit code `0`
  - argv summary `codex exec --sandbox read-only --output-last-message reviewer-last-message.json`
  - read-only supported `true`
  - changed paths `5`
  - diff chars `15869`
  - gate state `pass`
- Full Iteration 002 live dogfood through implemented path at 300s:
  - `kind=findings-result`
  - `FindingsResult.v1` valid/present
  - status `findings`
  - finding count `2`
  - exit code `0`
  - argv summary `codex exec --sandbox read-only --output-last-message reviewer-last-message.json`
  - read-only supported `true`
  - mutation guard `false`
  - changed paths `26`
  - diff chars `148365`
  - gate state `blocked`

The live evidence proves the repaired Windows Codex path can now produce valid
`FindingsResult.v1` through `composer -> adapter -> outbound prompt`.

## Findings

### Blocking finding B-197-I002-001 — Live dogfood path cannot produce `FindingsResult.v1`

**Requirement / task trace**: FR-018, FR-020, FR-021, FR-022, SC-012, SC-014,
SC-016, T053, T054, T056, T057.

**Prior status**: BLOCKING.

**Fresh status**: **RESOLVED**.

**Resolution evidence**:

1. Windows `codex.ps1` shim resolution is implemented through a safe PowerShell
   `-File` argv path.
2. Codex read-only behavior is preserved where supported:
   `codex exec --sandbox read-only`.
3. Codex last-message JSON is consumed via `--output-last-message`, so progress
   stdout does not prevent `FindingsResult.v1` normalization.
4. The adapter-bound prompt now embeds the concrete `FindingsResult.v1` schema
   and JSON-only/no-extra-properties instruction.
5. Focused deterministic validation passed `24/24`.
6. Repair-diff live smoke and full Iteration 002 live dogfood both produced
   valid `FindingsResult.v1` through the implemented path.

### Non-blocking observation NB-197-I002-001 — Pester host needs repo-local TEMP/TMP

Still applicable. Focused Pester validation passes with repo-local `TEMP`/`TMP`.
Keep that setup in handoff evidence to avoid host Pester TestDrive cleanup
noise from the default short-path temp environment.

### Feature-closeout/manual SC-012 reminder

This review does **not** close SC-012. Before feature closeout, the maintainer
must still run the manual real-host planted-design-violation validation from
`specs/197-continuous-co-review/iterations/001/manual-validation.md` for each
available authorized host and record a parseable blocking finding that names the
violated design decision.

## Final review decision

**APPROVED FOR REVIEW-SIGNOFF READINESS.**

`B-197-I002-001` is resolved for Iteration 002 repair review. Do not advance
retro, iteration closeout, or feature closeout without the next explicit human
boundary verdict.
