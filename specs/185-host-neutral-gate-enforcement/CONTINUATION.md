# Feature 185 — Host-Neutral Lifecycle Gate Enforcement — Continuation Record

This is the durable handoff for continuing feature 185. The design workshop is complete and
`spec.md` is the authoritative contract. Continue in this worktree
(`C:/Dev/185-host-neutral-gate-enforcement`, branch `185-host-neutral-gate-enforcement`,
based on origin/main `b71d3b4c`).

## PROGRESS (2026-06-19)

- specify + plan committed (`1f24aa29`, `1b1405f4`).
- **Iteration 1 (cleaning) DONE + tested + committed (`84f99984`)**: FR-002/003/006. The all-host digests (`general.md` rule-9, `specify.md` step-6/traps) are harness-free + instruct every host to emit the `SPECREW-VERDICT-BOUNDARY` marker. Because the capture is transcript-gated (not Claude-gated), non-Claude transcript hosts now capture verdicts with NO `HandoverStore` change. No new skill file. Test: `tests/integration/host-neutral-gate-cleaning.tests.ps1`.
- **Iteration 2 PENDING A MAINTAINER DECISION**: the gate provider's Claude mechanical block requires re-registering `PreToolUse`, which F-184 deliberately turned off (~920ms). Surface + measure before activating (advisor's flag) — options: (a) activate with a narrow matcher + measured cost; (b) leave out, rely on cleaning + cooperative-halt (FR-007 stays research-flagged). The non-reversal Iter-2 parts (per-host capability declaration + degraded-mode + parity/gate-detection tests) can proceed regardless.

## Lifecycle position (honest)

- **Worktree:** created, synced with origin/main.
- **Design workshop:** COMPLETE — all 10 lenses, all maintainer-confirmed (captured in `spec.md` → Design Workshop Summary). See the lens decisions there.
- **spec.md:** WRITTEN + committed (`187c76a4`) — 8 FRs, 4 TGs, 5 SCs, 4 user stories, the enforce-or-halt guarantee.
- **PENDING for a clean specify-boundary close:** the structured artifacts the preflight wants — `lens-applicability.json`, `workshop/product-domain.yml`, the 10 `workshop/<lens>.md` prose records, `implementation-rules.yml` — then the specify preflight green. (Replicate the schema from `specs/184-full-antigravity-refocus/` — `lens-applicability.json` carries each lens's `agenda` + `decision` + `confirmation: human-confirmed`/`confirmation_scope: lens-question`; `product-domain.yml` and `implementation-rules.yml` are separate; the `.md` files are prose.)
- **NOT started:** clarify, plan, tasks, before-implement, implement, review.

## Locked scope (do NOT change without a maintainer verdict)

Enforce-or-halt north star: **no host silently self-advances past a human-judgment boundary; each host enforces with its strongest available lever, or it halts.** P0 spine = (1) harness-free instruction-cleaning, (2) host-neutral gate-stop fallback + marker capture, (3) parity + gate-detection tests, (4) degraded-mode halt, (5) cross-host dogfood. **Out / research-flagged:** the hard *uniform* mechanical write-block everywhere (host-variable); the full Proposal-188 matrix; any broad host-model rewrite. **Split-guard:** STOP for a maintainer split/defer verdict if real enforcement needs a broad host-model rewrite.

Maintainer pre-authorized the gates through implementation, **conditional on no scope change**, multiple iterations allowed, then a Proposal-145 review, then report.

## Implementation plan (proposed iteration breakdown)

- **Iteration 1 — Cleaning + capture (most concrete, host-uniform, low-risk):**
  - Harness-free `general.md` rule-9 + `specify.md` step/traps (FR-002) — the leak fix.
  - Host-neutral gate-stop fallback renderer that renders the packet + emits the `SPECREW-VERDICT-BOUNDARY` marker (FR-003).
  - Non-Claude verdict-marker capture (FR-006).
  - SC-002 leak test + the marker-capture test (SC-005 automated half).
- **Iteration 2 — Capability + gate provider (host-variable, the split-guard lives here):**
  - Per-host capability declaration in `host.psd1` for all hosts (FR-004).
  - A `kind == 'gate'` provider on the dormant dispatcher seat (Claude `PreToolUse` first) wired to 065 authorization → `deny`/`ask` an unauthorized human-judgment write (FR-007); enforce-or-halt routing (FR-005).
  - Parity test (SC-003) + gate-detection test (SC-004).
- **Iteration 3 — Dogfood + degraded mode:**
  - Cross-host greenfield dogfood reproducing #2884 (SC-001, SC-005 real-host half); honest degraded-mode declarations for hookless hosts.
- **Then:** Proposal-145 structured multi-phase review of the implementation.

## Code touchpoints (verified by the orientation map)

- **Cleaning (edit SOURCE; `.specify/...` mirror auto-syncs):**
  - `extensions/specrew-speckit/refocus/general.md` — rule 9 (~line 23): the all-host leak.
  - `extensions/specrew-speckit/refocus/specify.md` — step 6 + Known-traps (~lines 15/17).
- **Fallback renderer + deploy:**
  - `extensions/specrew-speckit/squad-templates/skills/gate-stop.md` — Claude source (`host-scope: claude`, `disallowed-tools: AskUserQuestion`); add a host-neutral variant.
  - `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` — the `host-scope` deploy gate (~467–522); deploy the fallback to non-Claude hosts.
- **Verdict capture:** `scripts/internal/bootstrap/HandoverStore.ps1` — `Get-SpecrewCapturedBoundaryVerdict`, the `SPECREW-VERDICT-BOUNDARY` marker (extend to non-Claude).
- **Capability declaration:** `hosts/*/host.psd1` (claude/codex/antigravity/copilot/cursor) — add a capability field (`StructuredQuestionPrimitive` already varies per host: Claude `AskUserQuestion`, Codex `request_user_input`, others none).
- **Gate provider + enforcement:**
  - `scripts/internal/specrew-hook-dispatcher.ps1` — the DORMANT `kind == 'gate'` PreToolUse seat (~789–800; fails open today; no host registers `PreToolUse`).
  - `extensions/specrew-speckit/refocus-scopes.json` — provider catalog (only `inject` today); register a `gate` provider.
  - `extensions/specrew-speckit/scripts/shared-governance.ps1` — `Test-SpecrewBoundaryAuthorization` / `Add-SpecrewBoundaryAuthorization` (~1618–1715), the authorization core the gate provider calls.
  - `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-plan.md` (+ `sync-tasks`, `before-implement`) — where the gate fires today (post-write; the cooperative layer this supplements).

## Causal chain of #2884 (the bug this fixes)

Non-Claude hosts get ONLY the textual rule-9 (which names the Claude-only `specrew-gate-stop` skill they can't act on); the verdict check (`Test-SpecrewBoundaryAuthorization`) fires only inside the sync-wrappers AFTER `plan.md` is written; the `PreToolUse` gate seat is dormant + fails open + unregistered. On Antigravity there's no gate-stop skill → no `SPECREW-VERDICT-BOUNDARY` marker → `verdict_history` stays empty → the cooperative prose is the only "enforcement," and it's the leaking Claude-referencing rule the host can't follow.

## Next steps

1. Complete the specify artifacts (above) + run the specify preflight green; commit `boundary(specify)`; record the `specify → clarify` verdict (maintainer pre-auth).
2. Clarify (likely minimal — workshop covered it) → plan (design-analysis; **split-guard check** at the gate-provider design) → tasks → before-implement.
3. Implement per the iteration plan; commit `boundary(implement)` per iteration.
4. Proposal-145 review; report.
