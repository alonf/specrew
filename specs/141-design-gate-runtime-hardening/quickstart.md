# Quickstart: Design Gate Runtime Hardening

**Feature**: 141-design-gate-runtime-hardening  
**Last verified**: 2026-06-03 (Iteration 3 delivered: greenfield/downstream hygiene — FR-012 spurious multi-dev warning suppression, FR-013 baseline guidance)

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
