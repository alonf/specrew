# Data Model: F-046 Specrew Bug-Bash Bundle

**Feature**: `046-046-bug-bash`  
**Date**: 2026-05-25  
**Purpose**: Define entities, attributes, relationships, and validation rules for F-046 Bug-Bash items.

## Entity: BoundarySyncTransition

**Purpose**: Represents the transition between boundaries during a sync operation.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| ProjectRoot | String | Yes | Must resolve to a valid path | Path to project root |
| CurrentBoundary | String | Yes | Canonical boundary type | Starting boundary |
| TargetBoundary | String | Yes | Canonical boundary type | Target boundary |
| AuthorizingHuman | String | Yes | Non-empty string | Human authorizing the sync |
| VerdictText | String | Yes | Parsed by Parse-SpecrewBoundaryVerdict | Explanation or directive |
| AuthCommitHash | String | No | 40-character hex string | Authorizing commit hash |

---

## Entity: ScaffolderProtectionVerdict

**Purpose**: Represents the protection evaluation results for a target scaffold file.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| TargetPath | String | Yes | Valid file path | Destination file to write |
| Exists | Boolean | Yes | None | Whether the destination file exists |
| HasPopulatedVerdict | Boolean | Yes | None | True if accepted or non-placeholder verdicts are found |
| SiblingPendingPath | String | Yes | Valid file path | Path to sibling `.pending` file |
| Action | String | Yes | `preserved` / `created` / `pending` | Action taken by the scaffolder |
