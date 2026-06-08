# Review: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-09
**Overall Verdict**: accepted

Structured per Proposal 145 (7-phase reviewer + claim-to-evidence). Matrix, claim ledger, and
design-code trace in [review-report.yml](./review-report.yml). The implementation report is treated
as a claim to disprove. This is the FINAL iteration: it closes both carried live-wiring deferrals
(D-001 + D-002) and completes the feature scope.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T021 | FR-001, FR-005 | pass | D-001 downstream deploy; LIVE cross-host SessionStart smoke green (claude/codex/copilot/cursor). |
| T022 | FR-009 | pass (qualified) | D-002 SessionEnd provider + Claude host-hook; deployed config ON DISK carries SessionEnd (closure test); deployer-registers + dispatcher->handover round-trip auto-proven. Real session-end FIRING = SC-008 manual beta. |
| T016 | FR-005 | pass | Defensive multi-key per-host event normalization (snake_case + camelCase). |
| T017 | FR-005, SC-001, SC-005 | pass | Per-host adapter test (4 hosts) + the live cross-host render smoke. |
| T014 | FR-018 | pass | Advisory SessionStart marker write + read. |
| T015 | FR-018, FR-019 | pass | Same-worktree concurrency (fresh=advisory, stale=unclean-exit, no lock). |
| T018 | SC-007 | pass | HookJournalAccessor + all 3 modes distinguishable in the journal. |
| T019 | FR-011, FR-012, SC-005 | pass | B1/B3 unchanged (additive); no B4/Antigravity path. |
| T020 | FR-008, SC-006 | pass | getting-started.md: hook = primary bootstrap, specrew start = compat. |

## Seven-Phase Structured Review (Proposal 145)

- **Phase 0 - Context load**: pass. Loaded spec.md, iterations/003 plan + hardening-gate, the
  decisions carries (`f174-i003-livewiring-first`), Proposal 130, and the F-171 dispatcher + deployer.
- **Phase 1 - Branch hygiene**: pass with one info. All evidence committed; per-task boundary commits
  (`f51baaf3`/`a41c4f2c`/`0a9f7b23`/`e68a2ffa`/`fce895f2`/`916f3d31`/`4b433f96`/`1de2a45a`). Info:
  branch unpushed (push at feature-closeout).
- **Phase 2 - Functional correctness**: pass (D-002 qualified). D-001 is proven by a real cross-host
  SessionStart dispatcher smoke (4 hosts). D-002's auto-provable chain is proven to the dispatcher
  boundary AND the deployed config on disk now carries the SessionEnd hook (the iteration-003
  send-back fix): deployer-registers (scratch test) + the worktree `.claude/settings.local.json`
  carries SessionEnd dispatching `-Event SessionEnd` (`DeployedHostConfig.Tests` reads the committed
  config on disk) + dispatcher `-Event SessionEnd` -> handover -> SessionStart welcome-back round-trip.
  **The remaining link - the Claude host actually invoking the hook on a real session-end - is NOT
  auto-provable and is an SC-008 manual-beta confirmation; "proven LIVE" is qualified to that bar.**
  Two real gaps were surfaced and FIXED: (a) the launcher dedupe keyed on `last-start-prompt.md` which
  boundary syncs rewrite (false dedupe) -> dedicated launcher marker; (b) **the original review
  overstated D-002 as "proven LIVE" while the worktree config carried no SessionEnd** (both prior
  proofs bypassed the host-hook link: scratch deploy + dispatcher-direct smoke) -> deployed from the
  dev tree to the worktree, asserted on disk, added the on-disk closure test, and qualified the claim;
  also fixed a latent iter-001 overlay gap (canonical-id set excluded only `refocus`).
- **Phase 3 - Non-functional**: pass. Fail-open everywhere; SessionEnd write-only; advisory concurrency
  never blocks (no lock); local-tree trust unchanged.
- **Phase 4 - Code quality**: pass. PSScriptAnalyzer clean on all F-174 bootstrap components + both
  providers. The two touched F-171 files (deployer, overlay) carry only PRE-EXISTING style findings
  (BOM, ShouldProcess) not introduced by these additive edits - out of scope to refactor here.
- **Phase 5 - Test coverage + integrity**: pass. 17 bootstrap suites (`tests/bootstrap/*.Tests.ps1`,
  all green) + the F-171 deploy integration green; fixtures are real (a real git repo for the no-`-A` proof; the real dispatcher for the
  cross-host + round-trip + dispatch smokes; the SCRATCH deployer for register-correctness). **The
  send-back evidence-standard fix:** `DeployedHostConfig.Tests` now reads the ACTUAL committed
  `.claude/settings.local.json` ON DISK and asserts the SessionEnd hook is really deployed (not the
  deployer's return object, not a scratch project) - a host-hook claim is only true when the deployed
  config on disk carries it. SC-002/SC-003/SC-007 proven.
- **Phase 6 - System safety + ops**: pass. B1/B3 byte-unchanged (additive provider rows + a new
  SessionEnd event, no dispatcher-logic edit), regression-asserted (T019); the SessionEnd hook rides
  the existing F-171 deployment loop + merge-aware C6 invariants.
- **Phase 7 - Synthesis + falsification**: APPROVE for review-signoff (D-002 qualified). D-001 is live
  on all 4 hosts. D-002 is proven to the dispatcher boundary AND the deployed config on disk
  (closure test); its ONE remaining link - the host invoking the hook on a real session-end - is the
  SC-008 manual bar, stated honestly (the original "proven LIVE" was corrected). Claims map to
  committed files + reproduced smokes; no claim now exceeds its evidence; no new dependencies.

## Gap Ledger

- No PSScriptAnalyzer findings introduced by this iteration (F-174 files clean; the two F-171 files carry only pre-existing style findings): fixed-now.
- No outstanding requirement (FR/SC) gaps: every iteration-003 requirement is satisfied with runtime evidence: fixed-now.

## Scoped Limitations + Supersession (D-002 evolves in iteration 004)

- **Host-capability finding (research-verified):** only Claude exposes a true `SessionEnd`
  (session-end) hook. Codex (`Stop`/`SubagentStop`), Copilot (`agentStop`), and Cursor (`stop`) expose
  only END-OF-TURN events; Antigravity's surface is deferred. So the SessionEnd handover delivered in
  iteration 003 is **Claude-only by host capability, not by choice** - the bootstrap (SessionStart)
  path is live on all four hosts.
- **D-002 trigger pivot -> iteration 004 (decided with the human; drift D-005).** The end-of-turn
  `Stop` event is UNIVERSAL across hosts, so iteration 004 will REPLACE the SessionEnd-only handover
  with a **Stop-event rolling handover**: refresh ONE in-place handover file on each per-host Stop,
  updating only on material change. This is strictly better - **portable** (all 4 hosts) and
  **crash-safe** (the handover always reflects the last completed turn, so a hard-kill with no clean
  exit still leaves a current handover - closing Proposal 130's own "no crash guarantee" gap). The
  iteration-003 SessionEnd provider, dispatcher dispatch, and round-trip all carry over; only the
  trigger + file model change. Decision `f174-i004-stop-event-rolling-handover` in `.squad\decisions.md`.
- **Per-host SessionStart INPUT schemas** are handled by defensive multi-key extraction; the live
  render was proven with a representative event shape, not each host's authoritative payload schema.
  Fail-open covers unknown fields. Follow-up `f174-followup-other-host-sessionend`.

## Notes

- This iteration closed D-001 (downstream deploy) LIVE on all 4 hosts and D-002 (SessionEnd handover)
  on Claude with the deployed config now on disk + an on-disk closure test; the SessionEnd real-firing
  is the SC-008 manual bar. The "build+test != live" review check (iteration-002 retro action) caught
  the original "proven LIVE" overstatement and the missing host-hook registration before sign-off.
- **Dogfood finding (dev-tree validation trap):** the installed beta ships the STALE deployer, so
  host-hook changes MUST be validated by deploying from the dev tree and reading the on-disk config -
  never via `specrew update` (which would run the stale deployer). Recorded as
  `f174-dogfood-dev-tree-hook-validation`.
