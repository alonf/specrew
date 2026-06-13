# Feature Specification: Work Kind and Branch Governance Model

**Feature Branch**: `182-work-kind-branch-governance`  
**Created**: 2026-06-11  
**Status**: Draft (design-workshop complete)  
**Input**: Proposal 182 — Work Kind and Branch Governance Model. Separate Specrew's
single feature-lifecycle shape into first-class **work kinds** (software-feature,
bug-bash, docs-only, devops), make PR-backed branch protection a DevOps-lens decision,
and stop post-merge release/CI/CD/docs findings from reopening a merged feature.

## Context & Motivation *(informative)*

Feature 177 exposed a lifecycle-shape problem: a software feature can be
implementation-complete and merged, yet release/publish validation keeps producing
lessons *after* the PR is accepted. Specrew tried to hold the feature open to capture
that learning. That is unsafe for real repositories where the release branch is
protected and any post-merge correction must itself be a PR. The durable invariant is:

```text
A merged PR must not leave its work item open on the release branch.
Post-merge findings create a new PR-backed work item.
```

The DevOps & Operations design lens is the right home for "how strict should repository
governance be," because it already covers hosting, CI/CD, rollout, rollback, and
operational roles. This feature is itself delivered as a normal `software-feature` until
it introduces the first-class work kinds it defines, then dogfoods them.

**Workshop outcome (binding design constraints).** The design workshop (product-domain +
7 technical lenses + code-implementation, recorded under
`specs/182-work-kind-branch-governance/workshop/` and `lens-applicability.json`)
established three architectural pillars beyond the original proposal:

1. **Provider-neutral core + pluggable `ProviderAdapter`.** The methodology, the work-kind
   declaration, and the CI validator core import **no forge assumption**. A thin
   `ProviderAdapter` seam carries the only forge-specific behavior; v1 ships a **GitHub
   reference adapter** + a **generic/unknown fallback** (`ci-only`/`manual`); other forges
   (GitLab/Azure/Bitbucket/Gitea) are **synthesized on the fly** when a downstream
   developer names their forge (read-only by default; `apply_protection` human-approved).
2. **Configurable `branch_model`.** Branch **names** (`main`/`master`/`trunk`/…) and the
   branching **method** (trunk / integration-branch / GitFlow / custom) are user-set; the
   promotion *to the release-truth branch* is the natural release-validation event.
3. **Forge-neutralization of all downstream-governing surfaces.** Specrew's
   downstream-*deployed* surfaces (lifecycle prompt, skills, extension scripts, charters,
   lens content, CI templates) are decoupled from Specrew's own GitHub dev habits —
   **without** changing Specrew's own GitHub usage for its own development.

## Clarifications

The design workshop (recorded under `workshop/` + `lens-applicability.json`) served as an
extended clarification with the maintainer. Resolved forks:

- **Declaration mechanism (FR-009)** → `.specrew/work-kind.yml` authoritative (forge-neutral,
  versioned) + an optional branch-prefix hint; PR labels rejected as the source of truth.
- **Enforcement mechanism** → provider-neutral core + pluggable `ProviderAdapter` (GitHub
  reference adapter + generic/unknown fallback + on-the-fly synthesis). branch-protection vs
  rulesets is a per-repo capability the adapter *reports*, not a fixed global choice.
- **Branch name + method** → configurable `branch_model` (trunk/integration-branch/gitflow/
  custom; user-named branches); the promotion to release-truth is the release-validation event.
- **Review gate** → human approvals + comment-resolution always-available; automated review
  opt-in (Copilot suggested on GitHub via the adapter), the user decides in the workshop.
- **Changed-file classification** → allow-list exempts repository-global/generated files;
  fail-open + WARN on anything unknown/malformed.
- **Governance capture location** → project-level `.specrew/repository-governance.yml`
  (decided once, inherited per feature).
- **Multi-repo ownership** → default single-repo; `multi_repo` block captured only when chosen.
- **Brownfield** → detect existing CI/CD + protection and offer adapt-or-change, never
  overwrite.
- **Scope extension (maintainer-directed)** → forge-neutralize ALL downstream-governing
  surfaces of Specrew's own GitHub dev habits, without changing Specrew's own GitHub usage;
  re-sized to ~16–24 SP / 3 iterations.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lifecycle truth survives merge (Priority: P1)

A developer finishes a feature, closes it out, and merges. Later, release validation
surfaces a fix. Instead of reopening the merged feature on a protected release branch,
Specrew directs them to a *new* PR-backed work item (docs-only, devops, or bug-bash). The
merged feature's closeout truth is never retroactively edited.

**Why this priority**: This is the core invariant the proposal exists to protect.

**Independent Test**: Walk a worked example end-to-end (feature merged → post-merge
finding → new work item) using only the shipped methodology surfaces; verify it never
instructs reopening the merged feature and that a release-validation record is captured
separately from feature-closeout.

**Acceptance Scenarios**:

1. **Given** a merged feature PR and a post-merge beta-install failure, **When** the
   developer asks how to record it, **Then** Specrew directs them to open a new bug-bash
   or devops work item and does NOT reopen the merged feature.
2. **Given** a merged feature, **When** release validation produces lessons, **Then** they
   are captured in a release/post-merge validation record explicitly separate from the
   feature's `feature-closeout` artifacts.

---

### User Story 2 - DevOps lens governs branch protection, on any forge and branch model (Priority: P1)

When a developer works the DevOps & Operations lens, it presents Specrew's default
PR-backed protection model and asks the repository-governance questions — including the
**branch model** (style + user-named branches + which are protected + promotion path) and
the **review gate** (human approvals + comment-resolution; opt-in automated review). It
detects or asks for provider, plan, and visibility *before* promising any enforcement
mechanism, and captures the decisions in a **project-level** schema.

**Why this priority**: Branch governance is a design-time operational decision, portable
across repos, forges, and branch models — not a hidden GitHub-shaped default.

**Independent Test**: Run the DevOps lens for a sample feature; confirm every governance
question is surfaced, the branch name + method are configurable, the provider/plan/
visibility caveat precedes any enforcement promise, and the answers are written to
`.specrew/repository-governance.yml`.

**Acceptance Scenarios**:

1. **Given** a feature whose DevOps lens is selected, **When** the lens runs, **Then** it
   presents the default model and asks the human to adopt, modify, or skip it, including
   the branch model and review gate.
2. **Given** a project using `master` + a `dev` integration branch, **When** the lens
   captures the branch model, **Then** the validator and lifecycle honor those names
   (feature-closeout at the `dev` merge; `dev → master` promotion = release-validation).
3. **Given** an unknown provider/plan/visibility, **When** the lens reaches "block direct
   commits to the protected branch", **Then** it captures the constraints and labels the
   achievable enforcement honestly.

---

### User Story 3 - Lightweight docs-only and devops lifecycles (Priority: P2)

A developer changing only documentation, or only DevOps infrastructure, follows a
lightweight docs-only or devops lifecycle surface with right-sized evidence, completing
through a PR without producing a release.

**Why this priority**: Forcing every non-feature change through the full lifecycle is the
over-heavy shape that caused the 177 confusion.

**Independent Test**: Carry a docs-only change from intent to a PR-ready closeout; confirm
the lightweight evidence set and no release.

**Acceptance Scenarios**:

1. **Given** a docs-only change, **When** the developer follows the docs-only surface,
   **Then** they reach a PR-ready closeout with lightweight evidence and no release.
2. **Given** a DevOps/CI change, **When** the developer follows the devops surface,
   **Then** the required evidence includes a risk/rollback plan and dry-run/CI evidence.

---

### User Story 4 - CI enforces work-kind semantics, forge-neutrally (Priority: P2)

On every PR, a **provider-neutral** validator checks exactly one declared work kind,
changed-file/kind consistency, required closeout artifacts, and that
software-feature/bug-bash PRs have no open lifecycle boundary. It runs in any CI (GitHub
Actions is the v1 wiring) and defaults to **advisory**; partial enforcement is labeled
phased/deferred, never over-claimed.

**Why this priority**: CI is where work-kind semantics are actually checked, on top of the
real push-block layer (branch protection).

**Independent Test**: Run the validator against fixtures of each kind; a well-formed PR
passes; a mismatched/under-evidenced PR is flagged with a message naming the exact gap;
confirm the posture is stated truthfully.

**Acceptance Scenarios**:

1. **Given** a PR declaring `docs-only` that touches runtime source, **When** the validator
   runs, **Then** it flags the changed-file/work-kind mismatch and names the allowed scope.
2. **Given** a `software-feature` PR with an open lifecycle boundary, **When** the validator
   runs, **Then** it flags the missing closeout evidence.
3. **Given** a PR with no work-kind declaration, **When** the validator runs, **Then** it
   reports exactly which declaration is missing (and any branch-prefix default) and how to
   add it.
4. **Given** a repository with no provider adapter, **When** the validator runs, **Then** it
   still works via the `git diff` + `branch_model` fallback.

---

### User Story 5 - Honest forge capability detection + on-the-fly adapters (Priority: P3)

Before promising protection, Specrew detects what the repo can actually enforce given
provider/plan/visibility and reports the achievable mechanism
(`branch-protection`/`rulesets`/`ci-only`/`manual`). On GitHub it can *suggest* Copilot PR
review (opt-in) and describe/apply protection (apply is human-approved). For a non-GitHub
forge it can synthesize a read-only adapter once the developer names the forge.

**Why this priority**: Provider capability drifts with plan/visibility; honest reporting
prevents false confidence. Builds on US2/US4.

**Independent Test**: Run detection against a known repo context; confirm the reported
mechanism matches the capability matrix with a `ci-only`/`manual` fallback; confirm a
synthesized adapter is read-only until human-verified.

**Acceptance Scenarios**:

1. **Given** a public repo on a plan that supports protection, **When** detection runs,
   **Then** it reports `branch-protection` (or `rulesets`).
2. **Given** a private repo without protected branches, **When** detection runs, **Then**
   it reports `ci-only`/`manual` and does not promise protection.
3. **Given** a developer who names a non-GitHub forge, **When** synthesis runs, **Then** it
   produces an adapter that is read-only (`detect`/`describe`) until a human verifies it.

---

### User Story 6 - Brownfield projects adapt, not overwrite (Priority: P2)

A brownfield project that already has CI/CD + branch protection is met with detection of
its existing posture and an **adapt-or-change** offer — slot the work-kind check into the
existing CI lane, or change to the recommended posture — never a silent overwrite.

**Why this priority**: Most real downstreams already have *some* governance; imposing or
overwriting it is hostile and unsafe (NFR #5 brownfield-compat).

**Independent Test**: Point the lens at a repo with existing protection + a CI lane;
confirm it reports the detected posture and offers adapt-or-change rather than overwriting.

**Acceptance Scenarios**:

1. **Given** a repo with an existing protected branch + CI lane, **When** the DevOps lens
   runs, **Then** it shows the detected posture and asks ADAPT or CHANGE.
2. **Given** the developer chooses ADAPT, **When** the governance is captured, **Then** the
   work-kind check is wired into the existing lane and the existing posture is recorded.

---

### Edge Cases

- **Mixed-scope PR**: touches runtime source and docs → changed-file classification names
  the dominant kind's allowed scope; an allow-list exempts global/generated files.
- **Generated mirrors & global ledgers**: `CHANGELOG.md`, `.squad/decisions.md`, proposal
  indexes, host mirrors — exempt via allow-list so they don't produce false mismatches.
- **Provider cannot protect**: degrades to `ci-only`/`manual`, reported honestly.
- **Emergency / hotfix bypass**: a bypass leaves a durable audit artifact, never a silent
  skip.
- **Multi-repo ownership**: which repo owns lifecycle truth across coordinated repos.
- **CI-only false confidence**: CI cannot prevent a direct push; branch protection/rulesets
  are the actual push-block layer, with CI as the semantic layer on top.
- **No adapter present**: the validator runs via the `git diff` + `branch_model` fallback.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Specrew MUST define a work-kind taxonomy covering at least `software-feature`,
  `bug-bash`, `docs-only`, and `devops`, as a **data-driven catalog** (`work-kinds.yml`)
  with documented lifecycle weight + required evidence + allowed changed-file scope.
- **FR-002**: The DevOps lens MUST present the default PR-backed branch-governance model and
  ask the human to adopt, modify, or skip it.
- **FR-003**: The DevOps lens MUST capture a configurable **`branch_model`** — branching
  style (trunk/integration-branch/gitflow/custom), user-named branches, which branches are
  protected, and the promotion path — and MUST ask whether to block direct commits to the
  protected branch where the forge supports it, capturing provider/plan/visibility
  constraints before promising any enforcement mechanism.
- **FR-004**: Specrew MUST distinguish `feature-closeout` from release/post-merge
  validation; post-merge findings MUST create a new PR-backed work item instead of
  reopening the merged feature, and MUST NOT retroactively rewrite merged closeout
  artifacts. The promotion to the release-truth branch is the natural release-validation
  event.
- **FR-005**: Specrew MUST provide a lightweight `docs-only` lifecycle surface completable
  through a PR without producing a release.
- **FR-006**: Specrew MUST provide a `devops` work-kind lifecycle surface (CI/CD, repo
  settings, release workflows, branch protection, publishing infra) with risk/rollback and
  dry-run/CI evidence requirements.
- **FR-007**: A **provider-neutral** CI validator MUST check, on a PR, that (a) exactly one
  work kind is declared, (b) changed files are consistent with the declared kind where
  practical, and (c) required closeout artifacts exist; software-feature/bug-bash PRs MUST
  be flagged when an open lifecycle boundary remains. It MUST default to **advisory**.
- **FR-008**: The DevOps lens MUST ask single-repo vs multi-repo and capture the
  orchestration and release-coordination model.
- **FR-009**: A work item declares its kind via an authoritative, forge-neutral checked-in
  **`.specrew/work-kind.yml`**, with an **optional branch-prefix convention**
  (`docs/`,`devops/`,`fix/`,`feature/`) as a default the file confirms/overrides; an
  allow-list exempts repository-global/generated files from changed-file checks. *(Resolved
  in the integration-api lens; PR labels rejected as source of truth.)*
- **FR-010**: Specrew MUST record enforcement posture honestly; partial runtime enforcement
  MUST be labeled phased/deferred and MUST NOT over-claim automated enforcement.
- **FR-011**: Specrew MUST define an emergency/bypass path that leaves a durable audit
  artifact (who/why/when/what), not a silent skip.
- **FR-012**: Capability detection MUST report the achievable enforcement mechanism
  (`branch-protection`/`rulesets`/`ci-only`/`manual`) for the repo's provider/plan/
  visibility and surface `ci-only`/`manual` when protection is unavailable.
- **FR-013**: Specrew MUST dogfood this model on its own repository (protected branch via
  PR-required workflow + a declared work kind for this feature), recorded as evidence.
- **FR-014**: The methodology, the declaration, and the CI validator **core** MUST import no
  forge assumption; the `ProviderAdapter` is the only forge-specific seam.
- **FR-015**: Specrew MUST ship the `ProviderAdapter` **contract** + a **GitHub reference
  adapter** + a **generic/unknown fallback** (`ci-only`/`manual` via `git diff`).
- **FR-016**: Specrew MUST provide on-the-fly adapter **synthesis** conduct: generate a
  forge adapter when the downstream developer names their forge, read-only by default, with
  recorded provenance, captured at the downstream project.
- **FR-017**: The DevOps lens MUST capture a **`review_gate`** — human approvals +
  comment-resolution (always-available) and **opt-in** automated review (Copilot suggested
  on GitHub via the adapter; the user decides in the workshop).
- **FR-018**: Governance answers MUST persist to a **project-level**
  `.specrew/repository-governance.yml` (decided once, inherited per feature, deltas re-asked).
- **FR-019**: Specrew MUST audit + decouple ALL downstream-governing surfaces (lifecycle
  prompt, skills, extension scripts, charters, lens content, CI templates) from Specrew's
  own GitHub dev habits, producing an inventory, **without** changing Specrew's own GitHub
  usage for its own development.
- **FR-020**: `apply_protection` MUST be human-approved, never auto-applied, never from an
  unverified synthesized adapter; Specrew MUST hold no forge secret (tokens come from CI or
  the user's auth; least-privilege scopes).
- **FR-021**: Specrew MUST detect an existing brownfield CI/CD + branch-protection + review
  setup and offer to **adapt** the work-kind check into it OR **change** to the recommended
  posture, never silently overwriting; the existing posture + chosen action are recorded.

<!-- Iteration 4 additions: dogfood-finding completions (real-GitLab dogfood, 2026-06-12; see
     iterations/004/ + dogfood-findings.md). FR-022 completes FR-019's "ALL surfaces" claim.
     Scope: work-kind / forge-neutral governance ONLY — NOT F-174's session-bootstrap rewrite,
     NOT DF-006 session-state clobbering. -->
- **FR-022**: Forge-neutralization MUST cover downstream-governing **runtime/deployed surfaces** —
  including launch-prompt text (`scripts/specrew-start.ps1` / `.specrew/last-start-prompt.md`) and
  deployed per-host agent files (e.g. `.github/agents/squad.agent.md`) — not only methodology markdown.
  (Completes FR-019's "ALL surfaces"; the iter-3 implementation's SC-008 sweep was markdown-only.)
- **FR-023**: Work-kind **lifecycle templates** MUST be operationalized through **catalog/schema/deploy/
  intake**, so a selected `work_kind` resolves to its `<kind>-lifecycle.md` lifecycle template (not
  agent improvisation).
- **FR-024**: CI-lane guidance MUST be **forge-aware**. Minimum: the DevOps lens proposes CI for the
  project's forge and honestly states when no lane ships. Optional: ship a GitLab CI template if
  planned. A non-GitHub project MUST NOT be defaulted to GitHub Actions.
- **FR-025**: Lifecycle-end routing MUST distinguish **downstream project work**, **upstream Specrew/
  tool defects** (routed to the tool's backlog, not the project's carried-forward items), and **new
  work-kind items** (a separate work item, never "iteration N" of a different-kind feature).
- **FR-026**: Capability detection MUST read the canonical `provider.name`, with a **fallback for
  older/simpler schema shapes** (it MUST report `gitlab`, not `gitlab-ci`).

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation
  path.

### Key Entities

- **WorkKind** — `work-kinds.yml` entry: id (software-feature|bug-bash|docs-only|devops),
  lifecycle weight, required-evidence set, allowed changed-file scope.
- **WorkKindDeclaration** — `.specrew/work-kind.yml`: the declared kind + optional metadata.
- **RepositoryGovernance** — project-level `.specrew/repository-governance.yml`:
  `provider`, `branch_model` (style + named branches + protection + promotion_path),
  `review_gate`, `apply_to_admins`, `bypass_actors[]`, `enforcement_mode`.
- **MultiRepoModel** — mode, orchestration_repo, participant_repos[], merge/release
  coordination.
- **ReleaseValidationRecord** — post-merge validation record separate from feature-closeout.
- **ProviderAdapter** — `detect_capability`/`describe_protection`/`apply_protection`(guarded)
  /`read_pr_context`; implementations: github (reference), generic/unknown (fallback),
  synthesized (on the fly).
- **ProviderCapability** — provider+plan+visibility → achievable enforcement mechanisms.

### Requirement Ownership & Delivery Window *(satisfies TG-002 + TG-003)*

Every FR carries an expected owner role and an intended iteration. Owner roles are the
Crew baseline roles (Spec Steward = methodology/spec/lens content; Implementer = code,
catalog, validator, adapters; Reviewer = honesty/security/evidence review; all delegated
to `claude` this launch).

| FR | Owner role(s) | Delivery window |
| --- | --- | --- |
| FR-001 work-kind taxonomy catalog | Spec Steward + Implementer | Iter 1 |
| FR-002 DevOps lens presents default model | Spec Steward | Iter 1 |
| FR-003 `branch_model` capture + protected-branch + capability caveat | Spec Steward + Implementer | Iter 1 |
| FR-004 closeout vs release-validation invariant | Spec Steward | Iter 1 |
| FR-005 docs-only lifecycle surface | Spec Steward + Implementer | Iter 1 |
| FR-006 devops lifecycle surface | Spec Steward + Implementer | Iter 1 |
| FR-007 provider-neutral CI validator | Implementer | Iter 2 |
| FR-008 single/multi-repo capture | Spec Steward | Iter 1 |
| FR-009 declaration mechanism | Implementer | Iter 1 |
| FR-010 honest/phased enforcement (no over-claim) | Reviewer + Spec Steward | Iter 1 (baked) → all |
| FR-011 emergency/bypass audit | Implementer + Reviewer | Iter 2 |
| FR-012 capability detection | Implementer | Iter 2 |
| FR-013 dogfood on Specrew's repo | Implementer + Reviewer | Iter 2 |
| FR-014 provider-neutral core | Implementer | Iter 1 |
| FR-015 adapter contract + GitHub reference + fallback | Implementer | Iter 1 (contract + fallback) / Iter 2 (GitHub detect) |
| FR-016 on-the-fly adapter synthesis | Spec Steward (conduct) + Implementer | Iter 1 (doc) / Iter 2 (exercised) |
| FR-017 `review_gate` | Spec Steward | Iter 1 |
| FR-018 project-level governance capture | Spec Steward + Implementer | Iter 1 |
| FR-019 forge-neutralization audit + decouple | Implementer + Reviewer | Iter 1 (inventory) / Iter 3 (migration) |
| FR-020 `apply_protection` human-gated + no secrets | Implementer + Reviewer | Iter 2 |
| FR-021 brownfield adapt-or-change | Spec Steward (content) + Implementer (detector) | Iter 1 (content) / Iter 2 (detector) |
| FR-022 runtime-deployed surface neutralization + widened sweep (completes FR-019) | Implementer + Reviewer | Iter 4 |
| FR-023 operationalize lifecycle templates | Spec Steward + Implementer | Iter 4 |
| FR-024 forge-aware CI lane | Spec Steward + Implementer | Iter 4 |
| FR-025 tool-defect vs project-work + new-kind-new-work-item | Spec Steward | Iter 4 |
| FR-026 capability detection reads `provider.name` | Implementer | Iter 4 |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The four work kinds are documented (lifecycle weight + required evidence) in a
  discoverable, data-driven catalog; a reader can classify a change. *(FR-001)*
- **SC-002**: Running the DevOps lens surfaces all governance questions (incl. branch_model,
  review_gate, single/multi-repo) and records answers, with the provider/plan/visibility
  caveat before any enforcement promise. *(FR-002, FR-003, FR-008, FR-017)*
- **SC-003**: A docs-only change reaches a PR-ready closeout with no release. *(FR-005)*
- **SC-004**: A worked post-merge-finding example produces a NEW work item + a separate
  release-validation record, never a reopened merged feature. *(FR-004)*
- **SC-005**: The CI validator passes a well-formed PR of each kind and flags (or warns, per
  phased posture) a mismatched/under-evidenced PR with a message naming the exact gap.
  *(FR-007, FR-009)*
- **SC-006**: Capability detection reports the correct mechanism for a given
  provider/plan/visibility and falls back to `ci-only`/`manual` without over-promising.
  *(FR-012)*
- **SC-007**: Specrew's own repo carries protected-branch PR-protection + a declared work
  kind for this feature as dogfood evidence. *(FR-013)*
- **SC-008**: Every enforcement claim in the shipped surfaces is labeled with its true
  posture; a reviewer finds no over-claim. *(FR-010)*
- **SC-009**: A documented emergency/bypass path leaves an audit artifact. *(FR-011)*
- **SC-010**: The methodology + core validator run on a non-GitHub / no-adapter repo with
  the full lifecycle (via the `git diff` + `branch_model` fallback). *(FR-014, FR-015)*
- **SC-011**: A non-`main` integration-branch config (e.g. `master` + `dev`) is honored by
  the validator + lifecycle (closeout at target merge; promotion = release-validation).
  *(FR-003)*
- **SC-012**: On-the-fly synthesis produces a forge adapter that is read-only until a human
  verifies it. *(FR-016, FR-020)*
- **SC-013**: The forge-neutralization audit inventory exists; migrated downstream-governing
  surfaces carry no GitHub-only mandate (closeout "check Copilot" → opt-in); Specrew's own
  infra is unchanged. *(FR-019)*
- **SC-014**: Applying the updated DevOps lens to Specrew's own repo surfaces no conflict
  (or is reconciled); Specrew's `.specrew/repository-governance.yml` matches its actual
  posture — also proving the neutralized closeout still works for a GitHub project.
  *(FR-013, FR-021)*
- **SC-015**: The forge-neutralization sweep FAILS on **unlabeled** GitHub/PSGallery/Specrew-release
  mandates in downstream-governing `.ps1`, deployed-agent, lifecycle, methodology, and coordinator
  surfaces. It MUST include at least `gh pr create`, `gh pr merge`, `Find-Module Specrew`,
  `Install-Module Specrew`, `PSGallery` / `PowerShell Gallery`, with explicit **allowlist / labeled-
  example** semantics. (Confound-proof regression guard; also catches F-174's `launch-contract.ps1`
  site at reconciliation via a pattern-based `.ps1` scan.) *(FR-022)*
- **SC-016**: In a deployed downstream project, selecting a work kind resolves from
  `.specrew/work-kind.yml` + the catalog to the correct `<kind>-lifecycle.md`, and the **intake/start
  surface shows that lifecycle contract** (verified by artifact inspection, not agent behavior).
  *(FR-023)*

## Assumptions

- **GitHub-first, not GitHub-only**: GitHub is the first/reference adapter; a generic
  fallback + on-the-fly synthesis cover other forges. The methodology + core never depend on
  GitHub.
- **Main already protected**: Specrew's repo `main` already requires PRs, applies to admins,
  and blocks force-push/deletion (interim mitigation, 2026-06-11).
- **Phased enforcement is acceptable**: docs + capture + lens questions land first; the CI
  validator + capability helpers land as far as practical with honest phased/deferred
  labeling.
- **Self-delivery**: built as a normal `software-feature`, then dogfooded.
- **Specrew's own GitHub usage is unchanged**: only downstream-*governing* surfaces are
  forge-neutralized.
- **Follow-ups deferred**: Proposals 174 and 178 stay follow-ups unless a very small
  supporting slice is strictly required.
- **No release for docs-only**.

## Dependencies

- The DevOps & Operations design lens (extended) + the design-workshop capture.
- The validator / governance script surface (extended with work-kind checks).
- The CI workflow surface (a provider-neutral script + a GitHub Actions wrapper).
- `gh` / GitHub API for the GitHub adapter only; pure git for the core + generic fallback.

## Iteration Plan *(capacity confirmed at planning)*

~16–24 SP across **three iterations** (re-sized from the proposal's 8–14 SP after the
workshop added the provider-adapter, branch_model, and forge-neutralization pillars):

- **Iter 1 — methodology + seam contract + audit**: FR-001..006, 008, 009, 010, 014,
  015(contract+fallback), 016(doc), 017, 018, 019(inventory), 021(content) → SC-001..004, 011.
- **Iter 2 — runtime**: FR-007, 011, 012, 015(GH detect), 016(exercised), 020, 021(detector)
  → SC-005, 006, 007, 009, 010, 012, 014.
- **Iter 3 — decouple**: FR-019(migration) → SC-008, 013.

If the decouple migration is too large for one feature, it may be split into a sibling
work item (decided at capacity / iteration-closeout).

## Governance Alignment *(mandatory)*

- **Spec Steward**: Crew Spec Steward (delegated to `claude`) — owns spec integrity and the
  feature-closeout-vs-release-validation distinction.
- **Iteration Facilitator**: Crew Planner + Retro Facilitator — own cadence across three
  iterations and the phased-enforcement honesty discipline.
- **Capacity Model**: Story points. ~16–24 SP across three iterations.
- **Drift Signals**: `validate-governance`, the drift-check surface, and the new CI
  work-kind validator detect drift between declaration, changed files, and required
  evidence; over-claim is caught at review against SC-008/FR-010; forge coupling is caught
  against the FR-019 audit inventory.
- **Human Oversight Points**: every lifecycle boundary stop; design-analysis option choice;
  before-implement; review-signoff; iteration/feature-closeout; plus explicit human approval
  before any push, PR, merge, tag, publish, release, or `apply_protection`.
