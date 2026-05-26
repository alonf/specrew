# Quickstart: F-047 Trust-Hardening Bug-Bash Bundle

**Feature**: `047-bug-bash-trust-hardening`
**Last verified**: 2026-05-26 (planning-time; updated at review)

## Run it

```pwsh
# Run the new + existing integration suites
Invoke-Pester tests/integration/non-specrew-session-bypass.tests.ps1
Invoke-Pester tests/integration/    # full no-regression sweep

# Run governance validation (now emits the new WARNs)
$env:SPECREW_MODULE_PATH = "C:\Dev\Specrew"
pwsh -File extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

## Try the canonical scenarios

1. **Handoff-block WARN (Item 1)**: point the validator at an iteration whose boundary commit lacks a `=== SPECREW HANDOFF ===` block → expect a WARN finding, not FAIL.
2. **Mermaid-absence WARN (Item 3)**: create a `review-diagrams.md` containing only a ` ```text ` block → expect a soft-WARN. Re-scaffold with `scaffold-reviewer-artifacts.ps1` → the regenerated file contains a ` ```mermaid ` skeleton.
3. **Internal-reference WARN (Item 4)**: grep the in-scope coordinator handoff prose for `\bF-\d{3,}\b` → expect zero matches; feed a `=== SPECREW HANDOFF ===` block containing "Feature 016" through the validator → expect a WARN; confirm the same token inside a proposal does NOT WARN.
4. **Empty skill dir (Item 5)**: create `.claude/skills/` with no `SKILL.md` files, run `specrew start` → auto-repair fires; no contradictory "missing skill files" WARN remains.
5. **Resume reconciliation (Item 7)**: in a feature whose `tasks.md` shows all `[x]`, run `specrew start` → the regenerated `tasks-progress.yml` shows tasks `done`, and the welcome-back snapshot does not say "Start T001".

## Verify the edge cases

- A `review-diagrams.md` that has BOTH a ` ```mermaid ` and a ` ```text ` block does NOT WARN.
- Version strings (`v0.27.3`) and years do NOT trip the internal-reference regex.
- A skill root containing only a stray non-`SKILL.md` file is still treated as missing.
