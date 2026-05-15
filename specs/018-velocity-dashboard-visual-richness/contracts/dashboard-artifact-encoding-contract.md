# Contract: Dashboard Artifact Encoding and Persistence

## Purpose

Define how Feature 018 rich-mode rendering is persisted into stored dashboard artifacts.

## Required Artifact Paths

```text
specs/<feature>/iterations/<NNN>/dashboard.md
specs/<feature>/closeout-dashboard.md
```

## Persistence Rules

- Stored artifacts remain historical closeout snapshots.
- Re-running the live dashboard later must not silently rewrite an existing stored snapshot.
- Stored artifacts preserve dashboard section semantics and ordering.

## Encoding Rules

- Files must be written as UTF-8 without BOM.
- Files must use LF line endings.
- Persisted dashboard text must strip ANSI escape sequences.
- Persisted dashboard text may preserve Unicode glyphs.

## Validation Rules

- Artifacts must remain readable in plain text and Markdown viewers.
- ANSI codes must not appear in stored snapshots.
- Unicode preservation must not be treated as an error when ANSI is absent.
- Missing required post-rollout artifacts remain bounded governance warnings, not silent failures.

## Compatibility Rules

- Iteration closeout may continue to use compact dashboard rendering.
- Feature closeout may continue to use fuller dashboard rendering.
- Historical immutability and Feature 017 closeout semantics remain unchanged.
