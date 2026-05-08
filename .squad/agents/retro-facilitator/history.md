# Retro Facilitator History

Project-specific learnings and patterns discovered during work.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->

**Pattern:** Effort estimation remains accurate when task boundaries are clear and Phase-N clarity work is complete before iteration starts. **Context:** Iteration 002 delivered all 7 tasks at estimated effort (zero variance) because Phase 1 scope was well-defined from prior planning, and no discovery surprises emerged during implementation. When starting a new phase or feature, front-load clarification work so subsequent iteration estimation benefits from stable scope.

**Pattern:** Fail-closed governance enforcement prevents silent compliance gaps but requires upfront configuration of test-command harness. **Context:** Iteration 002 implemented required-gate enforcement successfully, but coverage verification defaulted to `not_executed` because reviewer config did not declare test commands. This pre-existing gap should be resolved before Phase 2 iterations begin, to prevent discovery of missing validation infrastructure at the wrong phase boundary.

**Pattern:** Infrastructure scaffolding scales cleanly when coupled to existing artifact flows rather than creating parallel mechanisms. **Context:** Adding `quality-evidence.md` and `mechanical-findings.json` to the iteration artifact surface worked because the publish flow was integrated into existing reviewer and scaffold paths. No coupling rework was needed.