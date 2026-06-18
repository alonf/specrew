---
proposal: 198
title: Self-Host & Dependency Currency — Deterministic Regeneration, Release-Time Self-Update, and Drift Gate
status: candidate
phase: phase-2
estimated-sp: 14-21
priority-tier: 1
type: release-process-governance
discussion: surfaced 2026-06-18 during the PR #2882 review — the Specrew repo's OWN deployed Specrew assets had drifted roughly six releases (extension registration stuck at 0.32.0, AGENTS.md/CLAUDE.md absent entirely, the Feature 177 code-rules skill never deployed, the Feature 171/184 hook binding missing) because no release or CI step regenerates them. The manual catch-up (PR #2882) is the symptom, not the fix; and that catch-up itself shipped a markdownlint defect and a non-deterministic key-reorder, exposing that generation is not byte-stable. A follow-on compatibility check (2026-06-19) found Specrew had also fallen behind Spec Kit — pinned to max_tested 0.9.0 while upstream shipped through 0.11.2, including a 0.10.0 breaking change (the legacy --ai/--no-git flags removed in favor of --integration) that specrew init still depends on — motivating a per-release dependency-currency discipline alongside the asset regeneration.
composes-with:
  - 060  # Prerelease Channel Staging — the beta-publish flow this hooks into
  - 061  # Init/Update Convergence Test — convergence to a clean regenerated state
  - 075  # Update Artifact Backfill Discipline
  - 132  # Mirror-Parity Validator Enforcement — sibling deterministic source-vs-deployed gate
  - 173  # Self-Artifact Reconstruction — same principle: Specrew as a first-class downstream project
  - 190  # Governance Self-Modification Guard — the automated regeneration is a SANCTIONED self-modification this must reconcile with
audience: maintainers, release process, CI, Crew agents
---

# Self-Host & Dependency Currency — Deterministic Regeneration, Release-Time Self-Update, and Drift Gate

## Why

The Specrew repository dogfoods Specrew on itself: it carries committed, generated runtime assets (`.specrew/`, `.specify/`, `.claude/`, `.agents/`, `.github/`, `.cursor/`) — the same surfaces a project receives from `specrew init` / `specrew update`. **Nothing in the release process or CI keeps those assets current with the version being shipped.** They move only when a human remembers to run `specrew update` by hand.

The PR #2882 review (2026-06-18) made the cost concrete. The self-host had drifted across roughly six releases:

- `.specify/extensions.yml` still registered the extension at **0.32.0** while main shipped **0.38.0**.
- `AGENTS.md` and `CLAUDE.md` — the Feature 184 persistent coordinator instructions — **did not exist at all**.
- The Feature 177 `specrew-code-rules` skill had **never been deployed** to any host surface.
- The Feature 171/184 hook `-HostBinding` was **missing** from the deployed hooks.

Confirmed during that review: **no CI workflow invokes `specrew update` or any self-sync** (zero matches across `.github/workflows`), and **no existing proposal owns this** ("dogfood" appears tangentially in ~20 proposals; none of them this).

This is the same failure mode as the pre-automation manual closeout steps: **a step that depends on human memory rots.** Here it rotted for six versions. The consequence is worse than cosmetic drift — the Specrew repo's self-governance *behavior* lags its own source, so the highest-value validation signal Specrew has (dogfooding the lifecycle on a real project) runs on **stale assets that are not the version being shipped.**

The manual catch-up also exposed that **generation is not byte-stable**: it produced a pure key-reorder of `.squad/casting/registry.json` (+15/-15, no semantic change) and a markdownlint **MD046** violation in the regenerated `squad.agent.md` (an indented code fence in generated output; main's copy is lint-clean). Non-deterministic, sometimes-lint-dirty generation is both why `specrew update` produces churny diffs and why a naive drift check would be unusable noise.

The deeper principle (shared with Proposal 173): **Specrew should treat itself as a first-class downstream project.** A downstream project on `specrew update` discipline stays current; Specrew itself does not, because the discipline was never wired into its own release.

## What

Three coupled parts, in dependency order. Part 1 is a prerequisite for Part 3.

### Part 1 — Deterministic, lint-clean generation (prerequisite)

Make `specrew update` / `specrew init` output **byte-stable and lint-clean** for the same inputs:

- Stable serialization: deterministic key ordering (the `registry.json` reorder), stable formatting, normalized EOLs, trailing-newline discipline.
- Lint-clean generated markdown: the generators must emit markdownlint-clean output. The `squad.agent.md` MD046 indented-fence is a generator / source-template defect, not a hand-edit to patch in the deployed copy.
- An **idempotence test**: `update` applied twice yields zero diff; `update` of an already-current tree yields zero diff. (Composes with Proposal 061's convergence intent.)

Without this, the drift gate in Part 3 is noise.

### Part 2 — Release-time self-update

As part of **creating the beta** (the existing closeout to beta flow), regenerate the self-host deployed assets from the **source being released** and commit them:

- Regenerate from the **local module source** (the repo *is* the module — `SPECREW_MODULE_PATH` to the dev tree), so this runs **before publish**, with no chicken-and-egg against PSGallery.
- Fold it into the **beta-validation obligation** Specrew already owes. The beta-before-stable mandate requires beta validation to *exercise the runtime deliverable on the real host, a real lifecycle — not file presence*. Regenerating the Specrew repo's own assets to the new beta and running a lifecycle on it **is** that validation; the Specrew repo becomes the canonical real-project beta validator. This makes a vague "go try it" step concrete and scriptable instead of new overhead.

### Part 3 — Drift gate (enforcement)

A CI check that regenerates the self-host assets into a temporary location and diffs against the committed tree; **fail (or warn during adoption) if they differ.** This is the half that prevents recurrence — Part 2 alone is just another forgettable manual step. It is a sibling of Proposal 132's mirror-parity validator (source vs deployed), applied to the self-host surface.

### Part 4 — Dependency currency (Squad + Spec Kit)

Each release brings the platform dependencies current and fixes any compatibility break, validated before `max_tested` advances. This is what keeps Specrew from silently falling behind a fast-moving dependency: the 2026-06-19 check found Specrew pinned to Spec Kit `max_tested` 0.9.0 while upstream had shipped through **0.11.2**, including a **0.10.0 breaking change** (`--ai`/`--no-git` removed in favor of `--integration`) that `specrew init` still passes.

The per-release self-update (Part 2) runs a **dependency-currency step**: detect the latest Squad and Spec Kit, attempt the bump, and run the contract/compatibility validation (install + a real lifecycle, per the beta-validation tie-in). The cadence is **conditional on what the bump turns out to be**, not pre-committed:

- **Additive / trivial bump** → fold into the current release (single release). Example: Squad 0.9.4 → 0.10.0 (state-backends + docs; additive).
- **Breaking / non-trivial bump** → does **not** block the in-flight feature; it spins out as its own governed upgrade slice (a `platform-upgrade` work kind) and ships as the next release (two releases). Example: the Spec Kit 0.10+ `--ai` → `--integration` migration, plus the git opt-in and per-event-hook-list changes — a source-code adaptation with its own validation surface.

`max_tested` advances only after validation passes, on whichever path. **Squad is bumped only while it remains a Specrew runtime** — the discipline is conditional on the dependency still being used (the Squad-removal arc may retire it).

The discriminator (trivial vs breaking) is the currency step's validation result — so the team never absorbs an unbounded dependency-fix inside an unrelated feature's release, yet currency never silently lags. This is the answer to "one release cadence or two": **one by default, two when the bump is breaking, decided per release.**

### Reconciliation with Proposal 190 (Governance Self-Modification Guard)

The automated regeneration **modifies the governance surface that 190 guards** (an agent must not edit the deployed governance that judges its own work). This proposal's regeneration is a **sanctioned, deterministic, source-derived self-modification** — categorically different from an agent's reactive tampering. The two must be reconciled explicitly: the sanctioned regeneration path carries provenance (source-derived, CI/release-driven, deterministic-diff-verified) that 190's guard recognizes and permits, while still blocking ad-hoc agent edits. Shipping this without that reconciliation would either trip 190 or punch a hole in it.

## Architecture (deliverable shape)

- A `regenerate-self-host` entry point that runs `specrew update` (and `init` for absent surfaces — see Open Questions) against the local source and stages the result deterministically.
- Generator determinism fixes in the update/deploy path (serialization ordering, markdown emission), plus the idempotence test in the integration suite.
- A release-flow hook: the closeout/beta step calls `regenerate-self-host` and includes the result in the beta commit; the beta-validation record references the self-host lifecycle run.
- A CI drift check (`validate-self-host-currency`, or folded into the existing validation lane) that regenerates and diffs.
- A 190-compatible provenance marker on the sanctioned regeneration.

## Composition map

- `[[060-prerelease-channel-staging]]` — the beta-publish flow this self-update hooks into.
- `[[061-init-update-convergence-test]]` — the idempotence/convergence test in Part 1 extends this.
- `[[075-update-artifact-backfill-discipline]]` — adjacent update-discipline.
- `[[132-mirror-parity-validator-enforcement]]` — Part 3's drift gate is the self-host sibling of mirror-parity.
- `[[173-self-artifact-reconstruction]]` — same principle (Specrew as a first-class downstream project); 173 backfills historical *lifecycle* artifacts, this keeps deployed *runtime* assets current. Complementary, not overlapping.
- `[[190-governance-self-modification-guard]]` — the sanctioned-regeneration reconciliation above is a hard dependency.
- Beta-before-stable validation mandate — this proposal makes that mandate's "exercise the runtime deliverable" requirement concrete for the self-host.

## Sizing + sequencing

~14-21 SP, three iterations (Part 1 gates Part 3):

- **Iter 1 (~6-9 SP):** deterministic, lint-clean generation + idempotence/convergence test. The biggest unknown (auditing every generator's output stability).
- **Iter 2 (~4-6 SP):** release-time self-update step + beta-validation tie-in + the `init`-vs-`update` resolution for absent surfaces.
- **Iter 3 (~4-6 SP):** drift gate (warn then block adoption phasing) + 190 reconciliation + provenance marker.

Part 4's per-release dependency-currency *check* folds into Iter 2 (small). The *remediation* of a breaking dependency bump is a separate `platform-upgrade` slice sized per occurrence — it is not counted in this proposal's SP. The first such occurrence already exists: the Spec Kit 0.10+ adaptation (`--ai` → `--integration`, git opt-in, per-event-hook re-validation).

## Open questions

- **Beta-track vs stable-track:** does the self-host track the in-flight **beta** (maximum dogfood signal, but a broken beta breaks the dev environment) or the **last stable** (safe, but Specrew does not eat its own cooking until promotion)? Recommendation: beta-track *as the validation* — a regenerated beta that breaks self-governance is the signal not to promote, and the regeneration is reverted. Risk-tolerance call for the maintainer.
- **`init` vs `update` for absent surfaces:** `AGENTS.md`/`CLAUDE.md` were *absent*, not stale; `specrew update` may only refresh existing surfaces, and the Feature 174 finding is that `SPECREW_MODULE_PATH` does **not** redirect `specrew init`. Resolve how the self-update creates missing surfaces from local source.
- **Gate severity:** hard-block vs warn during adoption (follow the 132/145 warn-then-block phasing).
- **Where the regeneration runs:** in the human closeout step, or a CI job on the beta tag that commits the regenerated assets.
- **Diff-churn budget:** even deterministic regeneration commits real per-release diffs; confirm that is acceptable signal, not noise.

## Risks

- **Generation determinism is harder than it looks.** The `registry.json` reorder and the `squad.agent.md` MD046 are early evidence; there may be many more non-stable emitters. Mitigate by making Part 1 its own iteration with the idempotence test as the gate.
- **Broken beta breaks the self-host.** Beta-track regeneration can wedge the dev environment. Mitigate via revertable regeneration + validation-then-promote ordering.
- **190 interaction.** An automated governance-surface rewrite is exactly what 190 guards against; shipping without the reconciliation either trips the guard or weakens it. Mitigate by treating the 190 reconciliation as a hard dependency, not a footnote.
- **Per-release diff churn.** Mitigate via deterministic generation (Part 1) so the only diffs are real version deltas.
- **Adoption friction.** A hard drift gate that fires before generation is fully deterministic would block unrelated PRs. Mitigate via warn-then-block phasing gated on Part 1 landing.
