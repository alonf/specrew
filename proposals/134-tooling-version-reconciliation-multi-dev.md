---
proposal: 134
title: Tooling Version Reconciliation in Multi-Dev Specrew Projects
status: candidate
phase: phase-5
estimated-sp: 25-40
priority-tier: 2
discussion: orthogonal sibling to Proposal 010 (Multi-Developer Reconciliation). 010 covers spec-content collisions (FR-provenance, conflict classifier, Spec Steward mediator). This proposal covers the parallel collision class — tooling version skew (Specrew, Spec Kit, Squad, host CLIs) and its downstream effects on shared in-tree artifacts (manifest pins, extension.yml, casting registry, dashboards, boundary-sync ledgers). Empirical motivation: 2026-05-27 tester portability report surfaced single-dev-multi-machine collisions; multi-dev adds tooling-version skew across developers on same project at same time. Together with Proposal 010, completes the multi-dev story for Specrew. Phase 5 candidate; some pillars splittable as earlier slices if multi-dev usage emerges before Phase 5.
---

# Tooling Version Reconciliation in Multi-Dev Specrew Projects

## Why

Proposal 010 (Multi-Developer Reconciliation) handles **spec-content collisions** — two developers editing the same FR, overlapping behavior across features, shared-surface co-modification. That is half the multi-dev story.

The other half is **tooling version skew**. When multiple developers work on the same Specrew project at the same time:

- Dev A runs Specrew `0.27.5`; Dev B runs `0.27.7-beta.1`; Dev C runs `0.28.0`. Each runs `specrew init` / `specrew update`, each writes `.specrew/config.yml specrew_version` with their own version, each manifest update creates a merge conflict.
- Dev A on Spec Kit `0.8.13`, Dev B on `0.9.0`. Each writes `.specrew/config.yml speckit_version` differently. The `.specify/extensions/specrew-speckit/extension.yml` may have schema changes between Spec Kit versions; one dev's extension format breaks the other's runtime.
- Dev A on Squad `0.9.4`, Dev B on `0.9.5`. `.squad/casting/registry.json` may have schema changes. Dev B's commit breaks Dev A's runtime; Dev A re-runs `specrew init` to repair, overwriting Dev B's intentional update.
- Dev A on Copilot CLI `1.0.54`, Dev B on `1.0.60`. Skill format may differ. `.copilot/skills/` or `.github/skills/` directory content drifts.
- F-NNN numbering races: Dev A starts F-049 from main; Dev B picks F-049 in parallel before A pushes. Two `specs/049-*` directories with different content compete at merge time.
- Version-bump-at-feature-close race (the new F-048 SDLC): two features racing to merge both want version `0.27.7` as their target. The `Specrew.psd1 ModuleVersion` + `.specrew/config.yml specrew_version` + `CHANGELOG.md` all conflict.
- Boundary-sync state-file races: `.specrew/closed-iterations.yml`, `.squad/decisions.md`, per-iteration `dashboard.md`, `closeout-dashboard.md` are all written by `sync-boundary-state.ps1`. Multiple devs closing boundaries simultaneously → race condition at write time; merge conflict at push time.

These are NOT spec-content conflicts (Proposal 010's domain). They are version-management + race-condition conflicts in the runtime/governance layer. Without a reconciliation story for this class, multi-dev Specrew projects suffer constant merge friction on tooling-state files that should be invisibly managed.

### Empirical motivation (2026-05-27)

External tester report exposed the **single-dev-multi-machine** version of this problem (`[[project-specrew-portability-gap-2026-05-27]]`): same developer, two machines, runtime files weren't committed, second machine couldn't continue. **Multi-dev is the same problem multiplied** — different machines AND different Specrew/Spec-Kit/Squad versions AND simultaneous writes.

The portability proposal (queued for F-051) addresses the single-dev-multi-machine surface. This proposal addresses the multi-dev superset. The two compose: portability + reconciliation together make multi-dev Specrew projects viable.

## What

Six pillars covering the collision classes above. Pillars 1-3 are foundational; 4-6 are reconciliation patterns built on top.

### Pillar 1: Tooling version pinning + drift detection (~5-7 SP)

`.specrew/config.yml` becomes the authoritative pin for `specrew_version`, `speckit_version`, `squad_version`. On every `specrew start`:

- Detect the installed runtime version
- Compare to the pinned version in `.specrew/config.yml`
- Emit a clear WARN if drift detected: "Your installed Specrew `0.27.7` differs from project pin `0.27.5`. Either upgrade the project (`specrew bump-version --target 0.27.7`) or downgrade your install (`Install-Module Specrew -RequiredVersion 0.27.5 -Force`)."
- Same logic for `speckit_version` + `squad_version`

Phase 1 = WARN-only. Phase 2 (after policy hardens) = optional FAIL for `--strict-version-pinning` mode.

Composes with F-049's Docker pre-publish test (the test should validate pin compatibility too).

### Pillar 2: Atomic boundary-sync writes (~3-5 SP)

`sync-boundary-state.ps1` and adjacent scripts (closeout-dashboard generation, decisions.md append, closed-iterations.yml append) MUST use atomic write-then-rename semantics + file-lock coordination. Concurrent writes from multiple developers' sessions on the same shared file (over WSL share, network mount, or rebased branches) MUST NOT corrupt state.

Composes with Proposal 123 (Verdict-History Atomic Single-Write Refactor) — same atomicity pattern extended to all boundary-sync writes.

### Pillar 3: Per-developer vs shared file classification (~4-6 SP)

Authoritative classification of every Specrew-managed file as one of:

- **Shared** — must be tracked, must be byte-identical across devs (`.specrew/config.yml`, `.specrew/constitution.md`, `.specrew/roadmap.yml`, `specs/`, `extensions/`, `.specify/extensions/`, `.squad/agents/<role>/charter.md`, etc.)
- **Per-developer** — must NOT be committed, must be gitignored (`.specrew/start-context.json`, `.specrew/last-start-prompt.md`, `.specrew/host-history.json`, `.specrew/.cache/`, `.squad/sessions/`, `.squad/decisions/inbox/`, `.specrew/last-validator-summary.json`)
- **Append-only-shared** — committed but with atomic-append discipline + structured merge resolution (`.squad/decisions.md`, `.specrew/closed-iterations.yml`)
- **Regenerable** — generated from shared sources on demand, can be gitignored OR tracked per project preference (`.claude/skills/`, `.github/skills/`, `.agents/skills/`, dashboards)

`specrew check-file-classification` CLI surfaces this for any project; `specrew init` writes the classification into `.gitignore` automatically.

Composes with the F-051 portability proposal (single-dev-multi-machine subset of the same classification work).

### Pillar 4: F-NNN numbering authority via roadmap + reservation protocol (~3-5 SP)

When Dev A starts a new feature locally, Specrew currently picks the next available F-NNN by scanning `specs/`. Dev B doing the same in parallel picks the SAME number → collision.

Solution: `.specrew/roadmap.yml` becomes the reservation source-of-truth. `specrew feature reserve <slug>` writes a reservation entry (claimed-by, claimed-at, branch-name-once-pushed). Other devs see existing reservations and pick the next available number.

Lightweight pre-PR reconciliation: if two devs race the same number, `git merge` produces a parseable conflict in `roadmap.yml` that a `specrew feature renumber <new>` command resolves by renaming the spec directory + updating all internal references.

Composes with Proposal 057 (Roadmap Spine) — roadmap.yml is the canonical reservation surface.

### Pillar 5: Version-bump race resolution at feature-close (~5-8 SP)

The F-048 SDLC has Step 9 (tag `v<next-version>-beta.1` after merge). When two features race to merge:

- Feature A merges first, claims version `0.27.7`
- Feature B (already approved, was about to tag `0.27.7`) needs to bump to `0.27.8`

`specrew release calculate-next-version` (or built into the existing closeout boundary-sync) detects the most recent published tag + most recent in-flight feature-close intent and surfaces the right version target.

Possible mechanism: a small "release reservation" file (similar to F-NNN reservation) where features claim their target version at the time of feature-closeout boundary entry, not at the time of tagging. If reservation already taken → bump intent surfaces in the Step 11 manual-test HANDOFF as "your target is 0.27.8 not 0.27.7."

Composes with F-049 Docker pre-publish test (the test could include "this tag version is sequentially next" assertion).

### Pillar 6: Composition with Proposal 010 spec-content reconciliation (~5-9 SP)

When this proposal's tooling-version reconciliation AND Proposal 010's spec-content reconciliation are both active, the PR-time conflict classifier needs to handle both classes coherently:

- Spec-content conflict (010): "Dev A's FR-007 conflicts with Dev B's FR-007"
- Tooling-version conflict (134): "Dev A's commit pins `speckit_version: 0.8.13`; Dev B's commit pins `0.9.0`"
- Composite conflict: "Spec change overlaps AND tooling pin differs" — needs Spec Steward mediation considering BOTH

The Spec Steward agent (010's blocking mediator) gets an extended responsibility: classify tooling-version drift alongside spec-content drift in the conflict report.

This pillar is the integration work that proposals 010 + 134 share. Implementation likely lands in whichever proposal ships first (010 if Phase 5 starts with multi-dev work; 134 if tooling version reconciliation ships earlier as a slice).

## Scope estimate

| Pillar | SP | Order |
|---|---|---|
| 1: Version pinning + drift detection | 5-7 | First (foundational) |
| 2: Atomic boundary-sync writes | 3-5 | Compose with Proposal 123 |
| 3: Per-developer vs shared file classification | 4-6 | Composes with F-051 portability |
| 4: F-NNN reservation protocol | 3-5 | Composes with Proposal 057 roadmap spine |
| 5: Version-bump race resolution | 5-8 | After F-049 release pipeline hardening |
| 6: Composition with Proposal 010 | 5-9 | Integration |
| **Total** | **25-40 SP** | Multi-iteration; split-friendly |

Splittable. Pillars 1 + 3 could ship as a "pre-multi-dev hardening" slice (~9-13 SP) before full multi-dev usage emerges. Pillars 4 + 5 are needed when concurrent feature work becomes routine. Pillars 2 + 6 land alongside Proposal 010 in Phase 5.

## Sequencing

**Phase 5 main**: Bundle with Proposal 010 (Multi-Developer Reconciliation) for the full multi-dev launch. Together ~100-115 SP, naturally a multi-iteration feature or sibling features sharing PR-time validator infrastructure.

**Pre-Phase-5 splittable slices** (could ship earlier as small-fix slices or bundled into adjacent features):

- **Pillar 1 (version drift detection, ~5-7 SP)** — could ship as part of F-051 (Specrew primer + portability + init hardening). Same surface (`specrew init`/`specrew start` startup checks). Adds drift WARN at startup without needing full multi-dev story.
- **Pillar 2 (atomic boundary-sync writes, ~3-5 SP)** — could ship as part of any iteration that touches boundary-sync (currently relevant during F-049 Docker test design if the test needs deterministic boundary-state). Composes with Proposal 123.
- **Pillar 3 (file classification, ~4-6 SP)** — strong overlap with F-051 portability proposal. Ship there or as immediate follow-up.

## Why this is NOT bundled into Proposal 010 directly

Proposal 010 is already 75 SP. Adding 25-40 SP would push it past 100 SP, making it harder to ship in coherent iterations. Two sibling proposals with explicit composition (Pillar 6 here, cross-reference in 010) is better than one mega-proposal.

The two proposals also have different STAKEHOLDERS:

- **010** = Spec Steward + Reviewer (spec-content conflict resolution)
- **134** = Implementer + ops (tooling-version reconciliation; mostly happens via init/start/boundary-sync hooks, not via manual conflict resolution)

Different surfaces, different empirical pulls, different test patterns. Separate proposals.

## Acceptance signals

- **AC1**: `specrew start` detects + reports any version skew between installed runtime and project pins (Specrew/Spec Kit/Squad)
- **AC2**: Boundary-sync writes are atomic (write-temp-rename pattern; concurrent multi-dev writes don't corrupt state)
- **AC3**: Specrew-managed files have a documented classification (shared / per-developer / append-only-shared / regenerable); `specrew check-file-classification` surfaces it
- **AC4**: Two devs starting features in parallel cannot pick the same F-NNN number (roadmap reservation enforces); collision detection at PR-time produces a parseable conflict
- **AC5**: Two features racing to merge produce a sequential version-bump (one gets 0.27.7, the other gets 0.27.8); no manual conflict resolution on `Specrew.psd1` ModuleVersion required
- **AC6**: Composite spec+tooling conflicts (both shipping in same PR set) produce a single Spec-Steward-mediated conflict report covering both classes

## Out of scope

- Spec-content conflict resolution (Proposal 010's domain)
- Multi-organization access control (single-org assumed)
- Cross-repository Specrew project federation
- Real-time collaborative editing (Specrew assumes async git-flow)

## Composes with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 010 (Multi-Developer Reconciliation, draft 75 SP Phase 5)** | **Sibling**. Together cover the full multi-dev story (010 = spec-content, 134 = tooling-version). Composition via Pillar 6 |
| **Proposal 057 (Roadmap Spine + Input Adapter Pattern)** | Pillar 4 uses roadmap.yml as F-NNN reservation surface |
| **Proposal 062 (Dependency Metadata + Reason Mapping + Impact-Analysis Propagation)** | Adjacent — both touch the proposal-numbering + cross-feature-dependency surface |
| **Proposal 123 (Verdict-History Atomic Single-Write Refactor)** | Pillar 2 extends the atomic-write pattern to all boundary-sync writes |
| **F-051 candidate (Specrew primer + portability + init hardening)** | Pillar 1 (version drift detection) + Pillar 3 (file classification) overlap heavily. Could ship Pillars 1+3 as part of F-051 if scope allows, leaving Pillars 2+4+5+6 for Phase 5 |
| **F-049 (Release Pipeline Hardening + Substantive Intake)** | Pillar 5 (version-bump race) builds on F-049's Docker pre-publish test infrastructure |
| **`[[project-specrew-portability-gap-2026-05-27]]`** | Single-dev-multi-machine subset of the same problem class |

## Status history

- 2026-05-27: candidate proposal drafted after user direction surfaced multi-dev collision concern. Six pillars covering version skew, atomic writes, file classification, numbering races, version-bump races, and composition with Proposal 010. Phase 5 main bundle; Pillars 1 + 3 splittable as earlier slices into F-051 or sibling small-fix work.

## Cross-references

- Empirical motivation: `[[project-specrew-portability-gap-2026-05-27]]` (single-dev-multi-machine subset) + 2026-05-27 user direction to extend portability scope to multi-dev
- file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md — sibling proposal
- file:///C:/Dev/Specrew/proposals/057-roadmap-spine-input-adapter-pattern.md — F-NNN reservation surface
- file:///C:/Dev/Specrew/proposals/062-dependency-metadata-reason-propagation.md — adjacent proposal-numbering work
- file:///C:/Dev/Specrew/proposals/123-verdict-history-atomic-single-write-refactor.md — atomic-write pattern source
- `[[project-post-f048-sequencing-locked-2026-05-26]]` — F-051 candidate is the early-slice landing target for Pillars 1+3
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
