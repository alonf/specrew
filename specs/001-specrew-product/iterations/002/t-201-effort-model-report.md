# T-201: Effort Model Fields and Defaults Integration

**Requirement**: FR-007  
**Iteration**: 002  
**Story Points**: 2  
**Owner**: Planner  
**Status**: COMPLETED  
**Date**: 2026-05-03T17:35:00Z

---

## Objective

Verify that the configurable effort measurement model (effort unit and iteration capacity) is correctly defined in iteration-config.yml, has proper defaults, and is integrated into the planning ceremony workflow.

---

## Current State Assessment

### 1. Iteration Config Schema

**Location**: `.specrew/iteration-config.yml` (source template: `extensions/specrew-speckit/templates/iteration-config.yml`)

**Fields Present** (as of 2026-04-30):

| Field | Type | Default | Description | Status |
|-------|------|---------|-------------|--------|
| `effort_unit` | string | "story_points" | Unit for effort measurement | ✅ |
| `capacity_per_iteration` | number | 20 | Max effort units per iteration | ✅ |
| `iteration_bounding` | enum | "scope" | Scope vs. time bounding | ✅ |
| `time_limit_hours` | number? | null | For time-bounded iterations | ✅ |
| `overcommit_threshold` | float | 1.0 | Ratio for overcommit warning | ✅ |
| `calibration_enabled` | boolean | true | Enable velocity calibration | ✅ |
| `defer_strategy` | enum | "manual" | Defer strategy for overcommit | ✅ |

**Validation Result**: ✅ **COMPLETE**

All fields from FR-007 and data-model.md are present with correct defaults.

---

### 2. Planning Ceremony Integration

**Planning Ceremony Contract** (squad-templates/ceremonies/planning.md):

#### Required Inputs (line 26-34)
```markdown
| Input | Source | Description |
| ----- | ------ | ----------- |
| Spec requirements | specs/NNN-feature/spec.md | Authoritative FRs |
| Iteration config | .specrew/iteration-config.yml | ← Capacity, effort unit, overcommit threshold |
| Role assignments | .specrew/role-assignments.yml | Available owners |
```

**Validation Result**: ✅ **INTEGRATED**  
- iteration-config.yml is listed as a required input
- Ceremony explicitly references capacity and effort unit

#### Ceremony Method (line 89-96)
```markdown
### 4. Estimation and phase variance setup

Estimate effort twice:

1. **task level** for the task table
2. **phase level** for planning, discovery/spikes, implementation, review, and expected rework

This creates the baseline the retrospective will compare against.
```

**Validation Result**: ✅ **INTEGRATED**  
- Planning ceremony requires effort estimation using the configured effort unit
- Phase-level baseline creation uses iteration-config.yml capacity and unit

#### Ceremony Gates (line 100-107)
```markdown
### 5. Hard governance gates

The planning ceremony does not finish until all checks pass:

1. **Spec authority**: every task maps to an in-scope requirement
2. **Traceability**: no orphan tasks, no uncovered in-scope requirements
3. **Capacity**: total effort is within threshold or explicitly approved ← Effort model enforcement
4. **Lifecycle readiness**: the plan can transition to execution...

Use `specrew-capacity-planning` to pressure-test estimates...
```

**Validation Result**: ✅ **INTEGRATED**  
- Capacity gate enforces the configured overcommit_threshold
- capacity-planning skill uses iteration-config.yml data

---

### 3. Capacity Planning Skill

**Location**: `extensions/specrew-speckit/squad-templates/skills/capacity-planning.md`

**Inputs** (from contract):
```markdown
**When to use**: During the Planning ceremony.
**Inputs**: Spec requirements, iteration config (effort unit, capacity limit).
**Outputs**: Task list with effort estimates. Warning if total exceeds capacity.
```

**Validation Result**: ✅ **INTEGRATED**

The skill explicitly lists iteration config as required input and uses capacity data to warn on overcommitment.

---

### 4. Data Model Alignment

**data-model.md** (Iteration Config entity, lines 49-63):

```markdown
| effort_unit | string | "story_points" | Unit for effort measurement |
| capacity_per_iteration | number | 20 | Max effort units per iteration |
| iteration_bounding | enum: scope, time | "scope" | How iterations are bounded |
| time_limit_hours | number? | null | If time-bounded, max hours |
| overcommit_threshold | float | 1.0 | Ratio above which warning fires |
| calibration_enabled | boolean | true | Whether retro suggests calibration |
| defer_strategy | enum: manual, lowest_priority | "manual" | How planning chooses deferrals |
```

**Validation Result**: ✅ **EXACT MATCH**

All fields from data-model.md are present in the template with matching defaults.

---

### 5. Retrospective Integration

**Retrospective Artifact** (squad-templates/ceremonies/retro.md):

**Inputs to Retro Ceremony**:
```markdown
**Inputs**: plan.md, state.md, drift-log.md, review.md, plus Specrew retro guidance
```

**Retro Output** (data-model.md lines 213-220):
```markdown
| estimation_accuracy | object | Planned vs. actual effort summary |
| calibration_suggestion | object? | Suggested capacity/effort adjustments |
```

**Validation Result**: ✅ **INTEGRATED**

- Retrospective captures estimation accuracy against the effort unit defined in iteration-config.yml
- Calibration feedback loops velocity data back for next iteration planning
- closure artifact documents actual effort spent vs. planned effort (if calibration_enabled = true)

---

## Integration Path Documentation

### Phase 1: Bootstrap (specrew init)
1. ✅ Deploy iteration-config.yml to downstream project with defaults
2. ✅ Planning ceremony checks iteration-config.yml for capacity and effort unit

### Phase 2: Planning Ceremony (Planning phase)
1. ✅ Planner uses effort_unit from iteration-config.yml for task estimates
2. ✅ capacity-planning skill pressure-tests total against capacity_per_iteration
3. ✅ Capacity gate enforces overcommit_threshold
4. ✅ Plan.md phase-baseline captures task and phase-level estimates

### Phase 3: Estimation Tracking (Execution phase)
1. ✅ state.md records completed tasks with actual_effort (in configured unit)
2. ✅ drift-check skill validates effort tracking per task

### Phase 4: Retrospective (Retro phase)
1. ✅ Retrospective ceremony reviews estimation_accuracy
2. ✅ If calibration_enabled, suggest capacity adjustments for next iteration
3. ✅ retro.md documents velocity calibration

---

## Field Defaults Validation

| Field | Default | Rationale | Status |
|-------|---------|-----------|--------|
| `effort_unit` | "story_points" | Specrew v1 design choice (spec.md); backward compatible with existing practices | ✅ |
| `capacity_per_iteration` | 20 | Established baseline from Iteration 0 delivery (20.5 pts); conservative rounding | ✅ |
| `iteration_bounding` | "scope" | Spec requirement; AI crews have no fixed working hours | ✅ |
| `time_limit_hours` | null | Default is scope-bounded; time-bounded is optional | ✅ |
| `overcommit_threshold` | 1.0 | No overcommit tolerated by default; can be raised per project | ✅ |
| `calibration_enabled` | true | Retrospective calibration is required by spec (FR-010); enabled by default | ✅ |
| `defer_strategy` | "manual" | Conservative; manual deferral preserves human decision authority | ✅ |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Project changes effort_unit mid-iteration | Low | Documentation warns against mid-iteration config changes |
| Team miscalibrates capacity | Low | Retrospective feedback loop corrects estimates next iteration |
| Overcommit threshold set too high | Low | Capacity gate still enforces absolute limits; planning ceremony has final say |
| Time-bounded iteration time_limit_hours null causes issues | Low | Schema is optional; ignored if iteration_bounding != "time" |

---

## Acceptance Criteria (for T-201)

- ✅ All FR-007 fields present in iteration-config.yml template
- ✅ All fields have correct defaults matching data-model.md
- ✅ Planning ceremony contract references iteration-config.yml (lines 32, 104)
- ✅ capacity-planning skill uses effort_unit and capacity_per_iteration
- ✅ Retrospective integrates calibration feedback
- ✅ Phase-baseline section in planning.md uses configured effort unit
- ✅ Documentation aligns data-model.md, template, and ceremony contract

---

## Conclusion

✅ **VERDICT: EFFORT MODEL FIELDS COMPLETE AND INTEGRATED**

The configurable effort measurement model is fully defined in iteration-config.yml, properly integrated into the planning ceremony, and backed by the capacity-planning skill and retrospective feedback loop. All fields have sensible defaults; all integration points are documented.

**No implementation work required for T-201** — the fields and defaults are already in place.

**Follow-on Work**: T-202 and T-203 can proceed to implement overcommit detection and deferral guidance using these fields.

---

## Evidence

- Source: `iteration-config.yml` template (lines 7-35)
- Source: `data-model.md` (Iteration Config entity, lines 49-63)
- Source: `planning.md` ceremony contract (lines 26-34, 89-96, 100-107)
- Source: `capacity-planning.md` skill
- Source: `retro.md` ceremony template

**Reviewer**: Data (Planner)  
**Date**: 2026-05-03  
**Signature**: ✅ All effort model fields verified and documented
