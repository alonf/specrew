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
| task_output | string/path | Yes | The deliverable or output from the completed task |
| requirement_ref | string | Yes | Requirement identifier (for example `FR-003`) |
| requirement_text | string | Yes | Full text of the requirement from the spec |
| spec_path | path | Yes | Path to the authoritative spec file |

## Process

1. Read the requirement text and extract:
   - must-do behavior
   - explicit constraints
   - explicit exclusions or deferrals
2. Compare the delivered output to three questions:
   - Did we omit something required?
   - Did we add something not authorized?
   - Did we contradict the requirement?
3. Classify each mismatch:
   - gold-plating
   - incomplete
   - violation
4. Assign severity:
   - minor = cosmetic or low-risk overshoot
   - moderate = materially changes scope or acceptance
   - critical = contradicts a must-have requirement or blocks review
5. Return a verdict plus a log-ready drift entry for each mismatch

## Outputs

| Output | Type | Description |
| ------ | ---- | ----------- |
| verdict | enum: PASS, DRIFT | Whether drift was detected |
| drift_events[] | array | List of detected drift events (empty if PASS) |
| drift_events[].type | enum: gold-plating, incomplete, violation | Type of drift |
| drift_events[].severity | enum: minor, moderate, critical | Severity level |
| drift_events[].description | string | What deviated and how |
| drift_events[].requirement_citation | string | Specific requirement text violated |
| drift_events[].log_snippet | string | Markdown-ready snippet for `drift-log.md` |

## Side Effects

- Intended to append or prepare entries for `iterations/NNN/drift-log.md`
- No side effects if verdict is PASS

## Error Handling

- If `spec_path` is not found: return DRIFT with reason `spec file missing`
- If `requirement_ref` is not found in the spec: return DRIFT with reason `requirement not in spec`
- If `task_output` is empty: return DRIFT with reason `task output missing evidence`

## Review Standard

This skill is only complete when the result can be copied directly into `drift-log.md` and cited during review without reinterpretation.
