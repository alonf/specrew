---
proposal: 187
title: Volatile Runtime Dependency Monitoring
status: candidate
phase: phase-2
estimated-sp: 8-13
priority-tier: 1
discussion: surfaced 2026-06-12 during Feature 174 review after transcript capture and resume enrichment began depending on AI-host hook payloads and transcript file formats. The maintainer called out that ordinary dependency review is not enough for empirical or private runtime contracts that can change without a package update.
---

# Volatile Runtime Dependency Monitoring

## Why

Some dependencies are not packages, services, or documented APIs. They are
runtime behaviors that a project discovers empirically and then starts relying
on:

- AI host hook payload fields;
- transcript or conversation file formats;
- CLI event ordering;
- undocumented environment variables;
- private cache/state paths;
- provider-specific headless modes;
- "works today" behavior in hosted tools that is not a stable public contract.

These dependencies are more dangerous than ordinary package dependencies
because they can break without a lockfile diff, dependency update PR, release
note, or compile error. They often fail as silent degradation: capture becomes
empty, resume context becomes stale, a hook no-ops, or an agent reports success
while relying on a missing provider field.

Feature 174 makes the problem concrete. Conversation capture can enrich
handover and resume by reading host-provided transcript surfaces, but the
stable truth for resume must remain Specrew artifacts, git state, and validated
handover files. If Codex, Claude, Copilot, Cursor, or another host changes its
hook payload or transcript format, Specrew should degrade visibly and report
the risk, not silently treat the stale or missing host surface as authoritative.

Existing Specrew proposals cover adjacent ground:

- Proposal 062 records dependency reasons and impact propagation.
- Proposal 097 catalogs broad coupling surfaces.
- Proposal 164 records risk and mitigation.
- Proposal 178 chooses verification strategy.
- Proposal 181 covers live cross-host behavior checks.
- Proposal 145 verifies evidence and conformance.

The missing surface is a named dependency class for volatile runtime contracts:
contracts that can be useful, but must be monitored, bounded, and prevented
from becoming hidden lifecycle truth.

## What

Add a first-class risk class: `volatile-runtime-dependency`.

A volatile runtime dependency is any external runtime behavior where at least
one of these is true:

- the contract is undocumented, private, empirical, preview, or provider-owned;
- the project depends on runtime output shape instead of a versioned artifact;
- the dependency can change outside the project's package/update workflow;
- breakage can be silent, partial, or hard to distinguish from normal empty
  data;
- the dependency is used by an AI host, automation host, or platform runtime
  whose behavior is not under project control.

The core rule:

> Volatile runtime dependencies may enrich, accelerate, or observe. They must
> not become authoritative for lifecycle truth unless the project has an
> explicit fallback, monitor, owner, and accepted risk record.

For Specrew, this means host transcript capture can improve handover quality,
but resume truth stays anchored in git, Specrew artifacts, handover files, and
validator output. For downstream projects, the same rule applies to any
workflow that reads private provider state, tool caches, live hosted outputs,
or undocumented automation payloads.

## Dependency Record

Extend dependency/coupling/risk artifacts with a compact volatile-runtime
record. The exact storage can be finalized during specification, but V1 should
support both project-level and feature-level records:

- `.specrew/monitors/volatile-dependencies.yml` for project-wide monitors.
- `specs/<feature>/risk-register.yml` entries for feature-specific risks.
- `specs/<feature>/dependency-report.md` as the human-readable review surface.
- `specs/<feature>/verification-strategy.yml` for required proof cadence.

Example:

```yaml
id: host-transcript-format
class: volatile-runtime-dependency
provider: codex
surface: transcript_path file format
contract_strength: empirical-only
used_for: non-authoritative resume enrichment
failure_mode: visible-degradation
fallback: git delta + Specrew artifacts + handover file + no-transcript floor
detection:
  - unit-fixture
  - live-canary-token-capture
  - provider-version-gated-scan
  - provider-news-scan
cadence: daily
owner: maintainer
gate_impact: warn
accepted_risk: required-before-authoritative-use
```

### Fields

| Field | Required | Purpose |
| --- | --- | --- |
| `id` | yes | Stable local identifier. |
| `provider` | yes | Host, service, CLI, runtime, or platform that owns the behavior. |
| `surface` | yes | Exact payload/file/event/behavior being relied on. |
| `contract_strength` | yes | `documented-stable`, `documented-unstable`, `empirical-only`, or `private-internal`. |
| `used_for` | yes | `authoritative-behavior`, `recovery`, `enrichment`, `observability`, or `convenience`. |
| `failure_mode` | yes | `silent-wrong`, `visible-degradation`, `performance-regression`, or `total-loss`. |
| `fallback` | yes | What the project does when the surface disappears or changes. |
| `detection` | yes | Check types that detect drift. |
| `cadence` | yes | `per-pr`, `daily`, `weekly`, `provider-version-change`, or `manual-smoke`. |
| `owner` | yes | Human or team responsible for reading reports and acting. |
| `gate_impact` | yes | `block`, `warn`, or `accepted-risk-required`. |
| `accepted_risk` | conditional | Required when `contract_strength` is `empirical-only` or `private-internal` and `used_for` is authoritative. |

## Detection Cadence

The monitor runner should generate a small report on every scheduled run, even
when all checks pass or a live check is skipped. Silence is not evidence.

Supported check types:

- `unit-fixture`: recorded provider payloads and transcript samples exercise
  parsers and fallback ladders.
- `live-canary-token-capture`: a bounded live host run writes a unique token
  and proves it can be recovered from the volatile surface.
- `provider-version-gated-scan`: when a host CLI/runtime version changes, run
  the relevant volatile dependency checks even if source code did not change.
- `provider-news-scan`: check provider release notes, changelogs, or official
  docs for relevant breaking changes.
- `manual-smoke`: a documented human check when live automation is not
  feasible or would expose secrets.

Severity rules should be explicit:

- Missing enrichment with a valid fallback normally warns.
- Silent-wrong data blocks when it can affect lifecycle truth.
- Authoritative use of an empirical/private surface blocks unless an accepted
  risk record names the owner, fallback, and monitoring cadence.
- Repeated skipped monitors escalate from warn to rework after a configured
  age threshold.

## Downstream Project Handling

This proposal is not only for Specrew self-development. Downstream projects
need a way to say, "this project relies on a volatile provider behavior, and
here is how we keep that risk visible."

V1 downstream behavior:

1. During design/risk/dependency review, the Crew asks whether any new
   undocumented runtime, provider, host, or tool behavior is being relied on.
2. If yes, the Crew records a `volatile-runtime-dependency` entry with fallback
   and cadence.
3. The verification strategy turns the cadence into tasks, CI, daily checks, or
   manual smoke evidence.
4. The reviewer verifies that the fallback exists, the monitor ran or was
   honestly skipped, and any accepted risk is visible to the user.
5. `specrew where` or the project dashboard surfaces stale/failing volatile
   dependency monitors separately from ordinary package/coupling warnings.

This gives downstream teams a lightweight operational risk surface without
requiring them to adopt Specrew's proposal corpus.

## Functional Requirements

- **FR-001**: Specrew MUST define `volatile-runtime-dependency` as a distinct
  dependency/risk class.
- **FR-002**: A volatile runtime dependency record MUST include provider,
  surface, contract strength, usage, failure mode, fallback, detection cadence,
  owner, and gate impact.
- **FR-003**: Specrew MUST distinguish enrichment/convenience use from
  authoritative lifecycle behavior.
- **FR-004**: Empirical-only or private/internal dependencies MUST NOT be used
  as authoritative truth without an accepted risk record.
- **FR-005**: Monitor definitions MUST support fixture checks, live canaries,
  provider-version-gated checks, provider-news scans, and manual smokes.
- **FR-006**: Monitor reports MUST be persisted and human-readable, including
  pass, fail, warn, skipped, and stale states.
- **FR-007**: Downstream projects MUST be able to define volatile runtime
  dependencies without using the proposal system.
- **FR-008**: Risk, dependency, verification, and review artifacts MUST all be
  able to reference the same volatile dependency id.
- **FR-009**: Review MUST verify fallback existence and monitor evidence for
  every volatile dependency touched by the feature.
- **FR-010**: Specrew MUST surface volatile dependency status separately from
  normal package/security/license dependency checks.
- **FR-011**: Repeated skipped or stale monitors MUST escalate according to the
  dependency's gate impact.
- **FR-012**: Host-specific monitors MUST be optional accelerators; the
  Specrew-owned artifacts and validators remain the source of lifecycle truth.

## Out of Scope

- Replacing ordinary dependency, SBOM, CVE, license, or version-currency
  scanners.
- Guaranteeing provider stability when a provider exposes no stable contract.
- Scraping private provider state without explicit user authorization.
- Requiring live AI-host canaries on every PR.
- Making conversation transcript capture authoritative for resume truth.
- Building a full incident-management system.
- Legal or compliance advice about provider terms.

## Effort

- **Iteration 1 (~4-6 SP)**: schema, docs, risk/dependency report integration,
  review checklist updates, and Specrew self-seeding for AI-host transcript and
  hook payload surfaces.
- **Iteration 2 (~4-7 SP)**: monitor runner, daily/report output, provider
  version/news scan hooks, dashboard/status surfacing, and downstream project
  template support.
- **Total**: ~8-13 SP.

## Phase Placement

Phase 2. This is methodology and governance infrastructure: it makes a known
class of fragile operational dependency visible before it becomes hidden
lifecycle truth. It should sequence with Proposal 164 and Proposal 178, and it
can feed Proposal 181's live host canaries where a volatile dependency is
AI-host-specific.

## Open Questions

1. Should volatile dependency records live primarily in
   `.specrew/monitors/volatile-dependencies.yml`, in the risk register, or in a
   dependency/coupling ledger with monitor references?
2. What default cadence should Specrew recommend for AI-host private surfaces:
   daily, weekly, or provider-version-change plus nightly-on-change?
3. Should `provider-news-scan` be an agent task, a CI task, or a manual report
   item until source-backed automation is reliable?
4. When a live canary cannot run because credentials are missing, how many
   skipped runs are allowed before the risk escalates?
5. Should authoritative use of `empirical-only` contracts be forbidden by
   default, or allowed only under a governance profile setting?

## Risks

- **Monitor fatigue**: daily reports can become noise. Mitigation: compact
  report format, owner assignment, stale-age thresholds, and separate warn vs
  block semantics.
- **False confidence**: a live canary can pass while a different host version
  or account shape fails. Mitigation: record host/version/account surface in
  the report and keep fallback mandatory.
- **Provider-doc drift**: news scans may miss breaking changes. Mitigation:
  combine news scans with canaries and version-gated checks.
- **Cost and secrets exposure**: live AI-host checks can consume tokens and
  require credentials. Mitigation: scheduled/main-only execution, hard
  time/token boxes, and manual-smoke fallback when automation is unsafe.
- **Overblocking downstream teams**: not every volatile dependency warrants a
  hard gate. Mitigation: gate impact is explicit per dependency.
- **Authority creep**: enrichment code can slowly become resume truth.
  Mitigation: review checks enforce the authoritative-vs-enrichment
  distinction and Proposal 145 verifies claim evidence.

## Cross-References

- Related proposals: 062, 097, 145, 164, 178, 181.
- Composes with Proposal 164 by adding a specific risk class and mitigation
  record shape.
- Composes with Proposal 178 by turning volatile dependency risk into explicit
  verification cadence and evidence tasks.
- Composes with Proposal 145 by making reviewer conformance check fallback,
  evidence, and authority boundaries.
- Composes with Proposal 181 by using live cross-host canaries for AI-host
  volatile surfaces when secrets and cost controls permit.
- Extends Proposal 097's coupling catalog with a narrower, higher-risk class
  for runtime contracts that ordinary package scanners cannot see.

## Status History

- 2026-06-12: status set to candidate after Feature 174 review surfaced the
  need to treat AI-host transcript and hook payload formats as dangerous
  volatile dependencies rather than ordinary package/coupling entries.
