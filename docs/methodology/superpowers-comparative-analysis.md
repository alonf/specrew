# Superpowers Comparative Analysis

## Scope and provenance

This analysis inspected [`obra/superpowers`](https://github.com/obra/superpowers) at commit
`d884ae04` on 2026-07-12, including its plugin manifests, lifecycle hooks, host adapters, skill files,
task-brief/review-package scripts, and behavioral skill tests. Superpowers is MIT licensed. Specrew
can reuse concepts and, where useful, code with attribution; this document recommends reusing the
method, not importing the plugin wholesale.

## Architectural model

Superpowers is a portable library of agent skills rather than a deterministic lifecycle engine. Its
core loop is: clarify the design, create an isolated worktree, write a small-task plan, dispatch a
fresh implementer per task, review each task, run a final review, and complete the branch. Host
integration is intentionally thin: install skills, expose commands, and use hooks to remind the agent
to load the right skill. Most enforcement is instructional. Specrew's boundary, validator, evidence,
and verdict machinery should remain authoritative.

## Strong reusable patterns

### Fresh contexts with file handoffs

Each task receives an explicit brief instead of inherited conversation history. The implementer writes
a result; the reviewer receives a review package with the exact baseline and task requirements. This
reduces context pollution and makes the handoff inspectable. The baseline is captured before the task;
it is not guessed later with `HEAD~1`.

### Two independent review questions

Task review distinguishes "did it implement the requested behavior?" from "is the implementation
sound?" A single accepted/rejected label hides this distinction. Specrew should preserve both verdicts
and aggregate fail-closed.

### Contradiction scan before execution

The executor checks the plan for missing files, incompatible requirements, and underspecified steps
before implementation. This is cheaper than discovering a plan defect after several tasks.

### Root-cause debugging discipline

The systematic-debugging skill requires evidence and root-cause analysis before patching. After three
materially different failed fixes, it calls for an architecture checkpoint instead of continued local
patching. This complements Specrew's round ceiling.

### Skills tested as behavior, not prose

The writing-skills methodology uses RED/GREEN/REFACTOR against fresh agent contexts: establish a
no-guidance baseline, present pressure scenarios, run repeated samples, capture rationalizations, and
strengthen the instruction until behavior changes. It also tests explicit skill invocation and warns
that a description which summarizes the workflow may let an agent skip the body.

### Durable progress under compaction

Task state is kept outside transient chat context. A new context can reconstruct the task, report,
review result, and next action from files.

## What not to copy unchanged

| Superpowers pattern | Specrew decision | Reason |
|---|---|---|
| Fresh subagent for every task | Adapt by risk and task boundary | Process startup and review overhead are disproportionate for trivial edits. |
| Very small universal task granularity | Keep configurable | Tiny tasks can create artifact and review churn without improving traceability. |
| TDD as an unconditional rule | Keep profile/risk governed | Strong for behavior changes, not universal for docs, migrations, generated artifacts, or spikes. |
| Worktree as isolation | Treat as identity/ergonomics only | A worktree is not an OS security boundary; Proposal 203 owns confinement. |
| Instruction-only enforcement | Do not adopt | Skills and hooks can be skipped or compacted; validators remain authoritative. |
| Review after every tiny edit | Batch coherent increments | Review spend and stale-lineage cost must stay bounded. |
| Invoke a skill for every question | Use applicability rules | Universal invocation adds latency and unnecessary workflow. |

## Reuse map

| Learning | Existing owner | Action |
|---|---|---|
| Fresh contexts, briefs/reports, durable ledger, contradiction scan | Proposal 139 | Amend the orchestration contract. |
| Exact baseline, file-only review package, dual spec/quality verdict | Proposal 145 | Amend the reviewer artifact contract. |
| Reviewer/worktree containment | Proposal 203 | No new proposal; preserve Specrew's stronger model. |
| Risk/cost-aware model routing | Proposal 068 and pending 206 work | Do not duplicate. |
| Skill/instruction pressure tests and baseline controls | No complete owner found | New Proposal 207. |
| Root-cause-first debugging and architecture checkpoint | Proposals 139/145 | Add as loop policy, not a standalone feature. |

## Recommended reuse order

1. Land the artifact-contract amendments to Proposals 139 and 145.
2. Specify Proposal 207 as a small host-neutral evaluation harness before expanding the skill catalog.
3. Reuse Superpowers scenarios as conceptual test shapes, not copied assertions; Specrew needs scenarios
   for boundary packets, stop ordering, verdict capture, reviewer output, and compaction.
4. Keep deterministic validators as release authority. Behavioral evaluations measure whether the agent
   follows the contract before the validator has to block it.

## License and attribution

Conceptual reuse needs a source link in design provenance. Any copied or substantially derived code,
prompt text, or fixtures must retain the MIT license notice and identify the source commit. Prefer
Specrew-native implementations against Specrew schemas and host-neutral contracts.
