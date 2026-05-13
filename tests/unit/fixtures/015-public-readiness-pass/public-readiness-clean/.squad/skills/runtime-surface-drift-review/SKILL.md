---
name: "runtime-surface-drift-review"
description: "Review deploy-surface changes by reconciling runtime scripts, contracts, and adjacent README files."
domain: "review"
confidence: "high"
source: "earned"
tools:
  - name: "rg"
    description: "Find surface names and stale vocabulary across related files."
    when: "When a skill, ceremony, or role label may be inconsistently documented."
  - name: "view"
    description: "Read the exact runtime script and template text that defines the shipped behavior."
    when: "When verdicts depend on file-level wording, not summaries."
---

## Context

Use this skill when a runtime-facing change affects what gets deployed or registered downstream. These changes often leave one corrected source file and one stale sibling README behind.

## Patterns

- Review the live deploy script first to determine actual shipped behavior.
- Reconcile that behavior against the contract and the nearest README files, not just the top-level docs.
- Treat directory-level READMEs as part of the runtime surface when they describe what is appended, copied, or registered downstream.
- Reject PASS when documentation still describes a runtime surface that the script no longer ships.

## Examples

- `deploy-squad-runtime.ps1` appends only `planning.md` and `review-demo.md`, so any README that still lists `Specrew: Retrospective` as appended is a real drift defect.
- If `iteration-resume.md` stays source-only, both the contract and skills README must describe it as deferred rather than deployed.

## Anti-Patterns

- Trusting earlier decision notes over the current files on disk.
- Reviewing only the contract and missing the directory-level README that operators will actually read.
- Calling drift resolved when runtime behavior and documentation still disagree.
