---
proposal: 202
title: MCP-Hosted Co-Reviewer — Execution & Communication Layer (Not a Gate Replacement)
status: candidate
phase: phase-3
estimated-sp: 18 (2 iterations)
discussion: 2026-06-26 cross-host reviewer-async survey. The continuous co-reviewer (Feature 197) runs detached and minutes-long; the hard cross-host problem is "how does any host trigger it, wait for a long-running result, and sample progress." Hook/stdin plumbing keeps biting (codex 0.141 hash-keyed hook-trust silently dropping untrusted hooks; claude `-p` 10 MB stdin cap; codex SessionStart oversized-payload drop). MCP is the most host-neutral surface available for trigger + status + result. KEY GROUNDING: the iter-008 work already extracted a host-neutral service (`co-review-service.ps1`) whose header NAMES the four MCP tools — the decoupling is built; this is the thin server + the durability gaps.
---

# MCP-Hosted Co-Reviewer — Execution & Communication Layer (Not a Gate Replacement)

## Why

The continuous co-reviewer (Feature 197) is **asynchronous and long-running** — it materializes an ephemeral worktree and runs an agentic reviewer (`claude -p` / `codex exec`) that can take minutes. The genuinely hard cross-host problem is the **trigger + wait + progress** loop: every host needs a way to (1) start a review of the committed state, (2) wait for a result even when it takes minutes, and (3) sample progress meanwhile — *without freezing the agent*.

Today that loop rides **host-specific hook + stdin plumbing**, and that plumbing has been the single largest source of fragility:

- **codex 0.141+ hash-keyed hook-trust** silently filters un-trusted hooks out of execution (source-confirmed; the trust hash is over the hook command, so it churns on re-deploy) — a silent-governance-void class.
- **claude `-p` 10 MB piped-stdin cap** rejected an oversized review prompt (exit 1, empty stdout) — the original "unparseable verdict."
- **codex SessionStart** drops oversized `additionalContext`.

Every one of those is hook/stdin *transport* breaking, not review *logic* breaking. **MCP (Model Context Protocol) is the most host-neutral transport available** for exactly this shape — a tool the agent calls, a structured result it gets back — and it is broadly supported across Specrew's roster (Claude, Codex `[mcp_servers]` + `codex mcp`, Cursor, Copilot). Hosting the reviewer behind an MCP server replaces the fragile per-host transport with one clean tool interface, and gives *every* host the "fire an async reviewer you can sample" behavior that only Claude has natively today.

**The decoupling is already built.** The iter-008 worktree-reviewer redesign deliberately extracted a **host-neutral service** — `scripts/internal/continuous-co-review/co-review-service.ps1` — whose header comment names the target consumers explicitly: *"consumed by TWO peers: the Claude Stop-hook navigator (today) AND a future MCP server (any MCP host, tomorrow) … The MCP server is a THIN wrapper."* This proposal builds that wrapper and the small set of durability gaps it needs.

## What

Stand up a **Specrew Reviewer MCP server**: a host-neutral service that **manages and hosts the co-reviewer's execution and lifecycle**, exposed to any MCP-capable host as a small, poll-model tool set. It owns *triggering, running, waiting, status, and result delivery* — the **communication and execution** layer. It does **not** own enforcement.

The tools map 1:1 onto the four functions the iter-008 service already exposes:

| MCP tool | Backing function (`co-review-service.ps1`) | Behavior |
|---|---|---|
| `start_review` | `Start-ContinuousCoReviewServiceRun` (`:41`, `-Detached`) | Non-blocking. Fires a review of the committed state; returns `run_id` + `status='running'` immediately. |
| `get_review_status` | `Get-ContinuousCoReviewServiceStatus` (`:88`) | Poll. Returns one run's lifecycle status (`running`/`reviewed`/`failed`/…) or all pending. |
| `get_review_findings` | `Get-ContinuousCoReviewServiceFindings` (`:108`) | Returns the durable `FindingsResult` for a `run_id`. |
| `ask_reviewer` | `Invoke-ContinuousCoReviewServiceAsk` (`:142`) | Follow-up question against a run's findings (fresh read-only worktree). |

**Poll model, not a single blocking call.** "Wait even if it takes long" is satisfied by `start_review` → repeated cheap `get_review_status` → `get_review_findings` when `done` — **not** by one long-held tool call. MCP/host clients impose per-call timeouts (codex configures `startup_timeout_sec`); a 10-minute blocking call would time out *and* freeze the agent. Polling keeps each call fast, lets the agent work between polls, and surfaces progress. (MCP progress-notifications exist but host-surfacing is inconsistent — treat as a bonus, never the floor.)

### This is explicitly NOT a gate replacement

MCP tools run **only when the agent chooses to call them**. An always-on enforcement gate ("you cannot advance without a review") therefore **cannot** be an MCP tool — the agent could simply not call it. The deterministic gate floor **stays a Stop-hook / software gate** (the layered design already ruled for Feature 197/185). This proposal is strictly the **communication + hosting + execution** layer:

- **Gate floor (unchanged):** deterministic hook/software gate = the always-on trigger + the reliable reap backstop at the next Stop.
- **MCP layer (new):** on-demand trigger ("review now" → `start_review`), interactive status sampling, host-neutral result delivery, and the durable home for the reviewer's execution.

The two share **one review record** (the same `run_id` + `.specrew/review/inline/<run-id>/`), so a review fired via the hook is queryable via MCP and vice-versa.

### Current implementation — what's already MCP-ready (the grounding)

A focused survey of the iter-008 reviewer (verdict: **substantially ready at the service/contract level; the server + durability gaps remain**):

**READY:**

- **Host-neutral service API** — the four functions above, each returning structured data with no host-specific surfacing (`co-review-service.ps1:4-12` documents the MCP-wrapper intent verbatim).
- **Self-contained contracts** — `contracts/review-request.schema.json` (v2: `change_set`, `design_context`, `visibility_policy`, `do_policy`, `provider_request`) and `contracts/findings-result.schema.json` (v1) are complete, self-contained JSON — directly usable as the MCP tools' input/output schemas.
- **Self-contained detached execution** — `Start-...ServiceRun -Detached` spawns `worktree-review-detached-entry.ps1`, which materializes a stripped ephemeral worktree, spawns the host CLI via the reviewer adapter, writes the result, and disposes the worktree. The reviewer brings its own host process — it does not depend on the *calling* host's runtime.
- **A durable result resource** — `.specrew/review/inline/<run-id>/findings-result.json` persists after reap; this is the MCP "resource."

**GAPS to build (the proposal's real work):**

1. **The MCP server process + transport bridge.** A non-PowerShell MCP host can't call PS functions directly. Build a thin stdio MCP server + a CLI bridge (`specrew-reviewer-mcp-cli.ps1`: JSON request in → service call → JSON result out). Lightest path preferred (reuse pwsh; the server is a stdio shim).
2. **A queryable run registry/index.** Today the reaper *deletes* pending entries; only durable `inline/<run-id>/` survives. Add `.specrew/review/index/` (run metadata + request/response) so `get_review_status`/history works after reap, not just for the last promoted run.
3. **Archive-not-delete cleanup + failure audit.** Reap should archive (not `Remove-Item`) and persist `InfrastructureFailure` reasons so a failed/old run is still queryable.
4. **Per-host MCP-server config deployment** at `specrew init` (codex `[mcp_servers]` TOML, Claude `.mcp.json`, Cursor) — the same per-host config pattern Specrew already uses for hooks.
5. *(Iteration 2, optional)* **Cross-session resume** — let a newly connected host query/reap a review fired by a prior session.

## Functional requirements

- **FR-001** — A stdio MCP server exposing `start_review` / `get_review_status` / `get_review_findings` / `ask_reviewer`, each a thin wrapper over the existing `co-review-service.ps1` function; tool I/O schemas derive from `review-request.schema.json` + `findings-result.schema.json`.
- **FR-002** — Poll-model semantics: `start_review` is non-blocking and returns a `run_id`; no tool call blocks longer than a short bounded budget; status is sampled, never long-held.
- **FR-003** — A CLI bridge (`specrew-reviewer-mcp-cli.ps1`) accepting a JSON request and emitting a JSON result, so the server is language-agnostic and the service stays the single source of truth.
- **FR-004** — A persistent, queryable run index (`.specrew/review/index/`) surviving reap, supporting "status by run_id" and "recent runs."
- **FR-005** — Reap becomes archive-not-delete; `InfrastructureFailure` reasons persist and are queryable via `get_review_status`.
- **FR-006** — Per-host MCP-server registration deployed by `specrew init` (codex/claude/cursor/copilot config shapes), behind the host package abstraction.
- **FR-007 (boundary)** — The MCP layer is **non-enforcing**: it shares the one review record with the hook gate but never becomes the advancement gate. The deterministic Stop-hook/software gate remains the sole enforcement floor.
- **FR-008 (parity)** — A review fired via the hook navigator and one fired via `start_review` produce byte-identical record shapes (same `run_id` space, same `inline/<run-id>/`), so the two consumers are interchangeable peers.

## Out of scope

- **Replacing or weakening the enforcement gate.** The hook/software gate floor is untouched. (FR-007.)
- **Removing the Stop-hook navigator.** It remains the always-on trigger + reap backstop; the MCP server is an additional, on-demand peer.
- **A long-lived multi-tenant daemon / HTTP server.** Iteration 1 is a per-session stdio server. Cross-session resume is iteration 2; a hosted HTTP service is explicitly not in this proposal.
- **Rewriting the reviewer in another language.** The reviewer stays PowerShell; the server shells out via the CLI bridge.
- **MCP "sampling"/"elicitation" dependence.** The reviewer spawns its own host CLI; it does not borrow the calling host's model.

## Effort

- **Iteration 1 (~10 SP)** — the MVP: stdio MCP server + CLI bridge (FR-001/002/003), per-host registration for one host first (FR-006), FR-007/008 parity. Outcome: a real MCP host triggers, samples, and retrieves a real review of real code.
- **Iteration 2 (~8 SP)** — durability: run index + archive-not-delete + failure audit (FR-004/005), remaining host registrations, optional cross-session resume.
- **Total**: ~18 SP.

## Phase placement

Phase-3 (the review/quality arc), as a **fast-follow on Feature 197** — sequenced *after* F-197 iter-008 (the worktree-agentic reviewer) lands and a *correct verdict through the real trigger path* is proven. Inherits F-197's placement; do not start before iter-008's milestone is genuinely met (a non-hollow review), since this proposal hosts that reviewer.

## Open questions

1. **Server implementation language** — a minimal PowerShell stdio MCP server, or a tiny Node/Python stdio shim that calls the CLI bridge? (Lean: whichever is lightest to deploy per-host; the CLI bridge makes the server nearly trivial either way.)
2. **Run-index schema** — reuse the pending-registry shape, or a richer record (request + response + timings + reviewer identity)? How much history to retain before pruning?
3. **Cross-session resume (iter 2)** — is per-session sufficient for the dogfood, or is "a new host queries a prior session's review" a real requirement?
4. **Trigger ownership** — does the hook navigator stay the always-on trigger with MCP as on-demand only, or should the agent be *instructed* to `start_review` at checkpoints (weaker, since instruction-following drifts)? Recommendation: keep the hook as the reliable trigger; MCP is on-demand + sampling.
5. **Per-host MCP maturity** — verify Antigravity/Devin MCP support specifically before claiming full roster coverage; design to the plain-tools common denominator (no reliance on resource-subscriptions / progress-notifications).

## Risks

- **MCP is agent-initiated → it must never become the enforcement gate.** The single largest risk is that the MCP server's convenience lulls the design into dropping the hook gate. Mitigation: FR-007 makes non-enforcement a contract; the deterministic floor stays a hook. (This is *why* the proposal title says "not a gate replacement.")
- **Transport churn moves, doesn't vanish** — per-host MCP-server config has its own quirks (codex TOML vs Claude `.mcp.json`). Mitigation: it is *more* standardized than hooks, and Specrew already deploys per-host configs; fold into the host package abstraction (FR-006).
- **Destructive reap is load-bearing today** — changing reap to archive-not-delete must not break the existing navigator dedup/reap. Mitigation: FR-008 parity tests; archive is additive (the durable `inline/` path is unchanged).
- **Scope creep toward a daemon** — "host the reviewer" can balloon into a hosted service. Mitigation: iteration 1 is a per-session stdio server only; HTTP/multi-tenant is explicitly out of scope.
- **Premature build** — hosting a reviewer that doesn't yet return *correct* verdicts (the iter-008 curation false-positive) would polish the wrong thing. Mitigation: phase placement gates this proposal on F-197 iter-008's real milestone.

## Cross-references

- **197 (continuous co-review)** — the reviewer this hosts; `co-review-service.ps1` (the host-neutral seam) and the iter-008 worktree-agentic redesign are the direct substrate.
- **105 (host-native hook deployment)** + **024 (multi-host runtime abstraction)** + `hosts/_contract.md` — the per-host config-deployment pattern reused for MCP-server registration (FR-006).
- **139 (multi-agent / subagent orchestration)** — the broader detached-execution arc; the MCP server is the host-neutral *communication* face of that orchestration.
- **185 / 199 (host-neutral gate enforcement; thin coordinator — hooks own the boundary mechanics)** — the enforcement floor this proposal deliberately does **not** touch (FR-007).
- Source artifacts: the iter-008 MCP-readiness survey (2026-06-26); the codex 0.141 hook-trust + claude 10 MB stdin findings (private memory) motivating the transport shift.

## Status history

- 2026-06-26: created as `candidate`. Grounded in the iter-008 MCP-readiness survey — the host-neutral service (`co-review-service.ps1`) and contracts are built and explicitly MCP-targeted; this proposal is the thin server + durability gaps, scoped as a non-enforcing communication/hosting layer.
