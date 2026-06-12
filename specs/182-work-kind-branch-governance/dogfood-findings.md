# Feature 182 — Dogfood Findings (real GitLab forge test)

**Status**: LIVING — collected during the 0.36.0-beta1 dogfood (real GitLab repo:
`gitlab.com/alonfliess-group/alonfliess-project`). Drives a **reopen → Iteration 4** on this branch
(before merge), NOT a separate proposal. Iteration 4 scope is decided at a before-implement gate after
the dogfood wraps.

**Test context**: branch build (`SPECREW_MODULE_PATH` dev tree, 0.36.0-beta1, not published); a
greenfield link-shortener project; `provider: gitlab`; trunk-based, `main` release-truth. The point is
to stress iteration-3's forge-neutralization on a genuinely non-GitHub forge.

## Findings

| ID | Surfaced at | What | Evidence | Severity | Candidate Iteration-4 fix |
| --- | --- | --- | --- | --- | --- |
| DF-001 | DevOps & Operations lens | **CI-lane GitHub-only default leaks on a non-GitHub forge.** The agent proposed/defaulted CI to "GitHub Actions" on a GitLab repo (diagram + the v1-CI question), never reaching for GitLab CI. **Follow-up: after correction the agent adapted correctly** — design-analysis Option A says "keeps **GitLab CI** deferred as separate devops work." So the agent CAN do the forge-neutral thing; the gap is the DEFAULT + the missing non-GitHub artifact, not agent capability. | Agent DevOps-lens output proposed "optional GitHub Actions" + asked "should v1 include an actual GitHub Actions CI file" — on a `gitlab.com` repo. Then post-correction the agent said "GitLab CI deferred" in design-analysis (commit `bdc673b`). | moderate | Root cause: iteration-3 neutralized the governance **prose**, but the only shipped work-kind CI lane is `templates/github/workflows/specrew-work-kind.yml` (GitHub-only) — so the agent's *default* reaches for the GitHub artifact. Fix options (decide at before-implement): (a) ship a forge-neutral CI-lane story — a GitLab CI lane template and/or a forge-neutral generator; (b) at minimum make the DevOps lens propose "CI for YOUR forge (`.gitlab-ci.yml` on GitLab, GitHub Actions on GitHub, …)" and surface plainly that no non-GitHub lane ships yet. The DEFAULT is the bug; the agent corrects when told. |
| DF-002 | DevOps & Operations lens | ~~Remote provider not detected despite a GitLab remote.~~ **RESOLVED — not a bug.** | The agent DID check: `repository-governance.yml` records `evidence: "human-provided; local git remote -v returned no configured remote"`. There is genuinely no remote configured (project is local-only; not pushed to gitlab.com). Honest provenance capture. | n/a | None — the agent's honest "human-provided / no remote detected" recording is correct behavior. (Side note: the user hasn't wired the real GitLab remote, so the forge is config-declared, not connected.) |
| DF-003 | plan → tasks → before-implement → implement | **Boundary discipline — UNCONFIRMED.** Agent went plan→built-feature across 4 steps; need to confirm it stopped at each human boundary (esp. before-implement) for explicit approval. | Pending the maintainer's confirmation of whether it stopped at the before-implement gate or rolled through. | TBD | If it rolled through before-implement → boundary-skip finding (the "auto-ran past the gate" failure). If the human approved each → non-finding. |
| DF-004 | capability detection | **Capability detector reports `provider: "gitlab-ci"`, not `"gitlab"`.** It read the CI-system field, not the forge `provider.name: "gitlab"`. | `Invoke-SpecrewCapabilityDetection` on wk-realtest returned `"provider": "gitlab-ci"` while `repository-governance.yml` has `provider.name: "gitlab"` + `ci.provider: "gitlab-ci"`. | minor | The detector's provider-field resolution reads the wrong key (or the agent's richer custom governance structure doesn't match the canonical schema the detector expects). Cosmetic — it still degrades honestly to manual/describe-only. Fix: align the detector's field read with `provider.name`, and/or confirm the agent's authored structure validates against `repository-governance.schema.json` (it improvised a much richer shape: `provider.name`, `protection_intent`, `ci`, `invariant`, `release_tags`). |
| **DF-005** | **`.specrew/last-start-prompt.md` (deployed launch prompt)** | **HEADLINE — forge-neutralization is INCOMPLETE at the runtime launch-prompt layer.** The agent's actual launch instructions on a GitLab project still mandate `gh pr create` + `Install-Module Specrew` for closeout. | `wk-realtest/.specrew/last-start-prompt.md:213` (project init'd TODAY from 0.36.0 greenfield) carries the BARE, un-neutralized closeout SDLC: "Step 6 create the PR with `gh pr create` … Step 10 verify prerelease publication with `Find-Module Specrew` … Step 11 … `Install-Module Specrew`." Root source in the **dev tree**: **`scripts/specrew-start.ps1:2590`** hardcodes that exact string (it writes the launch prompt for every host), and **`.github/agents/squad.agent.md:1542`** carries it too. The neutralized "instantiate each step from the project's repository-governance.yml … never assume a forge" language reached ONLY the coordinator methodology source (`specrew-governance.md`), not the launch script or the deployed agent file. | **HIGH** | **Root cause = the exact "markdown-only sweep" bound I flagged in the iter-3 review.** The SC-008 sweep is markdown-only + scoped to methodology/coordinator roots, so it could not see `specrew-start.ps1` (a `.ps1`) or `.github/agents/` (deployed host file). Iteration-4 fix: (1) neutralize the hardcoded closeout SDLC in `scripts/specrew-start.ps1` with the same labeled-example treatment as `specrew-governance.md`; (2) regenerate/neutralize `.github/agents/squad.agent.md` (and verify `.claude`/`.codex` agent files — they're currently clean: 0 hits); (3) **extend the SC-008 sweep to cover `.ps1` launch-prompt strings + deployed agent surfaces**, not just markdown methodology. This is the gap a real non-GitHub deploy-and-run was always going to find — and it did. |

| DF-006 | session resume / feature-closeout | **CONFIRMED + HIGH — `specrew start` regeneration CLOBBERS implementation-complete iteration state.** On resume, the session-start scaffold reset `state.md` + `tasks-progress.yml` to "not-started / 15 pending" and left `tasks.md` reading `planned` — i.e. it overwrote DONE work back to not-started. The gate preflight caught it and reconciled to committed-tree truth (commit `a591e6f`), but the root defect will recur for EVERY feature/resume in this setup. **NOT Feature-182 scope** (this is session-start/runtime-state, F-171/refocus/specrew-start territory — not work-kind/forge). | `wk-realtest/.../iterations/001/{state.md,tasks-progress.yml}` clobbered to not-started; `tasks.md` stale `planned`; reconciled in `a591e6f`. Agent: "specrew start regeneration overwrote implementation-complete iteration state … it will recur for every feature in this setup." Also the F-039 halt + framework-deploy gitignore (`b175af4`). | **HIGH** | **Separate bug-fix work item, NOT Feature-182 Iteration 4.** A state-truth corruption that relies on the gate preflight to catch every time (fragile — same "don't make mistakes too easy" anti-pattern as DF-005). Root: `specrew start` regenerates/clobbers committed iteration state instead of preserving it. Also: `specrew init` should gitignore the installed framework deploy by default. File as its own bug-bash slice. |

| DF-008 | lifecycle-end carried-forward + offers | **Scope/category leak: a Specrew-FRAMEWORK defect was recorded as a DOWNSTREAM project's carried-forward work item; and a devops item was offered as an "iteration" of the software-feature.** The work-kind model has no clean category for "a defect in the tool I'm using" (vs "work in my project"), so the `specrew start` clobber (a Specrew defect) leaked into the link-shortener's closeout/retro as project work. Separately, T015 (devops/CI) was offered as "iteration 002 of 001-link-shortener" — folding devops into the software-feature, against the approved posture ("distinct kinds = distinct work items; CI = devops not app-feature work"). | Maintainer caught it: "why does it offer a specrew one for a downstream project?" The agent recorded the Specrew defect as carried-forward item #2 in the link-shortener retro/closeout (it offered an "upstream issue note" but still mis-scoped it as downstream work). Lifecycle-end option (b): "open iteration 002 to implement the deferred T015 GitLab CI slice." | moderate | Feature-182 work-kind-model relevant (candidate for Iteration 4 OR a model discussion): (1) the model needs a clean way to route a **framework/tool defect** surfaced mid-work to the UPSTREAM tool's backlog, not the downstream project's carried-forward items (upstream-vs-downstream scope). (2) A new work KIND (devops/docs/bug-bash) should open a **separate work item**, not an "iteration N" of a different-kind feature — tighten the offer/flow so it doesn't conflate. |

| DF-009 | docs-only work-item intake | **CONFOUND-PROOF — the work-kind lifecycle TEMPLATES are inert; lifecycle-right-sizing isn't wired into intake.** Opening a docs-only work item, the agent improvised a 3-option ceremony menu (heavier than / unlike the shipped `docs-only-lifecycle.md`) because the governance that defines the right-sized flow is never surfaced. | Artifact facts (not agent behavior): (1) `docs-only-lifecycle.md` is **NOT deployed** to `wk-realtest`; (2) the lifecycle templates are referenced **only in `Specrew.psd1` FileList**, by no runtime/intake surface; (3) `work-kinds.yml` encodes `lifecycle_weight: lightweight` for docs-only but does NOT point to the template defining it. The shipped template prescribes `intent+audience → edit → markdownlint+link → PR → review → docs-closeout` — none of the agent's options matched. | moderate-HIGH | Feature-182 Iteration-4 (or adjacent): **operationalize the lifecycle templates** — deploy them into projects and/or reference them from the catalog + intake so a `<kind>` work item is governed by `<kind>-lifecycle.md`, not agent improvisation. Today lifecycle-right-sizing (a headline work-kind value-prop) is documentation-only. This is the cleanest demonstration of the confound: the artifact gap is provable; the agent's "reasonable" right-sizing was its own judgment, not the governance. |

### DF-005 follow-up (compensation nuance — important for severity)

At the actual feature-closeout boundary the agent rendered the closeout SDLC **generically** ("open the
PR … tag a beta, publish") and explicitly noted "module beta/stable publish steps do not apply — this is a
downstream app, not the Specrew module." So the **outcome** on this run was forge-neutral: the agent
COMPENSATED for the un-neutralized launch prompt with its own judgment. The SOURCE gap
(`specrew-start.ps1` / `last-start-prompt.md` bare mandate) is therefore a **latent landmine** that a more
literal-following host (the Codex failure mode) would still trip. Keep DF-005 HIGH: the fix is to
neutralize the source, NOT to rely on the agent compensating. This is precisely the "Specrew makes agent
mistakes too easy" principle — the un-neutralized source *invites* the mistake; the strong agent dodged it
this time.

## Cross-feature coordination with F-174 (session-bootstrap) — IMPORTANT

The session-bootstrap worktree `C:\Dev\Specrew-session-bootstrap` is **Feature 174
(`174-hook-driven-session-bootstrap`)**, actively rewriting `scripts/specrew-start.ps1` (510 lines →
`scripts/internal/bootstrap/*` incl. `SessionStateAccessor.ps1`). F-174 **branched before** F-182's
iteration-3 forge-neutralization. Consequences:

- **DF-006 → F-174 (owner).** F-174 owns + rewrites the session-start/state code; the clobber is likely
  already addressed by the rewrite (new `SessionStateAccessor.ps1`). Action: F-174 verifies its rewrite
  does NOT reset done→not-started on resume + adds a regression test. NOT a Feature-182 slice.
- **DF-005 collides with F-174.** F-174 moved the hardcoded launch-prompt closeout mandate from
  `specrew-start.ps1` into a NEW `scripts/internal/launch-contract.ps1` — so DF-005's fix target moves
  under F-174. The launch-prompt neutralization should land in F-174's `launch-contract.ps1` (it owns the
  file), coordinated with F-182 Iteration 4 (which owns the `.github/agents/squad.agent.md` regen + the
  SC-008 sweep widening + the coordinator-source neutralization).
- **DF-010 (NEW — release-train hazard).** F-174 still carries the OLD un-neutralized coordinator sources
  (`coordinator-decision-guidance.md`, `coordinator-response.md`, `specrew-governance.md` with the bare
  `gh pr create` mandate). **Merging F-174 after F-182 would REGRESS the forge-neutralization** unless
  reconciled. Whoever merges second must re-apply / verify the neutralization.

### Coordination LOCKED (F-174 crew accepted, 2026-06-12)

- F-174 **waits for F-182 to merge first**, then rebases onto post-F-182 main, **preserving** F-182's
  neutralized coordinator sources.
- **DF-006** → F-174 adds a resume-preserves-state regression test now.
- **DF-005** → F-174 owns the new `scripts/internal/launch-contract.ps1` string and neutralizes it after
  rebasing onto F-182's labeled-example pattern.
- **DF-010** → F-174 will NOT overwrite F-182 coordinator-source changes. Expected conflict =
  `specrew-start.ps1`; resolve **in favor of F-174's deletion** (the launch block moved to
  `launch-contract.ps1`).
- **F-182's binding obligation:** the **widened forge-neutralization sweep MUST land with F-182** so it
  catches F-174's remaining `launch-contract.ps1` site during reconciliation. → makes the sweep-widening
  the load-bearing Iteration-4 deliverable. F-182 also neutralizes its own `specrew-start.ps1` string so
  F-182 ships forge-clean + the sweep is green on our tree (that block is discarded at F-174's rebase per
  the deletion-wins rule — harmless).

## Test-validity note — the agent-knowledge confound (maintainer-raised, load-bearing)

The dogfood agent is a capable model with Specrew awareness (general knowledge + possible memory/context
bleed — same model family that built Specrew). This **confounds behavior-level findings**: forge-neutral
reasoning, recognizing a Specrew defect, MR terminology, the DF-005 "compensation" — none can be cleanly
attributed to the DEPLOYED governance vs. the agent's prior knowledge.

- **Confound-PROOF (trust these):** artifact-level facts — DF-001 (no GitLab lane ships), DF-004 (detector
  field), **DF-005 (launch prompt hardcodes the bare mandate)**, DF-006 (`specrew start` clobbers state).
  True regardless of agent knowledge; the confound HARDENS them. Our reopen case rests here.
- **CONFOUNDED (discount):** every "forge-neutrality holding / agent compensated" positive. Can't credit
  the governance for the agent's judgment; the confound SOFTENS these.

**Methodology for future dogfoods:** (1) prefer ARTIFACT-LEVEL checks (the leak-grep: does the deployed
file say `gh pr create`?) over BEHAVIOR grading; (2) for behavior tests use a NAIVE agent — no Specrew
memory, told to rely only on deployed artifacts — and verify the dogfood agent can't read the
`…/C--Dev-Specrew/memory/` dir (a direct contamination channel); (3) the deterministic work-kind VALIDATOR
is confound-proof (a script biting = the governance; the agent surfacing it = confounded). The isolated
validator smoke-test is stronger evidence than any agent-flow run.

## What's passing (record, so the reopen doesn't over-correct)

- **Boundary discipline holding** (DF-003 trending non-finding): the agent stopped and waited at
  review-signoff, feature-closeout, AND lifecycle-end — and even halted on the F-039 working-tree gate
  rather than bulldozing it. Strongly suggests it honored before-implement too (pending the maintainer's
  one-word confirm). The Copilot host honors boundaries here, unlike the earlier Codex auto-run.
- **Forge-neutral closeout reasoning**: "branch-ready, local-only" honest status (no remote); recognized
  module-publish steps are Specrew-specific and don't apply to a downstream app; SDLC rendered generically.

- Honest provider-not-detected hedging ("will not claim branch protection is enforced … unless repo
  evidence proves it"; "where the provider supports it"; "local/manual until a forge/CI capability is
  detected"; "automated review optional and not assumed") — iteration-3 honest-degradation working.
- Capability detection for `provider: gitlab` returns the correct honest report (`mechanism: manual`,
  "no shipped adapter … synthesize a READ-ONLY adapter", `describe_only_default: true`).
- Work-kind discipline: distinct kinds; link-shortener = software-feature; docs as docs not buried in
  impl; CI = devops; the post-merge invariant (a merged PR leaves no open work item; post-merge findings
  open a NEW work item, never reopen the feature).

## Notes

- DF findings are forge-neutrality completeness gaps in 182's OWN deliverable (the prose is neutral; the
  CI **artifact** layer is not) — they belong to 182, hence reopen + Iteration 4, not a new proposal.
- The earlier "no Iteration 4" constraint is lifted by this explicit send-back; Iteration 4 still goes
  through specify/plan/before-implement like any iteration.
