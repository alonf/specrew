# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-07-10
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-038 | pass | Scratch-dir probe of the 0.12.9 CLI with recorded evidence (quality/toolchain-probe-evidence.md): --integration surface confirmed live, --script ps / --ignore-agent-tools survive, multi-integration behind --force, git extension evidence-based NOT added, hooks schema loads (12 commands / 4 hooks Enabled). |
| T002 | FR-038 | pass | Init migrated to --integration copilot; palette loop upgraded to --force with new-refusal-text skip handling; all pin surfaces moved together (init defaults, CI env x2, supported-versions.yml, update fallback, preflight text, extension.yml requires + mirror). Real specrew init green on the pinned toolchain (squad-duplicate-rows), deployed-bootstrap-floor + command-surface-deploy + version-info-states + blocker-recovery all exit 0. |
| T003 | FR-039 | pass | Squad 0.11.0 across dependency minimums/CI/validate-versions; scratch probe squad init --non-interactive exit 0 with full .squad layout; suite evidence shared with T002 run set. |
| T004 | FR-037 | pass | SelfLeakDenyList shipped (11 entries, all seven classes, schema_version 1.0, FileList + .specify mirror); shape/compile/class-taxonomy assertions in tests/unit/self-leak-lint.tests.ps1 Test 1. |
| T005 | FR-033 | pass | lint-self-leak.ps1 with manifest-derived consumer-deployed surface (surface == FileList subset proven, Test 8), 0/1/2 exit contract (Tests 2-6), annotation semantics incl. missing-reason-is-red (Tests 3-4), blocking self-leak-lint CI job leads the Specrew CI workflow; real deploy surface GREEN with 25 annotated hits carrying recorded reasons (Test 9 born-clean guard). |
| T006 | FR-034 | pass | docs/methodology/self-leak-firewall.md carries the parameterization rule + resolution-point teaching; red output points at it (Test 7 asserts both the escape syntax and the doc path). |

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements (FR-033, FR-034, FR-037, FR-038, FR-039) verified with paired tests and recorded evidence: fixed-now.
- Old-debt cleanup beyond plan (maintainer-directed 2026-07-10, "a since we need to get rid of old problems"): neutral squad identity/now.md seed, self-facts scrubbed from five agent-history seeds, dangling proposals/145 deep-sources dropped, neutral validate-governance help example: fixed-now.
- Independent-review catch (run 20260710T014752659, codex): the pin sweep missed extension.yml config.defaults.versions (min_speckit/min_squad) and validate-versions.ps1 parameter defaults + doc line + extension README - all five stragglers fixed to 0.12.9/0.11.0 with mirrors synced in the same change: fixed-now.
- Independent-review catch (run 20260710T021347228, codex, temp-fixture PROOF): the annotation check accepted any comment form - a hash-style suppression in .md sanctioned a hit (false-green authorization path). Fixed: form validated per file kind (HTML comment for md; # for ps1/psd1/psm1/yml/yaml/sh/extensionless; kinds with no sanctioned form cannot be annotated - fail-closed); abuse-path Test 4b added (19/19 green): fixed-now.
- Independent-review catch (run 20260710T103527700, codex, citing the feature's own psd1-filelist rule): lint-self-leak.ps1 and docs/methodology/self-leak-firewall.md were missing from Specrew.psd1 FileList - both added (psd1 parse-verified): fixed-now.
- Tracked-debt annotations (7 hits: FR-030 release-model class x5, FR-026 retired-template class x2) are deliberate, reason-carrying markers whose removal is owned by iteration 004 tasks T021-T029; not a gap in this iteration's scope: fixed-now.

## Evidence

- **Machine evidence**: tests/unit/self-leak-lint.tests.ps1 — 19/19 PASS (18 original + abuse-path Test 4b)
  (paired per class + annotation semantics + exit-2 loud failure + surface
  enumeration + real-repo born-clean). Integration:
  version-info-states, bootstrap-asset-blocker-recovery,
  squad-duplicate-rows (REAL init on pinned toolchain),
  deployed-bootstrap-floor, command-surface-deploy — all exit 0.
- **Probe evidence**: quality/toolchain-probe-evidence.md (uvx transcript
  findings + squad probe + suite ledger).
- **Mechanical checks**: quality/mechanical-findings.json — zero findings
  for this iteration.
- **Co-review (final)**: signoff run 20260710T022949913-cdf729a4 (codex, independent, full): ZERO blocking findings, one nit (this stale evidence count - corrected in place). Earlier chain: three navigator runs
  (20260709T224852258, 20260709T231707847, 20260709T231951205); the one
  blocking finding (mode-change) was refuted against the committed tree
  (DRIFT-198-I001-001) and resolved by maintainer-typed ack
  ("approve", 2026-07-10; disposition-f1-human-ack). The round-3 ceiling
  halt is recorded honestly as an escalation, not a clean pass — live
  field evidence for this feature's own W11/W12 scope (iteration 003).
- **Drift**: drift-log.md — 1 event, resolved (the refuted finding);
  drift checks ran live during execution (no batch backfill needed).

## Notes

- Lint gate posture: BLOCKING in this repo from first landing; the
  consumer gateway stays advisory-first and arrives in iteration 004.
- The machine toolchain moved to the pins via the exact CI commands
  (specify 0.12.9, squad 0.11.0) — recorded in the probe evidence.
