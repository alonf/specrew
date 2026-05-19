---
proposal: 052
title: Specrew Profile System (Methodology Core + Domain Profile Composition)
status: candidate
phase: phase-3
estimated-sp: 35
discussion: tbd
---

# Specrew Profile System (Methodology Core + Domain Profile Composition)

## Why

Specrew today is positioned as **methodology for the feature-development lifecycle** (specify → clarify → plan → tasks → implement → review → retro → closeout). That's a powerful and distinctive scope. But software delivery has at least 8 other concern domains where AI-assisted decision-making would benefit from the same governance pattern:

- **Publishing**: README, LICENSE, CHANGELOG, code of conduct, package registry distribution
- **Hosting / Infrastructure**: IaC, network config, environment configs
- **DevOps / CI-CD**: build pipelines, deployment specs, release management
- **Operations / SRE**: runbooks, dashboards, alerts, SLOs, incident response
- **Security**: threat models, security scans, IAM, dependency vulnerability management
- **Compliance**: evidence packets, audit logs, controls (SOC2, HIPAA, PCI, GDPR, etc.)
- **Documentation**: user docs, API specs, tutorials, internal wikis
- **Support**: issue templates, response workflows, community moderation

Each concern has its own decisions, artifacts, boundaries, validators, and retrospectives. Each is a place where AI can produce form-correct outputs that miss meaning. Each would benefit from Specrew's governance pattern (boundary discipline, validators, decision-logs, retros, substantive-interaction-model). But trying to absorb all of them into Specrew core would dilute the methodology and create severe maintenance burden.

This proposal resolves the tension via **layer separation + a profile system**: Specrew core stays narrow and focused on methodology, while domain-specific content lives in opt-in profiles that compose with the core.

## The dilemma: narrow vs broad Specrew

Before proposing the architecture, this proposal explicitly records the strategic decision so future scope-creep arguments can be evaluated against it.

### Two possible Specrews considered

**Specrew A — Narrow**: methodology for feature-development lifecycle only. Other concerns out of scope; users handle them with specialized tools (Terraform, GitHub Actions, Snyk, etc.).

**Specrew B — Broad**: governance meta-framework for AI-assisted decision-making across the entire software delivery lifecycle. Every concern domain has its own boundaries, validators, decision-logs, and retros, all sharing the same underlying methodology pattern.

### Why both have merit

**Specrew A pros**: focused, distinctive, manageable scope; methodology core remains clean; specialized tools are better at their domains; lower opinion-concentration risk.

**Specrew A cons**: users still need 7+ other tools to govern the rest of delivery; the AI-governance gap exists everywhere AI produces outputs, not just feature code; competitors with broader scope could subsume Specrew's narrow scope.

**Specrew B pros**: captures the universal AI-governance value across all delivery; profile composition is a powerful product model; community/ecosystem can contribute profiles; positions Specrew as a meta-framework, not a tool.

**Specrew B cons**: scope-creep risk; opinion concentration on LICENSE choices, IaC frameworks, alerting philosophies; profile maintenance compounds; Specrew might become a half-baked alternative to specialized tools in each domain.

### Resolved direction (this proposal)

**Specrew core stays narrow. The profile system makes Specrew extensible to broad governance.**

Specifically:

- Specrew core stays focused on methodology pattern: lifecycle, boundaries, validators, decision-logs, retros, substantive-interaction-model
- A profile system defines extension points that opt-in profiles can plug into
- Specrew core authors 1-2 anchor profiles (likely `open-source-library` and `psgallery-publishing`) to prove the system works
- Community / ecosystem authors domain-specific profiles for DevOps, hosting, SRE, security, compliance, etc.
- Specrew explicitly does NOT replace specialized tools — profiles add the governance layer on top of Terraform/PagerDuty/Snyk/etc., they don't replace those tools

This preserves Specrew's distinctive value (the methodology pattern) while opening a path for broad governance coverage without scope creep into the core.

## What

### The universal pattern

The methodology pattern Specrew has built for feature work is **content-agnostic**. It applies wherever AI-assisted decision-making needs governance:

| Pattern (universal) | Feature-work content | Deployment content | Incident content |
|---|---|---|---|
| Boundary discipline | specify/plan/implement/review boundaries | deploy-readiness gate, canary gate | incident detection, response, recovery, postmortem |
| Validators | spec validator, before-implement gate, validator-hardening rules | IaC schema check, security scan, SLO check | runbook coverage check, on-call rotation check |
| Decision logs | architecture decisions, scope decisions | deployment decisions, capacity decisions, vendor decisions | incident response decisions, SLA breach decisions |
| Retrospectives | per-iteration retro, per-feature retro | per-deployment retro, per-release retro | per-incident postmortem |
| Substantive interaction model | feature scope, design choices | deployment scope, rollback strategy | incident severity, response priority |

Each row is a methodology pattern. Each column is a domain. The cells are profile content.

### The profile architecture

A profile is a structured extension that contributes to Specrew core at well-defined hooks:

#### Profile manifest

Each profile ships as a directory containing:

```
profiles/<profile-name>/
├── profile.yml              # Manifest: name, version, description, hooks declared
├── templates/               # Template files for `specrew init` scaffolding
│   ├── README.md.template
│   ├── LICENSE.template
│   └── ...
├── validators/              # Validator rules to add at lifecycle stages
│   ├── before-publish-check.ps1
│   └── ...
├── lifecycle-hooks/         # Scripts that fire at lifecycle boundaries
│   ├── on-feature-closeout.ps1
│   └── ...
├── decision-conventions.yml # Decision-log entry conventions for this domain
├── retro-templates/         # Retrospective templates this profile contributes
└── docs/                    # Profile-specific documentation
```

#### Extension points (hooks)

Specrew core exposes a fixed, versioned set of extension points. Profiles bind to these:

| Hook | When it fires | Profile responsibility |
|---|---|---|
| `on-init` | At `specrew init` | Scaffold template files into the new project |
| `on-update` | At `specrew update` | Migrate templates while preserving user edits |
| `on-boundary-<name>` | At each lifecycle boundary | Validator rules to run, artifacts to generate |
| `on-feature-closeout` | At feature-closeout | Per-feature artifacts (e.g., CHANGELOG entry, release notes) |
| `on-iteration-closeout` | At iteration-closeout | Per-iteration artifacts |
| `on-decision-log` | When decision-log entry created | Validate against profile conventions |
| `on-retro` | At retro boundary | Profile-specific retro template + corpus contribution |
| `on-validator-run` | When validators execute | Profile-specific rule injection |

Profiles declare which hooks they bind to. Core invokes hooks in declared order. Multiple profiles can bind to the same hook (composition).

#### Profile selection at init

```bash
# Single profile
specrew init --profile=open-source-library

# Multiple profiles (composition)
specrew init --profile=open-source-library --profile=psgallery-publishing --profile=devops-github-actions

# Interactive (per proposal 047 governance dial pattern)
specrew init  # prompts for profile selection from catalog

# From a saved bundle
specrew init --bundle=specrew-default  # bundle = curated multi-profile composition
```

### Initial profile catalog (planned, not all built)

Authored by Specrew core (anchor profiles):

| Profile | Domain | First-cut scope | Effort |
|---|---|---|---|
| `open-source-library` | Publishing | README, LICENSE, CHANGELOG, code of conduct, contribution guide | ~10 SP |
| `psgallery-publishing` | Publishing | PSGallery-specific: manifest validation, version bump rules, publish workflow | ~6 SP |

Authored by community / ecosystem (candidate profiles — NOT in initial Specrew scope):

| Profile | Domain | Sketch |
|---|---|---|
| `devops-github-actions` | DevOps / CI-CD | Workflow templates, deploy boundaries, release-management governance |
| `devops-azure-pipelines` | DevOps / CI-CD | Azure DevOps equivalent |
| `hosting-terraform-aws` | Hosting | IaC governance, plan-vs-apply boundaries, drift detection |
| `hosting-pulumi-azure` | Hosting | Pulumi+Azure equivalent |
| `sre-slo-management` | Operations | SLO definitions, error-budget governance, incident-response retros |
| `sre-on-call` | Operations | On-call rotation governance, runbook standards, postmortem templates |
| `security-supply-chain` | Security | SBOM governance, dependency-update boundaries, vulnerability-response retros |
| `security-iam-baseline` | Security | IAM policy validation, least-privilege governance |
| `compliance-soc2` | Compliance | Evidence-collection governance, control attestation, audit-prep workflow |
| `compliance-hipaa` | Compliance | HIPAA-specific controls, BA management |
| `documentation-readthedocs` | Documentation | Docs build/deploy governance, doc-vs-code drift detection |
| `documentation-api-spec` | Documentation | OpenAPI/protobuf governance, spec-driven-client generation |
| `support-issue-triage` | Support | Issue template governance, SLA-aware triage |

The catalog is illustrative, not a commitment. Profiles emerge when real users need them; Specrew core authors only the anchors.

### Effort

**Iteration 1 (Profile System Foundation): ~20 SP**

- Profile manifest schema + parser
- Extension-point definition + invocation engine
- `specrew init --profile=` and `specrew update --profile=` flag support
- Profile composition logic (multi-profile, ordering, conflict resolution)
- Tests for the profile system
- Documentation: `docs/profile-system.md` + author guide
- Refactor existing Specrew internal artifacts to NOT depend on profile-specific concerns (separation enforcement)

**Iteration 2 (Anchor Profiles): ~15 SP**

- Author `open-source-library` profile (~10 SP)
- Author `psgallery-publishing` profile (~6 SP) — composes with `open-source-library`
- Migrate Specrew's own repo to use both profiles (dogfooding)
- Tests for both profiles
- Documentation: per-profile README + integration guide

**Combined estimate: ~35 SP across 2 iterations.**

Community profiles add per-profile effort but happen outside this proposal.

## Phase placement

**Phase 3 (Runtime Abstraction & Spec Fidelity).** The profile system is architectural foundation work. It belongs alongside Multi-Host Runtime Abstraction (Proposal 024) as core extensibility infrastructure — both define how Specrew composes with external systems.

Sequencing rationale:

- Phase 2 (current): finish methodology hardening, ship the post-F-020 queue (032, 046+048, 049+050, 047, 051)
- Phase 3: ship the two big extensibility features (024 Multi-Host CORE, 052 Profile System) together; they share architectural patterns
- Phase 4+: per-profile features as needed

## Open questions

1. **Profile versioning + compatibility**: how do profiles declare compatibility with Specrew core versions? Likely a `min_specrew_version` field in the manifest plus per-hook versioning.
2. **Profile conflict resolution**: when two profiles bind to the same hook with conflicting behavior (e.g., one wants strict validator severity, another wants relaxed), how does Specrew resolve? Likely explicit priority field + last-profile-wins fallback.
3. **Profile discovery + distribution**: where do profiles live? Inline in Specrew repo for anchors; community profiles published to PSGallery as separate modules? GitHub topic-based discovery? Curated catalog file in Specrew repo?
4. **Profile authoring + review**: who can author profiles? Specrew core for anchors; community PRs for additions? RFC process for proposed profiles?
5. **Composition with proposals 044 (stack quality) + 047 (governance profile)**: stack-aware quality and governance profile are also init-time opt-in systems. Should they be unified under the profile system, or kept separate? Recommend unified — all three become "profiles" with different hook-binding patterns.
6. **Profile deprecation policy**: when a profile is abandoned by its author, how does Specrew handle? Deprecation flag, fork policy?
7. **Profile testing**: each profile needs its own test suite. Does Specrew core provide a testing framework, or does each profile author choose?
8. **Profile certification**: do "official" profiles vs "community" profiles get different visibility/trust signals?
9. **Profile-vs-extension distinction**: Spec Kit calls its plugins "extensions"; Squad calls them "skills". Specrew's profiles are different — should we use a different word entirely to avoid confusion? "Module"? "Pack"? "Profile" is OK but a bit overloaded.
10. **Profile interaction with Multi-Host CORE (Proposal 024)**: if Squad and Claude Code both invoke the same profile, does the profile work identically? Likely yes — profiles should be host-neutral.

## Risks

- **Scope creep through profile growth**: even if core stays narrow, profile bloat could erode the "Specrew is methodology" identity. Mitigation: maintain strict separation between core and profiles in messaging + docs; profile catalog is explicitly "ecosystem", not "Specrew product".
- **Opinion concentration in anchor profiles**: the open-source-library profile carries opinions about LICENSE choice, code of conduct templates, etc. Mitigation: anchor profiles ship with multiple template variants where opinions diverge; users select at init.
- **Profile maintenance burden**: profiles need to keep pace with their domain's evolution. Mitigation: clear authoring + ownership model; deprecate stale profiles explicitly; ecosystem-led for non-anchor profiles.
- **Extension-point versioning rot**: as Specrew core evolves, extension points might need to change. Profiles depending on old extension points break. Mitigation: semver the extension-point API; deprecation periods; migration guide.
- **Composition complexity**: multi-profile composition can produce unexpected interactions. Mitigation: explicit conflict-resolution rules; profile-author guidance on composition; "incompatible profiles" detection at init.
- **Half-baked profiles diluting Specrew's quality reputation**: a poorly authored community profile could create the impression that Specrew itself is poorly governed. Mitigation: certification model for "official" profiles; clear community-vs-official distinction; quality bar for anchor profiles.
- **Bandwidth diversion from core methodology work**: profile system work could displace core methodology improvements. Mitigation: explicit phase placement (Phase 3) ensures core methodology lands first.

## Cross-references

- **Proposal 024 (Multi-Host Runtime Abstraction)** — sibling Phase 3 extensibility feature; profiles must be host-neutral so they work across Squad/Claude/Codex
- **Proposal 044 (Downstream Quality Baseline Bootstrap)** — likely subsumed into the profile system as a "stack-aware quality" profile; resolves the open question of where stack-detection logic lives
- **Proposal 047 (Project Governance Profile)** — composes with this system; governance preferences become hook-binding declarations within the active profile set
- **Proposal 014 (Red Team Agent)** — could ship as a security/compliance profile rather than a Squad role
- **Proposal 023 (Reactive Specialist Lifecycle)** — composes; specialists may be profile-contributed rather than core
- **Proposal 015 (Expertise-Aware Adaptive Interaction)** — orthogonal; expertise inference is per-user, profiles are per-project
- **F-015 (Public-Readiness Pass)** — historical: F-015 IS the prototype for the `open-source-library` profile. Iteration 2 of this feature extracts and generalizes that work.

## Status history

- 2026-05-18: candidate captured after maintainer raised the strategic question: should Specrew govern publishing, hosting, DevOps, and other delivery concerns, or is the surface too varied for methodology? The reframe is that the methodology pattern is universal but content is context-specific. Resolved direction: narrow methodology core + extensible profile system. Anchor profiles authored by Specrew core (open-source-library, psgallery-publishing); ecosystem profiles authored by community.
