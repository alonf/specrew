# Directive: Traceability

**Schema**: v1  
**Status**: Active governance directive

## Principle

Every task must record which requirement it implements, who owns it, and the effort estimate. No orphan tasks.

## Scope

This directive applies to all agents creating or modifying iteration plans.

## Rules

1. **All tasks must trace to requirements**
   - Every task in `iterations/NNN/plan.md` must cite a valid requirement
   - Enabling work still needs a governing requirement
   - Placeholder references, em dashes, and nulls are invalid

2. **All requirements must have tasks**
   - Every requirement in scope for the iteration must have at least one implementing task
   - If a requirement has no tasks, either add coverage or remove it from scope
   - Do not leave coverage gaps for review to discover later

3. **Tasks must have complete metadata**
   Each task must record:
   - `task_id`: Unique identifier (for example `T-001`)
   - `title`: Brief description
   - `requirement_ref`: Which requirement this implements
   - `user_story_ref`: Which user story this supports
   - `effort`: Estimated effort in the configured unit
   - `owner`: Assigned role name
   - `status`: Current status

4. **Run traceability before task assignment**
   - Invoke `specrew-traceability-check` during planning, not after execution starts
   - Fix orphan tasks, stale references, and uncovered requirements before approval
   - Treat traceability failure as a planning blocker

5. **Update task status as work progresses**
   - When starting a task: update status to `in-progress`
   - When completing a task: update status to `done` and record actual effort
   - When deferring a task: update status to `deferred` and document reason

## Enforcement

Violations of this directive are detected by:

- **Planning ceremony**: Spec Steward reviews plan for traceability
- **Traceability-check skill**: Automated validation of task-to-requirement mapping
- **Governance validator**: phase transition checks fail if plan metadata or lifecycle artifacts are inconsistent

## Consequences

Plans that violate traceability receive **needs-work** verdict and must be revised before execution begins.

---

**Deployment**: This directive text will be merged into `.squad/agents/*/charter.md` by `specrew init`.
