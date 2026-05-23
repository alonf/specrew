# Iteration 001 Retro: Multi-Host Launch Path

**Feature**: F-040 | **Iteration**: 001 | **Date**: 2026-05-23

## What went well

- **Pre-existing research wave paid off**: the 2026-05-23 five-agent multi-host research session (Claude Code, Codex CLI, Antigravity, internal coupling audit, Claude Code follow-up) gave concrete CLI surfaces, flag names, and the single-load-bearing-literal location (`specrew-start.ps1:3131`) before implementation began. Zero discovery-during-implementation rework.
- **Helper script isolation**: putting the three new helpers (`detect-hosts.ps1`, `host-flag-translation.ps1`, `coordinator-prompt-surgery.ps1`) as standalone files under `scripts/internal/` kept the diff to `specrew-start.ps1` minimal and testable independently. The 15-assertion test suite hit each helper in isolation before touching the integration path.
- **F-021's prior multi-host skill deployment paid off**: skills already landed at `.claude/skills/`, `.github/skills/`, `.agents/skills/`. F-040's Pillar 3 (per-host skill verification) just had to READ what F-021 already deployed.
- **Universal Crew-coordinator header** is a cleaner design than per-host headers. The user's mid-flight correction ("you are the Crew team coordinator, this is the same for all") collapsed what would have been per-host branching into a single literal string change. Less code, less surface area for drift.

## What was hard

- **`$Host` is a PowerShell automatic variable**. Mid-implementation discovery that `$Host` is a read-only constant variable in the runspace caused a wave of test failures. Required renaming the parameter (`-HostKind` everywhere) and several `foreach ($host in ...)` loops (`$hk` instead) to avoid Set-StrictMode triggering "Cannot overwrite variable Host". Caught by tests; not a production regression. **Methodology note**: future Specrew code touching host-aware logic should default to `HostKind` from day one — adding to coding conventions.
- **Double-replacement bug from regex-style global rename**: my first `replace_all` of `$Host` → `$HostKind` ran a second time on already-renamed code, producing `$HostKindKind`. Caught immediately by the test, but a few minutes of debugging time. **Methodology note**: when doing global renames via PowerShell text-replace, scan the diff for double-applied-pattern before committing.
- **Research vs verified empirical gap for Antigravity** — the 2026-05-23 research confirmed `agy -p` as the bootstrap surface but flagged working-directory propagation as undocumented and session-ID emission as an open issue. F-040 deferred Antigravity entirely (clarify Q1) rather than ship a fragile partial implementation. Right call given the time pressure.

## What we'd do differently

- **Spec the `$Host` pitfall in coding conventions** so future Specrew-internal PowerShell code doesn't repeat the issue. Likely a small-fix slice to add a Rule 16 ("PowerShell parameter naming: avoid clashes with automatic variables") to the maintainer rules.
- **Add pre-implementation lint pass for double-replacement risks** in the bulk-rename tooling. Not a Specrew priority but a personal coding-discipline note.

## Lessons learned

- **Cooperative enforcement is honest enforcement.** The plan-boundary review correctly surfaced the gap between F-039's "launch-mode boundary enforcement" name and its actual cooperative mechanism. F-040 documented this honestly in FR-015 rather than overselling it. Proposal 105 picks up the runtime-hook upgrade as a separate, properly-scoped follow-up.
- **The single-load-bearing-literal pattern is powerful.** The 2026-05-23 internal coupling audit named `specrew-start.ps1:3131` as the single dispatch site. F-040's Slice 0 work was almost entirely localized to that one line + four new helper files. The architectural endgame (Proposal 024 full) remains 30+ SP, but the MVP cost was 15.25 SP because of the surgical pinpoint.
- **Methodology-first prioritization paid dividends**: F-040 ships before any external testers are using Claude/Codex hosts, but the foundation is in place when they do arrive. Per the methodology-first prioritization memory, this is the correct sequence.

## Signals for next iteration / follow-up work

- **Proposal 105 (Host-Native Hook Deployment)** is the natural next step — drafted in this session, queued as Phase 2 candidate. F-040 + 105 together would close the cooperative-runtime gap on Claude.
- **Proposal 104 (Multi-Host Onboarding + Selection Flow)** is the UX layer that builds on F-040. ~8-12 SP. Belongs as F-043 after F-041 (Proposal 068 cost routing) + F-042 (Proposal 070 token economy) per the 4-feature sequence.
- **F-041 (Proposal 068 — Cost-Aware Model Routing)** is the immediate next feature now that F-040 ships. Catalog + lean profile + Junior→cheap-model auto-routing.

## Boundary commit + push discipline (Rule 14B)

Implementer committed boundary-phase work in semantic groups during implementation:

- T001-T008 surfaces (param + parser + helpers + dispatch rewrite + persistence)
- T009 test suite
- T010 + T010a documentation
- T011-T014 closeout (version bump + CHANGELOG + proposal status flip + INDEX)

Each commit pushed to origin/040-multi-host-launch-path before boundary signaling.

---

## Addendum: Post-Ship Dogfooding (calc-v2 + tip-calc, 2026-05-23)

After F-040 closed, an immediate real-launch dogfooding test in a fresh greenfield
project (`C:\Temp\specrew-multi-host-calculator-v2` — "build a web-based calculator")
exposed a cluster of 14 mechanical and methodology gaps. None blocked the lifecycle
from completing — calc-v2 reached `reviewing` with 51/51 tests passing — but each one
either degraded the human-facing UX, silently disabled a governance gate, or produced
missing evidence. Fix-bundle shipped across three commits (`a45232af`, `7f6536b2`,
`162bcdb9` on `main`; `b1486f4c` callsite update on `040-multi-host-launch-path`).

The headline complaint that triggered the deep dive: *"It provided a very nice report,
however, it didn't say why it is stopped and what it needs from me."* That single
sentence anchored the bundle.

### What the dogfooding test caught (14 fixes)

| # | Symptom in calc-v2 | Root cause | Fixed in |
|---|---|---|---|
| 1 | Lifecycle ended with a wall of prose, no clear "stopped here / needs this from you / resume with that" | Coordinator prompt had no enforced exit-block format | `a45232af` — rule 46 mandates `=== SPECREW HANDOFF ===` block |
| 2 | Routing table showed every claude/codex-requesting role falling back to `copilot` (which can't be invoked from inside Claude) | `Get-DelegatedRoutingPlan` ignored `--host`; fallback priority was hard-coded copilot-first | `a45232af` + `b1486f4c` (Proposal 107 implementation) |
| 3 | F-033 markdownlint pre-boundary gate never fired on any of the 5 MD032 violations Claude wrote | `Get-ChangedMarkdownFiles` used `git diff baseRef...HEAD` which goes no-op on greenfield + no-commits | `a45232af` (working-tree fallback) |
| 4 | Validator threw "Boundary enforcement state is missing... Run the migration flow" mid-lifecycle | `boundary_enforcement` block was gated on `$SessionState -ne $null` — greenfield never had it written | `a45232af` (init unconditionally) |
| 5 | Claude had to read shared-governance.ps1 to reverse-engineer the validator's hardening-gate schema; first attempt used `Status: tbd` which validator rejected | `Get-HardeningGateContent` emitted incomplete column set with `tbd` placeholders | `7f6536b2` (canonical 9-column schema + valid Status defaults) |
| 6 | Claude wrote `Status: approved` and `Status: in_progress` (validator rejects both — underscore vs hyphen) | Stub didn't show the canonical Status sets | `7f6536b2` (HTML comment block in plan stub) |
| 7 | `validate-governance.ps1` emitted `FAIL` before iteration plan.md existed; misleading because that's the normal pre-implement state | `Get-IterationTargets` threw an "unexpected-validator-error" | `7f6536b2` (returns `@()` + dark-yellow `[validator-info]`) |
| 8 | Zero commits across the entire lifecycle — defeats F-033, F-039 boundary discipline, and git-history audit | Coordinator prompt didn't mandate boundary commits | `a45232af` — rule 45 mandates boundary commits |
| 9 | `scaffold-iteration-artifacts.ps1` exited 128 even though all actions succeeded | `Get-BaselineRef`'s `git rev-parse HEAD` failed silently but leaked $LASTEXITCODE=128 | `a45232af` (`$global:LASTEXITCODE = 0` reset) |
| 10 | 3× `WARN: Skill file missing YAML frontmatter delimiters` on every bootstrap | `capacity-planning.md` / `drift-check.md` / `traceability-check.md` had no frontmatter | `7f6536b2` (frontmatter added to source + .copilot/ mirrors + .specify/ mirror) |
| 11 | Claude introduced MD032 violations in the iteration drift-log AND the scaffold itself had a colon+list violation | Scaffold template + no author hint | `7f6536b2` (scaffold fixed + HTML hint block with BAD/GOOD example) |
| A | Iteration 001 closed with code touched and ZERO reviewer artifacts (code-map, coverage-evidence, reviewer-index, review-diagrams, dependency-report) — validator passed | `Get-ReviewerCloseoutDiffArtifacts` had the same `git diff $baselineRef` no-op pattern as Fix #3 (second instance of the same root cause) | `162bcdb9` (working-tree union with `ls-files -m` + `--others --exclude-standard`) |
| B | No `dashboard.md` or `closeout-dashboard.md` ever produced | The renderer existed (F-017) but no auto-render hook — Claude never invoked `/specrew-where` | `162bcdb9` (Proposal 046 auto-render slice inline-shipped — `Invoke-SpecrewAutoRenderDashboard` in `sync-boundary-state.ps1`) |
| C | Dashboard's ROADMAP section had nothing to render in fresh projects | `.specrew/roadmap.yml` doesn't exist; full Proposal 057 still draft | `162bcdb9` (Proposal 057 stub-bootstrap slice inline-shipped — `scaffold-governance.ps1` writes a minimal one-row roadmap.yml) |

### Cross-cutting lesson: the "diff-against-baseline-ref" pattern

Fixes #3 (markdownlint gate) and A (reviewer-artifact gate) are the *same root cause*
in two different validators: both used `git diff $baselineRef -- '*.md'` /
`git diff $baselineRef --` and went no-op when:

- `baselineRef` didn't resolve (no `origin/HEAD`, no `GITHUB_BASE_REF`)
- OR `HEAD` didn't exist (greenfield + zero commits)
- OR the diff path returned empty

Brownfield-launched-into-fresh-repo hits all three conditions simultaneously, so every
git-diff-based gate silently disabled itself for the entire pre-first-commit phase.
Both fixes use the same remediation pattern (preserve the committed-diff path; add a
working-tree union fallback via `git ls-files -m` + `git ls-files --others
--exclude-standard`). Worth scanning the rest of the validator surface for additional
instances of the pattern — there are probably more.

### Cross-cutting lesson: greenfield bootstrap state

Several fixes (Fix #4 boundary_enforcement init, Fix #9 LASTEXITCODE leak in scaffold,
Fix #3 markdownlint gate, Fix A reviewer-artifact gate, Fix C roadmap.yml) all converge on the
same broader gap: *Specrew's bootstrap doesn't fully prepare a greenfield project for
the lifecycle that runs on top of it.* The bootstrap created files (constitution,
config, role assignments) but didn't establish the state primitives that downstream
gates assume exist (boundary_enforcement block, roadmap, valid baseline ref). The
Phase A + C fixes pre-populate or fall-back-handle each of these so the lifecycle
runs against a coherent state from boundary 1.

### Cross-cutting lesson: discoverability over enforcement

Fixes #5, #6, #11 are all "the scaffold tells the model what valid input looks like"
via HTML comment blocks. Cheaper than enforcement-then-error-then-retry, and the model
gets the canonical schema at the point where it's filling in the cells. Pattern worth
re-using for any future template that the model edits.

### Status

- **Phase A** (5 fixes): `a45232af` on main, mirrored to `040-multi-host-launch-path`
  via `b1486f4c` (callsite update for `--host` threading)
- **Phase B** (5 fixes): `7f6536b2` on main, propagated to F-040 branch via merge
- **Phase C** (3 fixes): `162bcdb9` on main, propagated to F-040 branch via merge `58d198b7`
- **Proposal 107**: shipped (status flipped)
- **Proposal 046**: partially-shipped (auto-render slice; drill-down + cross-iteration diff candidate)
- **Proposal 057**: partially-shipped (stub-bootstrap slice; full input-adapter system candidate)
- **Proposal 088**: shipped + brownfield-gap-closed annotation
- **CHANGELOG**: `### Fixed` subsection under `[0.26.0]` with full per-fix breakdown

### Outstanding follow-ups (not in this bundle)

- Re-run dogfooding test in `C:\Temp\specrew-tip-calc` with the F-040 branch loaded to
  verify all 14 fixes empirically against a tighter feature (~3 FRs, 1 user story)
- The `feature-017-dashboard-core` "Healthy fixture: specrew where should succeed" test
  was failing pre-bundle (confirmed via `git stash`) — pre-existing flake to investigate
  separately
- Scan the rest of `validate-governance.ps1` for additional `git diff $baselineRef`
  patterns that may have the same brownfield gap as Fixes #3 + A
- Proposal 057's full input-adapter system remains the next move on the dashboard /
  roadmap front; the stub-bootstrap unblocked dogfooding but the full proposal still
  needs implementation
