# Feature Specification: Work Kind and Branch Governance Model

**Feature Branch**: `182-work-kind-branch-governance`  
**Created**: 2026-06-11  
**Status**: Draft  
**Input**: Proposal 182 — Work Kind and Branch Governance Model. Separate Specrew's
single feature-lifecycle shape into first-class **work kinds** (software-feature,
bug-bash, docs-only, devops), make PR-backed main protection a DevOps-lens decision,
and stop post-merge release/CI/CD/docs findings from reopening a merged feature.

## Context & Motivation *(informative)*

Feature 177 exposed a lifecycle-shape problem: a software feature can be
implementation-complete and merged, yet release/publish validation keeps producing
lessons *after* the PR is accepted. Specrew tried to hold the feature open to capture
that learning. That is unsafe for real repositories where `main` is protected and any
post-merge correction must itself be a PR. The durable invariant is:

```text
A merged PR must not leave its work item open on main.
Post-merge findings create a new PR-backed work item.
```

Specrew already has a full software-feature lifecycle and a bug-bash pattern. It now
needs first-class lightweight work kinds for documentation-only changes, DevOps /
CI-CD / repository-governance changes, and release/post-merge validation records that
do not reopen the merged feature. The DevOps & Operations design lens is the right
home for "how strict should repository governance be," because it already covers
hosting, CI/CD, rollout, rollback, and operational roles.

This feature is itself delivered as a normal `software-feature` (per the proposal's
own rule) until it introduces the first-class work kinds it defines.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lifecycle truth survives merge (Priority: P1)

A developer finishes a feature, closes it out, and merges the PR. Days later, release
validation (beta install, CI, docs) surfaces a fix. Instead of reopening the merged
feature on a protected `main`, Specrew directs the developer to open a *new*
PR-backed work item of the appropriate kind (docs-only, devops, or bug-bash). The
merged feature's closeout truth is never retroactively edited.

**Why this priority**: This is the core invariant the proposal exists to protect. It
prevents release/post-merge learning from corrupting feature-lifecycle truth and keeps
Specrew usable in protected-branch repositories.

**Independent Test**: Walk a worked example end-to-end (feature merged → post-merge
finding → new work item) using only the shipped methodology surfaces; verify the
guidance never instructs reopening the merged feature and that a release-validation
record is captured separately from feature-closeout.

**Acceptance Scenarios**:

1. **Given** a merged feature PR and a post-merge beta-install failure, **When** the
   developer asks Specrew how to record it, **Then** Specrew directs them to open a new
   bug-bash or devops work item and does NOT reopen the merged feature.
2. **Given** a merged feature, **When** release validation produces lessons, **Then**
   those lessons are captured in a release/post-merge validation record that is
   explicitly separate from the feature's `feature-closeout` artifacts.

---

### User Story 2 - DevOps lens governs branch protection (Priority: P1)

When a developer works the DevOps & Operations design lens for a feature, the lens
presents Specrew's default PR-backed main-protection model and asks the repository-
governance decision questions (protected default branch, PR-required workflow,
required checks, admin/automation bypass, force-push/deletion policy, release-vs-
closeout separation, single-repo vs multi-repo). It detects or asks for provider,
plan, and visibility *before* promising any specific enforcement mechanism, and
captures the decisions in a structured schema.

**Why this priority**: Branch governance is a design-time operational decision, not a
hidden default. Capturing it where the human can adopt/modify/skip it makes the
posture explicit and portable across repos.

**Independent Test**: Run the DevOps lens for a sample feature and confirm every
governance question is surfaced, the provider/plan/visibility caveat is stated before
any enforcement promise, and the answers are written to the capture schema.

**Acceptance Scenarios**:

1. **Given** a feature whose DevOps lens is selected, **When** the lens runs, **Then**
   it presents the default branch-governance model and asks the human to adopt, modify,
   or skip it.
2. **Given** an unknown provider/plan/visibility, **When** the lens reaches the
   "block direct commits to main" question, **Then** it captures provider/plan/
   visibility constraints and labels the achievable enforcement honestly (does not
   promise branch protection it cannot guarantee).

---

### User Story 3 - Lightweight docs-only and devops lifecycles (Priority: P2)

A developer needs to change only documentation (README, proposals, methodology
wording, release notes) or only DevOps infrastructure (CI/CD, GitHub settings, release
workflows). Instead of running the full feature lifecycle, they follow a lightweight
docs-only or devops lifecycle surface with right-sized required evidence, completing
through a PR without producing a release.

**Why this priority**: Forcing every non-feature change through the full lifecycle is
the over-heavy shape that caused the 177 confusion. Right-sized lifecycles keep
discipline without ceremony.

**Independent Test**: Carry a docs-only change from intent to a PR-ready closeout using
the docs-only surface; confirm it requires the lightweight evidence set and produces no
release.

**Acceptance Scenarios**:

1. **Given** a docs-only change, **When** the developer follows the docs-only surface,
   **Then** they reach a PR-ready closeout with the lightweight evidence (intent,
   audience, changed docs, markdown/link checks, review) and no release is created.
2. **Given** a DevOps/CI change, **When** the developer follows the devops surface,
   **Then** the required evidence includes a risk/rollback plan and dry-run/CI evidence.

---

### User Story 4 - CI enforces work-kind semantics (Priority: P2)

On every PR, Specrew governance/CI validates that exactly one work kind is declared,
the changed files match the declared kind, the required closeout artifacts exist for
that kind, and software-feature/bug-bash PRs cannot merge with open lifecycle
boundaries. Where runtime enforcement is only partial, the posture is recorded honestly
as phased/deferred rather than over-claimed.

**Why this priority**: Branch protection stops direct pushes; CI is where work-kind
semantics are actually checked. This is the runtime layer that makes the methodology
enforceable.

**Independent Test**: Run the validator against fixtures: a well-formed PR of each kind
passes; a mismatched/under-evidenced PR fails (or warns, per the documented phased
posture); confirm the result message states the enforcement posture truthfully.

**Acceptance Scenarios**:

1. **Given** a PR declaring `docs-only` that touches runtime source, **When** the
   validator runs, **Then** it flags the changed-file/work-kind mismatch.
2. **Given** a `software-feature` PR with an open lifecycle boundary, **When** the
   validator runs, **Then** it flags the missing closeout evidence.
3. **Given** a PR with no work-kind declaration, **When** the validator runs, **Then**
   it reports exactly which declaration is missing and how to add it.

---

### User Story 5 - GitHub capability detection (Priority: P3)

Before promising main-protection enforcement, Specrew detects what the GitHub repo can
actually enforce given provider, plan, and visibility, and reports the achievable
mechanism (branch-protection, rulesets, ci-only, or manual). It surfaces a helper to
apply or describe the recommended protection, and never claims an enforcement layer the
repo cannot use.

**Why this priority**: Provider capability drifts with plan/visibility. Honest
capability reporting prevents false confidence; it is valuable but builds on US2/US4.

**Independent Test**: Run capability detection against a known repo context and confirm
the reported mechanism matches the documented GitHub capability matrix, with a
`ci-only`/`manual` fallback when protection is unavailable.

**Acceptance Scenarios**:

1. **Given** a public repo on a plan that supports branch protection, **When**
   detection runs, **Then** it reports `branch-protection` (or `rulesets`) as available.
2. **Given** a private repo on a plan without protected branches, **When** detection
   runs, **Then** it reports `ci-only`/`manual` and does not promise branch protection.

---

### Edge Cases

- **Mixed-scope PR**: A PR touches both runtime source and docs. Which work kind wins,
  and how strict is changed-file classification? (See FR-009 + clarification needed.)
- **Generated mirrors & repository-global ledgers**: Files like `CHANGELOG.md`,
  `.squad/decisions.md`, proposal indexes, and generated host mirrors are touched by
  many work kinds. Classification must not produce false mismatches. (See FR-009.)
- **Provider cannot protect**: Private repo on a plan without protected branches —
  enforcement degrades to ci-only/manual and MUST be reported honestly.
- **Emergency / hotfix bypass**: A production fire needs an expedited path. A bypass
  must still leave an audit artifact rather than silently skipping governance.
- **Multi-repo ownership**: Which repository owns lifecycle truth when implementation
  PRs land in several repos coordinated by one orchestration repo.
- **CI-only false confidence**: CI cannot prevent a direct push after it happens;
  branch protection/rulesets must be the actual main-protection layer, with CI as the
  semantic layer on top.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Specrew MUST define a work-kind taxonomy covering at least
  `software-feature`, `bug-bash`, `docs-only`, and `devops`, each with documented
  lifecycle weight and required evidence, discoverable in a methodology surface.
- **FR-002**: The DevOps & Operations lens MUST present the default PR-backed branch-
  governance model and ask the human to adopt, modify, or skip it.
- **FR-003**: The DevOps lens MUST ask whether direct commits to the default branch
  should be blocked where the host supports it, and MUST capture provider/plan/
  visibility constraints before promising any enforcement mechanism.
- **FR-004**: Specrew MUST distinguish `feature-closeout` from release/post-merge
  validation; post-merge findings MUST create a new PR-backed work item instead of
  reopening the merged feature, and MUST NOT retroactively rewrite merged closeout
  artifacts.
- **FR-005**: Specrew MUST provide a lightweight `docs-only` lifecycle surface that can
  be completed through a PR without producing a release.
- **FR-006**: Specrew MUST provide a `devops` work-kind lifecycle surface for CI/CD,
  GitHub/repository settings, release workflows, branch protection, and publishing
  infrastructure, with risk/rollback and dry-run/CI evidence requirements.
- **FR-007**: Specrew governance/CI MUST validate, on a PR, that (a) exactly one work
  kind is declared, (b) changed files are consistent with the declared kind where
  practical, and (c) the required closeout artifacts exist for that kind; software-
  feature and bug-bash PRs MUST be flagged when an open lifecycle boundary remains.
- **FR-008**: The DevOps lens MUST ask whether the project is single-repo or multi-repo
  and capture the orchestration and release-coordination model.
- **FR-009**: Specrew MUST define how a work item / PR declares its work kind, with a
  documented default declaration mechanism and an allow-list approach for repository-
  global / generated files so they do not produce false changed-file mismatches.
  *[NEEDS CLARIFICATION: declaration mechanism — checked-in `.specrew/work-kind.yml`
  (default proposed), PR label, branch prefix, or a combination?]*
- **FR-010**: Specrew MUST record enforcement posture honestly. Where runtime
  enforcement is partial, documentation and validator output MUST label it
  phased/deferred and MUST NOT over-claim automated enforcement.
- **FR-011**: Specrew MUST define an emergency/bypass path for governance that still
  leaves a durable audit artifact, rather than a silent skip.
- **FR-012**: GitHub capability detection MUST report the achievable enforcement
  mechanism (`branch-protection`, `rulesets`, `ci-only`, or `manual`) for the repo's
  provider/plan/visibility and MUST surface `ci-only`/`manual` when protected branches
  or rulesets are unavailable.
- **FR-013**: Specrew MUST dogfood this model on its own repository: `main` protected
  via PR-required workflow with a declared work kind for this feature, recorded as
  evidence.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit
  reconciliation path.

### Key Entities

- **WorkKind**: A taxonomy entry — `id` (software-feature | bug-bash | docs-only |
  devops), lifecycle weight, required-evidence set, and allowed changed-file scope.
- **WorkKindDeclaration**: How a given work item / PR declares its kind (default
  proposed: a checked-in `.specrew/work-kind.yml`); carries the work-kind id and
  optional metadata.
- **RepositoryGovernanceDecision**: Captured DevOps-lens decision — provider,
  default_branch, protect_default_branch, require_pull_request, require_status_checks,
  required_checks[], apply_to_admins, allow_force_pushes, allow_deletions,
  bypass_actors[], enforcement_mode (branch-protection | rulesets | ci-only | manual).
- **MultiRepoModel**: mode (single-repo | multi-repo), orchestration_repo,
  participant_repos[], merge_coordination, release_coordination.
- **ReleaseValidationRecord**: A post-merge validation record (beta/stable/CI learning)
  separate from feature-closeout; references the merged feature without reopening it.
- **ProviderCapability**: provider + plan + visibility → achievable enforcement
  mechanisms; the input to honest capability reporting.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The four work kinds are documented with lifecycle weight + required
  evidence in a discoverable methodology surface, and a reader can identify which kind a
  given change belongs to. *(FR-001)*
- **SC-002**: Running the DevOps lens surfaces all eight repository-governance questions
  and records the answers in the capture schema, with the provider/plan/visibility
  caveat stated before any enforcement promise. *(FR-002, FR-003, FR-008)*
- **SC-003**: A docs-only change can be carried end-to-end to a PR-ready closeout using
  the docs-only surface with no release produced. *(FR-005)*
- **SC-004**: A worked post-merge-finding example produces a NEW work item and a
  separate release-validation record, never a reopened merged feature. *(FR-004)*
- **SC-005**: The CI/governance validator passes a well-formed PR of each kind and flags
  (or warns, per the documented phased posture) a mismatched or under-evidenced PR, with
  a message that names the exact gap. *(FR-007, FR-009)*
- **SC-006**: GitHub capability detection reports the correct enforcement mechanism for a
  given provider/plan/visibility and falls back to `ci-only`/`manual` without promising
  unavailable protection. *(FR-012)*
- **SC-007**: Specrew's own repo carries `main` PR-protection and a declared work kind
  for this feature as dogfood evidence. *(FR-013)*
- **SC-008**: Every enforcement claim in the shipped surfaces is labeled with its true
  posture (enforced vs phased/deferred); a reviewer can find no over-claim. *(FR-010)*
- **SC-009**: An emergency/bypass path is documented that leaves an audit artifact.
  *(FR-011)*

## Assumptions

- **GitHub-first**: GitHub is the first provider; a provider capability model abstracts
  other providers for later. (Proposal "Out of scope": not every Git provider in v1.)
- **Main already protected**: As of 2026-06-11, Specrew's repo `main` already requires
  pull requests, applies to admins, and blocks force-push/deletion (interim mitigation).
  This feature defines the durable methodology + automation on top of that.
- **Phased enforcement is acceptable**: Documentation + capture schema + DevOps-lens
  questions land first; CI validation and GitHub capability helpers land as far as
  practical, with honest phased/deferred labeling for anything not fully enforced.
- **Self-feature classification**: This feature is delivered as a normal
  `software-feature` until it introduces the work kinds it defines, then dogfoods them.
- **Follow-ups stay deferred**: Proposals 174 (boundary-variance disclosure) and 178
  (verification-strategy lens) remain follow-ups unless a very small supporting slice is
  strictly required.
- **No release for docs-only**: docs-only changes never create a release.

## Dependencies

- The DevOps & Operations design lens knowledge surface (extended by this feature).
- The design-workshop skill and lens-applicability capture (records the new DevOps-lens
  governance answers).
- The existing validator / governance script surface (extended with work-kind checks).
- The CI workflow surface (extended with a work-kind policy check).
- `gh` CLI / GitHub API for capability detection (US5).

## Governance Alignment *(mandatory)*

- **Spec Steward**: Crew Spec Steward (delegated to `claude` this launch) — owns spec
  integrity and the feature-closeout-vs-release-validation distinction.
- **Iteration Facilitator**: Crew Planner + Retro Facilitator — own cadence across the
  two iterations and the phased-enforcement honesty discipline.
- **Capacity Model**: Story points. ~8–14 SP total across two iterations (Iter 1
  methodology layer ~4–6 SP; Iter 2 runtime layer ~4–8 SP).
- **Drift Signals**: `validate-governance`, the drift-check surface, and the new CI
  work-kind validator detect drift between the work-kind declaration, changed files, and
  required evidence; over-claim is caught at review against SC-008/FR-010.
- **Human Oversight Points**: every lifecycle boundary stop (clarify→plan, design-
  analysis option choice, plan→tasks, before-implement, review-signoff, retro,
  iteration-closeout, feature-closeout); plus explicit human approval before any push,
  PR, merge, tag, publish, or release.
