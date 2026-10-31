# Drift Log: Iteration 001

**Schema**: v2

## Summary

**Total drift events**: 5 (DRIFT-001 to DRIFT-005)
**Resolution rate**: 4 of 5 handled locally; DRIFT-005 is open for the maintainer
**Specification drift**: 0

## Events

### DRIFT-001 — the quality-profile resolver read the stack as Node plus a browser SPA (observation, recurring)

- **Observed**: 2026-10-31, plan stage, `resolve-quality-profile.ps1 -ProjectPath .`. The resolver matched the
  presets `node-rest-with-postgres` (score 90) and `react-spa-public` (score 80), declared stack surfaces "Node.js
  http-api" and "TypeScript browser-spa", and marked concurrency-correctness, resiliency and
  retry-idempotency-and-recovery not-applicable. The repository's product is a PowerShell module with host hooks.
  202's plan recorded the same misreading on 2026-10-13.
- **Requirement**: the plan's quality planning inputs (before-plan step 3); spec FR-042, FR-043 depend on the
  concurrency and retry dimensions being required.
- **Resolution**: corrected by hand in plan.md, "Quality plan (resolved profile, corrected)": stack surfaces
  replaced, and the three dimensions made required with rationale. Recorded at the maintainer's plan verdict.
- **Class closure**: OPEN — the resolver will misread the next feature in this repository too. Backlog candidate:
  the resolver should weigh the repository's own module manifest and language mix over preset keyword matches,
  and say when its reading is low-confidence.

### DRIFT-002 — the agent-context script removed an unrelated line from .github/copilot-instructions.md (observation)

- **Observed**: 2026-10-31, plan stage, `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`.
  The script changed the "Last updated" date and removed the `046-create-spec-branch` entry from the recent-changes
  list, leaving a stray blank line. It added no 203 technology, because the stack is unchanged.
- **Requirement**: none of 203's; a generated surface changed outside the feature's scope.
- **Resolution**: reverted with `git checkout -- .github/copilot-instructions.md` before the plan commit; the file
  is unchanged in 203's history. Recorded at the maintainer's plan verdict.
- **Class closure**: OPEN — the B4F-111 family (generated-surface churn and ordering). Backlog candidate: the
  agent-context update must not drop existing entries, and a no-new-technology run should leave the file
  untouched.

### DRIFT-003 — the before-implement packet opened with "Overall verdict: BLOCKED for implementation" (observation)

- **Observed**: 2026-11-01, the before-implement packet. The before-implement command requires the readiness
  script's first line verbatim as the report's first line. At a normal approval step, before the human's verdict,
  that line is always `Overall verdict: BLOCKED for implementation - 'before-implement' is not authorized ...`, so
  the packet opened with what reads as a failure at the exact moment nothing was wrong.
- **Requirement**: the refusal standard and the ui-ux binding `blocking-text-audience: human-plain-words`; B4F-071
  is the reason the line exists (a BLOCKED line was once summarized to PASS).
- **Resolution**: recorded at the maintainer's before-implement verdict; no change to the packet already sent.
- **Class closure**: OPEN — backlog candidate: at a pending crossing the readiness line should read as the state
  it is ("waiting for your approval to start implementing") rather than as a failure, while still never being
  summarized to PASS; or the line belongs in the crew's checks, not the human's packet.

### DRIFT-004 — the pin is selected by a record file, not by the launcher's SPECREW_MODULE_PATH (design detail)

- **Observed**: 2026-11-01, T002 implementation. The plan and DA-8 said the pin would be selected through the hook
  launcher's `-ModulePath` (`SPECREW_MODULE_PATH`).
- **Requirement**: DA-8; T002 "inert until configured" (before-implement verdict).
- **Resolution**: the pin is configured by `.specrew/runtime/live-engine.json` (machine-local, git-ignored), written
  only by `scripts/internal/live-engine-pin.ps1`. `SPECREW_MODULE_PATH` is a shared developer override that tests and
  the boundary-sync wrapper also read; giving it "configured but unusable refuses" semantics would reach beyond the
  hooks. The record file keeps T002 inert until configured and confines the refusal to the hooks.
- **Class closure**: NONE — a design detail within DA-8's intent; plan.md wording updated at the next plan touch.

### DRIFT-005 — mirror-parity tests fail on the branch between deployment points (open, for the maintainer)

- **Observed**: 2026-11-01, the T002 regression sweep (103 files touching the changed providers, the dispatcher or
  shared-governance, run in a scratch checkout of `9f81fb52`). 10 failed; the same 10 at the base `fca9067e` gave 2
  pre-existing failures (`boundary-reader-conformance`, `CoordinatorFrontLoad`). Of the 8 new ones, 7 are mirror or
  deployed-copy parity checks (`ProviderMirrorParity`, `deployed-mirror-parity`, `conformance-material-turn-gate`
  parity case, `conformance-provider-seam`, `host-identity-runtime`, `session-orientation-rendered`,
  `workshop-material-packet-language`), all failing on "source and deployed `.specify` mirror differ", which the
  203 exception makes true until the deployment point. The 8th, `refocus-dispatcher` ("non-Specrew directory:
  silent no-op"), failed once under the 6-way parallel sweep and passed 3 of 3 in isolation.
- **Requirement**: the 203 `provider-mirror-parity` exception (plan, "When 203's changes reach the live hooks");
  the B4F-158 class (red as the normal colour hides real failures).
- **Resolution**: OPEN — these suites run in the branch CI lanes and the census, so the branch shows red on parity
  between deployment points. Options for the maintainer: accept the red on parity until each deployment point, or
  have the parity checks honour `iterations/<NNN>/deploy-pending.md` (fail on any drift NOT listed there).
- **Class closure**: OPEN.
