# DevOps Lifecycle (template)

**Work kind**: `devops` · **Lifecycle weight**: operational

Use this for CI/CD, repository settings, branch protection, release workflows, package/publish
infrastructure, and repository management. Operational changes carry **risk and rollback**, so the
evidence is heavier than docs-only but lighter than a full feature.

Declare it: `.specrew/work-kind.yml` → `work_kind: devops` (branch prefix `devops/` gives the default).

## Required evidence (the operational set)

- [ ] **Risk / rollback plan** — what could break, the blast radius, and exactly how to roll back
      (revert commit, restore the previous workflow, disable the new check, etc.).
- [ ] **Dry-run evidence** — the change exercised safely (a workflow `workflow_dispatch` dry run, a
      `--dry-run`/`-WhatIf`, a fork/sandbox run) before it touches the real pipeline.
- [ ] **CI evidence** — the affected lane(s) green on a real run; the new/changed check observed firing.
- [ ] **Operational retro** — what was learned operationally; any follow-up devops items filed.
- [ ] **DevOps-closeout** — a closeout note recording the applied change + the rollback handle.

## Branch-protection / `apply_protection` changes

- Capture the change in `.specrew/repository-governance.yml` first (describe-only).
- `apply_protection` mutates repo security and is **human-approved** — never auto-applied, never from
  an unverified synthesized adapter; it uses **your own** forge token (Specrew holds no secret).
- If the forge cannot enforce protection (provider/plan/visibility), record `ci-only`/`manual` honestly.

## Emergency / bypass

A bypass is an authorized escape hatch (e.g. a production fire). It MUST leave a **durable audit
artifact** (who / why / when / what), committed or logged — never a silent skip.

## Flow

```text
risk + rollback plan -> dry-run -> CI evidence -> PR -> review -> operational-retro -> devops-closeout -> merge
```
