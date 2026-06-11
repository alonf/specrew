---
proposal: 182
title: Work Kind and Branch Governance Model
status: candidate
phase: phase-2
estimated-sp: 8-14
priority-tier: 1
discussion: surfaced 2026-06-11 after Feature 177 release-closeout confusion. The feature work had merged, beta/stable publication happened, but feature-closeout artifacts lagged behind release validation. The root issue is that Specrew was treating feature lifecycle, release validation, documentation-only changes, and DevOps/CI-CD changes as one lifecycle shape. This proposal separates work kinds and makes PR-backed main protection a DevOps-lens decision.
---

# Work Kind and Branch Governance Model

## Why

Feature 177 exposed a lifecycle shape problem: a software feature can be implementation-complete and merged, but
release/publish validation may still produce lessons after the PR is accepted. Specrew tried to keep the feature
open long enough to capture CI/CD and beta-install learning. That is unsafe for downstream projects because many
repositories do not allow direct pushes to `main`; any post-merge correction must itself be a PR.

The better invariant is:

```text
A merged PR must not leave its work item open on main.
Post-merge findings create a new PR-backed work item.
```

Specrew already has a full software-feature lifecycle and a bug-bash pattern. It now needs first-class
lightweight work kinds for:

- documentation-only changes;
- DevOps / CI-CD / repository-governance changes;
- release/post-merge validation records that do not reopen the merged feature.

The DevOps & Operations workshop lens is the right place to ask how strict repository governance should be. It
already discusses hosting, CI/CD, rollout, rollback, and operational roles; branch protection and multi-repo
delivery are part of the same operational posture.

## What

Add a formal **work kind** model and a **repository governance** decision area in the DevOps & Operations lens.

### Work kinds

Specrew should distinguish at least these PR-backed work kinds:

| Kind | Use for | Lifecycle weight | Required evidence |
| --- | --- | --- | --- |
| `software-feature` | Product/runtime behavior and ordinary feature delivery | full Specrew lifecycle | spec, workshop, plan, tasks, implementation, review, retro, feature-closeout |
| `bug-bash` | Defect fixes or regression bundles | focused bug lifecycle | bug list, root cause, fix evidence, regression tests, closeout |
| `docs-only` | README, docs, proposals, methodology wording, examples, release notes with no runtime change | lightweight docs lifecycle | intent, audience, changed docs, markdown/link checks, review, docs-closeout |
| `devops` | CI/CD, GitHub settings, branch protection, release workflows, package/publish infrastructure, repository management | operational lifecycle | risk/rollback plan, dry-run evidence, CI evidence, operational retro, devops-closeout |

### Main branch policy

Default recommendation:

```text
main is protected release truth.
No direct human or agent pushes to main.
Every change enters through a PR-backed work item.
The work item must close before merge.
Post-merge release or CI/CD findings create a new docs-only, devops, or bug-bash PR.
```

The DevOps lens should ask:

1. Should Specrew block direct commits to `main` where the host supports it? Default: yes.
2. Which branch should be protected? Default: the repository default branch.
3. Should protection apply to admins and automation bypass roles? Default: apply to admins; require explicit bypass list for automation.
4. Which status checks are required before merge? Default: Specrew governance/lint + project tests.
5. Are force-pushes and branch deletions allowed? Default: no.
6. Who can approve and merge?
7. Are release tags human-created, automation-created, or both?
8. Is there a release/post-merge validation record separate from feature-closeout?

GitHub support depends on visibility and plan. GitHub protected branches are available for public repositories on
Free/Free-for-organizations and for public/private repositories on Pro, Team, Enterprise Cloud, and Enterprise
Server. GitHub rulesets are available for public repositories on Free/Free-for-organizations and for
public/private repositories on Pro, Team, and Enterprise Cloud. Push rulesets for internal/private repositories
are documented for GitHub Team. The lens should ask or detect provider, plan, and visibility before promising a
specific enforcement mechanism.

### CI policy enforcement

Branch protection prevents direct `main` pushes. CI should enforce work-kind semantics on PRs:

- exactly one work kind is declared;
- changed files match the declared work kind;
- required artifacts exist for that work kind;
- software-feature and bug-bash PRs cannot merge with open lifecycle boundaries;
- docs-only PRs cannot touch runtime source or workflows unless explicitly reclassified;
- devops PRs include risk, rollback, and dry-run evidence when they affect CI/CD or release infrastructure;
- release/stable promotion cannot silently resolve a missing feature closeout.

### Feature-closeout vs release validation

Feature closeout belongs in the feature PR before merge. Release validation belongs after merge and must not
reopen the merged feature.

```text
feature branch:
  iterations -> review -> retro -> iteration-closeout -> feature-closeout -> PR

main after merge:
  release/publish/beta/stable validation -> release validation record

if something changes:
  docs-only PR, devops PR, or bug-bash/software-feature PR
```

### Multi-repo mode

The DevOps lens should also ask whether the Specrew lifecycle is single-repo or multi-repo.

Questions:

1. Which repository owns the product/feature spec?
2. Which repositories receive implementation PRs?
3. Does each repository run its own Specrew lifecycle, or is there one orchestration repository?
4. Are PRs merged independently or as a coordinated release train?
5. What is the cross-repo acceptance gate?
6. How are versions, tags, releases, and rollback coordinated?
7. Where are shared workshop decisions and product-level rules stored?

Possible capture shape:

```yaml
work_kind: software-feature | bug-bash | docs-only | devops
repository_governance:
  provider: github
  default_branch: main
  protect_default_branch: true
  require_pull_request: true
  require_status_checks: true
  required_checks: []
  apply_to_admins: true
  allow_force_pushes: false
  allow_deletions: false
  bypass_actors: []
  enforcement_mode: branch-protection | rulesets | ci-only | manual
multi_repo:
  mode: single-repo | multi-repo
  orchestration_repo: null
  participant_repos: []
  merge_coordination: independent | release-train | manual
  release_coordination: independent | release-train | manual
```

## Functional requirements

- **FR-001**: Specrew MUST define a work-kind taxonomy covering `software-feature`, `bug-bash`, `docs-only`, and
  `devops`.
- **FR-002**: The DevOps & Operations lens MUST present the default PR-backed branch-governance model and ask the
  user whether to adopt, modify, or skip it.
- **FR-003**: The DevOps lens MUST ask whether direct commits to the default branch should be blocked where the
  host supports it, and MUST capture provider/plan/visibility constraints before promising enforcement.
- **FR-004**: Specrew MUST distinguish feature-closeout from release/post-merge validation; post-merge findings
  MUST create a new work item instead of reopening the merged feature.
- **FR-005**: Specrew MUST support a lightweight docs-only lifecycle that can be completed through PR without a
  release.
- **FR-006**: Specrew MUST support a DevOps work kind for CI/CD, GitHub/repository settings, release workflows,
  branch protection, and publishing infrastructure.
- **FR-007**: Specrew CI SHOULD validate work-kind declarations, changed-file scope, and required closeout
  artifacts before merge.
- **FR-008**: The DevOps lens MUST ask whether the project is single-repo or multi-repo and capture the
  orchestration and release-coordination model.

## Out of scope

- Implementing every Git provider in v1. GitHub can be the first provider, with a provider capability model for
  later.
- Enforcing a full ruleset policy in this proposal's documentation-only capture. Runtime enforcement is a future
  feature/devops slice.
- Rewriting historical feature artifacts. Historical corrections should be small PRs, not hidden retroactive
  edits.
- Creating a release for docs-only changes.

## Effort

- **Iteration 1 (~4-6 SP)**: Work-kind taxonomy, docs-only/devops lifecycle templates, branch-policy capture
  schema, DevOps-lens questions, documentation.
- **Iteration 2 (~4-8 SP)**: GitHub capability detection, branch-protection/ruleset helper, CI work-kind policy
  validator, tests, dogfood on Specrew itself.
- **Total**: ~8-14 SP.

## Phase placement

Phase 2. This is developer-experience and lifecycle-discipline work: it keeps Specrew usable in real protected
repositories and prevents release/post-merge learning from corrupting feature lifecycle truth.

## Open questions

1. Should the first implementation use GitHub branch protection, GitHub rulesets, or branch protection first with
   rulesets as a later enhancement?
2. How should PRs declare work kind: branch prefix, PR label, frontmatter file, checked-in
   `.specrew/work-kind.yml`, or a combination?
3. Should docs-only PRs allow `CHANGELOG.md` and proposal-index edits by default?
4. How strict should changed-file classification be for generated mirrors and repository-global ledgers?
5. In multi-repo mode, does the orchestration repository own all lifecycle truth, or does each implementation
   repo own its own closeout with a shared release train record?

## Risks

- **Over-blocking legitimate work**: strict branch and work-kind rules can slow emergency fixes. Mitigation:
  define an emergency/bypass path that still leaves an audit artifact.
- **False confidence from CI-only enforcement**: CI cannot prevent a direct push after it happens. Branch
  protection/rulesets must be the actual main-protection layer.
- **Provider capability drift**: GitHub plan/ruleset behavior can change. Mitigation: detect current
  capabilities and surface "manual/ci-only" when enforcement is unavailable.
- **Multi-repo complexity**: cross-repo lifecycle can become process-heavy. Mitigation: make single-repo the
  default and require explicit multi-repo ownership decisions.

## Cross-references

- Related proposals: [055](055-always-in-flow-bug-fix-lifecycle.md), [060](060-prerelease-channel-staging.md),
  [066](066-gate-respecting-default.md), [073](073-review-evidence-integrity.md),
  [089](089-pr-review-integration-address-pr-review-gate.md), [090](090-closeout-lifecycle-sync-commands.md),
  [156](156-design-analysis-lens-knowledge-catalog.md), [174](174-boundary-variance-disclosure.md),
  [178](178-verification-strategy-lens.md).
- Immediate empirical trigger: Feature 177 release/closeout mismatch after `v0.35.0` promotion.
- GitHub source anchors checked 2026-06-11:
  - `https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches`
  - `https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets`

## Status history

- 2026-06-11: captured as candidate after the Feature 177 publish/closeout discussion. Interim operational
  mitigation applied to the Specrew repository: `main` now requires pull requests, applies to admins, and blocks
  force-pushes/deletions. This proposal defines the durable methodology and automation follow-up.
