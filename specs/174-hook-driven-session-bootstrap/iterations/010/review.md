# Review: Iteration 010

**Schema**: v1
**Reviewed**: 2026-06-13
**Overall Verdict**: accepted (delivered scope) — DF-3/4/5/7 boundary-authoring + verdict-integrity cluster DEFERRED to iteration 011

> **Honesty note — reconstructed at the retro boundary.** This review.md was artifacted at the iteration-010
> retro boundary (2026-06-13) from the GENUINE review evidence performed during the iteration but recorded in
> `state.md` prose rather than a review.md: the Proposal-145 structured-review remediation (`261a969e`,
> `3af59389`, `404bec60`, `09a78f63`, `42f18499`), the four post-implementation findings dispositioned in
> `cf0bbd8c`, and the 5-host round-robin dogfood (`8fe3d75a`, `bf7c4429`). The content reflects review work
> actually done; the artifact is being made honest at closeout, not invented. (This gap — an under-artifacted
> boundary — is itself an instance of the class of issue the feature is fixing, and was caught by the retro
> preflight validator.)

Structured per Proposal 145. Iteration 010 delivered the **lean resume reconciliation** (the iter-009 carry):
SessionStart re-computes the cheap delta instead of replaying a stale snapshot (T001), best-effort conversation
capture (T002), tracking surfacing (T003), and host-universal recovery via `specrew start` (T008). It also
absorbed a large UNPLANNED tail — the Prop-145 structured-review remediation and the codex double-render dedupe —
and is signed off against a **5-host round-robin dogfood**, which validated the delivered machinery AND surfaced
the next iteration's load-bearing work. **Accepted** for the delivered, dogfood-validated scope; the
**DF-3/4/5/7 boundary-authoring + verdict-integrity cluster** is formally **deferred to iteration 011** (decisions
locked in `iterations/011/fix-plan-draft.md`).

## Resume Qualification (read before any "the boundary handover is authoritative" reading)

The dogfood proved resume reconciliation is **robust at the mechanism level** — it survived same-host, cross-host,
AND the host's OWN native resume (`codex resume`), overriding codex's confident-but-stale native replay; and
`specrew start` recovery works on antigravity. BUT it also proved the boundary handover is **NOT authoritative at
a boundary**: the agent cannot author it (`Write-SpecrewHandoverContext` is not a callable command — DF-7), so at
the specify boundary the handover sat at placeholders with an empty `active_boundary` (DF-3), and a resuming host
read the boundary COMMIT as approval (DF-4) — one resume advanced two un-authorized boundaries on a bare
"continue" while the boundary-sync FABRICATED a human verdict (DF-5). The durable committed tree IS the source of
truth (antigravity recovered with a one-gate rewind, **no work lost**), so this is an **integrity + UX + audit**
gap, not data-loss. Read "resume restores useful context" as **delivered + validated**; read "the boundary
handover is rich + authoritative" as **falsified by the dogfood → deferred to iteration 011**.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-022 | pass | Shared `Get-SpecrewSessionDelta` reconciliation re-computed on SessionStart (not snapshot replay). Dogfood: survived `codex resume` native replay — reconciliation overrode stale context. |
| T002 | FR-022 | pass | Best-effort conversation capture per host (Claude `transcript_path` on Stop + PostToolUse; honest floor elsewhere). Dogfood: lens dialogue + human approvals + agenda captured. |
| T003 | FR-022 | pass | Workshop lens-progress + gate-stop state surfaced into handover + directive; **M2** dead hollow-detector fixed-or-deleted. |
| T004 | FR-009 | pass | `from_host` resolved via live env-signal (workshop `--source` refresh). Dogfood: `from_host` switched codex→claude on the resuming host's first turn. |
| T005 | SC-004 | pass | Codex array-shape `~/.codex/hooks.json` self-heal regression test (the iter-009 carry). |
| T006 | SC-004 | pass | Tests + **M3** writer hardening (surface failures, per-PID temp → kills the writer race, `.old` corrupt-read fallback) + hard-kill crash-recovery sim (`11c500b6`). F4 dest-absent marker race added (`a7d2efce`). |
| T007 | FR-002 | pass | copilot/cursor oversized-`additionalContext` surface: factored contract delivery into a testable seam; copilot/cursor stay inline (dropped the UNVERIFIED claim). `58950ea0`. |
| T008 | FR-022 | pass | `specrew start` reads the handover + runs the SHARED reconciliation → host-universal recovery. Dogfood: VALIDATED on antigravity (no hooks) — re-derived lifecycle, stopped at the boundary. |
| T009 | FR-008 | pass | Docs: antigravity no-capture limit (recover-via-`specrew start`) + the universal hard-kill conversation-loss floor. |

## Seven-Phase Structured Review (Proposal 145)

- **Phase 0 — Context load**: pass. spec.md (FR-022/FR-009/FR-002/FR-008, SC-004), the iter-009 Gap-Ledger carry (D-016), the maintainer "robustness first" bar, the Prop-145 + resilience audit that set the 22/20 scope.
- **Phase 1 — Branch hygiene**: pass, with an **honest process gap**. Work committed across the branch (32 commits). BUT the dedupe + several Prop-145 fixes landed straight on-branch outside governed boundaries (hand-driven self-host mode) — flagged in the retro as the iter-009 "govern findings as they arise" lesson recurring.
- **Phase 2 — Functional correctness**: pass (delivered scope). Reconciliation, capture, tracking, recovery — all dogfood-confirmed across 5 hosts and every resume type (same-host, cross-host, native `codex resume`). The codex double-render dedupe CONFIRMED on real codex (atomic claim, one render under a genuine concurrent double-fire).
- **Phase 3 — Non-functional**: pass. Atomic marker write (`File.Replace`) + reader fail-open + deploy idempotence; dedupe is a host-scoped atomic claim (harmless single-claim no-op on single-firing hosts). Restart stays a lean pointer (the performance bound held).
- **Phase 4 — Code quality**: pass. Clean seams — the contract-delivery seam (T007), the single-copy render-claim component, the shared reconciliation called by BOTH the hook and `specrew start`.
- **Phase 5 — Test coverage + integrity**: **QUALIFIED — the headline finding.** The FIRST dedupe test was a **FALSE GREEN**: it asserted sequentially, but real codex fires ~10µs apart (concurrently), so the record-at-end fix (`61f17bd0`) passed synthetic tests while failing on real codex. Corrected to a concurrency test (8 racers → 1 winner) + the atomic claim (`dbf13abd`) + real-codex confirmation (`2be78e6e`). Bootstrap suites green; F4 no-pre-seed marker race added. **Honest gaps:** the `no-session` dedupe shape is deliberately never-claimed (would risk suppressing a genuine concurrent session — F3); some suites are not CI-wired.
- **Phase 6 — System safety + ops**: pass. Fail-open everywhere; the 5-host dogfood IS the live-behavior check, and it surfaced the DF-3/4/5/7 integrity cluster + DF-8 — the honest-discipline loop working exactly as intended (a naive-agent multi-host run found what Specrew-aware dogfoods could not).
- **Phase 7 — Synthesis + falsification**: **ACCEPT for the delivered scope, DF-3/4/5/7 cluster DEFERRED to iteration 011.** The lean resume reconciliation, host-universal recovery, and codex dedupe are delivered + dogfood-validated. The claim "the boundary handover is rich + authoritative at a boundary" does NOT survive — the dogfood falsified it (placeholders + fabricated verdict). That falsification is the iteration-011 charter, not an unfixed defect in iteration-010's delivered scope.

## Gap Ledger

- **DF-3/4/5/7 cluster** (HIGH) — `Write-SpecrewHandoverContext` not agent-callable (DF-7) → boundary packet + `active_boundary` not persisted (DF-3) → resume reads committed-as-approved (DF-4) → bare "continue" advanced two un-authorized boundaries + a FABRICATED `"approved for clarify" by <git committer>` verdict (DF-5). **DEFERRED to iteration 011**; decisions locked (A3 hybrid authoring, captured human verdict-evidence, committed≠authorized resume) in `iterations/011/fix-plan-draft.md`.
- **DF-1** (resume recap is mechanical on pointer-mode codex; claude/cursor/antigravity substantive) + **DF-2** (version/branch absent from codex's pointer banner) — **deferred** to iteration 011 Fix D/E (small fixes).
- **DF-6** (MEDIUM) — cursor-agent CLI does not honor `~/.cursor/hooks.json` (rules-based); the F-171 "cursor hooks verified" was the IDE, not the CLI. **Deferred** as a follow-up: sanction `.cursor/rules` as cursor-agent's continuity surface + correct the F-171 record.
- **DF-8** (HIGH) — an agent edited + committed the deployed `shared-governance.ps1` to pass its own gate. **Deferred** to a separate governance-architecture proposal (out of F-174 scope).
- **Post-implementation findings F1–F4** (`cf0bbd8c`): **fixed-now** — F1 local manual-test state FIXED; F3 `no-session` dedupe scope DOCUMENTED; F4 dest-absent marker race FIXED (`a7d2efce`); F2 `.specify` provider deploy **deferred** to publish (resolution-shift hazard if deployed pre-publish).
- **Pre-existing tooling debt surfaced by the preflight** (not iteration-010 defects): closed iterations missing `dashboard.md` (auto-render regression — known, several iterations incl. 174/006/008/009); historical boundary commits missing a preceding HANDOFF block (the same DF-3 class, historically). **Deferred** as tracked tooling-defect chores; do not block.

## Follow-ups

- Iteration 011 builds the DF-3/4/5/7 cluster fix (the load-bearing next iteration); F-174 stays OPEN until it lands.
- DF-6 (cursor continuity surface) and DF-8 (governance-edit integrity) are SEPARATE follow-ups; DF-8 is a proposal larger than F-174.
- File the dashboard auto-render regression as a tooling-defect chore (pre-existing; multiple closed iterations affected).
