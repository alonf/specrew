# Security And Compliance Lens

## Lens ID

`security-compliance`

## Purpose

Surface identity, authorization, data protection, privacy, audit, and regulatory
constraints early enough to shape alternatives rather than patching them on
after implementation.

## Applicability Signals

- The feature handles users, roles, permissions, credentials, tokens, secrets,
  PII, customer data, financial data, healthcare data, audit trails, public
  input, plugins, shell execution, or dependency installation.
- The feature affects trust boundaries or executes code from external sources.
- The domain has regulation, policy, retention, residency, accessibility, or
  auditability requirements.

## Design Decision Points

- Who authenticates, and where is identity established?
- What authorization model applies: roles, claims, scopes, ownership,
  tenant-boundary, policy, or local trust?
- What data is sensitive, and how is it protected in transit, at rest, logs,
  telemetry, backups, and exports?
- What actions need audit records?
- What threat surfaces are introduced by scripts, plugins, APIs, file writes,
  shell commands, generated code, or third-party dependencies?

## Workshop Conduct

- **Diagram for this lens**: trust boundaries + attack surface — render it as **console ASCII inline** so the human sees it in the conversation (a fenced mermaid block is source text, not a picture, on a terminal host); any mermaid/svg/html file is an *additional* artifact whose clickable `file:///` link you surface in the same message.
- **Facilitate, do not dictate**: raise the Design Decision Points above as a discussion, walk the trust boundaries and attack surface and agree the controls at each boundary, capture the human's decisions and explicit agreement, iterate until they say "move on", and record the agreement (never leave it only in the chat scrollback).
- **Re-invoke the `specrew-design-workshop` skill** before moving to the next lens.

## Question Bank

- Who is allowed to do this, and who must be prevented?
- What is the least-privilege role or permission set?
- Does the feature read, write, display, log, or transmit sensitive data?
- What secrets exist, where are they stored, and how are they rotated?
- What audit trail is required for user, operator, or system actions?
- What input must be validated or rejected?
- Does the feature need tenant isolation, data residency, retention, deletion,
  or consent handling?
- What is the failure mode if auth, policy, or secret retrieval fails?

## Alternative Dimensions

- **Simplest**: rely on existing trusted boundary and document no new sensitive
  surface.
- **Reasonable**: explicit authz checks, input validation, secret handling,
  audit notes, and security tests for the changed surface.
- **By the book**: threat model, least-privilege roles, secure-by-default
  configuration, audit schema, privacy controls, compliance mapping, and
  penetration-oriented review.

## Plan Obligations

- Name trust boundaries, identities, roles, data classification, and secret
  handling.
- Record threat surfaces and mitigations.
- Add security review or tests when sensitive surfaces change.

## Validation Signals

- Tests or review evidence exercise denial paths, not only success paths.
- Logs and artifacts are checked for sensitive data leakage.
- Shell or install surfaces prove confinement and failure-safe behavior.

## Source Notes

- Book Chapters 2 and 6.
- Course Modules 2 and 5.
