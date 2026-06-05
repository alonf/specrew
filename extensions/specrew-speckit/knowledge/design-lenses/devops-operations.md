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
- What users, roles, service identities, and permissions are needed?

## Workshop Conduct

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

## Source Notes

- Book Chapter 6.
- Course Modules 1, 2, and 5.
