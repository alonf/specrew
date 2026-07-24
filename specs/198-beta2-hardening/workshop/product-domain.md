# Product-Domain Record: 0.40.0-beta2 Hardening Bundle

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Depth**: standard
**Confirmation**: human-confirmed (lens-question, 2026-07-09)

## Depth rationale

Later feature in a well-known product (normally Light), but release-blocking
(stable 0.40.0 held per DEC-197-REL-001), multi-iteration (~15-25 SP), and it
touches every consumer project's trust surfaces. Discovery cost is low because
proposals 203/204/205 and issue #2906 carry field-verified evidence (run IDs,
ledger entries), so Standard was pre-filled from the proposals and confirmed
with the maintainer. Deep is not warranted: no new product, segment, or
regulated domain.

## Users and stakeholders (known)

- Downstream consumer developers/agents — inherit broken CI templates,
  self-leaked methodology, silent boundary bypass, and wrong per-host review
  budgets from `specrew init`.
- The maintainer/release owner — stable 0.40.0 is held on this bundle.
- Reviewer agents on all four hosts — harmed by missing stripped-paths
  teaching and flat timeout defaults.
- The Specrew governance trust story itself.

## Pain and cost of doing nothing (known, field-evidenced)

Four defect classes from the F-197 dogfoods and the beta-1 E2E:

1. Reviewer containment/identity gaps — instructional-only filesystem
   confinement, digest/worktree divergence, absent stripped-paths teaching
   (Proposal 203).
2. Broken-by-construction consumer distribution plus self-leak of
   Specrew-self facts into consumer surfaces (Proposals 204/205).
3. p0 silent boundary-approval bypass on non-stopping hosts —
   `Test-SpecrewBoundaryAuthorization` is dead code (issue #2906).
4. beta-1 E2E frictions — round-ceiling chicken-and-egg, budget kills at the
   flat 300s default, tracker-edit-staled review evidence (203 W11–W16).

Doing nothing keeps stable held and ships the defects to every fresh consumer.

## Existing system and context (known)

Pure hardening of shipped 0.40.0-beta1. Every fix lands in an existing seam:
`reviewer-host-catalog.ps1` (the only harness-data seam), the deploy
manifest/template surface, `sync-boundary-state.ps1` / `shared-governance.ps1`,
refocus/prompt content, and the Spec-Kit/Squad version pins.

Toolchain context: Spec-Kit 0.8.4 → 0.12.9 (breaking at 0.10.0: `--ai` family
removed in favor of `--integration <key>`; git extension opt-in; agent-context
extension full opt-in at 0.12.0; per-event hook lists with priority ordering).
Squad 0.9.1 → 0.11.0 (no breaking notes).

## Binding constraints (known)

Host-neutral core (catalog is the only harness-data seam); T096 (human-typed
remediations/acks/budget increases only); D5 (full+independent blocking
verdicts never agent-overridable); `specs/`, `proposals/`, `docs/`, `tests/`
are digest identity; ProviderMirrorParity; Specrew.psd1 FileList for new
shipped files; markdownlint --fix before every commit; the tag-push workflow
auto-publishes prereleases; never run agentic CLI probes in a governed cwd.

## Outcomes and success metrics (known)

- v0.40.0-beta2 ships all four work streams plus both toolchain bumps.
- The beta-1 E2E frictions do not reproduce on a fresh consumer E2E against
  published beta2 bits.
- Issues #2909 and #2903 close.
- Stable 0.40.0 unblocks after the maintainer's separate manual PASS.

## MVP and non-goals (known)

**MVP**: the four streams as triaged — 203 W1–W16, 204 W1–W7, 205 W1–W6,
the issue-2906 detect-at-next-stop fix, the toolchain bumps — released as
v0.40.0-beta2 (ModuleVersion 0.40.0, Prerelease 'beta2').

**Gate reading (maintainer-confirmed)**: the beta2 gate is *all four streams
landed with conditionals honestly resolved* — 203-W4 stays evaluate-first (may
resolve to not-pursued), 203-W7 is a decision item — not "every W item
implemented".

**Non-goals**: model/quota fallback (Proposal 102); the board-sync feature
(Proposal 101); non-GitHub forges; 204-W6 (design note only); cross-host
sandbox APIs; automatic bounded budget escalation.

## Alternatives (known)

No competing alternative — this hardens the shipped product. The rejected
alternative is promoting stable with known trust gaps; DEC-197-REL-001
explicitly holds stable on this bundle.

## Adoption and rollout (known)

beta2 publishes automatically on tag push (prerelease). Existing consumers
heal via `specrew update` (204-W5 obsolete-file surface + #2903 refocus-scopes
sync). Fresh consumers get the consumer-ized surface via init (204-W1/W3, W5b
bootstrap commit). Stable promotion is a separate maintainer PASS after a
fresh consumer E2E on the published beta2 bits (maintainer-confirmed).

## Follow-up research (non-load-bearing)

- Verify against the installed Spec-Kit 0.12.9 CLI: `--script ps` and
  `--ignore-agent-tools` survive; `extension.yml` hooks schema loads under
  0.12; whether our flow needs `specify extension add git`.
