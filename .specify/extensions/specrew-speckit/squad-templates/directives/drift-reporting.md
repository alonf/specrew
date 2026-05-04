# Directive: Drift Reporting

**Schema**: v1  
**Status**: Active governance directive

## Principle

After every task, persist execution state, then check the delivered output against its source requirement before the next task begins.

## Scope

This directive applies to all agents executing tasks within a Specrew-governed iteration.

## Rules

1. **Check for drift after every task**
   - When a task is ready to move to `done`, first update `iterations/NNN/state.md`
   - Record `Last Completed Task`, refresh `Tasks Remaining`, clear or replace `In Progress`, and update the timestamp before moving on
   - Then invoke `specrew-drift-check`
   - Provide the delivered artifact, requirement reference, requirement text, and any reviewer notes already known
   - Do not start the next task until the drift decision is recorded

2. **Report drift immediately**
   - If drift is detected, append or update `iterations/NNN/drift-log.md`
   - Record the task ID, requirement reference, deviation, severity, and chosen resolution path
   - Notify the Spec Steward before treating the task as finished

3. **Do not normalize deviations**
   - Added unplanned behavior = gold-plating
   - Missing required behavior = incomplete
   - Contradicting the requirement = violation
   - Improvements still count as drift until the spec changes

4. **Stop silent roll-forward**
   - Minor drift may continue only after it is logged
   - Moderate or critical drift must pause handoff until the Spec Steward decides whether to rework, defer, or update the spec
   - Never hide drift in a status note or commit message without a drift-log entry

5. **Fallback: batch drift check**
   - If a post-task hook is unavailable, the Review/Demo ceremony runs the same skill in batch
   - Batch mode is a fallback, not permission to skip drift discipline during execution

## Enforcement

Violations of this directive are detected by:

- **Review/Demo ceremony**: Reviewer checks `drift-log.md` for missing entries
- **Resume flow**: `specrew-iteration-resume` relies on current `state.md`; stale state is treated as execution debt
- **Governance validator**: lifecycle checks fail if the iteration advances without required artifacts
- **Spec Steward audit**: Manual review of task outputs vs. requirements

## Consequences

Tasks with missing or suppressed drift receive **needs-work** verdict and can be routed back to execution.

---

**Deployment**: This directive text will be merged into `.squad/agents/*/charter.md` by `specrew init`.
