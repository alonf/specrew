# Contract: Beta-Before-Stable SDLC Public Surface

**Feature**: `048-beta-before-stable-sdlc`  
**Stability**: pre-1.0

## Coordinator Feature-Closeout Handoff

The coordinator prompt emits a feature-closeout handoff with explicit ownership
rows. The agent row owns execution; the human row owns approvals and manual
validation.

### Required Text Surface

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `AGENT NEXT ACTION:` | handoff row | Enumerate Steps 5-14 as agent-driven work | Missing row fails tests |
| `HUMAN ACTION NEEDED:` | handoff row | Ask for approvals and Step 11 PASS/FAIL verdict | Missing row fails tests |

### Invariants

- Steps 5-14 must appear in order.
- Step 11 must pause for human PASS/FAIL on the installed prerelease package.
- Step 12 must loop on FAIL with an incremented beta tag.
- Step 13 stable promotion requires PASS.

## `specrew release-audit`

Top-level CLI route for release audit capture and validation.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `capture` | `specrew release-audit capture --feature <ref> --pr <number> --merge-sha <sha> --version <semver> --beta-tag <tag> --beta-verification <text> --human-verdict PASS\|FAIL --stable-tag <tag> --stable-verification <text>` | Write or update the per-feature release audit artifact | Fails when required fields are missing or verdict is not explicit |
| `validate` | `specrew release-audit validate --feature <ref>` | Validate the release audit artifact for one feature | Fails when schema/evidence/status is incomplete or contradictory |

### Invariants

- Missing or false `release_audit_direct_to_main` selects trailing one-file PR
  mode.
- `release_audit_direct_to_main: true` selects direct-main mode.
- The CLI never records secrets; it records commands, tags, SHAs, verdicts, and
  verification summaries.
- `complete` status requires at least one beta attempt with `PASS` plus stable
  package verification.

## Release Audit File

One Markdown file per feature stores the structured release record and narrative.

### File Path

```text
docs/releases/<feature-ref>.md
```

### Structured Front Matter

```yaml
---
schema: specrew.release-audit.v1
feature_ref: 048-beta-before-stable-sdlc
pr_number: 999
merge_sha: 0123456789abcdef
version: 0.27.5
audit_mode: direct-main
status: complete
beta_attempts:
  - tag: v0.27.5-beta.1
    published: true
    verification: Find-Module Specrew -AllowPrerelease -RequiredVersion 0.27.5-beta.1
    human_verdict: PASS
    evidence: Clean shell install plus feature smoke passed.
stable_tag: v0.27.5
stable_verification: Find-Module Specrew -RequiredVersion 0.27.5
captured_at: 2026-05-26T00:00:00Z
---
```

### Narrative Body

The body explains the feature release timeline, beta validation evidence,
failure loop if any, stable publication, and audit capture mode.
