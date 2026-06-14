# DevOps And Operations Lens

## Lens ID

`devops-operations`

## Purpose

Expose deployment, environment, CI/CD, configuration, secrets, access, rollback,
and operations choices as architecture, not afterthoughts.

## Applicability Signals

- The feature changes installation, packaging, release, hosting, CI, deployment,
  infrastructure, configuration, secrets, environment setup, roles, or runtime
  operations.
- The feature must run on multiple operating systems, clouds, hosts, tenants, or
  environments.
- The change introduces operational risk, rollback risk, or manual validation.

## Design Decision Points

- What is the hosting model: local tool, web server, VM, container,
  orchestrator, serverless function, serverless container, hybrid, or embedded?
- What infrastructure is code-owned, manually configured, or external?
- Which environments must be equivalent, and where may they differ?
- How are secrets, configuration hierarchy, and dynamic configuration handled?
- What CI/CD stages, gates, rollout strategy, and rollback path are required?
- **Which CI lane belongs to THIS project's forge?** (FR-024) Propose the CI lane for the project's own
  forge — a `.gitlab-ci.yml` on GitLab, a GitHub Actions workflow on GitHub, an Azure Pipelines file on
  Azure DevOps, and so on. Never default a non-GitHub project to GitHub Actions.
- What users, roles, service identities, and permissions are needed?

## Workshop Conduct

- **Forge-aware CI lane (FR-024)**: when CI is in scope, propose the lane for the project's *own* forge
  (read `provider` from `.specrew/repository-governance.yml`). If Specrew ships no work-kind CI lane for
  that forge, **say so plainly** — offer the provider-neutral local validator (`Invoke-SpecrewWorkKindValidation`)
  and let the human author the forge-native lane; do NOT silently hand them a GitHub Actions file on a
  non-GitHub project. The work-kind CI lane shipped today targets GitHub Actions; other forges run the
  validator manually or via a hand-authored lane until an adapter lane ships.
- **Diagram for this lens**: deployment topology (environments, nodes, pipelines) — render it as **console ASCII inline** so the human sees it in the conversation (a fenced mermaid block is source text, not a picture, on a terminal host); any mermaid/svg/html file is an *additional* artifact whose clickable `file:///` link you surface in the same message.
- **Facilitate, do not dictate**: raise the Design Decision Points above as a discussion, sketch the deployment topology and agree the promotion path, capture the human's decisions and explicit agreement, iterate until they say "move on", and record the agreement (never leave it only in the chat scrollback).
- **Re-invoke the `specrew-design-workshop` skill** before moving to the next lens.

## Question Bank

- What install or deployment command should a normal user run?
- What dependencies are passive and automated vs explicit prerequisites?
- What environments must the plan validate: dev, CI, staging, beta, stable,
  customer tenant, macOS, Linux, Windows, WSL, VM?
- What secrets or credentials are needed, and where are they stored?
- What should be represented in IaC, and what stays manual?
- How do we roll forward, roll back, or disable the feature?
- Which CI lane is authoritative, and which checks are only syntax/proxy checks?
- Who needs access, and what is the least-privilege role?
- How will operators know deployment or runtime failed?

## Alternative Dimensions

- **Simplest**: document manual steps and run local validation.
- **Reasonable**: scripted setup, environment parity checks, CI gate, rollback
  note, and secret/config conventions.
- **By the book**: IaC, idempotent deployment, staged rollout, policy gates,
  least-privilege identities, automated rollback, SLOs, runbook, and audit.

## Plan Obligations

- Name the user-facing install/deploy path and hidden dependencies.
- Record CI/CD lanes, environment matrix, secret handling, and rollback.
- Separate real runtime validation from proxy checks.
- State whether a release, beta, or publish action is authorized.

## Validation Signals

- Install/deploy evidence runs in the target environment.
- CI proves the operating systems or hosts claimed by the plan.
- Secrets are not embedded in scripts, logs, or generated artifacts.

## Repository Governance & Work Kinds (Feature 182)

This lens also captures **repository governance** — the work-kind taxonomy and the branch-protection
posture — as a design-time decision. The taxonomy lives in the data-driven catalog
`extensions/specrew-speckit/knowledge/work-kinds.yml` (4 kinds: `software-feature`, `bug-bash`,
`docs-only`, `devops`); the captured governance persists to the **project-level**
`.specrew/repository-governance.yml` (decided once, inherited per feature, deltas re-asked).

### The invariant (always state it)

```text
main (the release-truth branch) is protected. feature-closeout happens BEFORE merge.
A merged PR must not leave its work item open. Post-merge release/CI/docs findings create a
NEW PR-backed work item (docs-only / devops / bug-bash) + a separate release-validation record —
never a reopen of the merged feature.
```

### Brownfield first — detect, then adapt or change (FR-021)

Before proposing a posture, **detect** the repo's existing CI/CD + branch protection + review setup
and present the detected posture. Then offer **ADAPT** (slot the work-kind check into the existing CI
lane; record the existing posture) or **CHANGE** (move to the recommended posture). **Never silently
overwrite** an existing setup.

### Governance questions (present the defaults; ask adopt / modify / skip)

1. Block direct commits to the protected branch where the forge supports it? → default **yes**.
2. **Branch model** — what is the branching style and what are the branch **names**? Capture
   `branch_model`: `style` (trunk | integration-branch | gitflow | custom), the user-named
   `release_truth_branch` (`main`/`master`/`trunk`/`production`/…; `main` is only a default *name*,
   never an assumption), the protected `branches[]`, and the `promotion_path`. The promotion **to**
   release-truth is the release-validation event.
3. Apply protection to admins + automation? → default **apply to admins**; explicit `bypass_actors`
   for automation only.
4. Required status checks before merge? → default **Specrew governance/lint + project tests**.
5. Force-pushes / branch deletions? → default **no**.
6. **Review gate** — capture `review_gate`: human `required_approvals` + `require_comment_resolution`
   (always available), and **opt-in** `automated_review` (off by default; on GitHub the adapter MAY
   *suggest* Copilot the way Specrew uses it — the user decides in the workshop). `merge_requires`
   names which signals gate the merge.
7. Release tags human-created, automation-created, or both? → captured (default both).
8. A release/post-merge validation record separate from feature-closeout? → default **yes**.
9. Single-repo or multi-repo? → default **single-repo**; capture the `multi_repo` block only when
   multi-repo.

### Provider neutrality + capability honesty (FR-012/FR-014/FR-016)

Capture **provider / plan / visibility BEFORE promising any enforcement mechanism**. The methodology
and the validator are forge-neutral; the only forge-specific behavior sits behind the `ProviderAdapter`
(`extensions/specrew-speckit/scripts/provider-adapter.ps1`): v1 ships a **GitHub reference adapter** + a
**generic/unknown fallback** (`ci-only`/`manual` via git-diff). For another forge (GitLab / Azure
DevOps / Bitbucket / Gitea), **synthesize an adapter on the fly** when the developer names it, captured
at the downstream project under `.specrew/providers/<forge>.ps1` with provenance. **Synthesized adapters
are read-only by default** — `detect_capability` / `describe_protection` only; `apply_protection`
(which mutates repo security) stays **human-approved** and is refused for an unverified adapter. Report
the **achievable** mechanism honestly; degrade to `ci-only`/`manual` when protection is unavailable.

### Honesty (FR-010/SC-008 — non-negotiable)

Label every enforcement claim with its true posture. The CI work-kind validator defaults to
**advisory** (warn, never block) and graduates to blocking only when proven. Do **not** over-claim
runtime enforcement; record anything partial as **phased/deferred**.

## Source Notes

- Book Chapter 6.
- Course Modules 1, 2, and 5.
- Proposal 182 (Work Kind and Branch Governance Model); GitHub branch-protection + rulesets docs
  (checked 2026-06-11).
