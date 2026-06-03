---
proposal: 161
title: Confirm + Fix the Managed-Skill "Stuck Preserving" Risk (`.specrew-managed` Sidecar)
status: candidate
phase: phase-2
estimated-sp: 2-8
discussion: surfaced 2026-06-03 during Feature 140 self-host review of `deploy-squad-runtime.ps1` — the `.specrew-managed` per-skill marker drives the "refresh-from-canonical vs preserve-user-edits" decision. Hypothesis (NOT yet confirmed): a deploy path where the marker is absent when the managed/user-edited classification runs makes a Specrew-managed skill get treated as user-edited and silently frozen — canonical refresh stops applying. Module-shipped Squad-runtime deploy behavior; needs a repro to confirm before any fix.
---

# Confirm + Fix the Managed-Skill "Stuck Preserving" Risk

## Why

`deploy-squad-runtime.ps1` keeps Specrew's skill surfaces current by deploying canonical
content and marking each managed skill directory with a `.specrew-managed` sidecar. The
classification that decides whether a skill dir may be refreshed/removed
(`Test-IsManagedLegacySkillDirectory`) is:

1. `.specrew-managed` marker present → **managed** (safe to refresh/remove).
2. Else fall back to a **content heuristic** on `SKILL.md`: a dir whose `SKILL.md` starts with
   `---` (front matter) is treated as **user-edited → preserve**; a dir matching the legacy
   canonical signature (specific heading + namespace + command lines) is treated as managed.

The risk: if the marker is ever **absent** when this classification runs for a skill Specrew
actually owns — e.g. a first-deploy ordering where the dir exists before the marker is written,
or a skill whose canonical content has since gained front matter (which the heuristic at the
`---` check explicitly classifies as user-edited) — then a **managed** skill is misclassified
as **user-edited** and **preserved forever**. The canonical refresh silently stops, freezing
that skill at an old version with no warning. Because the marker is provenance and the heuristic
is a guess, the heuristic can override the truth.

This ships in the module and runs on `specrew init` / `specrew update` / `specrew start` for
Squad-host projects, so real users would hit it.

## Evidence (and why this is a HYPOTHESIS, not a confirmed bug)

`extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`:

- `Test-IsManagedLegacySkillDirectory` (~L502–542): marker present → managed; else the SKILL.md
  heuristic, where a leading `---` (front matter) returns **not managed** (~L526–528).
- Active-root deploy (~L591–600) writes **both** `SKILL.md` and the `.specrew-managed` marker
  (`Set-ManagedFile`). So the **active path does write the marker** — which is exactly why the
  "stuck preserving" path is not obviously reachable today and must be **reproduced** before any
  fix is committed.
- Preserve outcomes: `preserved-legacy-unmanaged-skill` (~L575, L587) — these are the legacy
  `.copilot/skills/` cleanup decisions where the bug, if any, would surface.

## What

- **Tier 0 — Investigate (small, do first).** Build a deploy repro: fresh `specrew init` →
  introduce divergence (edit a managed skill / add front matter to a canonical skill / simulate
  a marker-less dir from an older Specrew) → re-deploy via `specrew update` → observe whether
  canonical refresh applies or the skill stays preserved. Confirm or refute, and capture the
  exact code path.
- **Tier 1 — Fix (only if confirmed).** Make provenance authoritative: whenever Specrew deploys
  a managed skill, (re)write the `.specrew-managed` marker so "managed" is decided by the marker,
  not by a content heuristic that front matter defeats; keep the heuristic strictly as a fallback
  for genuinely pre-marker legacy dirs.

## Scope / Non-goals

- Preserve the existing **intent**: genuinely user-authored skills MUST stay preserved. This only
  closes the gap where a *Specrew-managed* skill is misclassified as user-edited and frozen.
- No change to which skills are canonical, only to the managed/preserve decision.

## Acceptance criteria

- AC1 (investigate): a documented repro that either demonstrates the stuck-preserving bug or
  proves the current logic always refreshes managed skills.
- AC2 (fix, if confirmed): after editing a managed skill, `specrew update` refreshes it from
  canonical (marker present), while a genuinely user-authored skill (no marker, front matter) is
  preserved.
- AC3: tests cover both the refresh-managed and preserve-user-edited paths.

## Effort + phasing

- Tier 0 investigate: ~2 SP. Tier 1 fix: ~3–6 SP if confirmed.
- Schedule after F-140 closeout; bundle with any other `deploy-squad-runtime.ps1` touch.

## Relationships

- Related to the managed-file / managed-block deploy machinery (`Set-ManagedFile`,
  `Set-ManagedBlock`).
- Possible bundle with Proposal [150](150-agent-support-hardening-bundle.md) if it touches deploy
  surfaces.
