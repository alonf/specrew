# Feature Closeout: 198-beta2-hardening

**Schema**: v1
**Feature**: 198-beta2-hardening
**Presented at the feature-closeout gate**: 2026-08-10
**Status**: presented for the feature-closeout verdict — the gate verdict is the closure ruling

## Delivered scope, with evidence

- **Authorization integrity — the beta2 tag basis.** FR-066's arrival state (an unrecordable
  crossing is a branchable state; the surface names what is missing) and FR-068's evidence half
  (tree-bound stage evidence, fail-closed unverifiable reasons, strict matcher). Evidence:
  iteration 011's record, certification round-2 validation (byte-unchanged since), the 90/90
  honesty-gate floor, and live behavior — during this very closure the evidence gate refused an
  identity-less crossing and the capture layer refused to authorize outside a verified pair.
- **Four pre-tag release-gate slices** (first-boundary arrival through all nine shipped skills,
  marker-invention retirement, capture refusals, Ordinal evidence matching, containment
  boundaries) — the drift log's release-slice table carries the per-slice record.
- **v0.40.0-beta2 published**: merge `67a5d7bc` (PR #3318), annotated tag naming the release
  claim as the position of record, publish workflow green including the tag-time prepublish
  gate, PowerShell Gallery listing live 2026-08-09T00:48:33Z with the Prerelease flag, GitHub
  release carrying the twelve-item known-issues body.
- **Certification lineage**: `run-f198-beta2-c0c3cda6-certify`, `run-f198-beta2-4e7d002c-certify`,
  `run-f198-beta2-0fa26271-certify` — immutable terminals in the review authority store; the
  third adjudicated by the maintainer's trajectory ruling (two expected residuals, one link-class
  routing, two design owners recorded as release-claim limitations 12/13). The tag basis differs
  from the certified head by the measured 15-file, zero-code delta (Review Proof aligned in-repo
  by PR #3503, merged).
- **T067 — published-bits consumer validation**: Gallery install (no pinning), full governed
  lifecycle on a blind consumer project, six boundary verdicts faithfully captured, product built
  and signed off with recorded residuals through the identity-bound disposition route;
  retro/iteration-closeout not exercised there (recorded coverage gap). Findings consolidated in
  the beta3 carry ledger.
- **Iteration 011 closed 2026-08-10** on the maintainer's hook-captured verdicts with the scoped
  accepted-verdict waiver; `review.md` keeps `needs-rework` — the record's words were never bent.

## Validation record

F-198 honesty regression suite 90/90 green (regression floor, not certification); independent
certification attempted to the full 3-round cap and not achieved — a named limitation, not a
claim; T067 full-lifecycle dogfood on the published package; release workflow green at the tag;
the Review Proof line aligned to the measured statement on main.

## Known non-blocking warnings, with dispositions

| Warning | Disposition |
| --- | --- |
| The -044 accepted-verdict wall (`complete` requires `accepted` requires every task `pass`) | Waived scoped twice on the honest record (release gate 2026-08-06; iteration-closeout gate 2026-08-10); real fix in beta3's vocabulary cluster |
| Standing main red — `Deterministic gate` / `generator-markdown-parity` INCONCLUSIVE (`markdownlint-cli` absent on the runner) | Chore carried: install the tool in the CI workflow (closeout notes, 2026-08-10) |
| Validator WARN classes (`handoff-block-missing` in clean flows = carry-ledger obs-3; dashboard WARNs on long-closed iterations) | Known noise classes, carried in the ledger |
| FR-066 mint guard NOT delivered (two designs faulted and reverted; release-claim limitation 7 / the `security-surface` deferral) | Design-spike debt carried per the beta3/beta4 split ruling |
| Verdict-capture defects root-caused at closure (instruction text containing "prompt" flips approval to *discuss*; first-human-turn shadowing; `'clarify'` in filename prose parsed as a named boundary) | Beta3 findings with reproductions, recorded in the closeout notes |

## Branch hygiene

Branch `198-beta2-hardening` carries the post-tag records tail ahead of origin (the carry ledger,
the closure-debt and closeout commits). **Pushing the branch and any records-PR to main are
external mutations this closeout does not authorize** — each needs the maintainer's explicit go.
Remaining working-tree dirt is pre-existing runtime/squad state, dispositioned as runtime records;
the approved post-beta2 gitignore chore (issue #3091) covers the `.specrew/review` class.

## Final status

**Prerelease shipped and consumer-validated; stable promotion deliberately NOT included.** Under
the resolved beta-stable model, stable publishes only after the maintainer's explicit PASS ruling
on the installed prerelease. T067's record — including its recorded residuals and its
retro/closeout coverage gap — is the *input* to that ruling; the ruling itself remains open and
human-owned. Branch-ready records; feature governance closes at the feature-closeout verdict.

## Carried items, named

- **The beta3 carry ledger** (committed unedited, `b9c5bacb`) — the handoff input: beta3
  stabilization (~10–12 SP) and beta4 deep work (~24–32 SP) per the 2026-08-09 split ruling,
  including the claim-alignment obligation (beta3's release notes must state explicitly that the
  two certify design owners moved to beta4).
- **Closeout-notes chores and findings** (iteration 011 state.md, 2026-08-10): the markdownlint
  runner install; the two capture defects; the F5/stop-surface fresh instances (five
  `review-stale` firings on records-only deltas); the limitation-11 feature-cycle edge observed
  live.
- **The review-evidence gitignore chore** (approved post-beta2; pairs with issue #3091).
