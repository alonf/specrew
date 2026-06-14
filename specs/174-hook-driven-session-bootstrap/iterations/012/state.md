# Iteration State: 012

**Schema**: v1
**Current Phase**: specify
**Iteration Status**: planning
**Last Completed Task**: (none — iteration opened at the specify boundary 2026-06-14)
**Tasks Remaining**: specify verdict → clarify (light) → plan → tasks → implement (the doc edits) → review-signoff → retro → iteration-closeout. No code change; documentation only.
**In Progress**: specify boundary authored from the F-174 doc-coverage assessment; awaiting the maintainer's specify verdict.
**Baseline Ref**: iteration-011 HEAD (`b965abf1`)
**Updated**: 2026-06-14T21:43:53Z

## Charter

Iteration 012 reconciles the F-174 **user-facing documentation** to the SHIPPED hook-driven session-continuity
model. F-174's behavior (hook bootstrap, rolling handover, cross-host auto-resume, per-host delivery, verdict
integrity, the new commands) is built + iter-011-closed + real-host-confirmed on Claude, Codex, and Copilot for
hook bootstrap plus rolling handover read/write; Cursor remains pending live validation, and rich boundary packet
plus automatic verdict capture remain Claude-only today. A 6-doc coverage assessment (2026-06-14) found every
user-facing doc is **partial or absent** on the new model: each got one new-model callout bolted on, while the
document BODIES still teach the old stateless, `specrew start`-driven model — and some carry **false or
mis-scoped claims**. This is a documentation-only iteration; no runtime/code change.

## Specify (this boundary)

**Problem (from the assessment):** the docs and the shipped behavior diverged. README/getting-started bodies
route continuity through `specrew start` (contradicting their own "hook is primary" callouts); the handover
file schema + the new commands are undocumented; iter-011 behavior (per-host delivery, the 10K cap, verdict
integrity on resume) is missing; and three docs carry the **false/mis-scoped** claim "Confirmed governed on
Claude, Codex, and Copilot" without saying which surfaces were confirmed or preserving the Claude-only
rich-packet/verdict-capture limit.

**Scope:** reconcile the 6 user-facing surfaces — `README.md`, `docs/getting-started.md`, `docs/user-guide.md`,
`docs/troubleshooting.md`, `docs/data-contracts.md` + `docs/api-reference.md`, `CHANGELOG.md` (+ a methodology
pointer) — to the shipped model. **Documentation only — NO code/runtime change.**

**Documentation requirements (DR):**

- **DR-1 (MUST — maintainer):** *After `init`, start with no `specrew start`.* Make the docs teach: `specrew
  init` deploys the hooks; from then on you just LAUNCH your host and the SessionStart hook bootstraps you
  (orientation banner + governed contract + resume). `specrew start` is OPTIONAL (explicit driver / re-anchor).
  Caveat to keep: hook-capable hosts (claude/codex/copilot/cursor) get this; **antigravity is hookless → still
  uses `specrew start`.** Reconcile the README body + getting-started so the old "`specrew start` is the entry
  point" framing is gone (no doc contradicts its own callout).
- **DR-2 (MUST — maintainer):** *Explain handover BETWEEN hosts.* Document the switch-hosts-mid-feature flow:
  stop in one host → the host-agnostic rolling handover (`.specrew/handover/session-handover.md`) → launch a
  DIFFERENT host → it resumes from that handover. Real-host dogfood has confirmed this for Claude, Codex, and
  Copilot, including Codex→Claude and Codex→Copilot handover read/write on disk. Be ACCURATE about the limit:
  mechanical feature/anchor continuity is confirmed on those hosts and expected for hook-capable hosts, Cursor
  still needs live validation, and the **rich boundary packet + automatic verdict capture are Claude-only today**
  (marker is Claude-scoped, D-001 fast-follow); a non-Claude resume at a boundary may re-confirm.
- **DR-3 (honesty fix — ship regardless):** correct the **false** "Confirmed governed on Claude, Codex, and
  Copilot" (README, getting-started, CHANGELOG) → use evidence-scoped wording: **Claude, Codex, and Copilot are
  real-host-confirmed for hook bootstrap, governed orientation/resume, and rolling handover read/write**; **Cursor
  is pending live validation**; **rich boundary packet capture + automatic verdict capture remain Claude-only**
  until the host-neutral marker path is implemented and validated.
- **DR-4:** document the handover FILE contract in `data-contracts.md` — `schema: v1` frontmatter + fields +
  the 8 fixed `## ` sections (incl. the iter-11 captured boundary packet) + the placeholder convention +
  atomic-replace/`.old` crash backup + gitignored overwrite-in-place; add it to the Writer-contract list.
- **DR-5:** document the new commands in `api-reference.md` — `specrew handover author` (--from/--stdin/--feature/
  --boundary/--host) and `specrew hooks status|install|remove [--host]`.
- **DR-6:** `troubleshooting.md` — add the iter-011 failure modes: the 10K hook-output cap drop (`WARN
  PAYLOAD_OVERSIZE`), the `SPECREW_MODULE_PATH` dev/dogfood silent-failure, and replace the stale
  `deploy-refocus-hooks.ps1` repair pointers with the canonical `specrew hooks status|install|remove`.
- **DR-7:** explain verdict-integrity on resume (committed != authorized → "awaiting your verdict") in
  `user-guide.md` + `troubleshooting.md`, including the Claude-only marker degrade.
- **DR-8:** `user-guide.md` Session Continuity — bring current to iter-011: per-host delivery (pointer vs
  inline), `specrew handover author`, and fix the stale "seven sections" → eight + the overstated three-way
  rotation claim (mechanical vs rich-packet distinction).
- **DR-9:** `getting-started.md` — say `init` deploys hooks; add `.specrew/handover/` + `.specrew/runtime/` to
  the artifact tree; fix the resume note that routes through `specrew start`.
- **DR-10:** `CHANGELOG.md` — announce the handover round-trip / auto-resume + the two new commands; remove the
  contradicted pre-iter-11 claims.

**Acceptance criteria (SC):**

- SC-1: every one of the 6 surfaces accurately teaches the hook-driven model; no doc contradicts its own
  new-model callout (the README body + getting-started no longer present `specrew start` as the entry point).
- SC-2: DR-1 + DR-2 are explicitly present (no-`specrew-start` entry; accurate cross-host handover incl. the
  Claude-only-rich-packet/verdict-capture limit and current real-host evidence scope).
- SC-3: zero false host-confirmation claims remain (DR-3).
- SC-4: the handover file schema + `specrew handover author` + `specrew hooks` are documented (DR-4/5).
- SC-5: markdownlint clean; `wrapper-docs-parity` (or the doc token-parity test) green if doc tokens are touched.
- SC-6 (verification): a re-run of the doc-coverage assessment (or the maintainer's read) finds no HIGH gaps +
  no stale/false claims for the new model.

**Out of scope:** the deferred design proposals (178 workshop diagrams / 179 fragment-priority-drop / 180
fail-loud) — those are separate slices; F-174 feature-closeout, merge, beta — those follow this iteration.

**Capacity note:** documentation-only; planned within the global 20 SP cap (no raise). Plan + tasks are authored
at the plan/tasks boundaries after the specify verdict.

## Real-Host Evidence Update (2026-06-14/15)

The iteration-012 docs must incorporate the post-iter-011 dogfood evidence, which corrected the original
"Claude-only confirmed" assessment:

- **Codex confirmed**: SessionStart bootstrap rendered the orientation banner, consumed the bounded handover,
  surfaced `AWAITING YOUR VERDICT`, treated `continue` as resume rather than approval, and wrote a Stop handover.
- **Claude confirmed**: resumed from Codex handover, rendered the pointer-mode user-profile/adaptation banner, and
  emitted the Claude-only `SPECREW-VERDICT-BOUNDARY` marker in the boundary packet.
- **Copilot confirmed**: bootstrap-journal recorded `host: copilot`, `mode: welcome-back`,
  `handover_valid: true`; the handover later flipped to `from_host: copilot`, `source: agentStop`, confirming
  Copilot end-of-turn handover writes live.
- **Cursor pending**: not yet live-dogfooded in this evidence set.
- **Integrity caveat**: non-Claude hosts are confirmed for mechanical bootstrap/resume/handover continuity, not for
  automatic rich boundary-packet/verdict capture. Without the Claude marker path, they safely degrade to
  "awaiting your verdict" and ask the human to re-confirm.
