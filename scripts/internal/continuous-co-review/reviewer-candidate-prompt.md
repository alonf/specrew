# Review candidate contract 1.0

Review the frozen workspace in your current working directory using risk-based inspection to complete
the requested scope. You are not required to open every file or read every line. A complete candidate
means the requested review scope received reasonable risk coverage; it does not claim exhaustive
line-by-line inventory. Do not mark the review complete when a planned high-risk check remains unfinished.
Do not modify the source, the workspace, Git state, or controller files. Work directly in this reviewer
session; do not delegate to subagents or start other model-backed reviewers. Follow this review scope:

The approved review contract permits only Read, Glob, Grep, and the exact candidate-file Write. Even if
the host exposes additional tools, they are outside the approved review contract. Use Read/Glob/Grep only
for inspection. Do not run tests, shell commands, installers, update commands, or repository automation;
the controller already verified the frozen candidate. Use Write only for the exact candidate result path
below and never create or change any other file.

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
summary = concise plain text
findings = array of objects with exactly: local_id, severity, title, description, and optional location

Keep the candidate well inside the schema bounds: summary at most __MAX_SUMMARY_CHARACTERS__ characters;
no more than __MAX_FINDINGS__ findings; each local_id at most __MAX_LOCAL_ID_CHARACTERS__ characters,
title at most __MAX_TITLE_CHARACTERS__, description at most __MAX_DESCRIPTION_CHARACTERS__, and location
at most __MAX_LOCATION_CHARACTERS__. Shorten prose instead of exceeding a budget; never truncate the JSON object.

Each `severity` is one of `blocking`, `major`, `minor`, or `note`. Use unique, run-local `local_id` values.
`location`, when present, must be one plain JSON string such as `path/to/file:line`; never an object,
array, number, or boolean. Omit it when there is no grounded source location.
A complete pass has `completion="complete"`, `verdict="pass"`, and an empty findings array. A complete
result with findings uses `verdict="findings"`. A partial result always uses `verdict="incomplete"`.
Report only code-review findings grounded in the frozen workspace. Never invent a clean result to satisfy
the schema.
