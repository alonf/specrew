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

## Implementation plan (UNIFIED — "reliably follow Specrew", re-scoped 2026-06-19, drift D-002)

Scope evolved from "host-neutral gate enforcement" to **make the host reliably follow Specrew** — 4 failure modes: (1) resume-asks-what-to-build, (2) gate-skip [#2884], (3) raw-Spec-Kit, (4) willing-host-blocked-by-wrong-instructions [#2884 4th face, dogfood test-f197]. All levers ride the init-deployed hooks/files (work at DIRECT launch — `specrew start` is rarely used). **DROPPED:** the Claude PreToolUse pre-block (D-001 — expensive + wrong host) and the CLI wrapper (D-002 — invasive PATH for marginal value). Do NOT build those.

**DONE + committed:**

- **Iter 1 — Cleaning + capture** (`84f99984`): FR-002/003/006 harness-free digests + marker-emit; capture is transcript-gated (no HandoverStore change). Test `host-neutral-gate-cleaning.tests.ps1`.
- **FR-013 part 1 — Guard precision** (`966c42cb`): coordinator instruction blesses the governed scripts, forbids only the raw `specify.exe workflow`, states the Specrew-coordinator/Spec-Kit-SDD division. Test `coordinator-guard-precision.tests.ps1`.

**REMAINING (meaty, critical-path — fresh context recommended; do ONE at a time, commit, dogfood between):**

- **FR-013 part 2 — Per-host command DEPLOY (the P0 centerpiece; a 0.38.0 regression):** normalize the host-native Spec Kit command surface — deploy the per-boundary speckit commands to each palette-host's command surface, **mirroring the SKILL normalization**. Add `CommandRoot` per host (mirroring `SkillRoot`); the host-neutral deploy normalizes commands per-host. Targets: Claude (`.claude/commands`), Antigravity (its surface — VERIFY) — Copilot already has them (`.github/prompts`); Cursor/Codex are `HasUserSlashCommandSurface=$false` → pwsh-form, no commands needed. ONE component decision: command source/format — (a) re-init Spec Kit per palette-host so it emits native format, or (b) Specrew reformats the canonical defs onto each CommandRoot. Architecture: extends the host-adapter skill-normalization; split-guard does NOT fire. Parity test + dogfood (test-f197 Claude proceeds).
- **FR-011 — #2 gate-skip detection** (extend the EXISTING verdict path in `HandoverStore.ps1` after ~L782, NOT a parallel detector): if an artifact advanced beyond `last_authorized_boundary` with NO verdict-stop marker rendered and no captured verdict → emit a loud halt-correction for next turn (model the `$hollow` journal emit ~L804-822). The marker-render check distinguishes the legitimate awaiting-verdict stop (NO false positives only with that check). HALT is real (state-protected). Test SC-008(#2). **Then COMMIT + STOP for the dogfood.**
- **FR-009 (#1 orientation) + FR-010 (#3 markdown-patch on the now-deployed commands) + FR-011 #1/#3 detection:** sized by the #2 dogfood. #1/#3 corrections are cooperative-only (the truncated channel F-174 documents) → NUDGE not halt; SC-006/007 dogfood decides them.
- **Then:** cross-host dogfood (SC-001/006/007/009 real-host) + the Proposal-145 review.

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

## Next steps (fresh-context implementation pass)

1. **FR-013 part 2 (command deploy)** — the P0 centerpiece. Verify Antigravity's command surface + decide the source/format mechanism; add `CommandRoot` per host; deploy commands per-host (mirror the skill deploy in `deploy-squad-runtime.ps1`); parity test; dogfood test-f197 on Claude.
2. **FR-011 #2 detection** — extend the `HandoverStore.ps1` verdict path; commit; STOP for the dogfood.
3. Let the #2 dogfood size **FR-009 / FR-010 / FR-011-#1/#3**.
4. Cross-host dogfood + Proposal-145 review + report.

The worktree carries everything (spec + plan + drift-log + Iter 1 + FR-013 guard precision, all committed). Start a fresh session here, "continue feature 185" → it picks up from this plan. **No workshop needed** — the design is complete (FR-013 extends the existing host-adapter skill-normalization; D-002 confirmed same-architecture).
