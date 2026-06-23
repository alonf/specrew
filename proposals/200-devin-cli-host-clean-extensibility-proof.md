---
proposal: 200
title: Add Devin CLI Host — Clean-Extensibility Proof
status: candidate
phase: phase-2
estimated-sp: 18-26 (Devin package is small; the bulk is the abstraction-completion cleanups — must split, see Sequencing)
priority-tier: 2
discussion: 2026-06-23 host-abstraction audit. The `hosts/` package contract + `_registry.ps1` + `host-coupling-firewall.tests.ps1` already make most host knowledge data-driven (firewall green: 0 violations / 11 allow-listed across 444 files). Adding the Devin CLI (the rebranded Windsurf surface) is the forcing function to retire the remaining allow-listed leaks and PROVE a host can be added by adding a folder only.
---

# Add Devin CLI Host — Clean-Extensibility Proof

## Why

Two goals in one feature:

1. **Add the Devin CLI as a supported host.** "Windsurf" is now **Devin Desktop** (Cognition rebrand, 2026-06-02). The governable surface is the new **`devin` CLI** ("Devin for Terminal", launched 2026-04-29): headless `devin -p`, file-based hooks at `.devin/hooks.v1.json` that are **explicitly Claude Code-compatible**, `AGENTS.md` project instructions, `.devin/agents/` subagents, and an ATIF (`--export`) transcript. Spec-Kit already supports a `devin` integration (`.devin/skills/`). This is one of the lowest-friction non-Claude hosts available.

2. **Prove the host abstraction is complete.** The 2026-06-23 audit found the `hosts/<kind>/` package architecture is real and enforced: a single registry (`hosts/_registry.ps1` — *"THIS IS THE ONLY FILE HOST-NEUTRAL CORE CODE CALLS"*), a written contract (`hosts/_contract.md`), and a structural firewall (`tests/integration/host-coupling-firewall.tests.ps1`, **green**) that bans hardcoded host-enum tuples and `antigravity`/`agy` routing literals in shared core. But the firewall carries an **allow-list of 11 known exceptions** — the "open work remaining": 3 `[ValidateSet]` callsites + 2 coordinator-tier hardcodes (`agent-detection.ps1`, `specrew-init.ps1`) — plus one surface the firewall does not yet cover: the per-host **transcript turn shapes** live in shared core (`ConversationCaptureAccessor.ps1`), with **no contract slot**.

The governing decision: **adding Devin must touch only `hosts/devin/`.** Wherever Devin would otherwise require a `devin` literal outside its folder, we do NOT add the literal — we **close the abstraction gap generically for all hosts** and retire the corresponding allow-list entry. The Devin package is the capstone; the cleanups are the substance. When this ships, the firewall allow-list is smaller, not larger, and the **next** host genuinely is "add a folder."

## Governing principle (the rule this proposal enforces)

| Rule | Statement |
|---|---|
| **R1 — Additive** | Devin support is the `hosts/devin/` package (manifest + handlers + coordinator-rules) and nothing else host-specific. |
| **R2 — No coupling** | If Devin needs a touchpoint outside its folder, that touchpoint MUST become **registry/manifest-driven for every host**. Never `if ($HostKind -eq 'devin')`. |
| **R3 — Cleanup-only core edits** | The only permitted edits outside `hosts/devin/` are generic abstraction completions that contain **zero `devin`/`windsurf` literals** and benefit all hosts. |
| **R4 — Proof** | An automated check enforces R1–R3: the Devin-enabling change set, outside `hosts/devin/`, contains no host-specific literal, and the firewall allow-list does not grow. |

## Devin → host contract mapping (all inside `hosts/devin/`)

Everything Devin needs is already a contract slot or manifest field (`hosts/_contract.md`). This part is purely additive:

| Need | Mechanism (existing slot) | Devin value |
|---|---|---|
| Launch headless | `New-DevinLaunchInvocation` (handler) | `devin -p "<prompt>"`; map `--permission-mode`, `--continue`/`--resume` |
| Flag translation | `ConvertTo-DevinFlag` (handler) | abstract permission/flags → Devin flags |
| Detection | `Test-DevinRuntimeInstalled` + `Get-DevinSignals` (handlers) | `Binary='devin'`; running-inside env vars |
| Crew runtime | `Install-DevinCrewRuntime` (handler) | `.specrew/team/agents/*.md` → `.devin/agents/<name>/AGENT.md` |
| Hooks | `RefocusHookBindings` (manifest) | `SettingsFile='.devin/hooks.v1.json'`, event map (SessionStart/Stop/PreToolUse/UserPromptSubmit), `ConfigShape`, `CommandMode` — **core consumes the binding; no devin literal in core** (firewall already proves this for hooks) |
| Instructions | `InstructionsFile` (manifest) | `AGENTS.md` — **already shared** with codex/cursor/antigravity; `instruction-deploy.ps1` dedups by path host-neutrally (returns `SharedWith`), so no new work (verified) |
| Coordinator surgery | `coordinator-rules.psd1` | declarative directives (may be `Rules=@()`) |
| Spec-Kit | `SpeckitAiFlag` (manifest) | `'devin'` (reconcile `--ai`/`--integration`, see FR-006) |
| Agent dir / skills | `AgentDir`, `SkillRoot` (manifest) | `.devin/agents/`, `.devin/skills/` |

## The leaks Devin exposes, and the generic fix for each

These are the only places Devin would force a non-folder change today. Each becomes an all-hosts cleanup (R2).

### Leak 1 — Transcript turn shapes have no contract slot (the big one)

`scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` recognizes turn shapes by **object shape** (`type='response_item'`, `type~'^(user|assistant)\.message$'`, `source='USER_EXPLICIT'`, Claude `message.content[]`). It is host-*agnostic* (a union parser, not `-eq host` dispatch — good), but the shapes are **hardcoded in shared core**, so teaching it Devin's ATIF shape is an edit outside `hosts/devin/`. **Fix (R2):** add a 6th contract slot — a per-host turn-shape matcher (e.g., `Get-<Kind>TranscriptTurnFromObject -Object $o` → `{role; parts}` or `$null`) registered via `$script:HostContractFunctionMap`. The core parser iterates registered matchers (still a host-agnostic union). **Migrate the 5 existing host shapes into their packages**; Devin's ATIF matcher lives in `hosts/devin/handlers.ps1`. Net: the shared parser holds no host-specific shape; future hosts add their matcher in-folder.

### Leak 2 — Coordinator-eligible tier is hardcoded (`@('copilot','claude','codex')`)

`scripts/init/agent-detection.ps1` and `scripts/specrew-init.ps1` (both firewall-allow-listed) hardcode the coordinator-eligible roster. **Fix (R2):** introduce a manifest field (e.g., `CanCoordinate: bool`, or derive from `Status`) consumed via `Get-SpecrewHostsByStatus`/registry; migrate the `iteration-config.yml` schema so it has an explicit agents slot driven by registry membership (this schema migration is the reason the audit deferred it). Retires **2 allow-list entries**.

### Leak 3 — Three `[ValidateSet]` callsites

`specrew-start.ps1`, `host-flag-translation.ps1`, `coordinator-prompt-surgery.ps1` hardcode the enum for *input validation only* (logic already dispatches via the registry). **Fix (R2):** the Phase-D `[ValidateScript({ $_ -in (Get-RegisteredHostKinds) })]` refactor the firewall comments already anticipate. Retires **3 allow-list entries**.

### Leak 4 — Spec-Kit flag surface

`SpeckitAiFlag` is already a manifest slot; setting `'devin'` is in-folder. The non-folder work is reconciling Spec-Kit's `--ai` (≤0.9.x) vs `--integration` (≥0.10) flag — a host-neutral fix that belongs with Proposal 198 (self-host currency) / `supported-versions.yml`, not a devin literal.

### Leak 5 — `Specrew.psd1` FileList hardcodes host package paths

The host contract requires `Specrew.psd1`'s `FileList` to list every host's `host.psd1`, `handlers.ps1`, and `coordinator-rules.psd1`, and today each path is **hardcoded per host**. So `hosts/devin/` would force a hand edit to `Specrew.psd1`, and if SC-001/FR-010 were followed literally the files would be omitted — Devin discoverable in the dev tree but **failing FileList/package validation** on install. (Raised by the codex reviewer on this very PR — a live demonstration of the leak.) **Fix (R2):** **generate** the host-package `FileList` entries from `hosts/*/{host.psd1,handlers.ps1,coordinator-rules.psd1}`, composing with Proposal 198's deterministic generation + the existing FileList-parity CI gate. The generated entries do contain the host path string, but they are **machine-derived from `hosts/` and parity-gated**, not a hand-authored coupling — so FR-010's purity scan exempts generated/derived files. Adding a folder then auto-packages with zero hand edits.

### Verified already-clean (no work needed — proof points for the additive claim)

The audit confirmed these surfaces already handle a new host generically, so Devin uses them as-is:

- **Shared instruction file** — Devin's `AGENTS.md` is already shared by codex/cursor/antigravity; `instruction-deploy.ps1` dedups by path (host-neutral, returns `SharedWith`). No new work; no `SharedInstructionsFileWith` field needed.
- **Hooks** — core hook deploy consumes `RefocusHookBindings` with no host literal (firewall forbidden-core scan proves it for the 5 shared-core hook/bootstrap files).
- **Shared skill root** — the `SharedSkillRootWith` manifest field already exists if Devin shares a skill catalog with another host.

## Functional requirements

- **FR-001** — `hosts/devin/` package (`host.psd1`, `handlers.ps1` with all 5 contract functions, `coordinator-rules.psd1`) passing `Test-HostManifestValid`; `Status: experimental` until FR-010 real-host validation, then `supported`.
- **FR-002** — `New-DevinLaunchInvocation` produces `devin -p "<prompt>"` with permission-mode + resume mapping; no core launch-path edit (consumed by `Get-SpecrewHostLaunchInvocation`).
- **FR-003** — `RefocusHookBindings` for `.devin/hooks.v1.json` (Claude-compatible event map); deployed by the existing core hook path with **no `devin` literal added to core** (re-asserted by the firewall's forbidden-core scan, extended to include Devin literals).
- **FR-004** — `InstructionsFile='AGENTS.md'`; coordinator surgery via `coordinator-rules.psd1`.
- **FR-005** — `Test-DevinRuntimeInstalled`, `Get-DevinSignals`, `ConvertTo-DevinFlag`, `Install-DevinCrewRuntime` (→ `.devin/agents/`).
- **FR-006** — `SpeckitAiFlag='devin'`; `--ai`/`--integration` reconciliation handled host-neutrally (coordinate with 198).
- **FR-007 (abstraction)** — Transcript-turn-shape contract slot added; `ConversationCaptureAccessor` iterates registered per-host matchers; the 5 existing host shapes migrated into their packages; **no host-specific turn shape remains in shared core**.
- **FR-008 (abstraction)** — Coordinator-eligibility becomes a manifest field; `agent-detection.ps1`/`specrew-init.ps1` consume the registry; `iteration-config.yml` schema migrated; **2 allow-list entries removed**.
- **FR-009 (abstraction)** — The 3 `[ValidateSet]` callsites become registry-driven `[ValidateScript]`; **3 allow-list entries removed**.
- **FR-010 (proof)** — The firewall test gains a **host-addition purity assertion** as a *steady-state invariant* (a static tree scan, like the existing forbidden-core scan — not a diff check, so it also catches future drift): no production file outside `hosts/devin/` contains a `devin`/`windsurf` literal, and `$allowListExact.Count` is **≤ pre-proposal count** (must not grow; shrinks by FR-008/009). The scan targets **hand-authored** source; machine-generated/derived artifacts (the `Specrew.psd1` FileList, regenerated from `hosts/` and covered by the FileList-parity gate per FR-012) are exempt. SC-001's `git diff` review is the complementary human check.
- **FR-011** — Transcript acquisition resolved: Devin has no confirmed always-on transcript file, so either launch with `--export <runtime path>` consumed by the Stop-hook providers, or fall back to the existing event-payload last-message tier (the parser's Codex-style Tier-3). Decided by an early spike.
- **FR-012 (abstraction)** — `Specrew.psd1` host-package `FileList` entries are **generated** from `hosts/*/{host.psd1,handlers.ps1,coordinator-rules.psd1}` (no hand-authored per-host path), so adding `hosts/devin/` auto-packages with no hand edit. Composes with Proposal 198's deterministic generation + the existing FileList-parity CI gate. (Surfaced by the codex PR reviewer.)

## Success criteria

- **SC-001** — `git diff` for the host-enabling commit shows hand edits **only under `hosts/devin/`**; everything else is either a generic abstraction edit with **zero hand-authored `devin` literals** or a **regenerated artifact** (e.g., the `Specrew.psd1` FileList produced by FR-012's generator, reproducible from `hosts/`).
- **SC-002** — Firewall allow-list count **decreases** (5 production entries retired: 3 ValidateSet + 2 coordinator-tier); **no new entry** added for Devin.
- **SC-003** — Real-host validation on the `devin` CLI: SessionStart bootstrap surfaces, a boundary gate-stop fires, and a handover is captured from the transcript (the SC-012-class manual check, per the dogfood-confound discipline — artifact + behavior on the actual host).
- **SC-004** — A fixture host exercising the **same capability dimensions as the existing five** (launch / flags / detection / hooks / instructions / transcript / crew) can be added with **only a new folder** and zero abstraction edits — proven by the FR-010 steady-state invariant. The guarantee is "no host-*specific* edits"; a host needing a genuinely *new* capability dimension still extends the contract generically (a core edit, never an `if ($HostKind -eq ...)` branch).
- **SC-005** — Zero regression on the existing 5 hosts: firewall green, and the transcript goldens (`tests/.../transcript-parse-once`) byte-identical after the shape migration.

## Risks & mitigations

- **Devin CLI volatility** — ~2 months old, mid-rebrand, multiple releases/week, Cascade EOL 2026-07-01. → Pin version; **target `devin` + `.devin/` + `AGENTS.md` only**, never `windsurf`/`cascade`/`~/.windsurf/`; track under Proposal 187. The `.v1.json` hook suffix signals a versioned contract.
- **Transcript `--export` (no always-on file)** — the softest finding. → FR-011 spike up front; the Tier-3 last-message fallback already exists, so handover degrades gracefully even if the export path is awkward.
- **Coordinator-tier schema migration** — touches deferred `iteration-config.yml` debt. → Can ship Devin as a *worker-only* host first (skip FR-008), keeping it strictly additive, and do the coordinator-tier cleanup as a follow-up slice if Devin-as-coordinator isn't needed day one.
- **Spec-Kit flag break** — `--ai` removed in 0.10. → Gate on Proposal 198 / `supported-versions.yml`; host-neutral fix.
- **Scope** — 18-26 SP exceeds the 20 SP cap. → Must split (see Sequencing).

## Relationship to other proposals

- **124 (multi-host catalog expansion)** — Devin is the next catalog entry; this proposal also hardens the catalog mechanism.
- **024 / 058 / 069 (multi-host runtime/distribution/launch)** — the foundation this builds on.
- **139 (subagent orchestration)** — `Install-DevinCrewRuntime` + `.devin/agents/`.
- **187 (volatile dependency monitoring)** — Devin's high churn is a monitoring case.
- **198 (self-host currency)** — owns the Spec-Kit `--ai`/`--integration` reconciliation **and the deterministic FileList generation + parity gate that FR-012 builds on**.
- **127 (git-host adapter)** — same data-driven-adapter pattern, a different (git-host) dimension.
- `hosts/_contract.md` and `tests/integration/host-coupling-firewall.tests.ps1` — the contract and proof surface this extends.

## Sequencing (split — cleanups first, Devin is the capstone)

Per R1–R3 the cleanups are *prerequisites* so Devin's addition is provably additive:

1. **Slice A — Phase-D `[ValidateScript]` + FileList generation + firewall purity assertion** (~4-6 SP). Retire the 3 ValidateSet allow-list entries; generate the host-package FileList (FR-012); add the FR-010 host-addition purity check (no host yet — it must already pass for the existing 5).
2. **Slice B — Transcript-turn-shape contract slot + migrate 5 hosts** (~6-8 SP). The big abstraction; goldens prove zero behavior change.
3. **Slice C — Devin package, worker-only** (~4-6 SP). `hosts/devin/` only; FR-001–006, FR-011; SC-001/SC-005; real-host validation (SC-003).
4. **Slice D — Coordinator-eligibility manifest field + `iteration-config.yml` migration** (~4-6 SP). Retire the last 2 allow-list entries; promote Devin to coordinator-eligible if desired.

Slices A+B+C deliver "Devin added by adding a folder, allow-list smaller." Slice D completes the abstraction and can defer if Devin-as-coordinator isn't day-one.

## Open questions

1. Devin transcript: confirm whether any always-on session file exists, or `--export <path>` is mandatory (FR-011 spike).
2. Coordinator-eligibility: a dedicated `CanCoordinate` manifest field vs deriving from `Status`/a new status value?
3. Transcript slot shape: a 6th handler function (consistent with the existing 5) vs a declarative `TranscriptTurnShapes` manifest block — handler is more flexible for nested content arrays; decide in Slice B. **Keep the host-agnostic union behavior** (try every registered matcher) rather than keying matchers by `HostKind` — a transcript's emitting host is not reliably the current host (cf. the codex `refocus-state-unknown` ambiguity), so a keyed matcher would mis-parse cross-host transcripts.
4. Should Slice A's purity assertion become a permanent gate for **every** future host PR (recommended: yes)?
