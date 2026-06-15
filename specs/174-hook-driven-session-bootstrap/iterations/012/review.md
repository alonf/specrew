# Review: Iteration 012 (review-signoff)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Iteration**: 012 (F-174 user-facing documentation reconciliation + F-182 merge reconciliation)
**Reviewer**: Crew (self-review) + maintainer close-review turn-by-turn
**Date**: 2026-06-15
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-006, FR-009 | pass | README reconcile + the five additions (one-time init, Antigravity, hands-off flags, Updating, Try-the-latest-beta) |
| T002 | FR-028, FR-006 | pass | getting-started reconcile (launch-then-continue host switch, anchor fix, `specrew update` canonical re-sync) |
| T003 | FR-009, FR-022, FR-027 | pass | user-guide Session Continuity + verdict integrity + per-host delivery |
| T004 | FR-028, FR-027 | pass | troubleshooting DR-6 (`WARN PAYLOAD_OVERSIZE`, `SPECREW_MODULE_PATH`, `specrew hooks`) |
| T005 | FR-022, FR-026 | pass | data-contracts handover schema + api-reference `specrew handover` / `hooks` |
| T006 | FR-009 | pass | CHANGELOG `0.37.0-beta1` + methodology pointer |
| T007 | SC-001 | pass | verification: 9 focused lanes + bootstrap suite + validator + markdownlint green |

## Gap Ledger

- No requirement (FR/SC) gaps for the documentation scope (DR-1..DR-10 / SC-1..SC-6): all in-scope requirements verified: fixed-now.
- F-182 merge-reconciliation drift (D-009 SessionStart cap, D-010 forge sweep, D-011 specify.md gate-stop), surfaced when `origin/main` merged mid-iteration, repaired with green lanes plus the resume-floor guard: fixed-now.

## Scope reviewed

1. **Docs reconciliation (DR-1..DR-10):** README, getting-started, user-guide, troubleshooting, data-contracts,
   api-reference, CHANGELOG, methodology — reframed to the shipped hook-driven model (after `init`, just launch
   the host; cross-host handover; per-host delivery; verdict integrity; the new commands) in user-facing
   explain-voice (no test/validation/evidence jargon).
2. **Five new doc additions:** one-time-`init` note; `## Starting on Antigravity`; `## Hands-off mode
   (auto-approve)` flag table; `## Updating Specrew`; `## Try the latest beta` (install + update + back-to-stable +
   feedback) — plus the `specrew update` canonical-project-resync coherence fix.
3. **F-182 merge reconciliation (drift D-009/D-010/D-011):** code/test fixes surfaced when `origin/main` merged
   mid-iteration — the SessionStart cap (D-009), the forge-neutralization sweep (D-010), and the `specify.md`
   gate-stop host-scoping drift (D-011).
4. **Release-prep:** version bump to `0.37.0-beta1` across the release-truth files.

## Method

Artifact-by-artifact reconciliation against the shipped behavior; an adversarial multi-agent doc-consistency sweep
(zero residual defects after the maintainer's four named findings were fixed); deterministic lane runs for every
code/test change; the governance validator on the full tree.

## Findings and resolution

All findings raised in review are **resolved**; the corrections were driven turn-by-turn with the maintainer.

| # | Finding | Resolution |
|---|---------|-----------|
| F1 | Stale host-switch instruction (getting-started) | Rewritten to launch-the-host + `continue`; `specrew start --host` is the optional driver / Antigravity path |
| F2 | Broken Session-Continuity anchor (getting-started) | Repointed to the live heading |
| F3 | DR-6 tokens absent (troubleshooting) | Added `WARN PAYLOAD_OVERSIZE` + `SPECREW_MODULE_PATH` dev/dogfood sections |
| F4 | Stale `deploy-refocus-hooks.ps1` user surface (user-guide) | Replaced with `specrew hooks remove` |
| F5 | Cap regression (DirectiveDeliveryCap, D-009) | Reverted the wrong reconciliation cut; recovered headroom from refocus B2; added the resume-floor guard. Primary 9,127 / verdict-worst 9,894 (both under 10K) |
| F6 | Forge sweep failure (D-010) | Specrew-own update-check marker + relocated `launch-contract.ps1` added to the sweep's positive-assertion list |
| F7 | `specify.md` gate-stop drift (D-011, pre-existing) | Host-scoped phrasing restored to the digest contract |

**Process correction recorded:** an interim cap fix cut the reconciliation excerpt 300→100 — spending the fix
against the feature's resume behavior. The maintainer caught it; reverted to the dogfooded 300 floor, recovered
the headroom from the co-resident refocus B2 instead, and added the floor-guard so the regression cannot recur.

## Verification evidence

- Focused lanes green (9/9): DirectiveDeliveryCap (+ the new 4b resume-floor guard), HostDeliveryPolicy,
  HandoverHookPrimary, HookPacketCapture, HookVerdictCapture, refocus-channels, refocus-digests, refocus-engine,
  forge-neutralization-sweep. Bootstrap suite + contract-parity guards green (47/47).
- Governance validator: all iterations PASS incl. iter-012.
- markdownlint clean on all touched docs; provider mirror parity (3) and digest parity (2) intact; both scripts
  parse clean.

## Residuals / deferrals (honest)

- **D-007 (CAP-1)** stays open as the architectural parent: the durable reduction is **Proposal 191** (lead pilot:
  pre-compute the in-flight digest to `.specrew/runtime/resume-now.md` + pointer, ~700–850 char reclaim — supersedes
  this interim refocus trim) + **Proposal 179** (dispatcher fragment-priority drop). The current verdict-worst
  headroom is ~106 chars — adequate for the beta, not a permanent state.
- **Version narrative:** CHANGELOG has no `[0.36.0]` entry (pre-existing gap from main's F-182 ship); the badge
  shows the base `0.37.0` while the psd1 `Prerelease=beta1`. Release-prep items, not blockers.
- **GH Copilot PR review** is requested at the PR step; per repo history it is unreliable on gh-PRs (may not fire).
- **Behavioral SCs (SC-2 cross-host)** are real-host-confirmed on Claude/Codex/Copilot; Cursor pending; the
  rich-packet/verdict-capture remains Claude-only (documented accurately).

## Verdict recommendation

The iteration's acceptance criteria (SC-1..SC-6) are met: the six surfaces teach the hook-driven model accurately,
no false host-confirmation claims remain, the new commands + handover schema are documented, lanes + lint + the
doc-coverage re-check are green, and the merge-reconciliation is fixed-with-evidence and floor-guarded. **Recommend
APPROVE for review-signoff** → retro → iteration-closeout.
