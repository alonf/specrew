# Product & Problem Domain Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-15
**Depth**: Light
**Confirmation**: human-confirmed (lens-question scope) — maintainer confirmed the product scope framing after reviewing the out-of-scope explanations.

## Depth Reason

Specrew is a known product and this feature is a narrow stability/quality bundle
following Feature 174's hook-driven bootstrap release. The work fixes named defects
and small follow-up improvements rather than introducing a new product, workflow, or
market-facing capability. A Light product-domain pass is enough to record who is
served, the operational pain, the MVP, non-goals, and constraints.

## Problem Reframe

The request is not "bundle everything that looks related to hooks or lifecycle."
The problem is that the current 0.37.0-beta1 dogfood path has a small number of
stability defects that can undermine trust in SessionStart bootstrap delivery,
boundary/closeout state, and local green-baseline tests before the stable 0.37.0
promotion. This feature keeps the bundle small enough to ship beta2, validate on a
real host, and promote only after the focused risks are addressed.

## Grounding

- **Users / stakeholders** — Primary users are the Specrew maintainer and dogfood
  users launching hook-capable hosts such as Claude and Codex. Reviewers and future
  downstream users are harmed if bootstrap guidance disappears, lifecycle state lies,
  or closeout evidence is stale.
- **Pain / workaround** — Feature 174 made hook-driven SessionStart bootstrap the
  primary path, but the current beta path still has defects: oversized hook payloads
  can drop the banner, provider failures can be silent, unknown session IDs can
  mis-key state, the delivery-cap test can false-red on ambient state, closeout
  classification can mislead, and two local-test reds remain mechanical hygiene
  issues.
- **Existing system** — This is a stability extension to the existing Specrew
  PowerShell module, hook providers, closeout sync logic, and tests. It is not a new
  product surface.
- **Constraints** — The work follows the software-feature lifecycle with bug-bash
  conduct per item; capacity remains capped at 20 story points; source hook/provider
  changes must be mirrored into the deployed `.specify` extension; dogfood uses the
  dev tree via `SPECREW_MODULE_PATH`; no global module upgrade or PSGallery dependency
  is introduced during the feature.
- **MVP** — Deliver the six named FRs from the intake: Proposal 179, Proposal 180,
  Issue #2446, DirectiveDeliveryCap hermeticity, Issue #1627 sub-parts a/b/c, and
  Issue #1761 reds #2/#3. Amendment 2026-06-16: add Antigravity hook support after
  maintainer-provided upstream evidence showed Antigravity now documents first-class
  hooks while Specrew still excludes Antigravity from hook provisioning. Ship the next
  appropriate 0.37.0-beta<N>, validate on a real host, then promote 0.37.0 stable if
  validation passes.
- **Non-goals** — Proposal 191, Proposal 165 / Issue #2081, Proposal 168, Issue #78,
  Proposal 159 Tier 2, Proposal 123, and Issue #1761 red #1 are deferred or excluded
  because they are research-heavy, host-specific, larger architectural slices, old
  Squad-specific work, CLI ergonomics, or wording/design decisions outside this
  focused stability bundle.

## Follow-up Research

None for the original product scope. Proposal 191 remains spike-first outside this feature.
For Antigravity hook support, implementation must verify the current official hook
contract and map only provable Antigravity hook events to Specrew behavior.
