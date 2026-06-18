# Product-Domain Record

**Depth**: standard - Continuation of F-183 with known Antigravity refocus gaps, downstream host-parity impact, and load-bearing real-host behavior uncertainty.
**Context scope**: feature_standalone

## Areas

- **users_stakeholders**: Primary users are downstream Specrew users running Antigravity via `agy`, plus Specrew maintainers validating host parity. Harmed parties are users who switch or resume sessions and lose refocus behavior, receive false concurrency warnings, or see full parity claimed before real-host evidence proves it.
- **pain_job**: Antigravity has bounded Specrew support but not full refocus parity. Users can start and resume, but the same-worktree concurrency advisory can false-fire on Antigravity's own marker and the Antigravity path does not yet persist the per-session refocus anchor/state required for reliable boundary-cross refocus.
- **current_workaround**: Manual discipline: use `specrew start`, rely on bootstrap and handover, and avoid claiming full Antigravity parity.
- **existing_system**: F-184 continues F-183 inside the existing Specrew host/refocus architecture. It should reuse the dispatcher, host manifest/bindings, `SessionStateAccessor`, `ClassificationEngine`, `refocus-state`, `Test-B3ShouldInject`, dedupe/breaker, bootstrap, and handover paths.
- **constraints**: Use real Antigravity CLI behavior via `agy` for final proof; do not claim full parity until real-host evidence exists; reuse existing refocus machinery; stop for a human split/defer decision if B3-on-`PreInvocation` exceeds a bounded extension; preserve F-183 bootstrap, Stop handover, welcome-back resume, and real conversation-id session keys; release waits for this completion feature.
- **outcomes**: No self-marker concurrency false-positive during normal Antigravity turns; per-session refocus state/anchor persists across turns; boundary-cross refocus fires through `PreInvocation` only on real boundary crossings; Stop handover and cross-session welcome-back resume still work; host matrix/docs claim only what evidence proves.
- **mvp**: Fix Edge 1, fix Edge 2, map B3 boundary-cross refocus onto Antigravity `PreInvocation`, preserve F-183 behavior, run manual `agy` validation including exit and re-entry, then proceed through beta and stable release gates if evidence passes.
- **out_of_scope**: No new general host framework beyond what this needs; no stable release without beta and release-gate authorization; no full Antigravity parity claim without real-host proof; no unrelated host parity fixes for Copilot, Codex, Cursor, or Claude.
- **alternatives**: Leaving Antigravity as bounded support and relying on manual discipline are rejected because the goal is completeness. A parallel Antigravity-specific refocus system is rejected unless discovery proves reuse cannot work. The chosen path is to reuse existing refocus machinery and extend the Antigravity binding where its event model requires it.
- **adoption_rollout**: Develop on F-184 as the completion of F-183. Before claiming full support, run manual real-host `agy` validation including exit and re-entry. If evidence passes and repo validation is clean, publish beta first, then stable only after beta validation passes.

## Evidence-Tagged Statements

- (known) [existing_system] F-184 is a completion of F-183, not an unrelated follow-up.
- (known) [mvp] The product goal is completeness now, not another knowingly partial Antigravity slice.
- (known) [pain_job] F-183 left the same-worktree concurrency advisory false-positive and missing per-session refocus state/anchor as mandatory carry-forward edges.
- (known) [constraints] Antigravity is launched with `agy`.
- (known) [existing_system] Bootstrap injection, Stop handover, resume, and real conversation-id keys were manually observed in `C:\Temp\f183-test`.
- (research-needed [load_bearing: true]) [outcomes] Antigravity `PreInvocation` must be confirmed fresh enough before a turn to support B3 correctly.
- (research-needed [load_bearing: true]) [alternatives] B3 should be mapped onto `PreInvocation` by reusing existing refocus machinery without a larger host-model rewrite, unless discovery proves that impossible.
- (assumed) [existing_system] The existing refocus dedupe, breaker, and state path can likely be extended rather than rebuilt.

## Follow-Up Research

- Run the discovery spike before planning: read dispatcher B2/B3 routing, `SessionStateAccessor`, `ClassificationEngine`, and run one `agy` experiment to confirm whether the boundary cursor is fresh before a turn.
- At validation, run manual real-host `agy` proof including exit and re-entry before claiming full Antigravity refocus.

## Confirmation

**Confirmation**: human-confirmed / lens-question
