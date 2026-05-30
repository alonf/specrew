# Specrew v0.28.0 — Pipeline Hardening + Substantive Intake

**Released**: 2026-05-30

## TL;DR — The headline

**v0.28.0 is the methodology-quality release**: Specrew now actively detects when its own boundary-discipline gates are bypassed, and the `/speckit.specify` intake adapts to your expertise dials (Product Strategy / UX-UI Design / Software Architecture / AI Delivery Planning) so the spec conversation matches your level. Shipped alongside is a Docker-based pre-publish harness that catches PSGallery packaging regressions (FileList omissions, version-pin drift) before they reach users — directly motivated by the v0.27.3 incident that broke every macOS install.

## Why this matters

Through the v0.26.x and v0.27.x line, Specrew's methodology was sound on paper but enforced cooperatively — agents could (and empirically did) silently bypass boundary gates, ship review verdicts citing uncommitted code, or accept iteration-closeouts on stale state. v0.28.0 closes the gap from cooperative-prose enforcement to mechanical detection:

- **Bypass detection is real**: missing handoff evidence, trigger-bypass artifact gaps, ephemeral host-scratch artifact placement, boundary state-advances without matching human verdicts, and accepted review evidence citing files outside the cited Tree Under Review — all five pillars now FAIL-gate at validator + sync time.
- **Intake quality scales with the user**: instead of asking the same 30+ clarification questions of every project, the Crew Interaction Profile lets you set expertise dials per area; the substantive intake engine produces shorter, sharper conversations for experts and richer guided dialogues for novices.
- **PSGallery shipping is gated empirically**: the Docker pre-publish harness builds a clean install in a Linux container and runs the FileList integrity + version-pin + init/update transition checks before publish workflow proceeds to upload. The v0.27.3 incident class (FileList omission breaks install) is structurally prevented.

## What's new

### F-049: Pipeline Hardening + Substantive Intake (five iterations)

#### Iteration 001 — Docker pre-publish version-update verification harness

A Linux-container harness (`tests/Dockerfile.publish-test` + `scripts/internal/test-publish-harness.ps1`) runs before any PSGallery publish:

- Phase 1: candidate Specrew.psd1 parses cleanly
- Phase 2: FileList integrity — every declared file exists on disk
- Phase 3: version-pin drift detection (Proposal 134)
- Phase 4: test project initialization works against the candidate
- Phase 5: `specrew update` transition validation

The harness runs in CI on the publish-module workflow before the actual PSGallery upload step. Failure blocks publication.

#### Iteration 002 — Durable troubleshooting guide

The init/update interaction failure modes that hit the v0.27.3 incident class are now documented + searchable in the troubleshooting docs.

#### Iteration 003 — Persona-driven `/speckit.specify` intake engine

Four expertise dials persist per-user at `~/.specrew/user-profile.yml`:

- **Product Strategy** (1-10 or `auto`)
- **UX / UI Design** (1-10 or `auto`)
- **Software Architecture** (1-10 or `auto`)
- **AI Delivery Planning** (1-10 or `auto`)

The substantive intake engine reads these dials and produces calibrated `/speckit.specify` conversations: high dials get expert-level concise prompts; low or `auto` dials get full guidance with examples + recommended defaults. The first run prompts you for dial values; you can re-run intake or edit `~/.specrew/user-profile.yml` manually.

#### Iteration 004 — Proposal 120 Five-Pillar Bypass Detection (FR-018..FR-022)

Governance validation now detects:

1. Missing `=== SPECREW HANDOFF ===` evidence at boundary stops (live producer `Add-SpecrewHandoffEvidence` so it fires in real runs)
2. Trigger-bypass artifact gaps (distinct from generic missing-artifact failures)
3. Canonical artifacts written to ephemeral host session-scratch (instead of the project tree)
4. Boundary state-advances lacking matching human verdict history (validator WARN + sync hard-block; stale-ahead short-circuit repaired)
5. Accepted review evidence citing production files absent from the cited Tree Under Review (`Test-ReviewEvidenceTreeIntegrity`, FAIL-gates iteration-closeout)

Pillars 1-3 were certified from F-047 (v0.27.3 bug-bash bundle); Pillars 4-5 completed in F-049.

#### Iteration 005 — Crew Interaction Profile + Welcome Orientation

The four saved profile values are presented as a **Crew Interaction Profile** (collaboration calibration; distinct from Specrew's internal persona lenses). The `user-profile-awareness` instruction is extracted to a canonical directive (`squad-templates/directives/user-profile-awareness.md`) referenced by all five role charters. The Coordinator governance gains a session-start **Welcome Orientation** rule that surfaces project state + lifecycle position + Crew Interaction Profile dials at every session start. First-run setup auto-detects non-interactive contexts (`-NonInteractive:([Console]::IsInputRedirected)`) so `specrew start` no longer hangs on `Read-Host` in CI/non-TTY, guarded by a regression test wired into the Contract lane.

### Proposal 144 — Grandfather Closed-Iteration Capacity (PR #1153)

`Test-PlanEffortModel` now validates closed iterations (Status `complete`/`abandoned`) against their own stated capacity (historical truth) instead of the current `iteration-config.yml` baseline. A baseline change no longer retroactively FAILs closed-iteration plans; active iterations (`planning`/`executing`) still enforce the current config. Closed-iteration index serves as belt-and-suspenders. The 29-iteration / 58-line capacity-drift set cleared to 0.

## For external users — what you can now do

1. **Run the persona-driven intake** — `specrew start "<task>"` prompts you for expertise dials on first run; subsequent runs use saved profile. Dial settings affect intake conversation depth across `/speckit.specify` + `/speckit.clarify`.
2. **Trust that boundary bypasses get caught** — the five-pillar bypass detection FAIL-gates iteration-closeout if any pillar fails. No more silent boundary skips.
3. **Get a Welcome Orientation at every `specrew start`** — Coordinator now surfaces project state + lifecycle position + Crew Interaction Profile summary before the first intake question, so you know exactly where you are.
4. **Publish-line confidence** — the Docker pre-publish harness gates every PSGallery push; v0.27.3-class FileList omissions no longer reach users.

## Known limitations / follow-ups

### Capacity-config baseline note

`capacity_per_iteration` was formalized at **25** story points for the self-host repo during F-049 Iteration 003 (whose real 23.45 SP load proved 20 insufficient). The shipped default for new downstream projects intentionally remains **20** (`templates/iteration-config.yml` + `extension.yml default_per_iteration`). A queued post-F-049 chore reverts the self-host repo baseline 25 → 20, since the 20 cap is intentional (AI scope/context-sized); Iteration 003 stays grandfathered by the Proposal-144 rule.

### Framework-fix slice (deferred)

- B-001: duplicate `Get-ObjectPropertyString` with `-Names` vs `-PropertyNames` (later shadows former)
- A-001: `Get-QualityEvidenceContent` StrictMode crash on the `| Gate | Target | Notes |` quality-gate convention (blocks scaffold/mechanical/reviewer-artifact generation in some flows)

Tracked for a separate framework-fix slice.

### Proposal 143 reframed

Proposal 143 (Session Start Welcome Orientation + Reset Surface) is **no longer required for F-049 closure** — FR-038 in-situ visibility is closed by Iteration 005's directive refactor + Coordinator Welcome Orientation rule. Proposal 143 still ships post-F-049/F-050 as the richer surface (CLI reset path, audit trail, structured Welcome Orientation with Unicode rendering, cross-platform polish). Non-blocking.

## Migration from v0.27.x

`specrew update --module` (or `Install-Module Specrew -Force` followed by re-launch) brings you to v0.28.0. The first `specrew start` after the upgrade prompts for expertise dials (creates `~/.specrew/user-profile.yml`); existing `.specrew/`, `.specify/`, `.squad/` directories are preserved. The Welcome Orientation rule activates at the next session start automatically.

If you've been on the v0.27.3 broken FileList window, this upgrade restores macOS install support that v0.27.4 (hot-fix) already addressed; v0.28.0 brings the structural prevention via the Docker pre-publish harness so the incident class doesn't recur.

## Verification

PR #1152 shipped with all 6 CI gates green plus the new Docker pre-publish harness running cleanly. Five iterations closed; 0 drift events at feature-closeout. Manual install validation passed (Universal Beta-Before-Stable mandate Step 11: v0.28.0-beta.2 installed + smoke-tested in a fresh project before v0.28.0 stable promotion).

## What's next

- v0.29.0 — F-050 Cursor Host Package (Proposal 114): adds Cursor as the fifth first-class Specrew host
- F-051 — Multi-Session Foundation (Proposals 010 + 134 minimal slice): single-human-multiple-Crew-shells coordination
- F-052 — Structured Multi-Phase Reviewer Skill (Proposal 145): per-phase per-FR coverage matrix enforcement
- F-053 — Multi-Agent Subagent Orchestration V1 (Proposal 139): cost-aware per-task model routing
