---
name: "specrew-drift-check"
description: "Detect drift between the spec, plan, tasks, and implementation; record findings to drift-log.md before review concludes."
domain: "lifecycle-review"
confidence: "high"
source: "Specrew governance pillar — review/closeout ceremony helper"
---

# specrew-drift-check

**Type**: Analysis Skill  
**Schema**: v1  
**Status**: Active execution/review method

## Purpose

Detect specification drift by comparing delivered output against the cited requirement and return a review-ready drift decision with evidence.

## When to Use

- After each task completion
- During Review/Demo as the batch fallback
- Any time a reviewer or implementer suspects the output and the spec disagree

## Inputs

| Input | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| task_id | string | Yes | Task identifier for the completed work (for example `T-012`) |
| task_output | string/path | Yes | The deliverable or output from the completed task |
| requirement_ref | string | Yes | Requirement identifier (for example `FR-003`) |
| requirement_text | string | Yes | Full text of the requirement from the spec |
| spec_path | path | Yes | Path to the authoritative spec file |
| drift_log_path | path | No | Path to `iterations/NNN/drift-log.md` when the result should be prepared for immediate logging |
| reviewer_notes | string/array | No | Existing reviewer concerns or context that should be tested against the requirement |

## Process

1. Confirm the authority before judging the output:
   - locate `requirement_ref` in `spec_path`
   - use the spec text as authoritative if `requirement_text` was copied inaccurately
   - extract required behavior, explicit constraints, exclusions, and deferred scope
2. Gather concrete evidence from `task_output`:
   - identify the files, commands, artifacts, or behavior that prove what was delivered
   - do not return PASS based on intention or a status note alone
3. Compare the delivered output to three drift questions:
   - Did we omit something required?
   - Did we add something not authorized?
   - Did we contradict the requirement or a documented deferral?
4. Classify each mismatch for reviewer clarity:
   - `gold-plating` = unauthorized added behavior
   - `incomplete` = required behavior missing or only partially delivered
   - `violation` = delivered behavior contradicts the requirement or accepted scope boundary
5. Choose a resolution path for each drift event:
   - `spec-updated`
   - `implementation-reverted`
   - `deferred`
   - `human-decision`
6. Produce a drift-log-ready result:
   - PASS: provide explicit evidence summary and say no drift event is required
   - DRIFT: emit contract-aligned event data and a Markdown snippet that can be copied into `drift-log.md`
   - if `drift_log_path` points at a zero-drift placeholder log, note that the summary text must be updated when the first event is added

## Outputs

| Output | Type | Description |
| ------ | ---- | ----------- |
| verdict | enum: PASS, DRIFT | Whether drift was detected |
| evidence_summary | string | Concrete evidence used to justify the verdict |
| drift_events[] | array | List of detected drift events (empty if PASS) |
| drift_events[].type | enum: gold-plating, incomplete, violation | Type of drift |
| drift_events[].drift_id | string | Drift event identifier (for example `DR-001`) |
| drift_events[].detected_at | ISO datetime | When the drift was identified |
| drift_events[].task_ref | string | Task that triggered the check |
| drift_events[].requirement_ref | string | Requirement identifier for the violated or exceeded requirement |
| drift_events[].severity | enum: minor, moderate, critical | Severity level for review routing |
| drift_events[].description | string | What deviated and how |
| drift_events[].requirement_citation | string | Specific requirement text violated |
| drift_events[].resolution | enum: spec-updated, implementation-reverted, deferred, human-decision | Chosen resolution path |
| drift_events[].resolution_detail | string | What should happen next to resolve the drift |
| drift_events[].log_snippet | string | Markdown-ready snippet aligned to the drift-log contract |
| drift_log_update_note | string | Guidance for updating `drift-log.md` summary text when needed |

## Side Effects

- Intended to append or prepare entries for `iterations/NNN/drift-log.md`
- When the first drift event is detected, the zero-drift placeholder summary in `drift-log.md` must be replaced with the real event count and resolution status
- No side effects if verdict is PASS

## Error Handling

- If `spec_path` is not found: return DRIFT with reason `spec file missing`
- If `requirement_ref` is not found in the spec: return DRIFT with reason `requirement not in spec`
- If `task_output` is empty: return DRIFT with reason `task output missing evidence`
- If the copied `requirement_text` disagrees with the spec: continue with the spec text and report `stale requirement text supplied`

## Review Standard

This skill is only complete when:

1. PASS results cite concrete evidence, not optimism
2. DRIFT results can be copied into `drift-log.md` without reformatting
3. every drift event is traceable to both a task and an authoritative requirement citation
