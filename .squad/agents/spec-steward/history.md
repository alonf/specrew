# Spec Steward History

Project-specific learnings and patterns discovered during work.

## Learnings

### 2026-05-08: Spec Quality Hardening Pass

Applied surgical spec-hardening to close contract gaps in specs 002 and 005 from roadmap review. Key improvements:

- **Canonicalizer versioning and derivation allow-lists** (Spec 002): Closed loophole where canonicalization could use open-ended derivation reasoning. Now requires explicit versioned allow-list artifacts and version recording in canonicalization reports.
- **Worked-example preset requirement** (Spec 005): Prevented preset content from being named but not specified. `node-public-ws-service` preset must include fully-specified worked example in the preset artifact itself.
- **Known-traps corpus seeding** (Spec 005): Corpus must be seeded from dogfooding findings and prior learnings rather than starting empty.
- **Mechanical check demotion workflow** (Spec 005): Provided safety valve for noisy checks that can be demoted to advisory through explicit reviewed workflow.
- **Strongest-class binding for hardening gate** (Spec 005): Aligned hardening gate routing with bug-hunter lens policy by default.
- **Quality-drift detection timing** (Spec 005): Bound detection to end of review phase before iteration close, preventing silent quality debt accumulation.
- **Phased implementation guidance** (Spec 005): Added 4-phase delivery structure to guide planning without mandating single undifferentiated block.

**Pattern discovered**: When closing contract gaps, prefer surgical edits that add explicit constraints or versioned artifacts over rewriting requirements. This preserves traceability and approval history while strengthening the contract.

### 2026-05-08: Phase 2 Multi-Iteration Repair

Repaired feature `005-stack-aware-quality-bar` Phase 2 planning after drift appeared between the feature-level capacity claim and the generated 32-task package. The governing fix was to keep the repo-standard 20-point capacity intact, rewrite the feature plan/tasks to name concrete execution slices (`003`-`005`), and make Iteration 003 the only MVP execution candidate until its hardening-gate contract is accepted.

**Pattern discovered**: when task generation reveals that one phase-level package no longer fits a single iteration, repair the parent plan and task language before repairing the active iteration. Otherwise the new iteration inherits a false capacity story and every downstream approval artifact starts from drift.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->
