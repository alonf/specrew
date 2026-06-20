# Feature Specification: Host-Neutral Lifecycle Gate Enforcement

**Feature Branch**: `185-host-neutral-gate-enforcement`  
**Created**: 2026-06-19  
**Status**: Draft  
**Input**: User description: "Enforce Specrew lifecycle gates consistently across all host harnesses (issue #2884) — host-neutral enforce-or-halt + instruction cleaning."

## Product-Domain Summary

- **Depth**: standard (feature_standalone)
- **users_stakeholders**: Downstream Specrew users on every host — especially hookless/non-Claude hosts (Antigravity, Copilot, Cursor) where boundary enforcement is weakest — plus Specrew maintainers validating cross-host parity. Harmed parties: any user whose host silently self-advances past a human-judgment boundary, defeating the portability of the governance guarantee.
- **pain_job**: A host can self-authorize past a human-judgment boundary (issue #2884: Antigravity wrote `plan.md` with no captured verdict despite `boundary_enforcement.enabled` + all classes `human-judgment-required` + empty `verdict_history`). Root cause: (1) the refocus digest deployed to all hosts names the Claude-only `specrew-gate-stop` skill / `AskUserQuestion` tool a non-Claude host cannot act on, and (2) nothing mechanically blocks the next-phase write — the gate seat is dormant + fails open + no host registers it, and the verdict check fires only inside the sync-wrappers after the artifact is already written.
- **mvp**: Make the deployed agent-instruction digests harness-free; add a host-neutral gate-stop fallback that renders the packet AND emits the verdict marker on non-Claude hosts; declare each host's enforcement capability and route through its strongest available lever; halt with an infrastructure/process failure when a host cannot enforce; prove parity + gate-detection with tests; dogfood the greenfield run across the host set. The guarantee: no host silently self-advances — enforce-or-halt.
- **out_of_scope**: The hard *uniform* mechanical write-block on every host (host-variable — Claude can `PreToolUse`-gate via the dormant seat; Antigravity's `PreInvocation`/`Stop` model cannot deny a per-tool-call write) — research-flagged. The full Proposal-188 capability matrix (185 is its first P0 slice). No new parallel enforcement system. No broad host-model rewrite (split-guard stops for a human verdict if one is required).
- **constraints**: Reuse the existing refocus engine, the dormant gate seat + dispatcher, Proposal-065 authorization (`Test/Add-SpecrewBoundaryAuthorization`, `start-context.json` / `verdict_history`), the Claude `specrew-gate-stop` skill, and `HandoverStore` verdict-marker capture. Edit refocus SOURCE files under `extensions/specrew-speckit/`, never the `.specify/...` synced mirror. No new dependencies. Honest cross-host degraded modes — no promise of mechanical prevention everywhere.
- **Follow-up research**: Confirm per-host the strongest available enforcement lever before a human-judgment write (Claude `PreToolUse`; Antigravity `PreInvocation`/`Stop`; Copilot/Cursor); confirm the dormant gate seat can be activated as a real `deny`/`ask` provider without a broad host-model change (split-guard).
- Full record: see `workshop/product-domain.md` and `workshop/product-domain.yml`.

## Clarifications

### Session 2026-06-19

- **Enforce-or-halt north star**: The feature's guarantee is that no host silently self-advances past a human-judgment boundary. Each host enforces with its strongest available runtime lever, or it halts with an infrastructure/process failure. Cleaning the instructions is necessary (a host cannot obey an instruction it cannot act on) but not sufficient; the enforcement guarantee is the goal.
- **Harness-free cleaning**: The refocus digests that reach all hosts (`general.md` rule-9, `specify.md` step-6/traps) become a single host-neutral instruction naming no host and no Claude-only skill/tool. Per-host regeneration is used only where a host must name its own mechanism.
- **Research split**: The hard *uniform* mechanical write-block is host-variable and out of scope / research-flagged; the achievable guarantee is enforce-or-halt via per-host levers + the cleaned instructions + the degraded halt mode.
- **Split-guard**: If activating real enforcement requires a broad host-model rewrite rather than a bounded gate-provider + digest + fallback change, the feature MUST stop for a human split/defer verdict.

## Design Workshop Summary

The specify workshop completed these lenses (all human-confirmed):

- **product-domain**: the MVP above and the enforce-or-halt goal.
- **architecture-core**: capability-matrix enforce-or-halt built on the existing dormant gate seat + 065 authorization; harness-free cleaning; split-guard armed.
- **component-design**: reuse-heavy (refocus engine, gate seat + dispatcher, 065 authorization, the Claude gate-stop skill, `HandoverStore` capture, host manifests) + four focused additions (host-neutral fallback renderer with marker emission, per-host capability declaration, a gate provider on the seat, non-Claude verdict capture).
- **data-storage**: reuse `start-context.json` (`boundary_enforcement` + `verdict_history`) via `SessionStateAccessor`; the `SPECREW-VERDICT-BOUNDARY` marker is the verdict-capture mechanism; per-host capability is a static `host.psd1` field.
- **integration-api**: host-appropriate refocus-digest render; gate-provider decision (`PreToolUse permissionDecision` where available, the host's strongest lever otherwise); the marker as the host-neutral verdict contract.
- **observability-resilience**: fail-open where over-blocking would break legitimate work, halt/fail-closed when a human-judgment boundary cannot be enforced; loud WARN reason codes; bounded evidence, no full-transcript logging.
- **devops-operations**: deploy via existing mechanisms (`deploy-squad-runtime.ps1` host-scoping; refocus/instruction deploy); opt-out respected; no new deploy surface.
- **requirements-nfr**: the no-silent-advance guarantee is the core NFR; honest degraded modes; real-host dogfood evidence; the gate stays cheap.
- **ui-ux**: n/a (no application UI; the only UX is the boundary-stop packet, owned by the packet contract).
- **code-implementation**: existing PowerShell baseline craft; the gate provider + fallback renderer follow the dispatcher/provider patterns; explicit fail-open/closed discipline; no new dependencies.

Full records under `workshop/`; implementation craft rules in `implementation-rules.yml`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A non-Claude host cannot silently self-advance (Priority: P1)

As a downstream Specrew user running a non-Claude host (Antigravity/Copilot/Cursor), I want the host to render the boundary packet and either capture a verdict or halt at a human-judgment boundary, so it cannot write the next phase's artifact without my authorization.

**Why this priority**: This is the #2884 bug; the portability of the governance guarantee depends on it.

**Independent Test**: Reproduce the #2884 greenfield scenario on a non-Claude host with `boundary_enforcement.enabled` + empty `verdict_history`. Verify the host renders the packet and either captures a verdict before advancing or halts — it does NOT produce the next-phase substantive artifact silently.

**Acceptance Scenarios**:

1. **Given** a governed feature at `clarify` with no `clarify -> plan` verdict, **When** a non-Claude host reaches the plan step, **Then** it renders the six-section packet, captures the verdict marker on approval, and does not write `plan.md` before the verdict exists — or halts with a process failure.
2. **Given** a host with no enforcement lever, **When** it reaches a human-judgment boundary without a verdict, **Then** it stops with an infrastructure/process failure rather than proceeding.

---

### User Story 2 - Deployed instructions are host-neutral (Priority: P1)

As a Specrew maintainer, I want the agent-instruction digests that reach all hosts to name no host-specific mechanism, so a non-Claude host never reads an instruction it cannot act on.

**Why this priority**: The mislabeled instruction is half the #2884 causal chain.

**Independent Test**: Grep the all-host refocus digests (`general.md`, `specify.md`) for host-specific imperatives (`specrew-gate-stop`, `AskUserQuestion`, "on the Claude host"). Zero matches; the instruction is host-neutral.

**Acceptance Scenarios**:

1. **Given** the cleaned digests, **When** any host renders rule-9 / the specify step, **Then** it sees a host-neutral instruction ("render the packet and capture the verdict via your host's approved interaction path") with no Claude-only skill or tool name.

---

### User Story 3 - Verdict capture works on non-Claude hosts (Priority: P1)

As a Specrew maintainer, I want non-Claude hosts to emit and capture the `SPECREW-VERDICT-BOUNDARY` marker, so their verdicts land in `verdict_history` and the authorization check passes legitimately.

**Why this priority**: Without capture the authorization state stays empty and enforcement cannot pass legitimately.

**Independent Test**: On a non-Claude host, complete a boundary verdict; verify the marker is emitted and `verdict_history` records the `{from,to}` verdict.

**Acceptance Scenarios**:

1. **Given** a non-Claude host with the host-neutral fallback renderer, **When** the human approves a boundary, **Then** the marker is emitted and captured into `verdict_history`.

---

### User Story 4 - Every host receives equivalent gate artifacts (Priority: P2)

As a Specrew maintainer, I want a parity test proving each supported host receives the required lifecycle/gate artifacts (instruction + verdict-capture + enforcement appropriate to the host).

**Why this priority**: Portability is only credible if it is mechanically checked, not asserted.

**Independent Test**: Run the parity test; each supported host's deployed artifact set includes the required gate surfaces or a recorded degraded-mode declaration.

**Acceptance Scenarios**:

1. **Given** the supported host set, **When** the parity test runs, **Then** each host has the required gate artifacts or a recorded degraded mode.

### Edge Cases

- A host with NO runtime hook surface: enforce-or-halt degrades to cooperative instruction + a mandatory halt; the parity test records the degraded mode.
- Over-blocking risk: the gate biases to allow on non-implementation / governance-artifact writes so it does not break legitimate work.
- The dormant gate-seat activation must not change non-target host behavior (fail-open preserved where no gate provider applies).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every supported host MUST receive equivalent lifecycle/gate artifacts appropriate to the host — a boundary-stop instruction, a verdict-capture mechanism, and the strongest available enforcement lever (or a recorded degraded mode).
- **FR-002**: The refocus digests that reach all hosts (`extensions/specrew-speckit/refocus/general.md` rule-9 and `extensions/specrew-speckit/refocus/specify.md` step/traps) MUST be harness-free — containing no host-specific imperative and no Claude-only skill or tool name.
- **FR-003**: A host-neutral gate-stop fallback MUST render the six-section boundary packet AND emit the `SPECREW-VERDICT-BOUNDARY` marker on hosts without the Claude `specrew-gate-stop` skill.
- **FR-004**: Each supported host MUST declare its boundary-enforcement capability (the strongest available lever and its degraded mode) in its host manifest; the enforcement layer MUST route through that declared capability.
- **FR-005**: A host that cannot enforce a human-judgment boundary MUST halt with an infrastructure/process failure rather than producing the next-phase substantive artifact.
- **FR-006**: Verdict capture MUST work on non-Claude hosts — the `SPECREW-VERDICT-BOUNDARY` marker is emitted and recorded into `start-context.json` `verdict_history`.
- **FR-007**: Where the host runtime supports it (Claude `PreToolUse`), a gate provider on the existing dormant seat MUST deterministically `deny` or `ask` a human-judgment-boundary next-phase write absent the matching verdict; this lever is host-variable, not uniform, and biases to allow.
- **FR-008**: All enforcement and cleaning MUST reuse existing machinery (refocus engine, the gate seat + dispatcher, 065 authorization, the gate-stop skill, `HandoverStore` capture) and edit refocus SOURCE under `extensions/specrew-speckit/`, never the `.specify/...` mirror; no new dependency; no broad host-model rewrite (split-guard stops for a human verdict if one is required).

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story maps to FRs — US1 -> FR-004 / FR-005 / FR-007; US2 -> FR-002; US3 -> FR-003 / FR-006; US4 -> FR-001.
- **TG-002**: Each FR names an owner role (Implementer) and an iteration window; the feature is sliced into iterations whose scope is recorded in `state.md`.
- **TG-003**: Any conflict between the enforce-or-halt guarantee and a host's runtime limit is reconciled by the degraded-mode declaration (halt), recorded honestly in the host capability declaration and the parity test — not by silently dropping enforcement.
- **TG-004**: Evidence labeling MUST distinguish automated test evidence from manual real-host dogfood evidence; no full-parity enforcement claim without real-host proof.

### Traceability Summary

| Story | Functional Requirements | Governance |
|---|---|---|
| US1 | FR-004, FR-005, FR-007 | TG-001, TG-003 |
| US2 | FR-002 | TG-001 |
| US3 | FR-003, FR-006 | TG-001 |
| US4 | FR-001 | TG-001, TG-004 |

### Key Entities

- **Host capability declaration**: a per-host (`host.psd1`) static record of the strongest enforcement lever and the degraded mode.
- **SPECREW-VERDICT-BOUNDARY marker**: the host-neutral verdict-capture contract (an HTML comment) emitted at a boundary verdict and captured into `verdict_history`.
- **Gate provider**: a `kind == 'gate'` provider on the dormant dispatcher seat that returns a `deny` / `ask` / `allow` decision for a human-judgment-boundary write where the host supports it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The #2884 repro (a greenfield run self-advancing past `clarify -> plan`) no longer self-advances on a cross-host dogfood — each host either captures a verdict before advancing or halts. (Evidence: manual real-host dogfood across the supported host set.)
- **SC-002**: A deterministic test confirms NO host-specific imperative or Claude-only skill/tool name remains in the all-host refocus digests. (Evidence: automated test.)
- **SC-003**: A parity test proves each supported host receives the required gate artifacts or a recorded degraded mode. (Evidence: automated test.)
- **SC-004**: A gate-detection test proves a missing verdict prevents or flags the human-judgment transitions producing next-phase substantive artifacts at the level each host supports. (Evidence: automated test.)
- **SC-005**: Non-Claude verdict capture is proven — the marker is emitted and recorded into `verdict_history` on a non-Claude host. (Evidence: automated test plus manual real-host evidence.)

## Assumptions

- The dormant gate seat can be activated as a real `deny`/`ask` provider on Claude `PreToolUse` without a broad host-model change (research-flagged; split-guard if false).
- Each non-Claude host has some interaction path to render a packet and capture a verdict marker (cooperative if no hook); a truly hookless host degrades to cooperative instruction plus a mandatory halt.
- Reusing 065's `verdict_history` authorization state is sufficient for the gate provider's decision.

## Governance Alignment *(mandatory)*

- **Spec Steward**: owns spec-to-implementation fidelity; the enforce-or-halt guarantee is the authoritative contract.
- **Iteration Facilitator**: slices the work into iterations (cleaning + fallback first; gate-provider activation + tests next; cross-host dogfood last).
- **Capacity Model**: standard-depth feature; multiple iterations expected.
- **Drift Signals**: any deviation from the locked scope (the hard uniform write-block, the full 188 matrix, a host-model rewrite) is recorded in `drift-log.md` and STOPS for a human verdict.
- **Human Oversight Points**: the lifecycle gates (specify, clarify, plan, tasks, before-implement, review-signoff, retro, iteration-closeout, feature-closeout). One approval advances exactly one boundary. The maintainer pre-authorized the gates through implementation, conditional on no scope change.
- **Split Guard**: stop for a human split/defer verdict if real enforcement requires a broad host-model rewrite.
- **Release Discipline**: beta-before-stable; no full-parity enforcement claim without real-host evidence.

## Scope Amendment (2026-06-19): Reliably Follow Specrew — Three Failure Modes

### Context

Maintainer dogfooding surfaced THREE distinct failure modes, of which gate-skipping (#2884, the original 185 scope) is only one:

1. **Resume confusion** — on an existing Specrew project, the host asks "what do you want to build?" instead of continuing the active feature (it did not read the lifecycle state; the orientation did not reliably reach it — the F-174 delivery limit).
2. **Gate-skip** — the host advances a human-judgment boundary without a verdict (#2884, the original scope).
3. **Raw Spec Kit** — the host runs the raw Spec Kit SDD engine (`specify workflow` / `/speckit.specify`) instead of the governed Specrew workshop + slash-commands.

The real target is **make the host reliably follow Specrew**, not just gate enforcement. All three share a root: the persistent instructions say the right thing, but a weak model does not reliably follow them, and the live-state orientation is not reliably delivered.

### Design (prevention + detection, riding the init-deployed hooks/files — must work at DIRECT launch)

The maintainer confirmed `specrew start` is rarely used; harnesses are launched **directly** after `specrew init`. So every lever rides the hooks + files Specrew deploys into the harness config at init (the same mechanism F-184's persistent instructions use): **prevention** = a reliable SessionStart orientation [#1] + a markdown patch of the deployed Spec Kit `specify` slash-command [#3] + the cleaned harness-free gate instruction [#2, done, Iter 1]; **detection** = one per-turn Stop-hook conformance check catching all three deviations + correcting.

### Dropped: the CLI wrapper (drift-log D-001/D-002)

A `specify.exe` wrapper (intercepting `specify workflow`) was validated (`specify.exe` IS Spec Kit's binary, with a `workflow` engine) then DROPPED: with direct launch the norm, it needs invasive install-time PATH placement (global PATH mod / shadowing the install) for marginal value over the detection, which catches the same invocation. No compiled binary, no new dependency.

### Functional Requirements Added

- **FR-009**: The SessionStart orientation MUST reliably deliver, at the first action of a resumed session, the active feature + boundary + the single next Specrew action — so the host continues the active feature rather than asking what to build (#1). Where a host truncates the payload (the F-174 limit), the orientation degrades to a lean pointer the host reads, not silence.
- **FR-010**: `specrew init` (and update / start-heal) MUST patch the deployed Spec Kit `specify` slash-command(s) with a managed section routing the host through the Specrew design workshop before producing a spec (#3) — idempotent, user-content-preserving, healed on re-run, resilient to a Spec Kit update re-deploying its commands.
- **FR-011**: A per-turn Stop-hook conformance check MUST detect and correct the three deviations at end-of-turn: an intake question while an active feature exists → redirect to continue it (#1); a raw Spec Kit engine invocation → redirect to the governed flow (#3); a human-judgment boundary advanced without a captured verdict → halt and require the verdict (#2). Bounded evidence; fail-open on over-correction, halt only on the un-authorized advance.
- **FR-012**: The CLI binary wrapper is OUT of scope (dropped per drift-log D-002); the `specify workflow` path is covered by FR-011's detection + the persistent instruction, not a pre-block.
- **FR-013**: Specrew MUST normalize the host-native Spec Kit command surface across hosts — deploying the per-boundary speckit commands to each palette-host's native command surface (a per-host `CommandRoot` mirroring `SkillRoot`), so a host told to use `/speckit.*` actually has them. Today only Copilot does (via `specify init --ai copilot`); Claude + Antigravity declare `HasUserSlashCommandSurface = $true` but received no commands — a 0.38.0 regression. The coordinator instruction MUST distinguish the forbidden raw `specify.exe workflow` automation from the allowed Specrew-governed scripts/commands, and name the entry point each host actually has (commands where deployed; the governed scripts otherwise — already handled for the no-palette hosts Cursor/Codex via the pwsh-form surgery). Architecture: extends the existing host-adapter skill-normalization pattern to commands (clean core, volatile per-host surface in the adapter); the split-guard does NOT fire (bounded extension, no host-model rewrite).
- **FR-014**: On a DIRECT host launch (the host CLI launched directly, not via `specrew start`), the orientation / launch-contract MUST render the ACTUAL host, not a hardcoded default. The host is already known at runtime — baked per-host into the hook registration (`-HostKind <host>`) → the dispatcher → the bootstrap provider's `$hostKind` — and a tested env-detection helper (`Get-SpecrewRuntimeHostFromEnv`: CLAUDECODE / ANTIGRAVITY_SESSION_ID / CURSOR_AGENT / CODEX_SESSION_ID / COPILOT_CLI) exists as a fallback. The provider MUST thread the known host into the contract writer, and the writer MUST resolve explicit → env → `claude` last-resort (no bare hardcoded param default). Dogfood: agy / Gemini-Flash on test-f185 read `Host: claude` because the regeneration call dropped the host it already held. Architecture: reuses the host-baked-into-hook + env-helper precedence already used by `Update-SpecrewRollingHandover`; no new detection code.

### Success Criteria Added

- **SC-006**: A direct-launch dogfood on an existing Specrew project shows the host continues the active feature (does not ask "what to build") — manual real-host evidence.
- **SC-007**: A direct-launch dogfood shows the host enters the Specrew workshop rather than running raw Spec Kit — manual real-host evidence.
- **SC-008**: The conformance check detects each of the three deviations — automated test.
- **SC-009**: A direct-launch dogfood on Claude (and Antigravity) shows the host has a runnable governed entry point (native speckit commands or the un-blocked governed scripts) and proceeds into the governed lifecycle rather than reporting "no valid route" — manual real-host evidence, plus a parity test that each palette-host's command surface is populated and the coordinator instruction blesses the governed scripts while still forbidding the raw `specify.exe workflow`. (Evidence: automated parity/guard test + manual real-host dogfood.)
- **SC-010**: A direct-launch dogfood on a non-Claude host (Antigravity) shows the orientation banner naming the ACTUAL host (e.g. `Host: antigravity`), not `claude` — manual real-host evidence + an automated wiring test (provider threads `-HostKind $hostKind`; writer env-detects; no bare `claude` param default; source/mirror parity).
