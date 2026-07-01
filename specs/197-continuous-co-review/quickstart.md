# Quickstart: Continuous Co-Review Planning Artifacts

This quickstart describes how maintainers should use Proposal 197 planning artifacts after the review send-back and before Iteration 002 implementation. It does not start implementation.

## Scope reminders

- Stay on branch `197-continuous-co-review`.
- Do not reintroduce `proposals/197-continuous-co-review.md`.
- Do not include `.squad/agents/spec-steward/history.md` runtime churn in feature commits.
- Do not edit F-184-protected host-runtime, hook, provider, registry, refocus, shared-governance, or `validate-governance.ps1` surfaces.
- Do not create Proposal 197 reviewer files named `provider-adapter.ps1`; use explicit reviewer-domain names such as `reviewer-host-adapter-*` or `reviewer-model-capability`.
- Do not add dependencies unless explicitly re-scoped with dependency-policy evidence.
- Automated live cross-host CI stays unnamed and out of scope in Proposal 197; preserve hooks/fixtures only for later composition with Proposal 181 plus Proposal 194 canary.
- Proposal 196 owns human-confirmed lens-stamp provenance/audit.
- Preserve the completed Iteration 001 spine; Iteration 002 is only the reviewer-definition repair.
- Before Iteration 002 implementation, merge or rebase latest remote `main` and resolve conflicts.
- Treat native host-folder reviewer-agent copies as best-effort mirrors only. Runtime correctness must come from the composed prompt that injects `scripts/internal/continuous-co-review/code-review-agent.md`.

## Planning artifacts

Review before the next before-implement readiness check:

1. `spec.md`
2. `lens-applicability.json` and `workshop/*.md`
3. `implementation-rules.yml`
4. `plan.md`
5. `research.md`
6. `data-model.md`
7. `contracts/*.schema.json` and `contracts/reviewer-spawn-contract.md`

## Expected Iteration 002 task posture

- Preserve the completed Iteration 001 spine and execute only the reviewer-definition repair tasks.
- Keep tasks in dependency order: latest-remote-`main` sync, canonical reviewer instruction, `ReviewRequest.v2`/prompt composer, read-only/mutation guard, host mirrors/runbook, deterministic prompt evidence, validation.
- Every Iteration 002 task should trace to at least one FR/SC plus `implementation-rules.yml`.
- Every Iteration 002 task should name owner role and capacity placement within the 8.00/20-point Iteration 002 budget.
- Preserve new-file-only/protected-surface behavior unless a human explicitly approves F-184 coordination.
- If an iteration scaffold is required, use installed Specrew helpers rather than hand-writing state.

## Future local validation commands

Exact commands are implementation-dependent, but planned evidence includes:

```powershell
pwsh -NoProfile -Command "Invoke-Pester -Path tests/continuous-co-review"
git --no-pager diff --name-only
```

Use the repository's existing markdownlint path/tooling before commits; do not add a new markdownlint dependency for Proposal 197.

Protected-surface review must show no changes to F-184 protected files listed in `spec.md`, their mirrored `.specify/extensions/specrew-speckit/scripts/` equivalents, or `validate-governance.ps1`.

## Runtime behavior expected after implementation

1. Resolve checkpoint baseline.
2. Run `git diff`.
3. If no reviewable diff exists, write `ReviewRunSkipped` and pass/no-op `GateVerdict` without spawning reviewer.
4. Build `ReviewRequest.v2` with design-context content and sources, exact diff/change-set content, reviewer-instruction metadata/content hash, `round_number`, `prior_findings`, visibility policy, do-policy, provider/model request, output contract `FindingsResult.v1`, and run correlation.
5. Compose the actual outbound `ReviewPrompt` by injecting the canonical `scripts/internal/continuous-co-review/code-review-agent.md` content plus request v2 content. Do not rely on host-folder/native agent auto-loading.
6. Create a unique per-run immutable request bundle and prompt artifact.
7. Discover configured host capabilities and require authorization for paid, non-default, external, or newly added provider/model use.
8. Invoke one fresh reviewer through a reviewer-domain host adapter using safe argv/equivalent invocation, passing supported read-only/no-write flags where available.
9. Run the workspace mutation guard before and after invocation; source, Git, or Specrew-state mutation invalidates the run as unsafe.
10. Accept only valid stdout JSON matching `FindingsResult`; otherwise record `InfrastructureFailure` or unsafe state.
11. Write `ReviewThread`, dispositions, `GateVerdict`, and `ReviewRun` under `.specrew/review/inline/<run-id>/...`.
12. Block on unresolved `blocking` findings, malformed state, infrastructure failures, invalidated mutation guard, or non-convergence after initial review plus one fix-verification round.

Maintainer-run real-host validation is required before feature closeout using `iterations/001/manual-validation.md`; that runbook must invoke the implemented orchestrator/prompt-composer path so each host receives the same injected prompt. Scheduled or rotating live-host CI remains future work.
