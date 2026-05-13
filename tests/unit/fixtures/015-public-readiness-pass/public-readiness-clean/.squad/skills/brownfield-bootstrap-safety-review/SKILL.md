---
name: "brownfield-bootstrap-safety-review"
description: "Review brownfield bootstrap changes against the full entrypoint path, conflict gate, dry-run evidence, and no-bypass requirements"
domain: "review"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Inspect bootstrap entrypoint, docs, and integration tests"
    when: "When tracing whether brownfield conflicts are blocked before writes"
  - name: "powershell"
    description: "Run existing integration scripts through the real bootstrap entrypoint"
    when: "When validating dry-run artifact creation, exit codes, and accepted brownfield flow"
---

## Context
Use this when reviewing a bootstrap CLI that must merge into an existing workspace without silently mutating conflicting user-owned surfaces.

## Patterns
- Judge the slice against the full entrypoint (`specrew init`), not the analyzer/helper script alone.
- Verify conflict handling happens before any deployment or scaffold step that can touch conflicting role or charter surfaces.
- Treat a target containing only `.git` as greenfield-fresh; treat any additional pre-existing content as populated workspace state that still needs the safety gate.
- Treat `-Force` as allowed to skip consent only; it must not suppress brownfield conflict blocking.
- Require a persistent dry-run artifact from the entrypoint path when the requirement calls for reviewable safety evidence.
- Require entrypoint-level integration coverage for both the blocked-conflict path and the accepted no-conflict brownfield path.
- Confirm user-facing docs describe the same blocked path, dry-run artifact location, and `-Force` constraint that the tests and code implement.
- In docs review, reject any brownfield quickstart that shows `specrew init -ProjectPath .` succeeding on a populated repo unless the code explicitly permits that case; the common safe wording is dry-run first, then `-Force` for genuinely populated workspaces.

## Examples
- `scripts\specrew-init.ps1` runs brownfield analysis, writes `.specrew\bootstrap-dry-run-{timestamp}.md`, and exits 5 on conflicts before deployment.
- `tests\integration\brownfield-conflict-handling.ps1` proves dry-run artifact creation, conflict blocking, `-Force` non-bypass, and no-conflict success via the real entrypoint.
- `tests\integration\bootstrap-to-iteration.ps1` proves a `git init` workspace with only `.git` can bootstrap without `-Force`.
- `tests\integration\bootstrap-to-iteration.ps1` keeps the accepted entrypoint bootstrap flow covered after initialization.

## Anti-Patterns
- Accepting a helper script pass while the top-level bootstrap command can still write after detecting conflicts.
- Accepting console-only dry-run summaries when the requirement calls for a reviewable artifact file.
- Treating `.git` metadata alone as user content that forces `-Force` on an otherwise fresh repo.
- Treating `-Force` as permission to continue through detected brownfield conflicts.
- Relying on isolated helper-script tests without entrypoint coverage of the accepted brownfield path.
