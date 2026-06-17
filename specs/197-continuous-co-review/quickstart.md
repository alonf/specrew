# Quickstart: Continuous Co-Review Planning Artifacts

This quickstart describes how maintainers should use Proposal 197 planning artifacts before task generation and later implementation. It does not start implementation.

## Scope reminders

- Stay on branch `197-continuous-co-review`.
- Do not reintroduce `proposals/197-continuous-co-review.md`.
- Do not include `.squad/agents/spec-steward/history.md` runtime churn in feature commits.
- Do not edit F-184-protected host-runtime, hook, provider, registry, refocus, shared-governance, or `validate-governance.ps1` surfaces.
- Do not create Proposal 197 reviewer files named `provider-adapter.ps1`; use explicit reviewer-domain names such as `reviewer-host-adapter-*` or `reviewer-model-capability`.
- Do not add dependencies unless explicitly re-scoped with dependency-policy evidence.
- CI/CD E2E stays unnamed in Proposal 197; preserve hooks/fixtures only for later composition with Proposal 181 plus Proposal 194 canary.
- Proposal 196 owns human-confirmed lens-stamp provenance/audit.

## Planning artifacts

Review before `/speckit.tasks`:

1. `spec.md`
2. `lens-applicability.json` and `workshop/*.md`
3. `implementation-rules.yml`
4. `plan.md`
5. `research.md`
6. `data-model.md`
7. `contracts/*.schema.json` and `contracts/reviewer-spawn-contract.md`

## Expected task-generation posture

- Create tasks in dependency order: contracts/schemas, fixture validation, diff/request/context packaging, adapter/config/authorization seams, execution/normalization, blackboard/gate/run evidence, governance/quality evidence.
- Every task should trace to FR/DS/SEC/INT/OPS/OBS/IMPL/TG requirements and one user story.
- Every task should name owner role and capacity placement within the 18-point Iteration 001 budget.
- Preserve new-file-only behavior unless a human explicitly approves F-184 coordination.
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
4. Build `ReviewRequest` with design context refs, path policy, provider/model request, output schema request, and run correlation.
5. Create a unique per-run immutable request bundle.
6. Discover configured host capabilities and require authorization for paid, non-default, external, or newly added provider/model use.
7. Invoke one fresh reviewer through a reviewer-domain host adapter using safe argv/equivalent invocation.
8. Accept only valid stdout JSON matching `FindingsResult`; otherwise record `InfrastructureFailure` or unsafe state.
9. Write `ReviewThread`, dispositions, `GateVerdict`, and `ReviewRun` under `.specrew/review/inline/<run-id>/...`.
10. Block on unresolved `blocking` findings, malformed state, infrastructure failures, or non-convergence after initial review plus one fix-verification round.

Live AI-host smoke is optional and must be explicitly configured and authorized.
