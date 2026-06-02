# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-06-02
**Review verdict**: accepted (Crew Reviewer) → maintainer review-signoff **APPROVE**

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T010 | 1 | 1 | 0 |
| T011 | 2 | 2 | 0 |
| T012 | 3 | 3 | 0 |
| T013 | 3 | 3 | 0 |
| T014 | 2 | 2 | 0 |
| T015 | 4 | 4 | 0 |
| T016 | 2 | 2 | 0 |
| T017 | 2 | 2 | 0 |

**Average variance**: 0 SP. No task overflowed its estimate; the Ubuntu CI proof passed on the **first**
run, and the in-review corrections (escaped-pipe parse fix, faithful-reporting wording) were absorbed
without consuming the 1 SP headroom. (AI-execution caveat as in Iter-1: SP variance = "did the task
overflow its scope," not clock-time.)

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | included | included | 0 | Plan + hardening gate + D11/D11a (MS-docs-derived) + ratified T010 decision. |
| Discovery/Spikes | 1 | 1 | 0 | D11 install matrix from Microsoft's current docs; T010 curl-to-sh/sudo decision. |
| Implementation | 12 | 12 | 0 | install.sh + tests + CI + lens; two read-only-var-free shell bugs caught by `bash -n`/CI, fixed in-scope. |
| Review | 6 | 6 | 0 | Ubuntu CI proof + security lens + Proposal 145 pass + advisor-driven faithful-reporting fixes. |
| Rework | buffer | ~0 | -1 (unused) | The escaped-pipe + wording fixes were small in-review corrections; 1 SP headroom not consumed. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- **The highest-risk code was built AND proven in-iteration.** The auto-install passed on the **first**
  Ubuntu CI run: a clean no-`pwsh` `ubuntu:24.04` container installed pwsh 7.6.2 from the Microsoft repo
  end-to-end, on branch code (`specrew version` worked). The advisor's "build-and-prove-together for
  intrinsically-runtime code" reframe (vs. build-now/prove-later) is what made that possible.
- **platform-not-proxy paid off concretely.** Git Bash (MINGW) could *not* prove FR-003 (symlink) or
  FR-004 (pwsh-missing) — both **passed on real Ubuntu CI** (`4 passed, 0 failed`). Treating Git Bash as a
  forwarding/syntax smoke (never the verdict) was exactly right; the Ubuntu lane caught what the proxy
  couldn't.
- **The advisor caught two faithful-reporting errors before sign-off.** (1) "validate-governance exit 0"
  didn't actually cover the still-untracked 002 plan — which, once committed, *failed* on the escaped-pipe
  parse; commit-then-validate fixed the claim. (2) "Ubuntu/Debian proven end-to-end" overstated (the
  container is `ubuntu:24.04` — only Ubuntu installed); relabelled to Ubuntu-proven + Debian-detection-proven.
- **The MS-docs-derive obligation was honored**: the install method came from Microsoft's *current* docs
  (the PMC apt repo), and the per-version PMC `.deb` 404 became the fail-closed signal — strictly better
  than a hardcoded version list.
- **`run_privileged` (root → no sudo) unified the container + real-user paths** and dodged the
  absent-`sudo`-in-a-root-container landmine the advisor flagged — one code path, two contexts.
- **Honest CI-vs-manual enumeration**: the `Install-Module`-from-PSGallery atom + interactive-`sudo` were
  explicitly labelled un-CI-provable (Iter-3 / manual), so the hardening gate never overstated coverage.

## What Didn't Go Well

- **Reviewer-artifact scaffold-chain friction.** `scaffold-reviewer-artifacts` requires a pre-existing
  artifact set (review.md, drift-log.md, …); skipping `scaffold-iteration-artifacts` at implement-start
  meant discovering the required set by trial via validate-governance feedback. Signal: run the iteration
  scaffold at its designed boundary (implement-start), not manually.
- **Escaped-pipe `\|` in the iteration-plan Tasks table** mis-parsed (Status + capacity under-count);
  caught at validation. Recorded as a memory; no literal pipes in Tasks-table cells.
- **A `sed` to insert `tr -d '\r'` mangled the escape** (inserted a literal CR), fixed by a clean rewrite.
  Signal: prefer the Edit tool over `sed` for escape-sensitive in-file changes.
- **Gap-Ledger "deferred" wording** tripped the deferred-gap-approval validator; reworded to scope-not-gap
  (matching Iter-1's clean single `fixed-now` bullet).

## Improvement Actions

1. Owner: Implementer | Phase: implement-start | Type: process | Expected effect: run
   `scaffold-iteration-artifacts` at the start of implementation so the reviewer-artifact set exists when
   review scaffolding runs — eliminate the manual required-artifact discovery loop.
2. Owner: Planner/Reviewer | Phase: authoring | Type: process | Expected effect: no literal `|` in
   iteration-plan Tasks-table cells; use the Edit tool (not `sed`) for escape-sensitive in-file edits.
3. Owner: Reviewer | Phase: review | Type: process | Expected effect: when citing CI as proof, cite the
   **branch-tip** run + read **per-job logs** (not the bare green check or an ancestor run), and state the
   CI-vs-manual + platform scope precisely (avoid "X/Y end-to-end" when only X ran).

## Calibration Suggestion

- Suggested capacity adjustment: 20 → 20 (no change).
- Rationale: 19/20 consumed, CI green on the first run, ~0 rework. The **platform+proof split** (not
  build-then-prove) kept the iteration honest and in-bounds — it should be the template for any
  runtime-dependent feature.

## Signals for Iteration 3 (maintainer-confirmed scope)

- **macOS/Homebrew + remaining MS-supported distros**, each proven on its surface (macOS = **manual proof**;
  macOS CI runners lack a clean no-`pwsh` env).
- **`install.sh --prerelease` (FR-017)** — built AND proven against a **published beta** at the release
  gate (the proof-artifact only exists then; this is exactly why it is Iter-3, not Iter-2).
- **Native-first docs** (FR-014 / SC-005).
- **The beta-before-stable release gate** (FR-015 / SC-006): greenfield + brownfield installed validation
  via `curl … | sh -s -- --prerelease` → `specrew version` / `specrew init` / `specrew start`, covering
  bundled Spec Kit 0.9.0.
- **Iteration-3 hardening gate must re-raise** `security-surface` / `error-handling` / `test-integrity` for
  the **macOS + prerelease** surfaces as `Blocking: true` (the Ubuntu portions are recorded this iteration;
  the macOS/prerelease portions are new and unproven until Iter-3).
- **No beta/stable publish** without explicit maintainer authorization.

## Notes

- Scaffolded from plan.md, state.md, drift-log.md, and review.md, then filled with iteration evidence.
- Iteration 2 delivered + **proved on Ubuntu CI** the platform-agnostic-plus-Ubuntu core; macOS,
  `--prerelease`, docs, and the release gate are Iteration 3.
