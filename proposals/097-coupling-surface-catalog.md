---
proposal: 097
title: Coupling Surface Catalog (Mandatory Dependency Inventory + Hygiene + Risk Surface)
status: candidate
phase: phase-2
estimated-sp: 18-25 (MVP); 30-40 (full vision across iterations)
discussion: ad-hoc 2026-05-22 session
---

# Coupling Surface Catalog (Mandatory Dependency Inventory + Hygiene + Risk Surface)

## Why

Every non-trivial software solution couples to external things: hosting providers, runtime versions, package dependencies, third-party APIs, DNS names, OS-level tooling, service URLs, license terms, commercial vendors. **Each coupling is a constraint, a risk, and a maintenance cost.** Specrew today has no first-class mechanism to catalog these couplings, assess them, or surface their changes — they live implicitly across `package.json`, `*.psd1`, `Dockerfile`, environment configuration, hardcoded URLs, agent skill templates, and tribal knowledge.

The 2026-05-22 GitHub-coupling investigation memory is one concrete instance of this gap: ~30 production files reference `gh` (GitHub CLI), some of it intentional, some of it accidental, with intent-vs-implementation drift documented in specs but no central catalog tracking which couplings exist, how deep they go, or whether their upstream is healthy.

User-stated motivation (2026-05-22):

> "Coupling surface: What are the mandatory couplings of the solution: hosting, tools, packages, URLs, DNS names, OS versions, services versions, maybe more. For each coupling, we need information and implications: versioning, is there a new version, is it obsolete, licenses and are we following the licensing rules, known issues from the community, the organization that is responsible for the coupled source, known security vulnerabilities. Level of coupling - small, medium large portion of the system relay on it."

Empirical instances where the absence of a coupling catalog has cost:

- **GitHub CLI drift** (audited 2026-05-22, captured in `project_github_coupling_investigation_2026_05_22` memory) — coupling grew across ~30 files implicitly; no central record of "we depend on `gh`"; intent docs say multi-host but code increasingly assumes GitHub
- **Copilot pricing pivot** (May 2026) — cost surprise because the magnitude of Copilot quota usage wasn't tracked as a coupling cost; Proposals 068/069/070 emerged reactively
- **PowerShell Gallery distribution** (F-019 closeout) — coupling to PSGallery's signing/unsigning behavior surfaced as a bug (Proposal 072) when defaults changed; no entry in any catalog said "we depend on PSGallery's default-signature-policy"
- **Squad CLI version pinning** (`squad-cli` npm package) — Specrew's own runtime; no catalog row tracks which Squad version Specrew tests against, which is current, which is supported
- **Markdownlint-cli + node version assumptions** baked into pre-commit hooks (Proposal 088) — coupling implicit in shell invocations; no catalog row
- **`gh discussion create` mechanism** (my Proposal 093 draft) — assumes GitHub Discussions exists; no catalog row tracks "Specrew tooling assumes GitHub Discussions when proposal-driven-design profile is active"

**Strategic framing**: this proposal is the **factual surface** ("here's what we couple to"). Proposal 091 (Tech Debt Control) is the **consequence surface** ("here's debt we owe"). A finding from the coupling catalog — outdated version, license issue, CVE — flows into 091's debt ledger as an entry. The catalog is a *source of truth*; 091 is the *workflow that acts on findings*.

The goal is not to eliminate coupling — every useful system couples to something. The goal is to make coupling **visible, queryable, and assessable**, so the team can make deliberate decisions rather than discover constraints during incidents.

## What (5 Pillars)

### Pillar 1 — Coupling-Surface Ledger (`.specrew/coupling-surface.md`)

Structured per-entry ledger, parallel in shape to Proposal 091's tech-debt ledger. Each entry captures the dimensions the user named plus the additions identified during this proposal's design.

| Field | Purpose | Example |
|---|---|---|
| `id` | Stable ID (`coupling-001`, `coupling-002`, …) | `coupling-014` |
| `name` | Human-readable identifier | "GitHub CLI (`gh`)" |
| `category` | `hosting` / `runtime` / `package` / `service-api` / `dns-name` / `os-level-tool` / `service-version` / `cli-tool` / `license` / `vendor` / `cloud-resource` / `agent-runtime` / `git-host` | `cli-tool` |
| `upstream` | Maintaining organization or person | "GitHub, Inc." |
| `homepage` | URL of canonical project / docs | `https://cli.github.com/` |
| `version-current` | Version we use today | `2.45.0` |
| `version-latest` | Latest released version (auto-fetched) | `2.49.1` |
| `version-status` | `current` / `behind-minor` / `behind-major` / `obsolete` / `pre-release` | `behind-minor` |
| `license` | License identifier (SPDX) | `MIT` |
| `license-compliance` | `compliant` / `non-compliant` / `unclear` / `unverified` | `compliant` |
| `security-cves` | Open CVEs affecting our pinned version | `[]` or list with severity |
| `coupling-level` | `small` / `medium` / `large` portion of system | `medium` (the GitHub-coupling investigation found ~30 files) |
| `failure-mode` | What happens if dependency disappears / breaks | `feature-degraded` (PR review integration falls through) |
| `replaceability` | `trivial` / `moderate` / `hard` / `effectively-impossible` | `moderate` (would need `glab`/`bb` per host adapter) |
| `coupling-pattern` | `direct-call` / `adapter-wrapped` / `sdk-wrapped` / `config-only` / `runtime-fetched` | `direct-call` (no adapter; each callsite invokes `gh` directly) |
| `trust-level` | `first-party` / `well-maintained-oss` / `community-maintained` / `single-maintainer` / `unmaintained` / `commercial-vendor-with-sla` | `well-maintained-oss` |
| `cost-rate-limits` | $-cost per usage; quota implications | `free-tier; rate-limited at 5000 API req/hour` |
| `data-sensitivity` | What data crosses this boundary; sensitivity level | `code-and-repo-metadata; medium-sensitivity` |
| `sovereignty` | Geographic / jurisdictional implications | `US-hosted; subject to US export controls` |
| `test-surface` | `integration-tested` / `mocked-only` / `untested` | `mocked-only` |
| `reversibility-under-outage` | `seamless` / `degrades-feature` / `breaks-build` / `hard-blocked` | `degrades-feature` |
| `eol-signals` | Has provider announced sunset? Migration path? | `none-as-of-2026-05-22` |
| `update-cadence` | How often releases happen + our lag | `~monthly minor releases; we are 2 versions behind` |
| `first-introduced` | Feature/commit/date this coupling first entered | `feature-001 (2026-04-15)` |
| `decision-provenance` | Was this a deliberate choice or drift? Alternatives considered? | `deliberate; considered glab + bb; chose gh for ecosystem maturity` |
| `community-trajectory` | `growing` / `stable` / `shrinking` | `stable` |
| `known-issues` | Community-flagged pain points relevant to our usage | `gh discussion create requires repo-level Discussions enabled` |
| `related-debt` | Cross-references to debt entries (Proposal 091) | `[debt-007, debt-014]` |
| `notes` | Free-text context | … |

**The schema is large by design** — the catalog answers many different questions, and lightweight catalogs that omit dimensions tend to be re-built when those dimensions are needed. Optional fields can be omitted; the validator distinguishes "required" (id, name, category, upstream, version-current, license, coupling-level) from "recommended" from "optional."

### Pillar 2 — Collection Mechanisms

Couplings enter the catalog through five channels (parallel structure to Proposal 091):

**2a. Auto-detection adapters** (the heaviest mechanism)

Specrew aggregates output from existing scanners rather than reinventing them. Initial adapter set:

| Adapter | Detects | Source tool |
|---|---|---|
| `npm-adapter` | npm packages + versions + licenses + CVEs | `npm ls --json`, `npm audit --json`, `license-checker` |
| `dotnet-adapter` | NuGet packages | `dotnet list package --vulnerable --include-transitive --format json` |
| `pip-adapter` | Python packages | `pip-audit --format json`, `pip list --format json` |
| `cargo-adapter` | Rust crates | `cargo audit --json` |
| `psgallery-adapter` | PowerShell modules | `Get-Module -ListAvailable`, manual version check vs gallery |
| `git-remote-adapter` | Git host (GitHub/GitLab/etc.) from `git remote -v` | (composes with the git-host-adapter from the GitHub-coupling investigation memory) |
| `os-tool-adapter` | OS-level CLIs found in scripts (`gh`, `node`, `pwsh`, `python`, `docker`, …) | grep + version probe via `--version` |
| `dockerfile-adapter` | Base images + apt/apk packages | parse Dockerfile FROM + RUN lines |
| `env-var-adapter` | External URLs / DNS names referenced in env or config | scan `.env` examples, `appsettings.json`, etc. |
| `sbom-adapter` | Standard SBOM ingestion (SPDX, CycloneDX) | parse `sbom.json` if present |

Each adapter emits structured entries that get merged into the catalog; manual entries override on conflict. Adapter selection is opt-in via governance profile (composes with Proposal 047).

**2b. Manual entry** (CLI + inline)

`specrew coupling add --category=service-api --name="Anthropic API" --upstream="Anthropic" --coupling-level=large …` for couplings auto-detection cannot catch (third-party API URLs, hardcoded service hostnames, etc.). Any agent or human can invoke during normal work.

**2c. Spec/plan-time declaration**

Composes with Proposal 094 (Documentation Update Discipline): plan-time declaration includes "does this iteration introduce new coupling?" alongside "does this affect docs?" Answer "yes" → new entries auto-added with `first-introduced=<feature>-<iter>`. Catches couplings at the moment they enter the codebase.

**2d. Retrospective ingestion**

Retro template gains a `## Coupling Surface` section. Retro Facilitator reviews any couplings added/removed/escalated during the iteration. Net coupling delta tracked (similar pattern to Proposal 091's tech-debt trend).

**2e. Incident-driven entries**

When something breaks and the root cause is an external coupling (CVE disclosure, vendor outage, license change, version-sunset), a coupling entry is created or updated as part of the incident response. Captures the lesson in durable form.

### Pillar 3 — Currency, Risk, Compliance Detection

**Currency checks** (run at iteration-closeout):

- `version-current` vs `version-latest` → status field auto-computed
- `behind-major` for ≥2 iterations → soft warning surfaced in dashboard + retro
- `obsolete` (provider announced EOL within 6 months) → high-severity entry in tech-debt ledger (Proposal 091 composition)

**Security checks** (run per validator invocation or scheduled):

- Aggregated from adapter outputs (`npm audit`, `pip-audit`, etc.)
- New CVE on a current coupling → immediate hard-warning + auto-debt-entry with `type=security, severity=high|critical`
- Severity-aware: critical CVE blocks merge if `enforce_security_gate: true` in governance profile

**License checks**:

- License recorded per entry; SPDX identifier preferred
- Compliance profile (per Proposal 047 governance profile) defines acceptable licenses
- Non-acceptable license detected → hard warning + manual review required
- License change between versions (e.g., MIT → BSL) flagged at upgrade time

**Sovereignty + EOL signals**:

- Manual entry (auto-detection of sovereignty + EOL is hard); reviewed at retro
- Catalog surfaces aging EOL signals so they're not forgotten

### Pillar 4 — Integration with SDLC + Visibility

**Dashboard section** (composes with Proposal 092):

```text
COUPLING SURFACE
Total: 47 couplings tracked (12 hosting/runtime, 21 packages, 8 service-APIs, 6 OS-tools)
By risk:
  ⚠ 2 critical (CVE-2026-XXXX on coupling-022; license-non-compliant on coupling-009)
  ⚠ 5 behind-major version
  ⚠ 1 EOL signal (coupling-031 sunset announced for 2026-12-31)
By coupling-level:
  large: 6 | medium: 14 | small: 27
Recent additions (last iter): coupling-046 (Anthropic API), coupling-047 (markdownlint-cli)
Recent removals: coupling-039 (old auth middleware retired)
```

**Retro section** (parallel to Proposal 091's tech-debt section):

- New couplings added this iteration
- Couplings removed (debt-reduction signal)
- Currency / CVE / license escalations
- Top-aged behind-major entries
- Recommendation: continue / schedule version-bumps / replace specific coupling

**Charter integration**:

- **Spec Steward** — at clarify, consults couplings relevant to new scope; raises significant couplings to user
- **Planner** — at plan, the docs-impact declaration (Proposal 094) gains a "new coupling?" parallel question; new entries added
- **Implementer** — at execute, sees coupling-related tasks (`[coupling-005-upgrade]`) and references them in commits
- **Reviewer** — at review, checks whether PR introduces *new* coupling not yet cataloged; offers candidate entries
- **Retro Facilitator** — owns retro coupling section + trend tracking

### Pillar 5 — Composition + Output Formats

**Composition with existing proposals**:

- **Proposal 091** (Tech Debt) — coupling findings flow into debt ledger; the GitHub-coupling investigation memory is now a specific catalog-driven exercise
- **Proposal 008** (NFR Governance) — security/compliance NFRs reference coupling-surface entries by ID
- **Proposal 044** (Downstream Quality Baseline Bootstrap) — coupling hygiene is part of the baseline assessment for newly-onboarded projects
- **Proposal 094** (Docs Update Discipline) — coupling changes trigger docs updates (new dependency = README update)
- **Proposal 092** (Dashboard) — primary visualization consumer
- **Proposal 047** (Governance Profile) — profile selects which adapters run + which license set is acceptable + which severity triggers hard gates
- **GitHub coupling investigation** (memory entry) — first concrete application of the catalog; provides the seed entries for git-host-related couplings

**Output formats**:

- Native: `.specrew/coupling-surface.md` (markdown with per-entry YAML frontmatter blocks)
- SBOM export: `specrew coupling export --format=spdx | cyclonedx` for compliance reporting
- CSV export: for non-Specrew consumers
- Dashboard read-only render: via Proposal 092

**Self-applied seeding**:

When this proposal ships, the catalog is seeded with Specrew's known couplings:

- `gh` (GitHub CLI) — medium coupling-level (~30 files); category `cli-tool`; first-introduced feature-001; coupling-pattern `direct-call`; replaceability `moderate`
- PowerShell Gallery — large coupling-level; category `service-api`; coupling-pattern `direct-call`
- squad-cli (npm) — large coupling-level; category `agent-runtime`; coupling-pattern `direct-call` (until Multi-Host Runtime Abstraction Proposal 024 ships)
- Copilot CLI — large coupling-level; category `agent-runtime`; coupling-level large; coupling-pattern `direct-call`
- markdownlint-cli — medium; `cli-tool`
- PowerShell 7.x — large; `runtime`
- Anthropic API (used by Claude Code, indirectly via Claude) — coupling-level small (indirect); category `service-api`
- Node.js (markdownlint + ecosystem) — medium; `runtime`
- npm registry — medium; `service-api`

Initial seed list is illustrative; final list authored at clarify time with user confirmation per entry.

## Functional Requirements (high-level for candidate phase)

- **FR-001**: `.specrew/coupling-surface.md` structured ledger with per-entry YAML frontmatter
- **FR-002**: Required vs recommended vs optional field tiers; validator enforces required fields
- **FR-003**: `specrew coupling add | list | show | update | remove | export` CLI surface
- **FR-004**: Auto-detection adapter framework with initial adapters: npm, dotnet, pip, psgallery, git-remote, os-tool, dockerfile (others as iteration 2+)
- **FR-005**: Currency check at iteration-closeout (auto-compute version-status; flag behind-major)
- **FR-006**: CVE aggregation from adapter outputs; new CVE → auto-debt entry (composes with Proposal 091)
- **FR-007**: License compliance check against profile-defined acceptable-license-set; non-compliant → hard warning
- **FR-008**: Plan-time "new coupling?" declaration (composes with Proposal 094)
- **FR-009**: Retro template `## Coupling Surface` section
- **FR-010**: Dashboard `COUPLING SURFACE` section (composes with Proposal 092)
- **FR-011**: SBOM export (SPDX or CycloneDX) for compliance reporting
- **FR-012**: Agent charter updates (Spec Steward / Planner / Implementer / Reviewer / Retro Facilitator)
- **FR-013**: Self-applied seeding at ship time (Specrew's own couplings catalogued)
- **FR-014**: Composition adapter: catalog findings flow into Proposal 091 debt ledger
- **FR-015**: Documentation: `docs/coupling-surface.md` explains the ledger to downstream-project users

## Out of scope

- **Auto-fix for outdated couplings** — surfacing + recommending only, not auto-upgrading. (Auto-upgrade tooling like Dependabot/Renovate handles execution; this proposal handles inventory + decision support.)
- **Vendor management / contract tracking** — commercial relationships, SLAs, billing — separate concern; could be a future profile
- **Runtime telemetry** (which couplings get hit how often at runtime) — out of scope; static-analysis only at MVP
- **Cross-project coupling correlation** ("project A and project B both depend on coupling X with different versions") — interesting but a Phase 5+ multi-project concern
- **License legal-advice generation** — catalog records facts; legal interpretation is the user's responsibility
- **Adapter coverage for every language ecosystem** — initial set is pragmatic; community adapters can extend

## Effort

- **Iteration 1 — MVP** (~12-15 SP):
  - Ledger schema + file + validator rule for required fields
  - Manual CLI (`add`/`list`/`show`/`update`/`remove`)
  - 3 simplest adapters (`git-remote`, `os-tool`, `psgallery`)
  - Self-applied seeding (~10 entries for Specrew itself)
  - Retro template `## Coupling Surface` section
- **Iteration 2 — Detection + risk** (~10-15 SP):
  - 4 more adapters (`npm`, `dotnet`, `pip`, `dockerfile`)
  - Currency check + behind-major escalation
  - CVE aggregation + auto-debt-entry composition with Proposal 091
  - License compliance check
- **Iteration 3 — Visibility + advanced** (~8-12 SP):
  - Dashboard section (composes with Proposal 092)
  - SBOM export
  - Plan-time declaration (composes with Proposal 094)
  - Agent charter updates
  - Remaining adapters (`cargo`, `env-var`, `sbom`)
  - Sovereignty + EOL manual review surfacing
- **Total**: 30-40 SP across 3 iterations; MVP is 12-15 SP. Realistic range with re-scoping: **~18-25 SP for MVP+detection** if iterations 1+2 are combined.

## Phase placement

**Phase 2 — Tier 1 methodology**. Coupling visibility is core SDLC hygiene. Should ship before significant external adoption (~late summer 2026) so downstream projects encounter the discipline from the start.

Sequencing recommendation:

1. **Ships after Proposal 091 (Tech Debt)** since findings flow into 091's ledger; ordering avoids "where does this debt entry come from?" forward reference
2. **Ships before / alongside Proposal 044 (Downstream Quality Baseline Bootstrap)** since coupling hygiene is part of the baseline
3. **Self-applied** at ship time — Specrew's own ~10 known couplings catalogued as the first instance
4. **GitHub-coupling investigation** (memory entry) becomes the first concrete catalog-driven assessment exercise once this proposal ships

## Open questions

1. **Field count tension** — the schema has ~25 fields per entry; that's a lot. Should iteration 1 ship a thinner schema (10 fields) and expand? Recommendation: ship full schema with clear required/recommended/optional tiering; allow empty fields rather than forcing thin schema.
2. **Adapter testability** — adapters depend on external tools (`npm`, `dotnet`, etc.) being installed on the dev machine. How do we test in CI? Recommendation: each adapter has integration test + skip-if-tool-missing fallback.
3. **Auto-detection vs reality drift** — adapters detect what's installed, but couplings can be implicit (hardcoded URLs in code, DNS names in config). Recommendation: adapters cover the easy 70%; manual + spec-time declaration cover the rest; retro catches drift.
4. **Version-latest fetch** — requires network. Run offline mode? Recommendation: cached in `.specrew/.cache/coupling-versions.jsonl`; refresh weekly or on-demand; offline runs use cache.
5. **Composition with Proposal 091 — should coupling findings auto-create debt entries, or just surface in catalog?** Recommendation: critical findings (CVE, license-non-compliant) auto-create; non-critical (behind-minor) just surface in catalog; user decides at retro.
6. **Coupling-level field — automatic or manual?** "Small/medium/large portion of system relies on it" is judgment. Recommendation: manual default; auto-suggest based on file-count heuristic (e.g., the GitHub-coupling audit found ~30 files → suggest "medium").
7. **What's "mandatory" vs "optional" coupling?** User's phrasing was "mandatory coupling." Some couplings could be replaced; others are fundamental. Recommendation: add `mandatory: true|false` field — manual judgment; the GitHub coupling for the gh CLI is "false" (replaceable via adapter); PowerShell coupling is "true" (Specrew IS a PowerShell module).
8. **External-tool overlap (Snyk, Dependabot, Renovate)** — those tools already do CVE detection + version-update PRs. Why not just use them? Recommendation: this proposal *consumes* their output, doesn't replace them. Snyk's CVE feed → catalog entry → Specrew debt ledger. Dependabot PRs trigger version-status updates.
9. **SBOM format choice** — SPDX or CycloneDX? Recommendation: support both; SPDX as default (broader compliance ecosystem).
10. **Coupling vs library distinction** — is jQuery a "coupling" or just a "library"? Recommendation: anything outside the project's own code is a coupling; the catalog tracks all. The granularity is at "package/tool/service" level, not "function call" level.
11. **Cost field** — should the cost dashboard from Proposal 070 (token economy) read from here, or vice versa? Recommendation: 070 owns its data; this proposal references 070's data for the cost field of agent-runtime couplings.

## Risks

1. **Ledger rot** — entries accumulate but get stale. *Mitigation*: aging rules + auto-detected fields refresh + retro discussion + dashboard staleness signal.
2. **False sense of completeness** — if the catalog shows "47 couplings" the user may believe that's all of them, missing implicit ones. *Mitigation*: explicit "auto-detection coverage" indicator; manual-entry encouraged; retro reviews coverage.
3. **Adapter brittleness** — `npm audit` / `dotnet list` output formats change over time; adapters break. *Mitigation*: integration tests per adapter; clear failure messages distinguish "tool not present" vs "format unexpected."
4. **Compliance over-confidence** — license-compliance checks are mechanical (SPDX matching), not legal judgment. *Mitigation*: documentation explicit that this is a *first pass*, not legal advice; consult counsel for material decisions.
5. **Field proliferation** — adding "just one more field" pressure forever. *Mitigation*: schema versioning; clear required/recommended/optional tiers; field additions need proposal-level review.
6. **Catalog vs reality drift** — `version-current` recorded as 2.45.0 but devs upgraded locally to 2.49.0 without updating catalog. *Mitigation*: adapter re-runs at iteration-closeout auto-detect drift and surface it.
7. **Detection runs slow** — running every adapter every iteration adds CI time. *Mitigation*: cache; cheap adapters per validator run; heavy ones at iteration-closeout (composes with Proposal 086 perf bundle).
8. **Sovereignty + EOL fields require manual entry that nobody does** — these are valuable but invisible. *Mitigation*: retro template prompts for them; aging-bump signals when they're missing on high-coupling entries.
9. **Privacy concern with cost field** — recording cost-per-usage is sensitive in some org contexts. *Mitigation*: cost field optional; per-profile setting controls visibility.
10. **Composition complexity with debt (091) creates duplicate entries** — same CVE creates a coupling-surface entry + a debt-ledger entry. *Mitigation*: explicit `related-debt` field cross-references; dashboard de-duplicates when rendering.
11. **External-tool adapter API costs** — some scanners (Snyk paid tier, GitHub Advisory Database) have rate limits or costs. *Mitigation*: free-tier-first adapters; paid adapters opt-in per profile.

## Cross-references

- **Composes with**:
  - [091 Technology Debt Control](091-tech-debt-control.md) — primary downstream consumer; coupling findings flow into debt ledger
  - [008 NFR Governance](008-nfr-governance.md) — security/compliance NFRs reference catalog entries
  - [044 Downstream Quality Baseline Bootstrap](044-downstream-quality-baseline-bootstrap.md) — coupling hygiene is part of baseline assessment
  - [047 Project Governance Profile](047-project-governance-profile.md) — profile selects adapters + acceptable licenses + severity thresholds
  - [070 Token Economy MVP](070-token-economy-mvp.md) — supplies cost data for agent-runtime couplings
  - [086 Validation Pipeline Performance Bundle](086-validation-pipeline-performance-bundle.md) — caching pattern for adapter runs
  - [092 Specrew Dashboard Web App](092-specrew-dashboard-web-app.md) — visualization consumer
  - [094 Documentation Update Discipline](094-documentation-update-discipline.md) — plan-time declaration alignment
- **Provides foundation for**:
  - GitHub-coupling investigation (memory: `project_github_coupling_investigation_2026_05_22`) — becomes the first catalog-driven assessment exercise; provides the seed for git-host-related couplings
  - Future git-host-adapter proposal — would be motivated by catalog entries showing high coupling-level on `gh` with low replaceability
- **Sibling consideration**:
  - **Vendor-management profile** (not yet drafted) — commercial relationship tracking; complements but distinct from this proposal
- **Related precedents**:
  - SBOM standards (SPDX, CycloneDX) — interop format we read/emit
  - Snyk / Dependabot / Renovate — external tools we aggregate from

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to user observation that Specrew has no first-class mechanism to track its coupling surface (hosting, tools, packages, URLs, DNS, OS, services, etc.) with versioning, license, security, community-health, and coupling-level dimensions. Strategic framing: this proposal is the *factual surface*; Proposal 091 is the *consequence surface*. GitHub-coupling investigation memory becomes the first concrete catalog-driven assessment. Awaiting clarify-time decisions on schema thickness, adapter scope, composition with external tools, and self-applied seed list.
