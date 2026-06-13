# DevOps & Operations Workshop Record: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Depth**: full (central lens)
**Confirmation**: human-confirmed (lens-question)

## Enforcement topology (defense in depth)

```text
ENFORCEMENT LAYERS (defense in depth)            WHO APPLIES IT / WHERE IT RUNS
┌────────────────────────────────────────────┐
│ L3  Methodology (always on, forge-neutral)  │  Specrew lens + lifecycle templates
│      work kinds · lifecycle surfaces ·       │  (every host, every forge, even plain git)
│      closeout-vs-release-validation invariant│
├────────────────────────────────────────────┤
│ L2  CI semantic check (advisory → blocking)  │  provider-NEUTRAL validator script, run in the
│      1 kind? changed-files match? closeout?  │  project's CI (GitHub Actions = v1 wiring;
│                                              │  other CIs documented — just invoke the script)
├────────────────────────────────────────────┤
│ L1  Branch protection (REAL push-block)      │  FORGE-applied via ProviderAdapter
│      per-branch: PR-required · no force-push ·│  (github reference adapter; generic/unknown
│      required checks · review gate · bypass  │  → ci-only/manual, honest)
└────────────────────────────────────────────┘
              ▲ decisions captured once at design time
              │
┌────────────────────────────────────────────┐
│ DevOps lens → .specrew/repository-           │  PROJECT-LEVEL (decided once, inherited per
│ governance.yml  (branch_model + 8 answers +  │  feature; re-opened only when posture changes)
│ review_gate + multi_repo)                    │
└────────────────────────────────────────────┘
```

## Branch models (configurable; branch NAMES are the user's)

```text
Trunk:               feature/* ──PR(feature-closeout)──▶ [release-truth]
                     release-validation = on release-truth, after merge
Integration branch:  feature/* ──PR(feature-closeout)──▶ [dev] ──promotion PR──▶ [release-truth]
                     release-validation = the dev→release-truth PROMOTION (separate work item)
GitFlow:             feature/* ──▶ [develop] ──release/*──▶ [release-truth] ; hotfix/* ──▶ [release-truth]
                     release-validation = the release/* + promotion
```

feature-closeout happens at the merge into the feature's TARGET branch (whatever it is
named); the promotion TO release-truth is the natural release-validation event — the
DP-A3 separation, free for integration/GitFlow shops.

## Capture schema (project-level `.specrew/repository-governance.yml`)

```yaml
repository_governance:
  provider: github                       # or a synthesized adapter
  branch_model:
    style: trunk | integration-branch | gitflow | custom
    release_truth_branch: main           # USER NAMES IT (master/trunk/production/release/…)
    branches:
      - name: main
        role: release-truth
        protected: true
        require_pull_request: true
        required_checks: [specrew-governance, tests]
        merges_from: [dev]
        allow_force_pushes: false
        allow_deletions: false
      - name: dev                        # OPTIONAL (omit for trunk)
        role: integration
        protected: true
        require_pull_request: true
        required_checks: [specrew-governance]
        merges_from: ["feature/*"]
    promotion_path: "feature/* -> dev -> main"
  review_gate:
    human_review:
      required_approvals: 1              # project-named reviewers; 0 = no human gate
      require_comment_resolution: true    # unresolved PR/MR comments block merge
    automated_review:
      enabled: false                     # OPT-IN — off by default; user decides in the workshop
      provider_suggestion: copilot        # GitHub adapter MAY suggest Copilot (as Specrew uses it);
                                          # other forges → their own bot or none, per capability
    merge_requires: [human_review]
  apply_to_admins: true
  bypass_actors: []
  enforcement_mode: branch-protection | rulesets | ci-only | manual
multi_repo:
  mode: single-repo | multi-repo         # default single-repo
  orchestration_repo: null
  participant_repos: []
  merge_coordination: independent | release-train | manual
  release_coordination: independent | release-train | manual
```

## Decisions

- **DP-D1 — Governance question set + defaults (the feature's content)**: the DevOps lens
  asks (1) block direct commits to the protected branch where the forge supports it →
  default yes; (2)→(generalized) **branch_model**: branching style + user-named branches +
  which are protected + promotion path → default `trunk` with `main` as the default *name*
  only; (3) apply protection to admins + automation → apply to admins, explicit automation
  bypass list; (4) required status checks → Specrew governance/lint + project tests;
  (5) force-push/deletion → no; (6)→(generalized) **review_gate**: human approvals +
  comment-resolution (always-available) and OPT-IN automated review (Copilot suggested on
  GitHub only, user decides in the workshop); (7) release tags human/automation/both →
  captured (default both); (8) release/post-merge validation record separate from
  feature-closeout → default yes (DP-A3).
- **DP-D2 — Capture is PROJECT-LEVEL**: answers persist to `.specrew/repository-governance.yml`
  (decided once, inherited per feature, re-opened only on posture change) — same
  product-level-once pattern as Feature 177's code-rules. The lens reads it and re-asks only
  deltas.
- **DP-D3 — Multi-repo**: default single-repo; the `multi_repo` block is captured only when
  the human chooses multi-repo.
- **DP-D4 — CI lane**: a new ADVISORY check on PRs, run as a provider-neutral script invoked
  by a GitHub Actions workflow (v1 wiring); other CIs documented. Real validation = the
  script's verdict on a real PR fixture, not "workflow file exists". Defaults advisory (DP-A5).
- **DP-D5 — The feature's own ship/release** (F-176/177 lesson, non-negotiable): new
  deployable files → FileList + `extension.yml` version bump + `.specify` mirror parity +
  markdownlint + CHANGELOG + beta-before-stable; the feature is a `software-feature`
  dogfooded on Specrew's protected `main`; rollback = module version rollback.
- **CROSS-CUTTING PILLAR — forge-neutralization (maintainer-directed)**: go over ALL
  downstream-governing surfaces (lifecycle prompt template, deployed skills, .specify
  extension scripts, agent charters, design-lens content, deployed CI templates) and remove
  Specrew's own GitHub dev habits (gh pr create / merge-commit closeout steps, the "check
  Copilot PR review" mandate → opt-in suggestion, GitHub-Actions-only wiring, branch=main
  assumptions); route forge-specific behavior through the ProviderAdapter + capability
  detection. Do NOT change Specrew's OWN GitHub usage for its own development. Magnitude:
  raw grep ~216 hits but heavily inflated by the `copilot` host name, generic "pull request"
  prose, and example agent-history seed files; genuine coupling concentrates in ~10–15 files
  (closeout SDLC steps, validate-governance PR-review checks, deployed GH-Actions templates,
  a few skills/charters). Precise inventory IS the Iteration-1 audit deliverable.
- **Sizing**: grown from ~8–14 SP to ~16–24 SP across **3 iterations** (Iter 1 methodology +
  adapter contract + reference adapter + audit; Iter 2 validator + capability detection +
  synthesis; Iter 3 decouple migration). Firmed up at capacity; may split the decouple into
  a sibling if too big.
