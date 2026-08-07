# Workshop Record: integration-api (medium)

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Confirmation**: human-confirmed (I1/I2/I3 each explained and picked
one-at-a-time at the maintainer's request)

## Migration surface (agreed)

```text
        specrew init / update  ──►  Spec-Kit CLI (pin 0.8.4 → 0.12.9)
        ─────────────────────────────────────────────────────────────
        scripts/specrew-init.ps1 (~line 621), TODAY:
          specify init ... --ai copilot            ← REMOVED at v0.10.0
        AFTER:                                       (hard-fails on 0.12.9)
          specify init ... --integration <key>
          --script ps, --ignore-agent-tools        ← VERIFY alive on 0.12
        ─────────────────────────────────────────────────────────────
        opt-in shifts:
          git extension        opt-in since 0.10.0 — add ONLY on evidence
          agent-context ext    full opt-in since 0.12.0 — same
          extension.yml hooks  per-event LISTS + priority since 0.10.0
                               — must still LOAD under 0.12 (VERIFY)
        ─────────────────────────────────────────────────────────────
        pin update surface (mechanical once verified):
          CI env SPEC_KIT_VERSION · version-check.ps1 supported-versions ·
          extension.yml requires/min_speckit · Get-SpecKitGitReference

        Squad CLI (pin 0.9.1 → 0.11.0) — clean, no breaking notes
          dependency-install.ps1 minimum · CI SQUAD_VERSION ·
          validate-versions defaults · probe `squad init --non-interactive`
          (SCRATCH DIR ONLY) + .squad layout via existing suites
```

## I1 — Opt-in extensions (decided)

**Evidence-first minimalism.** Probe the 0.12.9 CLI in a scratch directory
(NEVER the governed cwd — init probes mutate lifecycle state): flag survey
(`--integration` key set, `--script ps`, `--ignore-agent-tools`), then run the
existing integration suites against a 0.12.9-initialized fixture with NO
extensions. Add `specify extension add git` / agent-context ONLY if a governed
flow demonstrably depends on it (Specrew does its own git work via
create-new-feature.ps1 + boundary commits, so the expectation is neither is
needed). The decision gets recorded WITH the probe evidence. Rationale: every
extension is permanent downstream surface to keep consumer-clean (205) and
re-verify at every bump.

## I2 — Version posture (decided)

**Single tested pin: 0.12.9.** Pin, install, test, and support exactly
0.12.9; version-check warns anything else with a clear update instruction. No
dual-syntax runtime branch (the 0.10.0 flag break makes 0.8.4-vs-0.12.9
mutually exclusive syntaxes — a window means a permanently doubled fixture
matrix). Specrew controls spec-kit installation via dependency-install.ps1,
so the window's benefit is near-nil. Squad: same posture, 0.11.0.

## I3 — Contract evolution for the new data seams (decided)

**Deliberately asymmetric package:**

- **Catalog `default_timeout_seconds` column**: additive with tolerant
  reader — absent column → fall through to the 600 floor; no migration, old
  rows and stale mirrors cannot break resolution.
- **SelfLeakDenyList**: carries `schema_version`. Two readers at two trust
  points: the repo CI lane is version-locked (same repo, no skew); the
  consumer side (update heal + gateway advisory) CAN skew → mismatch =
  fail-open WARN (advisory-first posture; product-domain schema precedent).
- **TrackerHonestyCheck**: parse contract on our canonical artifacts
  (task-status enums, capacity lines, review.md verdict); parse failure =
  FAIL-CLOSED — declines the bypass, digest stales exactly as today (costs at
  worst one re-review; fail-open here would be the false-green door codex's
  P2 killed).
