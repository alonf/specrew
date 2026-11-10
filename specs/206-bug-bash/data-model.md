# Data Model: 206-bug-bash

Four records change or appear. None holds a local path, a user name or a machine name.

## 1. `.specrew/legacy-frozen.yml` (new, FR-007)

The frozen legacy list: iterations delivered but never formally closed, judged by no check.

```yaml
schema: v1
closed_on: 2026-11-10        # FR-007: no entry may be added after this list is applied
entries:
  - iteration: 048-<slug>/001
    reason: reached retro with an accepted review, never formally closed
  - iteration: 141-<slug>/006
    reason: closed before dashboards were rendered automatically
```

- `iteration`: `<feature-dir>/<NNN>`, as the closed index keys it.
- `reason`: one line, true for that entry.
- Exactly 18 entries: 048/001, 197/001, 198/008 (each with its own reason) and the 15 dashboards
  (141/006-008, 174/006, 174/008-011, 182/002-004, 197/003-005, 198/003).
- **Meaning:** an entry is judged by no validator check, open or closed (condition 2). It is not "closed"
  for `Test-SpecrewIterationClosed`.
- **Guard:** a test pins the 18 keys; any added, removed or changed key fails it (SC-005).

## 2. `.specrew/closed-iterations.yml` closure stamp (FR-008)

New entries written by iteration closeout carry a stamp; existing entries are not rewritten.

```yaml
  - feature: 206-bug-bash
    iteration: "001"
    closed_at: 2026-11-12T10:04:00Z
    closed_at_source: closeout
```

- `closed_at_source: closeout` means `closed_at` is the real closure time. An entry without it (the 131
  stamped by the 2026-08-06 rebuild, and every older one) has no trusted closure date.
- A closed-iteration check with `since` judges an iteration only when it has a `closeout` stamp with
  `closed_at >= since`.

## 3. Closed-iteration check declaration (FR-008)

Inside the validator, each check that judges closed iterations declares:

| Field | Value for the dashboard check |
| --- | --- |
| `name` | `missing-dashboard-auto-render-regression` |
| `since` | `2026-05-26` (`d4284c8a`) |
| `applies_to_status` | `complete` (an abandoned iteration owes no dashboard) |

It replaces the feature-number cut-off (features 017 and later).

## 4. Nightly findings file and tracking issue (FR-009)

**Findings file**: the validator writes it when given `-FindingsJsonPath`; the nightly passes it to the
notifier job as a workflow artifact.

```json
{ "schema": "v1", "findings": [ { "iteration": "198-beta2-hardening/011", "rule": "review-verdict-accepted", "severity": "error" } ] }
```

- `rule`: the finding's category. An error with no category is reported as `uncategorized`, and its
  normalized message contributes only a hash to the fingerprint, never text to the issue.
- **Fingerprint**: SHA-256 over the sorted `iteration|rule|severity` lines (plus message hashes for
  `uncategorized`).

**Tracking issue**: one open issue at a time, found by the label `nightly-truth-check`.

| Night | Open issue? | Fingerprint vs issue | Action |
| --- | --- | --- | --- |
| red | no | — | open the issue (title, body with the finding table and the fingerprint) |
| red | yes | same | nothing |
| red | yes | different | comment with the new table; update the stored fingerprint |
| green | yes | — | comment "green on run N" and close |
| green | no | — | nothing |

Title, body and comments carry only iteration ids, rule names, severities, the run id and the commit; a test
asserts that the rendered text has no path separator sequence, no runner home path and no user or machine
name.
