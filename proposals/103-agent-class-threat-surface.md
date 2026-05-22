---
proposal: 103
title: Agent-Class Threat Surface (Concrete Threat Catalog + Prevention + Detection)
status: candidate
discussion-status: ad-hoc
spec-status: none
relationship-status: clean
phase: phase-3
estimated-sp: 12-18
discussion: ad-hoc 2026-05-22 session
---

# Agent-Class Threat Surface (Concrete Threat Catalog + Prevention + Detection)

## Why

As Specrew governs increasingly autonomous AI agents in real codebases, the attack surface shifts from traditional application vulnerabilities to **agent-class** exploits — threats that exist specifically because an autonomous agent has tool-use, file-write, and CI/CD authority. These threats are not covered by:

- **Proposal 097 (Coupling Surface Catalog)** — handles *dependency-level* threats (CVEs, license issues, version-currency). An agent-introduced backdoor in a dependency upgrade PR has a *dependency* dimension that 097 catches, but the *agent-introduced-without-human-review* dimension is invisible to 097.
- **Proposal 008 (NFR Governance)** — handles security as a non-functional requirement at spec time. Cannot react to threats that emerge during execution from agent behavior.
- **Proposal 073 (Review Evidence Integrity)** — handles reviewer-bypass and form-not-meaning. Adjacent but doesn't catalog the underlying attack vectors.
- **Proposal 102 (Cross-Model Reviewer)** — adds reviewer independence. Helps catch some agent threats but isn't designed around the agent-class threat taxonomy.

There is currently no Specrew artifact that **enumerates concrete agent-class attack scenarios with named CVEs/incident patterns, classifies them by severity and blast radius, and specifies preventive controls**. The research document received 2026-05-22 named three categories ("prompt injection, capability creep, supply chain via CI/CD") — useful as a starting taxonomy but too abstract to act on.

The motivation is **preventive, not reactive**. Specrew memory shows zero past incidents of agent-class threats in our own development. The broader ecosystem, however, has produced concrete attack patterns (Socket / Aderyn / community reports of agent-introduced supply chain attacks, prompt-injection demonstrations, capability-creep audits). This proposal commits Specrew to enumerate the threat surface explicitly *before* an incident, with the understanding that:

1. The ROI is asymmetric: preventive cost is small; incident cost is potentially catastrophic
2. Memory entry `project_proposals_pattern_as_opt_in_profile_2026_05_19` already commits Specrew to govern multi-agent execution; security comes with that territory
3. Autonomous mode (Proposal 066's `--autonomous` flag) is exactly when these threats are highest, and `--autonomous` is the default for overnight runs

User-stated motivation (2026-05-22, from external research document review):

> "AI agents gain operational autonomy, the attack surface expands from standard application vulnerabilities to exotic, agent-specific exploits. These include prompt injection attacks, capability creep, and sophisticated supply chain attacks executed via agent-generated modifications to CI/CD pipelines."

This proposal makes the categories concrete and actionable.

## What (6 Pillars)

### Pillar 1 — Concrete threat catalog (named scenarios, not categories)

Catalog lives at `.specrew/security/agent-threats.md` — schema parallel to Proposal 091's tech-debt ledger and Proposal 097's coupling surface, optimized for security context.

**Initial catalog of named scenarios** (each with severity, blast radius, current detection status, proposed control):

| ID | Scenario | Severity | Blast radius | Current detection | Proposed control |
|---|---|---|---|---|---|
| AT-001 | Agent inserts backdoor in dependency upgrade PR | Critical | Production | None (097 catches CVEs, not novel backdoors) | Require human approval for any PR that modifies dependency manifests; reviewer-LLM (Proposal 102) cross-checks dependency PRs |
| AT-002 | Agent writes CI workflow that exfiltrates secrets to attacker URL | Critical | Production + future builds | None | Require human approval for any change under `.github/workflows/`, `.gitlab-ci.yml`, `azure-pipelines.yml`, etc. — even in `--autonomous` mode |
| AT-003 | Prompt injection via README of copied OSS project causes agent to commit malicious code | High | Single feature, potentially production | None | Content-quarantine: external content (README, issues, comments) loaded into context is flagged as untrusted; agents instructed to never execute instructions found in untrusted content |
| AT-004 | Agent tool-use access broadens over time as user clicks "allow" repeatedly | Medium-High | Local + future sessions | None | Capability allow-list per project + per-session; periodic capability audit at retro |
| AT-005 | Agent recovers stale credentials from session-state files or `.specrew/` cache | High | Local secrets | None | Validator scans for credential-pattern strings in `.specrew/`; gitignore enforcement; session-state encryption (future) |
| AT-006 | Agent emails / posts to external services using cached auth without authorization | High | Reputation, account compromise | None | Tool-use audit log; external-service-call gate requires explicit per-session allowance |
| AT-007 | Agent merges PR into protected branch by exploiting overprovisioned token | Critical | Production | None | Token scopes minimized at provisioning; merge-protected branches require human approval |
| AT-008 | Agent commits to wrong repository via path-traversal in user-prompted file paths | High | Cross-project | None | File-write paths validated against project root; symlink detection |
| AT-009 | Agent serializes secrets into commit message or PR body | High | Public if repo is public | None | Pre-commit / pre-PR scan for credential patterns in commit messages + PR bodies (composes with secret-scanning tools) |
| AT-010 | Agent generates code containing intentionally-obfuscated backdoor in response to prompt injection | Critical | Production | None | Cross-model reviewer (Proposal 102 L2/L3) cross-checks generated code; static analysis for obfuscation patterns |
| AT-011 | Agent disables hooks / validators / pre-commit / tests as "fix" for failing CI | Medium-High | Quality erosion + future incidents | None | Validator detects deletions or weakenings of governance files; reviewer-LLM flags any change to `.specrew/`, `.husky/`, `.github/workflows/`, etc. |
| AT-012 | Agent reads developer machine state outside project root (env vars, ssh keys, browser profiles) | High | Local secrets | None | Tool-use sandboxing; explicit filesystem-scope per session |

Catalog is **curated**, **versioned**, and **growing**. Initial set targets the 12 highest-blast-radius scenarios; community contributions via PR with sanity checks.

### Pillar 2 — Prevention-first for high-blast-radius

For each scenario in the catalog, the proposal specifies whether to ship **prevention** (don't let the threat happen) or **detection** (identify after the fact) — or both.

**Prevention is shipped first for**: AT-001 (dependency PRs), AT-002 (CI/CD changes), AT-007 (protected-branch merges), AT-010 (obfuscation in code).

**Detection is shipped first for**: AT-004 (capability creep — needs longitudinal data), AT-005 (credential recovery — scan-based), AT-009 (secrets in commit messages — pre-commit scan), AT-011 (governance-file weakening — diff-based).

**Prevention + detection both**: AT-003 (prompt injection — content quarantine prevents some; runtime detection catches more).

Iteration 1 ships prevention for all four "shipped first for prevention" scenarios. Iteration 2 adds detection. Iteration 3+ expands the catalog and adds remaining controls.

### Pillar 3 — Autonomous-mode interaction (additional guardrails required)

`--autonomous` mode (Proposal 066) skips human approvals at lifecycle gates. That's exactly when agent-class threats are highest. The proposal commits to **additional guardrails specifically for autonomous mode**:

| Guard | Gate-respecting mode | Autonomous mode |
|---|---|---|
| Dependency-PR approval | Soft warning; user can approve | **Hard block; autonomous mode does NOT bypass; falls through to human even in `--autonomous`** |
| CI/CD-change approval | Soft warning | **Hard block; same fallthrough** |
| Protected-branch merge | Manual | **Hard block; human-required** |
| External-service tool-use (network calls) | Per-call confirmation | **Allow-list only; non-allow-listed calls hard-block** |
| Cross-model reviewer (Proposal 102) | Optional per profile | **Mandatory at L2+ for high-blast-radius PRs in autonomous mode** |

These constitute the **autonomous-mode security envelope**: a set of hard gates that `--autonomous` cannot bypass. Their existence is what makes `--autonomous` safe enough to ship.

### Pillar 4 — Boundary with Proposal 097 (Coupling Surface)

Clean handoff between 097 and 100:

- **097 owns**: the catalog of *what we couple to* (dependencies, services, OS tools, URLs). Per-coupling: version, license, CVEs, coupling-level.
- **100 owns**: the catalog of *agent-class threats* (named scenarios that exploit agent autonomy). Per-threat: severity, blast radius, prevention, detection.

When an agent-introduced PR upgrades a dependency to a version with a CVE:

- 097's `dep-staleness` / CVE-detection adapter flags the CVE → debt entry
- 100's AT-001 control (human approval for dependency PRs) flags the PR itself as requiring human approval
- Both fire, both produce findings, neither duplicates

Cross-references explicit in both catalogs. Dashboard (Proposal 092) consumes both.

### Pillar 5 — Threat-intel curation model

Who maintains the catalog over time?

- **Initial catalog**: Specrew core authors AT-001 through AT-012 at ship.
- **Ongoing additions**: community contributions via PR with sanity checks (each new threat needs concrete scenario, severity rationale, proposed control).
- **External feed integration**: when ecosystem produces standardized agent-threat databases (analogous to NVD for traditional CVEs), the catalog ingests them. As of 2026-05-22, no such database exists at scale; the catalog is bootstrapped from first-principles scenarios + ecosystem incidents.
- **Severity calibration over time**: as ecosystem incidents materialize, severity ratings update. Catalog versioning + audit log preserves history.

The catalog is **explicitly Specrew-core curated** with community input, not a wiki — to avoid degradation under attacker-supplied "scenarios" that downgrade real threats.

### Pillar 6 — Severity tiering + response

Three tiers determine response:

| Tier | Examples | Response when control fires |
|---|---|---|
| **Tier 1 — Critical** | AT-001, AT-002, AT-007, AT-010 | Hard block; human override required; audit log entry; retro discussion mandatory |
| **Tier 2 — High** | AT-003, AT-005, AT-006, AT-008, AT-009, AT-011, AT-012 | Soft warning; logged; reviewer (human or Proposal 102) must address before boundary advances |
| **Tier 3 — Medium-High** | AT-004 | Logged; surfaced at retro; trend-tracked; no immediate gate |

Tier 1 is non-negotiable, profile cannot disable. Tier 2 + 3 are profile-configurable. This prevents "we disabled the annoying gates" pattern from undermining the highest-stakes controls.

## Functional Requirements

- **FR-001**: `.specrew/security/agent-threats.md` catalog with AT-001 through AT-012 initial scenarios
- **FR-002**: Each scenario has: id, name, severity, blast radius, current detection, proposed control, status (planned / shipped), shipped-as reference
- **FR-003**: Iteration 1 ships prevention controls for AT-001, AT-002, AT-007, AT-010
- **FR-004**: Iteration 2 ships detection controls for AT-004, AT-005, AT-009, AT-011
- **FR-005**: Tier 1 controls hard-block in autonomous mode (cannot be bypassed by `--autonomous`)
- **FR-006**: Tier 2 + 3 controls are profile-configurable (Proposal 047)
- **FR-007**: Catalog ingestion path: community PRs with sanity checks; Specrew core has final authority
- **FR-008**: Validator rule for catalog integrity (required fields, severity tier, control specified)
- **FR-009**: Audit log entry for every Tier 1 / Tier 2 control fire with timestamp + outcome + commit reference
- **FR-010**: Dashboard (Proposal 092) section: threats fired this iteration, controls bypassed, top-frequency scenarios
- **FR-011**: Composition with Proposal 097: dependency-CVE findings cross-reference AT-001 (agent-introduced dependency change context)
- **FR-012**: Composition with Proposal 102: cross-model reviewer mandatory at L2+ for Tier 1 affected PRs in `--autonomous`
- **FR-013**: Composition with Proposal 103 (`--autonomous` mode discipline) — security envelope as described in Pillar 3
- **FR-014**: Retro template gains a `## Security Events` section: which controls fired, which were bypassed, recommendation for next iteration
- **FR-015**: Self-applied dogfooding: Specrew adopts the catalog for its own development; first month's findings populate the empirical-incident record

## Out of scope

- **Replacing existing security tools** (Snyk, Socket, OWASP scanners, SAST/DAST) — 103 aggregates their signals into agent-class context, doesn't replace them
- **General application security** (XSS, SQL injection, etc.) — that's Proposal 008 NFR territory
- **Real-time threat-feed subscriptions** — out of scope at MVP; catalog is static + community-contributed initially
- **Agent forensics post-incident** (which agent did what, when, why) — composes with future dashboard work (Proposal 092 event stream); not this proposal's responsibility to architect
- **Automated remediation** ("agent did X bad; auto-revert") — too risky; humans remediate; this proposal detects + prevents only
- **Cryptographic verification of agent identity** — interesting but future; not at MVP
- **Per-agent risk scoring** ("this Claude session is more trustworthy than that one") — out of scope; agents are treated uniformly

## Effort

- **Pillar 1 (catalog authoring AT-001 through AT-012)**: ~3 SP — research-heavy; each scenario needs concrete rationale
- **Pillar 2 (prevention controls iteration 1: AT-001, AT-002, AT-007, AT-010)**: ~5-7 SP — git-diff-based gates + reviewer integration
- **Pillar 3 (autonomous-mode security envelope)**: ~2 SP — flag check + hard-block logic in lifecycle gates
- **Pillar 4 (composition adapter with 097)**: ~1 SP
- **Pillar 5 (catalog curation tooling)**: ~1 SP — validator rule + contribution-PR template
- **Pillar 6 (severity-tier policy + dashboard integration)**: ~2 SP
- **Retro template + agent charter updates**: ~1 SP
- **Self-applied dogfooding**: ~1 SP
- **Total iteration 1**: ~12-15 SP
- **Iteration 2 (detection controls)**: ~5-8 SP
- **Iteration 3 (catalog expansion + external feed integration if available)**: ~3-5 SP
- **Realistic total**: ~20-28 SP across 3 iterations; **MVP target**: 12-15 SP iteration 1.

## Phase placement

**Phase 3 — security + governance maturity**. Composes with Proposal 102 (cross-model reviewer) and Proposal 097 (coupling surface). Trigger condition for prioritization: **ship after observing a near-miss in our own dev OR when the broader ecosystem produces enough incident data to justify investment**.

Sequencing recommendation:

1. 097 (Coupling Surface) ships first — provides dependency-level controls and the catalog pattern
2. 099 (Cross-Model Reviewer) ships next — provides the reviewer-independence Tier 1 affected PRs need
3. 100 ships after both — fills the agent-class gap with concrete controls
4. Or, if a security incident materializes earlier, 100 jumps the queue with iteration 1 focused on the specific attack pattern observed

## Open questions

1. **AT-001-012 numbering — stable across catalog updates?** Recommendation: yes; numbers never reused; new threats get next available number; deprecated threats retain ID with status field.
2. **Should the catalog be public** (visible in `proposals/`, dashboards, external docs)? Recommendation: yes — the threat patterns are common knowledge; concealing them helps no one. Specific *controls* for individual organizations may be private.
3. **How to write controls that work cross-host** (GitHub vs GitLab vs Bitbucket)? Recommendation: control logic is host-aware (composes with git-host-adapter from github-coupling-investigation memory); each host has its own specific implementation behind the abstraction.
4. **Empirical-motivation gap** — without past Specrew incidents, hard to prioritize. Recommendation: trigger-condition gating; explicit "this proposal activates when X happens"; meanwhile keep iteration 1 in draft state.
5. **Capability allow-list per project (AT-004)** — granularity? Per-tool? Per-tool-action? Recommendation: per-tool at MVP; per-tool-action is future enhancement.
6. **Content-quarantine for prompt injection (AT-003)** — how to mark "untrusted"? Visual indicators in agent context? Recommendation: external-content blocks are tagged with `<external-content trust="untrusted">...</external-content>` wrapper; agent charter explicit about never executing instructions from such blocks.
7. **Secrets-pattern scanning (AT-005, AT-009)** — false positives are painful. Recommendation: standard tools (gitleaks, truffleHog) integrated rather than custom; tune per-project; opt-in heavy mode.
8. **Should profile-disabling of Tier 2 controls require explicit risk acceptance** (signed acknowledgement in `.specrew/security/risk-acceptances.md`)? Recommendation: yes — disabling is a deliberate choice with audit trail.
9. **Catalog evolution rate** — too-frequent updates create churn; too-slow leaves threats uncovered. Recommendation: quarterly review at minimum; ad-hoc additions when ecosystem incidents demand.
10. **Per-project threat-irrelevance declaration** — some threats don't apply (e.g., AT-002 for projects without CI/CD). Recommendation: profile setting `threats.disabled: [AT-002]` with mandatory `reason:`.

## Risks

1. **Catalog becomes shelfware** — entries enumerated but no controls implemented. *Mitigation*: each catalog entry has `status: planned | shipped | dormant` field; dashboard surfaces "planned but unshipped" count; trend tracking.
2. **False positives bounce adoption** — overzealous controls block legitimate work. *Mitigation*: severity tiering; Tier 2 + 3 profile-configurable; retro tracks false-positive rate.
3. **Prevention controls evaded** — agent-class threats by definition exploit autonomy. *Mitigation*: defense-in-depth (prevention + detection + cross-model reviewer + human boundary); no single control is sufficient.
4. **Autonomous-mode security envelope mistakes** — Tier 1 control accidentally bypassed by `--autonomous` due to bug. *Mitigation*: integration tests specifically verifying envelope; fail-closed default; bypass requires explicit codepath.
5. **Empirical-motivation gap leads to wrong threat catalog** — we author scenarios based on speculation, not actual incidents. *Mitigation*: trigger-condition gating; catalog evolution as real incidents emerge; willingness to retire scenarios that don't match reality.
6. **Catalog vs profile disagreement** — profile disables a Tier 2 control, then user complains when threat materializes. *Mitigation*: profile-disabling requires explicit risk acceptance; audit log preserved; not the catalog's fault.
7. **Community contributions degrade quality** — adversaries propose "scenarios" that minimize real threats. *Mitigation*: Specrew core has final authority; sanity-check criteria explicit; high contribution bar.
8. **Threat catalog leaked to attackers reveals defensive blind spots** — controls catalog tells attackers what we check for. *Mitigation*: catalog is public by design (concealing doesn't help); controls are *correct* not *secret*; defense-in-depth.
9. **Maintenance debt grows** — catalog needs ongoing curation. *Mitigation*: explicit owner (Specrew core); quarterly review cadence; community-contributed retros surface needed updates.
10. **Composition complexity with 097 + 099 + 047 + 066** — many proposals interact. *Mitigation*: explicit cross-reference fields; integration tests; composition adapter spec at clarify.

## Cross-references

- **Composes with**:
  - [047 Project Governance Profile](047-project-governance-profile.md) — sets per-project Tier 2/3 control activation
  - [066 Gate-Respecting Default + `--autonomous` Opt-In](066-gate-respecting-default.md) — `--autonomous` mode is where threats are highest; security envelope (Pillar 3) is on top of 066
  - [089 PR Review Integration](089-pr-review-integration-address-pr-review-gate.md) — reviewer findings feed agent-class threat detection
  - [092 Specrew Dashboard Web App](092-specrew-dashboard-web-app.md) — security view consumer
  - [097 Coupling Surface Catalog](097-coupling-surface-catalog.md) — dependency-level findings cross-reference agent-class catalog (AT-001 specifically)
  - [102 Cross-Model Independent Reviewer](102-cross-model-independent-reviewer.md) — mandatory at L2+ for Tier 1 affected PRs in `--autonomous`
- **Trigger conditions**:
  - Near-miss observed in Specrew's own development → bump to Phase 2 immediate
  - Ecosystem incident matching scenarios in catalog → bump to Phase 2 with iteration 1 focused on that pattern
- **Sources**:
  - External research document received 2026-05-22 (raised the agent-class threat categories; this proposal makes them concrete)
  - Memory `project_github_coupling_investigation_2026_05_22` (notes that some agent-class threats compose with git-host concerns)
- **Possibly subsumes** (at clarify time):
  - Subset of Proposal 014 (Red Team Agent) — adversarial review against the catalog is a 099-or-014 task

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to external research document raising agent-class threat categories. Sharpened from categories to 12 concrete named scenarios with severity, blast radius, current detection, proposed control. Preventive-first stance; autonomous-mode security envelope explicit. Trigger-condition gating: ships when near-miss or ecosystem-incident materializes, OR as part of post-Phase-2-stabilization security hardening. Awaiting clarify-time decisions on catalog publicness, control granularity, and severity-tier configurability.
