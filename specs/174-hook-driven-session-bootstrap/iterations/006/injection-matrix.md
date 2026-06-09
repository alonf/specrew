# Per-host injection matrix (F-174 iteration 006, T039)

The B2 SessionStart bootstrap is EMPIRICAL in TWO parts (FR-024). This matrix records the honest per-host
status at the close of iteration 006. It deliberately does NOT claim all-host parity on Claude-only evidence
(maintainer honesty guard).

## The two parts

1. **On-disk writes (host-AGNOSTIC, auto, evidence_locus: DEPLOYED).** The provider writes
   `last-start-prompt.md` + `boundary_enforcement` + the rolling handover regardless of host — these do not
   depend on the host. Proven DEPLOYED by T038 (`tests/integration/deployed-bootstrap-floor.tests.ps1`,
   tier-3, real installed-module scratch project).
2. **Injection-reaches-model (per-host, MANUAL observation).** Whether the host runtime actually delivers the
   provider's emitted `additionalContext` (cursor: `hookSpecificOutput.additionalContext`) INTO the model's
   context. NOT assertable on disk — a clean dogfood observation only (this is exactly why a confounded run
   cannot count).

## Matrix

| Host | Deployed on-disk writes (T038, auto) | Injection emission shape (dispatcher) | Injection-reaches-model (manual) | Net status |
| --- | --- | --- | --- | --- |
| **claude** | GREEN (deployed, host-agnostic) | `additionalContext` | **PROVEN** — direct observation this session: the SessionStart hook delivered the bootstrap directive INTO this Claude context | **PARITY — drives via the hook** |
| **codex** | GREEN (host-agnostic) | `additionalContext` | **UNVERIFIED** — the prior no-orientation run was CONFOUNDED; needs a clean re-test | plumbing-ready; `specrew start` fallback until confirmed |
| **copilot** | GREEN (host-agnostic) | `additionalContext` | **UNVERIFIED** — not yet observed clean | plumbing-ready; `specrew start` fallback until confirmed |
| **cursor** | GREEN (host-agnostic) | `hookSpecificOutput.additionalContext` | **UNVERIFIED** — not yet observed clean | plumbing-ready; `specrew start` fallback until confirmed |
| **antigravity** | n/a — NO SessionStart hook (deploy-refocus-hooks has no antigravity branch) | n/a | n/a | **`specrew start` fallback (no-hook host)** |

## Conclusions

- **Parity set (drives via the hook) = Claude only.** Claude has both halves: deployed plumbing (T038) AND
  injection-reaches-model (direct observation). iter-6 ships Claude-driving-in-practice.
- **`specrew start` fallback = Antigravity (no hook) + codex/copilot/cursor (hooked + plumbing-ready, but
  injection-reaches-model UNVERIFIED).** A host joins the parity set only when BOTH halves hold.
- **The injection emission SHAPE exists for all four hooked hosts** (the dispatcher's `Write-InjectionOutput`);
  T038 is provider-direct so it does not exercise the dispatcher's per-host shaping — that, plus the
  injection-reaches-model re-tests, is the explicit follow-on, NOT a silent drop.

## Tracked follow-on (NOT silently dropped)

The codex / copilot / cursor injection-reaches-model clean re-tests are scheduled as the standing slice
`f174-followup-multihost-injection-verification` (`.squad/decisions.md`). That slice is what actually delivers
the "all hosts, not just Claude" intent; until it lands, the docs (T042) and any claim must say Claude driving
is PROVEN while codex/copilot/cursor are plumbing-ready but injection-UNVERIFIED.
