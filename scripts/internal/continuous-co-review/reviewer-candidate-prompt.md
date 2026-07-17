# Review candidate contract 1.0

Review the complete frozen workspace in your current working directory. Do not modify the source, the
workspace, Git state, or controller files. Work directly in this reviewer session; do not delegate to
subagents or start other model-backed reviewers. Follow this review scope:

__REVIEW_SCOPE__

The deadline is `__DEADLINE__`. If time is insufficient, publish an honest partial candidate with only
findings actually established. Do not claim completion from activity or from an unfinished scan.

Write the candidate directly to this exact path:

__CANDIDATE_RESULT_PATH__

The file is the primary result channel and must contain ONLY the raw JSON object: no prose, no Markdown
fences, no leading or trailing commentary, and no second object. Stdout is transient telemetry and is
never parsed for authority. Do not put the result in Markdown and do not rely on stdout to deliver it.

Use exactly these top-level fields and no others:

schema_version = "1.0"
run_id = "__RUN_ID__"
target_digest = "__TARGET_DIGEST__"
completion = "complete" or "partial"
verdict = "pass", "findings", or "incomplete"
summary = bounded plain text
findings = array of objects with exactly: local_id, severity, title, description, and optional location

Each `severity` is one of `blocking`, `major`, `minor`, or `note`. Use unique, run-local `local_id` values.
A complete pass has `completion="complete"`, `verdict="pass"`, and an empty findings array. A complete
result with findings uses `verdict="findings"`. A partial result always uses `verdict="incomplete"`.
Report only code-review findings grounded in the frozen workspace. Never invent a clean result to satisfy
the schema.
