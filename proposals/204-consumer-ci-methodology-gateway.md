---
proposal: 204
title: Consumer CI Methodology Gateway + Distribution Workflow Hygiene
status: candidate
phase: phase-2
priority-tier: 1
discussion: surfaced 2026-07-08/09 when the FIRST co-review of a consumer working tree in Specrew's history (F-197 identity fix made untracked content reviewable) immediately flagged the forge workflows our own bootstrap deploys — three lanes deterministically broken in every downstream project, shipping since the F-031 distribution module bundled F-019-era self-host CI as templates. Recorded as NOTE-197-I010-004 (+ addendum) on the self-host ledger; maintainer framing: "if they are gates for lint on md files, then we may want to deploy them — do we need them as Specrew methodology gateway?"
---

# Consumer CI Methodology Gateway + Distribution Workflow Hygiene

## Why

`specrew init` deploys `templates/github/workflows/*.yml` into every consumer project
(`distribution-module-init.ps1` asserts it). Those templates were written for SPECREW'S OWN repo in
the Feature-019 era (commit `6737f115`) and were never consumer-ized: they still trigger on branch
`001-specrew-product` (Specrew's own first feature), pin `SPEC_KIT_VERSION`/`SQUAD_VERSION`, and
invoke self-host paths — `./extensions/specrew-speckit/scripts/validate-governance.ps1`,
`./tests/integration/*.ps1`, `.github/scripts/sync-specrew-board.ps1`,
`tests/manual/copilot-squad-confidence-lane.ps1` — none of which exist downstream. Every consumer
project since has received CI that can only fail; it stayed invisible because consumer test projects
had no GitHub remote (Actions never ran) and no reviewer ever saw a consumer working tree — until
2026-07-08, when the first F-197 consumer-project review flagged all of it within 253 seconds
(runs `20260708T220720322` and `20260708T220613175`, C:\Temp\tesr197local: every blocking finding
was OUR scaffold; the user's feature code got zero).

The findings also answer the maintainer's question in the affirmative: the lint+validator lane IS a
methodology gateway worth shipping — the remote belt to the local gates (F-033 pre-boundary
markdownlint, boundary validator, co-review evidence) for multi-dev/PR flows. The fix is not "stop
deploying CI"; it is **split and consumer-ize**.

## What

Current template inventory and disposition:

| Template | Content | Disposition |
| --- | --- | --- |
| `specrew-ci.yml` lint job | markdownlint (all .md) + PSScriptAnalyzer + `validate-governance.ps1` | **CONSUMER-IZE** → the methodology gateway |
| `specrew-ci.yml` deterministic-gate job | installs spec-kit/squad CLIs, runs ~10 Specrew integration tests | **SELF-HOST ONLY** — remove from templates |
| `specrew-work-kind.yml` | F-182 work-kind PR validation, provider-neutral, advisory-default | **KEEP DEPLOYING** — fix the script path |
| `specrew-project-sync.yml` | GitHub Projects board sync; needs `sync-specrew-board.ps1` (never deployed) | **SELF-HOST / OPT-IN** — remove from default deploy |
| `specrew-confidence-lane.yml` | weekly copilot-squad confidence harness from `tests/manual/` | **SELF-HOST ONLY** — remove from templates |

- **W1 — `specrew-methodology-gate.yml` (new consumer template)**: markdownlint with the SAME ignore
  set as the local F-033 gate; the governance validator at its DEPLOYED path
  (`.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` — present in every
  consumer project); PSScriptAnalyzer conditional on `.ps1` files existing. Generic triggers:
  `main` + the spec-kit `[0-9][0-9][0-9]-*` feature-branch pattern — no fossilized branch names, no
  self-host version pins. Advisory-first posture per the F-182 doctrine (deterministic hard-fails
  may block; warnings never), graduating to blocking by team opt-in.
- **W2 — `specrew-work-kind.yml` path fix**: point at the deployed validator location; keep its
  advisory default.
- **W3 — Deploy-list surgery**: `Install-TemplateSurface` deploys only W1+W2 to consumers; the
  self-host lanes move out of `templates/` into `.github/workflows/` (kept for this repo only);
  `distribution-module-init.ps1` assertions updated to the new consumer set.
- **W4 — `.claude/settings.local.json` hygiene**: init adds a `.gitignore` entry for machine-local
  host config it deploys (composes with Proposal 203 W5, which owns whether reviewers see machinery
  paths at all).
- **W5 — Update-path migration**: `specrew update` removes the retired broken templates from
  existing consumer projects (the F-116 obsolete-file-removal surface) so current downstream repos
  heal.
- **W5b — Init creates (or offers) the bootstrap commit**: `specrew init` currently leaves the
  ENTIRE deployed scaffold untracked, so a fresh project's first feature diff swallows it and the
  co-review blocks on Specrew's own files for rounds (the 2026-07-09 tesr197local saga: a
  zero-commit repo where every review round flagged different scaffold, including the un-removable
  live hook wiring, until a human ack). Init should end with a `chore(specrew): bootstrap scaffold`
  commit (or an explicit offer, brownfield-aware), giving every review and every feature diff a
  clean baseline from minute one.
- **W6 — Future lane (design note only)**: the gateway can later verify CO-REVIEW EVIDENCE freshness
  on code-touched PRs (`review-run.json` digest vs the PR head) — F-197's remote enforcement arm,
  composing with Proposal 087's push-to-main scoping. Not in this slice.

## Out of scope

- Reviewer-side machinery handling (Proposal 203).
- The board-sync feature itself (Proposal 101 owns external tracker sync; W3 merely stops
  mis-deploying its workflow).
- Non-GitHub forges (the gateway stays provider-neutral by keeping logic in the deployed validator;
  other forge wirings follow the F-182 pattern later).

## Effort

~4-6 SP: W1 template authoring plus fixture/integration-test updates (2 SP); W2 trivial; W3
deploy-list and test surgery (1-2 SP); W4 one-line init change plus test; W5 rides the existing
obsolete-file removal surface (1 SP).

## Open questions

1. Should the gateway's validator step run scoped (changed iterations only, Proposal 087-style) or
   full on PRs?
2. Do consumers get the gateway on init unconditionally, or only when a GitHub remote exists at
   init/update time (capability-detected)?
3. Version pins for actions (checkout/setup-node) — dependabot-style refresh policy for shipped
   templates?

## Risks

- Removing templates from existing projects (W5) must never delete USER-modified workflow files —
  content-hash guard against the shipped versions before removal.
- An advisory gateway that consumers never graduate to blocking gives false comfort — the
  README/user-guide teaching must state the posture explicitly.

## Cross-references

- Ledger: NOTE-197-I010-004 (+ addendum) in `.squad/decisions.md` — the field findings and origin
  trace.
- [203 Reviewer Containment + Identity Hardening](203-reviewer-containment-identity-hardening.md) —
  the reviewer-side sibling.
- [087 Push-to-Main Validator Scoping](087-push-to-main-validator-scoping-and-nightly-truth-check.md),
  [111 Git-Hook Markdownlint Enforcement](111-git-hook-markdownlint-enforcement.md),
  [045 CI Watchdog Recurrence Prevention](045-ci-watchdog-recurrence-prevention.md) — the adjacent
  CI-discipline lineage.
- [101 External Tracker Sync Provider](101-external-tracker-sync-provider.md) — owns board sync.
- [116 Update-Time Obsolete File Removal](116-update-time-obsolete-file-removal.md) — W5's surface.
- [182 Work-Kind Branch Governance](182-work-kind-branch-governance.md) — the advisory-first CI
  posture and the work-kind lane itself.

## Status history

- **2026-07-09**: status set to `candidate`. Drafted from the F-197 consumer-dogfood findings at
  maintainer direction; answers the maintainer's "do we need them as Specrew methodology gateway"
  with the split-and-consumer-ize design.
