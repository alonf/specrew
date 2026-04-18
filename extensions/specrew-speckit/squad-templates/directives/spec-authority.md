# Directive: Spec Authority

**Schema**: v1  
**Status**: Active governance directive

## Principle

The spec is the authoritative source of truth for what the system should do. Implementation decisions must not contradict the spec without raising a drift event.

## Scope

This directive applies to all agents executing tasks within a Specrew-governed iteration.

## Rules

1. **Read the requirement before acting**
   - Before starting any task, read the cited requirement from `specs/NNN-feature/spec.md`
   - Capture constraints, acceptance conditions, and anything explicitly deferred
   - If the requirement is ambiguous, stop and route the ambiguity to Picard or Alon

2. **Do not add gold-plating**
   - Implement only what the spec requires
   - Suggestions belong in notes, decisions, or retro actions until approved
   - A useful idea is still drift if it ships without authority

3. **Do not omit required functionality**
   - If the spec says `MUST`, implement it
   - If the spec says `SHOULD`, implement it unless there is a documented reason not to
   - If the spec says `MAY`, treat it as optional

4. **Raise drift immediately**
   - If delivered output differs from the requirement, invoke `specrew-drift-check`
   - Document the deviation in `drift-log.md`
   - Do not convert a disagreement with the spec into an undocumented implementation choice

5. **Do not change the spec without approval**
   - If you believe the spec is wrong, raise the issue to the Spec Steward
   - Only a tracked change or explicit decision can alter the governing requirement
   - Keep the implementation aligned to the last approved authority text

## Enforcement

Violations of this directive are detected by:

- **Review/Demo ceremony**: Reviewer compares implementation to spec
- **Drift-check skill**: Automated analysis of task output vs. requirement text
- **Governance validator**: later lifecycle phases fail if the required artifacts are incomplete

## Consequences

Tasks that violate spec authority receive a **needs-work** verdict and must be reworked in the next iteration.

---

**Deployment**: This directive text will be merged into `.squad/agents/*/charter.md` by `specrew init`.
