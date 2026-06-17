---
proposal: 145
title: Host-Neutral Structured Multi-Phase Reviewer (7-Phase Checklist + FR×Phase Coverage Matrix + Static Validator)
status: candidate
phase: phase-2
estimated-sp: 45-65
priority-tier: 1
discussion: surfaced 2026-05-30 after F-049 + F-050 dogfooding revealed 8+ "review missed X" instances despite review-signoff verdicts of accepted; pattern is structural (single-pass narrative reviewer with no per-dimension coverage enforcement), not exhortation-fixable
---

# Host-Neutral Structured Multi-Phase Reviewer (7-Phase Checklist + FR×Phase Coverage Matrix + Static Validator)

## Why

Reviews keep missing things. The empirical record from this session (~10 days, F-046 through F-050) shows the review-signoff verdict is currently a single-pass narrative assertion that does not structurally guarantee any specific dimension has been evaluated. Concrete instances where review-signoff said `accepted` but real gaps existed:

1. **Shape 8 (FileList directional blind spot) — F-049 → v0.28.0-beta.1.** Phase 2 FileList integrity check was built to prevent v0.27.3-class incidents but only checked one direction (declared files exist on disk), not the inverse (every referenced source file is declared). v0.28.0-beta.1 shipped the exact omission class (`scripts/internal/user-profile.ps1`) F-049 was designed to prevent → runtime crash on first `specrew start`. The gate was reviewed and signed off without anyone asking *"does this gate cover the full failure-mode space its spec claims?"*

2. **Coverage-evidence drift — F-050 iter-002 (2026-05-30).** `coverage-evidence.md` Tests Run table listed framework `reviewer.test_commands` (quality-profile-foundation, mechanical-findings-contract, etc.) but NOT the iter-002-added cursor test files. The deliverable tests were never explicitly recorded as executed at review-boundary. Caught by cross-reviewer code-read; would have passed any pattern-grep check.

3. **State-truth gaps — F-050 iter-002.** `start-context.json` and `feature.json` had empty `iteration_path`, `last_authorized_boundary`, `pending_next_boundary`, `current_iteration` fields. Review passed self-review without anyone validating session-state consistency.

4. **Never-pushed branch — F-050 (2026-05-30).** Entire `050-cursor-host-support` branch was local-only across iter-001 + iter-002 (10+ commits) when discovered. Same `[[project-codex-branch-push-discipline-gap-2026-05-26]]` pattern from F-046/F-048 recurring. Review did not check `git rev-parse HEAD == origin/<branch>`.

5. **Synthetic-fixture stand-in (Shape 6) — PlanningPoC iter-006 (2026-05-27).** 60-sec SLA test was a no-op against synthetic 4-line in-code fixture with English layer names while spec required real Hebrew customer DWGs. Code comment at `UploadRunFlowTests.cs:59-62` openly declared the gap. Across 4 prior iterations no review caught it.

6. **Reviewer-approves-uncommitted-state (Shape 5) — PlanningPoC iter-004 (2026-05-27).** Reviewer issued `accepted` verdict citing committed-hash provenance; 7 production code files cited as evidence were never committed to any branch. Caught by maintainer via `git status` by accident.

7. **Cross-reviewer Instance 11/13/17/18 — F-049 (2026-05-28/29).** I (Claude cross-reviewer) approved things based on metadata/pattern checks without reading content; Codex caught 8 substantive issues across the iteration. Lesson explicitly captured: pattern-grep ≠ verification.

8. **F-049 iter-5 under-coverage — producer/consumer meta-rule (2026-05-29).** Two gaps shipped that review-signoff missed: T009 reviewer-only inline content + first-run prompt hard-coded interactive→CI hang. Emerging meta-rule: producer-side changes need consumer-side demonstration tests at review-signoff.

### The structural gap

Reviews today depend on narrative assertions about quality dimensions, not enforced per-dimension evaluation evidence. Even with `[[proposal-140-reviewer-instruction-surface]]` (project-local review playbook) and `[[proposal-102-cross-model-independent-reviewer]]` (independent reviewer) in flight, the underlying problem is that a reviewer can write `**Overall Verdict**: accepted` without having structurally proven that every relevant dimension (functional / non-functional / code quality / test coverage / system safety / branch hygiene / context-load) was checked against every in-scope FR/SC.

The dimensions a competent reviewer needs to evaluate are large (>20 distinct concerns), specialized (security ≠ performance ≠ accessibility ≠ test isolation ≠ dependency intent), and easy to forget in a single-pass review. Single-agent narrative review is structurally bounded — too many dimensions for one agent to evaluate well in one pass, no enforcement that any specific dimension was actually evaluated.

## Research update — host memory, skills, hooks, and enforcement (2026-06-03)

This proposal was originally written from the current Specrew runtime reality: Squad is the only multi-agent runtime we are actively using, and the current practical host for Squad is Copilot. The follow-up question was whether Proposal 145 should be implemented as a "better Squad reviewer agent" or as a host-neutral review protocol that can later move to agent teams across Claude, Codex, Copilot, Cursor, Gemini/Antigravity-style hosts, and other AI hosts.

The research conclusion: **145 must be a host-neutral protocol with deterministic artifacts and validator enforcement.** A dedicated Squad reviewer agent is only one executor topology.

Important sources and findings:

- **Claude Code memory** — Claude Code has `CLAUDE.md` and auto memory, both loaded into sessions, but the documentation explicitly frames them as context, not enforced configuration. The same documentation says a blocking guarantee belongs in hooks, for example `PreToolUse`. Source: <https://docs.anthropic.com/en/docs/claude-code/memory.md>
- **Claude Code hooks** — Claude Code has the richest lifecycle hook surface found in the survey, including `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `PreCompact`, and `PostCompact`. These hooks are a good fit for automatic `/specrew.refocus` before/after context compaction and for local fast-fail guardrails, but they are host-specific and cannot be the only enforcement mechanism. Source: <https://docs.anthropic.com/en/docs/claude-code/hooks.md>
- **OpenAI Codex customization** — Codex positions `AGENTS.md` as durable project guidance, skills as reusable workflows, and external enforcement (pre-commit hooks, linters, type checkers) as the way to prevent recurring mistakes. Codex also supports project/user config layers, skills, and lifecycle hooks/rules, so it can implement strong refocus and gate-local hooks. Sources: <https://developers.openai.com/codex/concepts/customization.md>, <https://developers.openai.com/codex/config-reference.md>, <https://developers.openai.com/codex/config-advanced.md>
- **GitHub Copilot custom instructions** — Copilot supports repository-wide `.github/copilot-instructions.md`, path-specific `.github/instructions/*.instructions.md`, and agent instructions such as `AGENTS.md`, `CLAUDE.md`, or `GEMINI.md` for some agent features. This is useful for making Specrew rules visible to Copilot/Squad, but local lifecycle hooks are weaker than Claude/Codex. For Copilot, GitHub Actions / PR checks are the strongest enforcement surface. Source: <https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions>
- **Cursor rules** — Cursor supports `.cursor/rules/*.mdc`, user/team rules, and `AGENTS.md`. The documentation states that rules provide persistent reusable context at the prompt level. They are good for making Specrew's protocol visible, but weak as hard gates. Source: <https://cursor.com/docs/rules.md>
- **Gemini CLI / Antigravity-style hosts** — Gemini CLI has hierarchical `GEMINI.md`, configurable context filenames such as `AGENTS.md`, `/memory show`, `/memory reload`, workspace/user skills, custom commands, and auto-memory that proposes memory/skill updates for approval. This maps well to Specrew skills plus a deterministic refocus command. Sources: <https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/cli/gemini-md.md>, <https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/cli/skills.md>, <https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/cli/auto-memory.md>, <https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/cli/custom-commands.md>
- **CrewAI** — CrewAI's comparable lesson is that tasks, expected outputs, guardrails, memory, human-input steps, and LLM/tool execution hooks are first-class runtime constructs. Review reliability improves when task output shape and guardrails are structured, not when the reviewer is merely asked to "be careful." Sources: <https://docs.crewai.com/concepts/memory.md>, <https://docs.crewai.com/concepts/tasks.md>, <https://docs.crewai.com/learn/execution-hooks.md>, <https://docs.crewai.com/learn/human-in-the-loop.md>

### Design conclusion from the survey

- Persistent instruction files (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `.cursor/rules/*.mdc`, `GEMINI.md`) **teach and remind**.
- Skills/rules/commands package repeatable Specrew workflows and make gate-specific knowledge discoverable, but they still operate through model context.
- Hooks can refresh context and provide local fast feedback where the host supports them.
- **Specrew-owned artifacts, schemas, validators, and CI are the enforcement authority.**

Therefore Proposal 145 must not depend on any one host's reviewer agent, subagent system, or hook system. It must define the artifacts and validation contract that any host can satisfy.

## Research update — AI false-completion reports and evidence discipline (2026-06-04)

Follow-up research on "AI says the job is done" failures reinforces the core design rule for
145: **the agent's report is an artifact under test, not testimony.** A completion report,
review verdict, or "tests pass" claim is not accepted because the agent wrote it; it is accepted
only when the repository, commands, logs, design trace, and validator agree.

Important sources and findings:

- **AI code assistants can increase overconfidence.** Perry et al. found that participants with
  access to an AI code assistant wrote less secure code and were more likely to believe they had
  written secure code. This is directly relevant to review-signoff: an AI-generated "secure/done"
  statement can raise confidence faster than it raises evidence. Source:
  <https://arxiv.org/abs/2211.03622>
- **Generated code can be plausibly complete but vulnerable.** Pearce et al. generated 1,689
  Copilot programs across high-risk CWE scenarios and found approximately 40% vulnerable. A
  structured review must therefore include security/code-quality checks against the actual code,
  not only acceptance of task completion prose. Source: <https://arxiv.org/abs/2108.09293>
- **Generated dependencies can be hallucinated.** Spracklen et al. analyzed 576,000 generated
  code samples and found package hallucinations across commercial and open-source models. Any
  review claim about new dependencies must be verified against manifests, lockfiles, registry
  evidence, or an explicit no-new-dependency proof. Source: <https://arxiv.org/abs/2406.10279>
- **Executable evaluation is the reliable pattern.** SWE-bench evaluates a generated patch against
  a real GitHub issue, real repository state, and a reproducible Docker evaluation harness, with
  logs and final evaluation results as artifacts. The useful lesson for Specrew is not the exact
  benchmark, but the trust model: patch + reproducible evidence outranks model narrative. Source:
  <https://github.com/SWE-bench/SWE-bench>
- **Inspectable trajectories matter.** SWE-agent and mini-SWE-agent emphasize runnable agent
  trajectories, local/sandboxed execution, and inspectable histories. For Specrew, every
  review-signoff should leave a replayable proof trail: changed files, commands, exit codes,
  logs, evidence artifacts, and the final structured report. Sources:
  <https://github.com/SWE-agent/SWE-agent>, <https://github.com/SWE-agent/mini-swe-agent>

### Design conclusion from the false-completion research

- Treat `review.md`, `review-report.yml`, and any agent-authored "job done" packet as
  **claims to validate**, not ground truth.
- Require a **claim-to-evidence ledger**: each material report claim maps to file/line,
  test command/log, design node, diagram edge, commit, or manual evidence.
- Require a **design/code/diagram trace**: every material design component, flow, and diagram
  edge maps to implementation files/functions and at least one test/evidence pointer, or records
  an explicit drift/deferral.
- Add deterministic **anti-pattern scans** for common AI/developer shortcuts (sleep-based
  synchronization, broad catch-and-ignore, hidden global state, unbounded retries, test-only
  production behavior, fake fixtures, hallucinated dependencies).
- Add a dedicated **report-falsification step** before approval: try to disprove the report by
  rerunning claimed commands, checking uncommitted evidence, comparing code to design, and
  looking for stronger-than-proof language.
- Preserve the existing boundary: semantic judgment still belongs to reviewer/human, but the
  validator must reject unsupported or over-strong claims.

## Research update — workshop-decision conformance (2026-06-08)

Proposal 163 adds a `code-implementation` workshop lens that records
implementation-craft rules, but Proposal 145's obligation is broader than code
quality. Every workshop-bound decision is a review input: components by exact
name and responsibility, data structures and invariants, integration contracts,
UI layout decisions, security boundaries, devops/operations choices,
observability requirements, NFR decisions, and code-implementation rules.
Generic phase checks such as "clean code" or "design matches code" are no
longer enough when the human already approved concrete workshop decisions.

Design conclusion:

- Review must load all workshop decision records: `lens-applicability.json`,
  the Proposal 156 `workshop-decisions.yml` producer manifest, `workshop/*.md`,
  design-analysis Co-Design Record, `plan.md`, `data-model.md`, contracts,
  review diagrams, and the Proposal 163 implementation-rule manifest or
  manifest section when present.
- Every selected workshop decision gets a disposition: `satisfied`, `violated`,
  `n/a-with-reason`, or `accepted-exception`.
- Structural decisions require exact matching: component names,
  responsibilities, layer/ownership, dependency direction, data entities,
  fields, validation rules, contract fields, and diagram edges must map to
  implementation files/functions and behavioral evidence.
- Decision-prompt rules and lens decisions require the human's recorded decision
  or an accepted exception; applicability-filtered rules require a reason when
  marked `n/a`.
- Enforcement modes are evidence obligations. If a decision says analyzer,
  linter, compiler, test, approval test, runtime policy, diagram trace, or
  review must enforce it, the corresponding evidence must be present.
- Accepted exceptions must update the relevant design/plan/task artifact or
  flow through Proposal 174's boundary-variance path, so implementation reality
  can change the plan without silently erasing the prior decision.

## Gate review model — cheap gate checks plus full review-signoff

145 is the deep implementation review for the `review-signoff` boundary. Running all seven phases after every gate would be too heavy and would turn normal governance into review fatigue.

The better model is two-tier:

1. **Gate-local preflight before every human approval packet.** Each human-judgment boundary runs a small checklist for only the responsibilities of that gate, records evidence, then presents the packet only if the preflight passes. These checks are cheap, deterministic where possible, and designed to catch drift near the source.
2. **Full Proposal 145 review at `review-signoff`.** The structured reviewer loads the earlier gate-local evidence, then runs the seven-phase implementation review.

Gate-local checks are not merely retrospective notes. Before the Crew asks the
human to approve a boundary, it must reconstruct state from artifacts and run the
boundary's preflight: scoped validator, branch/upstream parity, dirty-state
classification, required artifact existence, stale-state/stale-phrase scan,
packet-vs-artifact consistency, and any boundary-specific evidence checks. If
preflight fails, the Crew self-sends-back: it records the failure, fixes or
classifies the issue, reruns the preflight, and only then re-presents the human
approval packet. The human should not be the first detector for mechanical or
artifact-consistency defects.

Hooks are an execution accelerator for this preflight, not the authority. Claude
Code and any host with lifecycle hooks can trigger the same preflight before a
menu or final stop; hosts without a comparable hook must run it through the
Specrew lifecycle command path and CI/validator checks. In every topology, the
source of truth remains the Specrew artifacts plus validator output, not the
agent's report.

Gate-local examples:

- `before-spec`: requirements captured, assumptions and clarifications recorded, no implementation drift.
- `before-plan`: FR/SC traceability exists, risks/capacity visible, no hidden overcommit.
- `before-implement`: tasks map to FR/SC, hardening gate ready, no unresolved send-back.
- `review-signoff`: full seven-phase structured review.
- `retro`: evidence, drift, lessons, deferrals, closeout consistency.

This makes the final review more likely to pass for the right reason: earlier boundaries already produced structured evidence, and the final reviewer is not rediscovering basic governance drift at the end.

## What — 7-Phase Structured Reviewer

Each phase has a focused scope, dedicated check list, and per-phase verdict (`pass | rework | reject | n/a + reason`). Phases compose into a machine-readable matrix output validated by a static coverage rule.

### Phase 0 — Context load (before-review surface)

Reviewer skill loads:

- Feature spec (FRs + SCs + acceptance scenarios)
- Iteration plan (tasks + traceability)
- Prior iteration retros + drift logs
- Code-map for the iteration's diff
- Data structures + flows referenced in spec/plan
- Design artifacts, diagrams, Mermaid blocks, architecture notes, and data-flow descriptions
- Agent completion packets, review drafts, coverage evidence, and other generated reports whose
  claims must be validated
- Prior boundary commits + their evidence pointers
- Existing reviewer-instructions.md playbook (Proposal 140 surface)

Output: context-pack handed to subsequent phase agents. Memoizable per Proposal 086 Pillar 1.

### Phase 1 — Branch hygiene

Checks:

- Branch pushed to origin? `git rev-parse HEAD == git rev-parse origin/<branch>`?
- Working tree clean OR every dirty file explicitly classified (iter scope vs out-of-scope)?
- Main divergence + conflict topology (does main need to be merged in before next iter)?
- Shape 5 audit: every file cited as evidence in review.md is actually committed (not working-tree-only)
- Boundary commit cadence honored (Proposal 082)
- Upstream parity check

### Phase 2 — Functional correctness

Checks:

- Logic correctness (manual trace + test trace, no auto-pass on test-green alone)
- Error handling (every throw point has a handler OR explicit propagation rationale)
- Edge cases (empty, null, max, concurrent, partial-failure)
- Side effects + system state on failure
- Concurrency + race conditions
- Data integrity (transactional boundaries, atomicity)
- Idempotency (for distributed / retry paths)
- **Workshop/design/code/diagram conformance:** every selected lens decision,
  material design component, named responsibility, data structure, contract
  field, diagram node/edge, and data-flow claim maps to implementation
  files/functions and behavioral evidence; mismatches are recorded as drift,
  rework, or accepted design change with rationale
- **Claim-to-code trace:** any report claim that "X was implemented" cites the changed files,
  functions, commits, or generated artifacts that implement X

### Phase 3 — Non-functional requirements

Checks:

- Security: input validation, secrets handling, injection vectors, authn/authz, sensitive-data redaction in logs
- Logging: every error path logged, structured fields, PII discipline
- Observability: metrics + traces (superset of logging) + audit trail
- Performance: hot-path complexity, allocations, I/O patterns
- Scalability: large-input behavior, resource ceilings
- Cost: cloud spend, AI token usage (per-iteration cost.yml per Proposal 070)
- Accessibility: UI keyboard nav, ARIA, contrast (UI features only)
- i18n + encoding: UTF-8 / RTL / non-Latin (Hebrew filename incident lesson from PlanningPoC)
- Operability: rollback path, feature flags, kill-switch

### Phase 4 — Code quality

Checks:

- Style + linter clean (markdownlint, PSScriptAnalyzer, language-specific)
- Workshop-chosen implementation-rule conformance: as the code-quality subset of
  `workshop-decision-conformance.yml`, load the `code-implementation` section
  from `workshop-decisions.yml` and/or the linked Proposal 163 rule manifest,
  then check every selected rule, including baseline defaults, decision-prompt
  rules, applicability-filtered rules, and enforcement modes
- SOLID (single responsibility, open/closed, dependency inversion, etc.)
- DRY violations
- DTOs / type discipline at boundaries (no leaking internals)
- Clean code: naming, cognitive complexity, magic numbers, file organization
- Dependency intent (license, cost, alternatives, reversibility) per `[[project-plan-time-dependency-intent-proposal-candidate-2026-05-27]]`
- Dependency reality check: new package/import/module claims are verified against manifests,
  lockfiles, repository files, registry evidence, or an explicit no-new-dependency proof
- Anti-pattern catalog scan (deterministic where practical, reviewer judgment where needed):
  sleep/time-delay as synchronization, broad catch-and-ignore, hidden/global mutable state,
  unbounded retries/poll loops, command output swallowed without assertion, test-only behavior in
  production paths, generated placeholder logic, over-broad regex/path matching, hard-coded
  environment assumptions, and fake/synthetic fixtures where real evidence is required
- No dead code / commented-out blocks
- Comment-vs-comment-rot discipline per `[[proposal-074-code-commentary-standards]]`
- Rule-level disposition ledger: each chosen implementation rule is marked
  `satisfied`, `violated`, `n/a-with-reason`, or `accepted-exception` inside
  the broader workshop-decision conformance ledger; accepted exceptions include
  rationale and point to the artifact update or variance path

### Phase 5 — Test coverage + integrity

Checks:

- Coverage breadth: every FR has at least one test
- Test isolation: no shared state, deterministic
- Fixture realism (Shape 6 check): synthetic stand-in vs real anchor dataset
- Skip-guard discipline + provenance: what runs deterministically vs only on dev machine
- Producer/consumer demonstration: new producer code has consumer-side demo test (F-049 iter-005 meta-rule)
- Gate completeness (Shape 8): does the gate cover what its spec CLAIMS, not just exist? Inverse-direction checks?
- Guardrails: explicit assertions on invariants
- Tests-actually-run-at-review evidence (closes coverage-evidence drift from F-050 iter-002)
- Evidence replay: material "tests pass" claims include exact command, environment/scope,
  exit code, timestamp or run id, and log/result path; reviewer reruns or explains why replay is
  not possible
- Negative/falsification cases: where a gate or validator is added, review must include at least
  one failure-mode proof showing the gate fails for the target defect class, not only a passing
  happy path

### Phase 6 — System safety + ops

Checks:

- Failure modes catalogued + tested
- Rollback path documented + reversible
- Backward compatibility: API contract, breaking-change analysis
- Deprecation discipline: timelines + migration notes
- Compliance: privacy, retention, regulatory
- Audit trail: who/when/what
- Multi-developer collision surface per `[[project-multi-dev-constraint-2026-05-27]]`

### Phase 7 — Output synthesis + report falsification

Machine-readable `review-report.yml` augmenting human-readable `review.md`:

```yaml
matrix:
  - requirement: FR-005
    phases:
      phase_0: { applicable: yes, evidence: [<paths>] }
      phase_1: { applicable: yes, finding: clean }
      phase_2: { applicable: yes, finding: clean, evidence_ref: tests/integration/host-cursor.tests.ps1 }
      phase_3: { applicable: no, reason: "no NFR aspect" }
      phase_4: { applicable: yes, finding: clean }
      phase_5: { applicable: yes, finding: skip-guard-provenance-documented, severity: info }
      phase_6: { applicable: no, reason: "no ops impact" }
claim_ledger:
  - claim: "FR-005 implemented"
    evidence:
      - type: code
        path: src/example.ps1
        symbol: Invoke-Example
      - type: test
        command: ./tests/example.tests.ps1
        exit_code: 0
design_trace:
  - design_ref: design-analysis.md#option-b-flow
    implementation: [src/example.ps1]
    evidence: [tests/example.tests.ps1]
    status: matched
workshop_decision_conformance:
  - decision_id: component.session-bootstrap-manager
    source: workshop/component-design.md
    expected: "SessionBootstrapManager orchestrates bootstrap only"
    implementation: [src/SessionBootstrapManager.ps1]
    evidence: [tests/SessionBootstrapManager.Tests.ps1]
    disposition: satisfied
  - decision_id: data.bootstrap-directive.required-reads
    source: data-model.md
    expected: "required_reads carries mandatory artifacts for the directive"
    implementation: [src/DirectiveEngine.ps1]
    evidence: [tests/DirectiveEngine.Tests.ps1]
    disposition: satisfied
  - decision_id: code-rule.object-invariants
    source: implementation-rules.yml
    disposition: satisfied
    evidence: [src/example.ps1, tests/example.tests.ps1]
verdict:
  per_phase: { phase_0: pass, phase_1: pass, phase_2: pass, phase_3: n/a, phase_4: pass, phase_5: pass, phase_6: n/a }
  overall: APPROVE for review-signoff
```

Verdict aggregation rule:

- Any phase = `reject` → overall `REJECT`
- Any phase = `rework` → overall `REWORK`
- All applicable phases = `pass` → overall `APPROVE for review-signoff` (per `[[feedback-verdict-boundary-naming-2026-05-22]]`)
- Phases marked `n/a` require a populated `reason` field (static validator enforces this)

Report-falsification rule:

- Before approval, the reviewer must attempt to disprove the generated report by checking that
  cited evidence exists, is committed/reachable, matches the claim strength, and is not contradicted
  by the diff, design artifacts, test logs, or validator output.
- A report claim with no supporting evidence is downgraded to `unsupported`.
- A report claim that is stronger than the evidence (for example, "CI passed" with only a local
  run, "security reviewed" with only lint, or "diagram implemented" with no code/diagram trace)
  is a `rework` finding unless explicitly corrected before signoff.

## Architecture (deliverable shape)

- Host-neutral review protocol, with a Squad/Copilot reviewer agent as the first executor implementation
- Invocable Reviewer skill at `extensions/specrew-speckit/squad-templates/skills/specrew-review-structured/SKILL.md` deployed per-host (`.agents/skills/`, `.claude/skills/`, `.copilot/skills/`, `.github/skills/`, `.cursor/rules/`, etc. per Proposal 058)
- Agent-mediated phase fan-out: each semantic review phase is executed by the coordinator/reviewer agent, using focused sub-agents where available (per `[[proposal-139-multi-agent-subagent-orchestration]]` / F-051)
- Without F-051: sequential single-agent phase execution (lower fidelity but functional)
- Deterministic scripts own workplan generation, schema validation, completeness checks, and aggregation; they do not directly invoke LLM reviewers as hidden side effects
- Output artifacts: `review-workplan.yml` (required phases, prompt files, input artifacts, expected outputs, schemas, ordering constraints), per-phase structured findings under `review-findings/`, `review-report.yml` machine-readable + traceable, `review-claim-ledger.yml` for claim-to-evidence validation, `design-code-trace.yml` for design/diagram/code conformance, `workshop-decision-conformance.yml` for all workshop-bound decisions, and `review.md` human prose synthesizing the matrix
- Static coverage validator: rule in `validate-governance.ps1` that fails the review-signoff boundary if structured outputs are missing, schema-invalid, incomplete, have FR phase coverage gaps without explicit `n/a + reason`, or contain unsupported/over-strong report claims; it validates evidence shape, reachability, claim strength, and aggregation rules, not semantic correctness by itself
- Per-phase memoization (Proposal 086 Pillar 1) — context-load is the most expensive phase; cache per-iteration

### Host-neutral execution contract

The contract is expressed as files and validator rules, not as a particular host's agent topology.

Required inputs:

- Active feature + iteration state (`state.md`, `tasks-progress.yml`, `plan.md`, `spec.md`, drift log, coverage evidence, quality gates).
- FR/SC matrix and task ledger.
- Boundary history and commit evidence (`pre_sha`, `post_sha`, boundary verdicts, and gate-local evidence).
- Changed files and branch status.
- Test commands + results, with explicit distinction between local-only, CI-reached, skipped, and not-run evidence.
- Design diagrams, data-flow descriptions, option decisions, and accepted design deltas.
- Workshop/lens decision records (`lens-applicability.json`,
  `workshop-decisions.yml`, `workshop/*.md`, design-analysis Co-Design Record,
  `plan.md`, `data-model.md`, contracts, review diagrams, and accepted deltas),
  including the Proposal 163 code-implementation rule manifest or manifest
  section when present.
- Agent-authored completion/review/coverage reports whose material claims must be verified.
- Prior review/retro findings and unresolved deferrals.
- `/specrew.refocus` output once that command exists; until then, the equivalent context pack produced by the existing start/resume surfaces.

Required outputs:

- `review-workplan.yml`: the deterministic plan for the seven phases, required inputs, expected outputs, schemas, order/parallelism rules, and applicability hints.
- `review-findings/phase-0-context.yml` through `review-findings/phase-6-system-safety.yml`: one structured finding file per semantic phase.
- `review-report.yml`: machine-readable aggregation and FR/SC × phase coverage matrix.
- `review-claim-ledger.yml`: every material approval/completion/test/design/dependency claim from
  `review.md` or generated packets mapped to supporting evidence, or marked `unsupported`.
- `design-code-trace.yml`: design components, diagrams, data flows, and option decisions mapped to
  implementation files/functions and tests/evidence, or marked drift/deferral with rationale.
- `workshop-decision-conformance.yml`: every selected decision from
  `workshop-decisions.yml` mapped to disposition, evidence, and exception or
  applicability rationale. This includes component names/responsibilities, data
  structures, contracts, diagrams, security/integration/devops/observability/NFR
  decisions, supplemental pack decisions from Proposal 175, and Proposal 163
  implementation rules when applicable.
- `review.md`: human-readable synthesis, with links to the structured report and any blocking findings.

Validator obligations:

- Fail or warn (per adoption phase) if any required artifact is missing.
- Fail if YAML schema is invalid.
- Fail if any FR/SC lacks coverage for an applicable phase.
- Fail if a phase is marked `n/a` without a non-empty reason.
- Fail if `review.md` cites evidence that is not committed or not reachable.
- Fail if test evidence claims are stronger than the recorded proof (for example, "CI-reached" without a CI run/link/hash).
- Fail if a material `review.md` / completion-packet claim lacks a `review-claim-ledger.yml`
  entry, or the entry has no evidence.
- Fail if a code/design/diagram conformance claim lacks a `design-code-trace.yml` entry.
- Fail if a selected `workshop-decisions.yml` decision lacks a
  `workshop-decision-conformance.yml` entry.
- Fail if a named component/responsibility, data structure, contract field,
  diagram edge, or selected code rule has no implementation/evidence mapping and
  no accepted exception or variance reference.
- Fail if a decision-prompt rule or lens decision lacks a recorded human
  decision, accepted exception, or variance reference.
- Fail if a decision's declared enforcement mode has no corresponding evidence.
- Fail if a decision is marked `n/a` without a non-empty applicability reason.
- Fail if a dependency/import/package claim is not backed by manifest, lockfile, local file, or
  registry/source evidence.
- Fail if a command/test claim lacks command text, exit code, and result/log evidence.
- Fail if anti-pattern scans find blocking patterns without a documented reviewer disposition
  (`accepted_with_rationale`, `false_positive`, or `rework`).
- Fail if review-signoff is approved while any phase verdict is `reject` or `rework`.

Semantic judgment remains with the reviewer agent/human reviewer. Structural completeness, evidence
presence, evidence reachability, and claim-strength discipline belong to deterministic validation.

### Executor topologies

Any of these topologies may satisfy the same file contract:

1. **Current Squad/Copilot topology** — one reviewer agent coordinates all phases and may ask other Squad roles for evidence. This is the immediate implementation path.
2. **Squad phase-specialist topology** — reviewer orchestrates phase-specific agents (functional reviewer, test-integrity reviewer, ops reviewer, etc.) when the host/runtime supports it.
3. **Claude/Codex subagent or hook-assisted topology** — host lifecycle hooks run `/specrew.refocus`; review skills execute phases; deterministic validators enforce artifact shape.
4. **Cursor/Copilot rules topology** — always-loaded rules/custom instructions keep the protocol visible; the reviewer agent or human explicitly runs the structured review; CI/validator enforces outputs.
5. **Human-assisted topology** — if a host cannot reliably execute a phase, the workplan permits a human to fill the phase finding file, but the schema and validator still apply.

The proposal intentionally separates "who performs the review" from "what evidence must exist." This is what preserves portability when Specrew moves from Copilot/Squad-only multi-agent execution to teams in other AI hosts.

### Host capability matrix

| Host | Persistent rule surface | Workflow packaging | Lifecycle hooks / triggers | Specrew enforcement posture |
| --- | --- | --- | --- | --- |
| Copilot + Squad | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `AGENTS.md`, `.github/agents/*.agent.md` where supported | `.copilot/skills/*`, agent charters, Squad roles | Weak local lifecycle; strong GitHub Actions / PR checks | Use Squad reviewer as first executor; enforce with Specrew validator + CI |
| Claude Code | `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*`, auto memory | `.claude/skills/*`, slash commands | Strong: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `PreCompact`, `PostCompact` | Good candidate for automatic refocus and hook-assisted local gate checks; still validate artifacts |
| Codex | `AGENTS.md`, nested `AGENTS.md`, `.codex/config.toml`, project/user config | `.agents/skills/*`, plugins, custom skills | Strong: project/user hooks including `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PreCompact`, `PostCompact`, `Stop`; command rules | Good candidate for automatic refocus and managed hook policy; still validate artifacts |
| Cursor | `.cursor/rules/*.mdc`, `AGENTS.md`, user/team rules | Cursor rules, prompts, skills where available | Limited lifecycle compared with Claude/Codex | Use rules for visibility; rely on explicit command + validator/CI for enforcement |
| Gemini CLI / Antigravity-style | `GEMINI.md`, configurable context filenames such as `AGENTS.md`, memory reload/show | `.gemini/skills`, `.agents/skills`, custom commands | Host-specific; less standard than Claude/Codex for Specrew today | Use skills/commands + refocus; validator remains authority |
| CrewAI-style framework | Programmatic agent/task definitions and memory | Tasks, expected outputs, guardrails, flows | LLM/tool execution hooks, human-input workflows | Design reference: make review outputs and guardrails first-class |

### Prompt/context vs enforcement rule

145 adopts the following non-negotiable rule:

- Instruction files, skills, rules, and memory make Specrew knowledge available to the host.
- Hooks refresh or block opportunistically where the host supports them.
- The Specrew validator and CI are the only authority for whether the `review-signoff` boundary is valid.

This prevents a host migration from weakening review discipline. A host may forget a rule; the boundary cannot pass without the required files and validator checks.

### Deterministic-script / agent-execution boundary

Structured review uses an agent-mediated fan-out protocol. Scripts may prepare and validate review work, but they must not directly invoke LLM reviewers as hidden side effects.

Flow:

1. The session runs `/specrew.refocus` when available, or the current equivalent resume/start context pack, to reconstruct state from artifacts rather than chat memory.
2. A deterministic script emits `review-workplan.yml` describing the required phase checks, prompt files, input artifacts, expected output files, schemas, and dependency/order constraints.
3. The coordinator or reviewer agent reads the workplan and executes each semantic phase review, using subagents where available (Proposal 139) or sequential single-agent phase execution otherwise.
4. Each phase writes a structured result such as `review-findings/phase-<n>.yml` with verdict, evidence, findings, and `n/a` reasons.
5. A deterministic aggregation/validation script checks schemas, required phase coverage, file existence, FR/SC coverage, and verdict aggregation rules, then produces or verifies `review-report.yml`.
6. `validate-governance.ps1` gates the boundary on the presence and schema/completeness of the structured outputs; it does not itself perform semantic LLM judgment.

This keeps scripts deterministic and auditable while keeping semantic review in the agent layer.

## Composition map

- `[[proposal-140-reviewer-instruction-surface]]` — runtime realization of the Per-Boundary Checklist Matrix; 145 makes 140's playbook structurally enforceable
- `[[proposal-102-cross-model-independent-reviewer]]` — different reviewer models per phase (specialty per phase) — Phase 2 functional review could use one model, Phase 3 security review another
- `[[proposal-139-multi-agent-subagent-orchestration]]` (F-051) — runtime substrate for multi-agent dispatch
- `[[197-continuous-co-review]]` — shifts these review dimensions LEFT to the edit boundary (continuous inline co-review); 197 runs the dimensions inline against the design contract while 145 stays the guaranteed review-signoff backstop
- `[[proposal-157-verdict-menu-instruction-text-capture]]` — adjacent gate UX bug: instruction-bearing verdict options must capture free-form text before dispatch; 145 depends on verdict packets being truthful
- `[[proposal-086-validation-pipeline-performance-bundle]]` — Pillar 1 memoization applies per-phase
- `[[proposal-021-bypass-detector]]` — Phase 5 gate-completeness check is structural realization of the bypass-detector concept
- `[[proposal-074-code-commentary-standards]]` — Phase 4 code-quality references the commentary standards
- `[[156-design-analysis-lens-knowledge-catalog]]` — produces the canonical
  `workshop-decisions.yml` manifest that 145 consumes and validates against
- `[[163-code-implementation-lens]]` — Phase 4 consumes the
  workshop-selected implementation rules and enforcement modes as one section of
  the broader `workshop-decisions.yml` input and workshop-decision conformance
  ledger
- `[[174-boundary-variance-disclosure]]` — if implementation reality violates or
  changes any chosen workshop decision (component map, data model, contract, UI,
  security/integration/ops decision, or code rule), review requires either
  rework or an accepted variance with artifact reconciliation
- `[[proposal-070-token-economy-mvp]]` — Phase 3 cost check references the per-iteration cost.yml
- `[[proposal-142-state-truth-integrity-validator]]` — Phase 1 state-truth check composes with 142's validator rule
- `/specrew.refocus` (proposal/spec TBD) — prerequisite or companion for host-neutral re-entry after compaction/session drift; 145 consumes its output but should not own the whole refocus feature
- `[[project-iter5-undercoverage-producer-consumer-2026-05-29]]` — formalized as Phase 5 sub-check
- `[[project-shape8-filelist-directional-blindspot-2026-05-30]]` — formalized as Phase 5 gate-completeness sub-check
- `[[project-multi-dev-constraint-2026-05-27]]` — Phase 6 collision-class checks
- `docs/methodology/lifecycle-discipline.md` Shape Catalog — Phase 5 references this for each Shape's check (Shape 5 working-tree → Phase 1; Shape 6 synthetic fixture → Phase 5; Shape 8 directional → Phase 5)

## Sizing + sequencing

- ~35-50 SP, 3-iteration decomposition plus optional prep slice:
  - **Iter 0 / prep slice (~3-5 SP, optional):** host-neutral contract finalization, schema names, and `/specrew.refocus` input contract alignment if the refocus proposal/spec lands first
  - **Iter 1 (~10-15 SP):** core skill scaffold + Phase 0-2 (context load + branch hygiene + functional correctness) + skeleton matrix output, implemented first for the current Squad/Copilot reviewer topology
  - **Iter 2 (~10-15 SP):** Phase 3-5 (NFR + code quality + test coverage + integrity)
  - **Iter 3 (~10-15 SP):** Phase 6-7 + static coverage validator + integration with existing review.md + host deployment
- Natural slot: F-053 or replaces F-052 (Design Alternatives Gate per the post-F-049 sequencing); user decides at sequencing review whether to substitute
- Prerequisite: F-051 multi-agent subagent orchestration (Proposal 139) for multi-agent dispatch; without it, sequential single-agent phase invocation is functional but lower fidelity
- Host migration strategy: implement the artifact contract once, then add host adapters incrementally. Do not block the first implementation on perfect host parity.
- Boundary strategy: define the host-neutral gate-preflight contract here: run cheap gate-local checks before the human approval packet, self-send-back on failures, and keep the full seven-phase review scoped to `review-signoff`.

## Open questions for proposal-to-spec conversion

- Per-phase reviewer model selection: always same model, or specialty per phase (composing with Proposal 102)?
- Phase ordering enforcement: must run in order, or parallel where independent (e.g., Phase 3 + Phase 4 are independent)?
- Cache strategy for context-load: per-iteration vs per-boundary?
- Threshold tuning: what severity level blocks vs. warns at each phase?
- Integration with existing `review.md` format: does the structured report SUPERSEDE or AUGMENT? Recommendation: augment for migration safety, propose supersede as a follow-up after empirical adoption.
- Backward compatibility for reviewers/Crews that don't have the skill installed: fall back to current narrative review with a soft warning?
- Should the static coverage validator hard-block boundary advancement, or warn? Recommendation: warn during adoption period, hard-block after 3+ features ship through it.
- Should gate-local checks live in this proposal or a sibling refocus/gate-hardening proposal? Recommendation: define the pre-human-packet interface here, implement the broad reusable preflight runner in refocus/gate-hardening work so 145 stays focused on full review.
- Should host hooks be installed automatically by Specrew update/init, or only generated as opt-in examples? Recommendation: opt-in at first, because hook support and trust prompts differ by host.
- How should a human reviewer fill phase files when an AI host cannot execute a phase reliably? Recommendation: allow manual phase files if they satisfy the schema and include `reviewer: human`.
- How should phase outputs cite web/current external evidence? Recommendation: require links in evidence arrays and an explicit "external evidence used" flag when a phase relies on current docs/laws/prices/security advisories.

## Open work items (deferred to spec)

- Define the canonical phase-checklist content for each of the 7 phases (this proposal sketches dimensions; the spec defines the exact checks)
- Define the `review-report.yml` JSON Schema for validator-side enforcement
- Define the `workshop-decision-conformance.yml` schema and how it references
  the Proposal 156 `workshop-decisions.yml` producer manifest, lens records,
  co-design records, component maps, data models, contracts, Proposal 163 rule
  manifests, Proposal 175 supplemental pack decisions, evidence, accepted
  exceptions, and boundary variance records.
- Define the per-phase agent charter (charter snippet for each phase agent, similar to existing role charters)
- Decide on the host-deployment shape for the invocable skill (Proposal 058 SDK alignment)
- Backfill strategy: do we re-run structured review on closed iterations as a one-shot quality audit?
- Define the gate-local checklist interface consumed by 145 at review-signoff (boundary verdicts, commit evidence, validator results, drift-log references).
- Define the gate-preflight result artifact/schema consumed before each human approval packet: boundary name, command list, validator status, stale-phrase scan, branch/upstream parity, dirty-state classification, artifact consistency findings, and self-send-back actions when failures are found.
- Define the host adapter mapping for the first four supported surfaces: Copilot/Squad, Claude Code, Codex, and Cursor.
- Define the "instruction visibility" invariant that must be deployed to always-loaded host files: before a Specrew gate, reconstruct state from artifacts and validators, not from chat memory.

## Risks

- **Reviewer fatigue / overhead:** 7 phases × per-phase agent invocation is heavier than current single-pass review. Mitigate via memoization (Proposal 086) + n/a-with-reason support + phase-skip when applicability is unambiguous.
- **Phase-agent disagreement:** multi-agent dispatch may produce conflicting verdicts. Mitigate via verdict aggregation rule (defined above) + escalation to human at conflict.
- **Static validator false-positives during adoption:** rules may flag legitimate `n/a` patterns. Mitigate via warn-then-block adoption phasing.
- **Skill installation drift across hosts:** the structured skill needs deployment in `.claude/skills/`, `.github/skills/`, etc. — risk of host drift. Mitigate via Proposal 058 SDK + Proposal 132 mirror-parity validator.
- **Prompt-only false confidence:** host instruction files and skills can still be ignored or dropped after compaction. Mitigate by treating them as reminders only; the validator must enforce artifacts.
- **Hook portability gap:** Claude/Codex have useful lifecycle hooks, while Copilot/Cursor/Gemini-style hosts differ. Mitigate by making hooks optional accelerators, never the only gate enforcement.
- **Current Squad/Copilot coupling:** the first implementation will naturally fit the current reviewer-agent flow. Mitigate by keeping the file contract host-neutral and documenting Squad as one executor topology, not the protocol itself.
