---
proposal: 122
title: Dependency-Report Enrichment via Registry Queries
status: candidate
phase: phase-2
estimated-sp: 8-12
priority-tier: 2
discussion: surfaced during 2026-05-25 PlanningPoC iter-001 review; current dependency-report.md is shallow (passes validator but doesn't deliver audit value its name implies); user-confirmed methodology gap; ~30 production files reference `gh` per coupling investigation memory
---

# Dependency-Report Enrichment via Registry Queries

## Why

Every Specrew project's iteration ships a `dependency-report.md` reviewer-artifact. Today the artifact has 5 columns: Ecosystem, Package, Version, Owning Task(s), Notes. The "Vulnerability Review" section is typically a no-op ("No dedicated vulnerability scan output was captured"). The artifact passes validator but doesn't deliver the audit value its name implies.

Missing data points that an actual dependency audit requires:

- **License** (MIT, Apache 2.0, GPL, proprietary, etc.) — load-bearing for OSS-compliance audits and downstream usage decisions
- **Latest version** (current vs latest comparison, like `Update-Module` pattern) — surfaces whether the project is on a stale dependency
- **Known issues / CVE** — security audit critical surface; OSV database or registry security advisories
- **Organization source** (Microsoft, OSS community, vendor, individual) — provenance / trust signal
- **GitHub or canonical-source URL** — link to the project so reviewer can investigate provenance

This is another form-vs-meaning bug ([[proposal-030]]): the file exists with valid markdown, but it doesn't deliver the value its name implies.

Every Specrew project's dependency-report.md shares the same gap. Gathering this data requires the agent to query official sources (npm registry, NuGet catalog, PyPI, Cargo registry, GitHub API, OSV database, etc.).

## What

Three composable pillars. Ship together unless effort forces a split.

### Pillar 1: Enriched template + scaffolder (~2 SP)

Extend `dependency-report.md` template (in `scaffold-reviewer-artifacts.ps1` mirror) with the 5 new columns + structured Vulnerability Review section:

```markdown
| Ecosystem | Package | Version | Latest | License | Source Org | Canonical URL | CVE / Advisories | Owning Task(s) | Notes |
|---|---|---|---|---|---|---|---|---|---|

## Vulnerability Review

| CVE / Advisory ID | Severity | Affected Package + Version Range | Fixed In | Status (open / mitigated / not-applicable) | Decision Rationale |
|---|---|---|---|---|---|
```

### Pillar 2: Reviewer skill `specrew-dependency-research` (~4-6 SP)

A new Reviewer skill that the Reviewer invokes at review-boundary time. The skill takes the dependency list from the iteration's manifest changes (npm `package.json` diff, NuGet `.csproj` diff, Cargo `Cargo.toml` diff, Python `pyproject.toml` diff, PowerShell `*.psd1` diff) and queries:

- **npm registry** (`https://registry.npmjs.org/<pkg>`) for latest version + maintainers + repository URL
- **NuGet catalog** (`https://api.nuget.org/v3/registration5-gz-semver2/<pkg>/index.json`) for similar
- **PyPI JSON API** (`https://pypi.org/pypi/<pkg>/json`)
- **Cargo registry** (`https://crates.io/api/v1/crates/<pkg>`)
- **PowerShell Gallery** (`https://www.powershellgallery.com/api/v2/Packages?$filter=Id eq '<pkg>'`)
- **OSV.dev** (`https://api.osv.dev/v1/query`) for CVE / advisory data across ecosystems
- **License**: derive from registry response (most include `license` field) OR fetch `LICENSE` file from canonical URL

Skill output: a populated `dependency-report.md` table. Manual overrides allowed for offline / paid registries.

### Pillar 3: Validator rule (~1-2 SP)

Soft WARN when iteration manifest changes are detected but `dependency-report.md` is missing required columns or has empty cells in mandatory fields (License, Latest, Source URL):

- `WARN [dependency-report] missing-license-column: dependency-report.md schema does not include License column; downstream OSS-compliance audit cannot proceed`
- `WARN [dependency-report] empty-license-cell: <pkg> license cell is empty; run /specrew-dependency-research to populate`

Soft WARN — does not block boundary advancement; surfaces the gap visibly.

## How

| Step | File | Effort |
|---|---|---|
| Pillar 1 template + scaffolder update | `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` (+ mirror) | 2 SP |
| Pillar 2 skill implementation per ecosystem | `extensions/specrew-speckit/scripts/specrew-dependency-research.ps1` (new) + per-ecosystem helpers | 4-6 SP |
| Pillar 2 skill deployment to host catalogs | `.claude/skills/specrew-dependency-research/SKILL.md`, `.github/skills/`, `.agents/skills/` | 0.5 SP |
| Pillar 3 validator rule | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror) | 1-2 SP |
| Integration tests + mock registry responses | `tests/integration/dependency-report-enrichment.tests.ps1` (new) | 1-2 SP |
| Reviewer charter directive (invoke skill at review boundary) | per-host charter templates | 0.5 SP |

Total ~8-12 SP. Phase 2.

## Acceptance criteria

- **AC1**: Fresh scaffolded `dependency-report.md` contains the 10-column table including License, Latest, Source Org, Canonical URL, CVE / Advisories
- **AC2**: Running `/specrew-dependency-research` against an iteration with npm/NuGet/PyPI changes populates the table from registry queries
- **AC3**: Registry-query failures (offline / 404 / rate-limited) are handled gracefully — failed cells show `(unavailable)` with a note; do NOT abort the skill
- **AC4**: OSV.dev query returns CVE entries for affected version ranges; populated into Vulnerability Review section with severity + status
- **AC5**: Validator emits WARN when manifest changes are detected but License column missing or empty in mandatory cells
- **AC6**: Mirror parity preserved
- **AC7**: Skill respects manual overrides — if a cell is hand-populated, skill does not overwrite without explicit `--force` flag
- **AC8**: Skill caches registry responses for 24h in `.specrew/dependency-research-cache.json` to reduce repeat-query cost

## Out of scope

- **Automated CVE-fix PR generation** — that's a Dependabot/Renovate scope; out
- **License-compatibility analysis** (e.g., GPL-incompatible with MIT) — surface raw licenses; downstream tooling owns compatibility
- **Paid registries** (private NPM, Azure DevOps NuGet feeds) — manual entry only in v1; can add per-registry auth as follow-up
- **Non-package dependencies** (system tools, OS packages, runtime versions) — out of scope; could be a sibling proposal
- **Real-time CVE monitoring** — registry queries are snapshot at iteration time; not a continuous watch

## Composition

- **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning)** — this IS a form-vs-meaning fix at the artifact-content level
- **Proposal 042 (Specrew Integration Test Suite)** — needs registry-query test coverage; this proposal composes
- **Proposal 052 (Specrew Profile System)** — per-profile dependency conventions (e.g., publishing profile cares about license; security profile cares about CVE)
- **Proposal 097 (Coupling Surface Catalog)** — adjacent; 097 covers the broader coupling map, 122 covers the per-iteration dependency snapshot
- **Proposal 067 (Small-Fix Slice Type)** — too big for small-fix; this is a full small Phase 2 feature

## Risks

- **Registry API rate limits** — Mitigation: 24h cache + exponential backoff + skill --offline mode
- **Registry API churn** (URL changes, schema changes) — Mitigation: per-ecosystem adapter pattern; version-pin adapter contracts
- **Slow boundary advancement** — registry queries take seconds per package — Mitigation: skill is opt-in at Reviewer discretion; default scaffolder template is unchanged unless skill invoked
- **License detection ambiguity** — some packages have license in README only, not in registry metadata — Mitigation: fall back to GitHub raw `LICENSE` file fetch; if still ambiguous, mark `(license-ambiguous, see canonical URL)`
- **CVE data lag** — OSV.dev has delay between disclosure and inclusion — Mitigation: emit "as-of timestamp" alongside CVE results; reviewer interprets

## Empirical motivation

2026-05-25 PlanningPoC iter-001 review surfaced this when the user inspected the dependency-report.md and noted "the dependency report should also bring information from the actual library (npm, NuGet, PyPI etc.) about license, latest version, known issues, the organization that owns the library, the GitHub or other source URL of the library." Memory captured at [[planning-poc-findings-2026-05-25]] with the 5 missing fields enumerated.

Pattern is universal: every Specrew-governed project shares this same gap. Shipping the enrichment lifts dependency-report.md from a placeholder artifact to a real audit surface.

## Cross-references

- file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- file:///C:/Dev/Specrew/proposals/042-specrew-integration-test-suite.md
- file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md
- file:///C:/Dev/Specrew/proposals/097-coupling-surface-catalog.md
- file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md
- Memory: [[planning-poc-findings-2026-05-25]]

## Status history

- 2026-05-25: gap surfaced during PlanningPoC iter-001 review with user-enumerated missing fields.
- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep.
