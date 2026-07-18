# Quickstart: Beta2 Finish-Line Acceptance

**Feature**: 198-beta2-hardening
**Status**: Iteration 008 plan-time acceptance guide
**Planning baseline**: `ec2287c0b950ceb78522f3b5aae8dd94d4710a88`

This guide describes the planned acceptance flow. It does not authorize task execution, provider spend, or
release publication.

## 1. Configure Downstream Verification

The production supplier must select commands in this order:

1. explicit project configuration;
2. reliable named detection from project-owned CI/build/package metadata;
3. an explicitly selected quality profile;
4. provider-specific configuration only when that provider is active;
5. otherwise, actionable `verification-not-configured`.

The selected plan is materialized at `.specrew/verification-plan.json` and validated by the existing
`verification-plan.schema.json`. Commands are executable-plus-argument arrays, not shell strings. Do not infer a
test framework from extensions and do not add an implicit Pester/Specrew plan.

Expected setup behavior:

- a valid explicit plan remains authoritative;
- an invalid explicit plan fails rather than falling through;
- generated content refreshes only while its recorded hash still matches;
- a user-modified plan is preserved with a warning;
- no trustworthy source yields an actionable setup instruction.

## 2. Run the Production Review Path

For a configured downstream project, the campaign must:

1. freeze an external clean Git target and compute its reviewed-state digest;
2. load and validate the selected plan from that frozen target;
3. run the existing T018 executor in declared order and record every attempted command;
4. join evidence by exact reviewed digest and `command_id`;
5. inject bounded matching evidence into the reviewer context;
6. preserve command failures/timeouts/invalid required results as blocking evidence;
7. invoke a provider only after plan selection and verification preflight succeed.

For an unconfigured or invalid project, the flow must stop before provider invocation and name the setup action.
Review never writes the origin worktree.

## 3. Prove Consumer Distribution

Use scratch fixtures for all of these shapes:

- GitHub-provider greenfield init: deployed workflows reference existing paths, use generic triggers, ignore local
  host config, and announce the bootstrap commit.
- Beta1-shaped update: unmodified retired templates are removed, a modified template is retained with warning,
  and refocus scopes synchronize.
- Local-only repository: closeout omits registry and beta-before-stable steps and names why they are not
  applicable.
- Publish-target repository: closeout renders the full release chain.
- Python/non-Pester, non-GitHub, and no-publish projects: prompts and deployed templates contain no inapplicable
  technology, provider, or delivery mandate.

## 4. Verify Before Release

The pre-release boundary requires:

- focused supplier/runner/injection fixtures, including both fail directions;
- the full deterministic test registry;
- scoped governance validation;
- the cross-platform Windows/Linux/macOS workflow;
- one independently authorized exact-digest review with no hidden retry;
- seven-surface version agreement and release-credential documentation that matches the tag workflow.

Repeated independent review does not continue merely because it is active. Stop and replan after three
consecutive recurrences of the same finding class or three consecutive rounds without a lower validated finding
count.

## 5. Publish and Dogfood

Publishing `v0.40.0-beta2` requires a fresh explicit human release authorization after all pre-release gates pass.
After publication, install the published beta into a fresh consumer and record maintainer PASS/FAIL evidence for
the four beta1 friction classes named by SC-014. This evidence informs a later stable-promotion decision; Iteration
008 does not publish a stable release.

## Explicitly Outside This Guide

- Generic non-code gate/artifact review adapters.
- Proposal 209.
- Automatic campaign retention/pruning.
- The optional stale-binding rebind and stop/capture repairs unless a later verdict selects them.
