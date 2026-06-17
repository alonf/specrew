# T001 Discovery: Host-Landscape Verification (Iteration 002)

**Schema**: v1
**Task**: T001
**Feature**: file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/spec.md
**Iteration plan**: file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/iterations/002/plan.md
**Date**: 2026-06-17
**Directive**: before-implement verdict (Alon Fliess, 2026-06-17) — verify four
host-landscape checks against the ACTUALLY-INSTALLED host CLIs (not docs or the
manifest alone), with split-guard escalation: STOP for a human split/defer
decision if any host's current convention diverges from the iter-002 premise
(the manifest-driven `InstructionsFile` projection won't hold, or a host changed
where/how instructions load).

## Method

Evidence basis: installed-CLI behavior + on-disk config locations on this machine,
the host manifests (`hosts/<host>/host.psd1`), and official-docs corroboration
(June 2026) via two research agents. Installed + on PATH: `codex` 0.139.0,
`agy` 1.0.9, `claude` (Claude Code), `gemini`, `cursor`, `copilot`.

## Split-Guard Determination

**Verdict: NO split-guard trigger.** The manifest-driven `InstructionsFile`
projection HOLDS for every supported host. The iteration-002 premise is confirmed.
Proceed to T002. One non-blocking nuance (Antigravity also reads `GEMINI.md`) is
recorded as a deferred follow-up, explicitly OUT of iter-002 scope.

## Check Evidence

| # | Check | Verdict | Evidence (installed CLI + on-disk + docs) | Design implication for iter-002 |
| --- | --- | --- | --- | --- |
| 1 | Codex `AGENTS.md` collision | HOLDS | `codex 0.139.0` has NO `init` CLI subcommand; `/init` is in-session and **create-only** (skips when `AGENTS.md` exists — `openai/codex` #21932, OPEN). Loader concatenates whole files root→cwd (32 KiB cap), does not parse sections. | A clearly-delimited Specrew-owned section in an existing `AGENTS.md` is safe from `/init` today; byte-preserving section-merge keeps Codex content by construction. Use delimited markers + byte-for-byte preservation (FR-012). |
| 2 | Claude delivery path | HOLDS | Claude Code `InstructionsLoaded` hook = observability-only (no `additionalContext`); `Setup` fires only at `--init-only`/`--maintenance`, not per session; `SessionStart additionalContext` capped at 10K (the F-174 saved-to-file behavior). `CLAUDE.md` loads in full, no cap, every session. | Deliver the coordinator section via a static `CLAUDE.md` section (the design's premise). Decision recorded: static-only; DEFER hook-based injection. Adjacent (not adopted): `--append-system-prompt`, managed `claudeMd` key. |
| 3 | Antigravity hooks-config + `InstructionsFile` | HOLDS (+ flag) | `agy 1.0.9` config lives under `~/.gemini/` but `find ~/.gemini -iname "*hook*"` is EMPTY; project `.agents/hooks.json` present with the correct `specrew-refocus` PreInvocation+Stop. Docs confirm `.agents/hooks.json` is the current project path; `~/.gemini/config/hooks.json` is an ADDED user tier, not a replacement. `agy` reads `AGENTS.md` AND `GEMINI.md`, priority `AGENTS.md → GEMINI.md`. | Project `.agents/hooks.json` unchanged (hooks are F-183/iter-001 scope, not iter-002). Deploy the coordinator section to `AGENTS.md` (wins on priority). `GEMINI.md` awareness = deferred manifest-enrichment follow-up (see below). |
| 4 | Manifest `InstructionsFile` freshness | HOLDS | `host.psd1` declares: `AGENTS.md` (codex, antigravity, cursor), `CLAUDE.md` (claude), `.github/copilot-instructions.md` (copilot). All match current conventions. | The manifest field is the correct host-neutral key; three hosts share `AGENTS.md`, so the merge must behave uniformly for that file. Minor: Cursor's governance binary is `cursor-agent` (not the `cursor` editor on PATH) — not iter-002-critical. |

## Design Implications Carried Into T002–T005

- **Delimited managed section + byte-for-byte preservation (FR-012) is confirmed
  both safe and necessary**: it coexists with Codex `/init` content, user content,
  and (on Antigravity) a separate `GEMINI.md`. The merge rewrites ONLY between
  Specrew markers.
- **`AGENTS.md` is a shared 3-host convention** (codex/antigravity/cursor); the
  host-neutral merge core (FR-015) reads the file path from the manifest and must
  not branch on which host shares it.
- **Codex `/init` create-only** means no clobber today; `specrew update` /
  `start`-heal (FR-016) remain the refresh path regardless.

## Deferred Follow-Ups (OUT of iteration-002 scope — to the ledger, not the diff)

- **Antigravity `GEMINI.md` secondary instruction file**: `agy` reads it alongside
  `AGENTS.md`. Candidate Antigravity-manifest enrichment (a secondary/also-read
  instruction-file list). Not built in iter-002 — `AGENTS.md` priority makes the
  current single-`InstructionsFile` deployment correct; adding `GEMINI.md` handling
  would be scope creep against the 20/20 cap. **The `AGENTS.md -> GEMINI.md`
  priority is docs-corroborated only (the official hooks/instructions page is
  JS-rendered), so T006 MUST verify it BEHAVIORALLY in the real-host `agy` run:
  place a conflicting marker in `AGENTS.md` vs `GEMINI.md` and confirm which `agy`
  honors. `AGENTS.md` wins -> defer proven. `GEMINI.md` wins -> STOP and surface;
  the defer flips to in-scope (human split/defer decision).** (Before-implement
  verdict carry, 2026-06-17.)
- **`AGENTS.md` size budget (Codex 32 KiB concatenation cap)**: Codex loads
  `AGENTS.md` whole into a root->cwd concatenation capped at 32 KiB and does not
  parse sections, so a large Specrew section atop a large user `AGENTS.md` risks
  truncation. T002 holds the packaged coordinator fragment LEAN under an explicit
  size budget, asserted by a test. (Before-implement verdict carry, 2026-06-17.)
- **Codex `/init` "update existing"** (`openai/codex` #21932): if it ships, re-test
  managed-section survival under a re-run `/init`.
- **`~/.gemini/config/hooks.json` user-scoped hooks tier**: relevant to the
  Antigravity hooks deployment (F-183/iter-001), not iter-002 instruction delivery.

## Honest Uncertainty Flags

- Codex loader override/fallback-filename mechanism: current behavior confirmed,
  but whether it is a recent vs long-standing change is not datable from sources.
- Antigravity project-vs-user hook precedence is undocumented.
- The official `antigravity.google/docs/hooks` page is JS-rendered; corroborated
  via the antigravity-cli CHANGELOG, danicat.dev hooks reference, and the Google
  Cloud migration note, which agree.

## Sources

- Codex: developers.openai.com/codex/cli/slash-commands; developers.openai.com/codex/guides/agents-md; github.com/openai/codex/issues/21932; github.com/openai/codex/blob/main/docs/agents_md.md
- Claude Code: code.claude.com/docs/en/hooks.md; code.claude.com/docs/en/hooks-guide.md; code.claude.com/docs/en/memory.md
- Antigravity: antigravity.google/docs/hooks; github.com/google-antigravity/antigravity-cli CHANGELOG; danicat.dev/posts/20260610-mastering-hooks; Google Cloud "Migrating to Antigravity CLI"
