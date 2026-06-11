# Product & Problem Domain Record: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Date**: 2026-06-11
**Depth**: Standard
**Confirmation**: human-confirmed (lens-question scope) — maintainer confirmed the framing as-is.

## Depth reason

Specrew is a known product and the trigger (Feature 177's release/closeout mismatch)
is well-documented, so most product context is `known`. But this is a consequential
change to lifecycle **shape** (new first-class work kinds + a branch-governance
decision area in the DevOps lens), not a tiny utility, so it earns current-workaround,
success-metrics, and alternatives — hence **Standard** rather than Light or Deep.

## Problem reframe (solution → problem)

The request — "implement work kinds + branch governance" — is the *solution*. The
*problem* is that Specrew treats feature delivery, release validation, docs-only
changes, and DevOps/CI changes as **one lifecycle shape**. That produces two failures:
(a) post-merge release/CI/docs findings have nowhere to go except *reopening a merged
feature*, which is unsafe on a protected `main`; and (b) trivial non-feature changes
carry full-feature ceremony. The feature is checked against this problem throughout.

## Grounding (evidence-tagged)

- **Users / stakeholders** — Primary: the Specrew-driven developer (human + Crew)
  deciding a change's work kind + lifecycle `known`. Operator: the lifecycle phases + CI
  consuming the declaration `known`. Buyer/maintainer: Alon, setting the default
  governance posture `known`. Harmed if bad: protected-`main` maintainers blocked/
  mis-routed; anyone misled by over-claimed enforcement; downstream CI maintainers
  inheriting brittle checks `assumed`.
- **Pain / workaround** — One shape for everything; post-merge findings reopen merged
  features; trivial changes over-processed `known`. Workaround: hold a feature open past
  merge (177 anti-pattern) or push small fixes informally `known`. Cost of nothing:
  lifecycle truth corrupted by post-merge edits; protected-`main` repos can't follow the
  model `assumed`.
- **Existing system** — Extension of the design-lens system (DevOps lens) + lifecycle/
  validator/CI surface. Not a new product `known`.
- **Constraints** — `main` already protected (PR-required, applies to admins, no
  force-push/delete) as of 2026-06-11 `known`; multi-host `known`; honest enforcement,
  no over-claim `known`; GitHub-first, capability varies by plan/visibility `known`;
  built as a normal software-feature until it introduces the work kinds `known`;
  174/178 stay follow-ups `known`.
- **Outcomes / metrics** — Lifecycle truth survives merge `known`; DevOps lens captures
  branch governance with honest capability reporting `known`; leading indicator:
  Specrew's own repo carries main protection + a work-kind declaration, and docs-only/
  devops lifecycles are usable end-to-end `assumed`.
- **MVP / non-goals / vision** — MVP: the full proposal across 2 iterations. Non-goals:
  every Git provider in v1; full ruleset enforcement automation; rewriting history;
  releases for docs-only; 174/178. v1 fails even if it works if it over-claims
  enforcement or blocks legitimate/emergency work with no audited bypass.
- **Alternatives / differentiation** — A: status quo (one lifecycle) → caused 177.
  B: CI-only → false confidence. C: branch-protection-only → no lifecycle right-sizing.
  Differentiation: real branch protection + work-kind semantics + honest capability
  reporting `assumed`.
- **Adoption / change impact** — Ships beta-first, dogfooded on Specrew's repo; work
  kinds + DevOps-lens questions join the standard flow; developers declare a work kind,
  mitigated by defaults + lightweight kinds + phased enforcement `assumed`.

## Follow-up research

None. No load-bearing `research-needed` gaps; the GitHub capability matrix is a known,
documented input (proposal source anchors checked 2026-06-11).
