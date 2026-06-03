# Quickstart: Design Gate Runtime Hardening

**Feature**: 141-design-gate-runtime-hardening  
**Last verified**: 2026-06-03 (Iteration 5 delivered: lens-informed analysis + FR-026 coverage gate — FR-009 decision-point surfacing, FR-026 anti-omission enforcement)

## Run it

```powershell
# Validate a design-analysis artifact against the gate (Feature 140 helper, extended in iter 1)
pwsh -NoProfile -Command ". ./scripts/internal/design-analysis-gate.ps1; Test-SpecrewDesignAnalysisArtifact -ProjectRoot . -FeatureRef '<feature>' -IterationNumber '001' | ConvertTo-Json"

# Focused tests (names finalize during implementation)
pwsh -File tests/unit/design-analysis-gate.tests.ps1
pwsh -File tests/integration/design-analysis-boundary.tests.ps1
```

## Try the canonical scenario (Iteration 1)

1. Reach the design-analysis stop for a substantive iteration. The scaffold emits
   `specs/<feature>/iterations/<NNN>/design-analysis.md` from the template.
   Expected: the freshly scaffolded artifact matches the Feature 140 validator
   contract (problem framing, decision points, ≥2 options with required fields,
   Crew recommendation, empty Human Decision).
2. Attempt to author `plan.md` before filling the artifact / before a human
   decision. Expected: the pre-plan validator blocks with an actionable message
   naming the missing section, and `plan.md` is not authored.
3. Fill the artifact, render the typed gate packet, and record a human decision
   (`approved for plan with Option <X>`). Expected: a narrow durable packet is
   stored under `specs/<feature>/gates/` and the pre-plan validator returns
   `valid: true` with the selected option.
4. Proceed to plan. Expected: `plan.md` is authored and the selected option is
   preserved as authoritative input.

## Verify the edge cases

- **Missing recommendation**: remove the Crew recommendation → validation fails.
- **Missing human decision**: leave Human Decision empty → plan-boundary blocked.
- **Lenses absent (downstream)**: no lens files present → the Applicable Lenses
  section degrades gracefully (states none applicable) rather than erroring.

## Iteration 2 (delivered 2026-06-02): start-packet correctness + stale-session recovery

- **No empty `specs//` paths (FR-011)**: the greenfield/intake orientation block no longer emits
  a `file:///<project-root-url>/specs/<feature>/` browse URL (which collapses to `specs//` when the
  coordinator substitutes an empty `<feature>` per Rule 48); it emits explicit-placeholder guidance
  instead, and a resolved-feature resume still surfaces the concrete browse paths. Verify:
  `pwsh -File tests/integration/multi-host-launch-path.tests.ps1` (Test 9b), or run a greenfield
  `specrew start --host claude -NoLaunch` and confirm the prompt contains no `specs//`.
- **Host-accurate launch wording (FR-014)**: the launch guidance is host-neutral — `Approval mode:`
  (not `Copilot approval mode`) plus a host-aware delegation line. Verify: same test (Test 18b), or a
  greenfield `specrew start --host claude` shows no `Copilot` terminology.
- **Stale cross-worktree session recovery (FR-024)**: a saved session anchored to a deleted/external
  feature worktree is detected stale; recovery choice A does NOT re-anchor to it and instead requests
  confirm-gated cleanup that clears ONLY the runtime session refs (start-context `session_state` + the
  matching `active-sessions` entry) — never feature artifacts, never lifecycle commits — and the
  cleared state sticks across the same start run. Verify:
  `pwsh -File tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1` and
  `pwsh -File tests/integration/start-recovery-flow.tests.ps1` (end-to-end confirm->clear).
- **Gate harness clean exit (T004)**: the design-analysis plan-boundary gate returns `Valid` with a
  clean `$LASTEXITCODE` (no stray error) on a valid artifact. Verify:
  `pwsh -File tests/unit/design-gate-runtime-hardening.tests.ps1`.

## Iteration 3 (delivered 2026-06-03): greenfield/downstream hygiene (FR-012, FR-013)

- **No spurious multi-developer warning in a fresh project (FR-012)**: a single-developer
  freshly bootstrapped greenfield no longer surfaces `Multiple developers detected
  (N close-together shared-state writes)`. Specrew's own bootstrap writes (`start-context.json`,
  `last-start-prompt.md`, and `decisions.md`, all written within ~1s by `init`/`start`) used to
  trip the write-signal trigger alone; close-together writes now only **corroborate** a genuine
  distinct-actor signal (≥2 git authors, ≥2 active-session machines, or ≥3 numbered-branch
  fanout) and never trigger the recommendation on their own. Genuine multi-developer activity
  still surfaces. Verify: `pwsh -File tests/unit/feature-051-iteration2b.tests.ps1` (SC-008), or
  call `Get-SpecrewMultiDeveloperSignals` in a fresh single-dev repo and confirm
  `has_multi_developer_signal` is `False`.
- **Fresh-greenfield baseline commit (FR-013)**: the baseline resolves to a real commit hash and
  refreshes consistently at every boundary **once a commit exists** (the existing Feature-029
  contract). A repo with **no commit yet** has nothing to resolve to: Specrew preserves the
  zero-commit fail-safe (it does **not** stamp a baseline and does **not** create a commit on
  your behalf) and instead emits a guidance line at `specrew start` telling you to make an
  initial commit so governance can anchor a baseline. Verify:
  `pwsh -File tests/integration/baseline-hygiene.tests.ps1` (SC-009), or run `specrew start` in a
  `git init`'d repo with no commit and confirm the guidance appears and no baseline is stamped.
- **Spec note (resolved-by-clarification)**: US6-AC1 ("baseline MUST resolve to a real commit
  hash … with no prior history") is satisfied the moment a commit exists; the literal zero-commit
  case is handled by the Feature-029 fail-safe + the guidance nudge rather than by auto-creating a
  commit (which would contradict the `baseline-hygiene.tests.ps1` tested contract). FR-012's
  version-mismatch-vs-placeholder and author/branch-fanout signals are self-host-only and were not
  reproduced as greenfield/downstream leaks (follow-ups, not changed here).

## Iteration 4 (delivered 2026-06-03): questionnaire-driven Applicable Lenses (FR-009/FR-010/FR-025)

- **Applicable Lenses are selected, not guessed (FR-025).** A fixed applicability questionnaire
  (UI? auth/secrets/PII? persistent data? external API? deploy/release? perf/resilience?) is
  recorded as `lens-applicability.json`, and a deterministic selector picks the lenses: foundational
  lenses (architecture-core, component-design, requirements-nfr) are always-on; specialized lenses
  are gated by a "yes" answer. Verify: `pwsh -File tests/unit/lens-applicability-selector.tests.ps1`,
  or:

  ```powershell
  . ./scripts/internal/lens-applicability.ps1
  $map = Read-SpecrewLensApplicabilityMap -Path extensions/specrew-speckit/knowledge/design-lenses/applicability-map.json
  Get-SpecrewApplicableLenses -Map $map -Answers @{ ui=$false; security=$true; data=$true; integration=$false; ops=$false; perf=$false }
  # -> architecture-core, component-design, requirements-nfr, security-compliance, data-storage
  ```

- **Decoupled (Option B decoupled).** The question-to-lens gating map is a sibling file
  (`extensions/specrew-speckit/knowledge/design-lenses/applicability-map.json`); the Proposal 156
  catalog `index.yml` stays PURE. Selection is deterministic (SC-015: identical answers -> identical
  set) and LLM/network-free; the JSON records the per-lens include/exclude rationale.
- **Graceful degradation (SC-006).** Absent catalog or absent answers render "none available"
  rather than erroring. The `design-analysis.md` template now carries an "Applicable Lenses" section
  rendered by `Format-SpecrewApplicableLensesSection`.
- **Deferred (still out, FR-010):** project-local lens overrides, lens-schema validation
  enforcement, broad cross-phase automation, a standalone `specrew lens` command, and per-lens
  rationale automation remain Proposal 156's deeper scope.

## Iteration 5 (delivered 2026-06-03): lens-informed analysis + FR-026 coverage gate (FR-009/FR-026)

- **The analysis is informed by the lenses, not just named by them (FR-009).** The enriched render
  surfaces each selected lens's **Design Decision Points** (verbatim from the lens files) plus an
  `Addressed:` line the author fills by pointing into the option comparison. Verify:
  `pwsh -File tests/unit/lens-applicability-selector.tests.ps1`, or:

  ```powershell
  . ./scripts/internal/lens-applicability.ps1
  $map = Read-SpecrewLensApplicabilityMap -Path extensions/specrew-speckit/knowledge/design-lenses/applicability-map.json
  $ans = @{ ui=$false; security=$false; data=$true; integration=$false; ops=$false; perf=$false }
  Format-SpecrewApplicableLensesSection -Map $map -Answers $ans -CatalogDir extensions/specrew-speckit/knowledge/design-lenses
  # -> each selected lens renders its Decision points + an "Addressed:" placeholder to fill
  ```

- **The gate enforces lens coverage (FR-026).** Before `plan.md`, the design-analysis gate blocks
  when any questionnaire-selected lens is left unaddressed (a placeholder or a missing `Addressed:`
  entry), and the failure **names** the lens (SC-016). The check is deterministic and
  LLM/network-free. It is an **anti-omission backstop, not a quality guarantee** — a deterministic
  gate cannot judge whether engagement is genuine. Verify:
  `pwsh -File tests/unit/design-analysis-gate.tests.ps1` (the FR-026 block).
- **Genuine engagement is proven by the discriminator, not the gate.** At review-signoff the
  reviewer applies a **blocking** check: delete every `Addressed:` line and confirm the option
  comparison *still* visibly engages each selected lens (its Trade-offs / Quality features). If the
  analysis goes blank, it was a checkbox and the iteration is sent back. This iteration dogfooded it
  on its own design analysis — the discriminator passed.
- **Grandfather-safe via an explicit marker (enforce-by-default).** A pre-FR-026 questionnaire must
  carry `fr026_grandfathered: true` in its `lens-applicability.json` to be exempt (Iteration 4 does),
  so it never retroactively fails. Grandfathering is **not** inferred from missing `Addressed:`
  lines — deleting every `Addressed:` entry from an FR-026-era artifact FAILS the gate (naming each
  selected lens) rather than silently no-opping it.
- **Still deferred (FR-010):** the deeper Proposal 156 automation above remains out (lens-file schema
  validation, overrides, standalone command, auto-rationale).
