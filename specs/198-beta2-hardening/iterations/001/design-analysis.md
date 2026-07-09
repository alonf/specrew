# Design Analysis - Feature 198-beta2-hardening / Iteration 001

**Feature**: 198-beta2-hardening
**Iteration**: 001 — substrate + firewall-first
**Date**: 2026-07-09
**Spec**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/spec.md

## Problem Framing

Iteration 001 lays the substrate every later iteration is tested on and the
firewall every later template is born under. Two toolchain pins move
(Spec-Kit 0.8.4 → 0.12.9 with one hard break — the `--ai` flag family was
removed at 0.10.0 and `scripts/specrew-init.ps1` passes `--ai copilot`;
Squad 0.9.1 → 0.11.0, clean), and the self-leak deny-list lint (205-W1)
lands FIRST so every surface iterations 002–004 touch is scanned from its
first commit (FR-033, custom rule `born-clean`).

Workshop-bound constraints govern: single tested pins (I2), probe-with-
evidence in scratch directories only (I1, `scratch-probes-only`), the
deny-list as one versioned JSON data file read by both repo lint and future
consumer checks (205-W6, data-storage lens), FileList + mirror parity for
every shipped file, and the paired-honesty-test rule (NFR-007).

In scope: FR-033, FR-034, FR-037 (deny-list lint + parameterization rule +
data file), FR-038 (Spec-Kit), FR-039 (Squad). Out of scope here: consumer-
side deny-list checks (FR-036, iteration 004), deploy surgery (FR-026,
iteration 004), all governance-core and reviewer-runtime work (002/003).

## Key Design Decision Points

1. How the lint derives its scan surface — hardcoded globs vs reading the
   deploy manifest source so scanned == shipped by construction.
2. Where the deny-list data lives and its initial seed (proposal 205's term
   classes) — single truth for repo lane now, consumer checks later.
3. How toolchain verification produces evidence — probe transcript recorded
   where reviewers can find it digest-matched.
4. Whether Spec-Kit's now-opt-in git / agent-context extensions enter our
   init flow — evidence-first per I1.
5. Where the W2 parameterization rule is documented so authors meet it
   before the lint reds them.

## Alternatives

### Option A: Simplest — inline patterns, bump-and-run

**Approach**: Fix `--ai` → `--integration`, bump all pins, run the suites.
Implement the lint as one script with a hardcoded pattern array and a
hardcoded list of template globs; wire it as a CI job.

**Architectural pattern**: scripted transaction.

**Quality features considered**: covers the happy path; no single-truth
data file (patterns-as-code), so consumer-side reuse (FR-036) later means
extracting or duplicating the list; scan surface can silently drift from
the deploy surface; no probe evidence trail.

**Effort estimate**: 3 SP.

**Reversibility cost**: medium — the list extraction is rework the moment
iteration 004 needs consumer-side checks.

**Trade-offs**:

- (+) Fastest visible result.
- (-) Violates the decided 205-W6 single-truth design and I3 versioning.
- (-) Scanned surface ≠ shipped surface by construction, only by care.
- (-) No recorded probe evidence for the extension decisions (I1 demands
  it).

### Option B: Reasonable — data-driven lint + evidence-first bumps (workshop-bound shape)

**Approach**: Ship `SelfLeakDenyList` as a versioned JSON data file
(`schema_version`, entries pattern/class/reason/source/added; annotation
escapes per file kind) under the extension data directory, in FileList,
with the initial seed from proposal 205 (registry/release-model terms,
dev-repo paths, self feature/iteration identifiers, repo/decision refs,
maintainer identifiers). The lint script derives its scan surface FROM the
deploy manifest source (the allowlist the installer actually ships), scans
file content plus deployed-script string literals, honors the
`specrew-self-ok: <reason>` escape (same line or line above), and runs as
a blocking job in the self-host Specrew CI workflow. Paired Pester
fixtures: seeded leak per class → red; annotated → green with reason;
clean surface → green. The W2 parameterization rule lands as a short
methodology doc section the lint's error text points at.

Toolchain: scratch-dir probe of the 0.12.9 CLI (flag survey:
`--integration` keys, `--script ps`, `--ignore-agent-tools`; extension.yml
hooks-schema load), recorded as digest-matched evidence under
`iterations/001/quality/`; migrate init to `--integration <key>`; run the
integration suites against a no-extensions 0.12.9 fixture; add
`specify extension add git` / agent-context ONLY if a suite failure
demonstrates the dependency (decision + evidence recorded either way).
Squad: bump minimums/defaults, scratch probe `squad init
--non-interactive`, existing `.squad` layout suites. All pin surfaces
updated together (CI env, version-check supported-versions, extension.yml
requires + `.specify` mirror, Get-SpecKitGitReference,
dependency-install minimum, validate-versions defaults).

**Architectural pattern**: data-driven catalog behind a stable seam (the
repo doctrine, A1).

**Quality features considered**: single-truth list (205-W6), scanned ==
shipped by construction, versioned contract (I3), paired honesty tests
(NFR-007), probe evidence (NFR-006), transparency in lint output naming
file/term/class/escape (NFR-002).

**Effort estimate**: 5 SP.

**Reversibility cost**: low — every later consumer of the list (gateway
advisory, update heal, prompt fixture) reads the same shipped file.

**Trade-offs**:

- (+) Realizes exactly the workshop-bound design; zero rework for
  iterations 002–004 consumers of the list.
- (+) The lint red-path teaches (names the escape and the rule doc).
- (-) ~2 SP more than Option A up front.

### Option C: By the book — lint framework + compatibility matrix

**Approach**: pluggable rule engine with SARIF output and GitHub
annotations, severity taxonomy, baseline suppression files; dual-version
Spec-Kit support (0.8.4 + 0.12.9 runtime branch) with a per-version
fixture matrix.

**Architectural pattern**: extensible lint platform.

**Quality features considered**: maximal tooling polish; the dual-version
matrix was already explicitly rejected at the workshop (I2), and SARIF
adds surface with no consumer demand.

**Effort estimate**: 9+ SP.

**Reversibility cost**: high (platform code to maintain).

**Trade-offs**:

- (+) Rich CI annotations.
- (-) Contradicts the recorded I2 decision; over-scoped for a five-SP
  substrate iteration; delays the firewall every other iteration waits on.

## Crew Recommendation

**Option B.** It is the only option that realizes the already-human-agreed
workshop decisions (205-W6 single truth, I1 evidence-first, I2 single pin,
I3 versioning, NFR-007 paired tests) without rework or contradiction.
Option A re-litigates the data-seam doctrine by accident; Option C
re-litigates I2 by design.

## Capacity Model

Iteration 001 = **5 SP** of the ~22 SP feature envelope (cap 5–8 SP per
iteration, Governance Alignment): deny-list file + seed (1), lint script +
CI job + paired fixtures (2), Spec-Kit probe + migration + pin surfaces +
fixture suites (1.5), Squad bump + probe + suites (0.5). No overcommit;
2–3 SP headroom under the cap absorbs probe surprises (e.g., a
demonstrated git-extension dependency).

## Applicable Lenses

- **architecture-core**: Option B keeps volatility in data (deny-list),
  logic stable (lint reads manifest source) — A1 honored.
- **component-design**: builds exactly the SelfLeakLintLane +
  SelfLeakDenyList + ToolchainPins components from the agreed map.
- **requirements-nfr**: paired tests per class; lint output content
  asserted (transparency).
- **data-storage**: JSON + schema_version + entry shape as agreed.
- **security-compliance**: author-time firewall arm of the trust story.
- **integration-api**: I1/I2/I3 realized; probe evidence recorded.
- **devops-operations**: blocking self-host lane (advisory posture is for
  the CONSUMER gateway, not our own repo); pin surfaces move together.
- **observability-resilience**: red output names file/term/class/escape +
  doc pointer; probe evidence correlates by date/run.
- **code-implementation**: six custom rules apply from this iteration's
  first commit (born-clean, FileList, mirror parity, scratch-probes-only).

## Co-Design Record

**Decomposition vocabulary**: data seams / host-neutral governed scripts
(A1, human-agreed at the workshop).

**Human-agreed**: yes — the component map (24 components) and this
iteration's slice of it were rendered in full and approved at the
component-design lens; the slicing placing these components in iteration
001 was approved at architecture-core A4 ("Looks good").

### Agreed component-to-responsibility map (iteration 001 slice)

```text
   CI LANE                       DATA SEAMS
   SelfLeakLintLane ──reads──►   SelfLeakDenyList (JSON, versioned, FileList)
        │        └──derives──►   deploy-manifest source (scan surface)
        │
   TEST HARNESS
   paired Pester fixtures (seeded-leak red / annotated green / clean green)

   SUBSTRATE
   ToolchainPins ── SPEC_KIT_VERSION 0.12.9 · SQUAD_VERSION 0.11.0 across
                    CI env · version-check · extension.yml (+ mirror) ·
                    Get-SpecKitGitReference · dependency-install ·
                    validate-versions
   InitBootstrap (Spec-Kit slice) ── `--integration <key>` migration +
                    evidence-gated opt-in extension decision (I1)
```

- `SelfLeakDenyList` — versioned self-fact patterns + annotation escape;
  single truth for this lane and every later consumer.
- `SelfLeakLintLane` — scans exactly what ships (manifest-derived) plus
  deployed-script literals; unannotated hit = red; red output teaches.
- `ToolchainPins` — all pin surfaces move together, verified by probe +
  suites.
- `InitBootstrap` (Spec-Kit slice) — the one hard break fixed;
  extension decisions carry probe evidence.

### Agreed flow (from the workshop, deny-list single-truth loop)

```text
  author edits a template
    → repo CI: SelfLeakLintLane reads SelfLeakDenyList over the
      manifest-derived deploy surface
    → unannotated self-fact = RED (names file/term/class + the escape +
      the rule doc) → fix or annotate `specrew-self-ok: <reason>`
    → ships clean → (iteration 004) consumer update heal + gateway
      advisory read the SAME shipped list
```

## Roadmap Fit

- Iteration 002 (governance correctness core) builds on the new substrate;
  its codex/copilot timeout measurements (clarify Q1) ride the consumer
  test project.
- Iteration 003 (containment + round economy) assumes the lint is live so
  its prompt/teaching edits are born clean.
- Iteration 004 (distribution + release) reuses `SelfLeakDenyList`
  consumer-side and completes the deny-by-default manifest surgery the
  lint's manifest-derived surface anticipates.

## Human Decision

- **Decision verdict**: approved for plan with Option B (maintainer chose
  option 1 — "Approve as-is — proceed with Option B and the defaults" — at
  the rendered design-analysis gate stop, 2026-07-10; hook-captured
  transcript verdict).
- **Chosen Option**: Option B — data-driven lint + evidence-first bumps.
- **Reason**: Option B is the only alternative that realizes the
  workshop-bound decisions (205-W6 single truth, I1 evidence-first, I2
  single pin, I3 versioning, NFR-007 paired tests) without rework; the
  manifest-derived scan surface and the blocking self-host posture were
  accepted as defaults.
- **Modifications**: None.
- **Design-analysis draft commit**: `89215832`
- **Decision recorded in commit**: `RECORDED-IN-GATES-COMMIT` (backfilled
  with the exact hash in the gates-packet commit)
