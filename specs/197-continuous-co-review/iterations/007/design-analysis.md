# Iteration 007 — INT-006 bridge: the code-lens reviewer choice authorizes the navigator

**Feature**: 197-continuous-co-review
**Status**: design-analysis (implementation landed in the dev tree; lifecycle gates owed)
**Date**: 2026-06-24

## The gap (found by the real-host dogfood — EnglishIntake / Copilot)

The maintainer ran F-197 on a real project and asked: *"I didn't see a question about the review AI host —
will it come before the first review?"* Tracing it: the **code-implementation lens already asks**
(`code-implementation.md` lines 54-61 / 108-113: "ask the human which continuous-co-review harness and
model should review the code … record in `reviewer_preference`"). But the async navigator authorizes from a
DIFFERENT file — `.specrew/reviewer-hosts.json` (the T086 catalog) — and **nothing connected
`reviewer_preference` to it**. So the human's choice was captured in `implementation-rules.yml` yet never
authorized the navigator → it fail-opened silently. INT-006's "present available choices when selection is
missing" shipped as lens guidance; the authorization-wiring half did not.

## The bridge

`Sync-ContinuousCoReviewReviewerAuthorizationFromWorkshop`
(`scripts/internal/continuous-co-review/reviewer-authorization-sync.ps1`): a deterministic read-and-sync.
It reads the active feature's `reviewer_preference`; if `mode = human-selected` + host, it builds the
navigator's catalog (installed-detected) with that host `allowed = $true` + `authorization_ref` and writes
`.specrew/reviewer-hosts.json`. Wired into `New-ContinuousCoReviewNavigatorReviewerPlan` — it runs only when
no catalog is persisted yet (idempotent), right before the navigator loads + selects.

## Trace + boundaries

- **INT-006** (present choices when missing): the lens presents; the bridge connects the answer to the
  authorization — the previously-missing half.
- **FR-028** (authorized once per project): the bridge persists the choice to the per-project
  `reviewer-hosts.json`; the navigator then runs every checkpoint without re-authorization.
- **INT-007** (independence): unchanged — the navigator's policy still picks the code-writer-independent host
  from the authorized set.
- **SEC-004 / Proposal 190** (no silent / no agent self-authorization): the bridge authorizes ONLY a
  human-selected host. `auto-select` and "undecided" deliberately do NOT write — they degrade to the
  navigator's fail-open. A follow-up gives auto-select its own present-the-candidates backstop rather than
  silently authorizing a possibly-paid set.

## Evidence

- Non-mocked chain test (`continuous-co-review-real-reviewer-wiring.Tests.ps1`): a human-selected manifest
  with no `reviewer-hosts.json` → the plan build syncs → the un-mocked policy selects that host (+ the
  `code-implementation-workshop` provenance); auto-select does NOT authorize (fail-open). Full CCR 239/0.
- Deploy: the bridge resolves from the dev tree via `SPECREW_MODULE_PATH` (live, no `specrew update`); the
  lens question is already present in the deployed `.specify`.

## Owed (lifecycle gates)

Maintainer-delegated direct implementation, mid-dogfood. The plan / before-implement / review-signoff gates
for iteration 007 are owed — formalize once the dogfood confirms the end-to-end behavior on the real host
(human picks reviewer in the code lens → bridge authorizes → navigator fires the review).
