# Integration API Workshop Record

**Lens**: integration-api · **Depth**: full · **Confirmation**: human-confirmed
**Facilitated**: one decision at a time with the human (2026-06-08).

```text
Host SessionEnd event
        |
        v
Handover writer (Proposal 130) --writes--> Handover .md + index metadata

Host SessionStart event
        |
        v
F-171 dispatcher --> Bootstrap provider --reads/validates--> handover + state + start marker
        |
        v
Bootstrap directive (data-oriented) --> Agent renders visible orientation + menu
```

## Decision 1 - contract ownership + data-oriented directive

- **F-171 dispatcher** owns hook event ingestion, kill switch, breaker, dedupe, and
  journal envelope.
- **Proposal 130** owns the handover `.md` + index format.
- **Feature 174** owns the **bootstrap directive contract** and the classification
  rules (full bootstrap vs light welcome-back vs cleared-anchor fallback).
- The directive is **data/message-oriented**, not a free-form prompt blob. It may
  carry prose templates, but needs stable fields for: `mode`, `sources`,
  `required_reads`, `render_first` instruction, `menu_intent`, `validation_findings`,
  and dedupe/session metadata.
- The agent remains the interactive consumer; the hook never collects choices.

## Decision 1b - SessionStart marker (do NOT churn the handover on start)

- Feature 174 may write a lightweight **SessionStart marker / journal event** using
  the existing F-171 hook journal / active-session surface - **not** by rewriting the
  Proposal 130 handover `.md` on startup (avoids churn + conflict risk, and keeps
  "last clean exit summary" separate from "session started" telemetry).
- Purpose: if a later launch sees a recent start marker with **no** subsequent
  SessionEnd handover, it can infer the prior session likely died / exited without a
  hook handover, then validate current project state and inspect `git diff`/`status`/
  commits since the marker's recorded HEAD.

## Decision 2 - SessionStart marker contract

- **In scope** as advisory journal/metadata. **No git-commit requirement; no handover
  rewrite on startup.**
- Fields: `started_at`, `host`, `project_root`, `branch`, `head_commit` (plus, when
  resolvable: feature ref, source event, prior handover ref/hash/timestamp,
  dirty-state summary).
- Truth sources: explicit recorded timestamp + git HEAD (filesystem mtime as a hint);
  `git diff` is a diagnosis aid, not the sole source of truth.

## Decision 3 - error / mismatch behavior: fail-open to safe bootstrap

| Bad input | Behavior |
| --- | --- |
| hook event invalid | no bootstrap directive; journal the failure if possible |
| handover invalid / stale | historical context only, or ignore |
| anchor invalid / stale | clear or ignore; do **not** offer resume |
| git / project mismatch | warning + full menu, **not** silent resume |
| start marker newer than handover | warn: possible unclean prior exit |

- Partial failure must never block the user from starting work.
- Invalid state is never treated as authoritative resume truth.
- The directive carries `validation_findings` so the agent can **explain** why it is
  offering full bootstrap instead of resume.
- Any session-anchor clearing is explicit and observable.

## Decision 4 - compatibility testing + host verification baseline

- Unit/contract tests for directive classification + SessionStart marker fields.
- Fixture tests for the SessionEnd handover read/write round-trip using
  Proposal 130-compatible handover examples.
- Regression tests proving F-171 **B1** and **B3** digest behavior unchanged.
- Per-host empirical evidence (Claude, Codex, Copilot, Cursor):
  - direct launch with no valid anchor -> full bootstrap;
  - active valid state -> light welcome-back;
  - stale / closed / non-portable anchor -> clears / falls back;
  - visible menu text appears **before** any structured picker or equivalent choice UI.
- If a host cannot be automated, record manual smoke evidence with exact command,
  observed output, timestamp, and the limitation.
