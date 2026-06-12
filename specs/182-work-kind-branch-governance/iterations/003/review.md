# Review: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-12
**Overall Verdict**: accepted
**Method**: Proposal 145 structured multi-phase reviewer (candidate; rules applied manually — no
shipped 145 validator/skill exists yet).
**Tree Under Review**: `1905760b` (HEAD; the D-304 broad-sweep completion fix); implementation diff
baseline `6d22dc85` (before-implement boundary).
**Review history**: single pass. The review's own SC-008 broad-verification step surfaced one residual
(D-304) that the shipped narrow sweep missed; it was neutralized + the sweep widened **in place under
maintainer direction** (commit `1905760b`) before this accepted verdict was recorded — analogous to a
rework round but lighter (one finding, fix-in-place, no needs-rework verdict issued). The finding +
fix are preserved in git history and recorded under "Finding closed during review" below.

## Summary

Iteration 003 (the **forge-neutralization migration**, FR-019 — the feature's final slice) decouples
Specrew's *downstream-governing* surfaces from Specrew's own GitHub-dev habits **without changing
Specrew's own GitHub usage**. The change set is exactly the inventory's confirmed couplings: the shared
closeout-SDLC prose (G1–G3, coordinator sources), the assembled lifecycle-prompt view (G4 = the runtime
view of G1–G3, D-301), the reviewer-routing script (G5, `shared-governance.ps1`), plus the methodology
deltas D1 (`lifecycle-discipline.md`), D2 (`proposal-discipline.md`, D-303) and D3 (the two methodology
index docs, D-304). Everything else (own-infra, the GitHub host adapter, false positives) is no-change.

**Verdict: accepted.** Every requirement in iteration-3 scope (FR-019 → SC-008, SC-013) is implemented
and evidenced on the tree under review. The one real gap the review surfaced (D-304) is committed-fixed
and regression-guarded. No FR/SC gap is open. Verdict aggregation (Proposal 145): every task `pass`,
every Gap Ledger entry `fixed-now` → **APPROVE for review-signoff**.

**Verification state (replayed this pass)**: forge-neutral-reviewer 10 PASS; forge-neutralization-sweep
7 assertion-groups PASS (incl. the new D-304 registry-clean assertion); pr-review-integration 7 PASS
(isolated run, ~180s — a genuinely slow suite, green); host-coupling-firewall 2 PASS;
work-kind-validator 12 PASS; work-kind-runtime 19 PASS. PSScriptAnalyzer (`-Settings PSGallery`):
**production code 0 errors and 0 NEW warnings** (G5 leaves `shared-governance.ps1`'s warning profile
byte-identical: baseline 47 = HEAD 47, every category). markdownlint **0 errors** (edited docs + repo CI
scope). `validate-governance` re-run on iterations 001/002/003 **after** authoring this review (the run
that actually exercises the accepted-verdict checks). `.specify` mirror of `shared-governance.ps1` in
SHA256 byte-parity.

## Finding closed during review (D-304 — the one real finding)

- **D-304 — the shipped narrow sweep had a gate-coverage directional blind spot.** The committed T306
  sweep (`20d4ce97`) checked four mandate tokens (`gh pr create/merge`, `Find/Install-Module Specrew`).
  The review's SC-008 **broad-verification grep** (a wider forge-token sweep run to verify the criterion
  rather than trust the self-test) found `PSGallery` named as a heading-descriptor of
  `lifecycle-discipline.md`'s Release Process Discipline section in two **downstream-governing
  methodology index docs** — `docs/methodology/README.md` (lines 9, 19) and
  `docs/methodology/review-instructions.md` (line 18) — with **no example label**. The iter-1 inventory
  had even inspected `review-instructions.md` and recorded it "already neutral", missing the descriptor.
  This is exactly review-signoff Rule 6 (gate-coverage skepticism: a gate must cover what its spec
  claims, both directions) doing its job. **NOT "the sweep was complete."**
- **Resolution (maintainer-directed, committed `1905760b`):** the registry-name descriptors were
  genericized to `package-registry` / `prerelease-vs-stable` (the index now points at the
  already-labeled section neutrally); the T306 sweep's token set was **widened** to add the
  registry-name class (`PSGallery` / `powershellgallery` / `PowerShell Gallery`, file-level marker
  tier), with `specrew-update` allowlisted as own-infra and a positive assertion proving both index docs
  are registry-clean. Recorded as inventory delta D3 + drift D-304.

## Phase 0 — Context load

- Read in full: `spec.md` (FR-019, SC-008, SC-013, US2, US5), the iteration-3 plan, the
  neutralization-inventory, the iteration-3 state/drift/hardening-gate, the Iteration-1
  `forge-coupling-inventory.md` (the source of truth), and every surface in the change set (the three
  coordinator sources, the G5 script diff, the four methodology docs).
- Iteration-3 scope (plan.md): **FR-019** → **SC-008** (no-over-claim sweep), **SC-013** (inventory
  complete + migrated surfaces carry no GitHub-only mandate + own infra unchanged); user stories US2
  (governance real on any forge) + US5 (the adapter is the only forge seam).
- Out of scope (not gaps): T013b release-prep (carried, D-001); the Iteration-2 dashboard WARN
  (confirm-not-harden carry-item); FR-007/011/012/013/015/016/020/021 (Iter-2 runtime, complete);
  FR-001..006/008..010/014/017/018 (Iter-1 methodology, complete).

## Phase 1 — Branch hygiene

- Branch `182-work-kind-branch-governance`; working tree clean except untracked/modified
  `.specrew`/`.squad` session+cache files (correctly left unstaged).
- Iteration-3 commits from the before-implement baseline `6d22dc85`: `3dfbc3ea` (T301–T303
  methodology-wording), `e2a6fca7` (T304–T305 G5 opt-in reviewer), `20d4ce97` (T306–T308 verification),
  `58b42ded` (D-302 `.specify` mirror sync), `1905760b` (D-304 completion fix).
- Each is a focused `boundary(implement)` / `chore` / `fix` commit; CI Lint scope green on the branch.

## Phase 2 — Functional correctness + claim-to-code + workshop conformance

Every neutralization was verified by **reading the changed surface**, not the summary (see the
inventory-to-code trace + claim ledger):

- **G1/G2/G3 (closeout SDLC prose)** — `coordinator-decision-guidance.md`, `coordinator-response.md`,
  `specrew-governance.md` now instantiate each closeout step "from the project's
  `.specrew/repository-governance.yml` … never assume a specific forge or package registry", and carry
  a clearly-labeled **"Specrew's own instantiation (a Specrew-specific example, NOT a downstream
  mandate)"** clause preserving Specrew's own `gh` + PSGallery steps (DP-1 (b)).
- **G4 (assembled lifecycle view)** — confirmed (D-301) to be the runtime-assembled view of G1–G3, not a
  separate artifact; neutralized by the G1–G3 edits.
- **G5 (reviewer routing)** — `Get-SpecrewAutomatedReviewOptIn` reads `review_gate.automated_review`
  from `.specrew/repository-governance.yml`; `Test-HostProvidesAutomatedPrReview` now returns inactive
  unless the project **opted in** AND the configured provider's capability is present. Default OFF; a
  non-GitHub/un-opted forge bakes in no Copilot. Verified against the code + the parser against Specrew's
  real governance file (2/4/6-space block → `Enabled=true`, `provider_suggestion=copilot`).
- **D1 (`lifecycle-discipline.md`)** — Repository Conventions + Post-Merge SDLC relabeled **"Specrew's
  own example … NOT a downstream mandate"** (DP-2).
- **D2 (`proposal-discipline.md`, D-303)** — `gh pr create` → "open a PR/MR via your forge (the provider
  adapter describes how)". **Maintainer-ratified at the review boundary: keep as inheritable
  methodology** (it lives under `docs/methodology`; downstream users can reasonably copy its process
  language; the generic PR/MR wording is correct). Recorded as ratified, not re-litigated here.
- **D3 (the two index docs, D-304)** — registry descriptors neutralized (see "Finding closed").
- **Workshop conformance: N/A.** Iteration 3 is a mechanical neutralization/migration — there is no
  design-workshop surface, lens decision, or co-design artifact in scope. The Prop-145 workshop-conformance
  slot is explicitly N/A, not silently dropped.

## Phase 3 — Non-functional requirements

- **Forge-neutral default (the core invariant):** the G5 opt-in **fails open to disabled** — no
  governance file, or no opt-in, yields human-review-only with no baked-in reviewer. The privileged
  posture (an automated reviewer) is the opt-in, not the default. Behaviourally proven (forge-neutral-reviewer T305).
- **Parser brittleness (honest watch-item):** `Get-SpecrewAutomatedReviewOptIn` is an indentation-based
  hand reader (matches `automated_review:` at 4-space, `enabled:`/`provider_suggestion:` at 6+). It is
  correct for Specrew's canonical 2/4/6 YAML and the test fixtures, and **fails open to disabled** on
  any shape it does not recognize (the safe direction). A non-standard indentation in a downstream
  governance file would silently read as opted-out — a maintenance surface as the schema evolves
  (consistent with the iter-2 hand-rolled-YAML watch-item), not a defect.
- **No new dependency / no secret held:** G5 adds no dependency; the reviewer routing still uses the
  caller's `gh auth` only on the opted-in GitHub path.

## Phase 4 — Code quality + anti-patterns + dependency reality

- **PSScriptAnalyzer (`-Settings PSGallery`): production code 0 errors, 0 NEW warnings.** Proven by a
  baseline-vs-HEAD diff of `shared-governance.ps1`: **47 warnings at `6d22dc85` = 47 at HEAD**, every
  rule category identical (`PSUseSingularNouns` 22, `PSUseShouldProcess` 11, `PSUseApprovedVerbs` 6,
  `PSAvoidUsingEmptyCatchBlock` 5, `PSUseDeclaredVarsMoreThanAssignments` 3). The G5 change introduced
  **zero**; all 47 are pre-existing in this large shared file (out of iteration-3 scope; the repo's
  convention queues such warnings via Proposal 037 rather than suppressing — same treatment as iter-2).
  The one warning inside the G5-touched line range (L343 empty catch) is the pre-existing `git remote`
  block, present unchanged at baseline.
- **New test files: 3 minor PSGallery warnings** — `forge-neutral-reviewer.tests.ps1` `PSUseShouldProcess`
  ×2 (the `Write-Pass`/`Write-Fail` helpers — a known analyzer false-positive on test helpers; iter-2's
  *accepted* `work-kind-validator.tests.ps1` carries the same warning) and `forge-neutralization-sweep.tests.ps1`
  `PSUseSingularNouns` ×1 (`Get-MarkdownSections`, which genuinely returns a collection). Consistent with
  repo test-file convention; production code is the gated bar and is clean.
- No dead code in the iteration-3 surface; the `gh` dependency stays confined and fail-open.

## Phase 5 — Test coverage + gate completeness + evidence replay

Evidence replayed this pass (commands re-run on the tree under review):

- `forge-neutral-reviewer.tests.ps1` → 10 PASS (opt-out default; `enabled:false` inactive;
  opted-in-without-capability inactive; non-GitHub never bakes in Copilot; inline-comment tolerated;
  routes through the opt-in gate).
- `forge-neutralization-sweep.tests.ps1` → 7 assertion-groups PASS (no bare mandate across 43
  downstream-governing surfaces; 4 change-surfaces carry the labeled example; **2 index docs
  registry-clean — the new D-304 guard**; allowlist inventory-backed; SC-013 own-infra unchanged; T308
  own opt-in active; T308 own gh+PSGallery steps still documented).
- `pr-review-integration.tests.ps1` → 7 PASS (isolated, ~180s; it is a slow suite — an earlier
  concurrent run tipped it over a 180s cap, isolated it is green; includes the SHA256 mirror-parity
  assertion for `shared-governance.ps1`).
- `host-coupling-firewall.tests.ps1` → 2 PASS; `work-kind-validator.tests.ps1` → 12 PASS;
  `work-kind-runtime.tests.ps1` → 19 PASS (G5's wider blast radius — unrelated `shared-governance.ps1`
  consumers — confirmed unbroken).
- markdownlint (CI scope) → 0 errors; `validate-governance` → PASS on iters 001/002/003 (re-run after
  this review; WARNs are pre-existing handoff-evidence, exit-code-independent).
- **Gate-coverage honesty (Rule 6):** the codified SC-008 sweep now guards two token classes (forge
  mandates section-level; Specrew-publish + registry file-level). It does **not** prove the absence of
  every conceivable forge mandate — the one-time broad-verification grep is the backstop that found
  D-304. "SC-008 satisfied" means: no over-claim on the swept surfaces + the broad grep is clean, not
  "the codified sweep catches all forge couplings forever."

## Phase 6 — System safety + operations

- **No privileged surface added.** G5 only narrows when an automated reviewer is reported active
  (opt-in + capability), strictly reducing baked-in behaviour. The validator consumes
  `Test-HostProvidesAutomatedPrReview` for a soft, try/catch-wrapped, **exit-code-independent** PR-review
  warning only; the opt-in gate suppresses that warning for un-opted projects (fail-open) and preserves
  it for Specrew's own opted-in repo. No closure/blocking behaviour changed.
- **Own-flow preserved (SC-013 + T308):** Specrew's own governance still opts into automated review
  (`provider_suggestion=copilot`), and the labeled examples still document Specrew's own `gh` + PSGallery
  closeout — usable for Specrew, example-only for downstream. Own infra (`.github/workflows`,
  `specrew-version`, the installer, the `templates/github` adapter) verified unchanged.

## Phase 7 — Output synthesis + report falsification

I attempted to falsify the accept before recording it:

- *Did widening the sweep break it or false-positive?* Re-ran: 7 assertion-groups PASS; the scanned
  count moved 44→43 exactly because `specrew-update` is now correctly allowlisted. No false positive.
- *Did G5 secretly add analyzer debt?* Baseline-vs-HEAD diff of `shared-governance.ps1`: 47=47, delta 0.
  No.
- *Is the D-304 fix honestly framed?* Recorded as a shipped-sweep blind spot found post-implementation,
  not as "the sweep was always complete". Yes.
- *Is `validate-governance` green on the REVIEW state, not just the executing state?* Re-run after
  authoring this review (verdict=accepted, status=reviewing) — the run that activates
  `Test-NoGapClosurePolicy` + `Test-ReviewEvidenceTreeIntegrity`. PASS.
- *Any over-claim?* The parser brittleness, the slow pr-review suite, the 47 pre-existing warnings, and
  the codified-sweep bound are all recorded as honest limits, not hidden. No over-claim found.

## FR × phase coverage matrix (iteration-3 scope)

| Requirement | P2 functional | P3 NFR | P4 quality | P5 tests/gates | P6 safety/ops | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| FR-019 decouple downstream-governing surfaces | pass (G1–G5 + D1–D3) | pass (fail-open default) | pass (0 new warnings) | pass (sweep + G5 tests) | pass (own-flow preserved) | pass |
| SC-008 no-over-claim sweep | pass (no bare mandate) | pass | pass | pass (7 groups + broad grep) | pass | pass |
| SC-013 inventory complete + own infra unchanged | pass | n/a | pass | pass (own-infra asserted) | pass (diff-verified) | pass |

## Claim-to-evidence ledger

| Claim | Evidence replayed | Verdict |
| --- | --- | --- |
| forge-neutral-reviewer 10 assertions green | re-ran: 10 PASS | true |
| forge-neutralization-sweep all groups green | re-ran: 7 assertion-groups PASS (incl. D-304 guard) | true |
| pr-review-integration green (+ mirror parity) | re-ran isolated: 7 PASS, exit 0 (~180s) | true |
| G5 introduced 0 new analyzer warnings | baseline 47 = HEAD 47, every category, delta 0 | true |
| markdownlint 0 errors | re-ran CI scope: 0 | true |
| validate-governance PASS (review state) | re-ran iters 001/002/003 after authoring review | true |
| `.specify` shared-governance mirror in parity | SHA256: 1 distinct hash | true |
| opt-in default OFF; non-GitHub bakes in no reviewer | forge-neutral-reviewer T305 behaviour-proven | true |
| Specrew's own gh+PSGallery flow still documented/usable | T308 assertions green | true |
| D-304 caught by broad verification, not the shipped sweep | shipped sweep = 4 tokens; broad grep found it; widened in 1905760b | true |

## Inventory-to-code trace

| Inventory item (disposition) | Code / surface | Conformance |
| --- | --- | --- |
| G1–G3 closeout SDLC → genericize + labeled example (DP-1 b) | 3 coordinator sources: "instantiate from `.specrew/repository-governance.yml`… never assume a forge" + labeled Specrew example | satisfied |
| G4 → assembled view, verify (D-301) | runtime view of G1–G3; no separate artifact | satisfied |
| G5 reviewer routing → adapter opt-in | `Get-SpecrewAutomatedReviewOptIn` + gated `Test-HostProvidesAutomatedPrReview`; default OFF | satisfied |
| D1 `lifecycle-discipline.md` → label as Specrew example (DP-2) | Repository Conventions + Post-Merge SDLC relabeled "NOT a downstream mandate" | satisfied |
| D2 `proposal-discipline.md` → genericize (D-303) | "open a PR/MR via your forge"; **maintainer-ratified keep** | satisfied |
| D3 index docs → neutralize registry descriptors (D-304) | README.md + review-instructions.md → `package-registry`/`prerelease-vs-stable`; sweep widened | satisfied |
| Own-infra / host-adapter → NO CHANGE (SC-013) | `.github`, `specrew-version`, `specrew-update`, installer, `templates/github` unchanged; asserted | satisfied |

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T301 | FR-019 | pass | G1–G3 closeout prose neutralized + labeled example in all 3 coordinator sources; bare mandate = 0. |
| T302 | FR-019 | pass | G4 = assembled view of G1–G3 (D-301); neutralized by T301; verified no bare mandate survives. |
| T303 | FR-019 | pass | D1 `lifecycle-discipline.md` Repository Conventions + Post-Merge SDLC relabeled Specrew-own-example (DP-2). |
| T304 | FR-019 | pass | G5 opt-in gate (`Get-SpecrewAutomatedReviewOptIn`); default OFF; mirror synced; 0 new analyzer warnings; pr-review-integration green. |
| T305 | FR-019 | pass | 10 assertions green (opt-out default; non-GitHub never bakes in Copilot; capability-gated). |
| T306 | SC-008 | pass | Section-aware + file-level sweep; **widened to the registry class after the broad-verification caught D-304**; 43 surfaces; allowlist inventory-backed. |
| T307 | SC-013 | pass | Own-infra/host-adapter still carry their GitHub usage; allowlist inventory-backed; own infra diff-verified unchanged. |
| T308 | FR-019 | pass | Specrew's own governance opts in (active reviewer); labeled example preserves Specrew's gh+PSGallery steps. |

## Gap Ledger

- No requirement (FR/SC) gaps in iteration-3 scope; FR-019 → SC-008 + SC-013 all implemented + evidenced on the tree under review (T013b + the dashboard WARN are carried phasing, not gaps): fixed-now.
- D-304 review finding (the shipped narrow sweep missed a `PSGallery` descriptor in two downstream-governing index docs) neutralized in place + the sweep token set widened to regression-guard the class, committed `1905760b`: fixed-now.
- D-303 (`proposal-discipline.md` genericization) maintainer-ratified at the review boundary as inheritable methodology — keep; not a gap: fixed-now.
- D-302 (`.specify` `specrew-governance.md` mirror carried pre-neutralization prose) synced to match the neutralized source, committed `58b42ded`: fixed-now.

## Notes

- The D-304 finding + fix are preserved in git history (`1905760b`); this single-pass review records the
  accepted verdict after the in-review completion.
- Carried (not iteration-3 gaps): T013b release-prep (D-001); the Iteration-2 dashboard WARN
  (confirm-not-harden at feature-closeout); the `Get-SpecrewAutomatedReviewOptIn` hand-YAML parser
  maintenance watch-item; the codified-sweep token-class bound (the broad grep is the backstop).
- **Stop at review-signoff for the maintainer's verdict; no push, PR, merge, tag, publish, release, or
  retro/closeout/Iteration-4 work.** Verdict: **APPROVE for review-signoff.**
