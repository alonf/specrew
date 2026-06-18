# Feature 197 Iteration 002 Review

**Reviewer**: Reviewer  
**Requested by**: Alon Fliess  
**Review type**: Human-led Proposal 145 pass for Iteration 002  
**Reviewed range**: `e54cb30cf2d8a6b796572a82e82e3eb4258f47b2..f279301eb73e60012c100cd34d5339f59f6a363e`  
**Implementation tip reviewed**: `f279301eb73e60012c100cd34d5339f59f6a363e`  
**Verdict**: **REJECT / NEEDS-REWORK**

## Verdict rationale

Iteration 002 substantially repairs the Proposal 145 runtime prompt path: the canonical reviewer instruction, `ReviewRequest.v2`, prompt composer, adapter seam, read-only posture metadata, and mutation guard are implemented and covered by deterministic tests.

The review cannot approve because the required dogfood/live-host smoke did not produce a valid `FindingsResult.v1` against the actual Iteration 002 diff. The Codex path also exposes a Windows live-invocation defect that the mocked adapter tests do not catch.

Reviewer rejection lockout applies: do not advance to retro, iteration-closeout, or feature-closeout until the blocking finding below is repaired and this review is rerun on the updated committed tree.

## Evidence inspected

- `specs/197-continuous-co-review/spec.md`
- `specs/197-continuous-co-review/tasks.md`
- `specs/197-continuous-co-review/iterations/002/plan.md`
- `specs/197-continuous-co-review/iterations/002/state.md`
- `specs/197-continuous-co-review/iterations/002/drift-log.md`
- `scripts/internal/continuous-co-review/code-review-agent.md`
- `scripts/internal/continuous-co-review/review-request-builder.ps1`
- `scripts/internal/continuous-co-review/reviewer-contracts.ps1`
- `scripts/internal/continuous-co-review/review-prompt-composer.ps1`
- `scripts/internal/continuous-co-review/reviewer-execution-engine.ps1`
- `scripts/internal/continuous-co-review/workspace-mutation-guard.ps1`
- `scripts/internal/continuous-co-review/host-agent-mirror.ps1`
- `scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1`
- `scripts/internal/continuous-co-review/reviewer-host-adapter-codex-exec.ps1`
- Iteration 002 Pester suites under `tests/continuous-co-review/`
- Workshop lenses under `specs/197-continuous-co-review/workshop/`
- `.squad/decisions.md` targeted Feature 197 / Proposal 145 entries

## Validation evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Focused Iteration 002 Pester suite | PASS | 44 passed, 0 failed after setting repo-local `TEMP`/`TMP` to avoid host Pester TestDrive short-path cleanup failure |
| Protected edit constraints | PASS | Iteration 002 diff does not touch F-184 protected surfaces, `proposals/197-continuous-co-review.md`, `.squad/agents/spec-steward/history.md`, hook/PostToolUse, Proposal 139, or Proposal 196 surfaces |
| Branch remote comparison before artifact write | PASS | `HEAD` and `origin/197-continuous-co-review` both resolved to `f279301eb73e60012c100cd34d5339f59f6a363e` |
| Runtime prompt composition evidence | PASS | `ReviewRequest.v2`, 6 design sources, design content chars `85585`, exact diff chars `124107`, 24 changed paths, prompt chars `563729`, output contract `FindingsResult.v1`, prompt hash `sha256:cb15aa2b0ef58f30125d86c994cc98f3a3bb4af855b74b86d391c609354b87d5` |
| Live host availability sanity | PASS | `claude -p` returned valid JSON for a small prompt; `codex --version` returned `codex-cli 0.139.0`; `claude --version` returned `2.1.181` |
| Dogfood / first live SC-012 smoke | FAIL | Codex orchestration returned `infrastructure_failure/nonzero-exit`; Claude orchestration timed out after 300s on the actual Iteration 002 prompt without a valid `FindingsResult.v1` |

## Workshop-decision conformance matrix

| Lens decision | Implementation mapping | Evidence/test pointer | Review result |
| --- | --- | --- | --- |
| Architecture: canonical instruction is the authoritative reviewer definition | `code-review-agent.md`; `Get-ContinuousCoReviewInstructionContent`; `New-ContinuousCoReviewPrompt` | `reviewer-instruction.Tests.ps1`; prompt evidence includes instruction hash `sha256:3f037e17a29ab5fe7639e4a79b43fad334f883195bfb15fff1f71d892109676d` | PASS |
| Architecture: runtime path is `ReviewRequest.v2 -> composed prompt -> adapter -> FindingsResult.v1` | `review-request-builder.ps1`; `review-prompt-composer.ps1`; shared adapter command; normalizer | `review-request-builder.Tests.ps1`; `review-prompt-composer.Tests.ps1`; `review-prompt-adapter-seam.Tests.ps1`; contracts suite | PASS deterministically; live smoke FAIL |
| Architecture: transport adapters must not own review semantics | `Invoke-ContinuousCoReviewReviewerHostAdapterCommand` composes from request and only invokes process | Adapter seam tests prove composed prompt is sent, fixture-owned prompt cannot bypass | PASS |
| Component: instruction source, request schema, prompt composer, mutation guard, and host mirror are distinct components | Separate scripts under `scripts/internal/continuous-co-review/` | Unit tests for each component; `_load.ps1` loads feature-local modules | PASS |
| Requirements/NFR: outbound prompt contains canonical rubric, design-context content, exact diff, round, prior findings, visibility policy, do-policy, and output contract | `New-ContinuousCoReviewRequest`; `New-ContinuousCoReviewPrompt` | Prompt evidence booleans all true; deterministic tests cover required fields | PASS |
| Integration/API: `ReviewRequest.v2` carries required contract fields and rejects schema drift | `review-request.schema.json`; `reviewer-contracts.ps1`; request builder | Contract tests and request-builder tests | PASS |
| Integration/API: host adapters use safe argv/equivalent invocation and deterministic infrastructure failure | Claude/Codex adapter wrappers; shared process invoker | Mocked tests pass; live Codex Windows shim path fails | FAIL live |
| Security: visibility/do policy explicitly bound into prompt | `review-visibility-policy-builder.ps1`; request builder; prompt composer | Prompt evidence includes both policy sections; tests assert presence | PASS |
| Security: read-only flag used where supported; mutation guard remains authoritative otherwise | `Get-ContinuousCoReviewReadOnlyInvocationPolicy`; `Invoke-ContinuousCoReviewGuardedAdapterAttempt`; `workspace-mutation-guard.ps1` | Codex invocation summary included `codex exec --sandbox read-only`; Claude records unsupported; mutation guard showed no mutation during dogfood attempts | PASS with live-output failure |
| Code implementation: no new dependency or broad utility-module expansion | Feature-local PowerShell scripts and tests only | Diff inspection and contract test “does not introduce dependency imports or protected-surface dot-sourcing” | PASS |

## Abstraction-leak gate

**Result**: PASS.

The core/provider boundary remains clean in the reviewed implementation. Request construction and prompt composition are host-neutral. Host-specific behavior is isolated to adapter wrappers and the shared adapter command. The Codex read-only flag is handled as provider-specific transport posture, not as review semantics. The live Codex failure is an invocation defect at the provider seam, not a semantic leak into the core.

## Protected constraint gate

**Result**: PASS.

The reviewed diff does not modify the protected Proposal 139, Proposal 196, F-184, hook/PostToolUse, `proposals/197-continuous-co-review.md`, or `.squad/agents/spec-steward/history.md` surfaces. No rung-1/hook/protected-edit variance was found.

## Runtime prompt correctness

**Result**: PASS for deterministic prompt construction; FAIL for live model completion.

The actual composed prompt includes:

- Canonical Proposal 145 reviewer instruction content
- Design-context content, not just references
- Exact diff/change-set content
- Round number
- Prior findings
- Visibility policy
- Do policy
- Full `ReviewRequest.v2` JSON
- `FindingsResult.v1` output contract instruction

Clean-state composed evidence:

- `schema_version`: `2.0`
- `request_hash`: `sha256:553eb2e960da35f62bb1b5329beda625fd0f88eccc84ec3d86c05a58dfc45a9d`
- `instruction_hash`: `sha256:3f037e17a29ab5fe7639e4a79b43fad334f883195bfb15fff1f71d892109676d`
- `design_source_count`: `6`
- `design_chars`: `85585`
- `diff_chars`: `124107`
- `changed_path_count`: `24`
- `round`: `1`
- `prior_findings_count`: `0`
- `output_contract`: `FindingsResult.v1`
- `prompt_chars`: `563729`
- `prompt_hash`: `sha256:cb15aa2b0ef58f30125d86c994cc98f3a3bb4af855b74b86d391c609354b87d5`

## Mutation-guard assessment

**Result**: PASS for deterministic coverage and runtime placement.

The guard snapshots source roots, Specrew state roots, and Git status before and after the adapter attempt. It excludes the immutable request-bundle workspace, which allows legitimate prompt/request-bundle writes while still catching source, Git, and Specrew-state mutations. Run-index and blackboard writes happen after guarded adapter execution, so legitimate review evidence writes are not part of the adapter mutation window.

Dedicated tests prove source mutation, Specrew-state mutation, and Git status mutation invalidation. The live dogfood attempts reported `mutation_guard=false`, so the failure was not caused by legitimate evidence writes tripping the guard.

## Dogfood smoke result

**Result**: FAIL.

Commands were run through the implemented orchestrator/prompt-composer/adapter path against the actual Iteration 002 diff from `e54cb30cf2d8a6b796572a82e82e3eb4258f47b2` to the implementation tip.

- Codex candidate: `codex exec --sandbox read-only`
  - Result: `infrastructure_failure`
  - Failure category: `nonzero-exit`
  - Read-only supported: `true`
  - Mutation guard: `false`
  - FindingsResult: none
  - Additional live diagnosis: `.NET ProcessStartInfo` with `UseShellExecute=false` cannot start `codex` in this Windows environment because the available command is the PowerShell shim `codex.ps1`; mocked tests did not catch this.
- Claude candidate: `claude -p`
  - Small-prompt sanity: valid JSON returned, proving live host availability
  - Iteration 002 prompt attempt: timeout after 300s
  - Read-only supported: `false`
  - Mutation guard: `false`
  - FindingsResult: none

Per the binding review instruction, inability to produce a valid `FindingsResult.v1` against a real available host is blocking.

## Findings

### Blocking finding B-197-I002-001 — Live dogfood path cannot produce `FindingsResult.v1`

**Requirement / task trace**: FR-018, FR-020, FR-021, FR-022, SC-012, SC-014, SC-016, T053, T054, T056, T057.

**Evidence**:

- Codex live orchestration returned `infrastructure_failure/nonzero-exit` with invocation summary `codex exec --sandbox read-only`.
- Direct live diagnosis shows the Windows environment exposes Codex as `codex.ps1`; the adapter invokes executable name `codex` through `.NET ProcessStartInfo` with `UseShellExecute=false`, which cannot resolve that PowerShell shim as an executable process.
- Claude live availability was proven by a small `claude -p` prompt returning valid JSON, but the actual Iteration 002 runtime prompt timed out after 300 seconds and produced no valid `FindingsResult.v1`.

**Why this blocks**: The repair goal is not only to construct a correct-looking prompt; it must be usable by the real host path. The live smoke did not return a parseable `FindingsResult.v1`, and the Codex path exposes an untested live invocation failure on Windows.

**Required repair owner/scope**: Implementer, with Security Reviewer/Reviewer validation.

**Required repair**:

1. Make live adapter invocation resolve PowerShell shim commands on Windows or otherwise invoke the resolved host command through a supported safe argv/equivalent path without regressing Unix behavior.
2. Add deterministic coverage that exercises command resolution for `.ps1`/shim-based host CLIs, not only mocked process output.
3. Re-run a real Iteration 002 dogfood smoke through the implemented path and capture a valid `FindingsResult.v1`, or record a human-approved explicit deferral of live SC-012 evidence if the project owner accepts that risk.
4. Preserve the read-only flag for Codex where supported and keep mutation guard green.

### Non-blocking observation NB-197-I002-001 — Pester host needs repo-local TEMP/TMP

Focused Pester validation passes with repo-local `TEMP`/`TMP`, but the default host environment triggered an old Pester 3 TestDrive short-path cleanup failure (`C:\Users\ALON~1.HOM`). This is environmental, not a product defect in Iteration 002, but the validation command should keep the repo-local temp setup in handoff evidence.

## Final review decision

**REJECT / NEEDS-REWORK.**

The deterministic runtime-prompt repair is mostly sound, but the live SC-012/dogfood path failed. Repair B-197-I002-001, commit the fix, push it to `origin/197-continuous-co-review`, and request a fresh Iteration 002 review. Do not advance retro or closeout.
