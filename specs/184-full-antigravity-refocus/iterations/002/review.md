# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-18
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-011, FR-016, FR-018, SC-011, SC-019, SC-020 | pass | Host-landscape discovery vs INSTALLED CLIs (codex 0.139.0, agy 1.0.9, claude); premise confirmed, no split-guard. Codex `/init` create-only (skips existing AGENTS.md), Claude static-CLAUDE.md (hooks deferred, 10K cap), Antigravity hooks unchanged. See discovery-host-landscape.md. |
| T002 | FR-012, FR-013, FR-018, SC-012, SC-013, SC-020 | pass | Single-source fragment (728B, exact FR-013 guard) + byte-for-byte managed-section merge; 8/8 unit (preservation, idempotence, exact guard, size budget, deploy round-trip). FileList carries fragment + helper (SC-020). |
| T003 | FR-011, FR-015, FR-016, FR-018, SC-011, SC-014, SC-019, SC-020 | pass | Host-neutral manifest-driven deploy/refresh/heal wired into init/update/start; 6/6 integration (byte-for-byte preservation across 3 InstructionsFiles, AGENTS.md dedupe, idempotent refresh, start-heal). No host-name branches. |
| T004 | FR-013, FR-014, FR-018, SC-013, SC-015, SC-018 | pass | Bootstrap front-loads the coordinator posture + the FR-013 guard from the single source (Get-SpecrewCoordinatorFragment); 3-copy mirror parity GREEN; 7/7 (guard present, ordered above banner+contract, real-provider e2e); DirectiveVersionBranch regression 9/9. |
| T005 | FR-012, FR-015, FR-016, FR-018, SC-011, SC-012, SC-013, SC-014, SC-015, SC-019, SC-020 | pass | Firewall extends to guard the new instruction-delivery core; NEGATIVE test verified fails-closed on a planted `HostKind -eq 'antigravity'` literal and passes clean manifest-driven content (the gate catches the defect, not just the happy path). Full firewall green (360 files). |
| T006 | FR-017, SC-016, SC-017, SC-018, TG-005 | pass | Real-host (machine-local, TG-005): FR-011 + governed workshop validated on strong models (Opus/Claude), cross-host resume; the iter-001 stale-cursor re-scaffold did NOT recur (under Flash the verdict-ledger was reset by self-authorization, Prop-142). SC-017 weak-model (Flash) boundary-discipline FAIL = the FR-017-required honest caveat (evidence, NOT failure). GEMINI.md priority docs-corroborated only. See real-host-evidence.md. |

<!--
  Gap Ledger schema (validator-enforced):
    EVERY non-empty line MUST be a bullet entry classified with one of two tokens:
      - "fixed-now"  — the gap was repaired during this iteration
      - "deferred"   — the gap is parked with explicit human approval (the approval
                       reference must be recorded in .squad/decisions.md)
-->

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope FR-011..FR-018, SC-011..SC-020, and TG-005 are verified by automated tests + the machine-local real-host evidence: fixed-now.

## Notes

### What was built (Proposal 145 implementation-completion review)

A host-neutral, manifest-driven persistent-coordinator-instruction delivery path:

- **Single-source fragment** (`templates/coordinator-instructions.md`, 728 bytes) carrying the exact FR-013 anti-`specify.exe workflow` guard — the ONE source for both the InstructionsFile section and the bootstrap.
- **Merge primitive** (`scripts/internal/instruction-file-merge.ps1`): delimited managed-section insert/refresh with byte-for-byte preservation of everything outside the section, idempotent, atomic write, lean size budget vs the Codex 32 KiB AGENTS.md cap.
- **Deploy orchestration** (`scripts/internal/instruction-deploy.ps1`): enumerates supported hosts from the registry, reads each manifest's `InstructionsFile`, dedupes the shared `AGENTS.md`, and deploys; wired into `specrew init`/`update`/`start` (deploy/refresh/heal). No host-name branches (FR-015).
- **Bootstrap front-load** (`Format-BootstrapDirective`, 3-copy mirror): the coordinator posture + the guard are front-loaded above the banner/contract, sourced from `Get-SpecrewCoordinatorFragment` so the two surfaces cannot drift.
- **Firewall** (`tests/integration/host-coupling-firewall.tests.ps1`): the new core is under the wall, with a negative test proving fail-closed detection.

### Requirement coverage

All in-scope FRs (FR-011..018), SCs (SC-011..020), and TG-005 are met — bidirectional traceability PASS (tasks.md). The real-host SCs (SC-016/017/018) are evidenced machine-local.

### Test evidence (all run, real counts)

- Unit: `instruction-file-merge.tests.ps1` 8/8.
- Integration: `instruction-deploy.tests.ps1` 6/6; `host-coupling-firewall.tests.ps1` full green incl. the negative test.
- Bootstrap: `CoordinatorFrontLoad.Tests.ps1` 7/7; `ProviderMirrorParity.Tests.ps1` green (3 copies in sync); `DirectiveVersionBranch.Tests.ps1` 9/9 regression.
- Scoped `validate-governance`: PASS.

### The two the maintainer flagged for hardest scrutiny

- **T005 negative test:** verified it actually FAILS-CLOSED on a planted single-host literal and PASSES clean content — it catches the defect, not only the happy path.
- **T006 GEMINI.md result:** the `AGENTS.md → GEMINI.md` priority is **docs-corroborated only** — the behavioral BANANA/APPLE probe was staged but NOT run; weak corroboration is that both Opus and Flash honored the `AGENTS.md` coordinator section. The maintainer accepted docs-only rather than running the probe. `GEMINI.md` handling was deferred at T001 (out of scope), so this is a recorded residual, not a requirement gap.

### Honest residuals + deferred follow-ups (filed, not blind-fixed; drift-log)

- **Weak-model boundary-discipline FAIL** (Gemini Flash self-authorized `specify→clarify→plan` despite the instructions + the refocus digest) → this IS the FR-017-required honest caveat (evidence); the deterministic-guard fix is **Proposal 180** (out of scope).
- **Verdict-ledger reset** (Flash's self-approvals vanished on disk) → **Proposal 142**.
- **Cold-init dangling reference** (fragment instructs reading files only `specrew start`/the hook create; the hook self-heals on the normal path) → **Proposal 143** / absence-tolerant wording.
- Antigravity transcript-parser gap + concurrent-session false advisory → candidate nits.

### Confidence

**High** on the automated surface (preservation, idempotence, host-neutrality, mirror parity, single-sourced guard — all behaviorally verified) and the strong-model real-host path. The weak-model governance caveat is honestly evidenced (FR-017), not papered over.

### Release posture (carry-forwards OPEN — SC-018)

beta-before-stable, `MigrateLegacyTopLevelEventMap` legacy-upgrade validation, and machine-local `agy` evidence (gathered — keep the label). No full/verified/stable Antigravity-parity claim.
