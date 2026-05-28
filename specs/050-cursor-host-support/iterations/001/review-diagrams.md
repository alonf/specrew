# Review Diagrams: Iteration 001

**Schema**: v1
**Diagram Format**: mermaid

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
> 
> This iteration's task tracking declares **10 completed task(s)**, but the git diff against baseline `b1b1ca0afff2c988cc4b94de0f96cd3a7d0b255c` contains **21 file(s)**.
> 
> **Severity**: WARNING  
> **Implication**: Review evidence may be incomplete or misleading.
> 
> **Possible causes**:
> - Implementation work was not committed before scaffolding review artifacts
> - Task status markers in plan.md or review.md do not match actual progress
> - Baseline reference in state.md is stale or incorrect
> 
> **Remediation**: 
> 1. Verify implementation is committed: `git diff b1b1ca0afff2c988cc4b94de0f96cd3a7d0b255c...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
> 
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Structure Diagram

```mermaid
graph TD
  omitted["_omitted_"]
```

## Flow Diagram

```mermaid
flowchart TD
  hosts_cursor_handlers["hosts/cursor/handlers"]
  scripts_specrew_start["scripts/specrew-start"]
```

## Omissions

- Structure diagram omitted: inter-module edges (0) below threshold (2).

## Local View Hints

- specs\050-cursor-host-support\iterations\001\review-diagrams.md