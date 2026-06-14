# Work Kinds & Branch Governance

Specrew distinguishes first-class **work kinds** so that feature delivery, release validation,
documentation changes, and DevOps/CI changes each follow a right-sized lifecycle — instead of one
heavy shape for everything. The taxonomy is data-driven
(`extensions/specrew-speckit/knowledge/work-kinds.yml`); this doc is its human-readable companion.

## The taxonomy

| Kind | Use for | Lifecycle weight | Required evidence |
| --- | --- | --- | --- |
| `software-feature` | Product/runtime behavior and ordinary feature delivery | full | spec · design-workshop · plan · tasks · implementation · review · retro · feature-closeout |
| `bug-bash` | Defect fixes or regression bundles | focused | bug-list · root-cause · fix-evidence · regression-tests · closeout |
| `docs-only` | README, docs, proposals, methodology, examples, release notes — **no runtime change** | lightweight | intent · audience · changed-docs · markdown/link checks · review · docs-closeout |
| `devops` | CI/CD, repo settings, branch protection, release workflows, publishing infra | operational | risk/rollback plan · dry-run evidence · CI evidence · operational-retro · devops-closeout |

A work item declares its kind in a checked-in, forge-neutral **`.specrew/work-kind.yml`** (an optional
branch-prefix convention — `docs/`, `devops/`, `fix/`, `feature/` — supplies a default the file
confirms/overrides). `docs-only` produces **no release**.

## The invariant — lifecycle truth survives merge

```text
feature branch:
  iterations -> review -> retro -> iteration-closeout -> feature-closeout -> PR -> merge

release-truth branch (main / master / trunk / …) AFTER merge:
  release / publish / beta / stable validation -> a release-validation record

if a post-merge finding appears:
  open a NEW docs-only / devops / bug-bash work item (a new PR)
  -- NEVER reopen the merged feature; NEVER retroactively rewrite its closeout artifacts
```

**feature-closeout happens before the merge.** The promotion **to** the release-truth branch (in an
integration-branch or GitFlow model, the `dev → main` / `release/* → master` promotion) is the natural
**release-validation** event — captured as a separate record, not a reopened feature.

## Branch governance is configurable

The DevOps & Operations lens captures a project-level `.specrew/repository-governance.yml`:

- a **`branch_model`** — the branching style (`trunk` | `integration-branch` | `gitflow` | `custom`),
  the **user-named** `release_truth_branch` (`main` is only a default name), the protected branches,
  and the promotion path;
- a **`review_gate`** — human approvals + comment-resolution (always available) and **opt-in**
  automated review (on GitHub the adapter may *suggest* Copilot; the user decides);
- the admin/automation bypass policy, force-push/deletion policy, required checks, and the
  single-repo vs multi-repo model.

## Provider neutrality + honest capability

The methodology and the CI work-kind validator are **forge-neutral**. Only a thin `ProviderAdapter`
is forge-specific: v1 ships a **GitHub reference adapter** + a **generic/unknown fallback**
(`ci-only`/`manual`). Other forges (GitLab, Azure DevOps, Bitbucket, Gitea) get an adapter
**synthesized on the fly** when you name your forge — **read-only by default** until a human verifies
it (`apply_protection` always stays human-approved).

> **GitHub capability caveat.** Protected branches and rulesets depend on **provider, plan, and
> visibility**. Specrew detects the **achievable** mechanism and reports `ci-only`/`manual` when
> protection is unavailable — it never promises enforcement a repo cannot apply.

## Honesty (phased enforcement)

The CI work-kind validator defaults to **advisory** (it warns and names the exact gap; it does not
block) and graduates to blocking only when proven. Partial enforcement is labeled **phased/deferred** —
Specrew does not over-claim runtime enforcement.

## A worked post-merge example

1. Feature `182` is closed out and its PR is merged to `main`.
2. Beta-install validation later surfaces a bug. The developer asks Specrew how to record it.
3. Specrew directs them to open a **new `bug-bash`** work item (a new PR) + a release-validation record
   — it does **not** reopen feature `182`, and `182`'s closeout artifacts are left intact.
