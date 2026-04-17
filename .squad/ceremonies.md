# Ceremonies

> Specrew operates in four phases: planning -> execution -> review/demo -> retrospective.

## Planning Ceremony

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | before |
| **Condition** | start of a new iteration, newly approved spec work, or tracked change to requirements |
| **Facilitator** | Data |
| **Participants** | Picard, Data, La Forge, Worf, Alon |
| **Time budget** | focused |
| **Enabled** | ✅ yes |

**Agenda:**
1. Read the authoritative requirements and acceptance criteria
2. Map tasks back to source requirements
3. Assign owners and capture effort estimates
4. Flag drift risks before execution begins

---

## Review and Demo Ceremony

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | after |
| **Condition** | a task batch completes or an increment is ready for verdict/demo |
| **Facilitator** | Worf |
| **Participants** | Picard, La Forge, Worf, Alon |
| **Time budget** | focused |
| **Enabled** | ✅ yes |

**Agenda:**
1. Compare each delivered task to its source requirement
2. Produce a verdict: pass, needs-work, or blocked
3. Demo the increment against the requirement narrative
4. Capture drift findings for the retrospective

---

## Retrospective Ceremony

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | after |
| **Condition** | review/demo completes, reviewer rejection occurs, or drift is detected |
| **Facilitator** | Troi |
| **Participants** | all-involved |
| **Time budget** | focused |
| **Enabled** | ✅ yes |

**Agenda:**
1. What happened? (facts only)
2. Measure estimation accuracy, process adherence, and drift events
3. Identify what to keep, change, or tighten in the next iteration
4. Record improvement actions for the next planning ceremony
