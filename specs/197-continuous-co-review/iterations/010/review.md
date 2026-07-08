# Review: Iteration 010

**Schema**: v1
**Reviewed**: 2026-07-08
**Overall Verdict**: accepted

## Review method

Runtime-evidence review of all 12 tasks (26.00/26.00 SP incl. the T111 send-back, boundary commits
`083c8607`…): per-task Pester evidence on Windows AND WSL (the R5/T100 hard gate), the full-suite
sweep (final: 252/252, 2 env-guarded skips), mechanical lenses (zero findings), and — decisively — **live
adversarial co-review by independent reviewers on TWO different harnesses** (codex, then antigravity
after codex went hard-down) through both doors (inline + navigator auto-fire), whose blocking findings
were fixed maintainer-approved same-day and re-verified. This iteration's review activity is the
feature's own machinery reviewing the feature, PLUS the human maintainer's architecture review
(which caught D-197-I010-002).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T091 | FR-037, SC-024, NFR-001 | pass | Inline spawn consolidated onto the shared OS containment; duplicate inline kill DELETED (contract-tested); the Add-Type pre-assignment escape window found+fixed during the WSL gate. Windows+WSL 14/14. |
| T093 | FR-035, FR-016, SEC-004 | pass | Independence is a first-class label (independent/same-host/unverified) flowing selection→status→registry→reap; same-host fires immediately labelled; `--host` honoured-or-surfaced. 7/7 + live validation (codex selected independent of claude). |
| T094 | FR-036, SC-019, SC-020, SC-024 | pass | 3-dimension evidence labels on every promoted run; full+independent auto-allows; partial/same-host/unverified needs the recorded first-class ack (`--ack-degraded`); never deadlocks (the block names the exact ack command). 8/8 + 51/51 gate suites. |
| T096 | FR-038, FR-024, FR-025 | pass | 5-option remediation menu on any problem run; choice carried one-shot via round-state; human-directed reruns never auto-ceiling-halted; scoped reruns honestly partial; D5 override refuses full+independent blocks. 9/9. Exercised for real: three maintainer-authorized verification reruns rode this mechanism. |
| T099 | FR-040, SC-025 | pass | The expensive transcript parse gates on boundary/material/retry only (the `$anySpec` per-stop tax removed); conversational stops verified cheap (no parse, no journal). Mirror parity green. |
| T100 | FR-039, SC-025, NFR-001 | pass | Job Object KILL_ON_JOB_CLOSE (Win) + setsid/PGID (Unix) atomic containment; session-scoped registry (child pids); child-aware reaper; `terminal_reason` everywhere. Dead-supervisor orphan tests BOTH directions, Windows+WSL. |
| T106 | FR-029, NFR-005 | pass | Latch wired (_load + navigator + transcript threading); surface-once→latch-quiet proven on real transcript shapes; only a REAL human turn closes (machine-forgery gate held); real bugs never latch; convergence clears. 6/6 integration. Live-exercised by the auto-fired escalation this session. |
| T107 | FR-017, FR-018, FR-021, SEC-007, SC-013, SC-014 | pass | Every TO-FOLD manifest row grafted into the REAL outbound slim prompt and asserted; every DROP row asserted absent; file retired to docs/reference/ (off FileList, manifest valid). Contracts 24/24. |
| T108 | FR-033, SC-024 | pass | Host-generic retry-once on empty exit-0 + cause diagnostic. **Fired on real codex flakes 3× this session** (2 recovered, 1 double-flake failed LOUDLY exit-1 — never-false-green held in production). |
| T109 | FR-040, SC-025 | pass | Forensic on the real dogfood corpus (21 records, 8 blocks): **D-197-I009-003 CLOSED refuted-with-evidence**; permanent reopen-on-signature analyzer shipped; no mitigation re-added per the approved N7 default. |
| T110 | SC-012, SC-022 | pass | claude (code-writer, live hooks) + codex AND antigravity (independent reviewers, both doors) exercised end-to-end — antigravity wired same-day via the catalog seam alone when codex went hard-down; copilot/cursor-agent recorded installed-but-unauthorized. Evidence: quality/cross-host-validation.md. |
| T111 | FR-009, FR-011, SC-024 | pass | Maintainer send-back (DEC-197-I010-004): digest-bound machine-recorded test evidence + exact-digest-match worktree injection + gated prompt substitution rule; never-false-green intact (only recorder output has evidence standing). 7/7 new tests; full suite 252/252 after the change. The closing co-review run over this tree is the mechanism's own first consumer. |

## Live co-review outcome (the feature reviewing itself)

- Runs `20260708T094626098` (inline) + `20260708T094838294` (auto-fire): 2 blocking findings, ceiling
  escalation honored, **human decision demanded and obtained** (maintainer approved the repair path).
- **f1 (blind-context review)**: fixed — durable design-context fallbacks (feature.json →
  start-context → single-spec), empty context RECORDED + reviewer told + run degraded to the ack tier.
  Verified RESOLVED by run `20260708T101433191`.
- **f2 (harvest schema laxity)**: fixed — full item-schema normalization incl. the verification-round
  residual (line-number minimum 1), validated against the real contract schema in tests.
- Final verification round: see the run record appended to quality/cross-host-validation.md.

## Gap Ledger

- Turn-end auto-review f1 (run 20260708T112353271: the launcher's post-spawn registry write could clobber a fast supervisor's child containment evidence, T100/SC-025): merge-not-rewrite + terminal re-assert belt + a mocked fast-supervisor race regression test: fixed-now
- Turn-end auto-review f2 (same run: the Unix detached service spawn passed Windows-only -WindowStyle and failed on WSL/Linux before the reviewer started): flag removed from the Unix branch + a real-branch WSL regression test (detached-service-spawn-unix): fixed-now
- Codex escalation f1 (silent blind-context reviews, FR-011-adjacent): durable fallbacks + record/degrade/tell shipped and re-verified: fixed-now
- Codex escalation f2 (schema-invalid partial harvest vs findings-result.schema.json) incl. the line-minimum residual: full normalization shipped, schema-validated in tests: fixed-now
- D-197-I010-002 (maintainer finding: harness names hardcoded in the CCR core vs FR-016/SC-022): catalog-derived independence rule + loud fallbacks + mandatory -HostName + governance guard test: fixed-now
- Verification round (antigravity run 20260708T115526673, 3 blocking + 2 advisory): teaching docs and test contracts lagging this iteration's own doctrine decisions (review-signoff refocus baseline-anchoring, code-implementation lens host-neutral wording, review-command Test 5 legacy pipeline) plus two honesty items (fabricated tasks-progress timestamps, unrecorded drift) — all corrected, recorded as D-197-I010-003: fixed-now
- Round-ceiling escalation (antigravity run 20260708T211331029, the FIRST T111-evidence consumer, 141s): reviewed identity ≠ certified identity — the worktree archived HEAD while the gate digested the working tree, so uncommitted changes could be certified as reviewed unseen (FR-025 false-allow; dirty-tree-only exploit; no existing evidence tainted — all runs were clean-tree). Maintainer fix-now decision: the worktree now materializes FROM the digest's own tree object, one identity by construction; --live now reviews uncommitted work; dirty-tree regression tests added (254/254). Recorded as D-197-I010-004: fixed-now
- Navigator auto-fire finding (codex run 20260708T225439577, round 1, 132s — fired unprompted on the proposals checkpoint): the AUTO-path dedup still keyed on HEAD^{tree}, so dirty increments were deduped as already-reviewed, bypassing the D-197-I010-004 fix on the auto path (gate digest-freshness backstop held — coverage gap, not certification hole). Maintainer fix-now: checkpoint identity = the certified digest (HEAD fallback) for dedup AND pending registration; content-addressed key regression tests (257/257). Recorded as D-197-I010-005: fixed-now
- SC-022 harness breadth (copilot/cursor-agent installed-but-unauthorized on this machine): the antigravity leg of this defer was DISCHARGED in-iteration (installed+authorized 2026-07-08, exercised end-to-end as the independent reviewer — see quality/cross-host-validation.md); the remaining copilot/cursor-agent breadth stays deferred per the N8 installed+authorized scope rule and the maintainer decision recorded in .squad\decisions.md: deferred
- Same-host fallback strongest-model upgrade + reviewer-failure classification/opt-in fallback chain (maintainer Q3/Q4 recommendations, agreed 2026-07-08, recorded in .squad\decisions.md): post-0.40.0 fast-follows, not release-blocking (current behavior safe-and-surfaced): deferred

## Notes

- Capacity: 26.00/26 delivered (24.00 planned + the 2.00 T111 send-back, which consumed the approved
  cap's headroom exactly; variance 0 against the cap). The unplanned work items (the maintainer's
  host-neutrality finding, the codex escalation fixes, and the T111 send-back) were absorbed within
  the approved capacity without displacing planned scope.
- Codex reliability diagnostic (D-197-I009-015 follow-through): 3 empty-exit0 events in 4 real runs
  today — the ~50% field rate is CONFIRMED by the T108 diagnostic (2× finalization-or-capture-gap,
  1× no-output-produced). The retry recovers singles; a double-flake fails loudly. This evidence
  feeds the Q4 fast-follow (failure classification + opt-in fallback chain).
- Drift: 5 events + 1 carried-finding closure, all resolved — see drift-log.md.
