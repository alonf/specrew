# V-R7-2: Validation Report — Per-Role Delegated-Agent Routing Surface

**Requirement**: FR-021  
**Date**: 2026-05-03T17:30:00Z  
**Status**: VALIDATION COMPLETE  
**Verdict**: ✅ VIABLE FOR IMPLEMENTATION

---

## Objective

Validate that the `preferred_agent` field in `role-assignments.yml` provides a viable surface for per-role agent routing, and document the routing path for FR-021 implementation (T-202/T-203).

---

## Design Surface Validation

### 1. Role Assignments Schema (`role-assignments.yml`)

**Location**: `.specrew/role-assignments.yml` (source template: `extensions/specrew-speckit/templates/role-assignments.yml`)

**Field Definition** (data-model.md, line 81):

```yaml
preferred_agent: string? | Optional | Preferred Copilot-accessible agent family (e.g., `copilot`, `claude`, `codex`)
```

**Current Template State** (as of 2026-04-30):

```yaml
roles:
  - name: "Spec Steward"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "copilot"  # ← Configured per-role
    responsibilities: "Maintains spec integrity, detects drift, reconciles deviations..."
  
  - name: "Reviewer"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "copilot"  # ← Configured per-role
    responsibilities: "Conducts Review/Demo ceremony..."
  
  - name: "Implementer"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "copilot"
    responsibilities: "Executes tasks from the iteration plan..."
```

**Validation Result**: ✅ **VIABLE**  

- Field is present in all baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator)
- Field is optional (marked as `string?`) — safe for existing consumers to ignore
- Spec requirement (FR-021) is satisfied: "Agent preference is per-role and configurable in `role-assignments.yml` via a `preferred_agent` field"

---

### 2. Routing Logic Path for Implementation

**Integration Points** (identified for T-202/T-203):

#### A. **Squad Team Configuration**

- **Where**: `.squad/team.md` (populated by `specrew init`)
- **How**: The `deploy-squad-runtime.ps1` script (extension/specrew-speckit/scripts/) builds Squad team configuration from `role-assignments.yml`
- **Action**: Extract `preferred_agent` from each role's entry and configure Squad's agent routing rules
- **Example**:

  ```yaml
  # In .squad/team.md (generated from role-assignments.yml)
  - role: "Spec Steward"
    agent: "unassigned"  # Human or AI
    preferred_model: "claude"  # Derived from role-assignments.yml preferred_agent
  ```

#### B. **Iteration Execution Routing**

- **When**: During task assignment (execution phase)
- **Where**: Squad's task routing logic (`specrew-iteration-resume` skill and planning ceremony)
- **How**: When assigning a task owner:
  1. Check if owner is a review role (Reviewer, Spec Steward)
  2. Lookup `preferred_agent` from role-assignments.yml
  3. If `preferred_agent` differs from Implementer's preferred agent, route to delegated agent
  4. If `preferred_agent` is not available or not enabled, fall back to default (Copilot)
- **Safety Gate**: Independent-reviewer principle only applies when multiple agents are enabled AND the preferred agent is available

#### C. **Ceremony Integration Points**

1. **Planning Ceremony** (specrew-speckit/squad-templates/ceremonies/planning.md)
   - **Inputs**: role-assignments.yml is already listed (line 32)
   - **Action**: Planner reviews preferred_agent assignments during task decomposition

2. **Review/Demo Ceremony** (specrew-speckit/squad-templates/ceremonies/review-demo.md)
   - **Inputs**: role-assignments.yml for Reviewer routing
   - **Action**: Ensure Reviewer role is routed to preferred agent during review execution

---

### 3. Configuration Consistency Check

**Cross-References**:

- ✅ `data-model.md` (line 81): Role Assignments schema includes preferred_agent field
- ✅ `role-assignments.yml` template: All baseline roles have preferred_agent field
- ✅ `planning.md` ceremony: Inputs include role-assignments.yml (line 32)
- ✅ `squad-extension.md` contract: Directives embedded in agent charters preserve role assignments

---

### 4. Agent Availability Detection

**Prerequisite**: FR-022 (detect available Copilot / Agent HQ selectable agents)

**Implementation Pattern**:

```powershell
# In specrew init (detects enabled agents)
$enabled_agents = Get-EnabledAgents  # From iteration-config.yml agents section (FR-022)

# In task routing (checks preferred agent is enabled)
if ($role.preferred_agent -in $enabled_agents) {
    Route-Task-To-Agent $role.preferred_agent
} else {
    Route-Task-To-Agent "copilot"  # Fallback to default
}
```

**Viability Note**: This pattern assumes FR-022 (agent detection and consent) is complete. Current status: FR-022 is deferred to Iteration 2 (post-MVP). V-R7-2 documents the surface; T-202/T-203 can implement the routing logic in parallel as long as FR-022 detection is available when execution begins.

---

## Routing Architecture (Proposed for T-202/T-203)

### Phase 1: Configuration (T-201, T-203 wiring)

1. `role-assignments.yml` defines preferred agents per role
2. `iteration-config.yml` agents section lists enabled agents (FR-022)
3. Planning ceremony uses both files to assign tasks

### Phase 2: Execution (T-202 implementation)

1. Task routing logic checks preferred_agent for review roles
2. If preferred agent is enabled, route to that agent
3. If preferred agent is unavailable/disabled, fall back to Copilot (default)
4. Log routing decisions to state.md for retrospective analysis

### Phase 3: Review Integration (built-in to T-202)

1. Reviewer and Spec Steward tasks auto-route to preferred agent
2. Review ceremony invokes the assigned reviewer agent
3. Independent-perspective principle maintained across iterations

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Preferred agent not available at execution time | Medium | FR-022 detection + fallback to Copilot default |
| User misconfigures preferred_agent field | Low | schema validation in `deploy-squad-runtime.ps1` |
| Multiple iterations with different enabled agents | Low | Routing logic checks enabled agents at execution time, not at planning time |
| Spec Steward routing breaks drift detection | Low | Drift detection is independent of agent; Spec Steward role responsibility is unchanged |

---

## Implementation Path for FR-021

### T-202: Implement per-role routing logic (2 pts)

- Add routing decision logic to task assignment in planning ceremony
- Check preferred_agent from role-assignments.yml
- Implement fallback to Copilot if preferred agent unavailable
- Add logging to state.md for routing decisions

### T-203: Wire effort model + routing into planning artifact (1 pt)

- Update planning.md output to include preferred_agent assignments per task
- Ensure capacity-planning skill respects role assignment constraints
- Add routing validation to planning ceremony gates (FR-021 enforcement)

### Prerequisites

- ✅ V-R7-2: Validate surface is viable (THIS DOCUMENT)
- FR-022: Agent detection and consent (deferred to Iter 2, but required for execution)
- T-201: Effort model fields verified and documented

---

## Acceptance Criteria (for V-R7-2)

- ✅ `preferred_agent` field is present in all baseline roles in role-assignments.yml template
- ✅ Field is optional and safe for existing consumers to ignore
- ✅ Integration points identified (team.md, routing logic, ceremony inputs)
- ✅ Agent availability handling documented (fallback to Copilot)
- ✅ Implementation path documented for T-202/T-203 without blocking on FR-022
- ✅ Risk assessment complete; no viability blockers found

---

## Conclusion

✅ **VERDICT: VIABLE FOR IMPLEMENTATION**

The `preferred_agent` field in `role-assignments.yml` provides a clean, schema-compliant surface for per-role agent routing. The routing logic path is clear and can be implemented in T-202 without waiting for FR-022 (the detection gate). Fallback handling ensures graceful degradation if preferred agents become unavailable.

**Blocker Status**: None. V-R7-2 validation unblocks T-202/T-203.

---

## Evidence

- Source: `data-model.md` (role assignments entity)
- Source: `role-assignments.yml` template
- Source: `planning.md` ceremony contract
- Source: `squad-extension.md` (skill and directive contracts)

**Reviewer**: Data (Planner)  
**Date**: 2026-05-03  
**Signature**: ✅ Validation complete and ready for implementation handoff
