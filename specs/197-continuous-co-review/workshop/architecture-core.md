# Architecture Core Lens Workshop

## Lens

- **Lens ID**: `architecture-core`
- **Depth**: full
- **Confirmation**: human-confirmed
- **Confirmation scope**: lens-question

## Decision Agenda

- Should Iteration 001 spawn a fresh reviewer process for each review run or reuse a long-lived reviewer?
- How should the review context be packaged and bounded for a fresh-context reviewer?
- How should the orchestrator detect reviewer completion, timeouts, invalid JSON, and process cleanup failures?
- Where should reviewer provider/model selection and cost authorization live?
- Which review kinds and multi-reviewer modes are in scope now versus future features?

## Agreed Architecture Direction

Iteration 001 uses a modular, contract-and-gate-centered architecture with one bounded fresh-context read-only
reviewer process per code/change-set review run. The orchestrator builds an explicit review request package
from the git diff, governing design/spec context, allowed paths, review kind, and provider/model configuration.
Process exit plus valid stdout JSON marks completion; timeout, nonzero exit, empty output, or invalid JSON
becomes a deterministic failure finding or gate block.

Provider/model selection and cost authorization are explicit configuration, not implicit background spend.
The contract preserves future features for stronger Job Object/cgroup cleanup, optional long-lived reviewer
reuse, multi-reviewer Codex/Claude/provider fan-out, retro-informed review, and non-code review kinds, but those
are out of scope for the first release.

## Architecture Sketch

```text
+-------------------------+
| Checkpoint / review     |
| trigger sees git diff   |
+------------+------------+
             |
             v
+-------------------------+
| Build review request    |
| - diff/change-set       |
| - review kind           |
| - design/spec context   |
| - allowed files         |
| - model/provider config |
+------------+------------+
             |
             v
+-------------------------+
| Spawn fresh reviewer    |
| headless host process   |
| bounded timeout         |
+------------+------------+
             |
             v
+-------------------------+
| Capture completion      |
| process exit + stdout   |
| valid findings JSON     |
+------------+------------+
             |
             v
+-------------------------+
| Normalize findings      |
| write blackboard        |
| deterministic gate      |
+-------------------------+
```

## Binding First-Release Scope

- Spawn a fresh, short-lived reviewer process per review run.
- Treat the durable blackboard/findings artifacts as state; do not rely on reviewer process memory.
- Scope the first execution path to code/change-set review at checkpoint boundaries.
- Preserve a generic `review_kind` field for future plan, tasks, spec, and design review.
- Allow multiple review runs and reviewer/model provenance in schema design, but execute one configured
  reviewer in Iteration 001.
- Do not include previous `retro.md` files by default in Iteration 001 context.

## Future Features Captured

- Reviewer lifecycle hardening using Windows Job Objects and Linux/macOS process groups or cgroups.
- Optional long-lived reviewer reuse after cancellation, isolation, memory-contamination, and cost controls are designed.
- Multi-reviewer fan-out across Codex, Claude, and other providers with later quorum/escalation policy.
- Retro-informed review context once stale-guidance and context-bounding risks are controlled.
- Expansion from code/change-set review to plan, tasks, spec, and design-artifact review kinds.

## Iteration 002 Send-Back Addendum: Reviewer Definition Injection

The reviewer-definition repair keeps the Iteration 001 spine and adds an explicit reviewer-definition and
prompt-composition layer. The canonical reviewer instruction lives at
`scripts/internal/continuous-co-review/code-review-agent.md`; host-folder copies are mirrors for consistency and
discoverability only, and runtime execution depends on injecting the canonical file content into the headless
host prompt. The prompt composer owns reviewer semantics, including Proposal 145 rubric text, design context,
diff content, round number, prior blocking findings, visibility policy, and do-policy. Host adapters remain
transport/read-only capability edges and must not invent reviewer instructions.

Reviewer execution defaults to an isolated review workspace. The orchestrator selects the exact review diff,
captures a pre-review workspace baseline, invokes the reviewer with the composed prompt and any supported
read-only host flags, then captures a post-review baseline. If the reviewer mutates files, Specrew records the
mutation diff as evidence, treats the result as an invalid review-host mutation violation, and discards the
isolated workspace instead of reverting the active feature worktree. The orchestrator remains the only owner of
durable writes such as blackboard, run index, disposition evidence, and gate artifacts.

```text
                            Canonical reviewer instruction
                scripts/internal/continuous-co-review/code-review-agent.md
                                           |
                                           | copied as best-effort host mirrors
                                           v
                          .claude/.github/.agents/... host folders
                          (discoverability only; not execution-critical)


Feature branch / developer worktree
  - committed implementation evidence
  - orchestrator selects exact review diff
  - orchestrator owns persistent writes
                |
                v
+------------------------------+
| Isolated review workspace    |
| pre-review snapshot/hash     |
+------------------------------+
                |
                v
+------------------------------+
| ReviewRequest.v2             |
| - design context content     |
| - exact diff content         |
| - round_number               |
| - prior_findings             |
| - visibility_policy          |
| - do_policy                  |
+------------------------------+
                |
                v
+------------------------------+
| Prompt Composer              |
| reads code-review-agent.md   |
| injects rubric + context +   |
| diff + round + prior results |
+------------------------------+
                |
                v
+------------------------------+
| Host Adapter                 |
| transport only               |
| uses read-only flags where   |
| supported                    |
+------------------------------+
                |
                v
+------------------------------+
| FindingsResult.v1 stdout     |
+------------------------------+
                |
                v
+------------------------------+
| Post-review mutation guard   |
| no change: continue          |
| changed: capture mutation    |
| diff, fail loud, discard     |
| isolated workspace           |
+------------------------------+
                |
                v
+------------------------------+
| Existing normalizer/gate/    |
| blackboard/run-index writes  |
| owned by orchestrator only   |
+------------------------------+
```
